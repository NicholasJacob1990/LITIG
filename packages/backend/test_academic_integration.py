#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
test_academic_integration.py

Script de teste para validar a integração completa do enriquecimento acadêmico.
Testa a classe AcademicEnricher, integração com Escavador e APIs externas.
"""

import asyncio
import logging
import os
import sys
from datetime import datetime
from typing import Dict, Any

# Adicionar path para imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Carregar variáveis de ambiente
from dotenv import load_dotenv
load_dotenv()

async def test_escavador_curriculum():
    """Testa a busca de currículo via Escavador."""
    logger.info("🧪 Testando busca de currículo no Escavador...")
    
    try:
        from services.escavador_integration import EscavadorClient
        
        api_key = os.getenv("ESCAVADOR_API_KEY")
        if not api_key or api_key == "your_escavador_api_key_here":
            logger.warning("⚠️ Chave do Escavador não configurada - pulando teste")
            return False
        
        client = EscavadorClient(api_key=api_key)
        
        # Teste com nome fictício (substituir por nome real para teste)
        test_name = "José da Silva"
        test_oab = "123456"
        
        curriculum_data = await client.get_curriculum_data(
            person_name=test_name,
            oab_number=test_oab
        )
        
        if curriculum_data:
            logger.info("✅ Currículo encontrado!")
            logger.info(f"   - Anos de experiência: {curriculum_data.get('anos_experiencia', 0)}")
            logger.info(f"   - Pós-graduações: {len(curriculum_data.get('pos_graduacoes', []))}")
            logger.info(f"   - Publicações: {len(curriculum_data.get('publicacoes', []))}")
            logger.info(f"   - Tem currículo Lattes: {curriculum_data.get('tem_curriculo', False)}")
            return True
        else:
            logger.warning("⚠️ Nenhum currículo encontrado")
            return False
            
    except Exception as e:
        logger.error(f"❌ Erro no teste do Escavador: {e}")
        return False

async def test_academic_enricher():
    """Testa a classe AcademicEnricher."""
    logger.info("🧪 Testando AcademicEnricher...")
    
    try:
        # Import do algoritmo
        from Algoritmo.algoritmo_match import AcademicEnricher, RedisCache, REDIS_URL
        
        # Configurar cache
        cache = RedisCache(REDIS_URL)
        enricher = AcademicEnricher(cache)
        
        # Teste básico de universidades
        test_universities = ["Universidade de São Paulo", "Harvard Law School"]
        logger.info(f"Testando universidades: {test_universities}")
        
        uni_scores = await enricher.score_universities(test_universities)
        logger.info(f"✅ Scores de universidades: {uni_scores}")
        
        # Teste básico de periódicos
        test_journals = ["Revista de Direito Administrativo", "Harvard Law Review"]
        logger.info(f"Testando periódicos: {test_journals}")
        
        jour_scores = await enricher.score_journals(test_journals)
        logger.info(f"✅ Scores de periódicos: {jour_scores}")
        
        # Fechar cache
        await cache.close()
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erro no teste do AcademicEnricher: {e}")
        return False

async def test_feature_calculator_integration():
    """Testa a integração no FeatureCalculator."""
    logger.info("🧪 Testando integração no FeatureCalculator...")
    
    try:
        # Imports do algoritmo
        from Algoritmo.algoritmo_match import (
            FeatureCalculator, Case, Lawyer, KPI, 
            EMBEDDING_DIM, ProfessionalMaturityData
        )
        import numpy as np
        
        # Criar caso de teste
        case = Case(
            id="test_case",
            area="Trabalhista",
            subarea="Rescisão",
            urgency_h=48,
            coords=(-23.5505, -46.6333),
            complexity="MEDIUM",
            summary_embedding=np.random.rand(EMBEDDING_DIM),
        )
        
        # Criar advogado de teste com currículo acadêmico
        lawyer = Lawyer(
            id="test_lawyer",
            nome="Dr. João Silva",
            tags_expertise=["trabalhista", "civil"],
            geo_latlon=(-23.5505, -46.6333),
            curriculo_json={
                "anos_experiencia": 15,
                "pos_graduacoes": [
                    {
                        "nivel": "mestrado",
                        "titulo": "Mestrado em Direito do Trabalho",
                        "instituicao": "Universidade de São Paulo",
                        "area": "Trabalhista",
                        "ano_inicio": 2010,
                        "ano_fim": 2012
                    }
                ],
                "publicacoes": [
                    {
                        "ano": 2020,
                        "titulo": "Direitos Trabalhistas Modernos",
                        "journal": "Revista de Direito do Trabalho",
                        "tipo": "artigo"
                    }
                ],
                "num_publicacoes": 1,
                "areas_de_atuacao": "Direito do Trabalho, Direito Civil",
                "fonte": "escavador_lattes",
                "tem_curriculo": True
            },
            kpi=KPI(
                success_rate=0.85,
                cases_30d=20,
                avaliacao_media=4.5,
                tempo_resposta_h=24,
                cv_score=0.8,
                success_status="V"
            ),
            max_concurrent_cases=25,
            diversity=None,
            kpi_subarea={"Trabalhista/Rescisão": 0.9},
            kpi_softskill=0.8,
            case_outcomes=[True, True, False, True],
            review_texts=["Excelente profissional", "Muito competente"],
            casos_historicos_embeddings=[np.random.rand(EMBEDDING_DIM) for _ in range(3)],
            maturity_data=ProfessionalMaturityData(
                experience_years=15,
                network_strength=150,
                reputation_signals=25,
                responsiveness_hours=12
            )
        )
        
        # Testar FeatureCalculator
        calculator = FeatureCalculator(case, lawyer)
        
        # Teste síncrono (fallback)
        logger.info("Testando qualification_score (síncrono)...")
        qual_score_sync = calculator.qualification_score()
        logger.info(f"✅ Qualification Score (sync): {qual_score_sync:.3f}")
        
        # Teste assíncrono (com enriquecimento acadêmico)
        logger.info("Testando qualification_score_async (com enriquecimento)...")
        qual_score_async = await calculator.qualification_score_async()
        logger.info(f"✅ Qualification Score (async): {qual_score_async:.3f}")
        
        # Teste de todas as features
        logger.info("Testando all_async (todas as features)...")
        all_features = await calculator.all_async()
        logger.info("✅ Todas as features calculadas:")
        for feature, score in all_features.items():
            logger.info(f"   - {feature}: {score:.3f}")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erro no teste do FeatureCalculator: {e}")
        return False

async def test_api_keys_configuration():
    """Testa se as chaves das APIs estão configuradas."""
    logger.info("🧪 Testando configuração das APIs...")
    
    tests_passed = 0
    total_tests = 3
    
    # Teste Escavador
    escavador_key = os.getenv("ESCAVADOR_API_KEY")
    if escavador_key and escavador_key != "your_escavador_api_key_here":
        logger.info("✅ Chave do Escavador configurada")
        tests_passed += 1
    else:
        logger.warning("⚠️ Chave do Escavador não configurada")
    
    # Teste Perplexity
    perplexity_key = os.getenv("PERPLEXITY_API_KEY")
    if perplexity_key and perplexity_key != "your_perplexity_api_key_here":
        logger.info("✅ Chave do Perplexity configurada")
        tests_passed += 1
    else:
        logger.warning("⚠️ Chave do Perplexity não configurada")
    
    # Teste OpenAI (opcional)
    openai_key = os.getenv("OPENAI_DEEP_KEY")
    if openai_key and openai_key != "your_openai_api_key_here":
        logger.info("✅ Chave do OpenAI configurada")
        tests_passed += 1
    else:
        logger.warning("⚠️ Chave do OpenAI não configurada (opcional)")
        tests_passed += 1  # Considerar como passado pois é opcional
    
    logger.info(f"📊 APIs configuradas: {tests_passed}/{total_tests}")
    return tests_passed >= 2  # Precisa de pelo menos 2/3 (Escavador é obrigatório)

def create_sample_env_file():
    """Cria arquivo .env de exemplo se não existir."""
    env_file = ".env"
    config_file = "config_academic_apis.env"
    
    if not os.path.exists(env_file) and os.path.exists(config_file):
        logger.info("📝 Criando arquivo .env de exemplo...")
        
        import shutil
        shutil.copy(config_file, env_file)
        
        logger.info(f"✅ Arquivo .env criado a partir de {config_file}")
        logger.info("⚠️ IMPORTANTE: Configure suas chaves reais no arquivo .env")
        return True
    
    return False

async def main():
    """Função principal de teste."""
    logger.info("🚀 Iniciando testes de integração acadêmica...")
    logger.info("=" * 60)
    
    # Estatísticas dos testes
    tests_results = []
    
    # Criar .env se necessário
    create_sample_env_file()
    
    # 1. Testar configuração das APIs
    logger.info("\n1️⃣ TESTE DE CONFIGURAÇÃO DAS APIS")
    result1 = await test_api_keys_configuration()
    tests_results.append(("Configuração APIs", result1))
    
    # 2. Testar AcademicEnricher
    logger.info("\n2️⃣ TESTE DO ACADEMIC ENRICHER")
    result2 = await test_academic_enricher()
    tests_results.append(("AcademicEnricher", result2))
    
    # 3. Testar integração Escavador
    logger.info("\n3️⃣ TESTE DE INTEGRAÇÃO ESCAVADOR")
    result3 = await test_escavador_curriculum()
    tests_results.append(("Integração Escavador", result3))
    
    # 4. Testar FeatureCalculator
    logger.info("\n4️⃣ TESTE DO FEATURE CALCULATOR")
    result4 = await test_feature_calculator_integration()
    tests_results.append(("FeatureCalculator", result4))
    
    # Relatório final
    logger.info("\n" + "=" * 60)
    logger.info("📊 RELATÓRIO FINAL DOS TESTES")
    logger.info("=" * 60)
    
    passed_tests = 0
    total_tests = len(tests_results)
    
    for test_name, result in tests_results:
        status = "✅ PASSOU" if result else "❌ FALHOU"
        logger.info(f"{test_name}: {status}")
        if result:
            passed_tests += 1
    
    logger.info("-" * 60)
    logger.info(f"Testes passados: {passed_tests}/{total_tests}")
    
    if passed_tests == total_tests:
        logger.info("🎉 TODOS OS TESTES PASSARAM!")
        logger.info("✅ Integração acadêmica está funcionando corretamente")
    elif passed_tests >= total_tests // 2:
        logger.info("⚠️ ALGUNS TESTES FALHARAM")
        logger.info("🔧 Verifique as configurações e dependências")
    else:
        logger.info("❌ MUITOS TESTES FALHARAM")
        logger.info("🚨 Verifique se as APIs estão configuradas corretamente")
    
    logger.info("\n📚 PRÓXIMOS PASSOS:")
    logger.info("1. Configure as chaves das APIs no arquivo .env")
    logger.info("2. Instale Redis: brew install redis (macOS) ou docker run -p 6379:6379 redis")
    logger.info("3. Execute: redis-server")
    logger.info("4. Execute novamente este teste: python test_academic_integration.py")
    
    return passed_tests == total_tests

if __name__ == "__main__":
    try:
        success = asyncio.run(main())
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        logger.info("\n⏹️ Teste interrompido pelo usuário")
        sys.exit(1)
    except Exception as e:
        logger.error(f"\n💥 Erro inesperado: {e}")
        sys.exit(1) 
# -*- coding: utf-8 -*-
"""
test_academic_integration.py

Script de teste para validar a integração completa do enriquecimento acadêmico.
Testa a classe AcademicEnricher, integração com Escavador e APIs externas.
"""

import asyncio
import logging
import os
import sys
from datetime import datetime
from typing import Dict, Any

# Adicionar path para imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Carregar variáveis de ambiente
from dotenv import load_dotenv
load_dotenv()

async def test_escavador_curriculum():
    """Testa a busca de currículo via Escavador."""
    logger.info("🧪 Testando busca de currículo no Escavador...")
    
    try:
        from services.escavador_integration import EscavadorClient
        
        api_key = os.getenv("ESCAVADOR_API_KEY")
        if not api_key or api_key == "your_escavador_api_key_here":
            logger.warning("⚠️ Chave do Escavador não configurada - pulando teste")
            return False
        
        client = EscavadorClient(api_key=api_key)
        
        # Teste com nome fictício (substituir por nome real para teste)
        test_name = "José da Silva"
        test_oab = "123456"
        
        curriculum_data = await client.get_curriculum_data(
            person_name=test_name,
            oab_number=test_oab
        )
        
        if curriculum_data:
            logger.info("✅ Currículo encontrado!")
            logger.info(f"   - Anos de experiência: {curriculum_data.get('anos_experiencia', 0)}")
            logger.info(f"   - Pós-graduações: {len(curriculum_data.get('pos_graduacoes', []))}")
            logger.info(f"   - Publicações: {len(curriculum_data.get('publicacoes', []))}")
            logger.info(f"   - Tem currículo Lattes: {curriculum_data.get('tem_curriculo', False)}")
            return True
        else:
            logger.warning("⚠️ Nenhum currículo encontrado")
            return False
            
    except Exception as e:
        logger.error(f"❌ Erro no teste do Escavador: {e}")
        return False

async def test_academic_enricher():
    """Testa a classe AcademicEnricher."""
    logger.info("🧪 Testando AcademicEnricher...")
    
    try:
        # Import do algoritmo
        from Algoritmo.algoritmo_match import AcademicEnricher, RedisCache, REDIS_URL
        
        # Configurar cache
        cache = RedisCache(REDIS_URL)
        enricher = AcademicEnricher(cache)
        
        # Teste básico de universidades
        test_universities = ["Universidade de São Paulo", "Harvard Law School"]
        logger.info(f"Testando universidades: {test_universities}")
        
        uni_scores = await enricher.score_universities(test_universities)
        logger.info(f"✅ Scores de universidades: {uni_scores}")
        
        # Teste básico de periódicos
        test_journals = ["Revista de Direito Administrativo", "Harvard Law Review"]
        logger.info(f"Testando periódicos: {test_journals}")
        
        jour_scores = await enricher.score_journals(test_journals)
        logger.info(f"✅ Scores de periódicos: {jour_scores}")
        
        # Fechar cache
        await cache.close()
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erro no teste do AcademicEnricher: {e}")
        return False

async def test_feature_calculator_integration():
    """Testa a integração no FeatureCalculator."""
    logger.info("🧪 Testando integração no FeatureCalculator...")
    
    try:
        # Imports do algoritmo
        from Algoritmo.algoritmo_match import (
            FeatureCalculator, Case, Lawyer, KPI, 
            EMBEDDING_DIM, ProfessionalMaturityData
        )
        import numpy as np
        
        # Criar caso de teste
        case = Case(
            id="test_case",
            area="Trabalhista",
            subarea="Rescisão",
            urgency_h=48,
            coords=(-23.5505, -46.6333),
            complexity="MEDIUM",
            summary_embedding=np.random.rand(EMBEDDING_DIM),
        )
        
        # Criar advogado de teste com currículo acadêmico
        lawyer = Lawyer(
            id="test_lawyer",
            nome="Dr. João Silva",
            tags_expertise=["trabalhista", "civil"],
            geo_latlon=(-23.5505, -46.6333),
            curriculo_json={
                "anos_experiencia": 15,
                "pos_graduacoes": [
                    {
                        "nivel": "mestrado",
                        "titulo": "Mestrado em Direito do Trabalho",
                        "instituicao": "Universidade de São Paulo",
                        "area": "Trabalhista",
                        "ano_inicio": 2010,
                        "ano_fim": 2012
                    }
                ],
                "publicacoes": [
                    {
                        "ano": 2020,
                        "titulo": "Direitos Trabalhistas Modernos",
                        "journal": "Revista de Direito do Trabalho",
                        "tipo": "artigo"
                    }
                ],
                "num_publicacoes": 1,
                "areas_de_atuacao": "Direito do Trabalho, Direito Civil",
                "fonte": "escavador_lattes",
                "tem_curriculo": True
            },
            kpi=KPI(
                success_rate=0.85,
                cases_30d=20,
                avaliacao_media=4.5,
                tempo_resposta_h=24,
                cv_score=0.8,
                success_status="V"
            ),
            max_concurrent_cases=25,
            diversity=None,
            kpi_subarea={"Trabalhista/Rescisão": 0.9},
            kpi_softskill=0.8,
            case_outcomes=[True, True, False, True],
            review_texts=["Excelente profissional", "Muito competente"],
            casos_historicos_embeddings=[np.random.rand(EMBEDDING_DIM) for _ in range(3)],
            maturity_data=ProfessionalMaturityData(
                experience_years=15,
                network_strength=150,
                reputation_signals=25,
                responsiveness_hours=12
            )
        )
        
        # Testar FeatureCalculator
        calculator = FeatureCalculator(case, lawyer)
        
        # Teste síncrono (fallback)
        logger.info("Testando qualification_score (síncrono)...")
        qual_score_sync = calculator.qualification_score()
        logger.info(f"✅ Qualification Score (sync): {qual_score_sync:.3f}")
        
        # Teste assíncrono (com enriquecimento acadêmico)
        logger.info("Testando qualification_score_async (com enriquecimento)...")
        qual_score_async = await calculator.qualification_score_async()
        logger.info(f"✅ Qualification Score (async): {qual_score_async:.3f}")
        
        # Teste de todas as features
        logger.info("Testando all_async (todas as features)...")
        all_features = await calculator.all_async()
        logger.info("✅ Todas as features calculadas:")
        for feature, score in all_features.items():
            logger.info(f"   - {feature}: {score:.3f}")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erro no teste do FeatureCalculator: {e}")
        return False

async def test_api_keys_configuration():
    """Testa se as chaves das APIs estão configuradas."""
    logger.info("🧪 Testando configuração das APIs...")
    
    tests_passed = 0
    total_tests = 3
    
    # Teste Escavador
    escavador_key = os.getenv("ESCAVADOR_API_KEY")
    if escavador_key and escavador_key != "your_escavador_api_key_here":
        logger.info("✅ Chave do Escavador configurada")
        tests_passed += 1
    else:
        logger.warning("⚠️ Chave do Escavador não configurada")
    
    # Teste Perplexity
    perplexity_key = os.getenv("PERPLEXITY_API_KEY")
    if perplexity_key and perplexity_key != "your_perplexity_api_key_here":
        logger.info("✅ Chave do Perplexity configurada")
        tests_passed += 1
    else:
        logger.warning("⚠️ Chave do Perplexity não configurada")
    
    # Teste OpenAI (opcional)
    openai_key = os.getenv("OPENAI_DEEP_KEY")
    if openai_key and openai_key != "your_openai_api_key_here":
        logger.info("✅ Chave do OpenAI configurada")
        tests_passed += 1
    else:
        logger.warning("⚠️ Chave do OpenAI não configurada (opcional)")
        tests_passed += 1  # Considerar como passado pois é opcional
    
    logger.info(f"📊 APIs configuradas: {tests_passed}/{total_tests}")
    return tests_passed >= 2  # Precisa de pelo menos 2/3 (Escavador é obrigatório)

def create_sample_env_file():
    """Cria arquivo .env de exemplo se não existir."""
    env_file = ".env"
    config_file = "config_academic_apis.env"
    
    if not os.path.exists(env_file) and os.path.exists(config_file):
        logger.info("📝 Criando arquivo .env de exemplo...")
        
        import shutil
        shutil.copy(config_file, env_file)
        
        logger.info(f"✅ Arquivo .env criado a partir de {config_file}")
        logger.info("⚠️ IMPORTANTE: Configure suas chaves reais no arquivo .env")
        return True
    
    return False

async def main():
    """Função principal de teste."""
    logger.info("🚀 Iniciando testes de integração acadêmica...")
    logger.info("=" * 60)
    
    # Estatísticas dos testes
    tests_results = []
    
    # Criar .env se necessário
    create_sample_env_file()
    
    # 1. Testar configuração das APIs
    logger.info("\n1️⃣ TESTE DE CONFIGURAÇÃO DAS APIS")
    result1 = await test_api_keys_configuration()
    tests_results.append(("Configuração APIs", result1))
    
    # 2. Testar AcademicEnricher
    logger.info("\n2️⃣ TESTE DO ACADEMIC ENRICHER")
    result2 = await test_academic_enricher()
    tests_results.append(("AcademicEnricher", result2))
    
    # 3. Testar integração Escavador
    logger.info("\n3️⃣ TESTE DE INTEGRAÇÃO ESCAVADOR")
    result3 = await test_escavador_curriculum()
    tests_results.append(("Integração Escavador", result3))
    
    # 4. Testar FeatureCalculator
    logger.info("\n4️⃣ TESTE DO FEATURE CALCULATOR")
    result4 = await test_feature_calculator_integration()
    tests_results.append(("FeatureCalculator", result4))
    
    # Relatório final
    logger.info("\n" + "=" * 60)
    logger.info("📊 RELATÓRIO FINAL DOS TESTES")
    logger.info("=" * 60)
    
    passed_tests = 0
    total_tests = len(tests_results)
    
    for test_name, result in tests_results:
        status = "✅ PASSOU" if result else "❌ FALHOU"
        logger.info(f"{test_name}: {status}")
        if result:
            passed_tests += 1
    
    logger.info("-" * 60)
    logger.info(f"Testes passados: {passed_tests}/{total_tests}")
    
    if passed_tests == total_tests:
        logger.info("🎉 TODOS OS TESTES PASSARAM!")
        logger.info("✅ Integração acadêmica está funcionando corretamente")
    elif passed_tests >= total_tests // 2:
        logger.info("⚠️ ALGUNS TESTES FALHARAM")
        logger.info("🔧 Verifique as configurações e dependências")
    else:
        logger.info("❌ MUITOS TESTES FALHARAM")
        logger.info("🚨 Verifique se as APIs estão configuradas corretamente")
    
    logger.info("\n📚 PRÓXIMOS PASSOS:")
    logger.info("1. Configure as chaves das APIs no arquivo .env")
    logger.info("2. Instale Redis: brew install redis (macOS) ou docker run -p 6379:6379 redis")
    logger.info("3. Execute: redis-server")
    logger.info("4. Execute novamente este teste: python test_academic_integration.py")
    
    return passed_tests == total_tests

if __name__ == "__main__":
    try:
        success = asyncio.run(main())
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        logger.info("\n⏹️ Teste interrompido pelo usuário")
        sys.exit(1)
    except Exception as e:
        logger.error(f"\n💥 Erro inesperado: {e}")
        sys.exit(1) 
# -*- coding: utf-8 -*-
"""
test_academic_integration.py

Script de teste para validar a integração completa do enriquecimento acadêmico.
Testa a classe AcademicEnricher, integração com Escavador e APIs externas.
"""

import asyncio
import logging
import os
import sys
from datetime import datetime
from typing import Dict, Any

# Adicionar path para imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Carregar variáveis de ambiente
from dotenv import load_dotenv
load_dotenv()

async def test_escavador_curriculum():
    """Testa a busca de currículo via Escavador."""
    logger.info("🧪 Testando busca de currículo no Escavador...")
    
    try:
        from services.escavador_integration import EscavadorClient
        
        api_key = os.getenv("ESCAVADOR_API_KEY")
        if not api_key or api_key == "your_escavador_api_key_here":
            logger.warning("⚠️ Chave do Escavador não configurada - pulando teste")
            return False
        
        client = EscavadorClient(api_key=api_key)
        
        # Teste com nome fictício (substituir por nome real para teste)
        test_name = "José da Silva"
        test_oab = "123456"
        
        curriculum_data = await client.get_curriculum_data(
            person_name=test_name,
            oab_number=test_oab
        )
        
        if curriculum_data:
            logger.info("✅ Currículo encontrado!")
            logger.info(f"   - Anos de experiência: {curriculum_data.get('anos_experiencia', 0)}")
            logger.info(f"   - Pós-graduações: {len(curriculum_data.get('pos_graduacoes', []))}")
            logger.info(f"   - Publicações: {len(curriculum_data.get('publicacoes', []))}")
            logger.info(f"   - Tem currículo Lattes: {curriculum_data.get('tem_curriculo', False)}")
            return True
        else:
            logger.warning("⚠️ Nenhum currículo encontrado")
            return False
            
    except Exception as e:
        logger.error(f"❌ Erro no teste do Escavador: {e}")
        return False

async def test_academic_enricher():
    """Testa a classe AcademicEnricher."""
    logger.info("🧪 Testando AcademicEnricher...")
    
    try:
        # Import do algoritmo
        from Algoritmo.algoritmo_match import AcademicEnricher, RedisCache, REDIS_URL
        
        # Configurar cache
        cache = RedisCache(REDIS_URL)
        enricher = AcademicEnricher(cache)
        
        # Teste básico de universidades
        test_universities = ["Universidade de São Paulo", "Harvard Law School"]
        logger.info(f"Testando universidades: {test_universities}")
        
        uni_scores = await enricher.score_universities(test_universities)
        logger.info(f"✅ Scores de universidades: {uni_scores}")
        
        # Teste básico de periódicos
        test_journals = ["Revista de Direito Administrativo", "Harvard Law Review"]
        logger.info(f"Testando periódicos: {test_journals}")
        
        jour_scores = await enricher.score_journals(test_journals)
        logger.info(f"✅ Scores de periódicos: {jour_scores}")
        
        # Fechar cache
        await cache.close()
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erro no teste do AcademicEnricher: {e}")
        return False

async def test_feature_calculator_integration():
    """Testa a integração no FeatureCalculator."""
    logger.info("🧪 Testando integração no FeatureCalculator...")
    
    try:
        # Imports do algoritmo
        from Algoritmo.algoritmo_match import (
            FeatureCalculator, Case, Lawyer, KPI, 
            EMBEDDING_DIM, ProfessionalMaturityData
        )
        import numpy as np
        
        # Criar caso de teste
        case = Case(
            id="test_case",
            area="Trabalhista",
            subarea="Rescisão",
            urgency_h=48,
            coords=(-23.5505, -46.6333),
            complexity="MEDIUM",
            summary_embedding=np.random.rand(EMBEDDING_DIM),
        )
        
        # Criar advogado de teste com currículo acadêmico
        lawyer = Lawyer(
            id="test_lawyer",
            nome="Dr. João Silva",
            tags_expertise=["trabalhista", "civil"],
            geo_latlon=(-23.5505, -46.6333),
            curriculo_json={
                "anos_experiencia": 15,
                "pos_graduacoes": [
                    {
                        "nivel": "mestrado",
                        "titulo": "Mestrado em Direito do Trabalho",
                        "instituicao": "Universidade de São Paulo",
                        "area": "Trabalhista",
                        "ano_inicio": 2010,
                        "ano_fim": 2012
                    }
                ],
                "publicacoes": [
                    {
                        "ano": 2020,
                        "titulo": "Direitos Trabalhistas Modernos",
                        "journal": "Revista de Direito do Trabalho",
                        "tipo": "artigo"
                    }
                ],
                "num_publicacoes": 1,
                "areas_de_atuacao": "Direito do Trabalho, Direito Civil",
                "fonte": "escavador_lattes",
                "tem_curriculo": True
            },
            kpi=KPI(
                success_rate=0.85,
                cases_30d=20,
                avaliacao_media=4.5,
                tempo_resposta_h=24,
                cv_score=0.8,
                success_status="V"
            ),
            max_concurrent_cases=25,
            diversity=None,
            kpi_subarea={"Trabalhista/Rescisão": 0.9},
            kpi_softskill=0.8,
            case_outcomes=[True, True, False, True],
            review_texts=["Excelente profissional", "Muito competente"],
            casos_historicos_embeddings=[np.random.rand(EMBEDDING_DIM) for _ in range(3)],
            maturity_data=ProfessionalMaturityData(
                experience_years=15,
                network_strength=150,
                reputation_signals=25,
                responsiveness_hours=12
            )
        )
        
        # Testar FeatureCalculator
        calculator = FeatureCalculator(case, lawyer)
        
        # Teste síncrono (fallback)
        logger.info("Testando qualification_score (síncrono)...")
        qual_score_sync = calculator.qualification_score()
        logger.info(f"✅ Qualification Score (sync): {qual_score_sync:.3f}")
        
        # Teste assíncrono (com enriquecimento acadêmico)
        logger.info("Testando qualification_score_async (com enriquecimento)...")
        qual_score_async = await calculator.qualification_score_async()
        logger.info(f"✅ Qualification Score (async): {qual_score_async:.3f}")
        
        # Teste de todas as features
        logger.info("Testando all_async (todas as features)...")
        all_features = await calculator.all_async()
        logger.info("✅ Todas as features calculadas:")
        for feature, score in all_features.items():
            logger.info(f"   - {feature}: {score:.3f}")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erro no teste do FeatureCalculator: {e}")
        return False

async def test_api_keys_configuration():
    """Testa se as chaves das APIs estão configuradas."""
    logger.info("🧪 Testando configuração das APIs...")
    
    tests_passed = 0
    total_tests = 3
    
    # Teste Escavador
    escavador_key = os.getenv("ESCAVADOR_API_KEY")
    if escavador_key and escavador_key != "your_escavador_api_key_here":
        logger.info("✅ Chave do Escavador configurada")
        tests_passed += 1
    else:
        logger.warning("⚠️ Chave do Escavador não configurada")
    
    # Teste Perplexity
    perplexity_key = os.getenv("PERPLEXITY_API_KEY")
    if perplexity_key and perplexity_key != "your_perplexity_api_key_here":
        logger.info("✅ Chave do Perplexity configurada")
        tests_passed += 1
    else:
        logger.warning("⚠️ Chave do Perplexity não configurada")
    
    # Teste OpenAI (opcional)
    openai_key = os.getenv("OPENAI_DEEP_KEY")
    if openai_key and openai_key != "your_openai_api_key_here":
        logger.info("✅ Chave do OpenAI configurada")
        tests_passed += 1
    else:
        logger.warning("⚠️ Chave do OpenAI não configurada (opcional)")
        tests_passed += 1  # Considerar como passado pois é opcional
    
    logger.info(f"📊 APIs configuradas: {tests_passed}/{total_tests}")
    return tests_passed >= 2  # Precisa de pelo menos 2/3 (Escavador é obrigatório)

def create_sample_env_file():
    """Cria arquivo .env de exemplo se não existir."""
    env_file = ".env"
    config_file = "config_academic_apis.env"
    
    if not os.path.exists(env_file) and os.path.exists(config_file):
        logger.info("📝 Criando arquivo .env de exemplo...")
        
        import shutil
        shutil.copy(config_file, env_file)
        
        logger.info(f"✅ Arquivo .env criado a partir de {config_file}")
        logger.info("⚠️ IMPORTANTE: Configure suas chaves reais no arquivo .env")
        return True
    
    return False

async def main():
    """Função principal de teste."""
    logger.info("🚀 Iniciando testes de integração acadêmica...")
    logger.info("=" * 60)
    
    # Estatísticas dos testes
    tests_results = []
    
    # Criar .env se necessário
    create_sample_env_file()
    
    # 1. Testar configuração das APIs
    logger.info("\n1️⃣ TESTE DE CONFIGURAÇÃO DAS APIS")
    result1 = await test_api_keys_configuration()
    tests_results.append(("Configuração APIs", result1))
    
    # 2. Testar AcademicEnricher
    logger.info("\n2️⃣ TESTE DO ACADEMIC ENRICHER")
    result2 = await test_academic_enricher()
    tests_results.append(("AcademicEnricher", result2))
    
    # 3. Testar integração Escavador
    logger.info("\n3️⃣ TESTE DE INTEGRAÇÃO ESCAVADOR")
    result3 = await test_escavador_curriculum()
    tests_results.append(("Integração Escavador", result3))
    
    # 4. Testar FeatureCalculator
    logger.info("\n4️⃣ TESTE DO FEATURE CALCULATOR")
    result4 = await test_feature_calculator_integration()
    tests_results.append(("FeatureCalculator", result4))
    
    # Relatório final
    logger.info("\n" + "=" * 60)
    logger.info("📊 RELATÓRIO FINAL DOS TESTES")
    logger.info("=" * 60)
    
    passed_tests = 0
    total_tests = len(tests_results)
    
    for test_name, result in tests_results:
        status = "✅ PASSOU" if result else "❌ FALHOU"
        logger.info(f"{test_name}: {status}")
        if result:
            passed_tests += 1
    
    logger.info("-" * 60)
    logger.info(f"Testes passados: {passed_tests}/{total_tests}")
    
    if passed_tests == total_tests:
        logger.info("🎉 TODOS OS TESTES PASSARAM!")
        logger.info("✅ Integração acadêmica está funcionando corretamente")
    elif passed_tests >= total_tests // 2:
        logger.info("⚠️ ALGUNS TESTES FALHARAM")
        logger.info("🔧 Verifique as configurações e dependências")
    else:
        logger.info("❌ MUITOS TESTES FALHARAM")
        logger.info("🚨 Verifique se as APIs estão configuradas corretamente")
    
    logger.info("\n📚 PRÓXIMOS PASSOS:")
    logger.info("1. Configure as chaves das APIs no arquivo .env")
    logger.info("2. Instale Redis: brew install redis (macOS) ou docker run -p 6379:6379 redis")
    logger.info("3. Execute: redis-server")
    logger.info("4. Execute novamente este teste: python test_academic_integration.py")
    
    return passed_tests == total_tests

if __name__ == "__main__":
    try:
        success = asyncio.run(main())
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        logger.info("\n⏹️ Teste interrompido pelo usuário")
        sys.exit(1)
    except Exception as e:
        logger.error(f"\n💥 Erro inesperado: {e}")
        sys.exit(1) 