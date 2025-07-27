#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Database Migration Demo - Partnership Growth Plan
================================================

Demo do sistema de migrations usando SQLite para demonstração.
"""

import asyncio
import os
import sys
import sqlite3
from pathlib import Path
from datetime import datetime
import logging

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class SQLiteMigrationDemo:
    """Demo de migration usando SQLite."""
    
    def __init__(self, db_path: str = "partnership_demo.db"):
        self.db_path = Path(db_path)
        self.conn = None
    
    def connect(self):
        """Conecta ao banco SQLite."""
        try:
            self.conn = sqlite3.connect(self.db_path)
            self.conn.row_factory = sqlite3.Row  # Para acessar colunas por nome
            logger.info(f"✅ Conectado ao banco SQLite: {self.db_path}")
            return True
        except Exception as e:
            logger.error(f"❌ Erro ao conectar ao SQLite: {e}")
            return False
    
    def run_migration_demo(self):
        """Executa a demo da migration."""
        
        logger.info("🚀 Iniciando DEMO da migration do Partnership Growth Plan...")
        
        if not self.connect():
            return False
        
        try:
            cursor = self.conn.cursor()
            
            # 1. Criar tabela partnership_invitations
            logger.info("📋 Criando tabela partnership_invitations...")
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS partnership_invitations (
                    id TEXT PRIMARY KEY,
                    token TEXT UNIQUE NOT NULL,
                    inviter_lawyer_id TEXT NOT NULL,
                    inviter_name TEXT NOT NULL,
                    invitee_name TEXT NOT NULL,
                    invitee_profile_url TEXT,
                    invitee_context TEXT,  -- JSON como TEXT no SQLite
                    area_expertise TEXT,
                    compatibility_score TEXT,
                    partnership_reason TEXT,
                    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired', 'cancelled')),
                    expires_at TIMESTAMP NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    accepted_at TIMESTAMP,
                    new_lawyer_id TEXT,
                    linkedin_message_template TEXT,
                    claim_url TEXT NOT NULL
                )
            """)
            
            # Índices para partnership_invitations
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_invitations_inviter ON partnership_invitations(inviter_lawyer_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_invitations_status ON partnership_invitations(status)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_invitations_token ON partnership_invitations(token)")
            
            logger.info("✅ Tabela partnership_invitations criada!")
            
            # 2. Criar tabela lawyers (demo)
            logger.info("📋 Criando tabela lawyers (demo)...")
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS lawyers (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    email TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    -- Campos de engajamento (novos)
                    interaction_score REAL DEFAULT 0.5,
                    engagement_trend TEXT,
                    engagement_updated_at TIMESTAMP
                )
            """)
            
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_lawyers_interaction_score ON lawyers(interaction_score DESC)")
            
            logger.info("✅ Tabela lawyers criada com campos de engajamento!")
            
            # 3. Criar tabela lawyer_engagement_history
            logger.info("📋 Criando tabela lawyer_engagement_history...")
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS lawyer_engagement_history (
                    id TEXT PRIMARY KEY,
                    lawyer_id TEXT NOT NULL,
                    iep_score REAL NOT NULL CHECK (iep_score >= 0.0 AND iep_score <= 1.0),
                    metrics_json TEXT,  -- JSON como TEXT
                    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_engagement_history_lawyer ON lawyer_engagement_history(lawyer_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_engagement_history_calculated ON lawyer_engagement_history(calculated_at DESC)")
            
            logger.info("✅ Tabela lawyer_engagement_history criada!")
            
            # 4. Criar tabela job_execution_logs
            logger.info("📋 Criando tabela job_execution_logs...")
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS job_execution_logs (
                    id TEXT PRIMARY KEY,
                    job_name TEXT NOT NULL,
                    metadata TEXT,  -- JSON como TEXT
                    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    status TEXT NOT NULL CHECK (status IN ('completed', 'error', 'up_to_date'))
                )
            """)
            
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_job_logs_name ON job_execution_logs(job_name)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_job_logs_executed ON job_execution_logs(executed_at DESC)")
            
            logger.info("✅ Tabela job_execution_logs criada!")
            
            # 5. Inserir dados de exemplo
            logger.info("📊 Inserindo dados de exemplo...")
            
            # Advogados de exemplo
            sample_lawyers = [
                ("lawyer_1", "Dr. João Silva", "joao@email.com", 0.8, "improving"),
                ("lawyer_2", "Dra. Maria Santos", "maria@email.com", 0.6, "stable"),
                ("lawyer_3", "Dr. Pedro Costa", "pedro@email.com", 0.9, "improving"),
            ]
            
            for lawyer_id, name, email, score, trend in sample_lawyers:
                cursor.execute("""
                    INSERT OR REPLACE INTO lawyers 
                    (id, name, email, interaction_score, engagement_trend, engagement_updated_at)
                    VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                """, (lawyer_id, name, email, score, trend))
            
            # Convite de exemplo
            cursor.execute("""
                INSERT OR REPLACE INTO partnership_invitations 
                (id, token, inviter_lawyer_id, inviter_name, invitee_name, 
                 area_expertise, compatibility_score, partnership_reason, 
                 expires_at, claim_url)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                "invite_1", "demo_token_12345", "lawyer_1", "Dr. João Silva",
                "Dr. Ana External", "Direito Empresarial", "85%", 
                "Complementa expertise em direito societário",
                "2025-08-26 00:00:00", "https://app.litig.com/invite/demo_token_12345"
            ))
            
            # Histórico de engagement
            cursor.execute("""
                INSERT OR REPLACE INTO lawyer_engagement_history 
                (id, lawyer_id, iep_score, metrics_json)
                VALUES (?, ?, ?, ?)
            """, (
                "history_1", "lawyer_1", 0.8, 
                '{"offers_received_30d": 15, "offers_accepted_30d": 12, "login_days_30d": 25}'
            ))
            
            # Log de job
            cursor.execute("""
                INSERT OR REPLACE INTO job_execution_logs 
                (id, job_name, metadata, status)
                VALUES (?, ?, ?, ?)
            """, (
                "job_1", "calculate_engagement_scores",
                '{"demo_setup": true, "total_lawyers": 3, "successful": 3}',
                "completed"
            ))
            
            self.conn.commit()
            logger.info("✅ Dados de exemplo inseridos!")
            
            # 6. Verificar resultados
            self.verify_demo()
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Erro durante migration demo: {e}")
            return False
        
        finally:
            if self.conn:
                self.conn.close()
    
    def verify_demo(self):
        """Verifica os resultados da demo."""
        
        logger.info("🔍 Verificando resultados da migration demo...")
        
        try:
            cursor = self.conn.cursor()
            
            # Verificar tabelas
            cursor.execute("""
                SELECT name FROM sqlite_master 
                WHERE type='table' AND name LIKE '%partnership%' OR name LIKE '%lawyer%' OR name LIKE '%job%'
                ORDER BY name
            """)
            tables = [row[0] for row in cursor.fetchall()]
            
            logger.info(f"📋 Tabelas criadas: {', '.join(tables)}")
            
            # Contar registros
            for table in tables:
                cursor.execute(f"SELECT COUNT(*) FROM {table}")
                count = cursor.fetchone()[0]
                logger.info(f"   📊 {table}: {count} registros")
            
            # Verificar campos de engajamento
            cursor.execute("PRAGMA table_info(lawyers)")
            columns = [col[1] for col in cursor.fetchall()]
            engagement_fields = [col for col in columns if col in ['interaction_score', 'engagement_trend', 'engagement_updated_at']]
            
            logger.info(f"📋 Campos de engajamento em lawyers: {', '.join(engagement_fields)}")
            
            # Mostrar dados de exemplo
            logger.info("📊 Exemplos de dados criados:")
            
            cursor.execute("SELECT name, interaction_score, engagement_trend FROM lawyers LIMIT 3")
            lawyers = cursor.fetchall()
            for lawyer in lawyers:
                logger.info(f"   👨‍💼 {lawyer[0]} - IEP: {lawyer[1]:.1f} ({lawyer[2]})")
            
            cursor.execute("SELECT inviter_name, invitee_name, compatibility_score FROM partnership_invitations LIMIT 1")
            invite = cursor.fetchone()
            if invite:
                logger.info(f"   📨 Convite: {invite[0]} → {invite[1]} (compat: {invite[2]})")
        
        except Exception as e:
            logger.error(f"❌ Erro na verificação: {e}")
    
    def show_schema(self):
        """Mostra o schema criado."""
        
        if not self.connect():
            return
        
        try:
            cursor = self.conn.cursor()
            
            print("\n" + "="*60)
            print("📋 SCHEMA DO BANCO DE DADOS (DEMO)")
            print("="*60)
            
            # Para cada tabela, mostrar estrutura
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
            tables = [row[0] for row in cursor.fetchall()]
            
            for table in tables:
                if table.startswith('sqlite_'):
                    continue
                    
                print(f"\n🏷️  TABELA: {table}")
                print("-" * 40)
                
                cursor.execute(f"PRAGMA table_info({table})")
                columns = cursor.fetchall()
                
                for col in columns:
                    col_name, col_type = col[1], col[2]
                    nullable = "NULL" if col[3] == 0 else "NOT NULL"
                    default = f" DEFAULT {col[4]}" if col[4] else ""
                    pk = " (PK)" if col[5] else ""
                    
                    print(f"   📄 {col_name:<25} {col_type:<15} {nullable}{default}{pk}")
        
        except Exception as e:
            logger.error(f"❌ Erro ao mostrar schema: {e}")
        
        finally:
            if self.conn:
                self.conn.close()


def main():
    """Função principal da demo."""
    
    print("🎯 LITIG Partnership Growth Plan - DEMO Migration")
    print("=" * 60)
    print("📝 Esta é uma demonstração usando SQLite local")
    print("📝 Em produção, seria usado PostgreSQL")
    print()
    
    demo = SQLiteMigrationDemo()
    
    if len(sys.argv) > 1 and sys.argv[1] == "schema":
        print("📋 Mostrando schema do banco...")
        demo.show_schema()
        return
    
    success = demo.run_migration_demo()
    
    if success:
        print("\n✅ DEMO MIGRATION CONCLUÍDA COM SUCESSO!")
        print("📊 O sistema de parcerias foi demonstrado!")
        print("💡 Execute 'python3 run_migrations_demo.py schema' para ver o schema")
        print(f"🗄️  Banco de dados salvo em: {demo.db_path}")
    else:
        print("\n❌ DEMO MIGRATION FALHOU!")


if __name__ == "__main__":
    main() 