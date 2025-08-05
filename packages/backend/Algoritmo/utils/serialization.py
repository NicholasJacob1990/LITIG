# -*- coding: utf-8 -*-
"""
utils/serialization.py

Funções utilitárias para serialização e conversão de dados.
"""

import hashlib
from typing import Dict, Any


def safe_json_dump(data: Dict, max_list_size: int = 100) -> Dict:
    """Converte recursivamente valores não serializáveis em JSON (ex: numpy) para tipos nativos e arredonda floats.
    
    Args:
        data: Dicionário a ser convertido
        max_list_size: Tamanho máximo de listas/tuplas antes de truncar (default: 100)
    """
    out = {}
    for key, value in data.items():
        if isinstance(value, dict) and value.get("_truncated"):
            out[key] = value
            continue
        
        # Robusta verificação para tipos NumPy
        is_np_scalar = hasattr(value, 'item') and hasattr(value, 'dtype') and not isinstance(value, dict)
        is_np_array = hasattr(value, 'tolist') and hasattr(value, 'tobytes') and not isinstance(value, dict)

        if is_np_scalar:
            try:
                item = value.item()
                if isinstance(item, (int, float)):
                    out[key] = round(item, 4) if isinstance(item, float) else item
                else:
                    out[key] = item
            except (AttributeError, TypeError):
                out[key] = str(value)
            continue
        elif is_np_array:
            try:
                arr = value.tolist()
                if len(arr) > max_list_size:
                    checksum = int(hashlib.sha1(value.tobytes()).hexdigest()[:8], 16)
                    out[key] = {
                        "_truncated": True, "size": len(arr), "checksum": checksum,
                        "sample": [round(float(v), 4) for v in arr[:10]],
                    }
                else:
                    out[key] = [round(float(v), 4) for v in arr]
            except (AttributeError, TypeError):
                out[key] = str(value)
            continue
        
        # Tipos nativos Python
        if isinstance(value, float):
            out[key] = round(value, 4)
        elif isinstance(value, (list, tuple)) and len(value) > max_list_size:
            out[key] = {
                "_truncated": True, "size": len(value), "sample": list(value[:10])
            }
        elif isinstance(value, dict):
            out[key] = safe_json_dump(value, max_list_size)
        elif isinstance(value, tuple):
            out[key] = list(value)
        else:
            out[key] = value
    return out
 
 