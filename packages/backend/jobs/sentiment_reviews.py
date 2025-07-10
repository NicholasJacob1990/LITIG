#!/usr/bin/env python3
# backend/jobs/sentiment_reviews.py
"""
Job para análise de sentimento de reviews dos advogados.
Calcula kpi_softskill baseado na polaridade média dos comentários.

Features v2.2:
- Análise de sentimento usando VADER (otimizado para português)
- Score de soft-skills (0-1) baseado em polaridade média
- Processamento de reviews em lotes para eficiência
"""
import asyncio
import json
import logging
import os
import re
import sys
from datetime import datetime, timedelta
from statistics import mean
from typing import Dict, List, Optional, Tuple

# Adiciona o diretório raiz ao path para importações
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

try:
    import nltk
    from celery import shared_task
    from dotenv import load_dotenv
    from nltk.sentiment import SentimentIntensityAnalyzer

    from backend.metrics import job_executions_total
    from supabase import Client, create_client
except ImportError as e:
    print(f"Dependência faltando: {e}")
    print("Instale com: pip install supabase python-dotenv nltk")
    sys.exit(1)

# --- Configuração ---
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
SOFT_SKILL_THRESHOLD = float(os.getenv("SOFT_SKILL_THRESHOLD", "0.4"))

# Configurar logging estruturado
logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger(__name__)

# Analyzer global para eficiência
analyzer = None

sb: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


def get_supabase_client() -> Client:
    """Cria e retorna um cliente Supabase."""
    if not all([SUPABASE_URL, SUPABASE_SERVICE_KEY]):
        raise ValueError("Variáveis de ambiente do Supabase não configuradas.")
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


def setup_sentiment_analyzer():
    """Configura o analisador de sentimento."""
    global analyzer
    if analyzer is None:
        try:
            # Download dos dados necessários do NLTK
            nltk.download('vader_lexicon', quiet=True)
            analyzer = SentimentIntensityAnalyzer()
            logger.info("Analisador de sentimento configurado com sucesso")
        except Exception as e:
            logger.error(f"Erro ao configurar analisador: {e}")
            raise
    return analyzer


def preprocess_review_text(text: str) -> str:
    """
    Pré-processa o texto da review para análise de sentimento.
    """
    if not text:
        return ""

    # Converter para minúsculas
    text = text.lower()

    # Remover caracteres especiais excessivos
    text = re.sub(r'[!]{2,}', '!', text)
    text = re.sub(r'[?]{2,}', '?', text)
    text = re.sub(r'[.]{2,}', '.', text)

    # Remover URLs
    text = re.sub(r'http\S+|www\S+', '', text)

    # Remover espaços excessivos
    text = re.sub(r'\s+', ' ', text).strip()

    return text


def analyze_sentiment(text: str) -> Dict[str, float]:
    """
    Analisa o sentimento de um texto usando VADER.
    Retorna scores de polaridade.
    """
    if not text:
        return {"compound": 0.0, "pos": 0.0, "neu": 0.0, "neg": 0.0}

    analyzer = setup_sentiment_analyzer()
    processed_text = preprocess_review_text(text)

    try:
        scores = analyzer.polarity_scores(processed_text)
        return scores
    except Exception as e:
        logger.warning(f"Erro na análise de sentimento: {e}")
        return {"compound": 0.0, "pos": 0.0, "neu": 0.0, "neg": 0.0}


def extract_soft_skill_indicators(text: str) -> List[str]:
    """
    Extrai indicadores de soft skills do texto da review.
    """
    if not text:
        return []

    # Padrões para soft skills positivas
    positive_patterns = [
        r'(?i)\b(atencioso|atenciosa|gentil|educado|educada|respeitoso|respeitosa)\b',
        r'(?i)\b(comunicativo|comunicativa|claro|clara|objetivo|objetiva)\b',
        r'(?i)\b(empático|empática|compreensivo|compreensiva|paciente)\b',
        r'(?i)\b(profissional|dedicado|dedicada|comprometido|comprometida)\b',
        r'(?i)\b(pontual|responsável|confiável|organizado|organizada)\b',
        r'(?i)\b(proativo|proativa|iniciativa|liderança|colaborativo|colaborativa)\b',
    ]

    # Padrões para soft skills negativas
    negative_patterns = [
        r'(?i)\b(rude|grosseiro|grosseira|mal[-\s]educado|mal[-\s]educada)\b',
        r'(?i)\b(confuso|confusa|desorganizado|desorganizada|impaciente)\b',
        r'(?i)\b(irresponsável|não[-\s]confiável|despreparado|despreparada)\b',
        r'(?i)\b(arrogante|prepotente|inflexível|teimoso|teimosa)\b',
    ]

    indicators = []

    # Buscar indicadores positivos
    for pattern in positive_patterns:
        matches = re.findall(pattern, text)
        indicators.extend([f"positive_{match}" for match in matches])

    # Buscar indicadores negativos
    for pattern in negative_patterns:
        matches = re.findall(pattern, text)
        indicators.extend([f"negative_{match}" for match in matches])

    return indicators


def calculate_soft_skill_score(reviews: List[Dict]) -> float:
    """
    Calcula score de soft skills baseado nas reviews.
    Retorna valor entre 0 e 1.
    """
    if not reviews:
        return 0.0

    sentiment_scores = []
    soft_skill_indicators = []

    for review in reviews:
        comment = review.get("comment", "")
        if not comment:
            continue

        # Análise de sentimento
        sentiment = analyze_sentiment(comment)
        sentiment_scores.append(sentiment["compound"])

        # Indicadores de soft skills
        indicators = extract_soft_skill_indicators(comment)
        soft_skill_indicators.extend(indicators)

    if not sentiment_scores:
        return 0.0

    # Score base: média dos sentimentos (normalizado 0-1)
    avg_sentiment = mean(sentiment_scores)
    base_score = (avg_sentiment + 1) / 2  # Normalizar de [-1,1] para [0,1]

    # Ajuste baseado em indicadores específicos
    positive_indicators = sum(
        1 for ind in soft_skill_indicators if ind.startswith("positive_"))
    negative_indicators = sum(
        1 for ind in soft_skill_indicators if ind.startswith("negative_"))

    # Bonus/penalidade baseado em indicadores
    indicator_adjustment = 0.0
    if positive_indicators > 0:
        indicator_adjustment += min(positive_indicators * 0.05, 0.2)  # Max +0.2
    if negative_indicators > 0:
        indicator_adjustment -= min(negative_indicators * 0.05, 0.2)  # Max -0.2

    final_score = base_score + indicator_adjustment
    return max(0.0, min(1.0, final_score))


async def process_lawyer_reviews(supabase: Client, lawyer_id: str) -> bool:
    """
    Processa reviews de um advogado e calcula soft skill score.
    """
    try:
        # Buscar reviews do advogado
        reviews_response = supabase.table("reviews")\
            .select("comment, rating, created_at")\
            .eq("lawyer_id", lawyer_id)\
            .execute()

        reviews = reviews_response.data
        if not reviews:
            logger.info(json.dumps({
                "event": "no_reviews_found",
                "lawyer_id": lawyer_id
            }))
            return False

        # Calcular soft skill score
        soft_skill_score = calculate_soft_skill_score(reviews)

        # Atualizar advogado
        update_data = {
            "kpi_softskill": soft_skill_score
        }

        supabase.table("lawyers").update(update_data).eq("id", lawyer_id).execute()

        logger.info(json.dumps({
            "event": "soft_skill_updated",
            "lawyer_id": lawyer_id,
            "soft_skill_score": soft_skill_score,
            "reviews_count": len(reviews),
            "avg_rating": mean([r.get("rating", 0) for r in reviews if r.get("rating")])
        }))

        return True

    except Exception as e:
        logger.error(json.dumps({
            "event": "soft_skill_error",
            "lawyer_id": lawyer_id,
            "error": str(e)
        }))
        return False


async def process_all_lawyers():
    """
    Processa soft skills de todos os advogados com reviews.
    """
    start_time = datetime.now()
    logger.info(json.dumps({
        "event": "job_started",
        "job": "sentiment_reviews",
        "timestamp": start_time.isoformat()
    }))

    try:
        supabase = get_supabase_client()

        # Buscar advogados que têm reviews
        lawyers_response = supabase.table("lawyers")\
            .select("id")\
            .execute()

        lawyers = lawyers_response.data
        if not lawyers:
            logger.info(json.dumps({"event": "no_lawyers_found"}))
            return

        total_processed = 0
        total_updated = 0

        # Processar em lotes
        batch_size = 20
        for i in range(0, len(lawyers), batch_size):
            batch = lawyers[i:i + batch_size]
            tasks = [process_lawyer_reviews(supabase, lawyer["id"]) for lawyer in batch]
            results = await asyncio.gather(*tasks)

            total_processed += len(results)
            total_updated += sum(1 for r in results if r)

            # Pausa entre lotes
            await asyncio.sleep(0.5)

        logger.info(json.dumps({
            "event": "job_completed",
            "total_processed": total_processed,
            "total_updated": total_updated,
            "duration_seconds": (datetime.now() - start_time).total_seconds()
        }))

    except Exception as e:
        logger.error(json.dumps({
            "event": "job_error",
            "error": str(e)
        }))


def analyze_reviews(reviews: List[Dict[str, str]]) -> List[Dict[str, str]]:
    """Analisa sentimento de uma lista de reviews."""
    analyzed_reviews = []
    for review in reviews:
        comment = review.get('comment', '')
        if not comment:
            continue

        sentiment_result = analyze_sentiment(comment)
        compound_score = sentiment_result.get('compound', 0.0)

        # Classificar sentimento baseado no compound score
        if compound_score >= 0.05:
            sentiment = 'positivo'
            confidence = min(abs(compound_score), 1.0)
        elif compound_score <= -0.05:
            sentiment = 'negativo'
            confidence = min(abs(compound_score), 1.0)
        else:
            sentiment = 'neutro'
            confidence = 0.5

        analyzed_reviews.append({
            'id': review.get('id'),
            'comment': comment,
            'sentiment': sentiment,
            'confidence': confidence,
            'created_at': review.get('created_at', '')
        })

    return analyzed_reviews


def _sentiment_to_softskill(reviews: List[Dict[str, str]]) -> float:
    """Converte lista de reviews analisadas em score 0-1 para soft-skills."""
    if not reviews:
        return 0.5
    # Ponderar por recência (exponencial)
    reviews_sorted = sorted(
        reviews, key=lambda r: r.get(
            'created_at', ''), reverse=True)
    scores, weights = [], []
    for i, rev in enumerate(reviews_sorted):
        sent = rev.get('sentiment')
        conf = float(rev.get('confidence', 0.7))
        if sent == 'positivo':
            val = conf
        elif sent == 'negativo':
            val = -conf
        else:
            val = 0.0
        scores.append(val)
        weights.append(0.5 ** i)
    weighted = sum(s * w for s, w in zip(scores, weights)) / sum(weights)
    return max(0, min(1, (weighted + 1) / 2))


@shared_task(name="backend.jobs.sentiment_reviews.update_softskill", bind=True)
def update_softskill(self):
    """Task Celery: recalcula kpi_softskill para todos os advogados."""
    job_name = "update_softskill"
    try:
        logger.info("Iniciando cálculo de soft-skills…")
        since = (datetime.utcnow() - timedelta(days=90)).isoformat()
        lawyers = sb.table("lawyers").select("id").execute().data or []
        for lw in lawyers:
            lw_id = lw['id']
            rev_rows = sb.table("reviews").select("id, comment, created_at").eq(
                "lawyer_id", lw_id).gte("created_at", since).execute().data or []
            # Analisar sentimento em lote
            raw_reviews = [{'id': r['id'], 'comment': r['comment']} for r in rev_rows]
            analyzed = analyze_reviews(raw_reviews)
            soft = _sentiment_to_softskill(analyzed)
            sb.table("lawyers").update(
                {"kpi_softskill": soft}).eq("id", lw_id).execute()
        logger.info("Soft-skills atualizadas para %d advogados", len(lawyers))
        job_executions_total.labels(job_name=job_name, status="success").inc()
        return "success"
    except Exception as exc:
        logger.exception("Erro em update_softskill: %s", exc)
        job_executions_total.labels(job_name=job_name, status="failed").inc()
        raise self.retry(exc=exc, countdown=600, max_retries=3)


if __name__ == "__main__":
    asyncio.run(process_all_lawyers())
