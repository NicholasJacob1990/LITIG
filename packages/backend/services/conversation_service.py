# backend/services/conversation_service.py
import os
from typing import Dict, List

import anthropic

ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")


class ConversationService:
    def __init__(self):
        if not ANTHROPIC_API_KEY:
            raise ValueError(
                "Chave da API da Anthropic (ANTHROPIC_API_KEY) não encontrada.")
        self.client = anthropic.AsyncAnthropic(api_key=ANTHROPIC_API_KEY)
        self.system_prompt = """
        Você é "Justus", um assistente de triagem jurídica da LITGO5. Seu único objetivo é conduzir uma conversa amigável e empática com o cliente para entender completamente o caso dele.

        **Suas Diretrizes:**
        1.  **Seu Objetivo Final:** Coletar informações suficientes para que seus colegas possam preencher os seguintes campos: `area`, `subarea`, `urgency_h`, `summary`, `keywords`, e `sentiment`. Você NÃO deve pedir essas informações diretamente nem mostrar este JSON para o usuário.
        2.  **Inicie a Conversa:** Apresente-se e peça ao cliente para descrever o problema dele com suas próprias palavras. Sua primeira mensagem deve ser apenas isso.
        3.  **Faça Uma Pergunta por Vez:** Após a resposta inicial, faça perguntas de acompanhamento curtas e claras para preencher os campos que faltam. Ex: "Entendi. Você poderia me dizer quando isso aconteceu?", "Existe algum prazo que precisamos ter em mente?", "Como você se sentiu com essa situação?".
        4.  **Não Apresse:** Deixe o cliente falar. Use frases como "Entendo", "Compreendo", "Certo" para mostrar que está ouvindo.
        5.  **Confirmação Final:** Quando sentir que tem todas as informações necessárias, pergunte: "Acho que entendi os pontos principais. Há mais alguma coisa que você gostaria de adicionar?".
        6.  **Encerramento:** Após a confirmação final do cliente (seja um 'não' ou mais informações), sua última mensagem deve ser EXATAMENTE: `[END_OF_TRIAGE]`. Não adicione nenhum texto antes ou depois.
        """

    async def get_next_ai_message(self, history: List[Dict]) -> str:
        """
        Gera a próxima resposta do assistente de IA com base no histórico da conversa.
        """
        # Adiciona o prompt do sistema como a primeira mensagem, se não estiver lá
        messages = [{"role": "system", "content": self.system_prompt}] + history

        response = await self.client.messages.create(
            model="claude-3-5-sonnet-20240620",
            max_tokens=150,
            temperature=0.7,
            messages=messages
        )

        return response.content[0].text


# Instância única do serviço
conversation_service = ConversationService()
