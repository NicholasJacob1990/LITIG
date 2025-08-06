#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
services/process_cache_service.py

Serviço de cache inteligente para movimentações processuais.
Implementa estratégia de cache em múltiplas camadas: Redis + PostgreSQL.
"""

import asyncio
import json
import logging
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

from fastapi import HTTPException

from services.redis_service import redis_service
from config.database import get_database

logger = logging.getLogger(__name__)

class ProcessCacheService:
    """
    Gerencia cache inteligente de movimentações processuais.
    
    Estratégia de cache em camadas:
    1. Redis (TTL: 1-8 horas) - Acesso ultra-rápido
    2. PostgreSQL (TTL: 7 dias) - Persistência e funcionamento offline  
    3. API Escavador - Fonte original quando cache expirado
    """
    
    def __init__(self):
        self.redis_ttl_seconds = 3600  # 1 hora no Redis
        self.db_ttl_hours = 24  # 24 horas no banco considera válido
        self.db_max_age_days = 7  # 7 dias máximo no banco
        
    async def get_process_movements_cached(
        self, 
        cnj: str, 
        limit: int = 50,
        force_refresh: bool = False
    ) -> Tuple[Dict[str, Any], str]:
        """
        Obtém movimentações de um processo usando cache inteligente.
        
        Returns:
            Tuple[dados, fonte] onde fonte é 'redis', 'database' ou 'api'
        """
        logger.info(f"Buscando movimentações cached para CNJ: {cnj}")
        
        if not force_refresh:
            # 1. Tentar Redis primeiro (mais rápido)
            redis_data = await self._get_from_redis(cnj)
            if redis_data:
                logger.info(f"Cache hit Redis para CNJ: {cnj}")
                return redis_data, "redis"
            
            # 2. Tentar banco de dados (funcionamento offline)
            db_data = await self._get_from_database(cnj, limit)
            if db_data:
                logger.info(f"Cache hit database para CNJ: {cnj}")
                # Salvar no Redis para próximas consultas
                await self._save_to_redis(cnj, db_data)
                return db_data, "database"
        
        # 3. Buscar na API Escavador (dados frescos)
        try:
            api_data = await self._fetch_from_api(cnj, limit)
            if api_data:
                logger.info(f"Dados obtidos da API Escavador para CNJ: {cnj}")
                
                # Salvar em ambos os caches
                await asyncio.gather(
                    self._save_to_redis(cnj, api_data),
                    self._save_to_database(cnj, api_data)
                )
                
                return api_data, "api"
                
        except Exception as e:
            logger.error(f"Erro ao buscar dados da API para CNJ {cnj}: {e}")
            
            # Se API falhou, tentar dados antigos do banco como fallback
            db_fallback = await self._get_from_database(cnj, limit, include_expired=True)
            if db_fallback:
                logger.warning(f"Usando dados antigos do banco para CNJ {cnj} (API indisponível)")
                return db_fallback, "database_fallback"
        
        raise HTTPException(
            status_code=404, 
            detail=f"Nenhum dado encontrado para o processo {cnj} e API indisponível"
        )
    
    async def get_process_status_cached(
        self, 
        cnj: str,
        force_refresh: bool = False
    ) -> Tuple[Dict[str, Any], str]:
        """
        Obtém status agregado de um processo usando cache.
        
        Returns:
            Tuple[status_data, fonte]
        """
        logger.info(f"Buscando status cached para CNJ: {cnj}")
        
        if not force_refresh:
            # 1. Verificar cache de status no banco
            cached_status = await self._get_status_from_database(cnj)
            if cached_status:
                logger.info(f"Status cache hit para CNJ: {cnj}")
                return cached_status, "database"
        
        # 2. Gerar status baseado nas movimentações cached/atuais
        movements_data, movements_source = await self.get_process_movements_cached(
            cnj, limit=20, force_refresh=force_refresh
        )
        
        # 3. Gerar status agregado
        status_data = await self._generate_status_from_movements(movements_data)
        
        # 4. Salvar status no cache
        await self._save_status_to_database(cnj, status_data, movements_source)
        
        return status_data, movements_source
    
    async def invalidate_cache(self, cnj: str) -> bool:
        """Remove dados do cache para forçar atualização."""
        try:
            # Remover do Redis
            redis_key = f"process_movements:{cnj}"
            await redis_service.delete(redis_key)
            
            # Marcar como expirado no banco (não remove, para histórico)
            async with get_database() as db:
                await db.execute("""
                    UPDATE process_status_cache 
                    SET cache_valid_until = NOW() - INTERVAL '1 hour',
                        sync_status = 'invalidated'
                    WHERE cnj = $1
                """, cnj)
            
            logger.info(f"Cache invalidado para CNJ: {cnj}")
            return True
            
        except Exception as e:
            logger.error(f"Erro ao invalidar cache para CNJ {cnj}: {e}")
            return False
    
    async def _get_from_redis(self, cnj: str) -> Optional[Dict[str, Any]]:
        """Busca dados no Redis."""
        try:
            redis_key = f"process_movements:{cnj}"
            data = await redis_service.get_json(redis_key)
            
            if data and self._is_data_fresh(data.get('cached_at', ''), hours=1):
                return data
                
        except Exception as e:
            logger.error(f"Erro ao buscar no Redis para CNJ {cnj}: {e}")
        
        return None
    
    async def _get_from_database(
        self, 
        cnj: str, 
        limit: int = 50,
        include_expired: bool = False
    ) -> Optional[Dict[str, Any]]:
        """Busca dados no banco PostgreSQL."""
        try:
            async with get_database() as db:
                # Buscar movimentações
                where_clause = "cnj = $1"
                params = [cnj]
                
                if not include_expired:
                    where_clause += " AND fetched_from_api_at > $2"
                    params.append(datetime.now() - timedelta(hours=self.db_ttl_hours))
                
                movements = await db.fetch(f"""
                    SELECT * FROM process_movements 
                    WHERE {where_clause}
                    ORDER BY movement_date DESC 
                    LIMIT $3
                """, *params, limit)
                
                if not movements:
                    return None
                
                # Converter para formato esperado
                processed_movements = []
                for mov in movements:
                    processed_movements.append({
                        "id": str(mov['id']),
                        "name": mov['movement_data'].get('name', ''),
                        "description": mov['content'][:200] + "..." if len(mov['content']) > 200 else mov['content'],
                        "full_content": mov['content'],
                        "type": mov['movement_type'],
                        "icon": mov['movement_data'].get('icon', '📋'),
                        "color": mov['movement_data'].get('color', '#6B7280'),
                        "date": mov['movement_date'],
                        "source": {
                            "tribunal": mov['source_tribunal'],
                            "grau": mov['source_grau']
                        },
                        "is_completed": True,
                        "is_current": False,
                        "completed_at": mov['movement_date'],
                        "documents": []
                    })
                
                # Marcar o primeiro como atual
                if processed_movements:
                    processed_movements[0]["is_current"] = True
                
                return {
                    "cnj": cnj,
                    "total_movements": len(processed_movements),
                    "shown_movements": len(processed_movements),
                    "movements": processed_movements,
                    "cached_at": movements[0]['fetched_from_api_at'].isoformat(),
                    "cache_source": "database"
                }
                
        except Exception as e:
            logger.error(f"Erro ao buscar no banco para CNJ {cnj}: {e}")
        
        return None
    
    async def _fetch_from_api(self, cnj: str, limit: int) -> Dict[str, Any]:
        """Busca dados frescos da API Escavador."""
        from services.escavador_integration import EscavadorClient
        from config.base import ESCAVADOR_API_KEY
        
        if not ESCAVADOR_API_KEY:
            raise HTTPException(status_code=500, detail="ESCAVADOR_API_KEY não configurada")
        
        client = EscavadorClient(api_key=ESCAVADOR_API_KEY)
        return await client.get_detailed_process_movements(cnj, limit)
    
    async def _save_to_redis(self, cnj: str, data: Dict[str, Any]) -> bool:
        """Salva dados no Redis com TTL."""
        try:
            redis_key = f"process_movements:{cnj}"
            
            # Adicionar timestamp de cache
            cache_data = data.copy()
            cache_data['cached_at'] = datetime.now().isoformat()
            cache_data['cache_source'] = 'redis'
            
            await redis_service.set_json(redis_key, cache_data, self.redis_ttl_seconds)
            return True
            
        except Exception as e:
            logger.error(f"Erro ao salvar no Redis para CNJ {cnj}: {e}")
            return False
    
    async def _save_to_database(self, cnj: str, data: Dict[str, Any]) -> bool:
        """Salva dados no banco PostgreSQL."""
        try:
            from routes.process_movements import MovementClassifier
            classifier = MovementClassifier()
            
            async with get_database() as db:
                # Salvar cada movimentação individual
                movements = data.get('movements', [])
                
                for movement in movements:
                    movement_date = None
                    if movement.get('date'):
                        try:
                            movement_date = datetime.fromisoformat(movement['date'].replace('Z', '+00:00'))
                        except:
                            movement_date = None
                    
                    await db.execute("""
                        INSERT INTO process_movements (
                            cnj, movement_data, movement_type, movement_date,
                            content, source_tribunal, source_grau,
                            classification_confidence, fetched_from_api_at
                        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
                        ON CONFLICT (cnj, content, movement_date) DO UPDATE SET
                            movement_data = EXCLUDED.movement_data,
                            fetched_from_api_at = NOW()
                    """, 
                    cnj,
                    json.dumps(movement),
                    movement.get('type', 'OUTROS'),
                    movement_date,
                    movement.get('full_content', movement.get('description', '')),
                    movement.get('source', {}).get('tribunal', 'N/A'),
                    movement.get('source', {}).get('grau', 'N/A'),
                    0.8  # confidence padrão
                    )
            
            return True
            
        except Exception as e:
            logger.error(f"Erro ao salvar no banco para CNJ {cnj}: {e}")
            return False
    
    async def _get_status_from_database(self, cnj: str) -> Optional[Dict[str, Any]]:
        """Busca status agregado do banco."""
        try:
            async with get_database() as db:
                status = await db.fetchrow("""
                    SELECT * FROM process_status_cache 
                    WHERE cnj = $1 AND cache_valid_until > NOW()
                """, cnj)
                
                if status:
                    return {
                        "current_phase": status['current_phase'],
                        "description": status['description'],
                        "progress_percentage": float(status['progress_percentage']),
                        "outcome": status['outcome'],
                        "cnj": cnj,
                        "total_movements": status['total_movements'],
                        "last_update": status['last_movement_date'],
                        "tribunal_info": {
                            "name": status['tribunal_name'],
                            "grau": status['tribunal_grau']
                        },
                        "cached_at": status['last_api_sync'].isoformat()
                    }
                    
        except Exception as e:
            logger.error(f"Erro ao buscar status no banco para CNJ {cnj}: {e}")
        
        return None
    
    async def _save_status_to_database(
        self, 
        cnj: str, 
        status_data: Dict[str, Any],
        source: str
    ) -> bool:
        """Salva status agregado no banco."""
        try:
            async with get_database() as db:
                await db.execute("""
                    INSERT INTO process_status_cache (
                        cnj, current_phase, description, progress_percentage,
                        outcome, total_movements, last_movement_date,
                        tribunal_name, tribunal_grau, last_api_sync,
                        cache_valid_until, sync_status
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW() + INTERVAL '24 hours', $10)
                    ON CONFLICT (cnj) DO UPDATE SET
                        current_phase = EXCLUDED.current_phase,
                        description = EXCLUDED.description,
                        progress_percentage = EXCLUDED.progress_percentage,
                        outcome = EXCLUDED.outcome,
                        total_movements = EXCLUDED.total_movements,
                        last_movement_date = EXCLUDED.last_movement_date,
                        tribunal_name = EXCLUDED.tribunal_name,
                        tribunal_grau = EXCLUDED.tribunal_grau,
                        last_api_sync = NOW(),
                        cache_valid_until = NOW() + INTERVAL '24 hours',
                        sync_status = EXCLUDED.sync_status,
                        updated_at = NOW()
                """,
                cnj,
                status_data.get('current_phase', 'Em Andamento'),
                status_data.get('description', ''),
                status_data.get('progress_percentage', 0.0),
                status_data.get('outcome', 'andamento'),
                status_data.get('total_movements', 0),
                status_data.get('last_update'),
                status_data.get('tribunal_info', {}).get('name', 'N/A'),
                status_data.get('tribunal_info', {}).get('grau', 'N/A'),
                'success' if source == 'api' else 'cached'
                )
            
            return True
            
        except Exception as e:
            logger.error(f"Erro ao salvar status no banco para CNJ {cnj}: {e}")
            return False
    
    async def _generate_status_from_movements(self, movements_data: Dict[str, Any]) -> Dict[str, Any]:
        """Gera status agregado baseado nas movimentações."""
        # Reutilizar lógica do escavador_integration.py
        from services.escavador_integration import EscavadorClient
        
        # Criar instância temporária para usar o método de geração de status
        client = EscavadorClient(api_key="dummy")  # API key não será usada aqui
        
        # Simular dados para geração de status
        return {
            "current_phase": movements_data.get('current_phase', 'Em Andamento'),
            "description": f"Processo {movements_data.get('cnj')} com {movements_data.get('total_movements', 0)} movimentações.",
            "progress_percentage": 50.0,  # Calcular baseado nos tipos de movimentação
            "outcome": movements_data.get('outcome', 'andamento'),
            "phases": [],  # Seria gerado baseado nas movimentações
            "cnj": movements_data.get('cnj'),
            "tribunal": movements_data.get('tribunal_info', {}),
            "total_movements": movements_data.get('total_movements', 0),
            "last_update": movements_data.get('movements', [{}])[0].get('date') if movements_data.get('movements') else None
        }
    
    def _is_data_fresh(self, cached_at: str, hours: int = 24) -> bool:
        """Verifica se os dados cached ainda estão frescos."""
        try:
            cached_time = datetime.fromisoformat(cached_at.replace('Z', '+00:00'))
            expiry_time = cached_time + timedelta(hours=hours)
            return datetime.now().replace(tzinfo=cached_time.tzinfo) < expiry_time
        except:
            return False

# Instância global do serviço
process_cache_service = ProcessCacheService() 
# -*- coding: utf-8 -*-
"""
services/process_cache_service.py

Serviço de cache inteligente para movimentações processuais.
Implementa estratégia de cache em múltiplas camadas: Redis + PostgreSQL.
"""

import asyncio
import json
import logging
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

from fastapi import HTTPException

from services.redis_service import redis_service
from config.database import get_database

logger = logging.getLogger(__name__)

class ProcessCacheService:
    """
    Gerencia cache inteligente de movimentações processuais.
    
    Estratégia de cache em camadas:
    1. Redis (TTL: 1-8 horas) - Acesso ultra-rápido
    2. PostgreSQL (TTL: 7 dias) - Persistência e funcionamento offline  
    3. API Escavador - Fonte original quando cache expirado
    """
    
    def __init__(self):
        self.redis_ttl_seconds = 3600  # 1 hora no Redis
        self.db_ttl_hours = 24  # 24 horas no banco considera válido
        self.db_max_age_days = 7  # 7 dias máximo no banco
        
    async def get_process_movements_cached(
        self, 
        cnj: str, 
        limit: int = 50,
        force_refresh: bool = False
    ) -> Tuple[Dict[str, Any], str]:
        """
        Obtém movimentações de um processo usando cache inteligente.
        
        Returns:
            Tuple[dados, fonte] onde fonte é 'redis', 'database' ou 'api'
        """
        logger.info(f"Buscando movimentações cached para CNJ: {cnj}")
        
        if not force_refresh:
            # 1. Tentar Redis primeiro (mais rápido)
            redis_data = await self._get_from_redis(cnj)
            if redis_data:
                logger.info(f"Cache hit Redis para CNJ: {cnj}")
                return redis_data, "redis"
            
            # 2. Tentar banco de dados (funcionamento offline)
            db_data = await self._get_from_database(cnj, limit)
            if db_data:
                logger.info(f"Cache hit database para CNJ: {cnj}")
                # Salvar no Redis para próximas consultas
                await self._save_to_redis(cnj, db_data)
                return db_data, "database"
        
        # 3. Buscar na API Escavador (dados frescos)
        try:
            api_data = await self._fetch_from_api(cnj, limit)
            if api_data:
                logger.info(f"Dados obtidos da API Escavador para CNJ: {cnj}")
                
                # Salvar em ambos os caches
                await asyncio.gather(
                    self._save_to_redis(cnj, api_data),
                    self._save_to_database(cnj, api_data)
                )
                
                return api_data, "api"
                
        except Exception as e:
            logger.error(f"Erro ao buscar dados da API para CNJ {cnj}: {e}")
            
            # Se API falhou, tentar dados antigos do banco como fallback
            db_fallback = await self._get_from_database(cnj, limit, include_expired=True)
            if db_fallback:
                logger.warning(f"Usando dados antigos do banco para CNJ {cnj} (API indisponível)")
                return db_fallback, "database_fallback"
        
        raise HTTPException(
            status_code=404, 
            detail=f"Nenhum dado encontrado para o processo {cnj} e API indisponível"
        )
    
    async def get_process_status_cached(
        self, 
        cnj: str,
        force_refresh: bool = False
    ) -> Tuple[Dict[str, Any], str]:
        """
        Obtém status agregado de um processo usando cache.
        
        Returns:
            Tuple[status_data, fonte]
        """
        logger.info(f"Buscando status cached para CNJ: {cnj}")
        
        if not force_refresh:
            # 1. Verificar cache de status no banco
            cached_status = await self._get_status_from_database(cnj)
            if cached_status:
                logger.info(f"Status cache hit para CNJ: {cnj}")
                return cached_status, "database"
        
        # 2. Gerar status baseado nas movimentações cached/atuais
        movements_data, movements_source = await self.get_process_movements_cached(
            cnj, limit=20, force_refresh=force_refresh
        )
        
        # 3. Gerar status agregado
        status_data = await self._generate_status_from_movements(movements_data)
        
        # 4. Salvar status no cache
        await self._save_status_to_database(cnj, status_data, movements_source)
        
        return status_data, movements_source
    
    async def invalidate_cache(self, cnj: str) -> bool:
        """Remove dados do cache para forçar atualização."""
        try:
            # Remover do Redis
            redis_key = f"process_movements:{cnj}"
            await redis_service.delete(redis_key)
            
            # Marcar como expirado no banco (não remove, para histórico)
            async with get_database() as db:
                await db.execute("""
                    UPDATE process_status_cache 
                    SET cache_valid_until = NOW() - INTERVAL '1 hour',
                        sync_status = 'invalidated'
                    WHERE cnj = $1
                """, cnj)
            
            logger.info(f"Cache invalidado para CNJ: {cnj}")
            return True
            
        except Exception as e:
            logger.error(f"Erro ao invalidar cache para CNJ {cnj}: {e}")
            return False
    
    async def _get_from_redis(self, cnj: str) -> Optional[Dict[str, Any]]:
        """Busca dados no Redis."""
        try:
            redis_key = f"process_movements:{cnj}"
            data = await redis_service.get_json(redis_key)
            
            if data and self._is_data_fresh(data.get('cached_at', ''), hours=1):
                return data
                
        except Exception as e:
            logger.error(f"Erro ao buscar no Redis para CNJ {cnj}: {e}")
        
        return None
    
    async def _get_from_database(
        self, 
        cnj: str, 
        limit: int = 50,
        include_expired: bool = False
    ) -> Optional[Dict[str, Any]]:
        """Busca dados no banco PostgreSQL."""
        try:
            async with get_database() as db:
                # Buscar movimentações
                where_clause = "cnj = $1"
                params = [cnj]
                
                if not include_expired:
                    where_clause += " AND fetched_from_api_at > $2"
                    params.append(datetime.now() - timedelta(hours=self.db_ttl_hours))
                
                movements = await db.fetch(f"""
                    SELECT * FROM process_movements 
                    WHERE {where_clause}
                    ORDER BY movement_date DESC 
                    LIMIT $3
                """, *params, limit)
                
                if not movements:
                    return None
                
                # Converter para formato esperado
                processed_movements = []
                for mov in movements:
                    processed_movements.append({
                        "id": str(mov['id']),
                        "name": mov['movement_data'].get('name', ''),
                        "description": mov['content'][:200] + "..." if len(mov['content']) > 200 else mov['content'],
                        "full_content": mov['content'],
                        "type": mov['movement_type'],
                        "icon": mov['movement_data'].get('icon', '📋'),
                        "color": mov['movement_data'].get('color', '#6B7280'),
                        "date": mov['movement_date'],
                        "source": {
                            "tribunal": mov['source_tribunal'],
                            "grau": mov['source_grau']
                        },
                        "is_completed": True,
                        "is_current": False,
                        "completed_at": mov['movement_date'],
                        "documents": []
                    })
                
                # Marcar o primeiro como atual
                if processed_movements:
                    processed_movements[0]["is_current"] = True
                
                return {
                    "cnj": cnj,
                    "total_movements": len(processed_movements),
                    "shown_movements": len(processed_movements),
                    "movements": processed_movements,
                    "cached_at": movements[0]['fetched_from_api_at'].isoformat(),
                    "cache_source": "database"
                }
                
        except Exception as e:
            logger.error(f"Erro ao buscar no banco para CNJ {cnj}: {e}")
        
        return None
    
    async def _fetch_from_api(self, cnj: str, limit: int) -> Dict[str, Any]:
        """Busca dados frescos da API Escavador."""
        from services.escavador_integration import EscavadorClient
        from config.base import ESCAVADOR_API_KEY
        
        if not ESCAVADOR_API_KEY:
            raise HTTPException(status_code=500, detail="ESCAVADOR_API_KEY não configurada")
        
        client = EscavadorClient(api_key=ESCAVADOR_API_KEY)
        return await client.get_detailed_process_movements(cnj, limit)
    
    async def _save_to_redis(self, cnj: str, data: Dict[str, Any]) -> bool:
        """Salva dados no Redis com TTL."""
        try:
            redis_key = f"process_movements:{cnj}"
            
            # Adicionar timestamp de cache
            cache_data = data.copy()
            cache_data['cached_at'] = datetime.now().isoformat()
            cache_data['cache_source'] = 'redis'
            
            await redis_service.set_json(redis_key, cache_data, self.redis_ttl_seconds)
            return True
            
        except Exception as e:
            logger.error(f"Erro ao salvar no Redis para CNJ {cnj}: {e}")
            return False
    
    async def _save_to_database(self, cnj: str, data: Dict[str, Any]) -> bool:
        """Salva dados no banco PostgreSQL."""
        try:
            from routes.process_movements import MovementClassifier
            classifier = MovementClassifier()
            
            async with get_database() as db:
                # Salvar cada movimentação individual
                movements = data.get('movements', [])
                
                for movement in movements:
                    movement_date = None
                    if movement.get('date'):
                        try:
                            movement_date = datetime.fromisoformat(movement['date'].replace('Z', '+00:00'))
                        except:
                            movement_date = None
                    
                    await db.execute("""
                        INSERT INTO process_movements (
                            cnj, movement_data, movement_type, movement_date,
                            content, source_tribunal, source_grau,
                            classification_confidence, fetched_from_api_at
                        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
                        ON CONFLICT (cnj, content, movement_date) DO UPDATE SET
                            movement_data = EXCLUDED.movement_data,
                            fetched_from_api_at = NOW()
                    """, 
                    cnj,
                    json.dumps(movement),
                    movement.get('type', 'OUTROS'),
                    movement_date,
                    movement.get('full_content', movement.get('description', '')),
                    movement.get('source', {}).get('tribunal', 'N/A'),
                    movement.get('source', {}).get('grau', 'N/A'),
                    0.8  # confidence padrão
                    )
            
            return True
            
        except Exception as e:
            logger.error(f"Erro ao salvar no banco para CNJ {cnj}: {e}")
            return False
    
    async def _get_status_from_database(self, cnj: str) -> Optional[Dict[str, Any]]:
        """Busca status agregado do banco."""
        try:
            async with get_database() as db:
                status = await db.fetchrow("""
                    SELECT * FROM process_status_cache 
                    WHERE cnj = $1 AND cache_valid_until > NOW()
                """, cnj)
                
                if status:
                    return {
                        "current_phase": status['current_phase'],
                        "description": status['description'],
                        "progress_percentage": float(status['progress_percentage']),
                        "outcome": status['outcome'],
                        "cnj": cnj,
                        "total_movements": status['total_movements'],
                        "last_update": status['last_movement_date'],
                        "tribunal_info": {
                            "name": status['tribunal_name'],
                            "grau": status['tribunal_grau']
                        },
                        "cached_at": status['last_api_sync'].isoformat()
                    }
                    
        except Exception as e:
            logger.error(f"Erro ao buscar status no banco para CNJ {cnj}: {e}")
        
        return None
    
    async def _save_status_to_database(
        self, 
        cnj: str, 
        status_data: Dict[str, Any],
        source: str
    ) -> bool:
        """Salva status agregado no banco."""
        try:
            async with get_database() as db:
                await db.execute("""
                    INSERT INTO process_status_cache (
                        cnj, current_phase, description, progress_percentage,
                        outcome, total_movements, last_movement_date,
                        tribunal_name, tribunal_grau, last_api_sync,
                        cache_valid_until, sync_status
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW() + INTERVAL '24 hours', $10)
                    ON CONFLICT (cnj) DO UPDATE SET
                        current_phase = EXCLUDED.current_phase,
                        description = EXCLUDED.description,
                        progress_percentage = EXCLUDED.progress_percentage,
                        outcome = EXCLUDED.outcome,
                        total_movements = EXCLUDED.total_movements,
                        last_movement_date = EXCLUDED.last_movement_date,
                        tribunal_name = EXCLUDED.tribunal_name,
                        tribunal_grau = EXCLUDED.tribunal_grau,
                        last_api_sync = NOW(),
                        cache_valid_until = NOW() + INTERVAL '24 hours',
                        sync_status = EXCLUDED.sync_status,
                        updated_at = NOW()
                """,
                cnj,
                status_data.get('current_phase', 'Em Andamento'),
                status_data.get('description', ''),
                status_data.get('progress_percentage', 0.0),
                status_data.get('outcome', 'andamento'),
                status_data.get('total_movements', 0),
                status_data.get('last_update'),
                status_data.get('tribunal_info', {}).get('name', 'N/A'),
                status_data.get('tribunal_info', {}).get('grau', 'N/A'),
                'success' if source == 'api' else 'cached'
                )
            
            return True
            
        except Exception as e:
            logger.error(f"Erro ao salvar status no banco para CNJ {cnj}: {e}")
            return False
    
    async def _generate_status_from_movements(self, movements_data: Dict[str, Any]) -> Dict[str, Any]:
        """Gera status agregado baseado nas movimentações."""
        # Reutilizar lógica do escavador_integration.py
        from services.escavador_integration import EscavadorClient
        
        # Criar instância temporária para usar o método de geração de status
        client = EscavadorClient(api_key="dummy")  # API key não será usada aqui
        
        # Simular dados para geração de status
        return {
            "current_phase": movements_data.get('current_phase', 'Em Andamento'),
            "description": f"Processo {movements_data.get('cnj')} com {movements_data.get('total_movements', 0)} movimentações.",
            "progress_percentage": 50.0,  # Calcular baseado nos tipos de movimentação
            "outcome": movements_data.get('outcome', 'andamento'),
            "phases": [],  # Seria gerado baseado nas movimentações
            "cnj": movements_data.get('cnj'),
            "tribunal": movements_data.get('tribunal_info', {}),
            "total_movements": movements_data.get('total_movements', 0),
            "last_update": movements_data.get('movements', [{}])[0].get('date') if movements_data.get('movements') else None
        }
    
    def _is_data_fresh(self, cached_at: str, hours: int = 24) -> bool:
        """Verifica se os dados cached ainda estão frescos."""
        try:
            cached_time = datetime.fromisoformat(cached_at.replace('Z', '+00:00'))
            expiry_time = cached_time + timedelta(hours=hours)
            return datetime.now().replace(tzinfo=cached_time.tzinfo) < expiry_time
        except:
            return False

# Instância global do serviço
process_cache_service = ProcessCacheService() 
# -*- coding: utf-8 -*-
"""
services/process_cache_service.py

Serviço de cache inteligente para movimentações processuais.
Implementa estratégia de cache em múltiplas camadas: Redis + PostgreSQL.
"""

import asyncio
import json
import logging
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

from fastapi import HTTPException

from services.redis_service import redis_service
from config.database import get_database

logger = logging.getLogger(__name__)

class ProcessCacheService:
    """
    Gerencia cache inteligente de movimentações processuais.
    
    Estratégia de cache em camadas:
    1. Redis (TTL: 1-8 horas) - Acesso ultra-rápido
    2. PostgreSQL (TTL: 7 dias) - Persistência e funcionamento offline  
    3. API Escavador - Fonte original quando cache expirado
    """
    
    def __init__(self):
        self.redis_ttl_seconds = 3600  # 1 hora no Redis
        self.db_ttl_hours = 24  # 24 horas no banco considera válido
        self.db_max_age_days = 7  # 7 dias máximo no banco
        
    async def get_process_movements_cached(
        self, 
        cnj: str, 
        limit: int = 50,
        force_refresh: bool = False
    ) -> Tuple[Dict[str, Any], str]:
        """
        Obtém movimentações de um processo usando cache inteligente.
        
        Returns:
            Tuple[dados, fonte] onde fonte é 'redis', 'database' ou 'api'
        """
        logger.info(f"Buscando movimentações cached para CNJ: {cnj}")
        
        if not force_refresh:
            # 1. Tentar Redis primeiro (mais rápido)
            redis_data = await self._get_from_redis(cnj)
            if redis_data:
                logger.info(f"Cache hit Redis para CNJ: {cnj}")
                return redis_data, "redis"
            
            # 2. Tentar banco de dados (funcionamento offline)
            db_data = await self._get_from_database(cnj, limit)
            if db_data:
                logger.info(f"Cache hit database para CNJ: {cnj}")
                # Salvar no Redis para próximas consultas
                await self._save_to_redis(cnj, db_data)
                return db_data, "database"
        
        # 3. Buscar na API Escavador (dados frescos)
        try:
            api_data = await self._fetch_from_api(cnj, limit)
            if api_data:
                logger.info(f"Dados obtidos da API Escavador para CNJ: {cnj}")
                
                # Salvar em ambos os caches
                await asyncio.gather(
                    self._save_to_redis(cnj, api_data),
                    self._save_to_database(cnj, api_data)
                )
                
                return api_data, "api"
                
        except Exception as e:
            logger.error(f"Erro ao buscar dados da API para CNJ {cnj}: {e}")
            
            # Se API falhou, tentar dados antigos do banco como fallback
            db_fallback = await self._get_from_database(cnj, limit, include_expired=True)
            if db_fallback:
                logger.warning(f"Usando dados antigos do banco para CNJ {cnj} (API indisponível)")
                return db_fallback, "database_fallback"
        
        raise HTTPException(
            status_code=404, 
            detail=f"Nenhum dado encontrado para o processo {cnj} e API indisponível"
        )
    
    async def get_process_status_cached(
        self, 
        cnj: str,
        force_refresh: bool = False
    ) -> Tuple[Dict[str, Any], str]:
        """
        Obtém status agregado de um processo usando cache.
        
        Returns:
            Tuple[status_data, fonte]
        """
        logger.info(f"Buscando status cached para CNJ: {cnj}")
        
        if not force_refresh:
            # 1. Verificar cache de status no banco
            cached_status = await self._get_status_from_database(cnj)
            if cached_status:
                logger.info(f"Status cache hit para CNJ: {cnj}")
                return cached_status, "database"
        
        # 2. Gerar status baseado nas movimentações cached/atuais
        movements_data, movements_source = await self.get_process_movements_cached(
            cnj, limit=20, force_refresh=force_refresh
        )
        
        # 3. Gerar status agregado
        status_data = await self._generate_status_from_movements(movements_data)
        
        # 4. Salvar status no cache
        await self._save_status_to_database(cnj, status_data, movements_source)
        
        return status_data, movements_source
    
    async def invalidate_cache(self, cnj: str) -> bool:
        """Remove dados do cache para forçar atualização."""
        try:
            # Remover do Redis
            redis_key = f"process_movements:{cnj}"
            await redis_service.delete(redis_key)
            
            # Marcar como expirado no banco (não remove, para histórico)
            async with get_database() as db:
                await db.execute("""
                    UPDATE process_status_cache 
                    SET cache_valid_until = NOW() - INTERVAL '1 hour',
                        sync_status = 'invalidated'
                    WHERE cnj = $1
                """, cnj)
            
            logger.info(f"Cache invalidado para CNJ: {cnj}")
            return True
            
        except Exception as e:
            logger.error(f"Erro ao invalidar cache para CNJ {cnj}: {e}")
            return False
    
    async def _get_from_redis(self, cnj: str) -> Optional[Dict[str, Any]]:
        """Busca dados no Redis."""
        try:
            redis_key = f"process_movements:{cnj}"
            data = await redis_service.get_json(redis_key)
            
            if data and self._is_data_fresh(data.get('cached_at', ''), hours=1):
                return data
                
        except Exception as e:
            logger.error(f"Erro ao buscar no Redis para CNJ {cnj}: {e}")
        
        return None
    
    async def _get_from_database(
        self, 
        cnj: str, 
        limit: int = 50,
        include_expired: bool = False
    ) -> Optional[Dict[str, Any]]:
        """Busca dados no banco PostgreSQL."""
        try:
            async with get_database() as db:
                # Buscar movimentações
                where_clause = "cnj = $1"
                params = [cnj]
                
                if not include_expired:
                    where_clause += " AND fetched_from_api_at > $2"
                    params.append(datetime.now() - timedelta(hours=self.db_ttl_hours))
                
                movements = await db.fetch(f"""
                    SELECT * FROM process_movements 
                    WHERE {where_clause}
                    ORDER BY movement_date DESC 
                    LIMIT $3
                """, *params, limit)
                
                if not movements:
                    return None
                
                # Converter para formato esperado
                processed_movements = []
                for mov in movements:
                    processed_movements.append({
                        "id": str(mov['id']),
                        "name": mov['movement_data'].get('name', ''),
                        "description": mov['content'][:200] + "..." if len(mov['content']) > 200 else mov['content'],
                        "full_content": mov['content'],
                        "type": mov['movement_type'],
                        "icon": mov['movement_data'].get('icon', '📋'),
                        "color": mov['movement_data'].get('color', '#6B7280'),
                        "date": mov['movement_date'],
                        "source": {
                            "tribunal": mov['source_tribunal'],
                            "grau": mov['source_grau']
                        },
                        "is_completed": True,
                        "is_current": False,
                        "completed_at": mov['movement_date'],
                        "documents": []
                    })
                
                # Marcar o primeiro como atual
                if processed_movements:
                    processed_movements[0]["is_current"] = True
                
                return {
                    "cnj": cnj,
                    "total_movements": len(processed_movements),
                    "shown_movements": len(processed_movements),
                    "movements": processed_movements,
                    "cached_at": movements[0]['fetched_from_api_at'].isoformat(),
                    "cache_source": "database"
                }
                
        except Exception as e:
            logger.error(f"Erro ao buscar no banco para CNJ {cnj}: {e}")
        
        return None
    
    async def _fetch_from_api(self, cnj: str, limit: int) -> Dict[str, Any]:
        """Busca dados frescos da API Escavador."""
        from services.escavador_integration import EscavadorClient
        from config.base import ESCAVADOR_API_KEY
        
        if not ESCAVADOR_API_KEY:
            raise HTTPException(status_code=500, detail="ESCAVADOR_API_KEY não configurada")
        
        client = EscavadorClient(api_key=ESCAVADOR_API_KEY)
        return await client.get_detailed_process_movements(cnj, limit)
    
    async def _save_to_redis(self, cnj: str, data: Dict[str, Any]) -> bool:
        """Salva dados no Redis com TTL."""
        try:
            redis_key = f"process_movements:{cnj}"
            
            # Adicionar timestamp de cache
            cache_data = data.copy()
            cache_data['cached_at'] = datetime.now().isoformat()
            cache_data['cache_source'] = 'redis'
            
            await redis_service.set_json(redis_key, cache_data, self.redis_ttl_seconds)
            return True
            
        except Exception as e:
            logger.error(f"Erro ao salvar no Redis para CNJ {cnj}: {e}")
            return False
    
    async def _save_to_database(self, cnj: str, data: Dict[str, Any]) -> bool:
        """Salva dados no banco PostgreSQL."""
        try:
            from routes.process_movements import MovementClassifier
            classifier = MovementClassifier()
            
            async with get_database() as db:
                # Salvar cada movimentação individual
                movements = data.get('movements', [])
                
                for movement in movements:
                    movement_date = None
                    if movement.get('date'):
                        try:
                            movement_date = datetime.fromisoformat(movement['date'].replace('Z', '+00:00'))
                        except:
                            movement_date = None
                    
                    await db.execute("""
                        INSERT INTO process_movements (
                            cnj, movement_data, movement_type, movement_date,
                            content, source_tribunal, source_grau,
                            classification_confidence, fetched_from_api_at
                        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
                        ON CONFLICT (cnj, content, movement_date) DO UPDATE SET
                            movement_data = EXCLUDED.movement_data,
                            fetched_from_api_at = NOW()
                    """, 
                    cnj,
                    json.dumps(movement),
                    movement.get('type', 'OUTROS'),
                    movement_date,
                    movement.get('full_content', movement.get('description', '')),
                    movement.get('source', {}).get('tribunal', 'N/A'),
                    movement.get('source', {}).get('grau', 'N/A'),
                    0.8  # confidence padrão
                    )
            
            return True
            
        except Exception as e:
            logger.error(f"Erro ao salvar no banco para CNJ {cnj}: {e}")
            return False
    
    async def _get_status_from_database(self, cnj: str) -> Optional[Dict[str, Any]]:
        """Busca status agregado do banco."""
        try:
            async with get_database() as db:
                status = await db.fetchrow("""
                    SELECT * FROM process_status_cache 
                    WHERE cnj = $1 AND cache_valid_until > NOW()
                """, cnj)
                
                if status:
                    return {
                        "current_phase": status['current_phase'],
                        "description": status['description'],
                        "progress_percentage": float(status['progress_percentage']),
                        "outcome": status['outcome'],
                        "cnj": cnj,
                        "total_movements": status['total_movements'],
                        "last_update": status['last_movement_date'],
                        "tribunal_info": {
                            "name": status['tribunal_name'],
                            "grau": status['tribunal_grau']
                        },
                        "cached_at": status['last_api_sync'].isoformat()
                    }
                    
        except Exception as e:
            logger.error(f"Erro ao buscar status no banco para CNJ {cnj}: {e}")
        
        return None
    
    async def _save_status_to_database(
        self, 
        cnj: str, 
        status_data: Dict[str, Any],
        source: str
    ) -> bool:
        """Salva status agregado no banco."""
        try:
            async with get_database() as db:
                await db.execute("""
                    INSERT INTO process_status_cache (
                        cnj, current_phase, description, progress_percentage,
                        outcome, total_movements, last_movement_date,
                        tribunal_name, tribunal_grau, last_api_sync,
                        cache_valid_until, sync_status
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW() + INTERVAL '24 hours', $10)
                    ON CONFLICT (cnj) DO UPDATE SET
                        current_phase = EXCLUDED.current_phase,
                        description = EXCLUDED.description,
                        progress_percentage = EXCLUDED.progress_percentage,
                        outcome = EXCLUDED.outcome,
                        total_movements = EXCLUDED.total_movements,
                        last_movement_date = EXCLUDED.last_movement_date,
                        tribunal_name = EXCLUDED.tribunal_name,
                        tribunal_grau = EXCLUDED.tribunal_grau,
                        last_api_sync = NOW(),
                        cache_valid_until = NOW() + INTERVAL '24 hours',
                        sync_status = EXCLUDED.sync_status,
                        updated_at = NOW()
                """,
                cnj,
                status_data.get('current_phase', 'Em Andamento'),
                status_data.get('description', ''),
                status_data.get('progress_percentage', 0.0),
                status_data.get('outcome', 'andamento'),
                status_data.get('total_movements', 0),
                status_data.get('last_update'),
                status_data.get('tribunal_info', {}).get('name', 'N/A'),
                status_data.get('tribunal_info', {}).get('grau', 'N/A'),
                'success' if source == 'api' else 'cached'
                )
            
            return True
            
        except Exception as e:
            logger.error(f"Erro ao salvar status no banco para CNJ {cnj}: {e}")
            return False
    
    async def _generate_status_from_movements(self, movements_data: Dict[str, Any]) -> Dict[str, Any]:
        """Gera status agregado baseado nas movimentações."""
        # Reutilizar lógica do escavador_integration.py
        from services.escavador_integration import EscavadorClient
        
        # Criar instância temporária para usar o método de geração de status
        client = EscavadorClient(api_key="dummy")  # API key não será usada aqui
        
        # Simular dados para geração de status
        return {
            "current_phase": movements_data.get('current_phase', 'Em Andamento'),
            "description": f"Processo {movements_data.get('cnj')} com {movements_data.get('total_movements', 0)} movimentações.",
            "progress_percentage": 50.0,  # Calcular baseado nos tipos de movimentação
            "outcome": movements_data.get('outcome', 'andamento'),
            "phases": [],  # Seria gerado baseado nas movimentações
            "cnj": movements_data.get('cnj'),
            "tribunal": movements_data.get('tribunal_info', {}),
            "total_movements": movements_data.get('total_movements', 0),
            "last_update": movements_data.get('movements', [{}])[0].get('date') if movements_data.get('movements') else None
        }
    
    def _is_data_fresh(self, cached_at: str, hours: int = 24) -> bool:
        """Verifica se os dados cached ainda estão frescos."""
        try:
            cached_time = datetime.fromisoformat(cached_at.replace('Z', '+00:00'))
            expiry_time = cached_time + timedelta(hours=hours)
            return datetime.now().replace(tzinfo=cached_time.tzinfo) < expiry_time
        except:
            return False

# Instância global do serviço
process_cache_service = ProcessCacheService() 