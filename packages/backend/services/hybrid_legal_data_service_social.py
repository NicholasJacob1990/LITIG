# -*- coding: utf-8 -*-
"""
HybridLegalDataService - Versão SOCIAL ATUALIZADA
===============================================

Serviço híbrido para agregação de dados legais + dados sociais.
Inclui Instagram, Facebook e LinkedIn via Unipile SDK.

Features:
- Agregação de dados de múltiplas fontes
- Cache inteligente com TTL diferenciado por fonte
- Transparência de dados (data_transparency)
- Fallback automático entre fontes
- Métricas de qualidade dos dados
- 🆕 DADOS SOCIAIS INTEGRADOS
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

from backend.database import get_async_session
from backend.models.lawyer import Lawyer
from backend.models.law_firm import LawFirm

# Import corrigido para evitar erros
try:
    from backend.services.unipile_sdk_wrapper_clean import UnipileSDKWrapper
except ImportError:
    from backend.services.unipile_sdk_wrapper import UnipileSDKWrapper


class DataSource(Enum):
    """Fontes de dados disponíveis."""
    ESCAVADOR = "escavador"
    UNIPILE = "unipile"      # SOCIAL + EMAIL INTEGRADO
    JUSBRASIL = "jusbrasil"
    CNJ = "cnj"
    OAB = "oab"
    INTERNAL = "internal"
    CACHED = "cached"


@dataclass
class DataTransparency:
    """Informações de transparência sobre a origem dos dados."""
    source: DataSource
    last_updated: datetime
    confidence_score: float  # 0.0 a 1.0
    data_freshness_hours: int
    validation_status: str  # "validated", "partial", "failed", "pending"
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
    """Dados consolidados de um advogado com múltiplas fontes."""
    oab_number: str
    name: str
    specializations: List[str]
    success_rate: float
    data_transparency: List[DataTransparency]
    consolidated_data: Dict[str, Any] = field(default_factory=dict)
    social_data: Optional[Dict[str, Any]] = None  # 🆕 DADOS SOCIAIS


class HybridLegalDataServiceSocial:
    """Serviço híbrido para agregação de dados legais + SOCIAIS."""
    
    def __init__(self, redis_url: str = "redis://localhost:6379/0"):
        self.redis = aioredis.from_url(redis_url, decode_responses=True)
        self.logger = logging.getLogger(__name__)
        
        # 🆕 PESOS REBALANCEADOS COM DADOS SOCIAIS
        self.cache_ttl = {
            DataSource.ESCAVADOR: 3600 * 8,   # 8 horas
            DataSource.UNIPILE: 3600 * 2,     # 2 horas - dados sociais mudam mais
            DataSource.JUSBRASIL: 3600 * 6,   # 6 horas
            DataSource.CNJ: 3600 * 24,        # 24 horas
            DataSource.OAB: 3600 * 12,        # 12 horas
            DataSource.INTERNAL: 3600 * 2,    # 2 horas
        }
        
        # URLs das APIs externas
        self.api_endpoints = {
            DataSource.ESCAVADOR: "https://api.escavador.com/v1",
            DataSource.UNIPILE: "https://api.unipile.com/v1",
            DataSource.JUSBRASIL: "https://api.jusbrasil.com.br/v1",
            DataSource.CNJ: "https://api.cnj.jus.br/v1",
            DataSource.OAB: "https://api.oab.org.br/v1",
        }
        
        # 🆕 PESOS AJUSTADOS PARA DADOS SOCIAIS
        self.source_weights = {
            DataSource.ESCAVADOR: 0.25,    # ↓ de 0.30 - primeira posição
            DataSource.UNIPILE: 0.25,      # ↑ de 0.20 - AGORA INCLUI SOCIAL
            DataSource.JUSBRASIL: 0.20,    # ↓ de 0.25 - reduzido
            DataSource.CNJ: 0.15,          # mantido
            DataSource.OAB: 0.10,          # ↑ de 0.07 - mais importante
            DataSource.INTERNAL: 0.05,     # ↑ de 0.03 - mais importante
        }
    
    async def get_lawyer_data(self, lawyer_id: str, oab_number: str) -> Optional[HybridLawyerData]:
        """
        Obtém dados consolidados de um advogado incluindo dados sociais.
        """
        try:
            self.logger.info(f"Buscando dados híbridos + sociais para OAB {oab_number}")
            
            # Buscar dados de todas as fontes em paralelo
            tasks = [
                self._fetch_escavador_data(oab_number),
                self._fetch_unipile_social_data(lawyer_id, oab_number),  # 🆕 SOCIAL
                self._fetch_jusbrasil_data(oab_number),
                self._fetch_cnj_data(oab_number),
                self._fetch_oab_data(oab_number),
                self._fetch_internal_data(lawyer_id)
            ]
            
            results = await asyncio.gather(*tasks, return_exceptions=True)
            
            # Processar resultados
            all_data = {}
            all_transparency = []
            social_data = None  # 🆕
            
            for i, (data, transparency) in enumerate(results):
                if isinstance(data, Exception):
                    self.logger.error(f"Erro na fonte {list(DataSource)[i]}: {data}")
                    continue
                
                if data:
                    source = list(DataSource)[i]
                    all_data[source.value] = data
                    all_transparency.append(transparency)
                    
                    # 🆕 Capturar dados sociais do Unipile
                    if source == DataSource.UNIPILE and "social_data" in data:
                        social_data = data["social_data"]
            
            if not all_data:
                self.logger.warning(f"Nenhum dado encontrado para OAB {oab_number}")
                return None
            
            # Consolidar dados
            consolidated = self._consolidate_data(all_data)
            
            # 🆕 Ajustar success_rate com dados sociais
            if social_data:
                social_boost = self._calculate_social_boost(social_data)
                consolidated["success_rate"] = min(consolidated.get("success_rate", 0.5) + social_boost, 1.0)
                consolidated["social_score"] = social_data.get("social_score", {})
            
            return HybridLawyerData(
                oab_number=oab_number,
                name=consolidated.get("name", ""),
                specializations=consolidated.get("specializations", []),
                success_rate=consolidated.get("success_rate", 0.5),
                data_transparency=all_transparency,
                consolidated_data=consolidated,
                social_data=social_data  # 🆕
            )
            
        except Exception as e:
            self.logger.error(f"Erro ao buscar dados híbridos para {oab_number}: {e}")
            return None
    
    async def _fetch_unipile_social_data(self, lawyer_id: str, oab_number: str) -> Tuple[Optional[Dict], DataTransparency]:
        """
        🆕 Busca dados do Unipile incluindo redes sociais.
        """
        try:
            unipile_wrapper = UnipileSDKWrapper()
            
            # Buscar dados de comunicação + sociais
            data, transparency = await unipile_wrapper.get_communication_data(oab_number)
            
            if data:
                # Enriquecer com análise social
                social_analysis = self._analyze_social_presence(data)
                data["social_analysis"] = social_analysis
                
                self.logger.info(f"Dados Unipile + social obtidos para OAB {oab_number}")
                return data, transparency
            else:
                self.logger.info(f"Nenhum dado Unipile encontrado para OAB {oab_number}")
                return None, transparency
                
        except Exception as e:
            self.logger.error(f"Erro ao buscar dados Unipile social: {e}")
            
            transparency = DataTransparency(
                source=DataSource.UNIPILE,
                last_updated=datetime.now(),
                confidence_score=0.0,
                data_freshness_hours=24,
                validation_status="failed",
                source_url="https://api.unipile.com/v1/accounts",
                api_version="v2-sdk-social"
            )
            
            return None, transparency
    
    def _analyze_social_presence(self, unipile_data: Dict) -> Dict[str, Any]:
        """
        🆕 Analisa presença social baseada nos dados do Unipile.
        """
        social_analysis = {
            "platforms_connected": [],
            "total_score": 0.0,
            "professional_ratio": 0.0,
            "engagement_quality": "low",
            "recommendations": []
        }
        
        try:
            # Verificar plataformas conectadas
            platforms = unipile_data.get("social_platforms", [])
            social_analysis["platforms_connected"] = platforms
            
            # Calcular score total
            social_score_data = unipile_data.get("social_score", {})
            if social_score_data:
                overall_score = social_score_data.get("overall_score", 0.0)
                social_analysis["total_score"] = overall_score
                
                # Determinar qualidade de engajamento
                if overall_score >= 0.8:
                    social_analysis["engagement_quality"] = "high"
                elif overall_score >= 0.6:
                    social_analysis["engagement_quality"] = "medium"
                else:
                    social_analysis["engagement_quality"] = "low"
            
            # Calcular ratio profissional baseado nas plataformas
            platform_details = unipile_data.get("platform_details", {})
            total_professional = 0
            total_posts = 0
            
            for platform, details in platform_details.items():
                if isinstance(details, dict) and "data" in details:
                    platform_data = details["data"]
                    if "professional_content_ratio" in platform_data:
                        ratio_data = platform_data["professional_content_ratio"]
                        total_professional += ratio_data.get("professional_posts", 0)
                        total_posts += ratio_data.get("total_posts", 0)
            
            if total_posts > 0:
                social_analysis["professional_ratio"] = total_professional / total_posts
            
            # Gerar recomendações
            recommendations = []
            if len(platforms) < 3:
                recommendations.append("Conecte mais redes sociais para melhorar seu score")
            if social_analysis["professional_ratio"] < 0.3:
                recommendations.append("Aumente o conteúdo profissional em suas postagens")
            if social_analysis["total_score"] < 0.6:
                recommendations.append("Aumente a frequência de posts e interações")
            
            social_analysis["recommendations"] = recommendations
            
        except Exception as e:
            self.logger.error(f"Erro ao analisar presença social: {e}")
        
        return social_analysis
    
    def _calculate_social_boost(self, social_data: Dict) -> float:
        """
        🆕 Calcula boost no success_rate baseado nos dados sociais.
        """
        try:
            social_score = social_data.get("social_score", {}).get("overall_score", 0.0)
            
            # Boost máximo de 15% no success_rate
            boost = social_score * 0.15
            
            self.logger.info(f"Social boost calculado: {boost:.3f}")
            return boost
            
        except Exception as e:
            self.logger.error(f"Erro ao calcular social boost: {e}")
            return 0.0
    
    def _consolidate_data(self, all_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Consolida dados de múltiplas fontes usando pesos ajustados.
        """
        consolidated = {
            "name": "",
            "specializations": [],
            "success_rate": 0.0,
            "sources_used": list(all_data.keys()),
            "weighted_score": 0.0
        }
        
        total_weight = 0.0
        weighted_success_rate = 0.0
        all_specializations = set()
        
        for source_name, data in all_data.items():
            try:
                source = DataSource(source_name)
                weight = self.source_weights.get(source, 0.0)
                
                if weight > 0:
                    # Nome (usar primeira fonte válida)
                    if not consolidated["name"] and data.get("name"):
                        consolidated["name"] = data["name"]
                    
                    # Success rate ponderado
                    source_success_rate = data.get("success_rate", 0.5)
                    weighted_success_rate += source_success_rate * weight
                    total_weight += weight
                    
                    # Especializações
                    source_specs = data.get("specializations", [])
                    if isinstance(source_specs, list):
                        all_specializations.update(source_specs)
                    
                    self.logger.debug(f"Fonte {source_name}: peso {weight}, success_rate {source_success_rate}")
                
            except Exception as e:
                self.logger.error(f"Erro ao processar dados da fonte {source_name}: {e}")
        
        # Finalizar consolidação
        if total_weight > 0:
            consolidated["success_rate"] = weighted_success_rate / total_weight
            consolidated["weighted_score"] = total_weight
        
        consolidated["specializations"] = list(all_specializations)
        
        self.logger.info(f"Dados consolidados: score {consolidated['success_rate']:.3f}, peso total {total_weight:.3f}")
        
        return consolidated
    
    # Métodos placeholder para outras fontes (manter compatibilidade)
    async def _fetch_escavador_data(self, oab_number: str) -> Tuple[Optional[Dict], DataTransparency]:
        """Placeholder para dados do Escavador."""
        return None, DataTransparency(
            source=DataSource.ESCAVADOR,
            last_updated=datetime.now(),
            confidence_score=0.0,
            data_freshness_hours=24,
            validation_status="not_implemented"
        )
    
    async def _fetch_jusbrasil_data(self, oab_number: str) -> Tuple[Optional[Dict], DataTransparency]:
        """Placeholder para dados do JusBrasil."""
        return None, DataTransparency(
            source=DataSource.JUSBRASIL,
            last_updated=datetime.now(),
            confidence_score=0.0,
            data_freshness_hours=24,
            validation_status="not_implemented"
        )
    
    async def _fetch_cnj_data(self, oab_number: str) -> Tuple[Optional[Dict], DataTransparency]:
        """Placeholder para dados do CNJ."""
        return None, DataTransparency(
            source=DataSource.CNJ,
            last_updated=datetime.now(),
            confidence_score=0.0,
            data_freshness_hours=24,
            validation_status="not_implemented"
        )
    
    async def _fetch_oab_data(self, oab_number: str) -> Tuple[Optional[Dict], DataTransparency]:
        """Placeholder para dados da OAB."""
        return None, DataTransparency(
            source=DataSource.OAB,
            last_updated=datetime.now(),
            confidence_score=0.0,
            data_freshness_hours=24,
            validation_status="not_implemented"
        )
    
    async def _fetch_internal_data(self, lawyer_id: str) -> Tuple[Optional[Dict], DataTransparency]:
        """Placeholder para dados internos."""
        return None, DataTransparency(
            source=DataSource.INTERNAL,
            last_updated=datetime.now(),
            confidence_score=0.0,
            data_freshness_hours=24,
            validation_status="not_implemented"
        ) 