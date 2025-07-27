#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Teste da Fase 2: Adaptação da Lógica de Similaridade
====================================================

Script para validar que a adaptação da lógica de similaridade do 
algoritmo_match.py para o contexto de parcerias está funcionando corretamente.

Testa:
1. PartnershipSimilarityService funcionando corretamente
2. Matriz de sinergia entre áreas do direito
3. Busca por complementaridade vs profundidade
4. Integração com PartnershipRecommendationService
5. Novos campos similarity_score e similarity_breakdown
"""

import asyncio
import sys
from pathlib import Path
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock

# Adicionar path do backend
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))


class Fase2IntegrationTester:
    """Testa a integração da Fase 2 do plano de unificação."""
    
    def __init__(self):
        self.results = {}
        self.mock_db = None
    
    async def run_all_tests(self):
        """Executa todos os testes da Fase 2."""
        
        print("🔬 TESTE DA FASE 2: ADAPTAÇÃO DA LÓGICA DE SIMILARIDADE")
        print("=" * 65)
        print("🎯 Validando Busca por Complementaridade e Profundidade")
        print()
        
        # Setup
        await self.setup_test_environment()
        
        # Teste 1: PartnershipSimilarityService funcionando
        await self.test_similarity_service()
        
        # Teste 2: Matriz de sinergia
        await self.test_synergy_matrix()
        
        # Teste 3: Estratégias de busca  
        await self.test_search_strategies()
        
        # Teste 4: Integração com PartnershipRecommendationService
        await self.test_partnership_integration()
        
        # Teste 5: Novos campos na recomendação
        await self.test_new_recommendation_fields()
        
        # Resumo final
        self.print_final_summary()
    
    async def setup_test_environment(self):
        """Setup do ambiente de teste."""
        
        print("🔧 SETUP: Preparando ambiente de teste")
        print("-" * 40)
        
        # Mock do AsyncSession
        self.mock_db = AsyncMock()
        
        print("✅ Mock da database configurado")
        print("✅ Ambiente de teste pronto")
        print()
    
    async def test_similarity_service(self):
        """Testa o PartnershipSimilarityService standalone."""
        
        print("🧮 TESTE 1: PartnershipSimilarityService")
        print("-" * 40)
        
        try:
            from services.partnership_similarity_service import PartnershipSimilarityService, SimilarityResult
            
            # Criar service
            similarity_service = PartnershipSimilarityService()
            
            # Dados de teste
            target_lawyer = {
                "id": "target_001",
                "name": "Dr. João Tributarista",
                "expertise_areas": ["direito_tributario", "direito_empresarial"],
                "anos_experiencia": 8,
                "success_rate": 0.85,
                "cases_30d": 15,
                "rating": 4.2
            }
            
            candidate_lawyer = {
                "id": "candidate_001", 
                "name": "Dr. Maria Societária",
                "expertise_areas": ["direito_societario", "m_and_a"],
                "anos_experiencia": 6,
                "success_rate": 0.88,
                "cases_30d": 12,
                "rating": 4.5
            }
            
            # Testar análise de similaridade
            result = await similarity_service.analyze_partnership_similarity(
                target_lawyer, candidate_lawyer, strategy="hybrid"
            )
            
            # Validar resultado
            assert isinstance(result, SimilarityResult)
            assert result.target_lawyer_id == "target_001"
            assert result.candidate_lawyer_id == "candidate_001"
            assert 0.0 <= result.synergy_score <= 1.0
            assert 0.0 <= result.complementarity_score <= 1.0
            assert 0.0 <= result.depth_score <= 1.0
            
            print(f"✅ PartnershipSimilarityService funcionando")
            print(f"   📊 Synergy Score: {result.synergy_score:.3f}")
            print(f"   📊 Complementarity: {result.complementarity_score:.3f}")
            print(f"   📊 Depth: {result.depth_score:.3f}")
            print(f"   🎯 Strategy: {result.strategy_used}")
            print(f"   🔍 Confidence: {result.confidence:.3f}")
            print(f"   💡 Reason: {result.synergy_reason}")
            
            self.results["similarity_service"] = True
            
        except Exception as e:
            print(f"❌ Erro no teste do PartnershipSimilarityService: {e}")
            self.results["similarity_service"] = False
        
        print()
    
    async def test_synergy_matrix(self):
        """Testa a matriz de sinergia entre áreas."""
        
        print("🗺️  TESTE 2: Matriz de Sinergia")
        print("-" * 40)
        
        try:
            from services.partnership_similarity_service import PartnershipSimilarityService
            
            service = PartnershipSimilarityService()
            matrix = service.synergy_matrix
            
            # Validar estrutura da matriz
            assert isinstance(matrix, dict)
            assert len(matrix) > 0
            
            # Testar sinergias específicas conhecidas
            assert matrix.get("direito_tributario", {}).get("direito_empresarial", 0) > 0.8
            assert matrix.get("m_and_a", {}).get("direito_societario", 0) > 0.8
            assert matrix.get("direito_trabalhista", {}).get("previdenciario", 0) > 0.7
            
            # Validar simetria (A->B = B->A)
            for area1, synergies in matrix.items():
                for area2, score in synergies.items():
                    reverse_score = matrix.get(area2, {}).get(area1, 0)
                    assert score == reverse_score, f"Assimetria: {area1}->{area2} = {score}, {area2}->{area1} = {reverse_score}"
            
            print(f"✅ Matriz de sinergia válida")
            print(f"   📊 {len(matrix)} áreas mapeadas")
            print(f"   🔗 Tributário ↔ Empresarial: {matrix['direito_tributario']['direito_empresarial']:.2f}")
            print(f"   🔗 M&A ↔ Societário: {matrix['m_and_a']['direito_societario']:.2f}")
            print(f"   🔗 Trabalhista ↔ Previdenciário: {matrix['direito_trabalhista']['previdenciario']:.2f}")
            
            self.results["synergy_matrix"] = True
            
        except Exception as e:
            print(f"❌ Erro no teste da matriz de sinergia: {e}")
            self.results["synergy_matrix"] = False
        
        print()
    
    async def test_search_strategies(self):
        """Testa as diferentes estratégias de busca."""
        
        print("🎯 TESTE 3: Estratégias de Busca")
        print("-" * 40)
        
        try:
            from services.partnership_similarity_service import PartnershipSimilarityService
            
            service = PartnershipSimilarityService()
            
            # Cenário 1: Alta complementaridade (Tributário + Societário)
            complementary_target = {
                "id": "comp_target",
                "expertise_areas": ["direito_tributario"],
                "anos_experiencia": 10,
                "success_rate": 0.9,
                "cases_30d": 20,
                "rating": 4.8
            }
            
            complementary_candidate = {
                "id": "comp_candidate",
                "expertise_areas": ["direito_societario"],
                "anos_experiencia": 8,
                "success_rate": 0.85,
                "cases_30d": 15,
                "rating": 4.5
            }
            
            # Testar estratégia de complementaridade
            comp_result = await service.analyze_partnership_similarity(
                complementary_target, complementary_candidate, strategy="complementarity"
            )
            
            assert comp_result.strategy_used == "complementarity"
            assert comp_result.complementarity_score > 0.7
            print(f"✅ Estratégia de complementaridade: {comp_result.complementarity_score:.3f}")
            
            # Cenário 2: Alta profundidade (ambos M&A experientes)
            depth_target = {
                "id": "depth_target",
                "expertise_areas": ["m_and_a", "direito_empresarial"],
                "anos_experiencia": 12,
                "success_rate": 0.92,
                "cases_30d": 25,
                "rating": 4.9
            }
            
            depth_candidate = {
                "id": "depth_candidate", 
                "expertise_areas": ["m_and_a", "direito_bancario"],
                "anos_experiencia": 10,
                "success_rate": 0.88,
                "cases_30d": 20,
                "rating": 4.7
            }
            
            # Testar estratégia de profundidade
            depth_result = await service.analyze_partnership_similarity(
                depth_target, depth_candidate, strategy="depth"
            )
            
            assert depth_result.strategy_used == "depth"
            print(f"✅ Estratégia de profundidade: {depth_result.depth_score:.3f}")
            
            # Testar estratégia híbrida
            hybrid_result = await service.analyze_partnership_similarity(
                complementary_target, complementary_candidate, strategy="hybrid"
            )
            
            print(f"✅ Estratégia híbrida: {hybrid_result.strategy_used} - {hybrid_result.synergy_score:.3f}")
            
            self.results["search_strategies"] = True
            
        except Exception as e:
            print(f"❌ Erro no teste de estratégias: {e}")
            self.results["search_strategies"] = False
        
        print()
    
    async def test_partnership_integration(self):
        """Testa a integração com PartnershipRecommendationService."""
        
        print("🔗 TESTE 4: Integração com PartnershipRecommendationService")
        print("-" * 40)
        
        try:
            from services.partnership_recommendation_service import PartnershipRecommendationService
            
            # Criar service
            service = PartnershipRecommendationService(self.mock_db)
            
            # Dados de teste
            target_lawyer = {
                "id": "integration_target",
                "name": "Dr. Ana Silva",
                "expertise_areas": ["direito_digital", "propriedade_intelectual"],
                "anos_experiencia": 7,
                "success_rate": 0.82
            }
            
            candidate_lawyer = {
                "id": "integration_candidate",
                "name": "Dr. Carlos Santos", 
                "expertise_areas": ["regulatorio", "direito_empresarial"],
                "anos_experiencia": 9,
                "success_rate": 0.87
            }
            
            # Testar método calculate_similarity_scores
            similarity_result = await service.calculate_similarity_scores(
                target_lawyer, candidate_lawyer
            )
            
            # Validar estrutura do resultado
            assert "similarity_score" in similarity_result
            assert "similarity_breakdown" in similarity_result
            assert "source" in similarity_result
            
            similarity_score = similarity_result["similarity_score"]
            assert 0.0 <= similarity_score <= 1.0
            
            print(f"✅ Integração funcionando")
            print(f"   📊 Similarity Score: {similarity_score:.3f}")
            print(f"   📝 Source: {similarity_result['source']}")
            
            if "similarity_breakdown" in similarity_result:
                breakdown = similarity_result["similarity_breakdown"]
                print(f"   🔍 Strategy: {breakdown.get('strategy_used', 'N/A')}")
                print(f"   🎯 Confidence: {breakdown.get('confidence', 0):.3f}")
            
            self.results["partnership_integration"] = True
            
        except Exception as e:
            print(f"❌ Erro na integração: {e}")
            self.results["partnership_integration"] = False
        
        print()
    
    async def test_new_recommendation_fields(self):
        """Testa os novos campos na PartnershipRecommendation."""
        
        print("📋 TESTE 5: Novos Campos na Recomendação")
        print("-" * 40)
        
        try:
            from services.partnership_recommendation_service import PartnershipRecommendation
            
            # Criar recomendação com novos campos
            recommendation = PartnershipRecommendation(
                lawyer_id="test_lawyer",
                lawyer_name="Dr. Teste",
                firm_name="Teste & Associados",
                compatibility_clusters=["direito_digital"],
                complementarity_score=0.8,
                diversity_score=0.7,
                momentum_score=0.6,
                reputation_score=0.9,
                firm_synergy_score=0.75,
                final_score=0.77,
                recommendation_reason="Teste de recomendação",
                # 🆕 FASE 2: Novos campos
                similarity_score=0.85,
                similarity_breakdown={
                    "complementarity": 0.9,
                    "depth": 0.8,
                    "strategy_used": "hybrid",
                    "confidence": 0.85
                }
            )
            
            # Validar novos campos
            assert hasattr(recommendation, 'similarity_score')
            assert hasattr(recommendation, 'similarity_breakdown')
            assert recommendation.similarity_score == 0.85
            assert recommendation.similarity_breakdown["strategy_used"] == "hybrid"
            
            print("✅ Novos campos similarity_score e similarity_breakdown presentes")
            print(f"   📊 Similarity Score: {recommendation.similarity_score}")
            print(f"   📈 Strategy: {recommendation.similarity_breakdown['strategy_used']}")
            print(f"   🎯 Confidence: {recommendation.similarity_breakdown['confidence']}")
            
            self.results["new_recommendation_fields"] = True
            
        except Exception as e:
            print(f"❌ Erro nos novos campos: {e}")
            self.results["new_recommendation_fields"] = False
        
        print()
    
    def print_final_summary(self):
        """Imprime resumo final dos testes."""
        
        print("=" * 65)
        print("📋 RESUMO DOS TESTES - FASE 2")
        print("=" * 65)
        
        total_tests = len(self.results)
        passed_tests = sum(1 for result in self.results.values() if result)
        
        test_names = {
            "similarity_service": "PartnershipSimilarityService",
            "synergy_matrix": "Matriz de Sinergia",
            "search_strategies": "Estratégias de Busca", 
            "partnership_integration": "Integração com PartnershipRecommendationService",
            "new_recommendation_fields": "Novos Campos na Recomendação"
        }
        
        for test_key, passed in self.results.items():
            status = "✅ PASSOU" if passed else "❌ FALHOU"
            test_name = test_names.get(test_key, test_key)
            print(f"{status:<10} {test_name}")
        
        print()
        print(f"📊 RESULTADO GERAL: {passed_tests}/{total_tests} testes passaram")
        
        if passed_tests == total_tests:
            print("🎉 FASE 2 IMPLEMENTADA COM SUCESSO!")
            print("✅ Lógica de similaridade adaptada do algoritmo_match.py")
            print("✅ Matriz de sinergia entre áreas funcionando")
            print("✅ Busca por complementaridade e profundidade implementada")
            print("✅ Integração com PartnershipRecommendationService concluída")
            print("✅ Similarity scores incluídos nas recomendações")
        else:
            print("⚠️  Alguns testes falharam - revisar implementação")
        
        print()
        print("🚀 PRÓXIMOS PASSOS:")
        print("   1. Executar testes em ambiente real")
        print("   2. Ajustar pesos do algoritmo baseado nos resultados")
        print("   3. Iniciar Fase 3: Unificação da Estrutura de Dados e Cache")
        print("   4. Implementar cache Redis otimizado para features")


async def main():
    """Função principal."""
    
    tester = Fase2IntegrationTester()
    await tester.run_all_tests()


if __name__ == "__main__":
    asyncio.run(main()) 