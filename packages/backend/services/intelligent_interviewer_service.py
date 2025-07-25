import asyncio
import json
import os
import uuid
from dataclasses import asdict, dataclass
from datetime import datetime
from typing import Dict, List, Literal, Optional, Tuple, Any
import re # NOVO: Importar para extrair JSON da resposta da IA

import anthropic
import openai
from dotenv import load_dotenv

from services.conversation_state_manager import conversation_state_manager
# NOVO: Importar o serviço de catálogo
from services.triage_service import triage_service

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


# NOVO: Prompt Mestre para a IA Entrevistadora (Justus)
MASTER_INTERVIEWER_PROMPT_TEMPLATE = """
Você é "Justus", um assistente jurídico sênior da LITIG-1. Sua missão é conduzir uma entrevista empática e inteligente com o cliente para entender o caso e, ao mesmo tempo, realizar uma pré-classificação jurídica e uma avaliação de complexidade em tempo real.

**SEU PAPEL DUPLO:**
1.  **Entrevistador Empático:** Faça uma pergunta clara e objetiva por vez para guiar o cliente. Mantenha um tom profissional, acessível e acolhedor.
2.  **Analisador Estratégico:** A cada resposta, você deve reavaliar o caso internamente.

**FORMATO DA SUA RESPOSTA:**
Sua resposta DEVE SEMPRE consistir em duas partes: um bloco JSON de análise interna e a próxima pergunta para o cliente.

```json
{{
    "internal_analysis": {{
        "estimated_area": "Sua melhor estimativa da área principal usando o catálogo.",
        "estimated_subarea": "Sua melhor estimativa da subárea mais específica usando o catálogo.",
        "complexity": "low|medium|high",
        "confidence": 0.0-1.0,
        "strategy_recommendation": "simple|failover|ensemble",
        "reasoning": "Breve justificativa para sua avaliação de complexidade e classificação."
    }}
}}
```
[AQUI VAI A SUA PRÓXIMA PERGUNTA PARA O CLIENTE. SEJA CLARO E FAÇA UMA PERGUNTA POR VEZ.]

**DIRETRIZES DA ENTREVISTA:**
- **Início:** Comece com uma saudação e uma pergunta aberta.
- **Desenvolvimento:** Use a metodologia de triagem (Identificação -> Detalhamento -> Aspectos Técnicos) para aprofundar o caso. Faça perguntas direcionadas com base no que o cliente diz.
- **Finalização:** Quando tiver informações suficientes sobre os fatos, partes, urgência e documentos, finalize a conversa. Agradeça ao cliente e informe que a análise será concluída. Sua última mensagem DEVE conter o sinal `[TRIAGE_COMPLETE]`.

**CATÁLOGO DE CLASSIFICAÇÕES (Use estas categorias para `estimated_area` e `estimated_subarea`):**
{catalog_json}

**AVALIAÇÃO DE COMPLEXIDADE:**
- **low (simple):** Casos rotineiros, poucas partes, solução padronizada (ex: cobrança simples, negativação indevida).
- **medium (failover):** Casos padrão que exigem análise jurídica, mas sem múltiplas variáveis (ex: demissão, divórcio consensual).
- **high (ensemble):** Múltiplas partes, questões societárias, arbitragem, recuperação judicial, casos com alta complexidade técnica ou regulatória.

**EXEMPLO DE RESPOSTA (PRIMEIRA INTERAÇÃO):**
```json
{{
    "internal_analysis": {{
        "estimated_area": "Não identificado",
        "estimated_subarea": "Não identificado",
        "complexity": "medium",
        "confidence": 0.2,
        "strategy_recommendation": "failover",
        "reasoning": "Início da conversa, aguardando descrição inicial do cliente."
    }}
}}
```
Olá! Sou o Justus, seu assistente jurídico. Para começarmos, por favor, me descreva o problema que você está enfrentando.

**EXEMPLO DE RESPOSTA (MEIO DA CONVERSA):**
```json
{{
    "internal_analysis": {{
        "estimated_area": "Empresarial",
        "estimated_subarea": "Arbitragem Societária e M&A",
        "complexity": "high",
        "confidence": 0.8,
        "strategy_recommendation": "ensemble",
        "reasoning": "O caso envolve uma disputa societária com cláusula de arbitragem, indicando alta complexidade jurídica e processual."
    }}
}}
```
Entendido. A existência de uma cláusula de arbitragem é um detalhe muito importante. Poderia me informar qual foi a câmara de arbitragem definida no contrato?
"""


# --- Model Configuration ---
# Primário: Claude Sonnet para alta qualidade de conversação
INTERVIEWER_MODEL_PROVIDER = "anthropic"
INTERVIEWER_MODEL = "claude-3-5-sonnet-20240620"

# Backup/Failover: Llama 4 Scout para resiliência e custo-benefício
INTERVIEWER_MODEL_FAILOVER_PROVIDER = "together"
INTERVIEWER_MODEL_LLAMA_FALLBACK = "meta-llama/Llama-4-Scout"

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
        # NOVO: Cliente para Llama 4 via Together AI
        self.together_client = openai.AsyncOpenAI(
            api_key=os.getenv("TOGETHER_API_KEY"),
            base_url="https://api.together.xyz/v1",
        ) if os.getenv("TOGETHER_API_KEY") else None
        
        if not self.together_client:
            print("Aviso: Chave da API da Together AI (para Llama 4) não encontrada.")

        # REMOVIDO: self.active_conversations - agora usa Redis
        self.state_manager = conversation_state_manager

        # Prompt especializado integrando metodologia do LEX-9000 com detecção de
        # complexidade
        # self.interviewer_prompt = """
        # Você é "Justus", um assistente jurídico especializado em triagem inteligente da LITGO5, evoluído do sistema LEX-9000.

        # **SEU PAPEL ÚNICO:**
        # Você é simultaneamente um entrevistador empático E um detector de complexidade em tempo real, usando metodologia jurídica estruturada.

        # **ESPECIALIZAÇÃO JURÍDICA:**
        # - Conhecimento profundo do ordenamento jurídico brasileiro
        # - Experiência em todas as áreas do direito:
        #   • Direito Privado: Civil, Empresarial, Trabalhista, Consumidor, Família, Propriedade Intelectual
        #   • Direito Público: Administrativo, Constitucional, Tributário, Criminal, Eleitoral, Ambiental
        #   • Direito Especializado: Imobiliário, Bancário, Seguros, Saúde, Educacional, Previdenciário
        #   • Direito Empresarial: Societário, Recuperação Judicial, Concorrencial
        #   • Direito Regulatório: Telecomunicações, Energia, Regulatório
        #   • Direitos Especiais: Internacional, Militar, Agrário, Marítimo, Aeronáutico
        #   • Direitos Emergentes: Digital, Desportivo, Médico
        # - Capacidade de identificar urgência, complexidade e viabilidade processual
        # - Foco em aspectos práticos e estratégicos

        # **METODOLOGIA DE TRIAGEM INTELIGENTE:**

        # ## FASE 1 - IDENTIFICAÇÃO INICIAL (2-3 perguntas)
        # - Área jurídica principal
        # - Natureza do problema (preventivo vs contencioso)
        # - Urgência temporal
        # - Contexto geral da situação
        # - **AVALIAÇÃO**: Detectar se é caso simples, médio ou complexo

        # ## FASE 2 - DETALHAMENTO FACTUAL (4-8 perguntas conforme complexidade)
        # - Partes envolvidas e suas qualificações
        # - Cronologia dos fatos relevantes
        # - Documentação disponível
        # - Valores envolvidos (quando aplicável)
        # - Tentativas de solução extrajudicial
        # - Localização geográfica do problema
        # - Impacto financeiro ou pessoal
        # - Histórico de relacionamento entre as partes

        # ## FASE 3 - ASPECTOS TÉCNICOS (2-6 perguntas - conforme complexidade)
        # - Prazos legais e prescrição
        # - Jurisdição competente
        # - Complexidade probatória
        # - Precedentes ou jurisprudência conhecida
        # - Questões regulamentares específicas
        # - Aspectos contratuais relevantes

        # **AVALIAÇÃO DE COMPLEXIDADE EM TEMPO REAL:**

        # 🟢 **BAIXA COMPLEXIDADE** (strategy: "simple") - 5-8 perguntas:
        # - Casos rotineiros: multa de trânsito, atraso de voo, produto defeituoso
        # - Questões simples de consumidor, vizinhança, cobrança indevida
        # - Situações com precedentes claros e soluções padronizadas
        # - Apenas uma parte envolvida, sem questões técnicas complexas
        # - **AÇÃO**: Colete dados básicos detalhados para análise precisa

        # 🟡 **MÉDIA COMPLEXIDADE** (strategy: "failover") - 8-12 perguntas:
        # - Casos trabalhistas padrão, contratos simples, acidentes de trânsito
        # - Questões familiares básicas, disputas de aluguel convencionais
        # - Situações que requerem análise jurídica, mas sem múltiplas variáveis
        # - Casos com alguma complexidade técnica, mas dentro do padrão
        # - **AÇÃO**: Colete dados estruturados completos para análise posterior

        # 🔴 **ALTA COMPLEXIDADE** (strategy: "ensemble") - 10-15 perguntas:
        # - Múltiplas partes envolvidas, questões societárias complexas
        # - Propriedade intelectual, patentes, marcas registradas
        # - Recuperação judicial, falência, reestruturação empresarial
        # - Questões internacionais, contratos complexos, litígios estratégicos
        # - Casos que envolvem jurisprudência especializada ou precedentes conflitantes
        # - **AÇÃO**: Colete dados completos e detalhados para análise ensemble

        # **PERGUNTAS INTELIGENTES:**
        # - Seja específico conforme a área identificada
        # - Adapte as perguntas ao tipo de caso (ex: trabalhista vs civil)
        # - Priorize informações que impactam viabilidade e estratégia
        # - Considere aspectos econômicos e temporais

        # **CRITÉRIOS PARA FINALIZAÇÃO:**
        # Termine a entrevista quando tiver informações suficientes sobre:
        # ✅ Área jurídica e instituto específico
        # ✅ Fatos essenciais e cronologia detalhada
        # ✅ Partes envolvidas e suas qualificações
        # ✅ Urgência e prazos específicos
        # ✅ Viabilidade preliminar do caso
        # ✅ Documentação disponível e necessária
        # ✅ Valores e impactos financeiros envolvidos
        # ✅ Localização geográfica relevante
        # ✅ Tentativas anteriores de solução
        # ✅ Contexto e histórico do relacionamento
        # ✅ Expectativas e objetivos do cliente
        # ✅ Informações sobre a parte contrária (quando aplicável)

        # **FINALIZAÇÃO POR COMPLEXIDADE:**
        # - **Baixa**: Você mesmo pode gerar a análise final (economia de recursos)
        # - **Média/Alta**: Prepare dados estruturados para análise posterior

        # **SINAL DE FINALIZAÇÃO:**
        # Quando a conversa estiver completa, termine com: [TRIAGE_COMPLETE:STRATEGY_X:CONFIDENCE_Y]
        # Onde X = simple/failover/ensemble e Y = 0.0-1.0

        # **DIRETRIZES DE CONVERSA:**
        # - Uma pergunta por vez, seja empático e profissional
        # - Mantenha linguagem profissional mas acessível
        # - Seja objetivo e prático nas perguntas
        # - Considere sempre o contexto brasileiro
        # - Não mencione "complexidade" ou "estratégias" para o cliente
        # - Foque em entender o problema completamente
        # - Use linguagem acessível, evite jargões jurídicos
        # """

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
        """Gera resposta da IA usando Claude com o prompt mestre unificado."""
        messages = [] # O prompt de sistema agora é formatado diretamente

        for msg in state["messages"]:
            messages.append({"role": msg["role"], "content": msg["content"]})

        try:
            catalog = await triage_service._get_area_catalog() # Reutiliza a função do triage_service
            system_prompt = MASTER_INTERVIEWER_PROMPT_TEMPLATE.format(catalog_json=catalog)
            
            # Adiciona o system prompt no início do histórico da conversa
            messages_with_system = [{"role": "user", "content": system_prompt}] + messages

            response = await self.anthropic_client.messages.create(
                model="claude-3-5-sonnet-20240620",
                max_tokens=2048,
                temperature=0.7,
                # system=system_prompt, # Claude não usa 'system' como OpenAI, então incluímos como primeira mensagem
                messages=messages_with_system
            )
            
            ai_full_response = response.content[0].text
            
            # Extrair o JSON e a mensagem de texto
            json_part, text_part = self._extract_json_and_text(ai_full_response)

            if json_part:
                # Atualizar o estado com a análise interna da IA
                analysis = json_part.get("internal_analysis", {})
                state["complexity_level"] = analysis.get("complexity", state["complexity_level"])
                state["confidence_score"] = analysis.get("confidence", state["confidence_score"])
                state["strategy_recommended"] = analysis.get("strategy_recommendation", state["strategy_recommended"])
                state["estimated_area"] = analysis.get("estimated_area") # NOVO
                state["estimated_subarea"] = analysis.get("estimated_subarea") # NOVO

            # Adicionar resposta ao histórico
            state["messages"].append({
                "role": "assistant",
                "content": text_part, # Salva apenas a parte do texto para o cliente
                "timestamp": datetime.now().isoformat(),
                "internal_analysis": json_part # Salva a análise interna para auditoria
            })

            return text_part

        except Exception as e:
            print(f"Erro na geração de resposta: {e}")
            fallback_response = "Desculpe, estou com problemas técnicos. Você poderia repetir sua última mensagem?"
            state["messages"].append({
                "role": "assistant",
                "content": fallback_response,
                "timestamp": datetime.now().isoformat()
            })
            return fallback_response

    def _extract_json_and_text(self, response_text: str) -> Tuple[Optional[Dict], str]:
        """Extrai o bloco JSON e a mensagem de texto da resposta da IA."""
        try:
            json_match = re.search(r'```json\s*(\{.*?\})\s*```', response_text, re.DOTALL)
            if json_match:
                json_str = json_match.group(1)
                json_data = json.loads(json_str)
                # O texto para o usuário é o que vem depois do bloco JSON
                text_part = response_text[json_match.end():].strip()
                return json_data, text_part
            else:
                # Fallback se o formato não for encontrado
                return None, response_text
        except (json.JSONDecodeError, IndexError) as e:
            print(f"Erro ao extrair JSON da resposta da IA: {e}")
            return None, response_text

    # REMOVER a função _evaluate_complexity, pois agora está unificada
    
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

    async def generate_response(self, conversation_history: List[Dict[str, str]]) -> str:
        """
        Gera uma resposta da IA com lógica de failover.
        Tenta o provedor primário (Anthropic) e usa o backup (Llama 4) em caso de falha.
        """
        try:
            # Tentativa com o provedor primário (Claude Sonnet)
            if INTERVIEWER_MODEL_PROVIDER == "anthropic" and self.anthropic_client:
                return await self._ask_anthropic(conversation_history, INTERVIEWER_MODEL)
        except Exception as e:
            print(f"Erro com o provedor primário '{INTERVIEWER_MODEL_PROVIDER}' ({INTERVIEWER_MODEL}): {e}. Acionando failover.")
            
            # Lógica de Failover
            try:
                if INTERVIEWER_MODEL_FAILOVER_PROVIDER == "together" and self.together_client:
                     return await self._ask_llama(conversation_history, INTERVIEWER_MODEL_LLAMA_FALLBACK)
            except Exception as e_failover:
                print(f"Erro com o provedor de failover '{INTERVIEWER_MODEL_FAILOVER_PROVIDER}' ({INTERVIEWER_MODEL_LLAMA_FALLBACK}): {e_failover}.")
                return "Desculpe, nosso assistente inteligente está temporariamente indisponível. Por favor, tente novamente em alguns instantes."

        return "Erro de configuração: Nenhum provedor de IA disponível para o entrevistador."

    async def _ask_anthropic(self, conversation_history: List[Dict[str, str]], model: str) -> str:
        """Chama a API da Anthropic para obter uma resposta."""
        if not self.anthropic_client:
            raise ValueError("Cliente da Anthropic não inicializado.")

        # Lógica para chamar a API da Anthropic...
        # Exemplo:
        system_prompt = "Você é Justus, um assistente jurídico empático e eficiente..." # Seu prompt de sistema aqui
        response = await self.anthropic_client.messages.create(
            model=model,
            max_tokens=1024,
            system=system_prompt,
            messages=conversation_history
        )
        return response.content[0].text

    async def _ask_openai(self, conversation_history: List[Dict[str, str]], model: str) -> str:
        """Chama a API da OpenAI para obter uma resposta."""
        if not self.openai_client:
            raise ValueError("Cliente da OpenAI não inicializado.")

        # Lógica para chamar a API da OpenAI...
        # Exemplo:
        system_prompt = "Você é Justus, um assistente jurídico empático e eficiente..." # Seu prompt de sistema aqui
        messages_for_openai = [{"role": "system", "content": system_prompt}] + conversation_history
        
        response = await self.openai_client.chat.completions.create(
            model=model,
            max_tokens=1024,
            messages=messages_for_openai
        )
        return response.choices[0].message.content

    async def _ask_llama(self, conversation_history: List[Dict[str, str]], model: str) -> str:
        """Chama um modelo Llama 4 via Together AI para obter uma resposta."""
        if not self.together_client:
            raise ValueError("Cliente da Together AI não inicializado.")

        system_prompt = "Você é Justus, um assistente jurídico empático e eficiente..." # Seu prompt de sistema aqui
        messages_for_llama = [{"role": "system", "content": system_prompt}] + conversation_history
        
        response = await self.together_client.chat.completions.create(
            model=model,
            max_tokens=1024,
            messages=messages_for_llama
        )
        return response.choices[0].message.content


# Instância única do serviço
intelligent_interviewer_service = IntelligentInterviewerService()
