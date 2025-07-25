#!/usr/bin/env python3
"""
Script para corrigir TODAS as funções restantes com rate limiter.
"""

import re

def fix_all_remaining_rate_limiters():
    """Corrige sistematicamente todas as funções com @limiter.limit que não têm request: Request."""
    
    file_path = "routes/intelligent_triage_routes.py"
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Encontrar todas as funções que têm @limiter.limit mas não têm request: Request
        # Padrão mais específico
        pattern = r'(@limiter\.limit\([^)]+\)\s*\n)(async def (\w+)\(\s*)(?!request: Request)'
        
        def add_request_param(match):
            limiter_decorator = match.group(1)
            func_def_start = match.group(2) 
            func_name = match.group(3)
            
            # Adicionar request: Request como primeiro parâmetro
            return limiter_decorator + func_def_start + 'request: Request,\n    '
        
        # Aplicar correção
        original_content = content
        content = re.sub(pattern, add_request_param, content, flags=re.MULTILINE)
        
        # Verificar se Request está nos imports
        if 'from fastapi import' in content and ', Request' not in content:
            # Encontrar a linha de import do fastapi e adicionar Request
            fastapi_import_pattern = r'(from fastapi import [^)]+?)(\n)'
            content = re.sub(fastapi_import_pattern, r'\1, Request\2', content)
        
        # Escrever arquivo corrigido
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✓ Corrigido {file_path}")
            
            # Contar quantas funções foram corrigidas
            corrections = len(re.findall(pattern, original_content, flags=re.MULTILINE))
            print(f"  - Corrigidas {corrections} funções com rate limiter")
            
            # Mostrar quais funções foram corrigidas
            matches = re.findall(pattern, original_content, flags=re.MULTILINE)
            for match in matches:
                func_name = match[2]
                print(f"    • {func_name}")
        else:
            print(f"  - Nenhuma correção necessária em {file_path}")
        
    except Exception as e:
        print(f"✗ Erro ao processar {file_path}: {e}")

if __name__ == "__main__":
    fix_all_remaining_rate_limiters()
    print("✅ Correção completa de TODOS os rate limiters concluída!") 