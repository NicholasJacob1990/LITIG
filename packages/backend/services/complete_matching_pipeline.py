# -*- coding: utf-8 -*-
"""
Pipeline Completa de Matching com Enriquecimento Automático
==========================================================
Integra o enriquecimento de perfis com o algoritmo de ranqueamento.
Fluxo: Enriquecimento → Ranqueamento → Resultados Explicáveis
"""

import asyncio
import logging
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime

# Imports locais
try:
    from academic_enrichment_pipeline import preprocess_lawyers_for_ranking, EnrichmentResult
    from algoritmo_match import MatchmakingAlgorithm, Case, Lawyer
except ImportError:
    # Fallback para execução standalone
    import sys
    sys.path.append('..')
    from academic_enrichment_pipeline import preprocess_lawyers_for_ranking, EnrichmentResult
    from algoritmo_match import MatchmakingAlgorithm, Case, Lawyer

# Logger para pipeline completa
PIPELINE_LOGGER = logging.getLogger("matching.complete_pipeline")


class EnhancedMatchingResult:
    """Resultado expandido do matching com dados de enriquecimento."""
    
    def __init__(
        self,
        case: Case,
        ranked_lawyers: List[Lawyer],
        enrichment_results: List[EnrichmentResult],
        ranking_metadata: Dict[str, Any]
    ):
        self.case = case
        self.ranked_lawyers = ranked_lawyers
        self.enrichment_results = enrichment_results
        self.ranking_metadata = ranking_metadata
        self.timestamp = datetime.now()
    
    def get_enrichment_summary(self) -> Dict[str, Any]:
        """Gera resumo estatístico do enriquecimento."""
        if not self.enrichment_results:
            return {"total": 0, "successful": 0, "failed": 0, "sources": {}}
        
        total = len(self.enrichment_results)
        successful = sum(1 for r in self.enrichment_results if r.success)
        failed = total - successful
        
        # Distribuição por fonte
        sources = {}
        for result in self.enrichment_results:
            sources[result.source] = sources.get(result.source, 0) + 1
        
        # Tempo médio de processamento
        processing_times = [r.processing_time_sec for r in self.enrichment_results if r.success]
        avg_processing_time = sum(processing_times) / len(processing_times) if processing_times else 0
        
        return {
            "total": total,
            "successful": successful,
            "failed": failed,
            "success_rate": successful / total if total > 0 else 0,
            "sources": sources,
            "avg_processing_time_sec": round(avg_processing_time, 2)
        }
    
    def get_feature_coverage(self) -> Dict[str, Dict[str, Any]]:
        """Analisa cobertura de features após enriquecimento."""
        coverage = {}
        
        for lawyer in self.ranked_lawyers:
            lawyer_id = lawyer.id
            
            # Analisar quais features foram enriquecidas
            features_enriched = {}
            
            # Feature S: Publicações acadêmicas
            features_enriched['publications'] = hasattr(lawyer, 'academic_publications') and len(lawyer.academic_publications) > 0
            
            # Feature E: Experiência prática
            features_enriched['experience'] = lawyer.curriculo_json.get('anos_experiencia', 0) > 0
            
            # Feature M: Maturidade profissional
            features_enriched['maturity'] = lawyer.maturity_data is not None
            
            # Feature P: Informações de preço
            features_enriched['pricing'] = (
                lawyer.avg_hourly_fee > 0 or 
                lawyer.flat_fee is not None or 
                lawyer.success_fee_pct is not None
            )
            
            # Feature Q: Qualificação (titulação)
            features_enriched['qualifications'] = len(lawyer.curriculo_json.get('pos_graduacoes', [])) > 0
            
            coverage[lawyer_id] = {
                'features_enriched': features_enriched,
                'total_features': sum(features_enriched.values()),
                'coverage_percentage': sum(features_enriched.values()) / len(features_enriched)
            }
        
        return coverage
    
    def to_dict(self) -> Dict[str, Any]:
        """Converte resultado para dicionário serializável."""
        return {
            "case_id": self.case.id,
            "case_area": self.case.area,
            "timestamp": self.timestamp.isoformat(),
            "ranked_lawyers": [
                {
                    "id": lawyer.id,
                    "nome": lawyer.nome,
                    "scores": lawyer.scores,
                    "enriched": lawyer.scores.get('enriched', False)
                }
                for lawyer in self.ranked_lawyers
            ],
            "enrichment_summary": self.get_enrichment_summary(),
            "feature_coverage": self.get_feature_coverage(),
            "ranking_metadata": self.ranking_metadata
        }


class CompleteMatchingPipeline:
    """Pipeline completa: Enriquecimento + Ranqueamento."""
    
    def __init__(self):
        self.algorithm = MatchmakingAlgorithm()
    
    async def execute_complete_matching(
        self,
        case: Case,
        candidate_lawyers: List[Lawyer],
        *,
        top_n: int = 5,
        preset: str = "balanced",
        enrich_profiles: bool = True,
        max_concurrent_enrichment: int = 3,
        use_openai: bool = True,
        use_perplexity: bool = True,
        model_version: Optional[str] = None,
        exclude_ids: Optional[set] = None
    ) -> EnhancedMatchingResult:
        """
        Executa pipeline completa de matching com enriquecimento opcional.
        
        Args:
            case: Caso jurídico para matching
            candidate_lawyers: Lista de advogados candidatos
            top_n: Número de advogados a retornar
            preset: Preset de pesos do algoritmo
            enrich_profiles: Se deve enriquecer perfis antes do ranking
            max_concurrent_enrichment: Máximo de enriquecimentos simultâneos
            use_openai: Se deve usar OpenAI Deep Research
            use_perplexity: Se deve usar Perplexity
            model_version: Versão do modelo para testes A/B
            exclude_ids: IDs de advogados a excluir
        
        Returns:
            Resultado expandido com dados de enriquecimento e ranking
        """
        
        start_time = datetime.now()
        
        PIPELINE_LOGGER.info(f"Iniciando matching completo para caso {case.id}", {
            "case_area": case.area,
            "candidate_count": len(candidate_lawyers),
            "enrich_profiles": enrich_profiles,
            "preset": preset,
            "top_n": top_n
        })
        
        enrichment_results = []
        
        # ETAPA 1: Enriquecimento de perfis (opcional)
        if enrich_profiles:
            PIPELINE_LOGGER.info("Iniciando enriquecimento de perfis")
            
            try:
                enriched_lawyers, enrichment_results = await preprocess_lawyers_for_ranking(
                    candidate_lawyers,
                    case.area,
                    max_concurrent=max_concurrent_enrichment,
                    use_openai=use_openai,
                    use_perplexity=use_perplexity
                )
                
                # Estatísticas de enriquecimento
                successful = sum(1 for r in enrichment_results if r.success)
                PIPELINE_LOGGER.info(f"Enriquecimento concluído: {successful}/{len(enrichment_results)} sucessos")
                
                # Usar advogados enriquecidos
                lawyers_for_ranking = enriched_lawyers
                
            except Exception as e:
                PIPELINE_LOGGER.error(f"Erro no enriquecimento: {e}")
                # Fallback: usar advogados originais
                lawyers_for_ranking = candidate_lawyers
                enrichment_results = []
        else:
            lawyers_for_ranking = candidate_lawyers
        
        # ETAPA 2: Execução do algoritmo de ranqueamento
        PIPELINE_LOGGER.info("Iniciando ranqueamento")
        
        try:
            ranked_lawyers = await self.algorithm.rank(
                case=case,
                lawyers=lawyers_for_ranking,
                top_n=top_n,
                preset=preset,
                model_version=model_version,
                exclude_ids=exclude_ids
            )
            
            PIPELINE_LOGGER.info(f"Ranqueamento concluído: {len(ranked_lawyers)} advogados ranqueados")
            
        except Exception as e:
            PIPELINE_LOGGER.error(f"Erro no ranqueamento: {e}")
            raise
        
        # ETAPA 3: Coleta de metadados do ranking
        total_time = (datetime.now() - start_time).total_seconds()
        
        ranking_metadata = {
            "algorithm_version": getattr(self.algorithm, 'algorithm_version', 'unknown'),
            "preset_used": preset,
            "model_version": model_version,
            "total_processing_time_sec": round(total_time, 2),
            "enrichment_enabled": enrich_profiles,
            "excluded_count": len(exclude_ids) if exclude_ids else 0,
            "candidates_processed": len(candidate_lawyers),
            "final_ranking_size": len(ranked_lawyers)
        }
        
        # ETAPA 4: Construir resultado expandido
        result = EnhancedMatchingResult(
            case=case,
            ranked_lawyers=ranked_lawyers,
            enrichment_results=enrichment_results,
            ranking_metadata=ranking_metadata
        )
        
        # Log final
        PIPELINE_LOGGER.info(f"Pipeline completa finalizada para caso {case.id}", {
            "total_time_sec": total_time,
            "ranking_size": len(ranked_lawyers),
            "enrichment_success_rate": result.get_enrichment_summary().get("success_rate", 0)
        })
        
        return result
    
    async def batch_matching(
        self,
        cases_and_candidates: List[Tuple[Case, List[Lawyer]]],
        **kwargs
    ) -> List[EnhancedMatchingResult]:
        """Executa matching para múltiplos casos em paralelo."""
        
        tasks = [
            self.execute_complete_matching(case, lawyers, **kwargs)
            for case, lawyers in cases_and_candidates
        ]
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Processar resultados e exceptions
        processed_results = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                PIPELINE_LOGGER.error(f"Erro no matching do caso {i}: {result}")
                # Criar resultado de erro
                case, lawyers = cases_and_candidates[i]
                error_result = EnhancedMatchingResult(
                    case=case,
                    ranked_lawyers=[],
                    enrichment_results=[],
                    ranking_metadata={"error": str(result)}
                )
                processed_results.append(error_result)
            else:
                processed_results.append(result)
        
        return processed_results


# Função de conveniência para uso direto
async def complete_lawyer_matching(
    case: Case,
    candidate_lawyers: List[Lawyer],
    **kwargs
) -> EnhancedMatchingResult:
    """
    Função de conveniência para matching completo com enriquecimento.
    
    Usage:
        result = await complete_lawyer_matching(case, lawyers, preset="economic")
        top_lawyer = result.ranked_lawyers[0]
        enrichment_stats = result.get_enrichment_summary()
    """
    pipeline = CompleteMatchingPipeline()
    return await pipeline.execute_complete_matching(case, candidate_lawyers, **kwargs)


# Exemplo de uso prático
if __name__ == "__main__":
    
    async def demo_complete_pipeline():
        """Demonstração da pipeline completa."""
        from algoritmo_match import Case, Lawyer, KPI
        import numpy as np
        
        # Criar caso de teste
        case = Case(
            id="CASO_DEMO_COMPLETO",
            area="Direito Empresarial",
            subarea="Contratos",
            urgency_h=48,
            coords=(-23.5505, -46.6333),
            complexity="HIGH",
            expected_fee_max=5000.0,  # Orçamento médio-alto
            summary_embedding=np.random.rand(384)
        )
        
        # Criar advogados candidatos
        lawyers = []
        for i in range(5):
            lawyer = Lawyer(
                id=f"ADV_DEMO_{i}",
                nome=f"Dr. Advogado {i}",
                tags_expertise=["empresarial", "contratos"],
                geo_latlon=(-23.5505 + (i * 0.01), -46.6333 + (i * 0.01)),
                curriculo_json={
                    "anos_experiencia": 5 + i * 2,
                    "pos_graduacoes": [{"nivel": "mestrado", "area": "Direito Empresarial"}] if i % 2 == 0 else []
                },
                kpi=KPI(
                    success_rate=0.7 + (i * 0.05),
                    cases_30d=10 + i,
                    avaliacao_media=4.0 + (i * 0.1),
                    tempo_resposta_h=24 - (i * 2),
                    active_cases=i
                ),
                avg_hourly_fee=200 + (i * 50)
            )
            lawyers.append(lawyer)
        
        print("🚀 Executando Pipeline Completa de Matching...")
        print("=" * 60)
        
        # Executar pipeline completa
        result = await complete_lawyer_matching(
            case=case,
            candidate_lawyers=lawyers,
            top_n=3,
            preset="balanced",
            enrich_profiles=False,  # Desabilitado para demo sem APIs
            use_openai=False,
            use_perplexity=False
        )
        
        # Exibir resultados
        print(f"\n📊 Resultados do Matching:")
        print(f"Caso: {result.case.id} ({result.case.area})")
        print(f"Timestamp: {result.timestamp}")
        
        print(f"\n🏆 Top {len(result.ranked_lawyers)} Advogados:")
        for i, lawyer in enumerate(result.ranked_lawyers, 1):
            scores = lawyer.scores
            print(f"{i}º {lawyer.nome}")
            print(f"   Score Final: {scores.get('fair_base', 0):.3f}")
            print(f"   LTR Score: {scores.get('ltr', 0):.3f}")
            print(f"   Preset: {scores.get('preset', 'N/A')}")
            print(f"   Enriquecido: {'✅' if scores.get('enriched', False) else '❌'}")
        
        print(f"\n📈 Estatísticas de Enriquecimento:")
        enrich_summary = result.get_enrichment_summary()
        print(f"   Total processados: {enrich_summary['total']}")
        print(f"   Sucessos: {enrich_summary['successful']}")
        print(f"   Taxa de sucesso: {enrich_summary['success_rate']:.1%}")
        
        print(f"\n🔧 Metadados do Ranking:")
        metadata = result.ranking_metadata
        print(f"   Tempo total: {metadata['total_processing_time_sec']}s")
        print(f"   Preset usado: {metadata['preset_used']}")
        print(f"   Candidatos processados: {metadata['candidates_processed']}")
        
        print(f"\n✅ Pipeline executada com sucesso!")
        
        # Exemplo de serialização para logs/API
        serialized = result.to_dict()
        print(f"\n📄 Resultado serializado disponível com {len(serialized)} campos")
    
    # Executar demonstração
    import asyncio
    asyncio.run(demo_complete_pipeline()) 