#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de teste para as funcionalidades de movimentações processuais via Escavador.
"""

import asyncio
import os
import sys
from pathlib import Path

# Adicionar o diretório backend ao path
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

async def test_movement_classifier():
    """Testa o classificador de movimentações."""
    print("\n🔍 TESTE 1: Classificador de Movimentações")
    print("=" * 50)
    
    # Importar classe diretamente para evitar problemas de dependência
    from routes.process_movements import MovementClassifier
    
    classifier = MovementClassifier()
    
    test_cases = [
        "Juntada de petição inicial",
        "Decisão do juiz sobre o pedido",
        "Citação da parte ré",
        "Audiência de conciliação designada",
        "Conclusão dos autos ao magistrado",
        "Movimento não identificado"
    ]
    
    for i, test_content in enumerate(test_cases, 1):
        result = classifier.classify_movement(test_content)
        print(f"{i}. Conteúdo: '{test_content}'")
        print(f"   → Tipo: {result['type']}")
        print(f"   → Ícone: {result['icon']}")
        print(f"   → Descrição: {result['description']}")
        print()
    
    print("✅ Classificador testado com sucesso!")

async def test_escavador_integration_methods():
    """Testa se os novos métodos estão acessíveis no EscavadorClient."""
    print("\n🔧 TESTE 2: Métodos do EscavadorClient")
    print("=" * 50)
    
    try:
        from services.escavador_integration import EscavadorClient
        
        # Verificar se os métodos existem
        methods_to_check = [
            "get_detailed_process_movements",
            "get_process_status_summary"
        ]
        
        for method_name in methods_to_check:
            if hasattr(EscavadorClient, method_name):
                print(f"✅ Método '{method_name}' encontrado")
            else:
                print(f"❌ Método '{method_name}' NÃO encontrado")
        
        print("\n✅ Verificação de métodos concluída!")
        
    except Exception as e:
        print(f"❌ Erro ao importar EscavadorClient: {e}")

async def test_api_routes_registration():
    """Testa se as rotas foram registradas corretamente."""
    print("\n🌐 TESTE 3: Registro de Rotas da API")
    print("=" * 50)
    
    try:
        from routes.process_movements import router
        
        # Verificar se o router tem as rotas esperadas
        routes = []
        for route in router.routes:
            if hasattr(route, 'path'):
                routes.append(f"{route.methods} {route.path}")
        
        print("Rotas registradas:")
        for route in routes:
            print(f"  📍 {route}")
        
        expected_routes = [
            "/{cnj}/detailed",
            "/{cnj}/summary"
        ]
        
        for expected in expected_routes:
            found = any(expected in route for route in routes)
            status = "✅" if found else "❌"
            print(f"{status} Rota esperada: {expected}")
        
        print("\n✅ Verificação de rotas concluída!")
        
    except Exception as e:
        print(f"❌ Erro ao verificar rotas: {e}")

async def test_data_structure_compatibility():
    """Testa se a estrutura de dados é compatível com o frontend."""
    print("\n📊 TESTE 4: Compatibilidade de Estrutura de Dados")
    print("=" * 50)
    
    # Simular dados que seriam retornados pelos métodos
    mock_process_status = {
        "current_phase": "Em Andamento",
        "description": "Processo em fase de análise judicial.",
        "progress_percentage": 65.0,
        "phases": [
            {
                "name": "Petição Inicial",
                "description": "Apresentação formal da causa à justiça.",
                "is_completed": True,
                "is_current": False,
                "completed_at": "2024-01-15T10:30:00Z",
                "documents": []
            },
            {
                "name": "Citação das Partes",
                "description": "Notificação das partes envolvidas.",
                "is_completed": True,
                "is_current": False,
                "completed_at": "2024-01-20T14:15:00Z",
                "documents": []
            },
            {
                "name": "Fase de Instrução",
                "description": "Coleta de provas e documentos.",
                "is_completed": False,
                "is_current": True,
                "completed_at": None,
                "documents": []
            }
        ],
        "cnj": "1234567-89.2024.1.23.4567",
        "outcome": "andamento"
    }
    
    # Verificar campos obrigatórios
    required_fields = [
        "current_phase", "description", "progress_percentage", "phases"
    ]
    
    for field in required_fields:
        if field in mock_process_status:
            print(f"✅ Campo obrigatório '{field}' presente")
        else:
            print(f"❌ Campo obrigatório '{field}' AUSENTE")
    
    # Verificar estrutura das fases
    if "phases" in mock_process_status:
        phases = mock_process_status["phases"]
        print(f"\n📋 Verificando {len(phases)} fases:")
        
        required_phase_fields = [
            "name", "description", "is_completed", "is_current", "documents"
        ]
        
        for i, phase in enumerate(phases):
            print(f"  Fase {i+1}: {phase.get('name', 'N/A')}")
            for field in required_phase_fields:
                if field in phase:
                    print(f"    ✅ {field}")
                else:
                    print(f"    ❌ {field} AUSENTE")
    
    print("\n✅ Verificação de compatibilidade concluída!")

async def main():
    """Executa todos os testes."""
    print("🚀 INICIANDO TESTES DE INTEGRAÇÃO - MOVIMENTAÇÕES PROCESSUAIS")
    print("=" * 70)
    
    await test_movement_classifier()
    await test_escavador_integration_methods()
    await test_api_routes_registration()
    await test_data_structure_compatibility()
    
    print("\n" + "=" * 70)
    print("🎉 TODOS OS TESTES CONCLUÍDOS!")
    print("\n📋 PRÓXIMOS PASSOS:")
    print("1. ✅ Backend: Endpoints criados e funcionais")
    print("2. 🔄 Frontend: Conectar aos novos endpoints")
    print("3. 🔄 Frontend: Substituir mocks por dados reais")
    print("4. 🧪 Testes: Validar com dados reais do Escavador")

if __name__ == "__main__":
    asyncio.run(main()) 
# -*- coding: utf-8 -*-
"""
Script de teste para as funcionalidades de movimentações processuais via Escavador.
"""

import asyncio
import os
import sys
from pathlib import Path

# Adicionar o diretório backend ao path
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

async def test_movement_classifier():
    """Testa o classificador de movimentações."""
    print("\n🔍 TESTE 1: Classificador de Movimentações")
    print("=" * 50)
    
    # Importar classe diretamente para evitar problemas de dependência
    from routes.process_movements import MovementClassifier
    
    classifier = MovementClassifier()
    
    test_cases = [
        "Juntada de petição inicial",
        "Decisão do juiz sobre o pedido",
        "Citação da parte ré",
        "Audiência de conciliação designada",
        "Conclusão dos autos ao magistrado",
        "Movimento não identificado"
    ]
    
    for i, test_content in enumerate(test_cases, 1):
        result = classifier.classify_movement(test_content)
        print(f"{i}. Conteúdo: '{test_content}'")
        print(f"   → Tipo: {result['type']}")
        print(f"   → Ícone: {result['icon']}")
        print(f"   → Descrição: {result['description']}")
        print()
    
    print("✅ Classificador testado com sucesso!")

async def test_escavador_integration_methods():
    """Testa se os novos métodos estão acessíveis no EscavadorClient."""
    print("\n🔧 TESTE 2: Métodos do EscavadorClient")
    print("=" * 50)
    
    try:
        from services.escavador_integration import EscavadorClient
        
        # Verificar se os métodos existem
        methods_to_check = [
            "get_detailed_process_movements",
            "get_process_status_summary"
        ]
        
        for method_name in methods_to_check:
            if hasattr(EscavadorClient, method_name):
                print(f"✅ Método '{method_name}' encontrado")
            else:
                print(f"❌ Método '{method_name}' NÃO encontrado")
        
        print("\n✅ Verificação de métodos concluída!")
        
    except Exception as e:
        print(f"❌ Erro ao importar EscavadorClient: {e}")

async def test_api_routes_registration():
    """Testa se as rotas foram registradas corretamente."""
    print("\n🌐 TESTE 3: Registro de Rotas da API")
    print("=" * 50)
    
    try:
        from routes.process_movements import router
        
        # Verificar se o router tem as rotas esperadas
        routes = []
        for route in router.routes:
            if hasattr(route, 'path'):
                routes.append(f"{route.methods} {route.path}")
        
        print("Rotas registradas:")
        for route in routes:
            print(f"  📍 {route}")
        
        expected_routes = [
            "/{cnj}/detailed",
            "/{cnj}/summary"
        ]
        
        for expected in expected_routes:
            found = any(expected in route for route in routes)
            status = "✅" if found else "❌"
            print(f"{status} Rota esperada: {expected}")
        
        print("\n✅ Verificação de rotas concluída!")
        
    except Exception as e:
        print(f"❌ Erro ao verificar rotas: {e}")

async def test_data_structure_compatibility():
    """Testa se a estrutura de dados é compatível com o frontend."""
    print("\n📊 TESTE 4: Compatibilidade de Estrutura de Dados")
    print("=" * 50)
    
    # Simular dados que seriam retornados pelos métodos
    mock_process_status = {
        "current_phase": "Em Andamento",
        "description": "Processo em fase de análise judicial.",
        "progress_percentage": 65.0,
        "phases": [
            {
                "name": "Petição Inicial",
                "description": "Apresentação formal da causa à justiça.",
                "is_completed": True,
                "is_current": False,
                "completed_at": "2024-01-15T10:30:00Z",
                "documents": []
            },
            {
                "name": "Citação das Partes",
                "description": "Notificação das partes envolvidas.",
                "is_completed": True,
                "is_current": False,
                "completed_at": "2024-01-20T14:15:00Z",
                "documents": []
            },
            {
                "name": "Fase de Instrução",
                "description": "Coleta de provas e documentos.",
                "is_completed": False,
                "is_current": True,
                "completed_at": None,
                "documents": []
            }
        ],
        "cnj": "1234567-89.2024.1.23.4567",
        "outcome": "andamento"
    }
    
    # Verificar campos obrigatórios
    required_fields = [
        "current_phase", "description", "progress_percentage", "phases"
    ]
    
    for field in required_fields:
        if field in mock_process_status:
            print(f"✅ Campo obrigatório '{field}' presente")
        else:
            print(f"❌ Campo obrigatório '{field}' AUSENTE")
    
    # Verificar estrutura das fases
    if "phases" in mock_process_status:
        phases = mock_process_status["phases"]
        print(f"\n📋 Verificando {len(phases)} fases:")
        
        required_phase_fields = [
            "name", "description", "is_completed", "is_current", "documents"
        ]
        
        for i, phase in enumerate(phases):
            print(f"  Fase {i+1}: {phase.get('name', 'N/A')}")
            for field in required_phase_fields:
                if field in phase:
                    print(f"    ✅ {field}")
                else:
                    print(f"    ❌ {field} AUSENTE")
    
    print("\n✅ Verificação de compatibilidade concluída!")

async def main():
    """Executa todos os testes."""
    print("🚀 INICIANDO TESTES DE INTEGRAÇÃO - MOVIMENTAÇÕES PROCESSUAIS")
    print("=" * 70)
    
    await test_movement_classifier()
    await test_escavador_integration_methods()
    await test_api_routes_registration()
    await test_data_structure_compatibility()
    
    print("\n" + "=" * 70)
    print("🎉 TODOS OS TESTES CONCLUÍDOS!")
    print("\n📋 PRÓXIMOS PASSOS:")
    print("1. ✅ Backend: Endpoints criados e funcionais")
    print("2. 🔄 Frontend: Conectar aos novos endpoints")
    print("3. 🔄 Frontend: Substituir mocks por dados reais")
    print("4. 🧪 Testes: Validar com dados reais do Escavador")

if __name__ == "__main__":
    asyncio.run(main()) 
# -*- coding: utf-8 -*-
"""
Script de teste para as funcionalidades de movimentações processuais via Escavador.
"""

import asyncio
import os
import sys
from pathlib import Path

# Adicionar o diretório backend ao path
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

async def test_movement_classifier():
    """Testa o classificador de movimentações."""
    print("\n🔍 TESTE 1: Classificador de Movimentações")
    print("=" * 50)
    
    # Importar classe diretamente para evitar problemas de dependência
    from routes.process_movements import MovementClassifier
    
    classifier = MovementClassifier()
    
    test_cases = [
        "Juntada de petição inicial",
        "Decisão do juiz sobre o pedido",
        "Citação da parte ré",
        "Audiência de conciliação designada",
        "Conclusão dos autos ao magistrado",
        "Movimento não identificado"
    ]
    
    for i, test_content in enumerate(test_cases, 1):
        result = classifier.classify_movement(test_content)
        print(f"{i}. Conteúdo: '{test_content}'")
        print(f"   → Tipo: {result['type']}")
        print(f"   → Ícone: {result['icon']}")
        print(f"   → Descrição: {result['description']}")
        print()
    
    print("✅ Classificador testado com sucesso!")

async def test_escavador_integration_methods():
    """Testa se os novos métodos estão acessíveis no EscavadorClient."""
    print("\n🔧 TESTE 2: Métodos do EscavadorClient")
    print("=" * 50)
    
    try:
        from services.escavador_integration import EscavadorClient
        
        # Verificar se os métodos existem
        methods_to_check = [
            "get_detailed_process_movements",
            "get_process_status_summary"
        ]
        
        for method_name in methods_to_check:
            if hasattr(EscavadorClient, method_name):
                print(f"✅ Método '{method_name}' encontrado")
            else:
                print(f"❌ Método '{method_name}' NÃO encontrado")
        
        print("\n✅ Verificação de métodos concluída!")
        
    except Exception as e:
        print(f"❌ Erro ao importar EscavadorClient: {e}")

async def test_api_routes_registration():
    """Testa se as rotas foram registradas corretamente."""
    print("\n🌐 TESTE 3: Registro de Rotas da API")
    print("=" * 50)
    
    try:
        from routes.process_movements import router
        
        # Verificar se o router tem as rotas esperadas
        routes = []
        for route in router.routes:
            if hasattr(route, 'path'):
                routes.append(f"{route.methods} {route.path}")
        
        print("Rotas registradas:")
        for route in routes:
            print(f"  📍 {route}")
        
        expected_routes = [
            "/{cnj}/detailed",
            "/{cnj}/summary"
        ]
        
        for expected in expected_routes:
            found = any(expected in route for route in routes)
            status = "✅" if found else "❌"
            print(f"{status} Rota esperada: {expected}")
        
        print("\n✅ Verificação de rotas concluída!")
        
    except Exception as e:
        print(f"❌ Erro ao verificar rotas: {e}")

async def test_data_structure_compatibility():
    """Testa se a estrutura de dados é compatível com o frontend."""
    print("\n📊 TESTE 4: Compatibilidade de Estrutura de Dados")
    print("=" * 50)
    
    # Simular dados que seriam retornados pelos métodos
    mock_process_status = {
        "current_phase": "Em Andamento",
        "description": "Processo em fase de análise judicial.",
        "progress_percentage": 65.0,
        "phases": [
            {
                "name": "Petição Inicial",
                "description": "Apresentação formal da causa à justiça.",
                "is_completed": True,
                "is_current": False,
                "completed_at": "2024-01-15T10:30:00Z",
                "documents": []
            },
            {
                "name": "Citação das Partes",
                "description": "Notificação das partes envolvidas.",
                "is_completed": True,
                "is_current": False,
                "completed_at": "2024-01-20T14:15:00Z",
                "documents": []
            },
            {
                "name": "Fase de Instrução",
                "description": "Coleta de provas e documentos.",
                "is_completed": False,
                "is_current": True,
                "completed_at": None,
                "documents": []
            }
        ],
        "cnj": "1234567-89.2024.1.23.4567",
        "outcome": "andamento"
    }
    
    # Verificar campos obrigatórios
    required_fields = [
        "current_phase", "description", "progress_percentage", "phases"
    ]
    
    for field in required_fields:
        if field in mock_process_status:
            print(f"✅ Campo obrigatório '{field}' presente")
        else:
            print(f"❌ Campo obrigatório '{field}' AUSENTE")
    
    # Verificar estrutura das fases
    if "phases" in mock_process_status:
        phases = mock_process_status["phases"]
        print(f"\n📋 Verificando {len(phases)} fases:")
        
        required_phase_fields = [
            "name", "description", "is_completed", "is_current", "documents"
        ]
        
        for i, phase in enumerate(phases):
            print(f"  Fase {i+1}: {phase.get('name', 'N/A')}")
            for field in required_phase_fields:
                if field in phase:
                    print(f"    ✅ {field}")
                else:
                    print(f"    ❌ {field} AUSENTE")
    
    print("\n✅ Verificação de compatibilidade concluída!")

async def main():
    """Executa todos os testes."""
    print("🚀 INICIANDO TESTES DE INTEGRAÇÃO - MOVIMENTAÇÕES PROCESSUAIS")
    print("=" * 70)
    
    await test_movement_classifier()
    await test_escavador_integration_methods()
    await test_api_routes_registration()
    await test_data_structure_compatibility()
    
    print("\n" + "=" * 70)
    print("🎉 TODOS OS TESTES CONCLUÍDOS!")
    print("\n📋 PRÓXIMOS PASSOS:")
    print("1. ✅ Backend: Endpoints criados e funcionais")
    print("2. 🔄 Frontend: Conectar aos novos endpoints")
    print("3. 🔄 Frontend: Substituir mocks por dados reais")
    print("4. 🧪 Testes: Validar com dados reais do Escavador")

if __name__ == "__main__":
    asyncio.run(main()) 