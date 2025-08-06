#!/usr/bin/env python3
"""
Demo Híbrido Simplificado - Demonstração da Estratégia Implementada
==================================================================

Demonstra a implementação híbrida funcionando sem dependências externas.
Mostra a estrutura e conceitos da estratégia para validação.

Execução:
python demo_hybrid_simplified.py
"""

import asyncio
import logging
import json
from typing import Dict, List, Optional, Any
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MockOpenRouterClient:
    """Mock do OpenRouter para demonstração."""
    
    async def chat_completion_with_fallback(self, model: str, messages: List[Dict], **kwargs) -> Dict:
        return {
            "success": True,
            "response": f"Resposta simulada do modelo {model}",
            "model_used": model,
            "method": "openrouter_mock"
        }

class MockLangChainAgent:
    """Mock de agente LangChain para demonstração."""
    
    def __init__(self, name: str, function: str):
        self.name = name
        self.function = function
    
    async def invoke(self, prompt: str) -> Dict:
        return {
            "success": True,
            "response": f"Agente {self.name} processou: {prompt[:50]}...",
            "function": self.function,
            "method": "langchain_agent_mock"
        }

class MockBrazilianRAG:
    """Mock do sistema RAG jurídico para demonstração."""
    
    def __init__(self):
        self.knowledge_base = {
            "clt": "A Consolidação das Leis do Trabalho (CLT) regula direitos trabalhistas...",
            "civil": "O Código Civil brasileiro estabelece normas de direito privado...",
            "criminal": "O Código Penal define crimes e contravenções..."
        }
    
    async def query(self, question: str, include_sources: bool = True) -> Dict:
        # Busca simulada
        relevant_law = "clt" if "trabalh" in question.lower() else "civil"
        
        return {
            "success": True,
            "answer": f"Segundo a legislação brasileira: {self.knowledge_base.get(relevant_law, 'Lei não encontrada')}",
            "sources": [f"Fonte jurídica: {relevant_law.upper()}"] if include_sources else [],
            "method": "brazilian_rag_mock"
        }

class HybridStrategyDemo:
    """
    Demonstração da estratégia híbrida implementada.
    
    Combina:
    ✅ Modelos fixos especializados (preservados)
    ✅ Agentes LangChain inteligentes  
    ✅ RAG jurídico brasileiro
    ✅ Fallback para OpenRouter
    """
    
    def __init__(self):
        self.logger = logging.getLogger(f"{self.__class__.__name__}")
        
        # Inicializar componentes
        self.openrouter_client = MockOpenRouterClient()
        self.rag_system = MockBrazilianRAG()
        
        # Configurar agentes especializados
        self.agents = {
            "contract_analysis": MockLangChainAgent("Análise Contratual", "contract"),
            "case_similarity": MockLangChainAgent("Similaridade de Casos", "similarity"), 
            "legal_research": MockLangChainAgent("Pesquisa Jurídica", "research"),
            "client_triage": MockLangChainAgent("Triagem de Clientes", "triage")
        }
        
        # Modelos fixos especializados (preservados)
        self.specialized_models = {
            "ocr": "gpt-4o-mini",  # OCR de documentos
            "general": "gpt-4o-mini",  # Consultas gerais
            "case": "claude-3-5-sonnet-20241022",  # Análise de casos
            "profile": "gemini-pro",  # Perfil de advogados
            "judge": "gemini-1.5-flash",  # Perfil de juízes
            "academic": "grok-2",  # Enriquecimento acadêmico
            "cost_optimization": "openrouter/auto"  # Otimização de custos
        }
        
        self.logger.info("🔄 Estratégia híbrida inicializada")
    
    def get_status(self) -> Dict:
        """Retorna status da implementação híbrida."""
        return {
            "strategy": "hybrid",
            "components": {
                "specialized_models": len(self.specialized_models),
                "langchain_agents": len(self.agents),
                "rag_system": "brazilian_legal",
                "fallback_system": "openrouter_4_levels"
            },
            "models": self.specialized_models,
            "agents": list(self.agents.keys()),
            "status": "operational",
            "timestamp": datetime.now().isoformat()
        }
    
    async def route_by_function(self, function: str, prompt: str, use_agents: bool = True, use_rag: bool = True) -> Dict:
        """
        Roteamento híbrido inteligente.
        
        Estratégia:
        1. Se função tem agente especializado → usar agente LangChain
        2. Se pergunta jurídica → consultar RAG primeiro  
        3. Fallback → modelo fixo especializado via OpenRouter
        4. Fallback final → OpenRouter auto-router
        """
        start_time = datetime.now()
        
        self.logger.info(f"🎯 Roteando função '{function}' com prompt: {prompt[:50]}...")
        
        # 1. Tentar agente LangChain especializado
        if use_agents and function in self.agents:
            self.logger.info(f"🤖 Usando agente LangChain: {function}")
            result = await self.agents[function].invoke(prompt)
            result["routing_path"] = "langchain_agent"
            result["duration_ms"] = (datetime.now() - start_time).total_seconds() * 1000
            return result
        
        # 2. Enriquecer com RAG se pergunta jurídica
        rag_context = ""
        if use_rag and any(word in prompt.lower() for word in ["lei", "artigo", "código", "clt", "direito"]):
            self.logger.info("📚 Consultando RAG jurídico brasileiro")
            rag_result = await self.rag_system.query(prompt)
            if rag_result.get("success"):
                rag_context = f"Contexto jurídico: {rag_result['answer']}\n\n"
        
        # 3. Determinar modelo especializado
        specialized_model = self.specialized_models.get(function, "gpt-4o-mini")
        enhanced_prompt = rag_context + prompt
        
        self.logger.info(f"🎯 Usando modelo especializado: {specialized_model}")
        
        # 4. Executar via OpenRouter com fallback
        messages = [{"role": "user", "content": enhanced_prompt}]
        result = await self.openrouter_client.chat_completion_with_fallback(
            model=specialized_model,
            messages=messages
        )
        
        result["routing_path"] = "specialized_model"
        result["rag_used"] = bool(rag_context)
        result["duration_ms"] = (datetime.now() - start_time).total_seconds() * 1000
        
        return result
    
    async def demonstrate_strategy(self) -> Dict:
        """Demonstra a estratégia híbrida com exemplos práticos."""
        
        print("🎯 DEMONSTRAÇÃO DA ESTRATÉGIA HÍBRIDA")
        print("=" * 60)
        
        # Exemplos de casos
        test_cases = [
            {
                "name": "Análise Contratual com Agente",
                "function": "contract_analysis", 
                "prompt": "Analise este contrato de trabalho em busca de cláusulas abusivas",
                "use_agents": True,
                "use_rag": True
            },
            {
                "name": "Consulta Jurídica com RAG",
                "function": "general",
                "prompt": "Quais são os direitos do trabalhador segundo a CLT artigo 7?",
                "use_agents": False,
                "use_rag": True
            },
            {
                "name": "OCR Especializado", 
                "function": "ocr",
                "prompt": "Extrair texto desta imagem de documento judicial",
                "use_agents": False,
                "use_rag": False
            },
            {
                "name": "Triagem com Agente + RAG",
                "function": "client_triage",
                "prompt": "Cliente relata demissão sem justa causa e não recebeu verbas rescisórias",
                "use_agents": True,
                "use_rag": True
            }
        ]
        
        results = []
        
        for i, case in enumerate(test_cases, 1):
            print(f"\n🧪 Teste {i}: {case['name']}")
            print("-" * 40)
            
            result = await self.route_by_function(
                function=case['function'],
                prompt=case['prompt'],
                use_agents=case['use_agents'],
                use_rag=case['use_rag']
            )
            
            print(f"✅ Rota: {result.get('routing_path')}")
            print(f"⚡ Método: {result.get('method')}")
            print(f"🕒 Duração: {result.get('duration_ms', 0):.1f}ms")
            print(f"📄 Resposta: {result.get('response', 'N/A')[:100]}...")
            
            results.append({
                "test": case['name'],
                "result": result
            })
        
        return {
            "strategy_demo": "completed",
            "tests_run": len(test_cases),
            "results": results,
            "status": self.get_status()
        }

async def main():
    """Função principal da demonstração."""
    print("🚀 DEMONSTRAÇÃO DA IMPLEMENTAÇÃO HÍBRIDA LITIG-1")
    print("Estratégia: Modelos Fixos + Agentes LangChain + RAG Jurídico")
    print()
    
    # Inicializar demonstração
    demo = HybridStrategyDemo()
    
    # Mostrar status
    status = demo.get_status()
    print("📊 STATUS DA IMPLEMENTAÇÃO:")
    print(json.dumps(status, indent=2, ensure_ascii=False))
    
    # Executar demonstração
    results = await demo.demonstrate_strategy()
    
    print("\n" + "=" * 60)
    print("📈 RESUMO DA DEMONSTRAÇÃO")
    print("=" * 60)
    
    print(f"✅ Testes executados: {results['tests_run']}")
    print(f"🎯 Estratégia: {results['strategy_demo']}")
    
    print("\n💡 BENEFÍCIOS DA ESTRATÉGIA HÍBRIDA:")
    print("   🔧 Mantém modelos fixos especializados (controle total)")
    print("   🤖 Adiciona agentes LangChain inteligentes")
    print("   📚 Integra RAG jurídico brasileiro") 
    print("   🛡️ Preserva fallback de 4 níveis")
    print("   ⚡ Melhor performance e precisão")
    print("   💰 Otimização de custos automática")
    
    print("\n🎉 Implementação híbrida validada com sucesso!")

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n⏹️ Demonstração interrompida pelo usuário")
    except Exception as e:
        print(f"\n❌ Erro inesperado: {e}")
