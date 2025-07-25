# -*- coding: utf-8 -*-
"""
HybridLegalDataService - Serviço híbrido para agregação de dados legais
=======================================================================

Este serviço combina dados de múltiplas fontes legais (JusBrasil, CNJ, etc.)
para fornecer informações consolidadas sobre advogados e escritórios com
transparência completa sobre as fontes de dados.

Features:
- Agregação de dados de múltiplas fontes
- Cache inteligente com TTL diferenciado por fonte
- Transparência de dados (data_transparency)
- Fallback automático entre fontes
- Métricas de qualidade dos dados
"""

import asyncio
import logging
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple, Union
import json
import hashlib
from enum import Enum

import aiohttp
import redis.asyncio as aioredis
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text

from database import get_async_session
from models.lawyer import Lawyer
from models.law_firm import LawFirm
from services.unipile_app_service import get_unipile_app_service


class DataSource(Enum):
    """Fontes de dados disponíveis."""
    ESCAVADOR = "escavador"  # Primeira posição
    UNIPILE = "unipile"      # Nova fonte
    JUSBRASIL = "jusbrasil"
    CNJ = "cnj"
    OAB = "oab"
    INTERNAL = "internal"
    CACHED = "cached"


@dataclass
class DataTransparency:
    """Metadados de transparência sobre a origem dos dados."""
    source: DataSource
    last_updated: datetime
    confidence_score: float  # 0.0 - 1.0
    data_freshness_hours: int
    validation_status: str  # "validated", "pending", "failed"
    source_url: Optional[str] = None
    api_version: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "source": self.source.value,
            "last_updated": self.last_updated.isoformat(),
            "confidence_score": self.confidence_score,
            "data_freshness_hours": self.data_freshness_hours,
            "validation_status": self.validation_status,
            "source_url": self.source_url,
            "api_version": self.api_version
        }


@dataclass
class HybridLawyerData:
    """Dados consolidados de advogado com transparência."""
    lawyer_id: str
    oab_number: str
    name: str
    specializations: List[str]
    success_metrics: Dict[str, float]
    reputation_score: float
    cases_won: int
    cases_total: int
    avg_case_duration_days: float
    
    # Transparência de dados
    data_transparency: List[DataTransparency] = field(default_factory=list)
    
    def add_transparency(self, transparency: DataTransparency):
        """Adiciona informação de transparência."""
        self.data_transparency.append(transparency)
    
    def get_primary_source(self) -> Optional[DataTransparency]:
        """Retorna a fonte primária (maior confidence_score)."""
        if not self.data_transparency:
            return None
        return max(self.data_transparency, key=lambda x: x.confidence_score)


class HybridLegalDataService:
    """Serviço híbrido para agregação de dados legais."""
    
    def __init__(self, redis_url: str = "redis://localhost:6379/0"):
        self.redis = aioredis.from_url(redis_url, decode_responses=True)
        self.logger = logging.getLogger(__name__)
        
        # Configurações de cache por fonte
        self.cache_ttl = {
            DataSource.ESCAVADOR: 3600 * 8,  # 8 horas - Primeira posição
            DataSource.UNIPILE: 3600 * 4,    # 4 horas - Nova fonte
            DataSource.JUSBRASIL: 3600 * 6,  # 6 horas
            DataSource.CNJ: 3600 * 24,       # 24 horas
            DataSource.OAB: 3600 * 12,       # 12 horas
            DataSource.INTERNAL: 3600 * 2,   # 2 horas
        }
        
        # URLs das APIs externas
        self.api_endpoints = {
            DataSource.ESCAVADOR: "https://api.escavador.com/v1",
            DataSource.UNIPILE: "https://api.unipile.com/v1",  # Nova fonte
            DataSource.JUSBRASIL: "https://api.jusbrasil.com.br/v1",
            DataSource.CNJ: "https://api.cnj.jus.br/v1",
            DataSource.OAB: "https://api.oab.org.br/v1",
        }
        
        # Pesos para agregação de dados (rebalanceados com Escavador primeiro + Unipile)
        self.source_weights = {
            DataSource.ESCAVADOR: 0.30,   # Primeira posição
            DataSource.UNIPILE: 0.20,     # Nova fonte
            DataSource.JUSBRASIL: 0.25,   # Reduzido de 0.35
            DataSource.CNJ: 0.15,         # Reduzido de 0.25
            DataSource.OAB: 0.07,         # Reduzido de 0.10
            DataSource.INTERNAL: 0.03,    # Reduzido de 0.05
        }
    
    async def get_lawyer_data(self, lawyer_id: str, oab_number: str) -> Optional[HybridLawyerData]:
        """
        Obtém dados consolidados de um advogado de múltiplas fontes.
        
        Args:
            lawyer_id: ID interno do advogado
            oab_number: Número OAB do advogado
            
        Returns:
            HybridLawyerData com dados consolidados e transparência
        """
        # Verificar cache primeiro
        cached_data = await self._get_cached_data(lawyer_id)
        if cached_data:
            return cached_data
        
        # Buscar dados de múltiplas fontes em paralelo
        tasks = [
            self._fetch_escavador_data(oab_number),  # Primeiro lugar
            self._fetch_unipile_data(lawyer_id, oab_number),    # Nova fonte
            self._fetch_jusbrasil_data(oab_number),
            self._fetch_cnj_data(oab_number),
            self._fetch_oab_data(oab_number),
            self._fetch_internal_data(lawyer_id),
        ]
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Consolidar dados
        consolidated_data = await self._consolidate_data(lawyer_id, oab_number, results)
        
        # Salvar no cache
        if consolidated_data:
            await self._cache_data(lawyer_id, consolidated_data)
        
        return consolidated_data
    
    async def _fetch_jusbrasil_data(self, oab_number: str) -> Tuple[Optional[Dict], DataTransparency]:
        """Busca dados do JusBrasil."""
        transparency = DataTransparency(
            source=DataSource.JUSBRASIL,
            last_updated=datetime.now(),
            confidence_score=0.0,
            data_freshness_hours=0,
            validation_status="pending",
            source_url=f"{self.api_endpoints[DataSource.JUSBRASIL]}/lawyers/{oab_number}",
            api_version="v1"
        )
        
        try:
            async with aiohttp.ClientSession() as session:
                url = f"{self.api_endpoints[DataSource.JUSBRASIL]}/lawyers/{oab_number}"
                headers = {"Authorization": f"Bearer {self._get_jusbrasil_token()}"}
                
                async with session.get(url, headers=headers, timeout=10) as response:
                    if response.status == 200:
                        data = await response.json()
                        
                        # Validar dados
                        if self._validate_jusbrasil_data(data):
                            transparency.confidence_score = 0.85
                            transparency.validation_status = "validated"
                            transparency.data_freshness_hours = self._calculate_freshness(
                                data.get("last_updated")
                            )
                            
                            return data, transparency
                        else:
                            transparency.validation_status = "failed"
                            self.logger.warning(f"Dados inválidos do JusBrasil para OAB {oab_number}")
                    else:
                        self.logger.error(f"Erro JusBrasil API: {response.status}")
                        
        except Exception as e:
            self.logger.error(f"Erro ao buscar dados JusBrasil: {e}")
            transparency.validation_status = "failed"
        
        return None, transparency
    
    async def _fetch_escavador_data(self, oab_number: str) -> Tuple[Optional[Dict], DataTransparency]:
        """Busca dados do Escavador."""
        transparency = DataTransparency(
            source=DataSource.ESCAVADOR,
            last_updated=datetime.now(),
            confidence_score=0.0,
            data_freshness_hours=0,
            validation_status="pending",
            source_url=f"{self.api_endpoints[DataSource.ESCAVADOR]}/lawyers/{oab_number}",
            api_version="v1"
        )
        
        try:
            async with aiohttp.ClientSession() as session:
                url = f"{self.api_endpoints[DataSource.ESCAVADOR]}/lawyers/{oab_number}"
                headers = {"Authorization": f"Bearer {self._get_escavador_token()}"}
                
                async with session.get(url, headers=headers, timeout=10) as response:
                    if response.status == 200:
                        data = await response.json()
                        
                        # Validar dados
                        if self._validate_escavador_data(data):
                            transparency.confidence_score = 0.80  # Ligeiramente menor que JusBrasil
                            transparency.validation_status = "validated"
                            transparency.data_freshness_hours = self._calculate_freshness(
                                data.get("last_updated")
                            )
                            
                            return data, transparency
                        else:
                            transparency.validation_status = "failed"
                            self.logger.warning(f"Dados inválidos do Escavador para OAB {oab_number}")
                    else:
                        self.logger.error(f"Erro Escavador API: {response.status}")
                        
        except Exception as e:
            self.logger.error(f"Erro ao buscar dados Escavador: {e}")
            transparency.validation_status = "failed"
        
        return None, transparency
    
    async def _fetch_unipile_data(self, lawyer_id: str, oab_number: str) -> Tuple[Optional[Dict], DataTransparency]:
        """
        Busca dados do Unipile usando o SDK oficial.
        
        Args:
            lawyer_id: ID do advogado
            oab_number: Número OAB
            
        Returns:
            Tuple com dados e transparência
        """
        try:
            unipile_service = get_unipile_app_service()
            
            # Buscar dados de comunicação usando o SDK
            data, transparency = await unipile_service.get_communication_data(
                oab_number=oab_number,
                email=None  # Pode ser expandido para incluir email se disponível
            )
            
            if data:
                self.logger.info(f"Dados Unipile obtidos via SDK para OAB {oab_number}")
                return data, transparency
            else:
                self.logger.info(f"Nenhum dado Unipile encontrado para OAB {oab_number}")
                return None, transparency
                
        except Exception as e:
            self.logger.error(f"Erro ao buscar dados Unipile via SDK: {e}")
            
            # Retornar transparência com erro
            transparency = DataTransparency(
                source=DataSource.UNIPILE,
                last_updated=datetime.now(),
                confidence_score=0.0,
                data_freshness_hours=24,
                validation_status="failed",
                source_url="https://api.unipile.com/v1/accounts",
                api_version="v1-sdk"
            )
            
            return None, transparency
    
    async def _get_lawyer_email(self, oab_number: str) -> Optional[str]:
        """Busca email do advogado no banco de dados."""
        try:
            async with get_async_session() as session:
                result = await session.execute(
                    select(Lawyer.email).where(Lawyer.oab_number == oab_number)
                )
                lawyer = result.scalar_one_or_none()
                return lawyer.email if lawyer else None
        except Exception as e:
            self.logger.error(f"Erro ao buscar email do advogado {oab_number}: {e}")
            return None
    
    async def _fetch_cnj_data(self, oab_number: str) -> Tuple[Optional[Dict], DataTransparency]:
        """Busca dados do CNJ."""
        transparency = DataTransparency(
            source=DataSource.CNJ,
            last_updated=datetime.now(),
            confidence_score=0.0,
            data_freshness_hours=0,
            validation_status="pending",
            source_url=f"{self.api_endpoints[DataSource.CNJ]}/lawyers/{oab_number}",
            api_version="v1"
        )
        
        try:
            async with aiohttp.ClientSession() as session:
                url = f"{self.api_endpoints[DataSource.CNJ]}/lawyers/{oab_number}"
                headers = {"X-API-Key": self._get_cnj_token()}
                
                async with session.get(url, headers=headers, timeout=15) as response:
                    if response.status == 200:
                        data = await response.json()
                        
                        if self._validate_cnj_data(data):
                            transparency.confidence_score = 0.90  # CNJ tem alta confiabilidade
                            transparency.validation_status = "validated"
                            transparency.data_freshness_hours = self._calculate_freshness(
                                data.get("updated_at")
                            )
                            
                            return data, transparency
                        else:
                            transparency.validation_status = "failed"
                            
        except Exception as e:
            self.logger.error(f"Erro ao buscar dados CNJ: {e}")
            transparency.validation_status = "failed"
        
        return None, transparency
    
    async def _fetch_oab_data(self, oab_number: str) -> Tuple[Optional[Dict], DataTransparency]:
        """Busca dados da OAB."""
        transparency = DataTransparency(
            source=DataSource.OAB,
            last_updated=datetime.now(),
            confidence_score=0.0,
            data_freshness_hours=0,
            validation_status="pending",
            source_url=f"{self.api_endpoints[DataSource.OAB]}/lawyers/{oab_number}",
            api_version="v1"
        )
        
        try:
            async with aiohttp.ClientSession() as session:
                url = f"{self.api_endpoints[DataSource.OAB]}/lawyers/{oab_number}"
                
                async with session.get(url, timeout=12) as response:
                    if response.status == 200:
                        data = await response.json()
                        
                        if self._validate_oab_data(data):
                            transparency.confidence_score = 0.95  # OAB é fonte oficial
                            transparency.validation_status = "validated"
                            transparency.data_freshness_hours = self._calculate_freshness(
                                data.get("last_sync")
                            )
                            
                            return data, transparency
                        else:
                            transparency.validation_status = "failed"
                            
        except Exception as e:
            self.logger.error(f"Erro ao buscar dados OAB: {e}")
            transparency.validation_status = "failed"
        
        return None, transparency
    
    async def _fetch_internal_data(self, lawyer_id: str) -> Tuple[Optional[Dict], DataTransparency]:
        """Busca dados internos do banco."""
        transparency = DataTransparency(
            source=DataSource.INTERNAL,
            last_updated=datetime.now(),
            confidence_score=0.8,
            data_freshness_hours=0,
            validation_status="validated",
            source_url="internal_database",
            api_version="internal"
        )
        
        try:
            async with get_async_session() as session:
                # Buscar dados do advogado
                result = await session.execute(
                    select(Lawyer).where(Lawyer.id == lawyer_id)
                )
                lawyer = result.scalar_one_or_none()
                
                if lawyer:
                    # Buscar métricas de casos
                    cases_query = text("""
                        SELECT 
                            COUNT(*) as total_cases,
                            SUM(CASE WHEN outcome = 'won' THEN 1 ELSE 0 END) as cases_won,
                            AVG(EXTRACT(EPOCH FROM (closed_at - created_at))/86400) as avg_duration_days
                        FROM cases 
                        WHERE lawyer_id = :lawyer_id 
                        AND closed_at IS NOT NULL
                        AND created_at >= NOW() - INTERVAL '12 months'
                    """)
                    
                    cases_result = await session.execute(cases_query, {"lawyer_id": lawyer_id})
                    cases_metrics = cases_result.fetchone()
                    
                    data = {
                        "id": lawyer.id,
                        "name": lawyer.name,
                        "oab_number": lawyer.oab_number,
                        "specializations": lawyer.specializations or [],
                        "success_rate": lawyer.success_rate,
                        "reputation_score": lawyer.reputation_score,
                        "cases_total": cases_metrics.total_cases if cases_metrics else 0,
                        "cases_won": cases_metrics.cases_won if cases_metrics else 0,
                        "avg_case_duration_days": cases_metrics.avg_duration_days if cases_metrics else 0,
                        "last_updated": lawyer.updated_at.isoformat() if lawyer.updated_at else None,
                    }
                    
                    transparency.data_freshness_hours = self._calculate_freshness(
                        lawyer.updated_at.isoformat() if lawyer.updated_at else None
                    )
                    
                    return data, transparency
                    
        except Exception as e:
            self.logger.error(f"Erro ao buscar dados internos: {e}")
            transparency.validation_status = "failed"
        
        return None, transparency
    
    async def _consolidate_data(self, lawyer_id: str, oab_number: str, 
                              results: List[Union[Tuple[Optional[Dict], DataTransparency], Exception]]) -> Optional[HybridLawyerData]:
        """Consolida dados de múltiplas fontes."""
        valid_results = []
        transparencies = []
        
        # Filtrar resultados válidos
        for result in results:
            if isinstance(result, Exception):
                self.logger.error(f"Erro na busca de dados: {result}")
                continue
            
            data, transparency = result
            transparencies.append(transparency)
            
            if data and transparency.validation_status == "validated":
                valid_results.append((data, transparency))
        
        if not valid_results:
            self.logger.warning(f"Nenhum dado válido encontrado para advogado {lawyer_id}")
            return None
        
        # Consolidar dados usando pesos
        consolidated = HybridLawyerData(
            lawyer_id=lawyer_id,
            oab_number=oab_number,
            name="",
            specializations=[],
            success_metrics={},
            reputation_score=0.0,
            cases_won=0,
            cases_total=0,
            avg_case_duration_days=0.0,
            data_transparency=transparencies
        )
        
        # Agregação ponderada
        total_weight = 0.0
        weighted_reputation = 0.0
        weighted_cases_won = 0.0
        weighted_cases_total = 0.0
        weighted_duration = 0.0
        
        all_specializations = set()
        names = []
        
        for data, transparency in valid_results:
            weight = self.source_weights.get(transparency.source, 0.1)
            confidence_weight = weight * transparency.confidence_score
            
            # Nome (usar fonte com maior confiança)
            if transparency.confidence_score > 0.8:
                names.append((data.get("name", ""), confidence_weight))
            
            # Especializações (união de todas as fontes)
            specs = data.get("specializations", [])
            if isinstance(specs, list):
                all_specializations.update(specs)
            
            # Métricas ponderadas
            if "reputation_score" in data:
                weighted_reputation += data["reputation_score"] * confidence_weight
            if "cases_won" in data:
                weighted_cases_won += data["cases_won"] * confidence_weight
            if "cases_total" in data:
                weighted_cases_total += data["cases_total"] * confidence_weight
            if "avg_case_duration_days" in data:
                weighted_duration += data["avg_case_duration_days"] * confidence_weight
                
            total_weight += confidence_weight
        
        # Aplicar pesos
        if total_weight > 0:
            consolidated.reputation_score = weighted_reputation / total_weight
            consolidated.cases_won = int(weighted_cases_won / total_weight)
            consolidated.cases_total = int(weighted_cases_total / total_weight)
            consolidated.avg_case_duration_days = weighted_duration / total_weight
        
        # Nome (usar o de maior confiança)
        if names:
            consolidated.name = max(names, key=lambda x: x[1])[0]
        
        # Especializações
        consolidated.specializations = list(all_specializations)
        
        # Métricas de sucesso
        if consolidated.cases_total > 0:
            consolidated.success_metrics = {
                "success_rate": consolidated.cases_won / consolidated.cases_total,
                "efficiency_score": 1.0 / (consolidated.avg_case_duration_days / 365) if consolidated.avg_case_duration_days > 0 else 0.0,
                "volume_score": min(1.0, consolidated.cases_total / 100.0),
            }
        
        return consolidated
    
    async def _get_cached_data(self, lawyer_id: str) -> Optional[HybridLawyerData]:
        """Recupera dados do cache."""
        try:
            cache_key = f"hybrid_lawyer_data:{lawyer_id}"
            cached_json = await self.redis.get(cache_key)
            
            if cached_json:
                data = json.loads(cached_json)
                
                # Verificar se o cache ainda é válido
                cache_time = datetime.fromisoformat(data["cached_at"])
                if datetime.now() - cache_time < timedelta(hours=2):
                    
                    # Reconstruir objeto HybridLawyerData
                    hybrid_data = HybridLawyerData(
                        lawyer_id=data["lawyer_id"],
                        oab_number=data["oab_number"],
                        name=data["name"],
                        specializations=data["specializations"],
                        success_metrics=data["success_metrics"],
                        reputation_score=data["reputation_score"],
                        cases_won=data["cases_won"],
                        cases_total=data["cases_total"],
                        avg_case_duration_days=data["avg_case_duration_days"],
                    )
                    
                    # Reconstruir transparências
                    for t_data in data["data_transparency"]:
                        transparency = DataTransparency(
                            source=DataSource(t_data["source"]),
                            last_updated=datetime.fromisoformat(t_data["last_updated"]),
                            confidence_score=t_data["confidence_score"],
                            data_freshness_hours=t_data["data_freshness_hours"],
                            validation_status=t_data["validation_status"],
                            source_url=t_data.get("source_url"),
                            api_version=t_data.get("api_version")
                        )
                        hybrid_data.add_transparency(transparency)
                    
                    # Marcar como cache
                    cache_transparency = DataTransparency(
                        source=DataSource.CACHED,
                        last_updated=cache_time,
                        confidence_score=1.0,
                        data_freshness_hours=int((datetime.now() - cache_time).total_seconds() / 3600),
                        validation_status="validated",
                        source_url="redis_cache",
                        api_version="cache"
                    )
                    hybrid_data.add_transparency(cache_transparency)
                    
                    return hybrid_data
                    
        except Exception as e:
            self.logger.error(f"Erro ao recuperar cache: {e}")
        
        return None
    
    async def _cache_data(self, lawyer_id: str, data: HybridLawyerData):
        """Salva dados no cache."""
        try:
            cache_key = f"hybrid_lawyer_data:{lawyer_id}"
            
            cache_data = {
                "lawyer_id": data.lawyer_id,
                "oab_number": data.oab_number,
                "name": data.name,
                "specializations": data.specializations,
                "success_metrics": data.success_metrics,
                "reputation_score": data.reputation_score,
                "cases_won": data.cases_won,
                "cases_total": data.cases_total,
                "avg_case_duration_days": data.avg_case_duration_days,
                "data_transparency": [t.to_dict() for t in data.data_transparency],
                "cached_at": datetime.now().isoformat()
            }
            
            await self.redis.setex(
                cache_key,
                7200,  # 2 horas
                json.dumps(cache_data, ensure_ascii=False)
            )
            
        except Exception as e:
            self.logger.error(f"Erro ao salvar cache: {e}")
    
    def _validate_jusbrasil_data(self, data: Dict) -> bool:
        """Valida dados do JusBrasil."""
        required_fields = ["name", "oab_number", "specializations"]
        return all(field in data for field in required_fields)
    
    def _validate_escavador_data(self, data: Dict) -> bool:
        """Valida dados do Escavador."""
        required_fields = ["name", "oab_number", "specializations", "success_rate"]
        return all(field in data for field in required_fields)
    
    def _validate_unipile_data(self, data: Dict) -> bool:
        """Valida dados do Unipile."""
        required_fields = ["name", "oab_number", "specializations", "success_rate"]
        return all(field in data for field in required_fields)
    
    def _validate_cnj_data(self, data: Dict) -> bool:
        """Valida dados do CNJ."""
        required_fields = ["name", "oab_number", "cases_total"]
        return all(field in data for field in required_fields)
    
    def _validate_oab_data(self, data: Dict) -> bool:
        """Valida dados da OAB."""
        required_fields = ["name", "oab_number", "status"]
        return all(field in data for field in required_fields) and data.get("status") == "active"
    
    def _calculate_freshness(self, last_updated: Optional[str]) -> int:
        """Calcula idade dos dados em horas."""
        if not last_updated:
            return 24 * 365  # 1 ano se não há timestamp
        
        try:
            updated_time = datetime.fromisoformat(last_updated.replace('Z', '+00:00'))
            delta = datetime.now() - updated_time.replace(tzinfo=None)
            return int(delta.total_seconds() / 3600)
        except Exception:
            return 24 * 365
    
    def _get_jusbrasil_token(self) -> str:
        """Obtém token do JusBrasil."""
        import os
        return os.getenv("JUSBRASIL_API_TOKEN", "")
    
    def _get_cnj_token(self) -> str:
        """Obtém token do CNJ."""
        import os
        return os.getenv("CNJ_API_TOKEN", "")
    
    def _get_escavador_token(self) -> str:
        """Obtém token do Escavador."""
        import os
        return os.getenv("ESCAVADOR_API_TOKEN", "")
    
    def _get_unipile_token(self) -> str:
        """Obtém token do Unipile."""
        import os
        return os.getenv("UNIPILE_API_TOKEN", "")
    
    async def get_data_quality_metrics(self, lawyer_id: str) -> Dict[str, Any]:
        """Retorna métricas de qualidade dos dados."""
        data = await self.get_lawyer_data(lawyer_id, "")
        
        if not data or not data.data_transparency:
            return {"quality_score": 0.0, "sources": 0, "freshness": "unknown"}
        
        # Calcular score de qualidade
        total_confidence = sum(t.confidence_score for t in data.data_transparency)
        avg_confidence = total_confidence / len(data.data_transparency)
        
        # Freshness score (melhor = mais recente)
        avg_freshness = sum(t.data_freshness_hours for t in data.data_transparency) / len(data.data_transparency)
        freshness_score = max(0.0, 1.0 - (avg_freshness / (24 * 7)))  # Decai em 1 semana
        
        quality_score = (avg_confidence * 0.7) + (freshness_score * 0.3)
        
        return {
            "quality_score": round(quality_score, 3),
            "sources": len([t for t in data.data_transparency if t.source != DataSource.CACHED]),
            "freshness": f"{int(avg_freshness)}h",
            "primary_source": data.get_primary_source().source.value if data.get_primary_source() else "unknown",
            "last_sync": max(t.last_updated for t in data.data_transparency).isoformat()
        }
    
    async def close(self):
        """Fecha conexões."""
        await self.redis.close() 