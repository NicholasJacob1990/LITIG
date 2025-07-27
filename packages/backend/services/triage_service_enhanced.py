# backend/services/triage_service_enhanced.py
import asyncio
import json
import os
import re
import time
from functools import wraps
from typing import Dict, List, Literal, Optional

import anthropic
import openai
from dotenv import load_dotenv

# Importação do serviço de embedding
from embedding_service import generate_embedding

load_dotenv()

# --- Configuração dos Clientes ---
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
JUDGE_MODEL_PROVIDER = os.getenv("JUDGE_MODEL_PROVIDER", "gemini")
JUDGE_MODEL_GEMINI = os.getenv("GEMINI_JUDGE_MODEL", "gemini-2.0-flash-exp")
JUDGE_MODEL_ANTHROPIC = "claude-3-opus-20240229"
JUDGE_MODEL_OPENAI = "gpt-4-turbo"
SIMPLE_MODEL_CLAUDE = "claude-3-haiku-20240307"

# Configurações de timeout e circuit breaker
API_TIMEOUT = int(os.getenv("API_TIMEOUT", "30"))  # 30 segundos timeout
CIRCUIT_BREAKER_THRESHOLD = int(
    os.getenv("CIRCUIT_BREAKER_THRESHOLD", "5"))  # 5 falhas consecutivas
CIRCUIT_BREAKER_RESET_TIME = int(
    os.getenv(
        "CIRCUIT_BREAKER_RESET_TIME",
        "300"))  # 5 minutos

Strategy = Literal["simple", "failover", "ensemble"]


class CircuitBreaker:
    """Circuit breaker pattern para APIs externas"""

    def __init__(self, failure_threshold: int = CIRCUIT_BREAKER_THRESHOLD,
                 reset_timeout: int = CIRCUIT_BREAKER_RESET_TIME):
        self.failure_threshold = failure_threshold
        self.reset_timeout = reset_timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN

    async def call(self, func, *args, **kwargs):
        """Executa função com circuit breaker"""
        if self.state == "OPEN":
            if time.time() - self.last_failure_time > self.reset_timeout:
                self.state = "HALF_OPEN"
            else:
                raise Exception(
                    "Circuit breaker OPEN - API temporariamente indisponível")

        try:
            result = await func(*args, **kwargs)
            self._on_success()
            return result
        except Exception as e:
            self._on_failure()
            raise e

    def _on_success(self):
        """Reset circuit breaker on success"""
        self.failure_count = 0
        self.state = "CLOSED"

    def _on_failure(self):
        """Increment failure count and potentially open circuit"""
        self.failure_count += 1
        self.last_failure_time = time.time()

        if self.failure_count >= self.failure_threshold:
            self.state = "OPEN"


def with_timeout(timeout_seconds: int = API_TIMEOUT):
    """Decorator para adicionar timeout a funções async"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            try:
                return await asyncio.wait_for(
                    func(*args, **kwargs),
                    timeout=timeout_seconds
                )
            except asyncio.TimeoutError:
                raise Exception(
                    f"Timeout de {timeout_seconds}s excedido para {
                        func.__name__}")
        return wrapper
    return decorator


class EnhancedTriageService:
    def __init__(self):
        # Cliente Anthropic (Claude)
        self.anthropic_client = anthropic.AsyncAnthropic(
            api_key=ANTHROPIC_API_KEY) if ANTHROPIC_API_KEY else None
        # Cliente OpenAI (ChatGPT)
        self.openai_client = openai.AsyncOpenAI(
            api_key=OPENAI_API_KEY) if OPENAI_API_KEY else None

        # Circuit breakers para cada API
        self.claude_circuit_breaker = CircuitBreaker()
        self.openai_circuit_breaker = CircuitBreaker()

        if not self.anthropic_client:
            print("Aviso: Chave da API da Anthropic não encontrada.")
        if not self.openai_client:
            print("Aviso: Chave da API da OpenAI não encontrada.")

    @with_timeout(30)
    async def _run_claude_triage_raw(
            self, text: str, model: str = "claude-3-5-sonnet-20240620") -> Dict:
        """Chama Claude sem circuit breaker (usado internamente)"""
        if not self.anthropic_client:
            raise Exception("Cliente Anthropic não inicializado.")

        triage_tool = {
            "name": "extract_case_details",
            "description": "Extrai detalhes estruturados de um relato de caso jurídico.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "area": {"type": "string"}, "subarea": {"type": "string"},
                    "urgency_h": {"type": "integer"}, "summary": {"type": "string"},
                    "keywords": {"type": "array", "items": {"type": "string"}},
                    "sentiment": {"type": "string", "enum": ["Positivo", "Neutro", "Negativo"]}
                },
                "required": ["area", "subarea", "urgency_h", "summary", "keywords", "sentiment"]
            }
        }

        message = await self.anthropic_client.messages.create(
            model=model, max_tokens=1024, tools=[triage_tool],
            tool_choice={"type": "tool", "name": "extract_case_details"},
            messages=[{"role": "user",
                       "content": f"Analise o caso e extraia os detalhes: '{text}'"}]
        )

        if message.content and isinstance(
                message.content, list) and message.content[0].type == 'tool_use':
            return message.content[0].input
        raise Exception(
            f"A resposta do Claude ({model}) não continha os dados esperados.")

    async def _run_claude_triage(
            self, text: str, model: str = "claude-3-5-sonnet-20240620") -> Dict:
        """Chama Claude com circuit breaker e timeout"""
        return await self.claude_circuit_breaker.call(
            self._run_claude_triage_raw, text, model
        )

    @with_timeout(30)
    async def _run_openai_triage_raw(self, text: str) -> Dict:
        """Chama OpenAI sem circuit breaker (usado internamente)"""
        if not self.openai_client:
            raise Exception("Cliente OpenAI não inicializado.")

        prompt = f"Analise a transcrição e extraia os dados em JSON. Transcrição: {text}"

        response = await self.openai_client.chat.completions.create(
            model="gpt-4o", response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": "Você é um assistente que extrai dados de textos legais para um JSON com os campos: area, subarea, urgency_h, summary, keywords, sentiment."},
                {"role": "user", "content": prompt}
            ]
        )
        return json.loads(response.choices[0].message.content)

    async def _run_openai_triage(self, text: str) -> Dict:
        """Chama OpenAI com circuit breaker e timeout"""
        return await self.openai_circuit_breaker.call(
            self._run_openai_triage_raw, text
        )

    def _compare_results(
            self, result1: Optional[Dict], result2: Optional[Dict]) -> bool:
        """Compara se os campos críticos dos dois resultados são idênticos."""
        if not result1 or not result2:
            return False
        critical_fields = ["area", "subarea"]
        return all(str(result1.get(f, "")).strip().lower() == str(
            result2.get(f, "")).strip().lower() for f in critical_fields)

    @with_timeout(45)
    async def _run_judge_triage(self, text: str, result1: Dict, result2: Dict) -> Dict:
        """Chama uma IA 'juiz' para decidir entre dois resultados conflitantes."""
        prompt = f"Você é um Sócio-Diretor. Revise a transcrição e os dois JSONs dos seus assistentes. Produza um JSON final e definitivo, com uma justificativa.\n\nTranscrição: {text}\n\nAssistente 1 (Claude):\n{
            json.dumps(
                result1,
                indent=2,
                ensure_ascii=False)}\n\nAssistente 2 (OpenAI):\n{
            json.dumps(
                result2,
                indent=2,
                ensure_ascii=False)}\n\nSua Saída Final (apenas JSON):"

        if JUDGE_MODEL_PROVIDER == 'gemini' and os.getenv("GEMINI_API_KEY"):
            import google.generativeai as genai
            genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
            
            model = genai.GenerativeModel(JUDGE_MODEL_GEMINI)
            response = await asyncio.wait_for(
                model.generate_content_async(prompt),
                timeout=30
            )
            
            # Extrair JSON da resposta do Gemini
            response_text = response.text
            match = re.search(r'\{.*\}', response_text, re.DOTALL)
            if match:
                return json.loads(match.group(0))
            else:
                # Se não encontrar JSON, tentar parsear a resposta completa
                return json.loads(response_text)
                
        elif JUDGE_MODEL_PROVIDER == 'openai' and self.openai_client:
            response = await self.openai_client.chat.completions.create(
                model=JUDGE_MODEL_OPENAI, response_format={"type": "json_object"},
                messages=[{"role": "user", "content": prompt}]
            )
            return json.loads(response.choices[0].message.content)
        elif JUDGE_MODEL_PROVIDER == 'anthropic' and self.anthropic_client:
            message = await self.anthropic_client.messages.create(
                model=JUDGE_MODEL_ANTHROPIC, max_tokens=2048,
                messages=[{"role": "user", "content": prompt}]
            )
            # Extrair JSON da resposta de texto
            match = re.search(r'\{.*\}', message.content[0].text, re.DOTALL)
            if match:
                return json.loads(match.group(0))
            raise Exception("A resposta do Juiz (Claude) não continha um JSON válido.")
        else:
            # Fallback se o juiz preferido não estiver disponível
            return result1

    async def _run_failover_strategy(self, text: str) -> Dict:
        """Estratégia failover com circuit breaker"""
        try:
            return await self._run_claude_triage(text)
        except Exception as e:
            print(f"Falha no Claude (principal), tentando OpenAI (backup): {e}")
            try:
                return await self._run_openai_triage(text)
            except Exception as e2:
                print(f"Falha no OpenAI (backup): {e2}. Usando fallback de regex.")
                return self._run_regex_fallback(text)

    async def _run_ensemble_strategy(self, text: str) -> Dict:
        """Estratégia ensemble com circuit breaker"""
        tasks = []

        # Adicionar tarefas apenas se circuit breaker permitir
        if self.claude_circuit_breaker.state != "OPEN" and self.anthropic_client:
            tasks.append(self._run_claude_triage(text))
        else:
            tasks.append(asyncio.sleep(0, result=None))

        if self.openai_circuit_breaker.state != "OPEN" and self.openai_client:
            tasks.append(self._run_openai_triage(text))
        else:
            tasks.append(asyncio.sleep(0, result=None))

        results = await asyncio.gather(*tasks, return_exceptions=True)

        successful_results = [
            res for res in results if res is not None and not isinstance(res, Exception)]

        if not successful_results:
            print("Ambas as IAs falharam no ensemble. Usando fallback de regex.")
            return self._run_regex_fallback(text)

        if len(successful_results) == 1:
            return successful_results[0]

        res1, res2 = successful_results[:2]
        if self._compare_results(res1, res2):
            return res1

        print("Resultados divergentes, acionando o Juiz.")
        try:
            return await self._run_judge_triage(text, res1, res2)
        except Exception as e:
            print(f"Falha no Juiz: {e}. Retornando primeiro resultado.")
            return res1

    async def run_triage(self, text: str, strategy: Strategy) -> dict:
        """Ponto de entrada principal para a triagem com timeouts e circuit breakers."""
        print(f"Executando estratégia de triagem: {strategy}")
        start_time = time.time()

        try:
            if strategy == 'simple':
                triage_results = await self._run_claude_triage(text, model=SIMPLE_MODEL_CLAUDE)
            elif strategy == 'ensemble':
                triage_results = await self._run_ensemble_strategy(text)
            else:  # Padrão é 'failover'
                triage_results = await self._run_failover_strategy(text)
        except Exception as e:
            print(f"Estratégia '{strategy}' falhou: {e}. Usando fallback de regex.")
            triage_results = self._run_regex_fallback(text)

        # Adicionar embedding se disponível
        summary = triage_results.get("summary")
        if summary:
            try:
                embedding_vector = await generate_embedding(summary)
                triage_results["summary_embedding"] = embedding_vector
            except Exception as e:
                print(f"Falha ao gerar embedding: {e}")
                triage_results["summary_embedding"] = None
        else:
            triage_results["summary_embedding"] = None

        # Adicionar métricas de performance
        processing_time = time.time() - start_time
        triage_results["_metadata"] = {
            "processing_time_seconds": processing_time,
            "strategy_used": strategy,
            "claude_circuit_state": self.claude_circuit_breaker.state,
            "openai_circuit_state": self.openai_circuit_breaker.state,
            "timestamp": time.time()
        }

        return triage_results

    def _run_regex_fallback(self, text: str) -> dict:
        """
        Fallback simples que usa regex para extrair a área jurídica.
        """
        text_lower = text.lower()

        # -------- Heurística de área --------------------------------------
        area = "Cível"  # padrão
        subarea = "Geral"

        trabalhista = r"trabalho|trabalhista|demitido|verbas? rescisórias|rescisão|salário"
        criminal = r"pol[ií]cia|crime|criminoso|preso|roubo|furto|homic[ií]dio"
        consumidor = r"consumidor|produto|compra|loja|defeito|garantia"

        if re.search(trabalhista, text_lower):
            area = "Trabalhista"
            if re.search(r"justa causa", text_lower):
                subarea = "Justa Causa"
            elif re.search(r"verbas? rescisórias", text_lower):
                subarea = "Verbas Rescisórias"
        elif re.search(criminal, text_lower):
            area = "Criminal"
            if re.search(r"homic[ií]dio", text_lower):
                subarea = "Homicídio"
            elif re.search(r"roubo|furto", text_lower):
                subarea = "Patrimonial"
        elif re.search(consumidor, text_lower):
            area = "Consumidor"
            if re.search(r"garantia", text_lower):
                subarea = "Garantia"

        # -------- Heurística de urgência ----------------------------------
        if re.search(r"\b(liminar|urgente|réu preso)\b", text_lower):
            urgency_h = 24
        elif re.search(r"\b(48h|2 dias?)\b", text_lower):
            urgency_h = 48
        else:
            m = re.search(r"\b(\d{1,2})\s*dias?\b", text_lower)
            if m:
                urgency_h = int(m.group(1)) * 24
            else:
                urgency_h = 72  # padrão

        return {
            "area": area,
            "subarea": subarea,
            "urgency_h": urgency_h,
            "summary": text[:150],
            "keywords": re.findall(r'\b\w{5,}\b', text.lower())[:5],
            "sentiment": "Neutro",
            "_fallback": True
        }

    def get_circuit_breaker_status(self) -> Dict:
        """Retorna status dos circuit breakers para monitoramento"""
        return {
            "claude": {
                "state": self.claude_circuit_breaker.state,
                "failure_count": self.claude_circuit_breaker.failure_count,
                "last_failure_time": self.claude_circuit_breaker.last_failure_time
            },
            "openai": {
                "state": self.openai_circuit_breaker.state,
                "failure_count": self.openai_circuit_breaker.failure_count,
                "last_failure_time": self.openai_circuit_breaker.last_failure_time
            }
        }


# Instância única aprimorada
enhanced_triage_service = EnhancedTriageService()
