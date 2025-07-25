#!/usr/bin/env python3
"""
Script para executar a migration de clusterização.
Executa o arquivo SQL 015_create_cluster_tables.sql no banco de dados.
"""

import asyncio
import asyncpg
import os
from pathlib import Path

async def run_cluster_migration():
    """Executa a migration de clusterização no banco."""
    
    # Obter URL do banco das variáveis de ambiente
    database_url = os.getenv(
        "DATABASE_URL",
        "postgresql://postgres:password@db.litgo.internal:5432/postgres"
    )
    
    # Remover prefixo asyncpg se presente
    if database_url.startswith("postgresql+asyncpg://"):
        database_url = database_url.replace("postgresql+asyncpg://", "postgresql://")
    
    print("🔄 Conectando ao banco de dados...")
    print(f"URL: {database_url.replace(database_url.split('@')[0].split('//')[1], '***')}")
    
    try:
        # Conectar ao banco
        conn = await asyncpg.connect(database_url)
        print("✅ Conectado ao banco com sucesso!")
        
        # Ler arquivo de migration
        migration_file = Path(__file__).parent / "migrations" / "015_create_cluster_tables.sql"
        
        if not migration_file.exists():
            print(f"❌ Arquivo de migration não encontrado: {migration_file}")
            return
        
        print(f"📖 Lendo migration: {migration_file}")
        migration_sql = migration_file.read_text(encoding='utf-8')
        
        print("🚀 Executando migration...")
        
        # Executar migration (pode conter múltiplos statements)
        await conn.execute(migration_sql)
        
        print("✅ Migration executada com sucesso!")
        
        # Verificar se as tabelas foram criadas
        print("\n🔍 Verificando tabelas criadas:")
        
        tables_to_check = [
            'case_embeddings',
            'lawyer_embeddings', 
            'case_clusters',
            'lawyer_clusters',
            'cluster_metadata',
            'case_cluster_labels',
            'lawyer_cluster_labels',
            'cluster_momentum_history',
            'partnership_recommendations'
        ]
        
        for table in tables_to_check:
            result = await conn.fetchval(
                "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = $1)",
                table
            )
            status = "✅" if result else "❌"
            print(f"  {status} {table}")
        
        print("\n🔍 Verificando funções RPC:")
        functions_to_check = [
            'get_cluster_texts',
            'get_trending_clusters',
            'calculate_vector_similarity'
        ]
        
        for func in functions_to_check:
            result = await conn.fetchval(
                "SELECT EXISTS (SELECT FROM pg_proc WHERE proname = $1)",
                func
            )
            status = "✅" if result else "❌"
            print(f"  {status} {func}")
        
        print("\n🔍 Verificando extensão pgvector:")
        result = await conn.fetchval(
            "SELECT EXISTS (SELECT FROM pg_extension WHERE extname = 'vector')"
        )
        status = "✅" if result else "❌"
        print(f"  {status} pgvector extension")
        
        await conn.close()
        print("\n🎉 Migration de clusterização concluída com sucesso!")
        
    except Exception as e:
        print(f"❌ Erro ao executar migration: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(run_cluster_migration()) 