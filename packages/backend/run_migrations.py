#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Database Migration Runner - Partnership Growth Plan
==================================================

Script para executar as migrations do sistema de parcerias de forma segura.
"""

import asyncio
import os
import sys
from pathlib import Path
from datetime import datetime

# Adicionar path do backend
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

try:
    from sqlalchemy.ext.asyncio import create_async_engine
    from sqlalchemy import text
    import logging
except ImportError as e:
    print(f"❌ Erro de importação: {e}")
    print("Instale as dependências: pip install sqlalchemy[asyncio] asyncpg")
    sys.exit(1)

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class MigrationRunner:
    """Executor de migrations do banco de dados."""
    
    def __init__(self, database_url: str = None):
        self.database_url = database_url or os.getenv(
            "DATABASE_URL", 
            "postgresql+asyncpg://localhost/litig"
        )
        self.engine = None
        self.migration_file = backend_dir / "migrations" / "add_partnership_tables.sql"
    
    async def connect(self):
        """Conecta ao banco de dados."""
        try:
            self.engine = create_async_engine(self.database_url, echo=False)
            
            # Testar conexão
            async with self.engine.begin() as conn:
                await conn.execute(text("SELECT 1"))
            
            logger.info("✅ Conexão com banco de dados estabelecida")
            return True
            
        except Exception as e:
            logger.error(f"❌ Erro ao conectar ao banco: {e}")
            return False
    
    async def run_migration(self):
        """Executa a migration principal."""
        
        logger.info("🚀 Iniciando migration do Partnership Growth Plan...")
        
        if not await self.connect():
            return False
        
        if not self.migration_file.exists():
            logger.error(f"❌ Arquivo de migration não encontrado: {self.migration_file}")
            return False
        
        try:
            # Ler arquivo de migration
            with open(self.migration_file, 'r', encoding='utf-8') as f:
                migration_sql = f.read()
            
            logger.info(f"📄 Migration carregada: {self.migration_file.name}")
            logger.info(f"📊 Tamanho: {len(migration_sql)} caracteres")
            
            # Executar migration
            async with self.engine.begin() as conn:
                logger.info("⚡ Executando migration...")
                
                # Executar SQL
                await conn.execute(text(migration_sql))
                
                logger.info("✅ Migration executada com sucesso!")
            
            # Verificar resultado
            await self.verify_migration()
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Erro durante migration: {e}")
            return False
        
        finally:
            if self.engine:
                await self.engine.dispose()
    
    async def verify_migration(self):
        """Verifica se a migration foi aplicada corretamente."""
        
        logger.info("🔍 Verificando resultados da migration...")
        
        try:
            async with self.engine.begin() as conn:
                # Verificar tabelas criadas
                tables_query = text("""
                    SELECT table_name 
                    FROM information_schema.tables 
                    WHERE table_schema = 'public' 
                    AND table_name IN ('partnership_invitations', 'lawyer_engagement_history', 'job_execution_logs')
                    ORDER BY table_name
                """)
                
                result = await conn.execute(tables_query)
                tables = [row.table_name for row in result.fetchall()]
                
                expected_tables = ['job_execution_logs', 'lawyer_engagement_history', 'partnership_invitations']
                
                logger.info(f"📋 Tabelas encontradas: {', '.join(tables)}")
                
                if set(tables) == set(expected_tables):
                    logger.info("✅ Todas as tabelas foram criadas corretamente!")
                else:
                    missing = set(expected_tables) - set(tables)
                    if missing:
                        logger.warning(f"⚠️  Tabelas faltando: {', '.join(missing)}")
                
                # Verificar campos adicionados na tabela lawyers
                lawyers_fields_query = text("""
                    SELECT column_name 
                    FROM information_schema.columns 
                    WHERE table_name = 'lawyers' 
                    AND column_name IN ('interaction_score', 'engagement_trend', 'engagement_updated_at')
                    ORDER BY column_name
                """)
                
                result = await conn.execute(lawyers_fields_query)
                fields = [row.column_name for row in result.fetchall()]
                
                expected_fields = ['engagement_trend', 'engagement_updated_at', 'interaction_score']
                
                logger.info(f"📋 Campos em lawyers: {', '.join(fields)}")
                
                if set(fields) == set(expected_fields):
                    logger.info("✅ Todos os campos de engajamento foram adicionados!")
                else:
                    missing = set(expected_fields) - set(fields)
                    if missing:
                        logger.warning(f"⚠️  Campos faltando em lawyers: {', '.join(missing)}")
                
                # Verificar seed data
                seed_query = text("""
                    SELECT COUNT(*) as count 
                    FROM job_execution_logs 
                    WHERE job_name = 'calculate_engagement_scores'
                """)
                
                result = await conn.execute(seed_query)
                count = result.fetchone().count
                
                if count > 0:
                    logger.info("✅ Seed data inserido corretamente!")
                else:
                    logger.warning("⚠️  Seed data não encontrado")
        
        except Exception as e:
            logger.error(f"❌ Erro na verificação: {e}")
    
    async def rollback_migration(self):
        """Rollback da migration (para desenvolvimento)."""
        
        logger.warning("🔄 Executando ROLLBACK da migration...")
        
        if not await self.connect():
            return False
        
        try:
            rollback_sql = """
            -- ROLLBACK: Partnership Growth Plan Migration
            
            -- Remover tabelas criadas
            DROP TABLE IF EXISTS partnership_invitations CASCADE;
            DROP TABLE IF EXISTS lawyer_engagement_history CASCADE;
            DROP TABLE IF EXISTS job_execution_logs CASCADE;
            
            -- Remover campos da tabela lawyers
            ALTER TABLE lawyers DROP COLUMN IF EXISTS interaction_score;
            ALTER TABLE lawyers DROP COLUMN IF EXISTS engagement_trend;
            ALTER TABLE lawyers DROP COLUMN IF EXISTS engagement_updated_at;
            
            -- Remover índices (se existirem)
            DROP INDEX IF EXISTS idx_lawyers_interaction_score;
            """
            
            async with self.engine.begin() as conn:
                await conn.execute(text(rollback_sql))
            
            logger.info("✅ Rollback executado com sucesso!")
            return True
            
        except Exception as e:
            logger.error(f"❌ Erro durante rollback: {e}")
            return False
        
        finally:
            if self.engine:
                await self.engine.dispose()


async def main():
    """Função principal."""
    
    print("🎯 LITIG Partnership Growth Plan - Database Migration")
    print("=" * 60)
    
    runner = MigrationRunner()
    
    # Verificar argumentos
    if len(sys.argv) > 1 and sys.argv[1] == "rollback":
        print("⚠️  MODO ROLLBACK - Isto irá REVERTER todas as alterações!")
        response = input("Tem certeza? Digite 'yes' para confirmar: ")
        if response.lower() == 'yes':
            success = await runner.rollback_migration()
        else:
            print("❌ Rollback cancelado pelo usuário")
            sys.exit(0)
    else:
        print("🚀 MODO MIGRATION - Aplicando alterações no banco...")
        success = await runner.run_migration()
    
    if success:
        print("\n✅ MIGRATION CONCLUÍDA COM SUCESSO!")
        print("📊 O sistema de parcerias está pronto para uso!")
        sys.exit(0)
    else:
        print("\n❌ MIGRATION FALHOU!")
        print("📋 Verifique os logs acima para detalhes do erro")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main()) 