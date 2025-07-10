import asyncio
import json
import logging
from backend.services.conversation_state_manager import conversation_state_manager

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ==============================================================================
# ATENÇÃO: ESTE SCRIPT DEVE SER USADO COM CUIDADO EM PRODUÇÃO
# ==============================================================================
# Este script é projetado para uma migração única de dados em memória
# para o Redis. Ele assume que você tem um dump dos dicionários
# `active_conversations` e `active_orchestrations` em um arquivo JSON.

# Exemplo de formato do arquivo de dump (conversations.json):
# {
#   "conversations": {
#     "case_id_1": { ... estado da conversa ... },
#     "case_id_2": { ... estado da conversa ... }
#   },
#   "orchestrations": {
#     "case_id_1": { ... estado da orquestração ... },
#     "case_id_2": { ... estado da orquestração ... }
#   }
# }

async def migrate_from_json(file_path: str):
    """Migra dados de um arquivo JSON para o Redis."""
    logger.info(f"Iniciando migração do arquivo: {file_path}")
    
    try:
        with open(file_path, 'r') as f:
            data_to_migrate = json.load(f)
    except FileNotFoundError:
        logger.error(f"Arquivo de migração não encontrado: {file_path}")
        return
    except json.JSONDecodeError:
        logger.error(f"Erro ao decodificar JSON do arquivo: {file_path}")
        return

    result = await conversation_state_manager.migrate_memory_to_redis(data_to_migrate)

    logger.info("="*30)
    logger.info("RESULTADO DA MIGRAÇÃO")
    logger.info("="*30)
    logger.info(f"Conversas migradas: {result['conversations_migrated']}")
    logger.info(f"Orquestrações migradas: {result['orchestrations_migrated']}")
    logger.info(f"Total de itens migrados: {result['total_migrated']}")
    logger.info("="*30)

async def main():
    """Função principal para executar a migração."""
    # Defina o caminho para o arquivo de dump dos dados em memória
    dump_file = "memory_dump.json" 
    
    # Criar um arquivo de exemplo se não existir
    try:
        with open(dump_file, 'x') as f:
            json.dump({
                "conversations": {},
                "orchestrations": {}
            }, f)
            logger.info(f"Arquivo de exemplo '{dump_file}' criado. Adicione seus dados a ele.")
    except FileExistsError:
        pass

    await migrate_from_json(dump_file)

if __name__ == "__main__":
    logger.info("Iniciando o processo de migração para o Redis...")
    # Inicializa o serviço Redis antes de usar
    from backend.services.redis_service import redis_service
    
    async def run_migration_with_init():
        await redis_service.initialize()
        await main()

    asyncio.run(run_migration_with_init())
    logger.info("Migração finalizada.") 