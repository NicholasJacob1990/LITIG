# -*- coding: utf-8 -*-
"""
tests/test_utils.py

Testes unitários para os módulos de utilities.
"""

import unittest
import numpy as np
from ..utils.math_utils import haversine, cosine_similarity
from ..utils.text_utils import canonical, _chunks
from ..utils.serialization import safe_json_dump


class TestMathUtils(unittest.TestCase):
    """Testes para utilitários matemáticos."""
    
    def test_haversine_same_point(self):
        """Teste de distância haversine para o mesmo ponto."""
        coord = (0.0, 0.0)
        distance = haversine(coord, coord)
        self.assertEqual(distance, 0.0)
    
    def test_haversine_known_distance(self):
        """Teste de distância haversine para pontos conhecidos."""
        # São Paulo para Rio de Janeiro (aproximadamente 357 km)
        sao_paulo = (-23.5505, -46.6333)
        rio_janeiro = (-22.9068, -43.1729)
        distance = haversine(sao_paulo, rio_janeiro)
        
        # Verificar se está na faixa esperada (±10 km)
        self.assertGreater(distance, 350)
        self.assertLess(distance, 370)
    
    def test_cosine_similarity_identical_vectors(self):
        """Teste de similaridade cosseno para vetores idênticos."""
        vec = np.array([1.0, 2.0, 3.0])
        similarity = cosine_similarity(vec, vec)
        self.assertAlmostEqual(similarity, 1.0, places=6)
    
    def test_cosine_similarity_orthogonal_vectors(self):
        """Teste de similaridade cosseno para vetores ortogonais."""
        vec_a = np.array([1.0, 0.0])
        vec_b = np.array([0.0, 1.0])
        similarity = cosine_similarity(vec_a, vec_b)
        self.assertAlmostEqual(similarity, 0.0, places=6)
    
    def test_cosine_similarity_opposite_vectors(self):
        """Teste de similaridade cosseno para vetores opostos."""
        vec_a = np.array([1.0, 0.0])
        vec_b = np.array([-1.0, 0.0])
        similarity = cosine_similarity(vec_a, vec_b)
        self.assertAlmostEqual(similarity, -1.0, places=6)


class TestTextUtils(unittest.TestCase):
    """Testes para utilitários de texto."""
    
    def test_canonical_basic(self):
        """Teste básico de canonicalização."""
        text = "João da Silva"
        result = canonical(text)
        self.assertEqual(result, "joao_da_silva")
    
    def test_canonical_accents(self):
        """Teste de remoção de acentos."""
        text = "Relatório de Análise"
        result = canonical(text)
        self.assertEqual(result, "relatorio_de_analise")
    
    def test_canonical_special_chars(self):
        """Teste de remoção de caracteres especiais."""
        text = "Dr. José & Cia. Ltd."
        result = canonical(text)
        self.assertEqual(result, "dr_jose_cia_ltd")
    
    def test_canonical_empty_string(self):
        """Teste com string vazia."""
        result = canonical("")
        self.assertEqual(result, "")
    
    def test_chunks_basic(self):
        """Teste básico de divisão em chunks."""
        lst = [1, 2, 3, 4, 5, 6]
        chunks = list(_chunks(lst, 2))
        expected = [[1, 2], [3, 4], [5, 6]]
        self.assertEqual(chunks, expected)
    
    def test_chunks_incomplete_last(self):
        """Teste de chunks com último incompleto."""
        lst = [1, 2, 3, 4, 5]
        chunks = list(_chunks(lst, 2))
        expected = [[1, 2], [3, 4], [5]]
        self.assertEqual(chunks, expected)
    
    def test_chunks_empty_list(self):
        """Teste com lista vazia."""
        chunks = list(_chunks([], 2))
        self.assertEqual(chunks, [])


class TestSerializationUtils(unittest.TestCase):
    """Testes para utilitários de serialização."""
    
    def test_safe_json_dump_basic(self):
        """Teste básico de JSON dump seguro."""
        data = {"name": "João", "age": 30}
        result = safe_json_dump(data)
        self.assertEqual(result, data)
    
    def test_safe_json_dump_large_list(self):
        """Teste com lista grande (deve ser truncada)."""
        data = {"items": list(range(200))}
        result = safe_json_dump(data, max_list_size=50)
        
        self.assertIn("items", result)
        # Deve retornar dict com _truncated = True
        self.assertIsInstance(result["items"], dict)
        self.assertTrue(result["items"].get("_truncated", False))
    
    def test_safe_json_dump_nested_lists(self):
        """Teste com listas aninhadas."""
        data = {
            "level1": {
                "level2": list(range(150))
            }
        }
        result = safe_json_dump(data, max_list_size=100)
        
        # Nested dict não é processado recursivamente nesta implementação
        self.assertIn("level1", result)
        self.assertIsInstance(result["level1"], dict)
    
    def test_safe_json_dump_no_truncation_needed(self):
        """Teste sem necessidade de truncar."""
        data = {"small_list": [1, 2, 3]}
        result = safe_json_dump(data, max_list_size=100)
        self.assertEqual(result, data)


if __name__ == "__main__":
    unittest.main()
 
 