# backend/services/triage_router_service.py
import re
from typing import Literal

Strategy = Literal["simple", "failover", "ensemble"]


class TriageRouterService:
    def __init__(self):
        self.complex_keywords = [
            'liminar', 'recurso', 'contrato internacional', 'múltiplas partes',
            'herança', 'societário', 'recuperação judicial', 'falência',
            'propriedade intelectual', 'patente', 'marca registrada',
            'fusão', 'aquisição', 'reestruturação', 'due diligence',
            'compliance', 'regulatório', 'arbitragem', 'mediação complexa',
            'joint venture', 'consórcio', 'licenciamento', 'franchising',
            'operação estruturada', 'derivativos', 'securitização',
            'projeto de lei', 'norma técnica', 'certificação'
        ]
        self.simple_keywords = [
            'multa de trânsito', 'atraso de voo', 'problema com produto',
            'cobrança indevida', 'nome sujo', 'cancelamento de compra',
            'batida de carro', 'vizinho barulhento', 'ruído excessivo',
            'animal de estimação', 'conta incorreta', 'entrega atrasada',
            'defeito simples', 'garantia básica', 'devolução de compra',
            'cadastro incorreto', 'cobrança duplicada', 'serviço não prestado'
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

        # Critério 3: Tamanho do texto e densidade de informações
        if len(text) > 1500:
            print("Complexidade detectada: ENSEMBLE (texto muito longo)")
            return "ensemble"
        elif len(text) > 800:
            print("Complexidade detectada: FAILOVER (texto médio)")
            return "failover"

        # Critério 4: Contagem de entidades e conceitos jurídicos
        legal_concepts = ['contrato', 'acordo', 'processo', 'ação', 'direito', 'lei', 'norma', 'regulamento']
        concept_count = sum(1 for concept in legal_concepts if concept in text_lower)
        
        if concept_count >= 4:
            print("Complexidade detectada: ENSEMBLE (múltiplos conceitos jurídicos)")
            return "ensemble"
        elif concept_count >= 2:
            print("Complexidade detectada: FAILOVER (conceitos jurídicos moderados)")
            return "failover"

        # Se não se encaixa em nenhum critério específico, usa estratégia simples
        print("Complexidade detectada: SIMPLE (padrão)")
        return "simple"


# Instância única
triage_router_service = TriageRouterService()
