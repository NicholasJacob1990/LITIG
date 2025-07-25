#!/usr/bin/env python3
"""
Script para corrigir imports problemáticos no backend.
"""

import os
import re
from pathlib import Path

def fix_imports():
    """Corrige imports problemáticos em todos os arquivos Python."""
    
    # Mapeamento de imports problemáticos para corretos
    import_fixes = {
        'from services.redis_service import': 'from services.redis_service import',
        'from services.cache_service_simple import': 'from services.cache_service_simple import',
        'from services.notify_service import': 'from services.notify_service import',
        'from services.offer_service import': 'from services.offer_service import',
        'from triage_service import': 'from triage_service import',  # Este está na raiz
        'from embedding_service import': 'from embedding_service import',  # Este está na raiz
        'from services.lex9000_integration_service import': 'from services.lex9000_integration_service import',
        'from services.conversation_state_manager import': 'from services.conversation_state_manager import',
        'from services.match_service import': 'from services.match_service import',
        'from services.escavador_integration import': 'from services.escavador_integration import',
        'from services.hybrid_legal_data_service import': 'from services.hybrid_legal_data_service import',
        'from services.intelligent_interviewer_service import': 'from services.intelligent_interviewer_service import',
        'from services.celery_task_service import': 'from services.celery_task_service import',
        
        # Correções para prefixo backend.
        'from services.': 'from services.',
        'from routes.': 'from routes.',
        'from tasks.': 'from tasks.',
        'from auth import': 'from auth import',
        'from config import': 'from config import',
        'from models import': 'from models import',
        'from main import': 'from main import',
        'from ': 'from ',
    }
    
    # Diretórios para processar
    directories = ['services', 'routes', 'tasks', '.']
    
    for directory in directories:
        if not os.path.exists(directory):
            continue
            
        # Para diretório raiz, só processar arquivos .py diretamente
        if directory == '.':
            files = [f for f in os.listdir('.') if f.endswith('.py')]
            for file in files:
                file_path = file
                print(f"Processando {file_path}")
                
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Aplicar correções
                    original_content = content
                    for old_import, new_import in import_fixes.items():
                        content = content.replace(old_import, new_import)
                    
                    # Só escrever se houve mudanças
                    if content != original_content:
                        with open(file_path, 'w', encoding='utf-8') as f:
                            f.write(content)
                        print(f"  ✓ Corrigido {file_path}")
                    
                except Exception as e:
                    print(f"  ✗ Erro ao processar {file_path}: {e}")
        else:
            for root, dirs, files in os.walk(directory):
                for file in files:
                    if file.endswith('.py'):
                        file_path = os.path.join(root, file)
                        print(f"Processando {file_path}")
                        
                        try:
                            with open(file_path, 'r', encoding='utf-8') as f:
                                content = f.read()
                            
                            # Aplicar correções
                            original_content = content
                            for old_import, new_import in import_fixes.items():
                                content = content.replace(old_import, new_import)
                            
                            # Só escrever se houve mudanças
                            if content != original_content:
                                with open(file_path, 'w', encoding='utf-8') as f:
                                    f.write(content)
                                print(f"  ✓ Corrigido {file_path}")
                            
                        except Exception as e:
                            print(f"  ✗ Erro ao processar {file_path}: {e}")

if __name__ == "__main__":
    fix_imports()
    print("Correção de imports concluída!") 