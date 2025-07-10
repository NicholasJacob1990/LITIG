# backend/services/triage_router_service.py
import re
from typing import Literal

Strategy = Literal["simple", "failover", "ensemble"]


class TriageRouterService:
    def __init__(self):
        self.complex_keywords = [
            'liminar', 'recurso', 'contrato internacional', 'múltiplas partes',
            'herança', 'societário', 'recuperação judicial', 'falência',
            'propriedade intelectual', 'patente', 'marca registrada'
        ]
        self.simple_keywords = [
            'multa de trânsito', 'atraso de voo', 'problema com produto',
            'cobrança indevida', 'nome sujo', 'cancelamento de compra',
            'batida de carro', 'vizinho barulhento'
        ]

    def classify_complexity(self, text: str) -> Strategy:
        """
        Classifica a complexidade do texto e retorna a estratégia de triagem apropriada.
        """
        text_lower = text.lower()

        # Critério 1: Palavras-chave de Complexidade
        if any(keyword in text_lower for keyword in self.complex_keywords):
            print("Complexidade detectada: ENSEMBLE (palavra-chave complexa)")
            return "ensemble"

        # Critério 2: Palavras-chave de Simplicidade
        if any(keyword in text_lower for keyword in self.simple_keywords):
            print("Complexidade detectada: SIMPLE (palavra-chave simples)")
            return "simple"

        # Critério 3: Tamanho do texto
        if len(text) > 2000:
            print("Complexidade detectada: ENSEMBLE (texto longo)")
            return "ensemble"

        # Se não se encaixa em nenhum critério extremo, usa a estratégia padrão
        print("Complexidade detectada: FAILOVER (padrão)")
        return "failover"


# Instância única
triage_router_service = TriageRouterService()
