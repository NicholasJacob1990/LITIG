# backend/services/intelligent_triage_orchestrator.py
import asyncio
import json
import time
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Dict, Optional

from .intelligent_interviewer_service import intelligent_interviewer_service
from .triage_service import triage_service
from .lex9000_integration_service import lex9000_integration_service
from .conversation_state_manager import conversation_state_manager
from .redis_service import redis_service
from .notify_service import send_notification_to_client
from .match_service import find_and_notify_matches
from ..models import MatchRequest
from ..models.triage_result import TriageResult, OrchestrationResult
from ..models.strategy import Strategy
from ..core.embedding_utils import generate_embedding
from ..utils.case_type_mapper import map_area_to_case_type


@dataclass
class OrchestrationResult:
    """Resultado final da orquestração inteligente."""
    case_id: str
    strategy_used: Strategy
    complexity_level: ComplexityLevel
    confidence_score: float
    triage_data: Dict[str, Any]
    conversation_summary: str
    processing_time_ms: int
    flow_type: str  # "direct_simple" | "standard_analysis" | "ensemble_analysis"
    analysis_details: Optional[Dict] = None


class IntelligentTriageOrchestrator:
    """
    Orquestrador que integra a nova arquitetura conversacional inteligente
    com as estratégias existentes de triagem.

    MIGRADO PARA REDIS - Sprint 1 Implementado

    Fluxo Inteligente:
    1. IA "Entrevistadora" conduz conversa e detecta complexidade
    2. Para casos SIMPLES: Resultado direto da Entrevistadora
    3. Para casos MÉDIOS: Estratégia "failover" com dados otimizados
    4. Para casos COMPLEXOS: Estratégia "ensemble" com análise completa
    """

    def __init__(self):
        self.interviewer = intelligent_interviewer_service
        self.triage_service = triage_service
        # REMOVIDO: self.active_orchestrations - agora usa Redis
        self.state_manager = conversation_state_manager

    def _get_channel_name(self, case_id: str) -> str:
        """Retorna o nome do canal Redis para um caso."""
        return f"triage_events:{case_id}"

    async def _publish_event(self, case_id: str, event_type: str, data: Dict[str, Any]):
        """Publica um evento no canal Redis para o caso."""
        channel = self._get_channel_name(case_id)
        event_data = {
            "event": event_type,
            "data": data,
            "timestamp": datetime.now().isoformat()
        }
        await redis_service.publish(channel, event_data)

    async def stream_events(self, case_id: str):
        """Gera eventos de triagem para um caso específico."""
        channel = self._get_channel_name(case_id)

        # Primeiro, envia o estado atual como um evento inicial
        initial_status = await self.get_orchestration_status(case_id)
        if initial_status:
            yield {
                "event": "initial_state",
                "data": json.dumps(initial_status)
            }

        # Agora, escuta por novos eventos
        async for event in redis_service.subscribe(channel):
            yield {
                "event": event.get("event", "message"),
                "data": json.dumps(event.get("data"))
            }

    async def start_intelligent_triage(self, user_id: str) -> Dict[str, Any]:
        """
        Inicia o processo de triagem inteligente - MIGRADO PARA REDIS.

        Returns:
            Dict com case_id e primeira mensagem
        """
        case_id, first_message = await self.interviewer.start_conversation(user_id)

        # Estado inicial da orquestração
        orchestration_state = {
            "user_id": user_id,
            "started_at": time.time(),
            "status": "interviewing",
            "flow_type": "unknown",
            "created_at": datetime.now().isoformat()
        }

        # Salvar no Redis
        await self.state_manager.save_orchestration_state(case_id, orchestration_state)

        await self._publish_event(
            case_id,
            "triage_started",
            {"user_id": user_id, "status": "interviewing"}
        )

        return {
            "case_id": case_id,
            "message": first_message,
            "status": "interviewing",
        }

    async def continue_intelligent_triage(
            self, case_id: str, user_message: str) -> Dict[str, Any]:
        """
        Continua o processo de triagem inteligente - MIGRADO PARA REDIS.

        Returns:
            Dict com resposta e status da conversa
        """
        # Recuperar estado do Redis
        orchestration = await self.state_manager.get_orchestration_state(case_id)
        if not orchestration:
            raise ValueError(f"Orquestração {case_id} não encontrada")

        try:
            # Continuar conversa com a IA Entrevistadora
            ai_response, is_complete = await self.interviewer.continue_conversation(
                case_id, user_message
            )

            if is_complete:
                # Conversa finalizada - processar resultado
                result = await self._process_completed_conversation(case_id)
                orchestration["status"] = "completed"
                orchestration["result"] = result
                orchestration["completed_at"] = datetime.now().isoformat()

                # Salvar estado final
                await self.state_manager.save_orchestration_state(case_id, orchestration)

                await self._publish_event(case_id, "triage_completed", {"result_id": case_id})

                # Notificar cliente sobre matches disponíveis
                try:
                    user_id = orchestration.get("user_id")
                    if user_id and result:
                        from .notify_service import send_notification_to_client
                        await send_notification_to_client(
                            client_id=user_id,
                            notification_type="caseUpdate",
                            payload={
                                "title": "Advogados Encontrados!",
                                "body": "Encontramos advogados recomendados para seu caso. Toque para ver.",
                                "data": {
                                    "case_id": case_id,
                                    "action": "view_matches",
                                    "screen": f"/advogados?case_highlight={case_id}"
                                }
                            }
                        )
                except Exception as e:
                    print(f"Erro ao enviar notificação para cliente: {e}")

                return {
                    "case_id": case_id,
                    "message": ai_response,
                    "status": "completed",
                    "result": result
                }
            else:
                # Conversa ainda em andamento
                # Obter status atual para monitoramento
                status = await self.interviewer.get_conversation_status(case_id)

                if status:
                    orchestration["current_complexity"] = status.get("complexity_level")
                    orchestration["current_confidence"] = status.get("confidence_score")

                # Atualizar estado no Redis
                orchestration["updated_at"] = datetime.now().isoformat()
                await self.state_manager.save_orchestration_state(case_id, orchestration)

                await self._publish_event(case_id, "message_received", {"message": user_message})

                return {
                    "case_id": case_id,
                    "message": ai_response,
                    "status": "active",
                    "complexity_hint": status.get("complexity_level") if status else None,
                    "confidence": status.get("confidence_score") if status else None
                }

        except Exception as e:
            orchestration["status"] = "error"
            orchestration["error"] = str(e)
            orchestration["error_at"] = datetime.now().isoformat()

            # Salvar estado de erro
            await self.state_manager.save_orchestration_state(case_id, orchestration)
            raise

    async def _process_completed_conversation(
            self, case_id: str) -> OrchestrationResult:
        """
        Processa uma conversa completa e aplica a estratégia apropriada.
        """
        start_time = time.time()

        # Obter resultado da IA Entrevistadora
        interviewer_result = await self.interviewer.get_triage_result(case_id)
        if not interviewer_result:
            raise ValueError(f"Resultado da entrevista não encontrado para {case_id}")

        # Obter estado da orquestração
        orchestration = await self.state_manager.get_orchestration_state(case_id)
        if not orchestration:
            raise ValueError(f"Estado da orquestração não encontrado para {case_id}")

        strategy = interviewer_result.strategy_used
        complexity = interviewer_result.complexity_level

        # Aplicar estratégia baseada na avaliação da IA Entrevistadora
        if strategy == "simple":
            # Fluxo direto: usar resultado da própria Entrevistadora
            result = await self._process_simple_flow(interviewer_result)
            orchestration["flow_type"] = "direct_simple"

        elif strategy == "failover":
            # Fluxo padrão: usar dados otimizados para análise failover
            result = await self._process_failover_flow(interviewer_result)
            orchestration["flow_type"] = "standard_analysis"

        elif strategy == "ensemble":
            # Fluxo complexo: análise ensemble completa
            result = await self._process_ensemble_flow(interviewer_result)
            orchestration["flow_type"] = "ensemble_analysis"

        else:
            # Fallback para failover
            result = await self._process_failover_flow(interviewer_result)
            orchestration["flow_type"] = "fallback_analysis"

        # DISPARAR MATCHING AUTOMÁTICO EM SEGUNDO PLANO
        try:
            print(f"Disparando matching automático para o caso {case_id}...")
            match_req = MatchRequest(
                case_id=interviewer_result.case_id,
                k=5,  # Usar um valor padrão ou obter de config
                preset="balanced", # Usar um preset padrão
            )
            # Executar como uma tarefa de fundo para não bloquear a resposta
            asyncio.create_task(find_and_notify_matches(match_req))
            print(f"Tarefa de matching para o caso {case_id} agendada.")
        except Exception as e:
            print(f"Erro ao disparar matching automático para o caso {case_id}: {e}")

        # Calcular tempo de processamento
        processing_time = int((time.time() - start_time) * 1000)
        result.processing_time_ms = processing_time

        # Atualizar estado da orquestração
        orchestration["processing_time_ms"] = processing_time
        await self.state_manager.save_orchestration_state(case_id, orchestration)

        # Limpar conversa da memória
        self.interviewer.cleanup_conversation(case_id)

        return result

    async def _process_simple_flow(
            self, interviewer_result: TriageResult) -> OrchestrationResult:
        """
        Processa casos simples diretamente com o resultado da IA Entrevistadora + melhorias LEX-9000.
        """
        # A IA Entrevistadora já processou tudo para casos simples
        triage_data = interviewer_result.triage_data

        # NOVO: Melhorar casos simples com LEX-9000 se disponível
        if lex9000_integration_service.is_available():
            print("Aplicando melhorias LEX-9000 para caso simples...")
            try:
                enhanced_data = await lex9000_integration_service.enhance_simple_case(triage_data)
                if enhanced_data:
                    triage_data = enhanced_data
            except Exception as e:
                print(f"Erro ao aplicar melhorias LEX-9000: {e}")

        # NOVO: Adicionar case_type baseado na área jurídica
        area = triage_data.get("area")
        subarea = triage_data.get("subarea")
        keywords = triage_data.get("keywords", [])
        summary = triage_data.get("summary")
        nature = triage_data.get("nature")  # Pode vir do LEX-9000
        
        case_type = map_area_to_case_type(
            area=area,
            subarea=subarea,
            keywords=keywords,
            summary=summary,
            nature=nature
        )
        triage_data["case_type"] = case_type
        
        # Gerar embedding do resumo se disponível
        if "summary" in triage_data:
            embedding = await generate_embedding(triage_data["summary"])
            triage_data["summary_embedding"] = embedding

        return OrchestrationResult(
            case_id=interviewer_result.case_id,
            strategy_used=interviewer_result.strategy_used,
            complexity_level=interviewer_result.complexity_level,
            confidence_score=interviewer_result.confidence_score,
            triage_data=triage_data,
            conversation_summary=interviewer_result.conversation_summary,
            processing_time_ms=0,  # Será definido pelo orquestrador
            flow_type="direct_simple",
            analysis_details={
                "source": "intelligent_interviewer",
                "analysis_type": "direct_simple_with_lex9000_enhancement",
                "optimization": "Caso simples processado diretamente pela IA Entrevistadora com melhorias LEX-9000",
                "lex9000_enhanced": lex9000_integration_service.is_available()
            }
        )

    async def _process_failover_flow(
            self, interviewer_result: TriageResult) -> OrchestrationResult:
        """
        Processa casos de complexidade média usando a estratégia failover
        com dados otimizados pela IA Entrevistadora.
        """
        # Extrair dados básicos da conversa
        conversation_data = interviewer_result.triage_data

        # Preparar texto otimizado para análise
        if "basic_info" in conversation_data:
            # Dados estruturados de caso complexo
            basic_info = conversation_data["basic_info"]
            optimized_text = f"""
            Área: {basic_info.get('area', 'Não identificado')}
            Subárea: {basic_info.get('subarea', 'Geral')}
            Resumo: {basic_info.get('summary', 'Sem resumo')}
            Urgência: {basic_info.get('urgency_h', 72)} horas

            Fatores de complexidade: {', '.join(conversation_data.get('complexity_factors', []))}
            Palavras-chave: {', '.join(conversation_data.get('keywords', []))}
            Sentimento: {conversation_data.get('sentiment', 'Neutro')}
            """
        else:
            # Dados diretos de caso simples
            optimized_text = f"""
            Área: {conversation_data.get('area', 'Não identificado')}
            Subárea: {conversation_data.get('subarea', 'Geral')}
            Resumo: {conversation_data.get('summary', 'Sem resumo')}
            Urgência: {conversation_data.get('urgency_h', 72)} horas
            Palavras-chave: {', '.join(conversation_data.get('keywords', []))}
            Sentimento: {conversation_data.get('sentiment', 'Neutro')}
            """

        # Executar análise failover com dados otimizados
        try:
            detailed_analysis = await self.triage_service._run_failover_strategy(optimized_text)

            # Combinar dados da conversa com análise detalhada
            combined_data = {
                **conversation_data,
                **detailed_analysis,
                "conversation_optimized": True,
                "source_strategy": "failover"
            }
            
            # NOVO: Adicionar case_type baseado na área jurídica
            area = combined_data.get("area")
            subarea = combined_data.get("subarea")
            keywords = combined_data.get("keywords", [])
            summary = combined_data.get("summary")
            nature = combined_data.get("nature")
            
            case_type = map_area_to_case_type(
                area=area,
                subarea=subarea,
                keywords=keywords,
                summary=summary,
                nature=nature
            )
            combined_data["case_type"] = case_type

            # Gerar embedding se necessário
            if "summary" in combined_data:
                embedding = await generate_embedding(combined_data["summary"])
                combined_data["summary_embedding"] = embedding

            return OrchestrationResult(
                case_id=interviewer_result.case_id,
                strategy_used="failover",
                complexity_level=interviewer_result.complexity_level,
                confidence_score=interviewer_result.confidence_score,
                triage_data=combined_data,
                conversation_summary=interviewer_result.conversation_summary,
                processing_time_ms=0,
                flow_type="standard_analysis",
                analysis_details={
                    "source": "failover_strategy",
                    "analysis_type": "optimized_failover",
                    "optimization": "Dados estruturados pela IA Entrevistadora para análise failover"
                }
            )

        except Exception as e:
            # Fallback para dados da conversa
            print(f"Erro na análise failover: {e}")
            return await self._process_simple_flow(interviewer_result)

    async def _process_ensemble_flow(
            self, interviewer_result: TriageResult) -> OrchestrationResult:
        """
        Processa casos complexos usando a estratégia ensemble
        com dados estruturados pela IA Entrevistadora + LEX-9000.
        """
        conversation_data = interviewer_result.triage_data

        # Preparar texto enriquecido para análise ensemble
        if "basic_info" in conversation_data:
            basic_info = conversation_data["basic_info"]
            entities = conversation_data.get("entities", {})

            optimized_text = f"""
            INFORMAÇÕES BÁSICAS:
            Área: {basic_info.get('area', 'Não identificado')}
            Subárea: {basic_info.get('subarea', 'Geral')}
            Resumo: {basic_info.get('summary', 'Sem resumo')}
            Urgência: {basic_info.get('urgency_h', 72)} horas
            
            ENTIDADES IDENTIFICADAS:
            Partes envolvidas: {', '.join(entities.get('parties', []))}
            Localizações: {', '.join(entities.get('locations', []))}
            Datas relevantes: {', '.join(entities.get('dates', []))}
            Valores mencionados: {', '.join(entities.get('amounts', []))}
            
            FATORES DE COMPLEXIDADE:
            {chr(10).join(f"- {factor}" for factor in conversation_data.get('complexity_factors', []))}

            CONTEXTO ADICIONAL:
            Palavras-chave: {', '.join(conversation_data.get('keywords', []))}
            Sentimento: {conversation_data.get('sentiment', 'Neutro')}

            RESUMO DA CONVERSA:
            {conversation_data.get('conversation_summary', 'Conversa não disponível')}
            """
        else:
            # Fallback para dados simples
            optimized_text = f"""
            Área: {conversation_data.get('area', 'Não identificado')}
            Subárea: {conversation_data.get('subarea', 'Geral')}
            Resumo: {conversation_data.get('summary', 'Sem resumo')}
            Caso identificado como complexo pela IA Entrevistadora.
            """

        try:
            # Executar análise ensemble com dados enriquecidos
            detailed_analysis = await self.triage_service._run_ensemble_strategy(optimized_text)

            # Executar análise detalhada adicional
            comprehensive_analysis = await self.triage_service.run_detailed_analysis(optimized_text)

            # NOVO: Executar análise LEX-9000 para casos complexos
            lex_analysis = None
            if lex9000_integration_service.is_available():
                print("Executando análise LEX-9000 para caso complexo...")
                lex_analysis = await lex9000_integration_service.analyze_complex_case(conversation_data)

            # Combinar todos os dados
            combined_data = {
                **conversation_data,
                **detailed_analysis,
                "detailed_analysis": comprehensive_analysis,
                "conversation_optimized": True,
                "source_strategy": "ensemble"
            }

            # Integrar análise LEX-9000 se disponível
            if lex_analysis:
                combined_data["lex9000_analysis"] = {
                    "classificacao": lex_analysis.classificacao,
                    "dados_extraidos": lex_analysis.dados_extraidos,
                    "analise_viabilidade": lex_analysis.analise_viabilidade,
                    "urgencia": lex_analysis.urgencia,
                    "aspectos_tecnicos": lex_analysis.aspectos_tecnicos,
                    "recomendacoes": lex_analysis.recomendacoes,
                    "confidence_score": lex_analysis.confidence_score,
                    "processing_time_ms": lex_analysis.processing_time_ms
                }
                print(
                    f"LEX-9000 analysis completed with confidence: {lex_analysis.confidence_score:.2f}")
            
            # NOVO: Adicionar case_type baseado na área jurídica
            # Priorizar dados do LEX-9000 se disponível
            area = combined_data.get("area")
            subarea = combined_data.get("subarea")
            keywords = combined_data.get("keywords", [])
            summary = combined_data.get("summary")
            nature = None
            
            # Se LEX-9000 analisou, usar a natureza dele
            if lex_analysis and hasattr(lex_analysis, 'classificacao'):
                nature = lex_analysis.classificacao.get('natureza')
            
            case_type = map_area_to_case_type(
                area=area,
                subarea=subarea,
                keywords=keywords,
                summary=summary,
                nature=nature
            )
            combined_data["case_type"] = case_type

            # Gerar embedding
            if "summary" in combined_data:
                embedding = await generate_embedding(combined_data["summary"])
                combined_data["summary_embedding"] = embedding

            return OrchestrationResult(
                case_id=interviewer_result.case_id,
                strategy_used="ensemble",
                complexity_level=interviewer_result.complexity_level,
                confidence_score=interviewer_result.confidence_score,
                triage_data=combined_data,
                conversation_summary=interviewer_result.conversation_summary,
                processing_time_ms=0,
                flow_type="ensemble_analysis",
                analysis_details={
                    "source": "ensemble_strategy",
                    "analysis_type": "comprehensive_ensemble_with_lex9000",
                    "optimization": "Dados estruturados e enriquecidos pela IA Entrevistadora para análise ensemble completa",
                    "additional_analysis": "Análise detalhada complementar executada",
                    "lex9000_enabled": lex_analysis is not None,
                    "lex9000_confidence": lex_analysis.confidence_score if lex_analysis else None
                }
            )

        except Exception as e:
            # Fallback para análise failover
            print(f"Erro na análise ensemble: {e}")
            return await self._process_failover_flow(interviewer_result)

    async def get_orchestration_status(self, case_id: str) -> Optional[Dict]:
        """Obtém status da orquestração."""
        if not self.state_manager.is_orchestration_active(case_id):
            return None

        orchestration = await self.state_manager.get_orchestration_state(case_id)

        # Obter status da conversa se ainda ativa
        conversation_status = None
        if orchestration["status"] == "interviewing":
            conversation_status = await self.interviewer.get_conversation_status(case_id)

        return {
            "case_id": case_id,
            "status": orchestration["status"],
            "flow_type": orchestration.get("flow_type", "unknown"),
            "started_at": orchestration["started_at"],
            "conversation_status": conversation_status,
            "current_complexity": orchestration.get("current_complexity"),
            "current_confidence": orchestration.get("current_confidence"),
            "error": orchestration.get("error")
        }

    def cleanup_orchestration(self, case_id: str):
        """Remove orquestração da memória."""
        if self.state_manager.is_orchestration_active(case_id):
            self.state_manager.remove_orchestration(case_id)

    async def get_orchestration_result(
            self, case_id: str) -> Optional[OrchestrationResult]:
        """Obtém resultado final da orquestração."""
        if not self.state_manager.is_orchestration_active(case_id):
            return None

        orchestration = await self.state_manager.get_orchestration_state(case_id)

        if orchestration["status"] != "completed":
            return None

        return orchestration.get("result")

    async def force_complete_conversation(
            self, case_id: str, reason: str = "timeout") -> Optional[OrchestrationResult]:
        """
        Força a finalização de uma conversa (por timeout ou outros motivos).
        """
        if not self.state_manager.is_orchestration_active(case_id):
            return None

        orchestration = await self.state_manager.get_orchestration_state(case_id)

        if orchestration["status"] != "interviewing":
            return None

        try:
            # Obter estado atual da conversa
            conversation_status = await self.interviewer.get_conversation_status(case_id)

            if not conversation_status:
                return None

            # Criar resultado baseado no estado atual
            current_complexity = conversation_status.get("complexity_level", "medium")
            current_confidence = conversation_status.get("confidence_score", 0.5)

            # Determinar estratégia baseada na complexidade atual
            if current_complexity == "low":
                strategy = "simple"
            elif current_complexity == "high":
                strategy = "ensemble"
            else:
                strategy = "failover"

            # Criar resultado de emergência
            emergency_result = TriageResult(
                case_id=case_id,
                strategy_used=strategy,
                complexity_level=current_complexity,
                confidence_score=current_confidence,
                triage_data={
                    "area": "Não identificado",
                    "subarea": "Geral",
                    "urgency_h": 72,
                    "summary": f"Conversa interrompida por {reason}",
                    "keywords": [],
                    "sentiment": "Neutro",
                    "completion_reason": reason
                },
                conversation_summary=f"Conversa interrompida - {reason}",
                processing_time_ms=0
            )

            # Processar resultado
            result = await self._process_completed_conversation(case_id)

            orchestration["status"] = "completed"
            orchestration["result"] = result
            orchestration["completion_reason"] = reason

            return result

        except Exception as e:
            orchestration["status"] = "error"
            orchestration["error"] = f"Erro ao forçar finalização: {str(e)}"
            return None


# Instância única do orquestrador
intelligent_triage_orchestrator = IntelligentTriageOrchestrator()
