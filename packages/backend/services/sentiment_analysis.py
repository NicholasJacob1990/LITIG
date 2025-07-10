"""
Serviço de análise de sentimento para reviews e comentários.
Usa modelos pré-treinados para português e extração de tópicos.
"""
import logging
import os
from collections import Counter
from datetime import datetime
from typing import Any, Dict, List

import nltk
import torch
from transformers import pipeline

from backend.metrics import external_api_duration

logger = logging.getLogger(__name__)

# Baixar recursos NLTK necessários
try:
    nltk.download('stopwords', quiet=True)
    nltk.download('punkt', quiet=True)
except Exception as e:
    logger.warning(f"Erro ao baixar recursos NLTK: {e}")


class SentimentAnalysisService:
    """Serviço para análise de sentimento e extração de tópicos."""

    def __init__(self):
        # Usar CPU por padrão (GPU se disponível)
        device = 0 if torch.cuda.is_available() else -1

        try:
            # Modelo multilíngue que funciona bem com português
            self.sentiment_pipeline = pipeline(
                "sentiment-analysis",
                model="nlptown/bert-base-multilingual-uncased-sentiment",
                device=device
            )
            self.model_available = True
        except Exception as e:
            logger.error(f"Erro ao carregar modelo de sentimento: {e}")
            self.model_available = False
            self.sentiment_pipeline = None

        # Stopwords em português
        try:
            self.stop_words = set(nltk.corpus.stopwords.words('portuguese'))
        except BaseException:
            # Fallback manual se NLTK falhar
            self.stop_words = {
                'de', 'a', 'o', 'que', 'e', 'do', 'da', 'em', 'um', 'para',
                'é', 'com', 'não', 'uma', 'os', 'no', 'se', 'na', 'por', 'mais',
                'as', 'dos', 'como', 'mas', 'foi', 'ao', 'ele', 'das', 'tem'
            }

    def analyze_sentiment(self, text: str) -> Dict[str, Any]:
        """
        Analisa o sentimento de um texto.

        Returns:
            Dict com sentiment (positivo/neutro/negativo), confidence e detalhes
        """
        if not text or not self.model_available:
            return {
                'sentiment': 'neutro',
                'confidence': 0.0,
                'error': 'Modelo não disponível ou texto vazio'
            }

        try:
            with external_api_duration.labels(service="sentiment", operation="analyze").time():
                # O modelo retorna labels de 1-5 estrelas
                result = self.sentiment_pipeline(text[:512])[0]  # Limitar tamanho

                # Mapear estrelas para sentimento
                label = result['label']
                score = result['score']

                if '1' in label or '2' in label:
                    sentiment = 'negativo'
                elif '3' in label:
                    sentiment = 'neutro'
                else:  # 4 ou 5 estrelas
                    sentiment = 'positivo'

                return {
                    'sentiment': sentiment,
                    'confidence': score,
                    'stars': label,
                    'raw_result': result
                }

        except Exception as e:
            logger.error(f"Erro na análise de sentimento: {e}")
            return {
                'sentiment': 'neutro',
                'confidence': 0.0,
                'error': str(e)
            }

    def extract_topics(self, text: str, top_n: int = 5) -> List[str]:
        """
        Extrai os principais tópicos/palavras-chave do texto.

        Args:
            text: Texto para análise
            top_n: Número de tópicos a retornar

        Returns:
            Lista com principais palavras/tópicos
        """
        try:
            # Tokenização básica
            tokens = nltk.word_tokenize(text.lower())

            # Filtrar: apenas palavras alfabéticas, não stopwords, tamanho > 3
            tokens = [
                t for t in tokens
                if t.isalpha() and t not in self.stop_words and len(t) > 3
            ]

            # Contar frequência
            word_freq = Counter(tokens)

            # Retornar top N palavras mais frequentes
            return [word for word, freq in word_freq.most_common(top_n)]

        except Exception as e:
            logger.error(f"Erro na extração de tópicos: {e}")
            return []

    def analyze_review_batch(
            self, reviews: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Analisa múltiplas reviews em batch.

        Args:
            reviews: Lista de dicts com 'id' e 'comment'

        Returns:
            Lista de resultados com análise de cada review
        """
        results = []

        for review in reviews:
            review_id = review.get('id')
            comment = review.get('comment', '')

            if not comment:
                continue

            # Análise de sentimento
            sentiment_result = self.analyze_sentiment(comment)

            # Extração de tópicos
            topics = self.extract_topics(comment)

            # Identificar aspectos específicos mencionados
            aspects = self._extract_aspects(comment)

            results.append({
                'review_id': review_id,
                'sentiment': sentiment_result['sentiment'],
                'confidence': sentiment_result['confidence'],
                'stars': sentiment_result.get('stars'),
                'topics': topics,
                'aspects': aspects,
                'processed_at': datetime.now().isoformat()
            })

        return results

    def _extract_aspects(self, text: str) -> Dict[str, bool]:
        """
        Extrai aspectos específicos mencionados no texto.
        Útil para identificar o que foi elogiado/criticado.
        """
        text_lower = text.lower()

        aspects = {
            'atendimento': any(word in text_lower for word in
                               ['atendimento', 'atendeu', 'atencioso', 'atenção']),
            'rapidez': any(word in text_lower for word in
                           ['rápido', 'rapidez', 'agilidade', 'ágil', 'demora']),
            'comunicacao': any(word in text_lower for word in
                               ['comunicação', 'resposta', 'retorno', 'explicou']),
            'preco': any(word in text_lower for word in
                         ['preço', 'valor', 'caro', 'barato', 'custo']),
            'resultado': any(word in text_lower for word in
                             ['resultado', 'ganhou', 'perdeu', 'sucesso', 'êxito']),
            'profissionalismo': any(word in text_lower for word in
                                    ['profissional', 'competente', 'preparado'])
        }

        return {k: v for k, v in aspects.items() if v}

    def get_sentiment_summary(self, reviews: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Gera resumo estatístico dos sentimentos.

        Args:
            reviews: Lista de reviews já analisadas

        Returns:
            Estatísticas agregadas
        """
        if not reviews:
            return {
                'total': 0,
                'positivo': 0,
                'neutro': 0,
                'negativo': 0,
                'score_medio': 0.0
            }

        sentiments = [r['sentiment'] for r in reviews]

        # Calcular score médio (positivo=1, neutro=0, negativo=-1)
        scores = []
        for r in reviews:
            if r['sentiment'] == 'positivo':
                scores.append(r['confidence'])
            elif r['sentiment'] == 'negativo':
                scores.append(-r['confidence'])
            else:
                scores.append(0)

        score_medio = sum(scores) / len(scores) if scores else 0

        return {
            'total': len(reviews),
            'positivo': sentiments.count('positivo'),
            'neutro': sentiments.count('neutro'),
            'negativo': sentiments.count('negativo'),
            'score_medio': score_medio,
            'percentual_positivo': sentiments.count('positivo') / len(sentiments) * 100
        }


# Instância singleton
sentiment_service = SentimentAnalysisService()


# Funções de conveniência
def analyze_sentiment(text: str) -> Dict[str, Any]:
    """Analisa sentimento de um texto."""
    return sentiment_service.analyze_sentiment(text)


def analyze_reviews(reviews: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Analisa batch de reviews."""
    return sentiment_service.analyze_review_batch(reviews)
