#!/usr/bin/env python3
"""
Script de Migração Gradual: Embeddings V1 (768D) → V2 (1024D)

Estratégia de Migração Sem Downtime:
1. Migra embeddings em batches pequenos
2. Mantém sistema V1 funcionando durante migração
3. Permite rollback seguro se necessário
4. Monitora progresso e performance

Uso:
    python migrate_embeddings_v2.py --batch-size 50 --delay 2.0 --dry-run
    python migrate_embeddings_v2.py --start-migration --batch-size 100
    python migrate_embeddings_v2.py --check-progress
    python migrate_embeddings_v2.py --rollback  # Se necessário
"""
import asyncio
import argparse
import logging
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
import psycopg2
from psycopg2.extras import RealDictCursor
import sys
import os

# Adicionar path do backend ao sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.embedding_service_v2 import legal_embedding_service_v2
from config.database import get_db_connection
from services.cache_service import create_redis_cache

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('migration_v2.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class EmbeddingMigrationV2:
    """
    Gerenciador de migração gradual para embeddings V2.
    
    Funcionalidades:
    - Migração em batches configuráveis
    - Controle de rate limiting
    - Rollback seguro
    - Monitoramento de progresso
    - Validação de qualidade
    """
    
    def __init__(
        self,
        batch_size: int = 50,
        delay_between_batches: float = 1.0,
        max_retries: int = 3,
        dry_run: bool = False
    ):
        self.batch_size = batch_size
        self.delay_between_batches = delay_between_batches
        self.max_retries = max_retries
        self.dry_run = dry_run
        
        # Estatísticas da migração
        self.stats = {
            "total_lawyers": 0,
            "pending": 0,
            "migrated": 0,
            "failed": 0,
            "start_time": None,
            "estimated_completion": None
        }
        
        logger.info(f"🚀 EmbeddingMigrationV2 inicializada")
        logger.info(f"📊 Configuração: batch_size={batch_size}, delay={delay_between_batches}s, dry_run={dry_run}")

    async def check_migration_status(self) -> Dict:
        """Verifica status atual da migração."""
        try:
            with get_db_connection() as conn, conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Contar total de advogados
                cursor.execute("SELECT COUNT(*) as total FROM lawyers WHERE ativo = true")
                total = cursor.fetchone()['total']
                
                # Contar por status de migração
                cursor.execute("""
                    SELECT 
                        embedding_migration_status,
                        COUNT(*) as count
                    FROM lawyers 
                    WHERE ativo = true
                    GROUP BY embedding_migration_status
                """)
                
                status_counts = {row['embedding_migration_status']: row['count'] for row in cursor.fetchall()}
                
                # Calcular estatísticas
                pending = status_counts.get('pending', 0)
                migrated = status_counts.get('completed', 0)
                failed = status_counts.get('failed', 0)
                migrating = status_counts.get('migrating', 0)
                
                # Cobertura V2
                cursor.execute("""
                    SELECT COUNT(*) as v2_count 
                    FROM lawyers 
                    WHERE ativo = true AND cv_embedding_v2 IS NOT NULL
                """)
                v2_coverage = cursor.fetchone()['v2_count']
                
                # Performance estimada
                coverage_pct = (v2_coverage / total * 100) if total > 0 else 0
                
                return {
                    "total_lawyers": total,
                    "status_breakdown": {
                        "pending": pending,
                        "migrating": migrating,
                        "completed": migrated,
                        "failed": failed
                    },
                    "v2_coverage": {
                        "count": v2_coverage,
                        "percentage": round(coverage_pct, 2)
                    },
                    "migration_progress": round((migrated / total * 100), 2) if total > 0 else 0,
                    "ready_for_v2_switch": coverage_pct >= 95.0  # 95% de cobertura para switch
                }
                
        except Exception as e:
            logger.error(f"Erro ao verificar status: {e}")
            raise

    async def get_next_batch(self) -> List[Dict]:
        """Obtém próximo batch de advogados para migrar."""
        try:
            with get_db_connection() as conn, conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("""
                    SELECT 
                        id, nome, curriculo_json,
                        cv_embedding_v2_model, cv_embedding_v2_generated_at
                    FROM lawyers 
                    WHERE ativo = true 
                    AND embedding_migration_status IN ('pending', 'failed')
                    AND cv_embedding_v2 IS NULL
                    ORDER BY RANDOM()  -- Distribuir carga aleatoriamente
                    LIMIT %s
                """, (self.batch_size,))
                
                return cursor.fetchall()
                
        except Exception as e:
            logger.error(f"Erro ao obter batch: {e}")
            raise

    async def migrate_single_lawyer(self, lawyer: Dict) -> Tuple[bool, str, Optional[str]]:
        """
        Migra embedding de um advogado individual.
        
        Returns:
            Tuple[success, error_message, provider_used]
        """
        lawyer_id = lawyer['id']
        lawyer_name = lawyer['nome']
        curriculo = lawyer.get('curriculo_json', {})
        
        try:
            # Marcar como 'migrating'
            if not self.dry_run:
                await self._update_migration_status(lawyer_id, 'migrating')
            
            # Extrair texto do currículo para embedding
            cv_text = self._extract_cv_text(curriculo)
            if not cv_text:
                return False, "Currículo vazio ou inválido", None
            
            # Gerar embedding V2 especializado para advogado
            embedding_v2, provider = await legal_embedding_service_v2.generate_legal_embedding(
                cv_text, 
                context_type="lawyer_cv"
            )
            
            if not self.dry_run:
                # Salvar embedding V2 no banco
                await self._save_embedding_v2(lawyer_id, embedding_v2, provider)
                
                # Marcar como 'completed'
                await self._update_migration_status(lawyer_id, 'completed')
            
            logger.info(f"✅ Migrado: {lawyer_name} (ID: {lawyer_id}) via {provider}")
            return True, "", provider
            
        except Exception as e:
            error_msg = f"Erro ao migrar {lawyer_name}: {str(e)}"
            logger.error(error_msg)
            
            if not self.dry_run:
                await self._update_migration_status(lawyer_id, 'failed')
            
            return False, error_msg, None

    def _extract_cv_text(self, curriculo: Dict) -> str:
        """Extrai texto relevante do currículo JSON."""
        if not curriculo:
            return ""
        
        # Extrair campos principais para embedding
        text_parts = []
        
        # Experiências profissionais
        if 'experiencias' in curriculo:
            for exp in curriculo['experiencias']:
                if isinstance(exp, dict):
                    text_parts.append(exp.get('cargo', ''))
                    text_parts.append(exp.get('empresa', ''))
                    text_parts.append(exp.get('descricao', ''))
        
        # Formação acadêmica
        if 'formacao' in curriculo:
            for form in curriculo['formacao']:
                if isinstance(form, dict):
                    text_parts.append(form.get('curso', ''))
                    text_parts.append(form.get('instituicao', ''))
        
        # Especializações
        if 'especializacoes' in curriculo:
            for esp in curriculo['especializacoes']:
                if isinstance(esp, str):
                    text_parts.append(esp)
                elif isinstance(esp, dict):
                    text_parts.append(esp.get('nome', ''))
        
        # Áreas de atuação
        if 'areas_atuacao' in curriculo:
            text_parts.extend(curriculo['areas_atuacao'])
        
        # Filtrar e juntar
        clean_parts = [part.strip() for part in text_parts if part and isinstance(part, str)]
        return ' '.join(clean_parts)

    async def _update_migration_status(self, lawyer_id: str, status: str):
        """Atualiza status de migração no banco."""
        try:
            with get_db_connection() as conn, conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE lawyers 
                    SET embedding_migration_status = %s
                    WHERE id = %s
                """, (status, lawyer_id))
                conn.commit()
        except Exception as e:
            logger.error(f"Erro ao atualizar status para {lawyer_id}: {e}")
            raise

    async def _save_embedding_v2(self, lawyer_id: str, embedding: List[float], provider: str):
        """Salva embedding V2 no banco."""
        try:
            with get_db_connection() as conn, conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE lawyers 
                    SET 
                        cv_embedding_v2 = %s,
                        cv_embedding_v2_model = %s,
                        cv_embedding_v2_generated_at = CURRENT_TIMESTAMP,
                        cv_embedding_v2_dimensions = %s
                    WHERE id = %s
                """, (embedding, provider, len(embedding), lawyer_id))
                conn.commit()
        except Exception as e:
            logger.error(f"Erro ao salvar embedding V2 para {lawyer_id}: {e}")
            raise

    async def run_migration_batch(self) -> Dict:
        """Executa migração de um batch."""
        batch_start = time.time()
        
        # Obter próximo batch
        lawyers = await self.get_next_batch()
        if not lawyers:
            logger.info("🎉 Nenhum advogado pendente para migração!")
            return {
                "batch_size": 0,
                "success": 0,
                "failed": 0,
                "providers_used": {},
                "duration": 0
            }
        
        logger.info(f"🔄 Iniciando migração de batch: {len(lawyers)} advogados")
        
        # Estatísticas do batch
        batch_stats = {
            "batch_size": len(lawyers),
            "success": 0,
            "failed": 0,
            "providers_used": {},
            "duration": 0
        }
        
        # Migrar cada advogado
        for i, lawyer in enumerate(lawyers):
            try:
                success, error, provider = await self.migrate_single_lawyer(lawyer)
                
                if success:
                    batch_stats["success"] += 1
                    if provider:
                        batch_stats["providers_used"][provider] = batch_stats["providers_used"].get(provider, 0) + 1
                else:
                    batch_stats["failed"] += 1
                    logger.error(f"❌ Falha na migração: {error}")
                
                # Rate limiting entre advogados
                if i < len(lawyers) - 1:  # Não delay no último
                    await asyncio.sleep(0.1)  # 100ms entre advogados
                    
            except Exception as e:
                logger.error(f"❌ Erro crítico na migração: {e}")
                batch_stats["failed"] += 1
        
        batch_stats["duration"] = time.time() - batch_start
        
        # Rate limiting entre batches
        if not self.dry_run:
            await asyncio.sleep(self.delay_between_batches)
        
        logger.info(f"✅ Batch concluído: {batch_stats['success']} sucessos, {batch_stats['failed']} falhas em {batch_stats['duration']:.2f}s")
        
        return batch_stats

    async def run_full_migration(self):
        """Executa migração completa."""
        logger.info("🚀 Iniciando migração completa V1 → V2")
        
        # Verificar status inicial
        initial_status = await self.check_migration_status()
        logger.info(f"📊 Status inicial: {initial_status}")
        
        if initial_status['ready_for_v2_switch']:
            logger.info("✅ Sistema já pronto para V2!")
            return
        
        # Estatísticas totais
        total_stats = {
            "batches_processed": 0,
            "total_success": 0,
            "total_failed": 0,
            "providers_used": {},
            "start_time": datetime.now()
        }
        
        try:
            while True:
                # Executar batch
                batch_result = await self.run_migration_batch()
                
                if batch_result["batch_size"] == 0:
                    break  # Não há mais advogados para migrar
                
                # Atualizar estatísticas
                total_stats["batches_processed"] += 1
                total_stats["total_success"] += batch_result["success"]
                total_stats["total_failed"] += batch_result["failed"]
                
                # Agregar provedores usados
                for provider, count in batch_result["providers_used"].items():
                    total_stats["providers_used"][provider] = total_stats["providers_used"].get(provider, 0) + count
                
                # Verificar progresso
                current_status = await self.check_migration_status()
                logger.info(f"📈 Progresso atual: {current_status['migration_progress']:.1f}% - V2 Coverage: {current_status['v2_coverage']['percentage']:.1f}%")
                
                # Verificar se atingiu threshold para switch
                if current_status['ready_for_v2_switch']:
                    logger.info("🎉 Threshold de 95% atingido! Sistema pronto para switch V2")
                    break
                
                # Mostrar ETA
                if total_stats["batches_processed"] > 1:
                    elapsed = datetime.now() - total_stats["start_time"]
                    remaining_pct = 100 - current_status['migration_progress']
                    estimated_total = elapsed / (current_status['migration_progress'] / 100)
                    eta = total_stats["start_time"] + estimated_total
                    logger.info(f"⏱️  ETA: {eta.strftime('%H:%M:%S')}")
        
        except KeyboardInterrupt:
            logger.info("⏹️  Migração interrompida pelo usuário")
        except Exception as e:
            logger.error(f"❌ Erro na migração: {e}")
            raise
        
        # Estatísticas finais
        total_duration = datetime.now() - total_stats["start_time"]
        final_status = await self.check_migration_status()
        
        logger.info("🏁 Migração finalizada!")
        logger.info(f"📊 Estatísticas finais:")
        logger.info(f"   - Batches processados: {total_stats['batches_processed']}")
        logger.info(f"   - Sucessos: {total_stats['total_success']}")
        logger.info(f"   - Falhas: {total_stats['total_failed']}")
        logger.info(f"   - Duração total: {total_duration}")
        logger.info(f"   - Progresso final: {final_status['migration_progress']:.1f}%")
        logger.info(f"   - Provedores usados: {total_stats['providers_used']}")

    async def validate_migration_quality(self, sample_size: int = 50) -> Dict:
        """Valida qualidade da migração comparando similaridades."""
        logger.info(f"🔍 Validando qualidade da migração (amostra: {sample_size})")
        
        try:
            with get_db_connection() as conn, conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Obter amostra de advogados com ambos embeddings
                cursor.execute("""
                    SELECT id, nome, cv_embedding, cv_embedding_v2, cv_embedding_v2_model
                    FROM lawyers 
                    WHERE ativo = true 
                    AND cv_embedding IS NOT NULL 
                    AND cv_embedding_v2 IS NOT NULL
                    AND embedding_migration_status = 'completed'
                    ORDER BY RANDOM()
                    LIMIT %s
                """, (sample_size,))
                
                lawyers = cursor.fetchall()
                
            if not lawyers:
                return {"error": "Nenhum advogado com ambos embeddings encontrado"}
            
            # Análise de qualidade
            quality_stats = {
                "sample_size": len(lawyers),
                "providers_distribution": {},
                "dimension_validation": {"v1": 0, "v2": 0},
                "quality_score": 0.0
            }
            
            for lawyer in lawyers:
                # Validar dimensões
                v1_dims = len(lawyer['cv_embedding']) if lawyer['cv_embedding'] else 0
                v2_dims = len(lawyer['cv_embedding_v2']) if lawyer['cv_embedding_v2'] else 0
                
                if v1_dims > 0:
                    quality_stats["dimension_validation"]["v1"] += 1
                if v2_dims == 1024:  # Dimensão esperada V2
                    quality_stats["dimension_validation"]["v2"] += 1
                
                # Distribuição de provedores V2
                provider = lawyer['cv_embedding_v2_model']
                quality_stats["providers_distribution"][provider] = quality_stats["providers_distribution"].get(provider, 0) + 1
            
            # Calcular score de qualidade
            v2_valid_pct = quality_stats["dimension_validation"]["v2"] / len(lawyers) * 100
            quality_stats["quality_score"] = v2_valid_pct
            
            logger.info(f"✅ Validação concluída: {v2_valid_pct:.1f}% dos embeddings V2 válidos")
            
            return quality_stats
            
        except Exception as e:
            logger.error(f"Erro na validação: {e}")
            raise

    async def rollback_migration(self, confirm: bool = False):
        """Executa rollback da migração V2."""
        if not confirm:
            logger.warning("⚠️  Rollback requer confirmação explícita!")
            return
        
        logger.info("🔄 Iniciando rollback da migração V2...")
        
        try:
            with get_db_connection() as conn, conn.cursor() as cursor:
                # Limpar embeddings V2 e resetar status
                cursor.execute("""
                    UPDATE lawyers 
                    SET 
                        cv_embedding_v2 = NULL,
                        cv_embedding_v2_model = NULL,
                        cv_embedding_v2_generated_at = NULL,
                        cv_embedding_v2_dimensions = NULL,
                        embedding_migration_status = 'pending'
                    WHERE ativo = true
                """)
                
                affected_rows = cursor.rowcount
                conn.commit()
                
            logger.info(f"✅ Rollback concluído: {affected_rows} advogados resetados")
            
        except Exception as e:
            logger.error(f"❌ Erro no rollback: {e}")
            raise


async def main():
    """Função principal CLI."""
    parser = argparse.ArgumentParser(description="Migração de Embeddings V1 → V2")
    
    parser.add_argument("--batch-size", type=int, default=50, help="Tamanho do batch")
    parser.add_argument("--delay", type=float, default=1.0, help="Delay entre batches (segundos)")
    parser.add_argument("--dry-run", action="store_true", help="Simular migração sem alterações")
    parser.add_argument("--check-progress", action="store_true", help="Verificar progresso atual")
    parser.add_argument("--start-migration", action="store_true", help="Iniciar migração completa")
    parser.add_argument("--validate", action="store_true", help="Validar qualidade da migração")
    parser.add_argument("--rollback", action="store_true", help="Executar rollback")
    parser.add_argument("--confirm-rollback", action="store_true", help="Confirmar rollback")
    
    args = parser.parse_args()
    
    # Criar instância do migrador
    migrator = EmbeddingMigrationV2(
        batch_size=args.batch_size,
        delay_between_batches=args.delay,
        dry_run=args.dry_run
    )
    
    try:
        if args.check_progress:
            status = await migrator.check_migration_status()
            print("📊 Status da Migração:")
            print(f"   Total de advogados: {status['total_lawyers']}")
            print(f"   Progresso: {status['migration_progress']:.1f}%")
            print(f"   Cobertura V2: {status['v2_coverage']['percentage']:.1f}%")
            print(f"   Pronto para switch: {'✅ Sim' if status['ready_for_v2_switch'] else '❌ Não'}")
            print(f"   Status breakdown: {status['status_breakdown']}")
            
        elif args.start_migration:
            await migrator.run_full_migration()
            
        elif args.validate:
            quality = await migrator.validate_migration_quality()
            print("🔍 Validação de Qualidade:")
            print(f"   Amostra: {quality['sample_size']} advogados")
            print(f"   Score de qualidade: {quality['quality_score']:.1f}%")
            print(f"   Provedores: {quality['providers_distribution']}")
            
        elif args.rollback:
            await migrator.rollback_migration(confirm=args.confirm_rollback)
            
        else:
            # Executar um batch por padrão
            result = await migrator.run_migration_batch()
            print(f"✅ Batch executado: {result}")
            
    except Exception as e:
        logger.error(f"❌ Erro na execução: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit_code = asyncio.run(main())
 
 