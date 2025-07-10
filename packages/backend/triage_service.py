# backend/triage_service.py
import os
import re

import anthropic
from dotenv import load_dotenv

load_dotenv()

# --- Configuração do Cliente Anthropic ---
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")


class TriageService:
    def __init__(self):
        if not ANTHROPIC_API_KEY:
            print(
                "Aviso: Chave da API da Anthropic (ANTHROPIC_API_KEY) não encontrada. Usando fallback de regex.")
            self.client = None
        else:
            self.client = anthropic.Anthropic(api_key=ANTHROPIC_API_KEY)

    async def run_triage(self, text: str) -> dict:
        """
        Executa a triagem usando o Claude ou um fallback de regex.
        """
        if self.client:
            try:
                return await self._run_claude_triage(text)
            except Exception as e:
                print(f"Erro na triagem com Claude: {e}. Usando fallback.")
                return self._run_regex_fallback(text)
        else:
            return self._run_regex_fallback(text)

    async def _run_claude_triage(self, text: str) -> dict:
        """
        Chama a API do Claude para extrair informações estruturadas do texto.
        """
        if not self.client:
            raise Exception("Cliente Anthropic não inicializado.")

        # Tool (função) que queremos que o Claude preencha com os dados extraídos
        triage_tool = {
            "name": "extract_case_details",
            "description": "Extrai detalhes estruturados de um relato de caso jurídico.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "area": {"type": "string", "description": "A principal área jurídica do caso (ex: Trabalhista, Cível, Criminal)."},
                    "subarea": {"type": "string", "description": "A subárea ou assunto específico (ex: Rescisão Indireta, Contrato de Aluguel)."},
                    "urgency_h": {"type": "integer", "description": "Estimativa da urgência em horas para uma ação inicial (ex: 24, 72)."},
                    "summary": {"type": "string", "description": "Um resumo conciso do caso em uma frase."}
                },
                "required": ["area", "subarea", "urgency_h", "summary"]
            }
        }

        message = self.client.messages.create(
            model="claude-3-5-sonnet-20240620",
            max_tokens=1024,
            tools=[triage_tool],
            tool_choice={"type": "tool", "name": "extract_case_details"},
            messages=[
                {"role": "user", "content": f"Analise o seguinte relato de caso jurídico e extraia os detalhes estruturados: '{text}'"}
            ]
        )

        # Extrai o conteúdo da ferramenta preenchida pelo modelo
        if message.content and isinstance(
                message.content, list) and message.content[0].type == 'tool_use':
            tool_result = message.content[0].input
            return {
                "area": tool_result.get("area", "Não identificado"),
                "subarea": tool_result.get("subarea", "Não identificado"),
                "urgency_h": tool_result.get("urgency_h", 72),
                "summary": tool_result.get("summary", "N/A"),
            }
        else:
            raise Exception("A resposta do LLM não continha os dados esperados.")

    def _run_regex_fallback(self, text: str) -> dict:
        """
        Fallback simples que usa regex para extrair a área jurídica.
        """
        text_lower = text.lower()
        area = "Cível"  # Padrão
        if re.search(r'trabalho|demitido|empresa|salário', text_lower):
            area = "Trabalhista"
        elif re.search(r'polícia|crime|preso|roubo', text_lower):
            area = "Criminal"
        elif re.search(r'consumidor|produto|compra|loja', text_lower):
            area = "Consumidor"

        return {
            "area": area,
            "subarea": "A ser definido",
            "urgency_h": 72,  # Urgência padrão
            "summary": text[:150]  # Pega os primeiros 150 caracteres como resumo
        }


# Instância única para ser usada na aplicação
triage_service = TriageService()
