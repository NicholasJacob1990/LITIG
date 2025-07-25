#!/usr/bin/env python3
"""
Script para corrigir rate limiters que precisam do parâmetro request.
"""

import os
import re

def fix_rate_limiters():
    """Corrige rate limiters adicionando request: Request como primeiro parâmetro."""
    
    directories = ['routes']
    
    for directory in directories:
        if not os.path.exists(directory):
            continue
            
        for root, dirs, files in os.walk(directory):
            for file in files:
                if file.endswith('.py'):
                    file_path = os.path.join(root, file)
                    print(f"Processando {file_path}")
                    
                    try:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            content = f.read()
                        
                        # Padrão para encontrar funções com @limiter.limit mas sem request
                        pattern = r'(@limiter\.limit\([^)]+\)\s*\nasync def \w+\(\s*)(?!request:)'
                        
                        def add_request_param(match):
                            return match.group(1) + 'request: Request,\n    '
                        
                        # Aplicar correção
                        original_content = content
                        content = re.sub(pattern, add_request_param, content, flags=re.MULTILINE)
                        
                        # Verificar se precisa adicionar import Request
                        if content != original_content and 'from fastapi import' in content and 'Request' not in content:
                            # Adicionar Request aos imports
                            fastapi_import_pattern = r'from fastapi import ([^)]+)'
                            
                            def add_request_import(match):
                                imports = match.group(1)
                                if 'Request' not in imports:
                                    return f"from fastapi import {imports}, Request"
                                return match.group(0)
                            
                            content = re.sub(fastapi_import_pattern, add_request_import, content)
                        
                        # Só escrever se houve mudanças
                        if content != original_content:
                            with open(file_path, 'w', encoding='utf-8') as f:
                                f.write(content)
                            print(f"  ✓ Corrigido {file_path}")
                        
                    except Exception as e:
                        print(f"  ✗ Erro ao processar {file_path}: {e}")

if __name__ == "__main__":
    fix_rate_limiters()
    print("Correção de rate limiters concluída!") 