# backend/embedding_service.py
import os

import openai
from dotenv import load_dotenv

load_dotenv()

# Configuração da API da OpenAI
openai.api_key = os.getenv("OPENAI_API_KEY")


async def generate_embedding(text: str) -> list[float]:
    """
    Gera um vetor de embedding para um texto usando a API da OpenAI.

    Args:
        text: O texto a ser processado.

    Returns:
        Uma lista de floats representando o vetor de embedding.

    Raises:
        Exception: Se a chamada de API da OpenAI falhar.
    """
    if not openai.api_key:
        raise ValueError(
            "A chave da API da OpenAI (OPENAI_API_KEY) não está configurada.")

    try:
        # Limpa o texto para evitar problemas com a API
        cleaned_text = text.replace("\\n", " ")

        response = openai.Embedding.create(
            model="text-embedding-3-small",
            input=cleaned_text
        )

        if response["data"] and len(response["data"]) > 0:
            return response["data"][0]["embedding"]
        else:
            raise Exception("Resposta da API de embedding inválida.")

    except Exception as e:
        print(f"Erro ao gerar embedding: {e}")
        # TODO: Adicionar um fallback ou um retry mechanism
        raise e
