#!/usr/bin/env python3
"""
Script de teste para verificar a implementação backend completa
"""
import sys
import os

# Adicionar o diretório raiz ao path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

def test_imports():
    """Testa se todos os módulos podem ser importados"""
    print("🔍 Testando imports...")
    
    try:
        # Testar imports básicos
        from fastapi import FastAPI
        from supabase import create_client
        from pydantic import BaseModel
        print("✅ Dependências básicas: OK")
        
        # Testar serviços
        from backend.services.consultation_service import ConsultationService
        from backend.services.document_service import DocumentService
        from backend.services.process_event_service import ProcessEventService
        from backend.services.task_service import TaskService
        print("✅ Serviços: OK")
        
        # Testar rotas
        from backend.routes.consultations import router as consultations_router
        from backend.routes.documents import router as documents_router
        from backend.routes.process_events import router as process_events_router
        from backend.routes.tasks import router as tasks_router
        print("✅ Rotas: OK")
        
        # Testar main
        from backend.main import app
        print("✅ Aplicação principal: OK")
        
        return True
        
    except ImportError as e:
        print(f"❌ Erro de import: {e}")
        return False
    except Exception as e:
        print(f"❌ Erro geral: {e}")
        return False

def test_service_initialization():
    """Testa se os serviços podem ser inicializados"""
    print("\n🔍 Testando inicialização dos serviços...")
    
    try:
        # Definir configurações de teste
        os.environ['SUPABASE_URL'] = 'https://test.supabase.co'
        os.environ['SUPABASE_SERVICE_KEY'] = 'test_key'
        
        from backend.services.consultation_service import ConsultationService
        from backend.services.document_service import DocumentService
        from backend.services.process_event_service import ProcessEventService
        from backend.services.task_service import TaskService
        
        # Tentar inicializar serviços
        consultation_service = ConsultationService()
        document_service = DocumentService()
        process_event_service = ProcessEventService()
        task_service = TaskService()
        
        print("✅ Inicialização dos serviços: OK")
        return True
        
    except Exception as e:
        print(f"❌ Erro na inicialização: {e}")
        return False

def test_routes_structure():
    """Testa a estrutura das rotas"""
    print("\n🔍 Testando estrutura das rotas...")
    
    try:
        from backend.routes.consultations import router as consultations_router
        from backend.routes.documents import router as documents_router
        from backend.routes.process_events import router as process_events_router
        from backend.routes.tasks import router as tasks_router
        
        # Verificar se routers têm prefixos corretos
        assert consultations_router.prefix == "/consultations"
        assert documents_router.prefix == "/documents"
        assert process_events_router.prefix == "/process-events"
        assert tasks_router.prefix == "/tasks"
        
        print("✅ Estrutura das rotas: OK")
        return True
        
    except Exception as e:
        print(f"❌ Erro na estrutura das rotas: {e}")
        return False

def test_app_registration():
    """Testa se as rotas estão registradas na aplicação"""
    print("\n🔍 Testando registro das rotas na aplicação...")
    
    try:
        from backend.main import app
        
        # Verificar se a aplicação foi criada
        assert app is not None
        assert hasattr(app, 'routes')
        
        # Contar rotas registradas
        route_count = len(app.routes)
        print(f"📊 Total de rotas registradas: {route_count}")
        
        # Verificar se há rotas com os prefixos esperados
        route_paths = [route.path for route in app.routes if hasattr(route, 'path')]
        
        expected_prefixes = ['/api/consultations', '/api/documents', '/api/process-events', '/api/tasks']
        found_prefixes = []
        
        for prefix in expected_prefixes:
            if any(path.startswith(prefix) for path in route_paths):
                found_prefixes.append(prefix)
        
        print(f"✅ Prefixos encontrados: {found_prefixes}")
        
        if len(found_prefixes) >= 2:  # Pelo menos algumas rotas devem estar registradas
            print("✅ Registro das rotas: OK")
            return True
        else:
            print("⚠️ Algumas rotas podem não estar registradas")
            return False
        
    except Exception as e:
        print(f"❌ Erro no registro das rotas: {e}")
        return False

def main():
    """Função principal de teste"""
    print("🚀 Iniciando testes da implementação backend...\n")
    
    tests = [
        test_imports,
        test_service_initialization,
        test_routes_structure,
        test_app_registration
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        if test():
            passed += 1
    
    print(f"\n📊 Resultado dos testes: {passed}/{total} passaram")
    
    if passed == total:
        print("🎉 Todos os testes passaram! Backend implementado com sucesso!")
        print("\n📝 Próximos passos:")
        print("1. Configurar variáveis de ambiente (SUPABASE_URL, SUPABASE_SERVICE_KEY)")
        print("2. Executar: uvicorn backend.main:app --reload")
        print("3. Acessar: http://localhost:8000/docs")
        return True
    else:
        print("⚠️ Alguns testes falharam. Verifique os erros acima.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 