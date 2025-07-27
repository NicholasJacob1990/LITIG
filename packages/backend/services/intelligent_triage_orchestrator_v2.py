#!/usr/bin/env python3
"""
Intelligent Triage Orchestrator V2 - LangGraph 0.4
==================================================

Versão V2 migrada para usar LangGraph 0.4 com:
- Workflow declarativo com nodes e edges
- Checkpointing automático com MemorySaver
- Interrupts nativos para pausas inteligentes
- Estado centralizado e versionado
- Visualização automática do fluxo

Mantém 100% compatibilidade com V1 para orquestração de triagem inteligente.
"""

import asyncio
import json
import logging
import time
from typing import TypedDict, Annotated, List, Optional, Dict, Any
from dataclasses import dataclass
from datetime import datetime
import operator

# LangGraph 0.4 imports
try:
    from langgraph.graph import StateGraph, END
    from langgraph.checkpoint.memory import MemorySaver
    from langchain_core.runnables import RunnableLambda
    LANGGRAPH_AVAILABLE = True
except ImportError:
    LANGGRAPH_AVAILABLE = False
    print("⚠️ LangGraph não disponível - usando simulação")

logger = logging.getLogger(__name__)

# ===== DEFINIÇÃO DO ESTADO =====

class TriageState(TypedDict):
    """Estado centralizado do workflow de triagem inteligente."""
    
    # Identificadores
    user_id: str
    case_id: Optional[str]
    thread_id: Optional[str]
    
    # Dados de entrada
    conversation_data: Annotated[Dict[str, Any], operator.add]  # Merge automático
    user_preferences: Dict[str, Any]
    
    # Análises intermediárias
    complexity_level: str
    basic_triage_result: Dict[str, Any]
    lex_analysis: Optional[Dict[str, Any]]
    
    # Matching e enhancement
    initial_matches: List[Dict[str, Any]]
    enhanced_matches: List[Dict[str, Any]]
    match_explanations: List[str]
    
    # Estado de execução
    current_step: str
    error_context: Optional[str]
    notifications_sent: bool
    workflow_paused: bool
    
    # Métricas
    processing_start_time: float
    step_durations: Annotated[List[Dict[str, Any]], operator.add]

@dataclass
class TriageResult:
    """Resultado final da triagem V2."""
    success: bool
    case_id: Optional[str]
    triage_result: Dict[str, Any]
    lex_analysis: Optional[Dict[str, Any]]
    matches: List[Dict[str, Any]]
    explanations: List[str]
    error: Optional[str]
    processing_summary: Dict[str, Any]
    workflow_visualization: Optional[str]

class IntelligentTriageOrchestratorV2:
    """
    Orquestrador V2 para triagem inteligente usando LangGraph 0.4.
    
    Transforma a lógica imperativa do V1 em um workflow declarativo e visual,
    com estado centralizado, checkpointing automático e interrupts nativos.
    
    Mantém 100% compatibilidade com V1.
    """
    
    def __init__(self):
        self.logger = logging.getLogger(f"{self.__class__.__name__}")
        
        # Inicializar LangGraph workflow se disponível
        if LANGGRAPH_AVAILABLE:
            self.workflow = self._build_langgraph_workflow()
            self.compiled_workflow = self._compile_workflow()
            self.logger.info("✅ LangGraph 0.4 workflow inicializado")
        else:
            self.workflow = None
            self.compiled_workflow = None
            self.logger.warning("⚠️ LangGraph não disponível - usando fallback")
        
        # Serviços dependentes (simulados por enquanto)
        self.services = self._initialize_services()
    
    def _initialize_services(self) -> Dict[str, Any]:
        """Inicializa serviços dependentes (simulados)."""
        return {
            "interviewer": None,  # intelligent_interviewer_service
            "triage": None,       # triage_service
            "lex9000": None,      # lex9000_integration_service
            "matching": None,     # enhanced_match_service
            "notification": None  # notify_service
        }
    
    def _build_langgraph_workflow(self) -> StateGraph:
        """Constrói o workflow declarativo com LangGraph 0.4."""
        
        # Inicializar grafo com estado tipado
        workflow = StateGraph(TriageState)
        
        # ===== ADICIONAR TODOS OS NÓS =====
        workflow.add_node("start_conversation", self._start_conversation_node)
        workflow.add_node("collect_case_details", self._collect_case_details_node)
        workflow.add_node("detect_complexity", self._detect_complexity_node)
        workflow.add_node("basic_triage", self._basic_triage_node)
        workflow.add_node("lex9000_analysis", self._lex9000_analysis_node)
        workflow.add_node("find_initial_matches", self._find_initial_matches_node)
        workflow.add_node("enhance_matches_with_llm", self._enhance_matches_node)
        workflow.add_node("generate_explanations", self._generate_explanations_node)
        workflow.add_node("send_notifications", self._send_notifications_node)
        workflow.add_node("handle_error", self._handle_error_node)
        
        # ===== DEFINIR ENTRY POINT =====
        workflow.set_entry_point("start_conversation")
        
        # ===== EDGES LINEARES =====
        workflow.add_edge("start_conversation", "collect_case_details")
        workflow.add_edge("collect_case_details", "detect_complexity")
        workflow.add_edge("detect_complexity", "basic_triage")
        
        # ===== EDGE CONDICIONAL: Usar LEX-9000? =====
        workflow.add_conditional_edges(
            "basic_triage",
            RunnableLambda(self._should_use_lex9000),
            {
                "lex9000_analysis": "lex9000_analysis",
                "find_matches": "find_initial_matches",
                "handle_error": "handle_error"
            }
        )
        
        # LEX-9000 sempre vai para matches
        workflow.add_edge("lex9000_analysis", "find_initial_matches")
        
        # ===== EDGE CONDICIONAL: Usar LLM Enhancement? =====
        workflow.add_conditional_edges(
            "find_initial_matches",
            RunnableLambda(self._should_enhance_matches),
            {
                "enhance_matches": "enhance_matches_with_llm",
                "generate_explanations": "generate_explanations",
                "handle_error": "handle_error"
            }
        )
        
        # Enhancement vai para explicações
        workflow.add_edge("enhance_matches_with_llm", "generate_explanations")
        
        # Explicações sempre vão para notificações
        workflow.add_edge("generate_explanations", "send_notifications")
        
        # ===== FINALIZAÇÕES =====
        workflow.add_edge("send_notifications", END)
        workflow.add_edge("handle_error", END)
        
        return workflow
    
    def _compile_workflow(self) -> Any:
        """Compila o workflow com checkpointing e interrupts."""
        if not LANGGRAPH_AVAILABLE:
            return None
        
        # Configurar checkpoint para persistência de estado
        memory = MemorySaver()
        
        # Compilar com interrupts específicos
        compiled = self.workflow.compile(
            checkpointer=memory,
            interrupt_before=["lex9000_analysis"],  # Pausa antes do LEX-9000
            interrupt_after=["enhance_matches_with_llm"]  # Pausa após enhancement
        )
        
        return compiled
    
    # ===== IMPLEMENTAÇÃO DOS NÓS =====
    
    async def _start_conversation_node(self, state: TriageState) -> TriageState:
        """Nó que inicia a conversa inteligente."""
        start_time = time.time()
        self.logger.info(f"🚀 Iniciando conversa para usuário {state['user_id']}")
        
        try:
            # Simular início da conversa
            await asyncio.sleep(0.1)  # Simular latência de API
            
            case_id = f"case_{state['user_id']}_{int(time.time())}"
            first_message = {
                "message": "Olá! Sou o assistente jurídico do LITIG-1. Vou ajudá-lo a analisar seu caso.",
                "timestamp": datetime.now().isoformat(),
                "type": "greeting"
            }
            
            duration = time.time() - start_time
            
            return {
                **state,
                "case_id": case_id,
                "conversation_data": {"first_message": first_message, "started_at": start_time},
                "current_step": "conversation_started",
                "step_durations": [{"step": "start_conversation", "duration": duration, "status": "success"}]
            }
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao iniciar conversa: {e}")
            return {
                **state,
                "error_context": f"Erro ao iniciar conversa: {str(e)}",
                "current_step": "error"
            }
    
    async def _collect_case_details_node(self, state: TriageState) -> TriageState:
        """Nó que coleta detalhes do caso via conversa."""
        start_time = time.time()
        self.logger.info(f"📝 Coletando detalhes do caso {state['case_id']}")
        
        try:
            # Simular coleta de detalhes
            await asyncio.sleep(0.2)
            
            detailed_data = {
                "case_description": "Caso trabalhista de horas extras não pagas",
                "urgency_level": "medium",
                "client_type": "individual",
                "estimated_value": 15000.00,
                "documents_available": True,
                "deadline": "30 dias"
            }
            
            duration = time.time() - start_time
            
            return {
                **state,
                "conversation_data": {**state["conversation_data"], **detailed_data},
                "current_step": "details_collected",
                "step_durations": [{"step": "collect_details", "duration": duration, "status": "success"}]
            }
            
        except Exception as e:
            self.logger.error(f"❌ Erro na coleta de detalhes: {e}")
            return {
                **state,
                "error_context": f"Erro na coleta de detalhes: {str(e)}",
                "current_step": "error"
            }
    
    async def _detect_complexity_node(self, state: TriageState) -> TriageState:
        """Nó que detecta a complexidade do caso."""
        start_time = time.time()
        self.logger.info(f"🔍 Detectando complexidade do caso {state['case_id']}")
        
        try:
            # Simular detecção de complexidade
            await asyncio.sleep(0.1)
            
            # Lógica heurística baseada nos dados
            conversation = state["conversation_data"]
            estimated_value = conversation.get("estimated_value", 0)
            urgency = conversation.get("urgency_level", "low")
            
            if estimated_value > 50000 or urgency == "high":
                complexity = "complex"
            elif estimated_value > 10000 or urgency == "medium":
                complexity = "medium"
            else:
                complexity = "simple"
            
            complexity_result = {
                "level": complexity,
                "confidence": 0.85,
                "factors": [
                    f"Valor estimado: R$ {estimated_value:,.2f}",
                    f"Urgência: {urgency}",
                    "Documentação disponível" if conversation.get("documents_available") else "Sem documentação"
                ]
            }
            
            duration = time.time() - start_time
            
            return {
                **state,
                "complexity_level": complexity,
                "conversation_data": {
                    **state["conversation_data"],
                    "complexity_analysis": complexity_result
                },
                "current_step": "complexity_detected",
                "step_durations": [{"step": "detect_complexity", "duration": duration, "status": "success"}]
            }
            
        except Exception as e:
            self.logger.error(f"❌ Erro na detecção de complexidade: {e}")
            return {
                **state,
                "error_context": f"Erro na detecção de complexidade: {str(e)}",
                "current_step": "error"
            }
    
    async def _basic_triage_node(self, state: TriageState) -> TriageState:
        """Nó que executa triagem básica."""
        start_time = time.time()
        complexity = state["complexity_level"]
        self.logger.info(f"⚖️ Executando triagem básica (complexidade: {complexity})")
        
        try:
            # Simular triagem baseada na complexidade
            if complexity == "simple":
                await asyncio.sleep(0.1)
                strategy = "direct_simple"
            elif complexity == "medium":
                await asyncio.sleep(0.2)
                strategy = "standard_analysis"
            else:  # complex
                await asyncio.sleep(0.3)
                strategy = "ensemble_analysis"
            
            triage_result = {
                "strategy": strategy,
                "legal_area": "Direito Trabalhista",
                "confidence": 0.9 if complexity == "simple" else 0.7,
                "classification": {
                    "area_principal": "Trabalhista",
                    "subarea": "Horas Extras",
                    "urgencia": state["conversation_data"].get("urgency_level", "medium")
                },
                "requires_detailed_analysis": complexity == "complex"
            }
            
            duration = time.time() - start_time
            
            return {
                **state,
                "basic_triage_result": triage_result,
                "current_step": "basic_triage_completed",
                "step_durations": [{"step": "basic_triage", "duration": duration, "status": "success"}]
            }
            
        except Exception as e:
            self.logger.error(f"❌ Erro na triagem básica: {e}")
            return {
                **state,
                "error_context": f"Erro na triagem básica: {str(e)}",
                "current_step": "error"
            }
    
    async def _lex9000_analysis_node(self, state: TriageState) -> TriageState:
        """Nó que executa análise detalhada LEX-9000."""
        start_time = time.time()
        self.logger.info(f"🤖 Executando análise LEX-9000 para caso {state['case_id']}")
        
        try:
            # Simular análise LEX-9000 (que usa Grok 4)
            await asyncio.sleep(1.0)  # LEX-9000 é mais demorado
            
            lex_result = {
                "analysis_type": "detailed_legal_analysis",
                "classificacao": {
                    "area_principal": "Direito do Trabalho",
                    "assunto_principal": "Horas Extras Não Pagas",
                    "natureza": "Contencioso"
                },
                "viabilidade": {
                    "classificacao": "Viável",
                    "probabilidade_exito": "Alta",
                    "complexidade": "Média"
                },
                "aspectos_tecnicos": {
                    "legislacao_aplicavel": ["CLT Art. 59", "Súmula 85 TST"],
                    "jurisprudencia_relevante": ["TST-RR-123456"],
                    "competencia": "Vara do Trabalho"
                },
                "confidence": 0.92
            }
            
            duration = time.time() - start_time
            
            return {
                **state,
                "lex_analysis": lex_result,
                "current_step": "lex9000_completed",
                "step_durations": [{"step": "lex9000_analysis", "duration": duration, "status": "success"}]
            }
            
        except Exception as e:
            self.logger.error(f"❌ Erro no LEX-9000: {e}")
            return {
                **state,
                "error_context": f"Erro no LEX-9000: {str(e)}",
                "current_step": "error"
            }
    
    async def _find_initial_matches_node(self, state: TriageState) -> TriageState:
        """Nó que encontra matches iniciais de advogados."""
        start_time = time.time()
        self.logger.info(f"🔍 Buscando matches iniciais para caso {state['case_id']}")
        
        try:
            # Simular busca de matches
            await asyncio.sleep(0.3)
            
            matches = [
                {
                    "lawyer_id": "adv_001",
                    "name": "Dr. Ana Santos",
                    "specialization": "Direito Trabalhista",
                    "experience_years": 15,
                    "success_rate": 0.92,
                    "location": "São Paulo",
                    "base_score": 0.87
                },
                {
                    "lawyer_id": "adv_002",
                    "name": "Dr. Carlos Silva",
                    "specialization": "Direito Trabalhista",
                    "experience_years": 12,
                    "success_rate": 0.89,
                    "location": "São Paulo",
                    "base_score": 0.83
                },
                {
                    "lawyer_id": "adv_003",
                    "name": "Dra. Maria Costa",
                    "specialization": "Direito Trabalhista",
                    "experience_years": 18,
                    "success_rate": 0.94,
                    "location": "Rio de Janeiro",
                    "base_score": 0.81
                }
            ]
            
            duration = time.time() - start_time
            
            return {
                **state,
                "initial_matches": matches,
                "current_step": "initial_matches_found",
                "step_durations": [{"step": "find_matches", "duration": duration, "status": "success"}]
            }
            
        except Exception as e:
            self.logger.error(f"❌ Erro na busca de matches: {e}")
            return {
                **state,
                "error_context": f"Erro na busca de matches: {str(e)}",
                "current_step": "error"
            }
    
    async def _enhance_matches_node(self, state: TriageState) -> TriageState:
        """Nó que aprimora matches com análise LLM."""
        start_time = time.time()
        matches_count = len(state.get("initial_matches", []))
        self.logger.info(f"✨ Aprimorando {matches_count} matches com LLM")
        
        try:
            # Simular enhancement via Gemini 2.5 Pro
            await asyncio.sleep(0.8)
            
            enhanced_matches = []
            for match in state["initial_matches"]:
                enhanced = {
                    **match,
                    "llm_score": match["base_score"] * 1.1,  # Boost com LLM
                    "compatibility_factors": [
                        "Alta experiência em horas extras",
                        "Histórico de vitórias similares",
                        "Estilo de comunicação adequado"
                    ],
                    "enhancement_confidence": 0.85
                }
                enhanced_matches.append(enhanced)
            
            # Reordenar por llm_score
            enhanced_matches.sort(key=lambda x: x["llm_score"], reverse=True)
            
            duration = time.time() - start_time
            
            return {
                **state,
                "enhanced_matches": enhanced_matches,
                "current_step": "matches_enhanced",
                "step_durations": [{"step": "enhance_matches", "duration": duration, "status": "success"}]
            }
            
        except Exception as e:
            self.logger.warning(f"⚠️ Falha no enhancement LLM: {e}")
            # Fallback: usar matches originais
            return {
                **state,
                "enhanced_matches": state["initial_matches"],
                "current_step": "matches_enhancement_failed",
                "step_durations": [{"step": "enhance_matches", "duration": time.time() - start_time, "status": "fallback"}]
            }
    
    async def _generate_explanations_node(self, state: TriageState) -> TriageState:
        """Nó que gera explicações para os matches."""
        start_time = time.time()
        matches = state.get("enhanced_matches", state.get("initial_matches", []))
        self.logger.info(f"📝 Gerando explicações para top {min(len(matches), 3)} matches")
        
        try:
            # Simular geração de explicações
            await asyncio.sleep(0.4)
            
            explanations = []
            for i, match in enumerate(matches[:3]):  # Top 3
                explanation = (
                    f"{match['name']} é uma excelente opção para seu caso de horas extras. "
                    f"Com {match['experience_years']} anos de experiência em Direito Trabalhista "
                    f"e taxa de sucesso de {match['success_rate']:.0%}, "
                    f"oferece a expertise necessária para maximizar suas chances de vitória."
                )
                explanations.append(explanation)
            
            duration = time.time() - start_time
            
            return {
                **state,
                "match_explanations": explanations,
                "current_step": "explanations_generated",
                "step_durations": [{"step": "generate_explanations", "duration": duration, "status": "success"}]
            }
            
        except Exception as e:
            self.logger.warning(f"⚠️ Falha na geração de explicações: {e}")
            return {
                **state,
                "match_explanations": [],
                "current_step": "explanations_failed",
                "step_durations": [{"step": "generate_explanations", "duration": time.time() - start_time, "status": "fallback"}]
            }
    
    async def _send_notifications_node(self, state: TriageState) -> TriageState:
        """Nó que envia notificações finais."""
        start_time = time.time()
        self.logger.info(f"📧 Enviando notificações para usuário {state['user_id']}")
        
        try:
            # Simular envio de notificações
            await asyncio.sleep(0.2)
            
            # Preparar dados para notificação
            notification_data = {
                "case_id": state["case_id"],
                "triage_result": state["basic_triage_result"],
                "matches_count": len(state.get("enhanced_matches", state.get("initial_matches", []))),
                "has_lex_analysis": state.get("lex_analysis") is not None,
                "processing_summary": {
                    "total_duration": sum(step["duration"] for step in state.get("step_durations", [])),
                    "steps_completed": len(state.get("step_durations", [])),
                    "complexity_level": state["complexity_level"]
                }
            }
            
            duration = time.time() - start_time
            
            return {
                **state,
                "notifications_sent": True,
                "current_step": "completed",
                "step_durations": [{"step": "send_notifications", "duration": duration, "status": "success"}]
            }
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao enviar notificações: {e}")
            return {
                **state,
                "error_context": f"Erro ao enviar notificações: {str(e)}",
                "current_step": "notification_error"
            }
    
    async def _handle_error_node(self, state: TriageState) -> TriageState:
        """Nó que trata erros do sistema."""
        self.logger.error(f"🚨 Tratando erro: {state.get('error_context')}")
        
        try:
            # Log do erro completo
            error_details = {
                "user_id": state["user_id"],
                "case_id": state.get("case_id"),
                "error": state.get("error_context"),
                "current_step": state.get("current_step"),
                "partial_results": {
                    "complexity_level": state.get("complexity_level"),
                    "basic_triage_result": state.get("basic_triage_result", {}),
                    "matches_found": len(state.get("initial_matches", []))
                }
            }
            
            # Simular notificação de erro
            await asyncio.sleep(0.1)
            
            return {
                **state,
                "current_step": "error_handled",
                "notifications_sent": True
            }
            
        except Exception as e:
            self.logger.critical(f"💥 Erro crítico no tratamento de erro: {e}")
            return {
                **state,
                "current_step": "critical_error"
            }
    
    # ===== FUNÇÕES DE DECISÃO =====
    
    def _should_use_lex9000(self, state: TriageState) -> str:
        """Decide se deve acionar o LEX-9000."""
        if state.get("error_context"):
            return "handle_error"
        
        complexity = state.get("complexity_level", "")
        triage_result = state.get("basic_triage_result", {})
        confidence = triage_result.get("confidence", 0)
        requires_analysis = triage_result.get("requires_detailed_analysis", False)
        
        # Usar LEX-9000 se:
        # 1. Caso é complexo OU
        # 2. Confiança da triagem básica é baixa OU
        # 3. Análise detalhada é explicitamente requerida
        if complexity in ["complex", "very_complex"] or confidence < 0.8 or requires_analysis:
            return "lex9000_analysis"
        else:
            return "find_matches"
    
    def _should_enhance_matches(self, state: TriageState) -> str:
        """Decide se deve usar LLM enhancement nos matches."""
        if state.get("error_context"):
            return "handle_error"
        
        matches = state.get("initial_matches", [])
        complexity = state.get("complexity_level", "")
        estimated_value = state.get("conversation_data", {}).get("estimated_value", 0)
        
        # Usar enhancement se:
        # 1. Há muitos matches (> 3) OU
        # 2. Caso é de média/alta complexidade OU
        # 3. Valor estimado é alto (> R$ 20.000)
        if len(matches) > 3 or complexity in ["medium", "complex", "very_complex"] or estimated_value > 20000:
            return "enhance_matches"
        else:
            return "generate_explanations"
    
    # ===== INTERFACE PÚBLICA =====
    
    async def start_intelligent_triage(
        self, 
        user_id: str,
        user_preferences: Optional[Dict[str, Any]] = None
    ) -> TriageResult:
        """
        Ponto de entrada público - executa o workflow completo.
        
        Args:
            user_id: ID do usuário
            user_preferences: Preferências opcionais do usuário
        
        Returns:
            TriageResult com resultado completo
        """
        
        start_time = time.time()
        thread_id = f"triage_{user_id}_{int(start_time)}"
        
        # Estado inicial
        initial_state = TriageState(
            user_id=user_id,
            case_id=None,
            thread_id=thread_id,
            conversation_data={},
            user_preferences=user_preferences or {},
            complexity_level="",
            basic_triage_result={},
            lex_analysis=None,
            initial_matches=[],
            enhanced_matches=[],
            match_explanations=[],
            current_step="starting",
            error_context=None,
            notifications_sent=False,
            workflow_paused=False,
            processing_start_time=start_time,
            step_durations=[]
        )
        
        try:
            if LANGGRAPH_AVAILABLE and self.compiled_workflow:
                # Executar via LangGraph 0.4
                config = {"configurable": {"thread_id": thread_id}}
                final_state = await self.compiled_workflow.ainvoke(initial_state, config)
                
                # Gerar visualização do workflow
                visualization = self._generate_workflow_visualization()
            else:
                # Fallback para execução simulada
                final_state = await self._simulate_workflow_execution(initial_state)
                visualization = "Visualização não disponível (LangGraph não instalado)"
            
            # Construir resultado final
            result = TriageResult(
                success=final_state.get("error_context") is None,
                case_id=final_state.get("case_id"),
                triage_result=final_state.get("basic_triage_result", {}),
                lex_analysis=final_state.get("lex_analysis"),
                matches=final_state.get("enhanced_matches", final_state.get("initial_matches", [])),
                explanations=final_state.get("match_explanations", []),
                error=final_state.get("error_context"),
                processing_summary={
                    "total_duration": sum(step["duration"] for step in final_state.get("step_durations", [])),
                    "steps_completed": [step["step"] for step in final_state.get("step_durations", [])],
                    "complexity_level": final_state.get("complexity_level", "unknown"),
                    "lex_analysis_used": final_state.get("lex_analysis") is not None,
                    "llm_enhancement_used": "enhanced_matches" in final_state
                },
                workflow_visualization=visualization
            )
            
            total_time = time.time() - start_time
            self.logger.info(
                f"✅ Triagem inteligente concluída em {total_time:.2f}s "
                f"para usuário {user_id} (caso: {result.case_id})"
            )
            
            return result
            
        except Exception as e:
            total_time = time.time() - start_time
            self.logger.error(f"❌ Erro na triagem inteligente ({total_time:.2f}s): {e}")
            
            return TriageResult(
                success=False,
                case_id=None,
                triage_result={},
                lex_analysis=None,
                matches=[],
                explanations=[],
                error=str(e),
                processing_summary={
                    "total_duration": total_time,
                    "steps_completed": [],
                    "complexity_level": "error",
                    "lex_analysis_used": False,
                    "llm_enhancement_used": False
                },
                workflow_visualization=None
            )
    
    async def _simulate_workflow_execution(self, state: TriageState) -> TriageState:
        """Simula execução do workflow quando LangGraph não está disponível."""
        self.logger.info("🔄 Executando workflow simulado (LangGraph não disponível)")
        
        # Executar nós sequencialmente
        current_state = state
        
        try:
            current_state = await self._start_conversation_node(current_state)
            current_state = await self._collect_case_details_node(current_state)
            current_state = await self._detect_complexity_node(current_state)
            current_state = await self._basic_triage_node(current_state)
            
            # Decisão sobre LEX-9000
            decision = self._should_use_lex9000(current_state)
            if decision == "lex9000_analysis":
                current_state = await self._lex9000_analysis_node(current_state)
            
            current_state = await self._find_initial_matches_node(current_state)
            
            # Decisão sobre enhancement
            decision = self._should_enhance_matches(current_state)
            if decision == "enhance_matches":
                current_state = await self._enhance_matches_node(current_state)
            
            current_state = await self._generate_explanations_node(current_state)
            current_state = await self._send_notifications_node(current_state)
            
        except Exception as e:
            current_state = await self._handle_error_node({
                **current_state,
                "error_context": str(e)
            })
        
        return current_state
    
    def _generate_workflow_visualization(self) -> str:
        """Gera visualização Mermaid do workflow."""
        if not LANGGRAPH_AVAILABLE or not self.workflow:
            return "Visualização indisponível"
        
        try:
            # LangGraph pode gerar diagramas automaticamente
            return self.workflow.get_graph().draw_mermaid()
        except Exception:
            # Fallback para visualização manual
            return """
graph TD
    A[start_conversation] --> B[collect_case_details]
    B --> C[detect_complexity]
    C --> D[basic_triage]
    D --> E{should_use_lex9000}
    E -->|yes| F[lex9000_analysis]
    E -->|no| G[find_initial_matches]
    F --> G
    G --> H{should_enhance_matches}
    H -->|yes| I[enhance_matches_with_llm]
    H -->|no| J[generate_explanations]
    I --> J
    J --> K[send_notifications]
    K --> L[END]
    E -->|error| M[handle_error]
    H -->|error| M
    M --> L
"""
    
    def get_service_status(self) -> Dict[str, Any]:
        """Retorna status do serviço V2."""
        return {
            "version": "2.0",
            "architecture": "LangGraph 0.4",
            "langgraph_available": LANGGRAPH_AVAILABLE,
            "workflow_compiled": self.compiled_workflow is not None,
            "supported_features": [
                "Declarative workflow",
                "Automatic checkpointing",
                "Native interrupts",
                "Visual workflow representation",
                "Centralized state management",
                "Error recovery",
                "Performance metrics"
            ],
            "workflow_nodes": [
                "start_conversation", "collect_case_details", "detect_complexity",
                "basic_triage", "lex9000_analysis", "find_initial_matches",
                "enhance_matches_with_llm", "generate_explanations", 
                "send_notifications", "handle_error"
            ],
            "interrupt_points": ["lex9000_analysis", "enhance_matches_with_llm"],
            "compatible_with_v1": True
        }


# Factory function para compatibilidade
def get_intelligent_triage_orchestrator_v2() -> IntelligentTriageOrchestratorV2:
    """Factory function para criar instância V2 do orquestrador."""
    return IntelligentTriageOrchestratorV2()


if __name__ == "__main__":
    # Teste básico de funcionalidade
    async def test_v2_orchestrator():
        orchestrator = get_intelligent_triage_orchestrator_v2()
        
        print("🎭 Testando Intelligent Triage Orchestrator V2")
        print("=" * 50)
        
        # Status do serviço
        status = orchestrator.get_service_status()
        print("📊 Status do Serviço V2:")
        for key, value in status.items():
            print(f"   {key}: {value}")
        
        # Teste com caso de exemplo
        try:
            print(f"\n🚀 Executando triagem inteligente...")
            result = await orchestrator.start_intelligent_triage(
                user_id="test_user_123",
                user_preferences={"language": "pt-BR", "location": "São Paulo"}
            )
            
            print(f"\n✅ Triagem concluída!")
            print(f"   🎯 Sucesso: {result.success}")
            print(f"   📋 Caso ID: {result.case_id}")
            print(f"   ⚖️ Área Jurídica: {result.triage_result.get('legal_area', 'N/A')}")
            print(f"   🤖 LEX-9000 usado: {result.processing_summary['lex_analysis_used']}")
            print(f"   ✨ LLM Enhancement: {result.processing_summary['llm_enhancement_used']}")
            print(f"   👥 Matches encontrados: {len(result.matches)}")
            print(f"   📝 Explicações: {len(result.explanations)}")
            print(f"   ⏱️ Tempo total: {result.processing_summary['total_duration']:.2f}s")
            print(f"   📈 Etapas: {', '.join(result.processing_summary['steps_completed'])}")
            
            if result.workflow_visualization:
                print(f"\n🔍 Visualização do Workflow:")
                print(result.workflow_visualization[:500] + "..." if len(result.workflow_visualization) > 500 else result.workflow_visualization)
            
        except Exception as e:
            print(f"\n❌ Erro no teste: {e}")
    
    # Executar teste
    asyncio.run(test_v2_orchestrator()) 
 