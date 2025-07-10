#!/usr/bin/env python3
"""
Script para executar a sincronização de KPIs de advogados via API do Jusbrasil.

Este script pode ser executado manualmente ou via cron job para manter
a taxa de sucesso (`success_rate`) dos advogados sempre atualizada.
"""
import os
import sys
import logging
from datetime import datetime
import asyncio

# Adicionar o diretório raiz ao path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from backend.jobs.jusbrasil_sync import sync_all_lawyers

def setup_logging():
    """Configura logging para o script, com rotação de arquivos."""
    from logging.handlers import TimedRotatingFileHandler
    
    # Criar diretório de logs se não existir
    os.makedirs("logs", exist_ok=True)
    
    log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    
    # Handler para rotacionar logs diariamente
    handler = TimedRotatingFileHandler(
        'logs/jusbrasil_sync.log', 
        when="midnight", 
        interval=1, 
        backupCount=7
    )
    handler.setFormatter(logging.Formatter(log_format))
    
    # Configuração básica
    logging.basicConfig(
        level=logging.INFO,
        handlers=[handler, logging.StreamHandler(sys.stdout)]
    )

def main():
    """Função principal do script."""
    setup_logging()
    logger = logging.getLogger(__name__)
    
    logger.info("=" * 60)
    logger.info("INICIANDO SINCRONIZAÇÃO DE KPIS VIA JUSBRASIL")
    logger.info(f"Timestamp: {datetime.now().isoformat()}")
    logger.info("=" * 60)
    
    try:
        # Verificar variáveis de ambiente essenciais
        required_vars = ['SUPABASE_URL', 'SUPABASE_SERVICE_KEY', 'JUS_API_TOKEN']
        missing_vars = [var for var in required_vars if not os.getenv(var)]
        
        if missing_vars:
            logger.error(f"Variáveis de ambiente faltando: {', '.join(missing_vars)}")
            sys.exit(1)
        
        # Executar a sincronização assíncrona
        asyncio.run(sync_all_lawyers())
        
        logger.info("=" * 60)
        logger.info("SINCRONIZAÇÃO JUSBRASIL CONCLUÍDA COM SUCESSO")
        logger.info("=" * 60)
        
    except Exception as e:
        logger.error(f"ERRO CRÍTICO NA SINCRONIZAÇÃO: {e}")
        logger.exception("Detalhes do erro:")
        sys.exit(1)

if __name__ == "__main__":
    main() 