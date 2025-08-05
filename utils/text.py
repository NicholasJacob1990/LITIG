# -*- coding: utf-8 -*-
"""
utils/text.py - Utilitários de Texto

Funções de manipulação de texto extraídas do algoritmo v2.11.
"""

import re
from typing import Dict, List


def canonical(text: str) -> str:
    """Normalização canônica de texto para comparação."""
    if not text:
        return ""
    
    # Converter para minúsculas
    text = text.lower()
    
    # Remover acentos
    accents = {
        'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'ä': 'a',
        'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
        'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
        'ó': 'o', 'ò': 'o', 'õ': 'o', 'ô': 'o', 'ö': 'o',
        'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
        'ç': 'c', 'ñ': 'n'
    }
    
    for accented, normal in accents.items():
        text = text.replace(accented, normal)
    
    # Remover caracteres especiais, manter apenas alfanuméricos e espaços
    text = re.sub(r'[^a-z0-9\s]', '', text)
    
    # Normalizar espaços
    text = re.sub(r'\s+', ' ', text).strip()
    
    return text


def count_keywords(patterns: List[str], text: str) -> int:
    """Conta ocorrências de padrões em texto."""
    if not text or not patterns:
        return 0
    
    text_lower = text.lower()
    count = 0
    
    for pattern in patterns:
        if pattern.lower() in text_lower:
            count += 1
    
    return count 
"""
utils/text.py - Utilitários de Texto

Funções de manipulação de texto extraídas do algoritmo v2.11.
"""

import re
from typing import Dict, List


def canonical(text: str) -> str:
    """Normalização canônica de texto para comparação."""
    if not text:
        return ""
    
    # Converter para minúsculas
    text = text.lower()
    
    # Remover acentos
    accents = {
        'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'ä': 'a',
        'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
        'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
        'ó': 'o', 'ò': 'o', 'õ': 'o', 'ô': 'o', 'ö': 'o',
        'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
        'ç': 'c', 'ñ': 'n'
    }
    
    for accented, normal in accents.items():
        text = text.replace(accented, normal)
    
    # Remover caracteres especiais, manter apenas alfanuméricos e espaços
    text = re.sub(r'[^a-z0-9\s]', '', text)
    
    # Normalizar espaços
    text = re.sub(r'\s+', ' ', text).strip()
    
    return text


def count_keywords(patterns: List[str], text: str) -> int:
    """Conta ocorrências de padrões em texto."""
    if not text or not patterns:
        return 0
    
    text_lower = text.lower()
    count = 0
    
    for pattern in patterns:
        if pattern.lower() in text_lower:
            count += 1
    
    return count 
"""
utils/text.py - Utilitários de Texto

Funções de manipulação de texto extraídas do algoritmo v2.11.
"""

import re
from typing import Dict, List


def canonical(text: str) -> str:
    """Normalização canônica de texto para comparação."""
    if not text:
        return ""
    
    # Converter para minúsculas
    text = text.lower()
    
    # Remover acentos
    accents = {
        'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'ä': 'a',
        'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
        'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
        'ó': 'o', 'ò': 'o', 'õ': 'o', 'ô': 'o', 'ö': 'o',
        'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
        'ç': 'c', 'ñ': 'n'
    }
    
    for accented, normal in accents.items():
        text = text.replace(accented, normal)
    
    # Remover caracteres especiais, manter apenas alfanuméricos e espaços
    text = re.sub(r'[^a-z0-9\s]', '', text)
    
    # Normalizar espaços
    text = re.sub(r'\s+', ' ', text).strip()
    
    return text


def count_keywords(patterns: List[str], text: str) -> int:
    """Conta ocorrências de padrões em texto."""
    if not text or not patterns:
        return 0
    
    text_lower = text.lower()
    count = 0
    
    for pattern in patterns:
        if pattern.lower() in text_lower:
            count += 1
    
    return count 