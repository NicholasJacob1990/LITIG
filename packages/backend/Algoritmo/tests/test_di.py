# -*- coding: utf-8 -*-
"""
tests/test_di.py

Testes unitários para o sistema de Dependency Injection.
"""

import unittest
from unittest.mock import MagicMock
from ..di.container import DIContainer, get_container, reset_container, inject
from ..di.setup import setup_di_container, get_service, get_service_optional


class TestDIContainer(unittest.TestCase):
    """Testes para o container de DI."""
    
    def setUp(self):
        """Setup comum para os testes."""
        reset_container()
        self.container = get_container()
    
    def tearDown(self):
        """Cleanup após os testes."""
        reset_container()
    
    def test_register_and_get_singleton(self):
        """Teste de registro e obtenção de singleton."""
        mock_service = MagicMock()
        
        self.container.register_singleton("test_service", mock_service)
        result = self.container.get("test_service")
        
        self.assertIs(result, mock_service)
    
    def test_register_and_get_factory(self):
        """Teste de registro e obtenção via factory."""
        mock_instance = MagicMock()
        factory = lambda: mock_instance
        
        self.container.register_factory("test_factory", factory)
        result = self.container.get("test_factory")
        
        self.assertIs(result, mock_instance)
    
    def test_factory_creates_singleton_instance(self):
        """Teste se factory cria instância singleton."""
        call_count = 0
        
        def factory():
            nonlocal call_count
            call_count += 1
            return MagicMock()
        
        self.container.register_factory("test_factory", factory)
        
        # Primeira chamada
        result1 = self.container.get("test_factory")
        # Segunda chamada
        result2 = self.container.get("test_factory")
        
        # Deve ser a mesma instância
        self.assertIs(result1, result2)
        # Factory deve ter sido chamada apenas uma vez
        self.assertEqual(call_count, 1)
    
    def test_get_nonexistent_service_raises_error(self):
        """Teste de erro ao obter serviço inexistente."""
        with self.assertRaises(ValueError):
            self.container.get("nonexistent_service")
    
    def test_get_optional_returns_none_for_nonexistent(self):
        """Teste de get_optional para serviço inexistente."""
        result = self.container.get_optional("nonexistent_service")
        self.assertIsNone(result)
    
    def test_has_service(self):
        """Teste de verificação se serviço existe."""
        mock_service = MagicMock()
        self.container.register_singleton("test_service", mock_service)
        
        self.assertTrue(self.container.has("test_service"))
        self.assertFalse(self.container.has("nonexistent_service"))
    
    def test_list_services(self):
        """Teste de listagem de serviços."""
        mock_singleton = MagicMock()
        mock_factory = lambda: MagicMock()
        
        self.container.register_singleton("singleton_service", mock_singleton)
        self.container.register_factory("factory_service", mock_factory)
        
        services = self.container.list_services()
        
        self.assertIn("singleton_service", services)
        self.assertIn("factory_service", services)
        self.assertEqual(services["singleton_service"], "singleton")
        self.assertEqual(services["factory_service"], "factory")
    
    def test_clear(self):
        """Teste de limpeza do container."""
        mock_service = MagicMock()
        self.container.register_singleton("test_service", mock_service)
        
        self.assertTrue(self.container.has("test_service"))
        
        self.container.clear()
        
        self.assertFalse(self.container.has("test_service"))


class TestDISetup(unittest.TestCase):
    """Testes para o setup automático de DI."""
    
    def setUp(self):
        """Setup comum para os testes."""
        reset_container()
    
    def tearDown(self):
        """Cleanup após os testes."""
        reset_container()
    
    def test_setup_di_container_basic(self):
        """Teste básico do setup do container."""
        setup_di_container()
        
        container = get_container()
        services = container.list_services()
        
        # Deve ter serviços básicos
        self.assertIn("logger", services)
        self.assertIn("settings", services)
        self.assertIn("redis_cache", services)
    
    def test_get_service_helper(self):
        """Teste do helper get_service."""
        setup_di_container()
        
        logger = get_service("logger")
        self.assertIsNotNone(logger)
    
    def test_get_service_optional_helper(self):
        """Teste do helper get_service_optional."""
        setup_di_container()
        
        # Serviço existente
        logger = get_service_optional("logger")
        self.assertIsNotNone(logger)
        
        # Serviço inexistente
        nonexistent = get_service_optional("nonexistent")
        self.assertIsNone(nonexistent)


class TestInjectDecorator(unittest.TestCase):
    """Testes para o decorator @inject."""
    
    def setUp(self):
        """Setup comum para os testes."""
        reset_container()
        setup_di_container()
    
    def tearDown(self):
        """Cleanup após os testes."""
        reset_container()
    
    def test_inject_sync_function(self):
        """Teste de injeção em função síncrona."""
        @inject(logger="logger")
        def test_function(message, logger=None):
            return f"{message} - {logger is not None}"
        
        result = test_function("test")
        self.assertEqual(result, "test - True")
    
    def test_inject_async_function(self):
        """Teste de injeção em função assíncrona."""
        import asyncio
        
        @inject(logger="logger")
        async def test_async_function(message, logger=None):
            return f"{message} - {logger is not None}"
        
        async def run_test():
            result = await test_async_function("test")
            self.assertEqual(result, "test - True")
        
        # Executar teste assíncrono
        asyncio.run(run_test())
    
    def test_inject_respects_provided_arguments(self):
        """Teste se injeção respeita argumentos fornecidos."""
        mock_provided_logger = MagicMock()
        
        @inject(logger="logger")
        def test_function(message, logger=None):
            return logger
        
        # Fornecer logger explicitamente
        result = test_function("test", logger=mock_provided_logger)
        self.assertIs(result, mock_provided_logger)
    
    def test_inject_with_nonexistent_service(self):
        """Teste de injeção com serviço inexistente."""
        @inject(nonexistent="nonexistent_service")
        def test_function(message, nonexistent=None):
            return nonexistent
        
        result = test_function("test")
        self.assertIsNone(result)


class TestDIIntegration(unittest.TestCase):
    """Testes de integração do sistema de DI."""
    
    def setUp(self):
        """Setup comum para os testes."""
        reset_container()
    
    def tearDown(self):
        """Cleanup após os testes."""
        reset_container()
    
    def test_full_setup_and_orchestrator_creation(self):
        """Teste de setup completo e criação do orchestrator."""
        setup_di_container()
        
        # Obter orchestrator via DI
        from ..di.setup import get_matching_orchestrator
        orchestrator = get_matching_orchestrator()
        
        self.assertIsNotNone(orchestrator)
        self.assertTrue(hasattr(orchestrator, 'rank_lawyers'))
        self.assertTrue(hasattr(orchestrator, 'record_case_outcome'))
    
    def test_service_dependencies_resolution(self):
        """Teste de resolução de dependências entre serviços."""
        setup_di_container()
        
        container = get_container()
        
        # Obter serviços que dependem uns dos outros
        ranking_facade = container.get("ranking_facade")
        feedback_facade = container.get("feedback_facade")
        
        self.assertIsNotNone(ranking_facade)
        self.assertIsNotNone(feedback_facade)


if __name__ == "__main__":
    unittest.main()
 
 