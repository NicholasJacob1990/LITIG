# -*- coding: utf-8 -*-
"""
utils/text_utils.py

Funções utilitárias para processamento de texto.
"""

import re
import unicodedata
from typing import List


def canonical(text: str) -> str:
    """Remove acentos, normaliza e converte para slug para uso como chave de cache."""
    if not text:
        return ""
    # Remove acentos e caracteres especiais
    normalized = unicodedata.normalize('NFKD', text)
    ascii_text = normalized.encode('ascii', 'ignore').decode('ascii')
    # Converte para lowercase e substitui espaços por underscores
    slug = re.sub(r'[^a-z0-9\s]', '', ascii_text.lower())
    slug = re.sub(r'\s+', '_', slug.strip())
    return slug


def _chunks(lst: List, n: int):
    """Divide uma lista em chunks de tamanho máximo n."""
    for i in range(0, len(lst), n):
        yield lst[i:i + n]
 
 