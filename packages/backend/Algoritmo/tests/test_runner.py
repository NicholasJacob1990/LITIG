# -*- coding: utf-8 -*-
"""
tests/test_runner.py

Test runner para executar todos os testes unitários do sistema de matching.
"""

import unittest
import sys
import time
from io import StringIO


def run_all_tests(verbose=True):
    """
    Executa todos os testes unitários do sistema.
    
    Args:
        verbose: Se deve mostrar output detalhado
        
    Returns:
        True se todos os testes passaram, False caso contrário
    """
    # Carregar suítes de teste manualmente para evitar problemas de descoberta
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Adicionar os testes do algoritmo modularizado
    suite.addTests(loader.loadTestsFromName('Algoritmo.tests.test_di'))
    suite.addTests(loader.loadTestsFromName('Algoritmo.tests.test_features'))
    suite.addTests(loader.loadTestsFromName('Algoritmo.tests.test_utils'))

    # Configurar runner
    stream = StringIO() if not verbose else sys.stdout
    runner = unittest.TextTestRunner(
        stream=stream,
        verbosity=2 if verbose else 1,
        buffer=True
    )
    
    # Executar testes
    print("🧪 Executando testes unitários do sistema de matching...")
    print("=" * 60)
    
    start_time = time.time()
    result = runner.run(suite)
    end_time = time.time()
    
    # Resultados
    duration = end_time - start_time
    
    print("\n" + "=" * 60)
    print(f"📊 RESULTADOS DOS TESTES:")
    print(f"   ✅ Testes executados: {result.testsRun}")
    print(f"   ✅ Sucessos: {result.testsRun - len(result.failures) - len(result.errors)}")
    print(f"   ❌ Falhas: {len(result.failures)}")
    print(f"   🚨 Erros: {len(result.errors)}")
    print(f"   ⏱️  Tempo: {duration:.2f}s")
    
    if result.failures:
        print(f"\n❌ FALHAS:")
        for test, traceback in result.failures:
            print(f"   - {test}: {traceback.split('\n')[-2] if traceback else 'Unknown'}")
    
    if result.errors:
        print(f"\n🚨 ERROS:")
        for test, traceback in result.errors:
            print(f"   - {test}: {traceback.split('\n')[-2] if traceback else 'Unknown'}")
    
    success = len(result.failures) == 0 and len(result.errors) == 0
    
    if success:
        print(f"\n🎉 TODOS OS TESTES PASSARAM! ({result.testsRun} testes)")
    else:
        print(f"\n💥 ALGUNS TESTES FALHARAM! ({len(result.failures) + len(result.errors)} problemas)")
    
    return success


def run_specific_test_module(module_name):
    """
    Executa testes de um módulo específico.
    
    Args:
        module_name: Nome do módulo (ex: 'test_utils', 'test_features')
    """
    loader = unittest.TestLoader()
    suite = loader.loadTestsFromName(f'tests.{module_name}')
    
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    return len(result.failures) == 0 and len(result.errors) == 0


if __name__ == "__main__":
    # Executar via linha de comando
    if len(sys.argv) > 1:
        # Módulo específico
        module = sys.argv[1]
        success = run_specific_test_module(module)
    else:
        # Todos os testes
        success = run_all_tests()
    
    sys.exit(0 if success else 1)
 
 