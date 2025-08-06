#!/usr/bin/env python3
"""
Hybrid Integration Example - Exemplo de Integração Híbrida
==========================================================

Demonstra como integrar agentes LangChain aos workflows LangGraph existentes.
Mantém 100% compatibilidade com intelligent_triage_orchestrator_v2.py.

Mostra a estratégia híbrida em ação:
✅ WORKFLOWS EXISTENTES: Preserva LangGraph V2 
✅ AGENTES AVANÇADOS: Adiciona LangChain nos nós
✅ RAG JURÍDICO: Integra base de conhecimento brasileira
✅ FALLBACK PRESERVADO: Mantém OpenRouter de 4 níveis
"""

import asyncio
import logging
import time
from typing import Dict, Any, Optional
from datetime import datetime

# Importações dos serviços existentes
try:
    from intelligent_triage_orchestrator_v2 import IntelligentTriageOrchestratorV2, TriageState
    TRIAGE_V2_AVAILABLE = True
except ImportError:
    TRIAGE_V2_AVAILABLE = False

# Importações dos novos serviços híbridos
try:
    from hybrid_langchain_orchestrator import get_hybrid_orchestrator
    HYBRID_ORCHESTRATOR_AVAILABLE = True
except ImportError:
    HYBRID_ORCHESTRATOR_AVAILABLE = False

try:
    from brazilian_legal_rag import get_brazilian_legal_rag
    BRAZILIAN_RAG_AVAILABLE = True
except ImportError:
    BRAZILIAN_RAG_AVAILABLE = False

logger = logging.getLogger(__name__)

class HybridTriageOrchestrator:
    """
    Orquestrador Híbrido que combina:
    - LangGraph workflows (existentes)
    - LangChain agents (novos)
    - RAG jurídico brasileiro (novo)
    - Fallback OpenRouter (preservado)
    
    Mantém interface idêntica ao V2 para compatibilidade total.
    """
    
    def __init__(self):
        self.logger = logging.getLogger(f"{self.__class__.__name__}")
        
        # Verificar disponibilidade de componentes
        self._check_availability()
        
        # Inicializar orquestrador V2 existente
        if TRIAGE_V2_AVAILABLE:
            self.v2_orchestrator = IntelligentTriageOrchestratorV2()
            self.logger.info("✅ Orquestrador V2 inicializado (LangGraph workflows)")
        else:
            self.v2_orchestrator = None
            self.logger.warning("⚠️ Orquestrador V2 não disponível")
        
        # Inicializar orquestrador híbrido (LangChain agents)
        if HYBRID_ORCHESTRATOR_AVAILABLE:
            self.hybrid_orchestrator = get_hybrid_orchestrator()
            self.logger.info("✅ Orquestrador Híbrido inicializado (LangChain agents)")
        else:
            self.hybrid_orchestrator = None
            self.logger.warning("⚠️ Orquestrador Híbrido não disponível")
        
        # Inicializar RAG jurídico brasileiro
        if BRAZILIAN_RAG_AVAILABLE:
            self.brazilian_rag = get_brazilian_legal_rag()
            self.logger.info("✅ RAG Jurídico Brasileiro inicializado")
        else:
            self.brazilian_rag = None
            self.logger.warning("⚠️ RAG Jurídico não disponível")
        
        self.logger.info("🚀 Hybrid Triage Orchestrator inicializado")
    
    def _check_availability(self):
        """Verifica disponibilidade de componentes."""
        components = {
            "LangGraph V2": TRIAGE_V2_AVAILABLE,
            "Hybrid Orchestrator": HYBRID_ORCHESTRATOR_AVAILABLE,
            "Brazilian RAG": BRAZILIAN_RAG_AVAILABLE
        }
        
        available = [name for name, status in components.items() if status]
        unavailable = [name for name, status in components.items() if not status]
        
        self.logger.info(f"✅ Componentes disponíveis: {', '.join(available)}")
        if unavailable:
            self.logger.warning(f"⚠️ Componentes indisponíveis: {', '.join(unavailable)}")
    
    async def execute_triage_with_hybrid_enhancement(
        self, 
        user_id: str,
        conversation_data: Dict[str, Any],
        user_preferences: Optional[Dict[str, Any]] = None,
        use_agents: bool = True,
        use_rag: bool = True
    ) -> Dict[str, Any]:
        """
        Executa triagem com melhorias híbridas.
        
        Args:
            user_id: ID do usuário
            conversation_data: Dados da conversa
            user_preferences: Preferências do usuário
            use_agents: Se deve usar agentes LangChain
            use_rag: Se deve usar RAG jurídico
        
        Returns:
            Resultado da triagem com melhorias híbridas
        """
        start_time = time.time()
        
        try:
            # ✅ ETAPA 1: Executar workflow LangGraph V2 (base existente)
            base_result = None
            if self.v2_orchestrator:
                self.logger.info("🔄 Executando workflow LangGraph V2...")
                base_result = await self._execute_v2_workflow(
                    user_id, conversation_data, user_preferences
                )
            
            # ✅ ETAPA 2: Enriquecer com agentes LangChain (se disponível)
            agent_enhancements = {}
            if use_agents and self.hybrid_orchestrator and base_result:
                self.logger.info("🤖 Aplicando melhorias com agentes LangChain...")
                agent_enhancements = await self._apply_agent_enhancements(base_result)
            
            # ✅ ETAPA 3: Adicionar insights RAG jurídico (se disponível)
            rag_insights = {}
            if use_rag and self.brazilian_rag and base_result:
                self.logger.info("📚 Consultando base jurídica brasileira...")
                rag_insights = await self._get_rag_insights(base_result)
            
            # ✅ ETAPA 4: Combinar resultados
            final_result = self._combine_results(
                base_result, agent_enhancements, rag_insights
            )
            
            duration = time.time() - start_time
            final_result["total_duration"] = duration
            final_result["hybrid_processing"] = {
                "v2_workflow": base_result is not None,
                "agent_enhancements": bool(agent_enhancements),
                "rag_insights": bool(rag_insights),
                "processing_time": duration
            }
            
            self.logger.info(f"✅ Triagem híbrida concluída em {duration:.2f}s")
            return final_result
            
        except Exception as e:
            self.logger.error(f"❌ Erro na triagem híbrida: {e}")
            return {
                "success": False,
                "error": str(e),
                "fallback_used": True,
                "duration": time.time() - start_time
            }
    
    async def _execute_v2_workflow(
        self, 
        user_id: str, 
        conversation_data: Dict[str, Any],
        user_preferences: Optional[Dict[str, Any]]
    ) -> Optional[Dict[str, Any]]:
        """Executa workflow LangGraph V2 existente."""
        if not self.v2_orchestrator:
            return None
        
        try:
            # Usar interface pública do V2 (se disponível)
            if hasattr(self.v2_orchestrator, 'execute_triage'):
                result = await self.v2_orchestrator.execute_triage(
                    user_id=user_id,
                    conversation_data=conversation_data,
                    user_preferences=user_preferences or {}
                )
                return result
            else:
                # Simulação se método não existir
                self.logger.warning("⚠️ Método execute_triage não encontrado - simulando")
                return {
                    "success": True,
                    "case_id": f"case_{user_id}_{int(time.time())}",
                    "triage_result": {
                        "complexity": "medium",
                        "legal_area": "Direito Trabalhista",
                        "confidence": 0.8
                    },
                    "method": "v2_simulation"
                }
                
        except Exception as e:
            self.logger.error(f"❌ Erro no workflow V2: {e}")
            return None
    
    async def _apply_agent_enhancements(self, base_result: Dict[str, Any]) -> Dict[str, Any]:
        """Aplica melhorias usando agentes LangChain."""
        enhancements = {}
        
        try:
            # Extrair informações do resultado base
            case_description = self._extract_case_description(base_result)
            legal_area = base_result.get("triage_result", {}).get("legal_area", "")
            
            # ✅ Agente de Análise de Casos
            if case_description:
                case_analysis = await self.hybrid_orchestrator.process_with_agent(
                    agent_type="case_analyzer",
                    user_input=f"Analisar caso: {case_description}",
                    context={"legal_area": legal_area}
                )
                if case_analysis.get("success"):
                    enhancements["detailed_case_analysis"] = case_analysis.get("result")
            
            # ✅ Agente de Pesquisa Jurídica
            if legal_area:
                legal_research = await self.hybrid_orchestrator.process_with_agent(
                    agent_type="legal_researcher",
                    user_input=f"Pesquisar legislação e jurisprudência para {legal_area}",
                    context={"case_context": case_description}
                )
                if legal_research.get("success"):
                    enhancements["legal_research"] = legal_research.get("result")
            
            # ✅ Agente de Perfis (se há dados de advogado)
            lawyer_data = base_result.get("lawyer_match")
            if lawyer_data:
                profile_analysis = await self.hybrid_orchestrator.process_with_agent(
                    agent_type="profile_analyzer",
                    user_input=f"Analisar compatibilidade advogado-caso",
                    context={
                        "case": case_description,
                        "lawyer": lawyer_data,
                        "legal_area": legal_area
                    }
                )
                if profile_analysis.get("success"):
                    enhancements["lawyer_compatibility"] = profile_analysis.get("result")
            
            self.logger.info(f"✅ {len(enhancements)} melhorias de agentes aplicadas")
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao aplicar melhorias de agentes: {e}")
        
        return enhancements
    
    async def _get_rag_insights(self, base_result: Dict[str, Any]) -> Dict[str, Any]:
        """Obtém insights da base jurídica brasileira."""
        insights = {}
        
        try:
            # Preparar consultas baseadas no resultado base
            legal_area = base_result.get("triage_result", {}).get("legal_area", "")
            case_description = self._extract_case_description(base_result)
            
            queries = []
            
            # Consulta sobre legislação aplicável
            if legal_area:
                queries.append({
                    "type": "legislation",
                    "query": f"Qual legislação se aplica a casos de {legal_area}?"
                })
            
            # Consulta sobre precedentes
            if case_description:
                queries.append({
                    "type": "precedents",
                    "query": f"Precedentes jurisprudenciais sobre {case_description[:200]}"
                })
            
            # Consulta sobre prazos
            if legal_area:
                queries.append({
                    "type": "deadlines",
                    "query": f"Prazos processuais para {legal_area}"
                })
            
            # Executar consultas RAG
            for query_info in queries:
                try:
                    rag_result = await self.brazilian_rag.query(
                        question=query_info["query"],
                        include_sources=True
                    )
                    
                    if rag_result.get("success"):
                        insights[query_info["type"]] = {
                            "answer": rag_result.get("answer"),
                            "sources": rag_result.get("sources", []),
                            "query": query_info["query"]
                        }
                        
                except Exception as query_error:
                    self.logger.warning(f"⚠️ Erro na consulta RAG {query_info['type']}: {query_error}")
            
            self.logger.info(f"✅ {len(insights)} insights RAG obtidos")
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao obter insights RAG: {e}")
        
        return insights
    
    def _extract_case_description(self, result: Dict[str, Any]) -> str:
        """Extrai descrição do caso do resultado."""
        # Tentar diferentes caminhos para encontrar descrição do caso
        paths = [
            ["conversation_data", "case_description"],
            ["triage_result", "description"],
            ["case_details", "description"],
            ["input", "description"]
        ]
        
        for path in paths:
            current = result
            try:
                for key in path:
                    current = current[key]
                if current and isinstance(current, str):
                    return current
            except (KeyError, TypeError):
                continue
        
        # Fallback: usar informações disponíveis
        triage_result = result.get("triage_result", {})
        legal_area = triage_result.get("legal_area", "")
        complexity = triage_result.get("complexity", "")
        
        if legal_area or complexity:
            return f"Caso de {legal_area} com complexidade {complexity}"
        
        return "Caso jurídico não especificado"
    
    def _combine_results(
        self, 
        base_result: Optional[Dict[str, Any]], 
        agent_enhancements: Dict[str, Any],
        rag_insights: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Combina resultados de todas as fontes."""
        # Começar com resultado base ou estrutura padrão
        if base_result:
            combined = base_result.copy()
        else:
            combined = {
                "success": False,
                "error": "Workflow base não executado",
                "fallback_result": True
            }
        
        # Adicionar melhorias dos agentes
        if agent_enhancements:
            combined["agent_enhancements"] = agent_enhancements
            combined["enhanced"] = True
        
        # Adicionar insights RAG
        if rag_insights:
            combined["legal_insights"] = rag_insights
            combined["rag_enhanced"] = True
        
        # Adicionar metadados da execução híbrida
        combined["hybrid_metadata"] = {
            "timestamp": datetime.now().isoformat(),
            "components_used": {
                "langraph_v2": base_result is not None,
                "langchain_agents": bool(agent_enhancements),
                "brazilian_rag": bool(rag_insights)
            },
            "enhancement_level": self._calculate_enhancement_level(
                base_result, agent_enhancements, rag_insights
            )
        }
        
        return combined
    
    def _calculate_enhancement_level(
        self, 
        base_result: Optional[Dict[str, Any]], 
        agent_enhancements: Dict[str, Any],
        rag_insights: Dict[str, Any]
    ) -> str:
        """Calcula nível de melhoria aplicado."""
        if not base_result:
            return "fallback_only"
        elif agent_enhancements and rag_insights:
            return "full_hybrid"
        elif agent_enhancements:
            return "agent_enhanced"
        elif rag_insights:
            return "rag_enhanced"
        else:
            return "base_only"
    
    # ===== MÉTODOS DE COMPATIBILIDADE COM V2 =====
    
    async def execute_triage(self, **kwargs) -> Dict[str, Any]:
        """Interface compatível com V2."""
        return await self.execute_triage_with_hybrid_enhancement(**kwargs)
    
    def get_status(self) -> Dict[str, Any]:
        """Status do orquestrador híbrido."""
        status = {
            "hybrid_orchestrator": "active",
            "components": {}
        }
        
        if self.v2_orchestrator:
            status["components"]["langraph_v2"] = "available"
        
        if self.hybrid_orchestrator:
            status["components"]["langchain_agents"] = "available"
            status["components"].update(self.hybrid_orchestrator.get_status())
        
        if self.brazilian_rag:
            status["components"]["brazilian_rag"] = "available"
            status["components"].update(self.brazilian_rag.get_stats())
        
        return status


# ===== EXEMPLO DE USO =====

async def example_usage():
    """Exemplo de como usar o orquestrador híbrido."""
    print("🚀 Iniciando exemplo de orquestrador híbrido...")
    
    # Inicializar orquestrador
    orchestrator = HybridTriageOrchestrator()
    
    # Dados de exemplo
    user_id = "user_123"
    conversation_data = {
        "case_description": "Funcionário não recebeu horas extras trabalhadas nos últimos 2 anos",
        "urgency_level": "medium",
        "estimated_value": 15000.00,
        "client_type": "individual"
    }
    
    user_preferences = {
        "preferred_lawyer_location": "São Paulo",
        "budget_range": "medium"
    }
    
    # Executar triagem híbrida
    print("📋 Executando triagem híbrida...")
    result = await orchestrator.execute_triage_with_hybrid_enhancement(
        user_id=user_id,
        conversation_data=conversation_data,
        user_preferences=user_preferences,
        use_agents=True,
        use_rag=True
    )
    
    # Exibir resultado
    print("\n✅ Resultado da triagem híbrida:")
    print(f"Sucesso: {result.get('success')}")
    print(f"Nível de melhoria: {result.get('hybrid_metadata', {}).get('enhancement_level')}")
    
    if result.get("agent_enhancements"):
        print("\n🤖 Melhorias dos agentes:")
        for key, value in result["agent_enhancements"].items():
            print(f"  - {key}: {str(value)[:100]}...")
    
    if result.get("legal_insights"):
        print("\n📚 Insights jurídicos:")
        for key, value in result["legal_insights"].items():
            print(f"  - {key}: {value.get('answer', '')[:100]}...")
    
    print(f"\n⏱️ Tempo total: {result.get('total_duration', 0):.2f}s")
    
    # Status do sistema
    print("\n📊 Status do sistema:")
    status = orchestrator.get_status()
    for component, info in status.get("components", {}).items():
        print(f"  - {component}: {info}")


if __name__ == "__main__":
    asyncio.run(example_usage())
