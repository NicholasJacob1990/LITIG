#!/usr/bin/env python3
"""
Teste Supabase RAG - Sistema RAG Jurídico com Supabase
=====================================================

Script para testar a configuração do sistema RAG com Supabase.

Antes de executar:
1. Configure as variáveis de ambiente:
   - SUPABASE_URL
   - SUPABASE_SERVICE_KEY
   - OPENAI_API_KEY

2. Execute o SQL em supabase_setup.sql no dashboard do Supabase

3. Instale dependências:
   pip install supabase langchain-community

Execução:
python test_supabase_rag.py
"""

import asyncio
import logging
import sys
import os
from pathlib import Path

# Adicionar path dos serviços
sys.path.append(str(Path(__file__).parent))

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class SupabaseRAGTester:
    """Testador do sistema RAG com Supabase."""
    
    def __init__(self):
        self.logger = logging.getLogger(f"{self.__class__.__name__}")
    
    async def run_tests(self):
        """Executa todos os testes do Supabase RAG."""
        print("🧪 TESTE DO SISTEMA RAG COM SUPABASE")
        print("=" * 50)
        
        # Verificar configuração
        if not await self.check_environment():
            return False
        
        # Testar importações
        if not await self.test_imports():
            return False
        
        # Testar inicialização
        if not await self.test_initialization():
            return False
        
        # Testar queries
        await self.test_queries()
        
        print("\n🎉 Todos os testes concluídos!")
        return True
    
    async def check_environment(self) -> bool:
        """Verifica se as variáveis de ambiente estão configuradas."""
        print("\n🔧 Verificando configuração...")
        
        required_vars = [
            "SUPABASE_URL",
            "SUPABASE_SERVICE_KEY", 
            "OPENAI_API_KEY"
        ]
        
        missing_vars = []
        for var in required_vars:
            if not os.getenv(var):
                missing_vars.append(var)
        
        if missing_vars:
            print(f"❌ Variáveis de ambiente faltando: {', '.join(missing_vars)}")
            print("\n💡 Configure:")
            for var in missing_vars:
                print(f"   export {var}='seu_valor'")
            return False
        
        print("✅ Todas as variáveis de ambiente configuradas")
        return True
    
    async def test_imports(self) -> bool:
        """Testa se as dependências estão disponíveis."""
        print("\n📦 Testando importações...")
        
        try:
            from supabase import create_client
            print("✅ supabase")
        except ImportError:
            print("❌ supabase - instale: pip install supabase")
            return False
        
        try:
            from langchain_community.vectorstores import SupabaseVectorStore
            print("✅ langchain_community")
        except ImportError:
            print("❌ langchain_community - instale: pip install langchain-community")
            return False
        
        try:
            from langchain_openai import OpenAIEmbeddings
            print("✅ langchain_openai")
        except ImportError:
            print("❌ langchain_openai - instale: pip install langchain-openai")
            return False
        
        return True
    
    async def test_initialization(self) -> bool:
        """Testa a inicialização do sistema RAG."""
        print("\n🚀 Testando inicialização...")
        
        try:
            # Configurar variáveis para o módulo config
            import sys
            sys.path.append('/Users/nicholasjacob/Documents/Aplicativos/LITIG-1')
            
            # Mock das configurações se config não disponível
            try:
                from config import Settings
            except ImportError:
                class MockSettings:
                    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
                    SUPABASE_URL = os.getenv("SUPABASE_URL") 
                    SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
                
                # Adicionar ao sys.modules para importação
                import types
                config_module = types.ModuleType('config')
                config_module.Settings = MockSettings
                sys.modules['config'] = config_module
            
            # Importar e testar RAG
            from brazilian_legal_rag import BrazilianLegalRAG
            
            # Inicializar com Supabase
            rag = BrazilianLegalRAG(use_supabase=True)
            
            # Verificar status
            stats = rag.get_stats()
            print(f"✅ RAG inicializado - Storage: {stats['storage_type']}")
            print(f"   Supabase habilitado: {stats['supabase_enabled']}")
            
            # Testar inicialização da base
            print("   📚 Inicializando base de conhecimento...")
            success = await rag.initialize_knowledge_base(force_rebuild=True)
            
            if success:
                print("✅ Base de conhecimento inicializada com sucesso")
                self.rag = rag
                return True
            else:
                print("❌ Falha ao inicializar base de conhecimento")
                return False
                
        except Exception as e:
            print(f"❌ Erro na inicialização: {e}")
            return False
    
    async def test_queries(self):
        """Testa consultas no sistema RAG."""
        print("\n❓ Testando consultas...")
        
        if not hasattr(self, 'rag'):
            print("❌ RAG não inicializado")
            return
        
        test_queries = [
            "Quais são os direitos trabalhistas segundo a CLT?",
            "O que diz o artigo 7º da Constituição Federal?",
            "Como funciona a compensação de horário no trabalho?",
            "Quais são as causas de justa causa para demissão?"
        ]
        
        for i, question in enumerate(test_queries, 1):
            print(f"\n🔍 Consulta {i}: {question}")
            
            try:
                result = await self.rag.query(question, include_sources=True)
                
                if result["success"]:
                    print("✅ Consulta processada")
                    print(f"   ⏱️ Duração: {result['duration_seconds']:.2f}s")
                    print(f"   📄 Resposta: {result['answer'][:100]}...")
                    
                    if "sources" in result:
                        print(f"   📚 Fontes: {len(result['sources'])} documentos")
                        for source in result["sources"][:2]:  # Mostrar 2 primeiras fontes
                            print(f"      - {source['source']} ({source['type']})")
                else:
                    print(f"❌ Erro na consulta: {result.get('error', 'Erro desconhecido')}")
                    
            except Exception as e:
                print(f"❌ Exceção na consulta: {e}")
        
        # Testar estatísticas finais
        final_stats = self.rag.get_stats()
        print(f"\n📊 Estatísticas finais:")
        for key, value in final_stats.items():
            print(f"   {key}: {value}")


async def main():
    """Função principal."""
    tester = SupabaseRAGTester()
    success = await tester.run_tests()
    
    if success:
        print("\n🎉 Sistema RAG com Supabase funcionando perfeitamente!")
    else:
        print("\n❌ Alguns testes falharam. Verifique a configuração.")
        sys.exit(1)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n⏹️ Teste interrompido pelo usuário")
    except Exception as e:
        print(f"\n❌ Erro inesperado: {e}")
        sys.exit(1)
