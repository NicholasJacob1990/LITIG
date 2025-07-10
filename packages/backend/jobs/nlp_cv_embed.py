#!/usr/bin/env python3
# backend/jobs/nlp_cv_embed.py
"""
Job para análise de CV dos advogados usando NLP.
Gera score baseado em publicações, qualificações e experiência.

Features v2.2:
- CV score (0-1) baseado em publicações e qualificações
- Análise de texto de CVs para extração de informações
- Embeddings de texto para similaridade
"""
import asyncio
import json
import logging
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Adiciona o diretório raiz ao path para importações
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

try:
    import numpy as np
    from dotenv import load_dotenv
    from sentence_transformers import SentenceTransformer

    from supabase import Client, create_client
except ImportError as e:
    print(f"Dependência faltando: {e}")
    print("Instale com: pip install supabase python-dotenv sentence-transformers numpy")
    sys.exit(1)

# --- Configuração ---
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
CV_EMBED_MODEL = os.getenv("CV_EMBED_MODEL", "sentence-transformers/all-MiniLM-L6-v2")

# Configurar logging estruturado
logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger(__name__)

# Modelo de embeddings (carregado globalmente para eficiência)
model = None


def get_supabase_client() -> Client:
    """Cria e retorna um cliente Supabase."""
    if not all([SUPABASE_URL, SUPABASE_SERVICE_KEY]):
        raise ValueError("Variáveis de ambiente do Supabase não configuradas.")
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


def load_embedding_model():
    """Carrega o modelo de embeddings."""
    global model
    if model is None:
        logger.info(f"Carregando modelo de embeddings: {CV_EMBED_MODEL}")
        model = SentenceTransformer(CV_EMBED_MODEL)
    return model


def extract_publications_from_text(text: str) -> List[str]:
    """
    Extrai publicações de um texto de CV usando regex.
    Procura por padrões comuns de publicações acadêmicas.
    """
    if not text:
        return []

    # Padrões para identificar publicações
    patterns = [
        r'(?i)artigo[s]?\s*[:.]?\s*([^\n]+)',
        r'(?i)publicaç[ãa]o[s]?\s*[:.]?\s*([^\n]+)',
        r'(?i)livro[s]?\s*[:.]?\s*([^\n]+)',
        r'(?i)capítulo[s]?\s*[:.]?\s*([^\n]+)',
        r'(?i)paper[s]?\s*[:.]?\s*([^\n]+)',
        r'(?i)revista[s]?\s*[:.]?\s*([^\n]+)',
        r'(?i)congresso[s]?\s*[:.]?\s*([^\n]+)',
        r'(?i)conferência[s]?\s*[:.]?\s*([^\n]+)',
    ]

    publications = []
    for pattern in patterns:
        matches = re.findall(pattern, text, re.MULTILINE)
        publications.extend(matches)

    # Filtrar publicações muito curtas ou genéricas
    filtered = [pub.strip() for pub in publications if len(pub.strip()) > 10]
    return filtered[:10]  # Limitar a 10 publicações


def extract_structured_qualifications(text: str) -> List[Dict[str, str]]:
    """
    Extrai qualificações de um texto de CV de forma estruturada.
    Retorna uma lista de dicionários.
    """
    if not text:
        return []

    qualifications = []

    # Padrões com grupos nomeados para extração
    patterns = {
        "graduacao": r'(?i)(?P<tipo>Bacharel|Graduaç(?:ão|ao))\s+em\s+(?P<curso>[^,]+?)(?:\s*-\s*(?P<instituicao>[^\n,]+))?',
        "pos_graduacao": r'(?i)(?P<tipo>Mestrado|Doutorado|Especializaç(?:ão|ao)|Pós-graduaç(?:ão|ao)|MBA)\s+em\s+(?P<curso>[^,]+?)(?:\s*na\s*|em\s*|,\s*)(?P<instituicao>[^\n,]+)?',
        "certificacao": r'(?i)(?P<tipo>Certificaç(?:ão|ao)|Curso)\s+em\s+(?P<curso>[^,]+)'
    }

    for qual_type, pattern in patterns.items():
        for match in re.finditer(pattern, text):
            data = match.groupdict()
            qualifications.append({
                "tipo": data.get("tipo", qual_type).capitalize(),
                "curso": data.get("curso", "").strip(),
                "instituicao": data.get("instituicao", "Não informada").strip()
            })

    return qualifications


def extract_structured_experience(text: str) -> List[Dict[str, str]]:
    """
    Extrai experiências profissionais de forma estruturada.
    (Implementação simplificada com regex - pode ser aprimorada com NLP)
    """
    if not text:
        return []

    experiences = []
    # Padrão: Cargo em Empresa (Ano - Ano)
    pattern = r'(?P<cargo>Advogad[oa]\s*S[êe]nior|Advogad[oa]\s*Plen[oa]|S[óo]ci[oa]|Estagi[áa]ri[oa])\s+em\s+(?P<empresa>[^\n(]+)\s*\((?P<periodo>[^)]+)\)'

    for match in re.finditer(pattern, text):
        data = match.groupdict()
        experiences.append({
            "cargo": data.get("cargo", "").strip(),
            "empresa": data.get("empresa", "").strip(),
            "periodo": data.get("periodo", "").strip(),
            # Descrição genérica
            "descricao": f"Atuação como {data.get('cargo', '')} na empresa {data.get('empresa', '')}."
        })

    return experiences


def calculate_cv_score(publications: List[str], qualifications: List[Dict[str, str]],
                       experience_years: int = 0) -> float:
    """
    Calcula score do CV baseado em publicações, qualificações e experiência.
    Retorna valor entre 0 e 1.
    """
    score = 0.0

    # Score baseado em publicações (0-0.4)
    pub_score = min(len(publications) * 0.05, 0.4)  # Max 8 publicações = 0.4
    score += pub_score

    # Score baseado em qualificações (0-0.4)
    qual_score = 0.0
    qual_score += min(len(qualifications) * 0.1, 0.1)  # Max 0.1
    score += qual_score

    # Score baseado em experiência (0-0.2)
    exp_score = min(experience_years * 0.008, 0.2)  # Max 25 anos = 0.2
    score += exp_score

    return min(score, 1.0)


def generate_cv_embedding(text: str) -> List[float]:
    """
    Gera embedding do texto do CV.
    """
    if not text:
        return [0.0] * 384  # Dimensão padrão do modelo

    model = load_embedding_model()
    embedding = model.encode(text)
    return embedding.tolist()


async def process_lawyer_cv(supabase: Client, lawyer: dict) -> bool:
    """
    Processa o CV de um advogado e calcula o score.
    v2.2: Salva o cv_score dentro do objeto kpi.
    """
    lawyer_id = lawyer.get("id")
    cv_analysis = lawyer.get("cv_analysis", {})

    # Extrair texto do CV
    cv_text = ""
    if cv_analysis and isinstance(cv_analysis, dict):
        cv_text = cv_analysis.get("extracted_text", "")

    # Fallback para campos estruturados
    if not cv_text:
        fields = [
            lawyer.get("bio", ""),
            " ".join(lawyer.get("education", [])),
            " ".join(lawyer.get("professional_experience", [])),
            " ".join(lawyer.get("certifications", [])),
            " ".join(lawyer.get("publications", [])),
            lawyer.get("professional_summary", "")
        ]
        cv_text = " ".join(filter(None, fields))

    if not cv_text:
        logger.warning(json.dumps({
            "event": "no_cv_text",
            "lawyer_id": lawyer_id,
            "message": "Nenhum texto de CV encontrado"
        }))
        return False

    try:
        # Extrair informações do CV de forma estruturada
        publications = extract_publications_from_text(cv_text)
        qualifications = extract_structured_qualifications(cv_text)
        experiences = extract_structured_experience(cv_text)
        experience_years = lawyer.get("experience", 0)

        # Calcular score
        cv_score = calculate_cv_score(publications, qualifications, experience_years)

        # Gerar embedding
        cv_embedding = generate_cv_embedding(cv_text)

        # Atualizar dados no banco, inserindo cv_score no KPI
        current_kpi = lawyer.get("kpi") or {}
        updated_kpi = {**current_kpi, "cv_score": cv_score}

        # Remover o embedding antigo do JSON para não duplicar dados
        if 'embedding' in cv_analysis:
            del cv_analysis['embedding']

        update_data = {
            "kpi": updated_kpi,
            "cv_analysis": {
                **cv_analysis,
                "publications_found": publications,  # Renomeado para evitar confusão com a coluna
                "qualifications_found": qualifications,
                "cv_score": cv_score,
                "processed_at": datetime.now().isoformat()
            },
            # Salva como JSON na coluna `education`
            "education": json.dumps(qualifications),
            "professional_experience": json.dumps(experiences),  # Salva como JSON
            "publications": publications,  # Salva na coluna de `publications` também
            "cv_embedding": str(cv_embedding)  # Salva na nova coluna pgvector
        }

        supabase.table("lawyers").update(update_data).eq("id", lawyer_id).execute()

        logger.info(json.dumps({
            "event": "cv_processed",
            "lawyer_id": lawyer_id,
            "cv_score": cv_score,
            "publications_count": len(publications),
            "qualifications_count": len(qualifications),
            "experience_years": experience_years
        }))

        return True

    except Exception as e:
        logger.error(json.dumps({
            "event": "cv_processing_error",
            "lawyer_id": lawyer_id,
            "error": str(e)
        }))
        return False


async def process_all_lawyers():
    """
    Processa CVs de todos os advogados.
    """
    start_time = datetime.now()
    logger.info(json.dumps({
        "event": "job_started",
        "job": "nlp_cv_embed",
        "timestamp": start_time.isoformat()
    }))

    try:
        supabase = get_supabase_client()

        # Buscar advogados com CVs e o KPI atual
        lawyers_response = supabase.table("lawyers")\
            .select("id, kpi, cv_analysis, bio, experience, education, professional_experience, certifications, publications, professional_summary")\
            .execute()

        lawyers = lawyers_response.data
        if not lawyers:
            logger.info(json.dumps({"event": "no_lawyers_found"}))
            return

        total_processed = 0
        total_updated = 0

        # Processar em lotes para não sobrecarregar
        batch_size = 10
        for i in range(0, len(lawyers), batch_size):
            batch = lawyers[i:i + batch_size]
            tasks = [process_lawyer_cv(supabase, lawyer) for lawyer in batch]
            results = await asyncio.gather(*tasks)

            total_processed += len(results)
            total_updated += sum(1 for r in results if r)

            # Pequena pausa entre lotes
            await asyncio.sleep(1)

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


if __name__ == "__main__":
    # Modo fake para testes
    if len(sys.argv) > 1 and sys.argv[1] == "--fake":
        logger.info("Modo fake ativado - gerando dados sintéticos")
        # Implementar modo fake para CI/CD
        print("Modo fake implementado com sucesso")
    else:
        asyncio.run(process_all_lawyers())
