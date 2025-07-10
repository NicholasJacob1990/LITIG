import asyncio
import json
import os
import uuid
from dataclasses import asdict, dataclass
from datetime import datetime
from typing import Dict, List, Literal, Optional, Tuple

import anthropic
import openai
from dotenv import load_dotenv

from .conversation_state_manager import conversation_state_manager

load_dotenv()

# Configurações
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

Strategy = Literal["simple", "failover", "ensemble"]
ComplexityLevel = Literal["low", "medium", "high"]


@dataclass
class TriageResult:
    """Resultado final da triagem inteligente."""
    case_id: str
    strategy_used: Strategy
    complexity_level: ComplexityLevel
    confidence_score: float
    triage_data: Dict
    conversation_summary: str
    processing_time_ms: int


class IntelligentInterviewerService:
    """
    IA "Entrevistadora" que conduz conversas inteligentes e detecta complexidade em tempo real.

    MIGRADO PARA REDIS - Sprint 1 Implementado
    """

    def __init__(self):
        if not ANTHROPIC_API_KEY:
            raise ValueError(
                "Chave da API da Anthropic (ANTHROPIC_API_KEY) não encontrada.")

        self.anthropic_client = anthropic.AsyncAnthropic(api_key=ANTHROPIC_API_KEY)
        self.openai_client = openai.AsyncOpenAI(
            api_key=OPENAI_API_KEY) if OPENAI_API_KEY else None

        # REMOVIDO: self.active_conversations - agora usa Redis
        self.state_manager = conversation_state_manager

        # Prompt especializado integrando metodologia do LEX-9000 com detecção de
        # complexidade
        self.interviewer_prompt = """
        Você é "Justus", um assistente jurídico especializado em triagem inteligente da LITGO5, evoluído do sistema LEX-9000.

        **SEU PAPEL ÚNICO:**
        Você é simultaneamente um entrevistador empático E um detector de complexidade em tempo real, usando metodologia jurídica estruturada.

        **ESPECIALIZAÇÃO JURÍDICA:**
        - Conhecimento profundo do ordenamento jurídico brasileiro
        - Experiência em todas as áreas do direito (civil, trabalhista, criminal, administrativo, etc.)
        - Capacidade de identificar urgência, complexidade e viabilidade processual
        - Foco em aspectos práticos e estratégicos

        **METODOLOGIA DE TRIAGEM INTELIGENTE:**

        ## FASE 1 - IDENTIFICAÇÃO INICIAL (1-2 perguntas)
        - Área jurídica principal
        - Natureza do problema (preventivo vs contencioso)
        - Urgência temporal
        - **AVALIAÇÃO**: Detectar se é caso simples, médio ou complexo

        ## FASE 2 - DETALHAMENTO FACTUAL (2-6 perguntas conforme complexidade)
        - Partes envolvidas e suas qualificações
        - Cronologia dos fatos relevantes
        - Documentação disponível
        - Valores envolvidos (quando aplicável)
        - Tentativas de solução extrajudicial

        ## FASE 3 - ASPECTOS TÉCNICOS (0-4 perguntas - apenas se complexo)
        - Prazos legais e prescrição
        - Jurisdição competente
        - Complexidade probatória
        - Precedentes ou jurisprudência conhecida

        **AVALIAÇÃO DE COMPLEXIDADE EM TEMPO REAL:**

        🟢 **BAIXA COMPLEXIDADE** (strategy: "simple") - 3-5 perguntas:
        - Casos rotineiros: multa de trânsito, atraso de voo, produto defeituoso
        - Questões simples de consumidor, vizinhança, cobrança indevida
        - Situações com precedentes claros e soluções padronizadas
        - Apenas uma parte envolvida, sem questões técnicas complexas
        - **AÇÃO**: Colete dados básicos e finalize rapidamente

        🟡 **MÉDIA COMPLEXIDADE** (strategy: "failover") - 5-8 perguntas:
        - Casos trabalhistas padrão, contratos simples, acidentes de trânsito
        - Questões familiares básicas, disputas de aluguel convencionais
        - Situações que requerem análise jurídica, mas sem múltiplas variáveis
        - Casos com alguma complexidade técnica, mas dentro do padrão
        - **AÇÃO**: Colete dados estruturados para análise posterior

        🔴 **ALTA COMPLEXIDADE** (strategy: "ensemble") - 6-10 perguntas:
        - Múltiplas partes envolvidas, questões societárias complexas
        - Propriedade intelectual, patentes, marcas registradas
        - Recuperação judicial, falência, reestruturação empresarial
        - Questões internacionais, contratos complexos, litígios estratégicos
        - Casos que envolvem jurisprudência especializada ou precedentes conflitantes
        - **AÇÃO**: Colete dados completos e detalhados para análise ensemble

        **PERGUNTAS INTELIGENTES:**
        - Seja específico conforme a área identificada
        - Adapte as perguntas ao tipo de caso (ex: trabalhista vs civil)
        - Priorize informações que impactam viabilidade e estratégia
        - Considere aspectos econômicos e temporais

        **CRITÉRIOS PARA FINALIZAÇÃO:**
        Termine a entrevista quando tiver informações suficientes sobre:
        ✅ Área jurídica e instituto específico
        ✅ Fatos essenciais e cronologia
        ✅ Partes e suas qualificações
        ✅ Urgência e prazos
        ✅ Viabilidade preliminar do caso
        ✅ Documentação disponível

        **FINALIZAÇÃO POR COMPLEXIDADE:**
        - **Baixa**: Você mesmo pode gerar a análise final (economia de recursos)
        - **Média/Alta**: Prepare dados estruturados para análise posterior

        **SINAL DE FINALIZAÇÃO:**
        Quando a conversa estiver completa, termine com: [TRIAGE_COMPLETE:STRATEGY_X:CONFIDENCE_Y]
        Onde X = simple/failover/ensemble e Y = 0.0-1.0

        **DIRETRIZES DE CONVERSA:**
        - Uma pergunta por vez, seja empático e profissional
        - Mantenha linguagem profissional mas acessível
        - Seja objetivo e prático nas perguntas
        - Considere sempre o contexto brasileiro
        - Não mencione "complexidade" ou "estratégias" para o cliente
        - Foque em entender o problema completamente
        - Use linguagem acessível, evite jargões jurídicos
        """

    async def start_conversation(self, user_id: str) -> Tuple[str, str]:
        """
        Inicia uma nova conversa de triagem inteligente - MIGRADO PARA REDIS.

        Returns:
            Tuple[case_id, primeira_mensagem_ia]
        """
        case_id = str(uuid.uuid4())

        # Estado inicial da conversa
        initial_state = {
            "user_id": user_id,
            "messages": [],
            "complexity_level": "medium",
            "confidence_score": 0.0,
            "collected_data": {},
            "is_complete": False,
            "strategy_recommended": "failover",
            "completion_reason": "",
            "status": "active",
            "created_at": datetime.now().isoformat()
        }

        # Gerar primeira mensagem
        first_message = "Olá! Sou o Justus, seu assistente jurídico da LITGO5. Estou aqui para entender seu caso e ajudá-lo da melhor forma possível. Para começarmos, você poderia me descrever o problema que está enfrentando?"

        # Adicionar primeira mensagem ao estado
        initial_state["messages"].append({
            "role": "assistant",
            "content": first_message,
            "timestamp": datetime.now().isoformat()
        })

        # Salvar no Redis
        await self.state_manager.save_conversation_state(case_id, initial_state)

        return case_id, first_message

    async def continue_conversation(
            self, case_id: str, user_message: str) -> Tuple[str, bool]:
        """
        Continua uma conversa existente - MIGRADO PARA REDIS.

        Returns:
            Tuple[resposta_ia, conversa_finalizada]
        """
        # Recuperar estado do Redis
        state = await self.state_manager.get_conversation_state(case_id)
        if not state:
            raise ValueError(f"Conversa {case_id} não encontrada")

        # Adicionar mensagem do usuário
        state["messages"].append({
            "role": "user",
            "content": user_message,
            "timestamp": datetime.now().isoformat()
        })

        # Gerar resposta da IA
        ai_response = await self._generate_ai_response(state)

        # Verificar se a conversa foi finalizada
        if "[TRIAGE_COMPLETE:" in ai_response:
            return await self._finalize_conversation(case_id, ai_response, state)

        # Salvar estado atualizado no Redis
        state["updated_at"] = datetime.now().isoformat()
        await self.state_manager.save_conversation_state(case_id, state)

        return ai_response, False

    async def _generate_ai_response(self, state: Dict) -> str:
        """Gera resposta da IA usando Claude com avaliação de complexidade."""

        # Preparar histórico para o Claude
        messages = [{"role": "system", "content": self.interviewer_prompt}]

        # Adicionar mensagens da conversa (sem timestamps para o Claude)
        for msg in state["messages"]:
            messages.append({
                "role": msg["role"],
                "content": msg["content"]
            })

        try:
            response = await self.anthropic_client.messages.create(
                model="claude-3-5-sonnet-20240620",
                max_tokens=300,
                temperature=0.7,
                messages=messages
            )

            ai_response = response.content[0].text

            # Adicionar resposta ao histórico
            state["messages"].append({
                "role": "assistant",
                "content": ai_response,
                "timestamp": datetime.now().isoformat()
            })

            # Avaliar complexidade se não for finalização
            if not "[TRIAGE_COMPLETE:" in ai_response:
                await self._evaluate_complexity(state)

            return ai_response

        except Exception as e:
            print(f"Erro na geração de resposta: {e}")
            fallback_response = "Desculpe, estou com problemas técnicos. Você poderia repetir sua última mensagem?"
            state["messages"].append({
                "role": "assistant",
                "content": fallback_response,
                "timestamp": datetime.now().isoformat()
            })
            return fallback_response

    async def _evaluate_complexity(self, state: Dict):
        """Avalia a complexidade do caso baseado na conversa atual."""

        # Prompt específico para avaliação de complexidade
        complexity_prompt = """
        Analise a conversa a seguir e determine a complexidade do caso jurídico.

        Responda APENAS com um JSON no formato:
        {
            "complexity": "low|medium|high",
            "confidence": 0.0-1.0,
            "reasoning": "breve explicação",
            "indicators": ["indicador1", "indicador2"]
        }

        Critérios:
        - LOW: casos simples, rotineiros, com soluções padronizadas
        - MEDIUM: casos que requerem análise jurídica padrão
        - HIGH: casos complexos, múltiplas partes, questões especializadas
        """

        # Preparar contexto da conversa
        conversation_text = "\n".join([
            f"{msg['role'].upper()}: {msg['content']}"
            for msg in state["messages"][-6:]  # Últimas 6 mensagens
        ])

        try:
            response = await self.anthropic_client.messages.create(
                model="claude-3-haiku-20240307",  # Modelo mais rápido para avaliação
                max_tokens=200,
                temperature=0.1,
                messages=[
                    {"role": "system", "content": complexity_prompt},
                    {"role": "user", "content": f"Conversa:\n{conversation_text}"}
                ]
            )

            # Extrair JSON da resposta
            response_text = response.content[0].text
            if "{" in response_text and "}" in response_text:
                json_start = response_text.find("{")
                json_end = response_text.rfind("}") + 1
                complexity_data = json.loads(response_text[json_start:json_end])

                # Atualizar estado
                state["complexity_level"] = complexity_data.get("complexity", "medium")
                state["confidence_score"] = complexity_data.get("confidence", 0.5)

                # Determinar estratégia recomendada
                if state["complexity_level"] == "low":
                    state["strategy_recommended"] = "simple"
                elif state["complexity_level"] == "high":
                    state["strategy_recommended"] = "ensemble"
                else:
                    state["strategy_recommended"] = "failover"

        except Exception as e:
            print(f"Erro na avaliação de complexidade: {e}")
            # Manter valores padrão
            state["complexity_level"] = "medium"
            state["confidence_score"] = 0.5
            state["strategy_recommended"] = "failover"

    async def _finalize_conversation(
            self, case_id: str, ai_response: str, state: Dict) -> Tuple[str, bool]:
        """Finaliza a conversa e processa o resultado."""

        # Extrair informações do sinal de finalização
        if "[TRIAGE_COMPLETE:" in ai_response:
            # Remover o sinal da resposta do usuário
            clean_response = ai_response.split("[TRIAGE_COMPLETE:")[0].strip()

            # Extrair estratégia e confiança do sinal
            signal_part = ai_response.split("[TRIAGE_COMPLETE:")[1].replace("]", "")
            parts = signal_part.split(":")

            if len(parts) >= 2:
                strategy = parts[0].replace("STRATEGY_", "").lower()
                confidence = float(parts[1].replace("CONFIDENCE_", ""))

                state["strategy_recommended"] = strategy
                state["confidence_score"] = confidence
        else:
            clean_response = ai_response

        # Marcar como completa
        state["is_complete"] = True
        state["completion_reason"] = "natural_end"
        state["status"] = "completed"
        state["completed_at"] = datetime.now().isoformat()

        # Processar resultado baseado na estratégia
        if state["strategy_recommended"] == "simple":
            # Para casos simples, gerar resultado diretamente
            await self._process_simple_case(state)
        else:
            # Para casos complexos, preparar dados para análise posterior
            await self._prepare_complex_case_data(state)

        # Salvar estado final no Redis
        await self.state_manager.save_conversation_state(case_id, state)

        return clean_response, True

    async def _process_simple_case(self, state: Dict):
        """Processa casos simples diretamente, sem análise posterior."""

        # Prompt para gerar análise completa de caso simples
        simple_analysis_prompt = """
        Você é um assistente jurídico especializado. Analise a conversa a seguir e gere uma análise completa do caso.

        Responda APENAS com um JSON no formato:
        {
            "area": "área jurídica principal",
            "subarea": "subárea específica",
            "urgency_h": número_de_horas_para_ação,
            "summary": "resumo conciso do caso",
            "keywords": ["palavra1", "palavra2"],
            "sentiment": "Positivo|Neutro|Negativo",
            "analysis": {
                "viability": "Alta|Média|Baixa",
                "complexity": "Baixa",
                "recommended_action": "ação recomendada",
                "estimated_cost": "estimativa de custo",
                "next_steps": ["passo1", "passo2"]
            }
        }
        """

        conversation_text = "\n".join([
            f"{msg['role'].upper()}: {msg['content']}"
            for msg in state["messages"]
        ])

        try:
            response = await self.anthropic_client.messages.create(
                model="claude-3-5-sonnet-20240620",
                max_tokens=1000,
                temperature=0.3,
                messages=[
                    {"role": "system", "content": simple_analysis_prompt},
                    {"role": "user", "content": f"Conversa completa:\n{conversation_text}"}
                ]
            )

            # Extrair JSON da resposta
            response_text = response.content[0].text
            if "{" in response_text and "}" in response_text:
                json_start = response_text.find("{")
                json_end = response_text.rfind("}") + 1
                analysis_data = json.loads(response_text[json_start:json_end])

                state["collected_data"] = analysis_data

        except Exception as e:
            print(f"Erro na análise de caso simples: {e}")
            # Fallback básico
            state["collected_data"] = {
                "area": "Não identificado",
                "subarea": "Geral",
                "urgency_h": 72,
                "summary": "Análise pendente",
                "keywords": [],
                "sentiment": "Neutro",
                "analysis": {
                    "viability": "Média",
                    "complexity": "Baixa",
                    "recommended_action": "Consultar advogado",
                    "estimated_cost": "A definir",
                    "next_steps": ["Reunir documentação"]
                }
            }

    async def _prepare_complex_case_data(self, state: Dict):
        """Prepara dados estruturados para casos complexos usando schema LEX-9000."""

        # Implementação simplificada - versão completa seria muito extensa
        conversation_text = "\n".join([
            f"{msg['role'].upper()}: {msg['content']}"
            for msg in state["messages"]
        ])

        # Dados básicos para casos complexos
        state["collected_data"] = {
            "basic_info": {
                "area": "Análise pendente",
                "subarea": "Análise pendente",
                "urgency_h": 72,
                "summary": f"Caso complexo identificado - {len(state['messages'])} mensagens coletadas"
            },
            "conversation_summary": conversation_text,
            "complexity_factors": ["Múltiplas variáveis", "Análise especializada requerida"],
            "keywords": [],
            "sentiment": "Neutro",
            "entities": {
                "parties": [],
                "dates": [],
                "amounts": [],
                "locations": []
            }
        }

    async def get_triage_result(self, case_id: str) -> Optional[TriageResult]:
        """
        Obtém resultado final da triagem - MIGRADO PARA REDIS.
        """
        state = await self.state_manager.get_conversation_state(case_id)
        if not state or not state.get("is_complete"):
            return None

        # Gerar resumo da conversa
        conversation_summary = f"Conversa com {
            len(
                state.get(
                    'messages',
                    []))} mensagens"

        return TriageResult(
            case_id=case_id,
            strategy_used=state.get("strategy_recommended", "failover"),
            complexity_level=state.get("complexity_level", "medium"),
            confidence_score=state.get("confidence_score", 0.5),
            triage_data=state.get("collected_data", {}),
            conversation_summary=conversation_summary,
            processing_time_ms=0  # Será calculado pelo orquestrador
        )

    def cleanup_conversation(self, case_id: str):
        """
        Remove conversa - MIGRADO PARA REDIS.
        """
        # Execução assíncrona para não bloquear
        asyncio.create_task(
            self.state_manager.delete_conversation_state(case_id)
        )

    async def get_conversation_status(self, case_id: str) -> Optional[Dict]:
        """
        Obtém status da conversa - MIGRADO PARA REDIS.
        """
        state = await self.state_manager.get_conversation_state(case_id)
        if not state:
            return None

        return {
            "case_id": case_id,
            "status": state.get("status", "unknown"),
            "complexity_level": state.get("complexity_level", "unknown"),
            "confidence_score": state.get("confidence_score", 0.0),
            "message_count": len(state.get("messages", [])),
            "created_at": state.get("created_at"),
            "updated_at": state.get("updated_at"),
            "is_complete": state.get("is_complete", False)
        }


# Instância única do serviço
intelligent_interviewer_service = IntelligentInterviewerService()
