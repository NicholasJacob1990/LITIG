#!/usr/bin/env python3
"""
Script de Backfill - Migração de Dados Legados B2B
==================================================

Este script realiza a migração de dados legados para o sistema B2B Law Firms:
1. Cria escritórios de exemplo
2. Associa advogados existentes aos escritórios
3. Calcula KPIs agregados dos escritórios
4. Valida a integridade dos dados

Uso:
    python migration_backfill.py [--dry-run] [--force]
    
Flags:
    --dry-run: Executa sem fazer alterações no banco
    --force: Força a execução mesmo com dados existentes
"""

import asyncio
import argparse
import logging
import sys
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from uuid import uuid4, UUID
import random

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

try:
    import psycopg2
    from psycopg2.extras import RealDictCursor
    import numpy as np
except ImportError as e:
    logger.error(f"Dependência faltando: {e}")
    sys.exit(1)

class MigrationBackfill:
    """Classe principal para migração de dados B2B"""
    
    def __init__(self, db_config: Dict, dry_run: bool = False):
        self.db_config = db_config
        self.dry_run = dry_run
        self.conn = None
        
        # Dados de exemplo para escritórios
        self.sample_firms = [
            {
                "name": "Advocacia Silva & Associados",
                "team_size": 15,
                "main_lat": -23.5505,
                "main_lon": -46.6333,
                "success_rate": 0.85,
                "nps": 0.72,
                "reputation_score": 0.88,
                "diversity_index": 0.65
            },
            {
                "name": "Escritório Advocacia Moderna Ltda",
                "team_size": 8,
                "main_lat": -22.9068,
                "main_lon": -43.1729,
                "success_rate": 0.78,
                "nps": 0.68,
                "reputation_score": 0.75,
                "diversity_index": 0.70
            },
            {
                "name": "Machado & Partners Advocacia",
                "team_size": 25,
                "main_lat": -25.4284,
                "main_lon": -49.2733,
                "success_rate": 0.91,
                "nps": 0.82,
                "reputation_score": 0.93,
                "diversity_index": 0.58
            },
            {
                "name": "Jurídico Corporativo Avançado",
                "team_size": 12,
                "main_lat": -30.0346,
                "main_lon": -51.2177,
                "success_rate": 0.80,
                "nps": 0.55,
                "reputation_score": 0.82,
                "diversity_index": 0.62
            }
        ]
    
    def connect_db(self):
        """Conecta ao banco de dados"""
        try:
            self.conn = psycopg2.connect(**self.db_config)
            self.conn.autocommit = False
            logger.info("Conectado ao banco de dados")
        except Exception as e:
            logger.error(f"Erro ao conectar ao banco: {e}")
            raise
    
    def disconnect_db(self):
        """Desconecta do banco de dados"""
        if self.conn:
            self.conn.close()
            logger.info("Desconectado do banco de dados")
    
    def check_existing_data(self) -> Dict[str, int]:
        """Verifica dados existentes no banco"""
        with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
            # Contar escritórios existentes
            cur.execute("SELECT COUNT(*) as count FROM law_firms")
            firms_count = cur.fetchone()['count']
            
            # Contar advogados com firm_id
            cur.execute("SELECT COUNT(*) as count FROM lawyers WHERE firm_id IS NOT NULL")
            lawyers_with_firm = cur.fetchone()['count']
            
            # Contar KPIs de escritórios
            cur.execute("SELECT COUNT(*) as count FROM firm_kpis")
            kpis_count = cur.fetchone()['count']
            
            return {
                "firms": firms_count,
                "lawyers_with_firm": lawyers_with_firm,
                "kpis": kpis_count
            }
    
    def create_sample_firms(self) -> List[UUID]:
        """Cria escritórios de exemplo"""
        created_firms = []
        
        with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
            for firm_data in self.sample_firms:
                firm_id = uuid4()
                
                if not self.dry_run:
                    cur.execute("""
                        INSERT INTO law_firms (id, name, team_size, main_lat, main_lon, created_at, updated_at)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                        ON CONFLICT (name) DO NOTHING
                    """, (
                        firm_id,
                        firm_data["name"],
                        firm_data["team_size"],
                        firm_data["main_lat"],
                        firm_data["main_lon"],
                        datetime.now(),
                        datetime.now()
                    ))
                    
                    # Verificar se foi inserido
                    cur.execute("SELECT id FROM law_firms WHERE name = %s", (firm_data["name"],))
                    result = cur.fetchone()
                    if result:
                        actual_firm_id = result['id']
                        created_firms.append(actual_firm_id)
                        
                        # Criar KPIs do escritório
                        cur.execute("""
                            INSERT INTO firm_kpis (firm_id, success_rate, nps, reputation_score, diversity_index, active_cases, updated_at)
                            VALUES (%s, %s, %s, %s, %s, %s, %s)
                            ON CONFLICT (firm_id) DO UPDATE SET
                                success_rate = EXCLUDED.success_rate,
                                nps = EXCLUDED.nps,
                                reputation_score = EXCLUDED.reputation_score,
                                diversity_index = EXCLUDED.diversity_index,
                                updated_at = EXCLUDED.updated_at
                        """, (
                            actual_firm_id,
                            firm_data["success_rate"],
                            firm_data["nps"],
                            firm_data["reputation_score"],
                            firm_data["diversity_index"],
                            random.randint(5, 20),  # active_cases aleatório
                            datetime.now()
                        ))
                        
                        logger.info(f"Escritório criado: {firm_data['name']} (ID: {actual_firm_id})")
                else:
                    logger.info(f"[DRY RUN] Criaria escritório: {firm_data['name']}")
                    created_firms.append(firm_id)
        
        return created_firms
    
    def associate_lawyers_to_firms(self, firm_ids: List[UUID]) -> int:
        """Associa advogados existentes aos escritórios"""
        if not firm_ids:
            logger.warning("Nenhum escritório disponível para associação")
            return 0
        
        with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
            # Buscar advogados sem firm_id
            cur.execute("""
                SELECT id, nome, geo_latlon 
                FROM lawyers 
                WHERE firm_id IS NULL 
                ORDER BY RANDOM()
                LIMIT 50
            """)
            lawyers = cur.fetchall()
            
            if not lawyers:
                logger.warning("Nenhum advogado encontrado para associação")
                return 0
            
            associated_count = 0
            
            for lawyer in lawyers:
                # Associar aleatoriamente a um escritório (30% de chance)
                if random.random() < 0.3:
                    selected_firm = random.choice(firm_ids)
                    
                    if not self.dry_run:
                        cur.execute("""
                            UPDATE lawyers 
                            SET firm_id = %s 
                            WHERE id = %s
                        """, (selected_firm, lawyer['id']))
                        
                        logger.info(f"Advogado {lawyer['nome']} associado ao escritório {selected_firm}")
                    else:
                        logger.info(f"[DRY RUN] Associaria advogado {lawyer['nome']} ao escritório {selected_firm}")
                    
                    associated_count += 1
            
            return associated_count
    
    def update_firm_kpis(self, firm_ids: List[UUID]):
        """Atualiza KPIs dos escritórios baseado nos advogados associados"""
        with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
            for firm_id in firm_ids:
                # Calcular KPIs agregados baseados nos advogados
                cur.execute("""
                    SELECT 
                        COUNT(*) as lawyer_count,
                        AVG(CASE WHEN kpi->>'success_rate' ~ '^[0-9.]+$' 
                            THEN (kpi->>'success_rate')::float 
                            ELSE 0.8 END) as avg_success_rate,
                        AVG(CASE WHEN kpi->>'avaliacao_media' ~ '^[0-9.]+$' 
                            THEN (kpi->>'avaliacao_media')::float 
                            ELSE 4.0 END) as avg_rating,
                        SUM(CASE WHEN kpi->>'active_cases' ~ '^[0-9]+$' 
                            THEN (kpi->>'active_cases')::int 
                            ELSE 0 END) as total_active_cases
                    FROM lawyers 
                    WHERE firm_id = %s
                """, (firm_id,))
                
                stats = cur.fetchone()
                
                if stats and stats['lawyer_count'] > 0:
                    # Calcular NPS baseado na avaliação média
                    nps = max(-1, min(1, (stats['avg_rating'] - 3) / 2))
                    
                    if not self.dry_run:
                        cur.execute("""
                            UPDATE firm_kpis 
                            SET 
                                success_rate = %s,
                                nps = %s,
                                active_cases = %s,
                                updated_at = %s
                            WHERE firm_id = %s
                        """, (
                            min(1.0, stats['avg_success_rate']),
                            nps,
                            stats['total_active_cases'],
                            datetime.now(),
                            firm_id
                        ))
                        
                        logger.info(f"KPIs atualizados para escritório {firm_id}: "
                                  f"success_rate={stats['avg_success_rate']:.3f}, "
                                  f"nps={nps:.3f}, "
                                  f"active_cases={stats['total_active_cases']}")
                    else:
                        logger.info(f"[DRY RUN] Atualizaria KPIs para escritório {firm_id}")
    
    def validate_data_integrity(self) -> bool:
        """Valida a integridade dos dados após a migração"""
        with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
            # Verificar se todos os escritórios têm KPIs
            cur.execute("""
                SELECT lf.id, lf.name 
                FROM law_firms lf 
                LEFT JOIN firm_kpis fk ON lf.id = fk.firm_id 
                WHERE fk.firm_id IS NULL
            """)
            firms_without_kpis = cur.fetchall()
            
            if firms_without_kpis:
                logger.error(f"Escritórios sem KPIs: {[f['name'] for f in firms_without_kpis]}")
                return False
            
            # Verificar se firm_id em lawyers é válido
            cur.execute("""
                SELECT l.id, l.nome 
                FROM lawyers l 
                LEFT JOIN law_firms lf ON l.firm_id = lf.id 
                WHERE l.firm_id IS NOT NULL AND lf.id IS NULL
            """)
            lawyers_invalid_firm = cur.fetchall()
            
            if lawyers_invalid_firm:
                logger.error(f"Advogados com firm_id inválido: {[l['nome'] for l in lawyers_invalid_firm]}")
                return False
            
            # Verificar constraints de KPIs
            cur.execute("""
                SELECT firm_id 
                FROM firm_kpis 
                WHERE success_rate < 0 OR success_rate > 1 
                   OR nps < -1 OR nps > 1 
                   OR reputation_score < 0 OR reputation_score > 1
            """)
            invalid_kpis = cur.fetchall()
            
            if invalid_kpis:
                logger.error(f"KPIs com valores inválidos: {[k['firm_id'] for k in invalid_kpis]}")
                return False
            
            logger.info("Validação de integridade passou com sucesso")
            return True
    
    def run(self, force: bool = False) -> bool:
        """Executa o processo completo de migração"""
        try:
            self.connect_db()
            
            # Verificar dados existentes
            existing_data = self.check_existing_data()
            logger.info(f"Dados existentes: {existing_data}")
            
            if existing_data['firms'] > 0 and not force:
                logger.warning("Dados de escritórios já existem. Use --force para continuar.")
                return False
            
            if not self.dry_run:
                # Iniciar transação
                self.conn.begin()
            
            # Criar escritórios de exemplo
            logger.info("Criando escritórios de exemplo...")
            firm_ids = self.create_sample_firms()
            
            # Associar advogados aos escritórios
            logger.info("Associando advogados aos escritórios...")
            associated_count = self.associate_lawyers_to_firms(firm_ids)
            
            # Atualizar KPIs dos escritórios
            logger.info("Atualizando KPIs dos escritórios...")
            self.update_firm_kpis(firm_ids)
            
            # Validar integridade dos dados
            if not self.dry_run:
                if self.validate_data_integrity():
                    self.conn.commit()
                    logger.info("Migração concluída com sucesso!")
                else:
                    self.conn.rollback()
                    logger.error("Validação falhou. Rollback executado.")
                    return False
            
            # Relatório final
            final_data = self.check_existing_data()
            logger.info(f"Dados finais: {final_data}")
            logger.info(f"Escritórios criados: {len(firm_ids)}")
            logger.info(f"Advogados associados: {associated_count}")
            
            return True
            
        except Exception as e:
            logger.error(f"Erro durante a migração: {e}")
            if self.conn and not self.dry_run:
                self.conn.rollback()
            return False
        finally:
            self.disconnect_db()

def main():
    parser = argparse.ArgumentParser(description="Script de Backfill B2B Law Firms")
    parser.add_argument("--dry-run", action="store_true", help="Executa sem fazer alterações")
    parser.add_argument("--force", action="store_true", help="Força execução com dados existentes")
    parser.add_argument("--db-host", default="localhost", help="Host do banco de dados")
    parser.add_argument("--db-port", default="5432", help="Porta do banco de dados")
    parser.add_argument("--db-name", default="litgo", help="Nome do banco de dados")
    parser.add_argument("--db-user", default="postgres", help="Usuário do banco de dados")
    parser.add_argument("--db-password", help="Senha do banco de dados")
    
    args = parser.parse_args()
    
    # Configuração do banco de dados
    db_config = {
        "host": args.db_host,
        "port": args.db_port,
        "database": args.db_name,
        "user": args.db_user,
        "password": args.db_password or input("Senha do banco de dados: ")
    }
    
    # Executar migração
    migration = MigrationBackfill(db_config, dry_run=args.dry_run)
    success = migration.run(force=args.force)
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main() 