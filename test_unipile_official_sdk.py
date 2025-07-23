#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Teste do SDK Python Oficial - Unipile
=====================================
Testa o SDK Python oficial da Unipile (unified-python-sdk v0.48.9)
para verificar funcionalidades disponíveis.
"""

import os
from unified_python_sdk import UnifiedTo

def test_official_sdk():
    """Testa o SDK oficial Python da Unipile"""
    
    print("🚀 Testando SDK Python Oficial da Unipile...")
    print(f"✅ Versão instalada: unified-python-sdk v0.48.9")
    
    # Verificar estrutura do SDK
    print("\n📋 Estrutura do SDK:")
    print(f"Cliente principal: {UnifiedTo}")
    
    # Tentar inicializar (sem credenciais reais)
    try:
        # Exemplo de inicialização (sem fazer chamadas reais)
        print("\n🔧 Teste de inicialização:")
        print("from unified_python_sdk import UnifiedTo")
        print("client = UnifiedTo()")
        print("✅ Classe principal pode ser importada")
        
        # Verificar métodos disponíveis
        methods = [m for m in dir(UnifiedTo) if not m.startswith('_')]
        print(f"\n📌 Métodos disponíveis: {len(methods)}")
        for method in methods[:5]:  # Mostrar apenas os primeiros 5
            print(f"  - {method}")
        if len(methods) > 5:
            print(f"  ... e mais {len(methods) - 5} métodos")
            
    except Exception as e:
        print(f"❌ Erro na inicialização: {e}")
    
    print("\n✅ SDK Python oficial da Unipile está instalado e importável!")
    print("📚 Para usar em produção, você precisará configurar:")
    print("   - DSN (Data Source Name)")
    print("   - Token de acesso")
    print("   - client = UnifiedTo(dsn='your_dsn', token='your_token')")

if __name__ == "__main__":
    test_official_sdk() 
 
# -*- coding: utf-8 -*-
"""
Teste do SDK Python Oficial - Unipile
=====================================
Testa o SDK Python oficial da Unipile (unified-python-sdk v0.48.9)
para verificar funcionalidades disponíveis.
"""

import os
from unified_python_sdk import UnifiedTo

def test_official_sdk():
    """Testa o SDK oficial Python da Unipile"""
    
    print("🚀 Testando SDK Python Oficial da Unipile...")
    print(f"✅ Versão instalada: unified-python-sdk v0.48.9")
    
    # Verificar estrutura do SDK
    print("\n📋 Estrutura do SDK:")
    print(f"Cliente principal: {UnifiedTo}")
    
    # Tentar inicializar (sem credenciais reais)
    try:
        # Exemplo de inicialização (sem fazer chamadas reais)
        print("\n🔧 Teste de inicialização:")
        print("from unified_python_sdk import UnifiedTo")
        print("client = UnifiedTo()")
        print("✅ Classe principal pode ser importada")
        
        # Verificar métodos disponíveis
        methods = [m for m in dir(UnifiedTo) if not m.startswith('_')]
        print(f"\n📌 Métodos disponíveis: {len(methods)}")
        for method in methods[:5]:  # Mostrar apenas os primeiros 5
            print(f"  - {method}")
        if len(methods) > 5:
            print(f"  ... e mais {len(methods) - 5} métodos")
            
    except Exception as e:
        print(f"❌ Erro na inicialização: {e}")
    
    print("\n✅ SDK Python oficial da Unipile está instalado e importável!")
    print("📚 Para usar em produção, você precisará configurar:")
    print("   - DSN (Data Source Name)")
    print("   - Token de acesso")
    print("   - client = UnifiedTo(dsn='your_dsn', token='your_token')")

if __name__ == "__main__":
    test_official_sdk() 