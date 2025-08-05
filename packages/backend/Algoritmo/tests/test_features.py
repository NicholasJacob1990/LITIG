# -*- coding: utf-8 -*-
"""
tests/test_features.py

Testes unitários para o módulo de features (strategies).
"""

import unittest
import numpy as np
from unittest.mock import MagicMock
from ..models.domain import Case, Lawyer, KPI
from ..features.core_matching import CoreMatchingFeatures
from ..features.geographic import GeographicFeatures
from ..features.performance import PerformanceFeatures
from ..features.calculator import ModernFeatureCalculator


class TestCoreMatchingFeatures(unittest.TestCase):
    """Testes para features básicas de matching."""
    
    def setUp(self):
        """Setup comum para os testes."""
        self.case = Case(
            id="test_case",
            area="civil",
            subarea="contratos",
            urgency_h=24,
            coords=(0.0, 0.0)
        )
        
        self.kpi = KPI(
            success_rate=0.8,
            cases_30d=10,
            avaliacao_media=4.5,
            tempo_resposta_h=2
        )
        
        self.lawyer = Lawyer(
            id="test_lawyer",
            nome="João Silva",
            tags_expertise=["civil", "penal"],
            geo_latlon=(0.0, 0.0),
            curriculo_json={},
            kpi=self.kpi
        )
    
    def test_area_match_positive(self):
        """Teste de match positivo de área."""
        strategy = CoreMatchingFeatures(self.case, self.lawyer)
        result = strategy.area_match()
        self.assertEqual(result, 1.0)
    
    def test_area_match_negative(self):
        """Teste de match negativo de área."""
        lawyer_no_match = Lawyer(
            id="test_lawyer_2",
            nome="Maria Santos",
            tags_expertise=["trabalhista", "tributario"],
            geo_latlon=(0.0, 0.0),
            curriculo_json={},
            kpi=self.kpi
        )
        
        strategy = CoreMatchingFeatures(self.case, lawyer_no_match)
        result = strategy.area_match()
        self.assertEqual(result, 0.0)
    
    def test_case_similarity_no_embeddings(self):
        """Teste de similaridade sem embeddings."""
        strategy = CoreMatchingFeatures(self.case, self.lawyer)
        result = strategy.case_similarity()
        self.assertEqual(result, 0.0)
    
    def test_case_similarity_with_embeddings(self):
        """Teste de similaridade com embeddings."""
        # Configurar embeddings
        embedding = np.array([1.0, 0.0, 0.0])
        self.case.summary_embedding = embedding
        self.lawyer.casos_historicos_embeddings = [embedding, embedding]
        self.lawyer.case_outcomes = [True, False]
        
        strategy = CoreMatchingFeatures(self.case, self.lawyer)
        result = strategy.case_similarity()
        
        # Deve ser > 0 pois há embeddings similares
        self.assertGreater(result, 0.0)
        self.assertLessEqual(result, 1.0)
    
    def test_calculate_returns_correct_keys(self):
        """Teste se calculate() retorna as chaves corretas."""
        strategy = CoreMatchingFeatures(self.case, self.lawyer)
        result = strategy.calculate()
        
        self.assertIn("A", result)  # area_match
        self.assertIn("C", result)  # case_similarity
        self.assertEqual(len(result), 2)


class TestGeographicFeatures(unittest.TestCase):
    """Testes para features geográficas."""
    
    def setUp(self):
        """Setup comum para os testes."""
        self.case = Case(
            id="test_case",
            area="civil",
            subarea="contratos",
            urgency_h=24,
            coords=(0.0, 0.0),
            radius_km=50
        )
        
        self.kpi = KPI(
            success_rate=0.8,
            cases_30d=10,
            avaliacao_media=4.5,
            tempo_resposta_h=2
        )
    
    def test_geo_score_same_location(self):
        """Teste de score geográfico para mesma localização."""
        lawyer = Lawyer(
            id="test_lawyer",
            nome="João Silva",
            tags_expertise=["civil"],
            geo_latlon=(0.0, 0.0),  # Mesma coordenada
            curriculo_json={},
            kpi=self.kpi
        )
        
        strategy = GeographicFeatures(self.case, lawyer)
        result = strategy.geo_score()
        self.assertEqual(result, 1.0)
    
    def test_geo_score_far_location(self):
        """Teste de score geográfico para localização distante."""
        lawyer = Lawyer(
            id="test_lawyer",
            nome="João Silva",
            tags_expertise=["civil"],
            geo_latlon=(1.0, 1.0),  # Coordenada distante
            curriculo_json={},
            kpi=self.kpi
        )
        
        strategy = GeographicFeatures(self.case, lawyer)
        result = strategy.geo_score()
        
        # Deve ser < 1.0 pois há distância
        self.assertLess(result, 1.0)
        self.assertGreaterEqual(result, 0.0)
    
    def test_calculate_returns_g_key(self):
        """Teste se calculate() retorna a chave G."""
        lawyer = Lawyer(
            id="test_lawyer",
            nome="João Silva",
            tags_expertise=["civil"],
            geo_latlon=(0.0, 0.0),
            curriculo_json={},
            kpi=self.kpi
        )
        
        strategy = GeographicFeatures(self.case, lawyer)
        result = strategy.calculate()
        
        self.assertIn("G", result)
        self.assertEqual(len(result), 1)


class TestPerformanceFeatures(unittest.TestCase):
    """Testes para features de performance."""
    
    def setUp(self):
        """Setup comum para os testes."""
        self.case = Case(
            id="test_case",
            area="civil",
            subarea="contratos",
            urgency_h=24,
            coords=(0.0, 0.0)
        )
    
    def test_success_rate_verified_status(self):
        """Teste de success rate com status verificado."""
        kpi = KPI(
            success_rate=0.8,
            cases_30d=10,
            avaliacao_media=4.5,
            tempo_resposta_h=2,
            success_status="V"  # Verificado
        )
        
        lawyer = Lawyer(
            id="test_lawyer",
            nome="João Silva",
            tags_expertise=["civil"],
            geo_latlon=(0.0, 0.0),
            curriculo_json={},
            kpi=kpi
        )
        
        strategy = PerformanceFeatures(self.case, lawyer)
        result = strategy.success_rate()
        
        # Deve ser > 0 pois tem status verificado
        self.assertGreater(result, 0.0)
    
    def test_success_rate_not_verified_status(self):
        """Teste de success rate com status não verificado."""
        kpi = KPI(
            success_rate=0.8,
            cases_30d=10,
            avaliacao_media=4.5,
            tempo_resposta_h=2,
            success_status="N"  # Não verificado
        )
        
        lawyer = Lawyer(
            id="test_lawyer",
            nome="João Silva",
            tags_expertise=["civil"],
            geo_latlon=(0.0, 0.0),
            curriculo_json={},
            kpi=kpi
        )
        
        strategy = PerformanceFeatures(self.case, lawyer)
        result = strategy.success_rate()
        
        # Deve ser 0.0 pois status é N
        self.assertEqual(result, 0.0)
    
    def test_success_rate_with_economic_data(self):
        """Teste de success rate com dados econômicos."""
        kpi = KPI(
            success_rate=0.8,
            cases_30d=20,
            avaliacao_media=4.5,
            tempo_resposta_h=2,
            success_status="V",
            valor_recuperado_30d=100000.0,
            valor_total_30d=150000.0
        )
        
        lawyer = Lawyer(
            id="test_lawyer",
            nome="João Silva",
            tags_expertise=["civil"],
            geo_latlon=(0.0, 0.0),
            curriculo_json={},
            kpi=kpi
        )
        
        strategy = PerformanceFeatures(self.case, lawyer)
        result = strategy.success_rate()
        
        # Deve usar fórmula econômica
        expected = (100000.0 / 150000.0) * 1.0  # * sample_factor * status_mult
        self.assertAlmostEqual(result, expected, places=2)


class TestModernFeatureCalculator(unittest.TestCase):
    """Testes para o calculador moderno de features."""
    
    def setUp(self):
        """Setup comum para os testes."""
        self.case = Case(
            id="test_case",
            area="civil",
            subarea="contratos",
            urgency_h=24,
            coords=(0.0, 0.0)
        )
        
        self.kpi = KPI(
            success_rate=0.8,
            cases_30d=10,
            avaliacao_media=4.5,
            tempo_resposta_h=2
        )
        
        self.lawyer = Lawyer(
            id="test_lawyer",
            nome="João Silva",
            tags_expertise=["civil"],
            geo_latlon=(0.0, 0.0),
            curriculo_json={},
            kpi=self.kpi
        )
    
    def test_all_returns_combined_features(self):
        """Teste se all() retorna features combinadas."""
        calculator = ModernFeatureCalculator(self.case, self.lawyer)
        result = calculator.all()
        
        # Deve conter pelo menos as features básicas
        self.assertIn("A", result)  # CoreMatching
        self.assertIn("C", result)  # CoreMatching  
        self.assertIn("G", result)  # Geographic
        self.assertIn("S", result)  # Performance
    
    def test_backward_compatibility_methods(self):
        """Teste de métodos para backward compatibility."""
        calculator = ModernFeatureCalculator(self.case, self.lawyer)
        
        # Testar métodos individuais
        area_score = calculator.area_match()
        geo_score = calculator.geo_score()
        success_score = calculator.success_rate()
        
        self.assertIsInstance(area_score, float)
        self.assertIsInstance(geo_score, float)
        self.assertIsInstance(success_score, float)
    
    def test_all_async(self):
        """Teste da versão assíncrona."""
        import asyncio
        
        async def run_test():
            calculator = ModernFeatureCalculator(self.case, self.lawyer)
            result = await calculator.all_async()
            
            # Deve retornar o mesmo que all() 
            sync_result = calculator.all()
            self.assertEqual(result, sync_result)
        
        # Executar teste assíncrono
        asyncio.run(run_test())


if __name__ == "__main__":
    unittest.main()
 
 