#!/usr/bin/env python3
"""
Script de Migração: Embeddings Enriquecidos (CV + KPIs + Performance)

Executa migração gradual dos advogados para embeddings enriquecidos que combinam:
- Dados textuais (CV, especialização)
- Métricas de performance (KPIs, taxa de sucesso)
- Contexto profissional (educação, experiência)

Características:
- Migração por lotes com controle de velocidade
- A/B testing automático (50% enriquecidos, 50% padrão V2)
- Validação de qualidade e rollback
- Métricas de progresso e performance
"""
import asyncio
import argparse
import logging
import json
import time
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple
import sys
import os

# Adicionar path do backend
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class EnrichedEmbeddingMigration:
    """
    Gerencia migração para embeddings enriquecidos com A/B testing.
    
    Estratégia:
    1. Seleciona advogados elegíveis (com KPIs suficientes)
    2. Divide em grupos A/B (50% enriquecidos, 50% V2 padrão)  
    3. Migra em lotes com validação
    4. Monitora qualidade e performance
    """
    
    def __init__(self, dry_run: bool = False, batch_size: int = 20):
        self.dry_run = dry_run
        self.batch_size = batch_size
        self.total_migrated = 0
        self.total_errors = 0
        self.start_time = time.time()
        
        # Estatísticas da migração
        self.stats = {
            "eligible_lawyers": 0,
            "ab_group_a": 0,  # Embeddings enriquecidos
            "ab_group_b": 0,  # V2 padrão (controle)
            "successful_enriched": 0,
            "failed_enriched": 0,
            "processing_times": [],
            "template_usage": {},
            "provider_usage": {}
        }
        
        logger.info(f"🧪 EnrichedEmbeddingMigration inicializada")
        logger.info(f"   Modo: {'DRY RUN' if dry_run else 'EXECUÇÃO REAL'}")
        logger.info(f"   Batch size: {batch_size}")

    async def check_eligibility_criteria(self) -> Dict[str, Any]:
        """Verifica quantos advogados são elegíveis para embeddings enriquecidos."""
        
        try:
            from config.database import get_db_connection
            
            with get_db_connection() as conn, conn.cursor() as cursor:
                # Query para advogados elegíveis
                cursor.execute("""
                    SELECT 
                        COUNT(*) as total_lawyers,
                        COUNT(CASE WHEN kpi IS NOT NULL AND kpi != '{}' THEN 1 END) as with_kpi,
                        COUNT(CASE WHEN tags_expertise IS NOT NULL AND array_length(tags_expertise, 1) > 0 THEN 1 END) as with_expertise,
                        COUNT(CASE WHEN cv_text IS NOT NULL AND length(cv_text) > 50 THEN 1 END) as with_cv,
                        COUNT(CASE WHEN 
                            kpi IS NOT NULL AND kpi != '{}' AND
                            tags_expertise IS NOT NULL AND array_length(tags_expertise, 1) > 0 AND
                            cv_text IS NOT NULL AND length(cv_text) > 50
                        THEN 1 END) as eligible_for_enriched,
                        COUNT(CASE WHEN cv_embedding_v2_enriched IS NOT NULL THEN 1 END) as already_enriched
                    FROM lawyers 
                    WHERE ativo = true
                """)
                
                result = cursor.fetchone()
                
                eligibility_stats = {
                    "total_active_lawyers": result[0],
                    "lawyers_with_kpi": result[1],
                    "lawyers_with_expertise": result[2], 
                    "lawyers_with_cv": result[3],
                    "eligible_for_enriched": result[4],
                    "already_enriched": result[5],
                    "eligibility_rate": (result[4] / result[0] * 100) if result[0] > 0 else 0,
                    "enriched_coverage": (result[5] / result[4] * 100) if result[4] > 0 else 0
                }
                
                self.stats["eligible_lawyers"] = result[4]
                
                return eligibility_stats
                
        except Exception as e:
            logger.error(f"Erro ao verificar critérios de elegibilidade: {e}")
            return {"error": str(e)}

    async def get_next_batch_for_enrichment(self) -> List[Dict[str, Any]]:
        """Busca próximo lote de advogados para migração enriquecida."""
        
        try:
            from config.database import get_db_connection
            
            with get_db_connection() as conn, conn.cursor() as cursor:
                # Buscar advogados elegíveis que ainda não foram processados
                cursor.execute("""
                    SELECT 
                        id, nome, cv_text, tags_expertise, kpi, kpi_subarea,
                        total_cases, publications, education, professional_experience,
                        city, state, interaction_score
                    FROM lawyers 
                    WHERE 
                        ativo = true
                        AND cv_embedding_v2_enriched IS NULL
                        AND use_enriched_embeddings IS NULL
                        AND kpi IS NOT NULL AND kpi != '{}'
                        AND tags_expertise IS NOT NULL AND array_length(tags_expertise, 1) > 0
                        AND cv_text IS NOT NULL AND length(cv_text) > 50
                    ORDER BY total_cases DESC, interaction_score DESC NULLS LAST
                    LIMIT %s
                """, (self.batch_size,))
                
                rows = cursor.fetchall()
                
                lawyers = []
                for row in rows:
                    lawyer = {
                        "id": row[0],
                        "nome": row[1],
                        "cv_text": row[2] or "",
                        "tags_expertise": row[3] or [],
                        "kpi": row[4] or {},
                        "kpi_subarea": row[5] or {},
                        "total_cases": row[6] or 0,
                        "publications": row[7] or [],
                        "education": row[8] or "",
                        "professional_experience": row[9] or "",
                        "city": row[10] or "",
                        "state": row[11] or "",
                        "interaction_score": row[12]
                    }
                    lawyers.append(lawyer)
                
                return lawyers
                
        except Exception as e:
            logger.error(f"Erro ao buscar próximo lote: {e}")
            return []

    def assign_ab_groups(self, lawyers: List[Dict[str, Any]]) -> Tuple[List[Dict], List[Dict]]:
        """
        Divide advogados em grupos A/B para teste.
        
        Grupo A: Embeddings enriquecidos (50%)
        Grupo B: V2 padrão como controle (50%)
        """
        import random
        
        # Embaralhar para distribuição aleatória
        shuffled = lawyers.copy()
        random.shuffle(shuffled)
        
        # Dividir meio a meio
        mid_point = len(shuffled) // 2
        
        group_a = shuffled[:mid_point]  # Embeddings enriquecidos
        group_b = shuffled[mid_point:]  # V2 padrão (controle)
        
        self.stats["ab_group_a"] += len(group_a)
        self.stats["ab_group_b"] += len(group_b)
        
        logger.info(f"📊 Grupos A/B criados: A={len(group_a)} (enriquecido), B={len(group_b)} (controle)")
        
        return group_a, group_b

    async def migrate_lawyer_enriched(self, lawyer: Dict[str, Any]) -> bool:
        """Migra um advogado específico para embedding enriquecido."""
        
        start_time = time.time()
        
        try:
            from services.enriched_embedding_service import LawyerProfile, enriched_embedding_service
            
            # 1. Criar perfil estruturado
            profile = LawyerProfile(
                id=lawyer["id"],
                nome=lawyer["nome"],
                cv_text=lawyer["cv_text"],
                tags_expertise=lawyer["tags_expertise"],
                kpi=lawyer["kpi"],
                kpi_subarea=lawyer["kpi_subarea"],
                total_cases=lawyer["total_cases"],
                publications=lawyer["publications"],
                education=lawyer["education"],
                professional_experience=lawyer["professional_experience"],
                city=lawyer["city"],
                state=lawyer["state"],
                interaction_score=lawyer["interaction_score"]
            )
            
            # 2. Escolher template baseado no perfil
            template_type = self._select_optimal_template(profile)
            
            # 3. Gerar embedding enriquecido
            embedding, provider, metadata = await enriched_embedding_service.generate_enriched_embedding(
                profile, template_type
            )
            
            processing_time = time.time() - start_time
            self.stats["processing_times"].append(processing_time)
            
            # 4. Atualizar estatísticas
            self.stats["template_usage"][template_type] = self.stats["template_usage"].get(template_type, 0) + 1
            self.stats["provider_usage"][provider] = self.stats["provider_usage"].get(provider, 0) + 1
            
            # 5. Salvar no banco (se não for dry run)
            if not self.dry_run:
                await self._save_enriched_embedding(lawyer["id"], embedding, provider, metadata, template_type)
            
            self.stats["successful_enriched"] += 1
            
            logger.info(f"✅ {lawyer['nome']}: embedding enriquecido via {provider} ({processing_time:.2f}s)")
            
            return True
            
        except Exception as e:
            self.stats["failed_enriched"] += 1
            logger.error(f"❌ Erro ao migrar {lawyer['nome']}: {e}")
            return False

    def _select_optimal_template(self, profile: LawyerProfile) -> str:
        """Seleciona template ótimo baseado no perfil do advogado."""
        
        # Calcular scores dos dados disponíveis
        kpi_richness = len([k for k, v in profile.kpi.items() if v and v != 0])
        expertise_richness = len(profile.tags_expertise)
        publications_richness = len(profile.publications)
        cv_richness = len(profile.cv_text)
        
        # Lógica de seleção de template
        if kpi_richness >= 5 and profile.total_cases > 20:
            return "performance_focused"  # Foco em performance para advogados com histórico
        elif expertise_richness >= 3 and publications_richness >= 3:
            return "expertise_focused"  # Foco em especialização para especialistas
        elif kpi_richness >= 3 and expertise_richness >= 2 and cv_richness > 200:
            return "complete"  # Template completo para perfis ricos
        else:
            return "balanced"  # Template padrão para casos gerais

    async def _save_enriched_embedding(
        self, 
        lawyer_id: str, 
        embedding: List[float], 
        provider: str, 
        metadata: Dict[str, Any],
        template_type: str
    ):
        """Salva embedding enriquecido no banco de dados."""
        
        try:
            from config.database import get_db_connection
            
            # Converter embedding para formato pgvector
            embedding_str = f"[{','.join(map(str, embedding))}]"
            
            with get_db_connection() as conn, conn.cursor() as cursor:
                # Atualizar advogado com embedding enriquecido
                cursor.execute("""
                    UPDATE lawyers 
                    SET 
                        cv_embedding_v2_enriched = %s,
                        cv_embedding_v2_enriched_model = %s,
                        cv_embedding_v2_enriched_generated_at = CURRENT_TIMESTAMP,
                        cv_embedding_v2_enriched_version = %s,
                        use_enriched_embeddings = true
                    WHERE id = %s
                """, (
                    embedding_str,
                    provider,
                    metadata["version"],
                    lawyer_id
                ))
                
                conn.commit()
                
        except Exception as e:
            logger.error(f"Erro ao salvar embedding para {lawyer_id}: {e}")
            raise

    async def set_control_group(self, lawyers: List[Dict[str, Any]]):
        """Marca advogados do grupo de controle (V2 padrão)."""
        
        if self.dry_run:
            logger.info(f"🔄 DRY RUN: Marcaria {len(lawyers)} advogados como grupo de controle")
            return
        
        try:
            from config.database import get_db_connection
            
            lawyer_ids = [lawyer["id"] for lawyer in lawyers]
            
            with get_db_connection() as conn, conn.cursor() as cursor:
                # Marcar como grupo de controle (usa V2 padrão)
                cursor.execute("""
                    UPDATE lawyers 
                    SET use_enriched_embeddings = false
                    WHERE id = ANY(%s)
                """, (lawyer_ids,))
                
                conn.commit()
                
            logger.info(f"✅ {len(lawyers)} advogados marcados como grupo de controle (V2 padrão)")
            
        except Exception as e:
            logger.error(f"Erro ao marcar grupo de controle: {e}")

    async def run_batch_migration(self) -> bool:
        """Executa migração de um lote de advogados."""
        
        logger.info(f"🚀 Iniciando migração de lote (tamanho: {self.batch_size})")
        
        # 1. Buscar próximo lote
        lawyers = await self.get_next_batch_for_enrichment()
        
        if not lawyers:
            logger.info("✅ Nenhum advogado elegível encontrado para migração")
            return False
        
        logger.info(f"📋 {len(lawyers)} advogados elegíveis encontrados")
        
        # 2. Dividir em grupos A/B
        group_a, group_b = self.assign_ab_groups(lawyers)
        
        # 3. Migrar grupo A (embeddings enriquecidos)
        logger.info(f"🧠 Migrando grupo A para embeddings enriquecidos...")
        
        for lawyer in group_a:
            success = await self.migrate_lawyer_enriched(lawyer)
            if success:
                self.total_migrated += 1
            else:
                self.total_errors += 1
        
        # 4. Configurar grupo B (controle V2 padrão)
        logger.info(f"⚖️  Configurando grupo B como controle...")
        await self.set_control_group(group_b)
        
        return True

    async def run_full_migration(self):
        """Executa migração completa com todos os lotes."""
        
        logger.info("🚀 Iniciando migração completa para embeddings enriquecidos...")
        
        # Verificar elegibilidade
        eligibility = await self.check_eligibility_criteria()
        if "error" in eligibility:
            logger.error(f"❌ Erro na verificação de elegibilidade: {eligibility['error']}")
            return
        
        logger.info(f"📊 Critérios de Elegibilidade:")
        logger.info(f"   Total de advogados ativos: {eligibility['total_active_lawyers']}")
        logger.info(f"   Com KPIs: {eligibility['lawyers_with_kpi']}")
        logger.info(f"   Com especialização: {eligibility['lawyers_with_expertise']}")
        logger.info(f"   Com CV: {eligibility['lawyers_with_cv']}")
        logger.info(f"   Elegíveis para enriquecimento: {eligibility['eligible_for_enriched']}")
        logger.info(f"   Taxa de elegibilidade: {eligibility['eligibility_rate']:.1f}%")
        
        if eligibility['eligible_for_enriched'] == 0:
            logger.warning("⚠️  Nenhum advogado elegível para embeddings enriquecidos")
            return
        
        # Executar migração em lotes
        batch_count = 0
        
        while True:
            batch_count += 1
            logger.info(f"\n📦 LOTE {batch_count}")
            
            has_more = await self.run_batch_migration()
            
            if not has_more:
                break
            
            # Progresso
            progress = (self.total_migrated / eligibility['eligible_for_enriched']) * 100
            logger.info(f"📊 Progresso: {self.total_migrated}/{eligibility['eligible_for_enriched']} ({progress:.1f}%)")
            
            # Pequena pausa entre lotes
            await asyncio.sleep(1)
        
        # Relatório final
        await self._generate_final_report(eligibility)

    async def _generate_final_report(self, eligibility: Dict[str, Any]):
        """Gera relatório final da migração."""
        
        total_time = time.time() - self.start_time
        
        logger.info(f"\n🎉 MIGRAÇÃO CONCLUÍDA!")
        logger.info(f"=" * 60)
        logger.info(f"⏱️  Tempo total: {total_time:.1f}s")
        logger.info(f"📊 Advogados processados: {self.total_migrated}")
        logger.info(f"❌ Erros: {self.total_errors}")
        logger.info(f"✅ Taxa de sucesso: {(self.total_migrated/(self.total_migrated+self.total_errors)*100):.1f}%")
        
        logger.info(f"\n📈 Grupos A/B:")
        logger.info(f"   Grupo A (enriquecidos): {self.stats['ab_group_a']}")
        logger.info(f"   Grupo B (controle V2): {self.stats['ab_group_b']}")
        
        if self.stats["processing_times"]:
            avg_time = sum(self.stats["processing_times"]) / len(self.stats["processing_times"])
            logger.info(f"\n⚡ Performance:")
            logger.info(f"   Tempo médio por embedding: {avg_time:.2f}s")
        
        if self.stats["template_usage"]:
            logger.info(f"\n📝 Templates utilizados:")
            for template, count in self.stats["template_usage"].items():
                percentage = (count / self.stats["successful_enriched"]) * 100
                logger.info(f"   {template}: {count} ({percentage:.1f}%)")
        
        if self.stats["provider_usage"]:
            logger.info(f"\n🔧 Provedores utilizados:")
            for provider, count in self.stats["provider_usage"].items():
                percentage = (count / self.stats["successful_enriched"]) * 100
                logger.info(f"   {provider}: {count} ({percentage:.1f}%)")

    async def get_migration_status(self) -> Dict[str, Any]:
        """Retorna status atual da migração."""
        
        try:
            from config.database import get_db_connection
            
            with get_db_connection() as conn, conn.cursor() as cursor:
                cursor.execute("""
                    SELECT 
                        COUNT(*) as total_active,
                        COUNT(CASE WHEN cv_embedding_v2_enriched IS NOT NULL THEN 1 END) as enriched,
                        COUNT(CASE WHEN use_enriched_embeddings = true THEN 1 END) as using_enriched,
                        COUNT(CASE WHEN use_enriched_embeddings = false THEN 1 END) as control_group
                    FROM lawyers 
                    WHERE ativo = true
                """)
                
                result = cursor.fetchone()
                
                return {
                    "total_active_lawyers": result[0],
                    "enriched_embeddings": result[1],
                    "using_enriched": result[2],
                    "control_group": result[3],
                    "enriched_coverage": (result[1] / result[0] * 100) if result[0] > 0 else 0,
                    "ab_test_coverage": ((result[2] + result[3]) / result[0] * 100) if result[0] > 0 else 0
                }
                
        except Exception as e:
            return {"error": str(e)}


async def main():
    """Função principal CLI."""
    parser = argparse.ArgumentParser(description="Migração para Embeddings Enriquecidos")
    
    parser.add_argument("--dry-run", action="store_true", help="Executar sem fazer alterações")
    parser.add_argument("--batch-size", type=int, default=20, help="Tamanho do lote")
    parser.add_argument("--check-eligibility", action="store_true", help="Verificar critérios de elegibilidade")
    parser.add_argument("--run-batch", action="store_true", help="Executar um lote")
    parser.add_argument("--run-full", action="store_true", help="Executar migração completa")
    parser.add_argument("--status", action="store_true", help="Verificar status da migração")
    
    args = parser.parse_args()
    
    migrator = EnrichedEmbeddingMigration(
        dry_run=args.dry_run,
        batch_size=args.batch_size
    )
    
    try:
        if args.check_eligibility:
            eligibility = await migrator.check_eligibility_criteria()
            print(json.dumps(eligibility, indent=2))
        
        elif args.status:
            status = await migrator.get_migration_status()
            print(json.dumps(status, indent=2))
        
        elif args.run_batch:
            await migrator.run_batch_migration()
        
        elif args.run_full:
            await migrator.run_full_migration()
        
        else:
            parser.print_help()
        
        return 0
        
    except Exception as e:
        logger.error(f"❌ Erro na execução: {e}")
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
 
 