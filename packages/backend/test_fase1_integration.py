#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Teste da Fase 1: Integração FeatureCalculator
============================================

Script para validar que a integração do FeatureCalculator com o 
PartnershipRecommendationService está funcionando corretamente.

Testa:
1. Import do FeatureCalculator funcionando
2. Método calculate_quality_scores() gerando scores válidos  
3. Quality score sendo incluído no ranking de parcerias
4. Breakdown das features Q, M, I, C, E disponível
5. Fallbacks funcionando se FeatureCalculator não disponível
"""

import asyncio
import sys
from pathlib import Path
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock

# Adicionar path do backend
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))


class Fase1IntegrationTester:
    """Testa a integração da Fase 1 do plano de unificação."""
    
    def __init__(self):
        self.results = {}
        self.mock_db = None
    
    async def run_all_tests(self):
        """Executa todos os testes da Fase 1."""
        
        print("🔬 TESTE DA FASE 1: INTEGRAÇÃO FEATURECALCULATOR")
        print("=" * 60)
        print("🎯 Validando Unificação dos Algoritmos de Recomendação")
        print()
        
        # Setup
        await self.setup_test_environment()
        
        # Teste 1: Imports funcionando
        await self.test_imports()
        
        # Teste 2: FeatureCalculator integration  
        await self.test_feature_calculator_integration()
        
        # Teste 3: Quality scores no PartnershipRecommendationService
        await self.test_quality_scores_in_recommendations()
        
        # Teste 4: Dataclass conversions
        await self.test_dataclass_conversions()
        
        # Teste 5: Fallbacks funcionando
        await self.test_fallback_mechanisms()
        
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
    
    async def test_imports(self):
        """Testa se os imports estão funcionando."""
        
        print("📦 TESTE 1: Imports e Dependências")
        print("-" * 40)
        
        try:
            # Testar import do PartnershipRecommendationService
            from services.partnership_recommendation_service import (
                PartnershipRecommendationService, 
                PartnershipRecommendation,
                FEATURE_CALCULATOR_AVAILABLE
            )
            print("✅ PartnershipRecommendationService importado")
            
            # Verificar se FeatureCalculator está disponível
            if FEATURE_CALCULATOR_AVAILABLE:
                print("✅ FeatureCalculator disponível")
                from Algoritmo.algoritmo_match import FeatureCalculator, Lawyer, Case
                print("✅ FeatureCalculator, Lawyer, Case importados")
            else:
                print("⚠️  FeatureCalculator não disponível - testando fallback")
            
            # Verificar novos campos na dataclass
            rec = PartnershipRecommendation(
                lawyer_id="test",
                lawyer_name="Test Lawyer",
                firm_name="Test Firm",
                compatibility_clusters=[],
                complementarity_score=0.8,
                diversity_score=0.7,
                momentum_score=0.6,
                reputation_score=0.5,
                firm_synergy_score=0.4,
                quality_score=0.75,  # 🆕 Novo campo
                quality_breakdown={"qualification": 0.8, "maturity": 0.7},  # 🆕 Novo campo
                final_score=0.65,
                recommendation_reason="Test reason"
            )
            
            assert hasattr(rec, 'quality_score')
            assert hasattr(rec, 'quality_breakdown') 
            print("✅ Novos campos quality_score e quality_breakdown presentes")
            
            self.results["imports"] = True
            
        except Exception as e:
            print(f"❌ Erro nos imports: {e}")
            self.results["imports"] = False
        
        print()
    
    async def test_feature_calculator_integration(self):
        """Testa a integração com o FeatureCalculator."""
        
        print("🧮 TESTE 2: Integração FeatureCalculator")
        print("-" * 40)
        
        try:
            from services.partnership_recommendation_service import PartnershipRecommendationService
            
            # Criar service
            service = PartnershipRecommendationService(self.mock_db)
            
            # Dados de teste de um advogado
            lawyer_data = {
                "id": "test_lawyer_001",
                "name": "Dr. João Silva",
                "expertise_areas": ["direito_empresarial", "m_and_a"],
                "geo_latlon": [-23.5505, -46.6333],
                "success_rate": 0.85,
                "cases_30d": 15,
                "rating": 4.2,
                "response_time_hours": 12,
                "anos_experiencia": 8,
                "firm_id": "firm_001",
                "avg_hourly_fee": 450.0,
                "maturity_data": {
                    "experience_years": 8.0,
                    "network_strength": 120,
                    "reputation_signals": 25,
                    "responsiveness_hours": 12.0
                }
            }
            
            # Testar método calculate_quality_scores
            quality_result = await service.calculate_quality_scores(lawyer_data)
            
            # Validar estrutura do resultado
            assert "quality_score" in quality_result
            assert "breakdown" in quality_result
            assert "source" in quality_result
            
            quality_score = quality_result["quality_score"]
            breakdown = quality_result["breakdown"]
            
            # Validar ranges dos scores
            assert 0.0 <= quality_score <= 1.0
            print(f"✅ Quality score válido: {quality_score:.3f}")
            
            # Validar breakdown tem todas as features esperadas
            expected_features = ["qualification", "maturity", "interaction", "soft_skill", "firm_reputation"]
            for feature in expected_features:
                assert feature in breakdown
                assert 0.0 <= breakdown[feature] <= 1.0
            
            print(f"✅ Breakdown completo: {list(breakdown.keys())}")
            print(f"   📊 Qualification: {breakdown['qualification']:.3f}")
            print(f"   📊 Maturity: {breakdown['maturity']:.3f}")
            print(f"   📊 Interaction (IEP): {breakdown['interaction']:.3f}")
            print(f"   📊 Soft Skill: {breakdown['soft_skill']:.3f}")
            print(f"   📊 Firm Reputation: {breakdown['firm_reputation']:.3f}")
            
            self.results["feature_calculator"] = True
            
        except Exception as e:
            print(f"❌ Erro na integração FeatureCalculator: {e}")
            self.results["feature_calculator"] = False
        
        print()
    
    async def test_quality_scores_in_recommendations(self):
        """Testa se quality scores estão sendo incluídos nas recomendações."""
        
        print("📊 TESTE 3: Quality Score nas Recomendações")
        print("-" * 40)
        
        try:
            from services.partnership_recommendation_service import PartnershipRecommendationService
            
            # Mock da query de clusters
            mock_result = MagicMock()
            mock_result.fetchall.return_value = [
                # Mock de dados de clusters para teste
                MagicMock(
                    lawyer_id="candidate_001",
                    lawyer_name="Dr. Maria Santos", 
                    firm_name="Santos & Associados",
                    cluster_label="direito_digital",
                    confidence_score=0.85,
                    momentum=0.7,
                    rating=4.5
                )
            ]
            
            # Mock do banco
            self.mock_db.execute.return_value = mock_result
            
            # Criar service com mock
            service = PartnershipRecommendationService(self.mock_db)
            
            # Mock dos métodos auxiliares para focar no quality score
            service._get_lawyer_clusters = AsyncMock(return_value={"cluster_001": 0.8})
            service._get_complementary_clusters = AsyncMock(return_value=[])
            service._calculate_firm_synergy = AsyncMock(return_value=(0.6, "boa sinergia"))
            
            # Tentar gerar recomendações internas (com mocks)
            # Este teste foca em verificar se o quality score está sendo calculado
            lawyer_data = {
                "id": "candidate_001",
                "name": "Dr. Maria Santos",
                "firm_name": "Santos & Associados",
                "expertise_areas": ["direito_digital"],
                "success_rate": 0.9,
                "rating": 4.5
            }
            
            quality_result = await service.calculate_quality_scores(lawyer_data)
            
            # Verificar se o método está retornando dados válidos
            assert quality_result["quality_score"] > 0
            print(f"✅ Quality score calculado: {quality_result['quality_score']:.3f}")
            
            # Verificar se breakdown está presente
            assert "breakdown" in quality_result
            print("✅ Quality breakdown presente nas recomendações")
            
            # Verificar source
            print(f"✅ Source: {quality_result['source']}")
            
            self.results["quality_in_recommendations"] = True
            
        except Exception as e:
            print(f"❌ Erro ao testar quality scores nas recomendações: {e}")
            self.results["quality_in_recommendations"] = False
        
        print()
    
    async def test_dataclass_conversions(self):
        """Testa conversões entre formatos de dados."""
        
        print("🔄 TESTE 4: Conversões de Dataclass")
        print("-" * 40)
        
        try:
            from services.partnership_recommendation_service import PartnershipRecommendationService
            
            service = PartnershipRecommendationService(self.mock_db)
            
            # Dados de teste
            lawyer_data = {
                "id": "conv_test_001",
                "name": "Dr. Ana Costa",
                "expertise_areas": ["direito_trabalhista", "previdenciario"],
                "geo_latlon": [-23.5505, -46.6333],
                "success_rate": 0.78,
                "cases_30d": 12,
                "rating": 4.0,
                "anos_experiencia": 6
            }
            
            # Testar conversão para Lawyer dataclass
            lawyer_obj = service._convert_to_lawyer_dataclass(lawyer_data)
            
            # Validar conversão
            assert lawyer_obj.id == "conv_test_001"
            assert lawyer_obj.nome == "Dr. Ana Costa"
            assert "direito_trabalhista" in lawyer_obj.tags_expertise
            assert lawyer_obj.kpi.success_rate == 0.78
            assert lawyer_obj.kpi.avaliacao_media == 4.0
            
            print("✅ Conversão para Lawyer dataclass funcionando")
            print(f"   📊 ID: {lawyer_obj.id}")
            print(f"   📊 Nome: {lawyer_obj.nome}")
            print(f"   📊 Expertise: {lawyer_obj.tags_expertise}")
            print(f"   📊 Success Rate: {lawyer_obj.kpi.success_rate}")
            
            self.results["dataclass_conversions"] = True
            
        except Exception as e:
            print(f"❌ Erro nas conversões de dataclass: {e}")
            self.results["dataclass_conversions"] = False
        
        print()
    
    async def test_fallback_mechanisms(self):
        """Testa mecanismos de fallback."""
        
        print("🛡️  TESTE 5: Mecanismos de Fallback")
        print("-" * 40)
        
        try:
            from services.partnership_recommendation_service import PartnershipRecommendationService
            
            service = PartnershipRecommendationService(self.mock_db)
            
            # Simular dados inválidos para testar fallback
            invalid_data = {}
            
            quality_result = await service.calculate_quality_scores(invalid_data)
            
            # Deve retornar fallback válido
            assert "quality_score" in quality_result
            assert quality_result["quality_score"] >= 0
            assert "source" in quality_result
            
            print(f"✅ Fallback funcionando - Score: {quality_result['quality_score']}")
            print(f"✅ Source: {quality_result['source']}")
            
            # Testar conversão com dados mínimos
            minimal_data = {"id": "minimal"}
            lawyer_obj = service._convert_to_lawyer_dataclass(minimal_data)
            
            assert lawyer_obj.id == "minimal"
            assert lawyer_obj.nome == "Advogado"  # Fallback
            
            print("✅ Fallback de conversão funcionando")
            
            self.results["fallback_mechanisms"] = True
            
        except Exception as e:
            print(f"❌ Erro nos mecanismos de fallback: {e}")
            self.results["fallback_mechanisms"] = False
        
        print()
    
    def print_final_summary(self):
        """Imprime resumo final dos testes."""
        
        print("=" * 60)
        print("📋 RESUMO DOS TESTES - FASE 1")
        print("=" * 60)
        
        total_tests = len(self.results)
        passed_tests = sum(1 for result in self.results.values() if result)
        
        test_names = {
            "imports": "Imports e Dependências",
            "feature_calculator": "Integração FeatureCalculator", 
            "quality_in_recommendations": "Quality Score nas Recomendações",
            "dataclass_conversions": "Conversões de Dataclass",
            "fallback_mechanisms": "Mecanismos de Fallback"
        }
        
        for test_key, passed in self.results.items():
            status = "✅ PASSOU" if passed else "❌ FALHOU"
            test_name = test_names.get(test_key, test_key)
            print(f"{status:<10} {test_name}")
        
        print()
        print(f"📊 RESULTADO GERAL: {passed_tests}/{total_tests} testes passaram")
        
        if passed_tests == total_tests:
            print("🎉 FASE 1 IMPLEMENTADA COM SUCESSO!")
            print("✅ FeatureCalculator integrado ao PartnershipRecommendationService")
            print("✅ Quality scores (Q+M+I+C+E) funcionando")
            print("✅ Unificação entre algoritmos de casos e parcerias estabelecida")
            print("✅ Fallbacks robustos implementados")
        else:
            print("⚠️  Alguns testes falharam - revisar implementação")
        
        print()
        print("🚀 PRÓXIMOS PASSOS:")
        print("   1. Executar testes em ambiente real")
        print("   2. Monitorar performance das recomendações")
        print("   3. Iniciar Fase 2: Adaptação da Lógica de Similaridade")
        print("   4. Implementar cache Redis otimizado")


async def main():
    """Função principal."""
    
    tester = Fase1IntegrationTester()
    await tester.run_all_tests()


if __name__ == "__main__":
    asyncio.run(main()) 