import logging
import os
import uuid
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

from redis_service import redis_service

logger = logging.getLogger(__name__)

# Configurações TTL
DEFAULT_TTL = int(os.getenv("REDIS_CONVERSATION_TTL", "86400"))  # 24 horas
ORCHESTRATION_TTL = int(os.getenv("REDIS_ORCHESTRATION_TTL", "86400"))  # 24 horas


class ConversationStateManager:
    """Gerencia estado de conversas no Redis."""

    def __init__(self):
        self.conversation_prefix = "conversation:"
        self.orchestration_prefix = "orchestration:"
        self.default_ttl = DEFAULT_TTL

    # ========== CONVERSAS ==========

    async def save_conversation_state(
        self,
        case_id: str,
        state: Dict[str, Any],
        ttl: Optional[int] = None
    ) -> bool:
        """Salva estado da conversa."""
        try:
            key = f"{self.conversation_prefix}{case_id}"

            # Adicionar metadados
            state["_metadata"] = {
                "case_id": case_id,
                "updated_at": datetime.now().isoformat(),
                "version": "1.0"
            }

            return await redis_service.set_json(
                key,
                state,
                ttl or self.default_ttl
            )

        except Exception as e:
            logger.error(f"Erro ao salvar conversa {case_id}: {e}")
            return False

    async def get_conversation_state(self, case_id: str) -> Optional[Dict[str, Any]]:
        """Recupera estado da conversa."""
        try:
            key = f"{self.conversation_prefix}{case_id}"
            state = await redis_service.get_json(key)

            if state:
                # Remover metadados internos
                state.pop("_metadata", None)

            return state

        except Exception as e:
            logger.error(f"Erro ao recuperar conversa {case_id}: {e}")
            return None

    async def delete_conversation_state(self, case_id: str) -> bool:
        """Remove estado da conversa."""
        try:
            key = f"{self.conversation_prefix}{case_id}"
            return await redis_service.delete(key)

        except Exception as e:
            logger.error(f"Erro ao deletar conversa {case_id}: {e}")
            return False

    async def conversation_exists(self, case_id: str) -> bool:
        """Verifica se conversa existe."""
        key = f"{self.conversation_prefix}{case_id}"
        return await redis_service.exists(key)

    async def extend_conversation_ttl(self, case_id: str, ttl: int) -> bool:
        """Estende TTL da conversa."""
        key = f"{self.conversation_prefix}{case_id}"
        return await redis_service.set_ttl(key, ttl)

    async def list_active_conversations(self) -> List[Dict[str, Any]]:
        """Lista todas as conversas ativas."""
        try:
            pattern = f"{self.conversation_prefix}*"
            keys = await redis_service.get_keys_pattern(pattern)

            conversations = []
            for key in keys:
                case_id = key.replace(self.conversation_prefix, "")
                state = await redis_service.get_json(key)

                if state:
                    metadata = state.get("_metadata", {})
                    conversations.append({
                        "case_id": case_id,
                        "updated_at": metadata.get("updated_at"),
                        "ttl": await redis_service.get_ttl(key)
                    })

            return conversations

        except Exception as e:
            logger.error(f"Erro ao listar conversas: {e}")
            return []

    # ========== ORQUESTRAÇÕES ==========

    async def save_orchestration_state(
        self,
        case_id: str,
        state: Dict[str, Any],
        ttl: Optional[int] = None
    ) -> bool:
        """Salva estado da orquestração."""
        try:
            key = f"{self.orchestration_prefix}{case_id}"

            # Adicionar metadados
            state["_metadata"] = {
                "case_id": case_id,
                "updated_at": datetime.now().isoformat(),
                "version": "1.0"
            }

            return await redis_service.set_json(
                key,
                state,
                ttl or ORCHESTRATION_TTL
            )

        except Exception as e:
            logger.error(f"Erro ao salvar orquestração {case_id}: {e}")
            return False

    async def get_orchestration_state(self, case_id: str) -> Optional[Dict[str, Any]]:
        """Recupera estado da orquestração."""
        try:
            key = f"{self.orchestration_prefix}{case_id}"
            state = await redis_service.get_json(key)

            if state:
                # Remover metadados internos
                state.pop("_metadata", None)

            return state

        except Exception as e:
            logger.error(f"Erro ao recuperar orquestração {case_id}: {e}")
            return None

    async def delete_orchestration_state(self, case_id: str) -> bool:
        """Remove estado da orquestração."""
        try:
            key = f"{self.orchestration_prefix}{case_id}"
            return await redis_service.delete(key)

        except Exception as e:
            logger.error(f"Erro ao deletar orquestração {case_id}: {e}")
            return False

    async def orchestration_exists(self, case_id: str) -> bool:
        """Verifica se orquestração existe."""
        key = f"{self.orchestration_prefix}{case_id}"
        return await redis_service.exists(key)

    def is_orchestration_active(self, case_id: str) -> bool:
        """Verifica se orquestração está ativa (método síncrono para compatibilidade)."""
        try:
            import asyncio

            # Usar get_event_loop() para compatibilidade com loops existentes
            loop = asyncio.get_event_loop()
            if loop.is_running():
                # Se já estamos em um loop, criar uma task
                return False  # Fallback seguro
            else:
                return loop.run_until_complete(self.orchestration_exists(case_id))
        except Exception as e:
            logger.error(f"Erro ao verificar orquestração ativa {case_id}: {e}")
            return False

    async def list_active_orchestrations(self) -> List[Dict[str, Any]]:
        """Lista todas as orquestrações ativas."""
        try:
            pattern = f"{self.orchestration_prefix}*"
            keys = await redis_service.get_keys_pattern(pattern)

            orchestrations = []
            for key in keys:
                case_id = key.replace(self.orchestration_prefix, "")
                state = await redis_service.get_json(key)

                if state:
                    metadata = state.get("_metadata", {})
                    orchestrations.append({
                        "case_id": case_id,
                        "updated_at": metadata.get("updated_at"),
                        "status": state.get("status", "unknown"),
                        "ttl": await redis_service.get_ttl(key)
                    })

            return orchestrations

        except Exception as e:
            logger.error(f"Erro ao listar orquestrações: {e}")
            return []

    def remove_orchestration(self, case_id: str) -> bool:
        """Remove orquestração da memória (método síncrono para compatibilidade)."""
        try:
            import asyncio

            # Usar get_event_loop() para compatibilidade com loops existentes
            loop = asyncio.get_event_loop()
            if loop.is_running():
                # Se já estamos em um loop, criar uma task
                task = asyncio.create_task(self.delete_orchestration_state(case_id))
                return True  # Retorna True otimisticamente
            else:
                return loop.run_until_complete(self.delete_orchestration_state(case_id))
        except Exception as e:
            logger.error(f"Erro ao remover orquestração {case_id}: {e}")
            return False

    # ========== UTILITÁRIOS ==========

    async def cleanup_expired_conversations(self) -> Dict[str, int]:
        """Remove conversas expiradas."""
        try:
            conv_pattern = f"{self.conversation_prefix}*"
            orch_pattern = f"{self.orchestration_prefix}*"

            conv_cleaned = await redis_service.cleanup_expired(conv_pattern)
            orch_cleaned = await redis_service.cleanup_expired(orch_pattern)

            return {
                "conversations_cleaned": conv_cleaned,
                "orchestrations_cleaned": orch_cleaned,
                "total_cleaned": conv_cleaned + orch_cleaned
            }

        except Exception as e:
            logger.error(f"Erro na limpeza: {e}")
            return {"conversations_cleaned": 0,
                    "orchestrations_cleaned": 0, "total_cleaned": 0}

    async def get_system_stats(self) -> Dict[str, Any]:
        """Obtém estatísticas do sistema."""
        try:
            conv_pattern = f"{self.conversation_prefix}*"
            orch_pattern = f"{self.orchestration_prefix}*"

            conv_keys = await redis_service.get_keys_pattern(conv_pattern)
            orch_keys = await redis_service.get_keys_pattern(orch_pattern)

            redis_health = await redis_service.health_check()

            return {
                "active_conversations": len(conv_keys),
                "active_orchestrations": len(orch_keys),
                "redis_health": redis_health,
                "timestamp": datetime.now().isoformat()
            }

        except Exception as e:
            logger.error(f"Erro ao obter estatísticas: {e}")
            return {}

    async def migrate_memory_to_redis(
            self, memory_data: Dict[str, Any]) -> Dict[str, int]:
        """Migra dados da memória para Redis."""
        try:
            migrated_conversations = 0
            migrated_orchestrations = 0

            # Migrar conversas se existirem
            conversations = memory_data.get("conversations", {})
            for case_id, state in conversations.items():
                success = await self.save_conversation_state(case_id, state)
                if success:
                    migrated_conversations += 1
                    logger.info(f"Conversa migrada: {case_id}")
                else:
                    logger.error(f"Erro ao migrar conversa: {case_id}")

            # Migrar orquestrações se existirem
            orchestrations = memory_data.get("orchestrations", {})
            for case_id, state in orchestrations.items():
                success = await self.save_orchestration_state(case_id, state)
                if success:
                    migrated_orchestrations += 1
                    logger.info(f"Orquestração migrada: {case_id}")
                else:
                    logger.error(f"Erro ao migrar orquestração: {case_id}")

            return {
                "conversations_migrated": migrated_conversations,
                "orchestrations_migrated": migrated_orchestrations,
                "total_migrated": migrated_conversations + migrated_orchestrations
            }

        except Exception as e:
            logger.error(f"Erro na migração: {e}")
            return {"conversations_migrated": 0,
                    "orchestrations_migrated": 0, "total_migrated": 0}


# Instância global
conversation_state_manager = ConversationStateManager()
