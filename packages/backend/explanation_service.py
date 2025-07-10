# backend/explanation_service.py
import os

import anthropic
from dotenv import load_dotenv

load_dotenv()

# --- Configuração do Cliente Anthropic ---
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")


class ExplanationService:
    def __init__(self):
        if not ANTHROPIC_API_KEY:
            print("Aviso: Chave da API da Anthropic (ANTHROPIC_API_KEY) não encontrada.")
            self.client = None
        else:
            self.client = anthropic.Anthropic(api_key=ANTHROPIC_API_KEY)

    async def generate_explanation(self, case_summary: str, lawyer_data: dict) -> str:
        """
        Gera uma explicação concisa do motivo pelo qual um advogado é um bom match.
        """
        if not self.client:
            return "O serviço de IA para gerar explicações está indisponível no momento."

        prompt = f"""
        Você é um assistente jurídico que ajuda clientes a entenderem por que um advogado é uma boa escolha para seu caso.

        Resumo do Caso do Cliente:
        "{case_summary}"

        Dados do Advogado:
        - Nome: {lawyer_data.get('nome', 'N/A')}
        - Score de Match (Fair): {lawyer_data.get('fair', 0):.2f}
        - Score de Qualificação (Q): {lawyer_data.get('features', {}).get('Q', 0):.2f}
        - Score de Similaridade de Casos (S): {lawyer_data.get('features', {}).get('S', 0):.2f}
        - Taxa de Sucesso (T): {lawyer_data.get('features', {}).get('T', 0):.2f}
        - Distância: {lawyer_data.get('distance_km', 0):.1f} km

        Tarefa:
        Com base nos dados acima, escreva uma explicação curta (2-3 frases, em markdown) para o cliente, destacando os 2 ou 3 pontos mais fortes do advogado para este caso específico. Use uma linguagem clara e positiva.
        Exemplo: "Dr(a). [Nome] parece uma ótima opção! Com uma alta taxa de sucesso em casos como o seu e excelentes qualificações na área, ele(a) está bem preparado(a) para te ajudar. Além disso, seu escritório fica próximo a você."
        """

        try:
            message = self.client.messages.create(
                model="claude-3-haiku-20240307",
                max_tokens=256,
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )
            return message.content[0].text if message.content else "Não foi possível gerar uma explicação."
        except Exception as e:
            print(f"Erro ao gerar explicação com Claude: {e}")
            return "Houve um erro ao gerar a explicação. Tente novamente."


# Instância única
explanation_service = ExplanationService()
