#!/usr/bin/env python3
"""
Script para corrigir TODAS as funções com rate limiter.
"""

import os
import re

def fix_all_rate_limiters():
    """Corrige todas as funções com @limiter.limit que não têm request: Request."""
    
    file_path = "routes/intelligent_triage_routes.py"
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Padrão para encontrar funções com @limiter.limit mas sem request: Request
        pattern = r'(@limiter\.limit\([^)]+\)\s*\nasync def \w+\(\s*)(?!request: Request)'
        
        def add_request_param(match):
            return match.group(1) + 'request: Request,\n    '
        
        # Aplicar correção
        original_content = content
        content = re.sub(pattern, add_request_param, content, flags=re.MULTILINE)
        
        # Verificar se Request está nos imports
        if 'Request' not in content and 'from fastapi import' in content:
            content = content.replace(
                'from fastapi import APIRouter, Depends, HTTPException',
                'from fastapi import APIRouter, Depends, HTTPException, Request'
            )
        
        # Escrever arquivo corrigido
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✓ Corrigido {file_path}")
            
            # Contar quantas funções foram corrigidas
            corrections = len(re.findall(pattern, original_content, flags=re.MULTILINE))
            print(f"  - Corrigidas {corrections} funções com rate limiter")
        else:
            print(f"  - Nenhuma correção necessária em {file_path}")
        
    except Exception as e:
        print(f"✗ Erro ao processar {file_path}: {e}")

if __name__ == "__main__":
    fix_all_rate_limiters()
    print("Correção completa de rate limiters concluída!") 