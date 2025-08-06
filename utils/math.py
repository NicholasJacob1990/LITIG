# -*- coding: utf-8 -*-
"""
utils/math.py - Utilitários Matemáticos

Funções matemáticas extraídas do algoritmo v2.11.
"""

import math
from typing import Tuple
import numpy as np


def haversine(coord_a: Tuple[float, float], coord_b: Tuple[float, float]) -> float:
    """Calcula distância entre duas coordenadas em km."""
    lat1, lon1 = coord_a
    lat2, lon2 = coord_b
    
    # Raio da Terra em km
    R = 6371.0
    
    # Converter graus para radianos
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    
    # Diferenças
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    
    # Fórmula haversine
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    return R * c


def cosine_similarity(vec_a: np.ndarray, vec_b: np.ndarray) -> float:
    """Calcula similaridade de cosseno entre dois vetores."""
    if vec_a is None or vec_b is None:
        return 0.0
    
    dot_product = np.dot(vec_a, vec_b)
    norm_a = np.linalg.norm(vec_a)
    norm_b = np.linalg.norm(vec_b)
    
    if norm_a == 0 or norm_b == 0:
        return 0.0
    
    return dot_product / (norm_a * norm_b) 
"""
utils/math.py - Utilitários Matemáticos

Funções matemáticas extraídas do algoritmo v2.11.
"""

import math
from typing import Tuple
import numpy as np


def haversine(coord_a: Tuple[float, float], coord_b: Tuple[float, float]) -> float:
    """Calcula distância entre duas coordenadas em km."""
    lat1, lon1 = coord_a
    lat2, lon2 = coord_b
    
    # Raio da Terra em km
    R = 6371.0
    
    # Converter graus para radianos
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    
    # Diferenças
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    
    # Fórmula haversine
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    return R * c


def cosine_similarity(vec_a: np.ndarray, vec_b: np.ndarray) -> float:
    """Calcula similaridade de cosseno entre dois vetores."""
    if vec_a is None or vec_b is None:
        return 0.0
    
    dot_product = np.dot(vec_a, vec_b)
    norm_a = np.linalg.norm(vec_a)
    norm_b = np.linalg.norm(vec_b)
    
    if norm_a == 0 or norm_b == 0:
        return 0.0
    
    return dot_product / (norm_a * norm_b) 
"""
utils/math.py - Utilitários Matemáticos

Funções matemáticas extraídas do algoritmo v2.11.
"""

import math
from typing import Tuple
import numpy as np


def haversine(coord_a: Tuple[float, float], coord_b: Tuple[float, float]) -> float:
    """Calcula distância entre duas coordenadas em km."""
    lat1, lon1 = coord_a
    lat2, lon2 = coord_b
    
    # Raio da Terra em km
    R = 6371.0
    
    # Converter graus para radianos
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    
    # Diferenças
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    
    # Fórmula haversine
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    return R * c


def cosine_similarity(vec_a: np.ndarray, vec_b: np.ndarray) -> float:
    """Calcula similaridade de cosseno entre dois vetores."""
    if vec_a is None or vec_b is None:
        return 0.0
    
    dot_product = np.dot(vec_a, vec_b)
    norm_a = np.linalg.norm(vec_a)
    norm_b = np.linalg.norm(vec_b)
    
    if norm_a == 0 or norm_b == 0:
        return 0.0
    
    return dot_product / (norm_a * norm_b) 