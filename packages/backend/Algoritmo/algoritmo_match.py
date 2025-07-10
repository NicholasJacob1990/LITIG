# -*- coding: utf-8 -*-
# -*- coding: utf-8 -*-
"""algoritmo_match_v2_6_2.py
Algoritmo de Match Jurídico Inteligente — v2.6.2
======================================================================
Novidades v2.6.2 🚀
-------------------
1.  **Normalização de Acentos**: Matching robusto de keywords sem dependência de acentuação.
2.  **Reviews Mobile-Friendly**: Limite reduzido (10 chars) e validação de variedade de tokens.
3.  **Cobertura de Disponibilidade**: Circuit breaker baseado em cobertura do serviço (80%).
4.  **Truncamento de Tuplas**: safe_json_dump agora trunca tuplas grandes também.
5.  **Validação Flexível**: Melhores heurísticas para reviews curtos e mobile.

Novidades v2.6.1 ✨
-------------------
1.  **Análise Real de Soft-skills**: Cálculo baseado em keywords dos reviews
    quando score externo não disponível.
2.  **No-op Counter Elegante**: Classe NoOpCounter quando Prometheus ausente.
3.  **Validação de Pesos**: Filtragem automática de chaves desconhecidas.
4.  **Checksum Estável**: Uso de hashlib.sha1 para consistência entre runs.
5.  **Prevenção de Re-truncamento**: Marcador _truncated em objetos processados.

Novidades v2.6 ✨
-----------------
1.  **Verificação de Disponibilidade em Batch**: Otimização de performance para
    consultar disponibilidade de múltiplos advogados em uma única chamada.
2.  **Campo active_cases**: Substituição de capacidade_mensal por active_cases
    para cálculo mais preciso de equidade baseado em casos ativos.
3.  **Melhorias de Resiliência**: Timeout configurável (AVAIL_TIMEOUT) e fallback 
    na verificação de disponibilidade.
4.  **Refinamentos de Cache**: Apenas features verdadeiramente estáticas (G, Q) com TTL 6h.
5.  **Métricas de Observabilidade**: Prometheus metrics para modo degradado.
6.  **Configurações via ENV**: 
    - OVERLOAD_FLOOR: Piso para advogados lotados (default: 0.01)
    - MIN_EPSILON: Limite inferior do ε-cluster (default: 0.02)
    - AVAIL_TIMEOUT: Timeout para serviço de disponibilidade (default: 1.5s)
    - DIVERSITY_TAU/LAMBDA: Parâmetros de fairness
7.  **Safe JSON Dump**: Trunca arrays grandes em logs para evitar logs de 100KB+
8.  **Fail-open Inteligente**: Em modo normal, novos advogados são permitidos por padrão

Para histórico completo das versões, consulte CHANGELOG.md
"""

from __future__ import annotations

import asyncio
import atexit
import json
import logging
import os
import time
from dataclasses import dataclass, field
from math import asin, cos, log1p, radians, sin, sqrt
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Literal, Set
from datetime import datetime
import re

# type: ignore - para ignorar erros de importação não resolvidos
import numpy as np
import redis.asyncio as aioredis
try:
    from backend.services.availability_service import get_lawyers_availability_status
except ImportError:
    # Fallback para testes - mock da função
    async def get_lawyers_availability_status(lawyer_ids):
        return {lid: True for lid in lawyer_ids}

# Métrica Prometheus declarada uma única vez no topo
try:
    import prometheus_client  # type: ignore
    HAS_PROMETHEUS = True
    # Verificar se já existe antes de criar
    try:
        AVAIL_DEGRADED = prometheus_client.REGISTRY._names_to_collectors['litgo_availability_degraded_total']
    except KeyError:
        AVAIL_DEGRADED = prometheus_client.Counter(
            'litgo_availability_degraded_total',
            'Total times availability service operated in degraded mode'
        )
except ImportError:  # Prometheus opcional
    HAS_PROMETHEUS = False
    # No-op Counter mais elegante quando Prometheus não disponível
    class NoOpCounter:
        def inc(self, *args, **kwargs):
            pass
    
    AVAIL_DEGRADED = NoOpCounter()

# =============================================================================
# 1. Configurações globais
# =============================================================================

# --- Pesos ---
# Caminho para os pesos dinâmicos do LTR, configurável via variável de ambiente
default_path = Path(__file__).parent / "models/ltr_weights.json"
WEIGHTS_FILE = Path(os.getenv("LTR_WEIGHTS_PATH", default_path))

# Pesos padrão (fallback) - agora incluem feature C
DEFAULT_WEIGHTS = {
    "A": 0.30, "S": 0.25, "T": 0.15, "G": 0.10,
    "Q": 0.10, "U": 0.05, "R": 0.05, "C": 0.03  # Nova feature C
}

# Presets para diferentes cenários
PRESET_WEIGHTS = {
    "fast": {  # Priorizando velocidade - soft-skills ignorados (C=0.00)
        "A": 0.40, "S": 0.15, "T": 0.20, "G": 0.15,
        "Q": 0.05, "U": 0.03, "R": 0.02, "C": 0.00
    },
    "expert": {  # Priorizando expertise e experiência
        "A": 0.25, "S": 0.30, "T": 0.15, "G": 0.05,
        "Q": 0.15, "U": 0.05, "R": 0.03, "C": 0.02
    },
    "balanced": DEFAULT_WEIGHTS,  # Balanceamento equilibrado de todos os fatores
    "economic": {  # Foco em preço e proximidade
        "A": 0.20, "S": 0.15, "T": 0.10, "G": 0.20,
        "Q": 0.05, "U": 0.20, "R": 0.05, "C": 0.05
    }
}

# Variável global para armazenar os pesos carregados
_current_weights = {}

# URL Redis reutilizada do ambiente (mesma usada no Celery)
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

# Regex precompiled
_POSITIVE_PATTERNS = [
    r'\batencioso\b', r'\bdedicado\b', r'\bprofissional\b', r'\bcompetente\b',
    r'\beficiente\b', r'\bcordial\b', r'\bprestativo\b', r'\bresponsavel\b',
    r'\bpontual\b', r'\borganizado\b', r'\bcomunicativo\b', r'\bclaro\b',
    r'\btransparente\b', r'\bconfiavel\b', r'\bexcelente\b', r'\botimo\b',
    r'\bbom\b', r'\bsatisfeito\b', r'\brecomendo\b', r'\bgentil\b',
    r'\beducado\b', r'\bpaciente\b', r'\bcompreensivo\b', r'\bdisponivel\b',
    r'\bagil\b', r'\brapido\b', r'\bpositivo\b'
]
_NEGATIVE_PATTERNS = list(set([
    r'\bdesatento\b', r'\bnegligente\b', r'\bdespreparado\b', r'\bincompetente\b',
    r'\blento\b', r'\brude\b', r'\bgrosseiro\b', r'\birresponsavel\b',
    r'\batrasado\b', r'\bdesorganizado\b', r'\bconfuso\b', r'\bobscuro\b',
    r'\binsatisfeito\b', r'\bnao\s+recomendo\b', r'\bpessimo\b', r'\bruim\b',
    r'\bhorrivel\b', r'\bdemorado\b', r'\bindisponivel\b',
    r'\bausente\b', r'\bnegativo\b'
]))

POS_RE = [re.compile(p, re.I) for p in _POSITIVE_PATTERNS]
NEG_RE = [re.compile(p, re.I) for p in _NEGATIVE_PATTERNS]

def _count_kw(patterns, text):
    return sum(len(p.findall(text)) for p in patterns)

def load_weights() -> Dict[str, float]:
    """Carrega os pesos do LTR do arquivo JSON, com fallback para os padrões."""
    global _current_weights
    try:
        if WEIGHTS_FILE.exists():
            with open(WEIGHTS_FILE, 'r') as f:
                loaded = json.load(f)
                # Converte valores string para float (robustez)
                # Filtra apenas chaves conhecidas para evitar pesos "fantasma"
                loaded = {k: float(v) for k, v in loaded.items() if k in DEFAULT_WEIGHTS}
                # Validação simples para garantir que os pesos não estão todos zerados
                if any(v > 0 for v in loaded.values()):
                    logging.info(f"Pesos do LTR carregados de '{WEIGHTS_FILE}'")
                    _current_weights = loaded
                else:
                    raise ValueError(
                        "Pesos do LTR no arquivo são todos zero, usando fallback.")
        else:
            raise FileNotFoundError("Arquivo de pesos não encontrado.")
    except (FileNotFoundError, ValueError, json.JSONDecodeError) as e:
        logging.warning(
            f"Não foi possível carregar pesos do LTR ({e}). Usando pesos padrão.")
        _current_weights = DEFAULT_WEIGHTS
    return _current_weights


def load_experimental_weights(version: str) -> Optional[Dict[str, float]]:
    """Carrega um arquivo de pesos experimental, se existir."""
    try:
        exp_path = WEIGHTS_FILE.parent / f"ltr_weights_{version}.json"
        if exp_path.exists():
            with open(exp_path, 'r') as f:
                loaded = json.load(f)
                # Converte valores string para float (robustez)
                # Filtra apenas chaves conhecidas para evitar pesos "fantasma"
                loaded = {k: float(v) for k, v in loaded.items() if k in DEFAULT_WEIGHTS}
                if any(v > 0 for v in loaded.values()):
                    logging.info(
                        f"Pesos EXPERIMENTAIS '{version}' carregados de '{exp_path}'")
                    return loaded
        return None
    except (IOError, json.JSONDecodeError, ValueError) as e:
        logging.warning(
            f"Não foi possível carregar pesos experimentais '{version}': {e}")
        return None


def load_preset(preset: str) -> Dict[str, float]:
    """Carrega preset de pesos específico."""
    return PRESET_WEIGHTS.get(preset, DEFAULT_WEIGHTS)


# Carregamento inicial na inicialização do módulo
load_weights()

# --- Outras Configs ---
EMBEDDING_DIM = 384              # Dimensão dos vetores pgvector
# DEPRECATED: RAIO_GEOGRAFICO_KM - agora usa case.radius_km (variável)
# RAIO_GEOGRAFICO_KM = 50          # Normalização para G
MIN_EPSILON = float(os.getenv("MIN_EPSILON", "0.02"))  # Limite inferior ε‑cluster - reduzido e configurável
BETA_EQUITY = 0.30               # Peso equidade
# (v2.5) Fairness configurável sem redeploy
DIVERSITY_TAU = float(os.getenv("DIVERSITY_TAU", "0.30"))
DIVERSITY_LAMBDA = float(os.getenv("DIVERSITY_LAMBDA", "0.05"))
# (v2.6) Piso quando lotado - configurável via ENV
OVERLOAD_FLOOR = float(os.getenv("OVERLOAD_FLOOR", "0.01"))  # Reduzido de 0.05 para 0.01

# =============================================================================
# 2. Logging em JSON
# =============================================================================


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:  # noqa: D401
        return json.dumps({
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "message": record.getMessage(),
            "context": record.args,
        })


_handler = logging.StreamHandler()
_handler.setFormatter(JsonFormatter())
AUDIT_LOGGER = logging.getLogger("audit.match")
AUDIT_LOGGER.addHandler(_handler)
AUDIT_LOGGER.setLevel(logging.INFO)

# =============================================================================
# 3. Utilitários
# =============================================================================


def haversine(coord_a: Tuple[float, float], coord_b: Tuple[float, float]) -> float:
    """Distância Haversine em km."""
    lat1, lon1, lat2, lon2 = map(radians, (*coord_a, *coord_b))
    dlat, dlon = lat2 - lat1, lon2 - lon1
    hav = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    return 2 * 6371 * asin(sqrt(hav))


def cosine_similarity(vec_a: np.ndarray, vec_b: np.ndarray) -> float:
    denom = float(np.linalg.norm(vec_a) * np.linalg.norm(vec_b)) or 1e-9
    return float(np.dot(vec_a, vec_b) / denom)


def safe_json_dump(data: Dict, max_list_size: int = 100) -> Dict:
    """Converte recursivamente valores não serializáveis em JSON (ex: numpy) para tipos nativos e arredonda floats.
    
    Args:
        data: Dicionário a ser convertido
        max_list_size: Tamanho máximo de listas/tuplas antes de truncar (default: 100)
    """
    import hashlib
    
    out = {}
    for key, value in data.items():
        if isinstance(value, dict) and value.get("_truncated"):
            out[key] = value
            continue
        
        # Robusta verificação para tipos NumPy
        is_np_scalar = hasattr(value, 'item') and hasattr(value, 'dtype')
        is_np_array = hasattr(value, 'tolist') and hasattr(value, 'tobytes')

        if is_np_scalar:
            item = value.item()
            if isinstance(item, (int, float)):
                out[key] = round(item, 4) if isinstance(item, float) else item
            else:
                out[key] = item
            continue
        elif is_np_array:
            arr = value.tolist()
            if len(arr) > max_list_size:
                checksum = int(hashlib.sha1(value.tobytes()).hexdigest()[:8], 16)
                out[key] = {
                    "_truncated": True, "size": len(arr), "checksum": checksum,
                    "sample": [round(float(v), 4) for v in arr[:10]],
                }
            else:
                out[key] = [round(float(v), 4) for v in arr]
            continue
        
        # Tipos nativos Python
        if isinstance(value, float):
            out[key] = round(value, 4)
        elif isinstance(value, (list, tuple)) and len(value) > max_list_size:
            out[key] = {
                "_truncated": True, "size": len(value), "sample": list(value[:10])
            }
        elif isinstance(value, dict):
            out[key] = safe_json_dump(value, max_list_size)
        elif isinstance(value, tuple):
            out[key] = list(value)
        else:
            out[key] = value
    return out

# =============================================================================
# 4. Dataclasses expandidas
# =============================================================================


@dataclass(slots=True)
class DiversityMeta:
    """Metadados de diversidade (auto-declarados e opcionais)."""
    gender: Optional[str] = None
    ethnicity: Optional[str] = None
    pcd: Optional[bool] = None  # Pessoa com Deficiência
    lgbtqia: Optional[bool] = None # Pessoa da comunidade LGBTQIA+
    orientation: Optional[str] = None


@dataclass(slots=True)
class Case:
    id: str
    area: str
    subarea: str
    urgency_h: int
    coords: Tuple[float, float]
    complexity: str = "MEDIUM"  # Nova v2.2: LOW, MEDIUM, HIGH
    summary_embedding: np.ndarray = None
    radius_km: int = 50  # Normalização dinâmica para G (pode ser ajustado por chamada)
    
    def __post_init__(self):
        if self.summary_embedding is None:
            self.summary_embedding = np.zeros(EMBEDDING_DIM, dtype=np.float32)


@dataclass(slots=True)
class KPI:
    success_rate: float
    cases_30d: int
    avaliacao_media: float
    tempo_resposta_h: int
    active_cases: int = 0  # número de casos ainda abertos/pendentes
    cv_score: float = 0.0
    success_status: str = "N"


@dataclass(slots=True)
class Lawyer:
    id: str
    nome: str
    tags_expertise: List[str]
    geo_latlon: Tuple[float, float]
    curriculo_json: Dict[str, Any]
    kpi: KPI
    max_concurrent_cases: int = 10  # Novo (v2.6) - com valor padrão
    diversity: Optional[DiversityMeta] = None  # (v2.3)
    kpi_subarea: Dict[str, float] = field(default_factory=dict)  # KPI granular
    kpi_softskill: float = 0.0  # Score de soft-skills
    case_outcomes: List[bool] = field(default_factory=list)
    # Textos de reviews para anti-spam
    review_texts: List[str] = field(default_factory=list)
    last_offered_at: float = field(default_factory=time.time)
    casos_historicos_embeddings: List[np.ndarray] = field(default_factory=list)
    scores: Dict[str, Any] = field(default_factory=dict)
    # v2.7 – autoridade doutrinária e reputação
    pareceres: List[Parecer] = field(default_factory=list)
    reconhecimentos: List[Reconhecimento] = field(default_factory=list)
    
    def __post_init__(self):
        # Inicializar campos mutáveis com valores padrão
        if self.kpi_subarea is None:
            self.kpi_subarea = {}
        if self.case_outcomes is None:
            self.case_outcomes = []
        if self.review_texts is None:
            self.review_texts = []
        if self.last_offered_at is None:
            self.last_offered_at = time.time()
        if self.casos_historicos_embeddings is None:
            self.casos_historicos_embeddings = []
        if self.scores is None:
            self.scores = {}


@dataclass(slots=True)
class Parecer:
    """Representa um parecer jurídico (legal opinion)."""
    titulo: str
    resumo: str
    area: str
    subarea: str
    embedding: np.ndarray = field(default_factory=lambda: np.zeros(EMBEDDING_DIM))


@dataclass(slots=True)
class Reconhecimento:
    """Ranking ou publicação especializada."""
    tipo: Literal["ranking", "artigo", "citacao"]
    publicacao: str
    ano: int
    area: str


# =============================================================================
# 5. Cache estático (simulado)
# =============================================================================


class RedisCache:
    """Cache baseado em Redis assíncrono para features quase estáticas."""

    def __init__(self, redis_url: str):
        try:
            self._redis = aioredis.from_url(
                redis_url, socket_timeout=1, decode_responses=True)
        except Exception:  # Fallback para dev local sem Redis
            class _FakeRedis(dict):
                async def get(self, k): 
                    return super().get(k)
                async def set(self, k, v, ex=None): 
                    self[k] = v
                async def close(self): 
                    pass
            self._redis = _FakeRedis()
        self._prefix = 'match:cache'

    async def get_static_feats(self, lawyer_id: str) -> Optional[Dict[str, float]]:
        raw = await self._redis.get(f"{self._prefix}:{lawyer_id}")
        if raw:
            import json
            return json.loads(raw)
        return None

    async def set_static_feats(self, lawyer_id: str, features: Dict[str, float]):
        import json

        # TTL de 6h - reduzido para permitir atualizações mais frequentes de CV/endereço
        await self._redis.set(f"{self._prefix}:{lawyer_id}", json.dumps(features), ex=21600)

    async def close(self) -> None:
        """Fecha a conexão com o Redis."""
        await self._redis.close()


# Substitui cache fake
cache = RedisCache(REDIS_URL)

# =============================================================================
# 6. Feature calculator expandido
# =============================================================================


class FeatureCalculator:
    """Calcula as oito features normalizadas (0‑1) incluindo soft-skills."""

    def __init__(self, case: Case, lawyer: Lawyer) -> None:
        self.case = case
        self.lawyer = lawyer
        self.cv = lawyer.curriculo_json

    # --------‑‑‑‑‑ Features individuais ‑‑‑‑‑---------

    def area_match(self) -> float:
        return 1.0 if self.case.area in self.lawyer.tags_expertise else 0.0

    def case_similarity(self) -> float:
        """(v2.7) Combina similaridade de casos práticos com pareceres técnicos."""
        # ── 2-a) Similaridade com casos práticos ──────────────────────
        sim_hist = 0.0
        embeddings_hist = self.lawyer.casos_historicos_embeddings
        if embeddings_hist:
            sims_hist = [cosine_similarity(self.case.summary_embedding, e) for e in embeddings_hist]
            outcomes = self.lawyer.case_outcomes
            if outcomes and len(outcomes) == len(sims_hist):
                weights = [1.0 if outcome else 0.8 for outcome in outcomes]
                sim_hist = float(np.average(sims_hist, weights=weights))
            else:
                sim_hist = float(np.mean(sims_hist))

        # ── 2-b) Similaridade com pareceres ───────────────────────────
        sim_par = 0.0
        if self.lawyer.pareceres:
            sims_par = [cosine_similarity(self.case.summary_embedding, p.embedding) for p in self.lawyer.pareceres]
            sim_par = float(max(sims_par)) if sims_par else 0.0

        # ── 2-c) Combinação ponderada ─────────────────────────────────
        if sim_par == 0:
            return sim_hist
        return 0.6 * sim_hist + 0.4 * sim_par

    def success_rate(self) -> float:
        """Success rate com smoothing bayesiano e multiplicador de status (v2.3)."""
        # (v2.3) multiplicador M conforme status
        mult = {"V": 1.0, "P": 0.4, "N": 0.0}.get(self.lawyer.kpi.success_status, 0.0)

        key = f"{self.case.area}/{self.case.subarea}"
        granular = self.lawyer.kpi_subarea.get(key)
        total_cases = self.lawyer.kpi.cases_30d or 1  # fallback 1 para evitar div/0
        # Parâmetros de smoothing
        alpha, beta = 1, 1  # prior (Beta(1,1))
        if granular is not None:
            # Supõe-se granular como valor float (sucessos/total). Estimamos wins.
            wins = int(granular * total_cases)
            base = (wins + alpha) / (total_cases + alpha + beta)
        else:
            # Fallback para taxa geral com smoothing
            wins_general = int(self.lawyer.kpi.success_rate * total_cases)
            base = (wins_general + alpha) / (total_cases + alpha + beta)

        return np.clip(base * mult, 0, 1)

    def geo_score(self) -> float:
        dist = haversine(self.case.coords, self.lawyer.geo_latlon)
        return np.clip(1 - dist / self.case.radius_km, 0, 1)

    def qualification_score(self) -> float:
        """(v2.7) Métrica de reputação com experiência, títulos, publicações, pareceres e reconhecimentos."""
        # ── Experiência ───────────────────────────────────────────────
        score_exp = min(1.0, self.cv.get("anos_experiencia", 0) / 25)

        # ── Títulos acadêmicos ────────────────────────────────────────
        titles: List[Dict[str, str]] = self.cv.get("pos_graduacoes", [])
        counts = {"lato": 0, "mestrado": 0, "doutorado": 0}
        for t in titles:
            level = str(t.get("nivel", "")).lower()
            if level in counts and self.case.area.lower() in str(t.get("area", "")).lower():
                counts[level] += 1

        score_titles = 0.1 * min(counts["lato"], 2) / 2 + \
                       0.2 * min(counts["mestrado"], 2) / 2 + \
                       0.3 * min(counts["doutorado"], 2) / 2

        # ── Publicações gerais ───────────────────────────────────────
        pubs = self.cv.get("num_publicacoes", 0)
        score_pub = min(1.0, log1p(pubs) / log1p(10))

        # ── Pareceres relevantes ─────────────────────────────────────
        num_pareceres_rel = len([p for p in self.lawyer.pareceres if self.case.area.lower() in p.area.lower()])
        score_par = min(1.0, log1p(num_pareceres_rel) / log1p(5))

        # ── Reconhecimentos de mercado ───────────────────────────────
        pesos_rec = {
            "análise advocacia 500": 1.0,
            "chambers and partners": 1.0,
            "the legal 500": 0.9,
            "leaders league": 0.9,
        }
        pontos_rec = 0.0
        for rec in self.lawyer.reconhecimentos:
            if self.case.area.lower() in rec.area.lower():
                pontos_rec += pesos_rec.get(rec.publicacao.lower(), 0.4)
        score_rec = np.clip(pontos_rec / 3.0, 0, 1)

        # ── Combinação final ─────────────────────────────────────────
        base_score = (
            0.30 * score_exp +
            0.25 * score_titles +
            0.15 * score_pub +
            0.15 * score_par +
            0.15 * score_rec
        )

        # Integração com CV score v2.2
        cv_score = self.lawyer.kpi.cv_score
        return 0.8 * base_score + 0.2 * cv_score

    def urgency_capacity(self) -> float:
        if self.case.urgency_h <= 0:
            return 0.0
        return np.clip(1 - self.lawyer.kpi.tempo_resposta_h / self.case.urgency_h, 0, 1)

    def review_score(self) -> float:
        """Score de reviews com filtro anti-spam (alinhado com soft_skill validation)."""
        good = [t for t in self.lawyer.review_texts if self._is_valid_review(t)]
        trust = min(1.0, len(good) / 5)  # confiança cresce até 5 reviews boas
        return np.clip((self.lawyer.kpi.avaliacao_media / 5) * trust, 0, 1)

    def soft_skill(self) -> float:
        """Nova feature C: soft-skills baseada em análise de sentimento."""
        # Se já tem um score calculado externamente, usa ele
        if self.lawyer.kpi_softskill > 0:
            return np.clip(self.lawyer.kpi_softskill, 0, 1)
        
        # Senão, tenta calcular a partir dos reviews
        if self.lawyer.review_texts:
            return self._calculate_soft_skills_from_reviews(self.lawyer.review_texts)
        
        return 0.5  # Neutro quando não há dados
    
    def _normalize_text(self, text: str) -> str:
        """Remove acentos e normaliza texto para matching robusto."""
        import unicodedata
        return unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower()

    def _is_valid_review(self, text: str) -> bool:
        """Valida se review é adequado para análise (≥10 chars, mobile-friendly)."""
        if not text or len(text.strip()) < 10:
            return False
        
        tokens = text.split()
        if len(tokens) < 2:
            return False
            
        # Variedade de tokens: ≥3 tokens OU tokens únicos para reviews curtos
        if len(tokens) >= 3:
            return True
        
        # Para reviews curtos (2 tokens), aceitar se tokens são únicos
        if len(tokens) == 2 and len(set(tokens)) < 2:
            return False
        
        # Para reviews curtos (2 tokens), aceitar se tokens são únicos
        unique_ratio = len(set(tokens)) / len(tokens)
        return unique_ratio >= 0.5  # 50% para reviews muito curtos

    def _calculate_soft_skills_from_reviews(self, reviews: List[str]) -> float:
        """
        Analisa sentimento dos reviews para extrair soft-skills.
        Usa heurísticas simples quando bibliotecas NLP não estão disponíveis.
        Melhorias v2.6.3: normalização de acentos, reviews mobile-friendly e emojis 👍/👎.
        """
        def _replace_emojis(txt: str) -> str:
            txt = (txt.replace('👍', ' positivo ')
                      .replace('👎', ' negativo ')
                      .replace(':+1:', ' positivo ')
                      .replace(':-1:', ' negativo '))
            # Substituir somente -1 isolado
            return re.sub(r'\b-1\b', ' negativo ', txt)
        
        total_score = n_valid = 0
        for review in reviews:
            review = _replace_emojis(review)
            if not self._is_valid_review(review):
                continue
            
            norm_review = self._normalize_text(review)
            pos_count = _count_kw(POS_RE, norm_review)
            neg_count = _count_kw(NEG_RE, norm_review)
            
            if pos_count + neg_count > 0:
                score = pos_count / (pos_count + neg_count)
            else:
                score = 0.5
            
            total_score += score
            n_valid += 1
        
        if n_valid:
            avg = total_score / n_valid
            boost = 0.1 if avg > 0.7 and n_valid >= 3 else 0
            return np.clip(avg + boost, 0, 1)
        return 0.5

    # --------‑‑‑‑‑ Aggregate ‑‑‑‑‑---------

    def all(self) -> Dict[str, float]:  # noqa: D401
        return {
            "A": self.area_match(),
            "S": self.case_similarity(),
            "T": self.success_rate(),
            "G": self.geo_score(),
            "Q": self.qualification_score(),
            "U": self.urgency_capacity(),
            "R": self.review_score(),
            "C": self.soft_skill(),  # Nova feature v2.2
        }

# =============================================================================
# 7. Core algorithm expandido
# =============================================================================


class MatchmakingAlgorithm:
    """Gera ranking justo de advogados para um caso com features v2.2."""

    @staticmethod
    def equity_weight(kpi: KPI, max_cases: int) -> float:
        active = kpi.active_cases
        if max_cases > active:
            return 1 - (active / max_cases)
        return OVERLOAD_FLOOR

    @staticmethod
    def apply_dynamic_weights(
            case: Case, base_weights: Dict[str, float]) -> Dict[str, float]:
        """Aplica pesos dinâmicos baseados na complexidade do caso e normaliza."""
        weights = base_weights.copy()

        if case.complexity == "HIGH":
            # Casos complexos valorizam mais qualificação e taxa de sucesso
            weights["Q"] += 0.05
            weights["T"] += 0.05
            weights["U"] -= 0.05
            weights["C"] += 0.02  # Soft-skills mais importantes
        elif case.complexity == "LOW":
            # Casos simples valorizam mais urgência e localização
            weights["U"] += 0.05
            weights["G"] += 0.03
            weights["Q"] -= 0.05
            weights["T"] -= 0.03

        # Garantir pesos não negativos
        for k, v in weights.items():
            if v < 0:
                weights[k] = 0.0
        # Normalizar soma=1
        total = sum(weights.values()) or 1
        return {k: v / total for k, v in weights.items()}

    # -------- Diversity helper (v2.3+) --------
    @staticmethod
    def _calculate_dimension_boost(
            elite: List[Lawyer], dimension: str) -> Dict[str, float]:
        """Calcula o diversity boost para cada advogado com base em uma única dimensão."""
        boosts = {lw.id: 0.0 for lw in elite}

        groups: Dict[str, int] = {}
        for lw in elite:
            key = 'UNK'
            if lw.diversity:
                value = getattr(lw.diversity, dimension, 'UNK')
                # Chave consistente para None, False
                key = str(value) if value is not None else 'UNK'
            groups[key] = groups.get(key, 0) + 1

        total_elite = len(elite)
        if not total_elite:
            return boosts

        representation = {k: v / total_elite for k, v in groups.items()}

        for lw in elite:
            key = 'UNK'
            if lw.diversity:
                value = getattr(lw.diversity, dimension, 'UNK')
                key = str(value) if value is not None else 'UNK'

            rep = representation.get(key, 1.0)
            if rep < DIVERSITY_TAU:
                boosts[lw.id] = DIVERSITY_LAMBDA

        return boosts

    # ------------------------------------------------------------------
    async def rank(self, case: Case, lawyers: List[Lawyer], *, top_n: int = 5,
                   preset: str = "balanced", model_version: Optional[str] = None,
                   exclude_ids: Optional[Set[str]] = None) -> List[Lawyer]:
        """Classifica advogados para um caso.

        Passos:
        1. Carrega pesos (preset + dinâmica).
        2. Calcula features (cache Redis para estáticas).
        3. Gera breakdown `delta` por feature.
        4. Aplica ε-cluster e equidade, incluindo boost de diversidade (v2.3).
        5. (v2.6) Permite carregar pesos de um modelo experimental para testes A/B.
        6. Retorna top_n ordenados por `fair` e `last_offered_at`.
        """
        if not lawyers:
            return []

        # --- Filtro de exclusão opcional -------------------------------
        if exclude_ids:
            lawyers = [lw for lw in lawyers if lw.id not in exclude_ids]
            if not lawyers:
                return []

        # 1. Carregar pesos base
        # (v2.6) Lógica para teste A/B de pesos
        experimental_weights = None
        if model_version and model_version != 'production':
            experimental_weights = load_experimental_weights(model_version)

        if experimental_weights:
            base_weights = experimental_weights
        else:
            base_weights = (_current_weights or DEFAULT_WEIGHTS).copy()

        # Sobrepor apenas chaves declaradas no preset (permite ajustes rápidos)
        base_weights.update(load_preset(preset))

        # 2. Aplicar pesos dinâmicos baseados na complexidade
        weights = self.apply_dynamic_weights(case, base_weights)

        # CORREÇÃO PONTO 2 e 7: Filtro de disponibilidade em batch (otimizado)
        lawyer_ids = [lw.id for lw in lawyers]
        # Consulta de disponibilidade com timeout resiliente
        timeout_sec = float(os.getenv("AVAIL_TIMEOUT", "1.5"))
        coverage_threshold = float(os.getenv("AVAIL_COVERAGE_THRESHOLD", "0.8"))  # 80%
        
        try:
            availability_map = await asyncio.wait_for(
                get_lawyers_availability_status(lawyer_ids),
                timeout=timeout_sec
            )
            
            # Calcular cobertura do serviço (apenas advogados disponíveis)
            available_count = sum(1 for v in availability_map.values() if v)
            response_count = len(availability_map)
            coverage = response_count / len(lawyer_ids) if lawyer_ids else 0
            availability_rate = available_count / response_count if response_count else 0
            
            # Modo degradado se timeout, vazio ou cobertura de resposta baixa
            degraded_mode = (not availability_map or coverage < coverage_threshold or availability_rate == 0)
            
            if degraded_mode:
                AUDIT_LOGGER.warning(
                    "Availability service low coverage - operating in degraded mode",
                    {
                        "case_id": case.id, 
                        "lawyer_count": len(lawyers), 
                        "response_coverage": round(coverage, 2),
                        "availability_rate": round(availability_rate, 2),
                        "threshold": coverage_threshold
                    }
                )
                
        except asyncio.TimeoutError:
            AUDIT_LOGGER.warning(
                "Availability service timeout - operating in degraded mode",
                {"case_id": case.id, "lawyer_count": len(lawyers), "timeout": timeout_sec}
            )
            availability_map = {}
            degraded_mode = True
            coverage = 0.0
        
        # Detecção de modo degradado e fail-open
        if degraded_mode:
            # Em modo degradado, permite todos (fail-open)
            availability_map = {lw.id: True for lw in lawyers}
            
            # Incrementa contador Prometheus apenas quando realmente degradado
            AVAIL_DEGRADED.inc()
            
            # Log estruturado adicional quando não há Prometheus
            if not HAS_PROMETHEUS:
                AUDIT_LOGGER.info(
                    "Degraded mode metric logged",
                    {"metric": "availability_degraded", "value": 1, "case_id": case.id}
                )
        
        available_lawyers = []
        # Default True no modo normal para map parcial (advogados novos)
        default_availability = True if not degraded_mode else False
        for lw in lawyers:
            if availability_map.get(lw.id, default_availability):
                available_lawyers.append(lw)

        # 3. Calcular features com cache
        for lw in available_lawyers:
            # Tentar recuperar features estáticas do cache
            static_feats = await cache.get_static_feats(lw.id)

            if static_feats:
                feats = static_feats.copy()
                calculator = FeatureCalculator(case, lw)
                feats["A"] = calculator.area_match()
                feats["S"] = calculator.case_similarity()
                feats["T"] = calculator.success_rate()
                feats["U"] = calculator.urgency_capacity()  # recálculo para urgência
                feats["C"] = calculator.soft_skill()        # recálculo de soft-skills
                feats["R"] = calculator.review_score()
            else:
                # Se não há cache, calcular tudo e salvar features estáticas
                calculator = FeatureCalculator(case, lw)
                feats = calculator.all()
                # Somente Q permanece verdadeiramente estático;
                # G depende de radius_km → não cachear.
                static_to_cache = {"Q": feats["Q"]}
                await cache.set_static_feats(lw.id, static_to_cache)

            # Atribuição unificada de features
            lw.scores["features"] = feats

            # 4. Calcular score LTR e Delta
            features = lw.scores["features"]
            # Garantir que todas as features existem para não dar KeyError
            score_ltr = sum(features.get(k, 0) * weights.get(k, 0) for k in weights)
            lw.scores["ltr"] = score_ltr
            lw.scores["delta"] = {
                k: features.get(k, 0) * weights.get(k, 0) for k in weights
            }

            # Guardar preset/complexidade e modo degradado para logs
            lw.scores.update({
                "preset": preset, 
                "complexity": case.complexity,
                "degraded_mode": degraded_mode
            })

        if not available_lawyers:
            return []

        # 5. Aplicar ε-cluster e equidade
        max_score = max(lw.scores["ltr"] for lw in available_lawyers)
        eps = max(MIN_EPSILON, 0.10 * max_score)  # proporcional ao max_score
        min_score = max_score - eps
        elite = [lw for lw in available_lawyers if lw.scores["ltr"] >= min_score]

        # 6. Re-ranking com equidade e diversidade
        for lw in elite:
            # CORREÇÃO PONTO 4 (uso): Passar `max_concurrent_cases`
            equity = self.equity_weight(lw.kpi, lw.max_concurrent_cases)
            
            # (v2.5) O boost de diversidade será aplicado sequencialmente
            lw.scores["equity_raw"] = equity
            lw.scores["fair_base"] = (1 - BETA_EQUITY) * \
                lw.scores["ltr"] + BETA_EQUITY * equity

        # (v2.5) Fairness Sequencial Multi-Eixo
        # O re-ranking acontece em múltiplos passos para cada dimensão
        current_ranking = sorted(elite, key=lambda l: l.scores["fair_base"], reverse=True)
        for dimension in ["gender", "ethnicity", "pcd", "orientation"]:
            boosts = self._calculate_dimension_boost(current_ranking, dimension)
            for lw in current_ranking:
                lw.scores["fair_base"] += boosts.get(lw.id, 0.0)
            # Re-ordena após cada boost para o próximo cálculo de representação
            current_ranking.sort(key=lambda l: l.scores["fair_base"], reverse=True)
        
        # O ranking final é o resultado do último passo
        final_ranking = current_ranking

        # Log de auditoria
        for lw in final_ranking[:top_n]:  # só loga os top_n selecionados
            # CORREÇÃO PONTO 6: Garantir que o log é serializável
            log_scores = lw.scores.copy()
            # Remover embeddings verbosos do log
            feats_log = log_scores.get("features", {})
            if "casos_historicos_embeddings" in feats_log:
                del feats_log["casos_historicos_embeddings"]
            if "summary_embedding" in feats_log:
                del feats_log["summary_embedding"]
            
            log_context = {
                "case_id": case.id,
                "lawyer_id": lw.id,
                "scores": safe_json_dump(log_scores),
                "model_version": model_version or "production",
                "preset": preset,
                "weights_used": safe_json_dump({k: float(v) for k, v in weights.items()}),
                "degraded_mode": degraded_mode,
            }
            AUDIT_LOGGER.info(
                f"Lawyer {lw.id} ranked for case {case.id}", log_context)

        # 7. Ordenar por score final e, como desempate, pelo mais "descansado"
        final_ranking.sort(key=lambda l: (-l.scores["fair_base"], l.last_offered_at))

        # Atualizar timestamp para os advogados selecionados e retornar
        now = time.time()
        top_n_lawyers = final_ranking[:top_n]
        for lw in top_n_lawyers:
            lw.last_offered_at = now

        return top_n_lawyers

# =============================================================================
# 8. Exemplo de uso expandido
# =============================================================================


if __name__ == "__main__":
    # Exemplo com as novas features v2.2

    def make_lawyer_v2(id_num: int, exp: int, succ: float, load: int,
                       titles: List[Dict], soft_skill: float = 0.5,
                       kpi_subarea: Optional[Dict[str, float]] = None,
                       case_outcomes: Optional[List[bool]] = None,
                       success_status: str = "N",  # (v2.3)
                       diversity: Optional[DiversityMeta] = None  # (v2.3)
                       ) -> Lawyer:
        return Lawyer(
            id=f"ADV{id_num}",
            nome=f"Advogado {id_num}",
            tags_expertise=["civil", "criminal", "trabalhista"],
            geo_latlon=(-23.5505, -46.6333),
            curriculo_json={
                "anos_experiencia": exp,
                "pos_graduacoes": titles,
                "num_publicacoes": 5,
            },
            kpi=KPI(
                success_rate=succ,
                cases_30d=load,
                avaliacao_media=4.5,
                tempo_resposta_h=24,
                cv_score=0.8,
                success_status=success_status,
                active_cases=load//2,
            ),
            max_concurrent_cases=20, # (v2.6) Adicionado ao mock
            diversity=diversity,
            kpi_subarea=kpi_subarea or {},
            kpi_softskill=soft_skill,
            case_outcomes=case_outcomes or [True, False, True],
            review_texts=[f"Review {i + 1} for lawyer {id_num}" for i in range(5)],
            casos_historicos_embeddings=[
                np.random.rand(EMBEDDING_DIM) for _ in range(3)],
        )

    # Caso de teste com complexidade
    case_demo = Case(
        id="caso_v2_demo",
        area="Trabalhista",
        subarea="Rescisão",
        urgency_h=48,
        coords=(-23.5505, -46.6333),
        complexity="HIGH",  # Caso complexo
        summary_embedding=np.random.rand(EMBEDDING_DIM),
    )

    # Advogados de teste com features v2.2
    lawyers_demo = [
        make_lawyer_v2(1, exp=15, succ=0.95, load=18,
                       titles=[{"nivel": "mestrado", "area": "Trabalhista"}],
                       soft_skill=0.8, case_outcomes=[True, True, True, False],
                       success_status="V", diversity=DiversityMeta(gender="F", ethnicity="parda")),
        make_lawyer_v2(2, exp=12, succ=0.88, load=10,
                       titles=[{"nivel": "lato", "area": "Trabalhista"}],
                       soft_skill=0.6, case_outcomes=[True, False, True, True],
                       success_status="P", diversity=DiversityMeta(gender="M", ethnicity="branca", pcd=True)),
        make_lawyer_v2(3, exp=20, succ=0.92, load=15,
                       titles=[{"nivel": "doutorado", "area": "Trabalhista"}],
                       soft_skill=0.9, case_outcomes=[True, True, True, True],
                       success_status="V", diversity=DiversityMeta(gender="M", ethnicity="branca", orientation="G")),
    ]

    async def demo_v2():
        """Demo da versão 2.6.2 com normalização de acentos, reviews mobile e circuit breaker."""
        print("\n" + "=" * 60)
        print("🚀 Demo do Algoritmo de Match v2.6.2")
        print("=" * 60)

        matcher = MatchmakingAlgorithm()

        # Teste com preset "expert" para caso complexo
        ranking_v2 = await matcher.rank(case_demo, lawyers_demo, top_n=3, preset="expert")

        print("\n—— Resultado do Ranking v2.6.2 (Normalização + Reviews Mobile + Circuit Breaker) ——")
        for pos, adv in enumerate(ranking_v2, 1):
            scores = adv.scores
            feats = scores["features"]
            delta = scores["delta"]

            print(f"{pos}º {adv.nome}")
            print(
                f"  Fair: {scores['fair_base']:.3f} | Raw: {scores['ltr']:.3f} | Equity: {scores.get('equity_raw', 0):.3f}")
            print(
                f"  Features: A={feats['A']:.2f} S={feats['S']:.2f} T={feats['T']:.2f} G={feats['G']:.2f}")
            print(
                f"           Q={feats['Q']:.2f} U={feats['U']:.2f} R={feats['R']:.2f} C={feats['C']:.2f}")
            print(f"  Delta: {delta}")
            print(f"  Preset: {scores['preset']} | Complexity: {scores['complexity']}")
            print(f"  Degraded Mode: {'SIM' if scores.get('degraded_mode', False) else 'NÃO'}")
            print(f"  Last offered: {datetime.fromtimestamp(adv.last_offered_at).isoformat()}")
            print()

        print("\n📊 Observações v2.6.2:")
        print("1. Normalização de acentos: 'nao recomendo' agora é detectado")
        print("2. Reviews mobile aceitos: 'Top!' e 'Muito bom 👍' são válidos")
        print("3. Circuit breaker: modo degradado se cobertura < 80%")
        print("4. Tuplas grandes truncadas em logs para evitar overflow")
        print("5. Validação flexível com 40% de variedade de tokens")
        print("6. Soft-skills mais precisos com keywords normalizadas")
        print("7. Configuração via ENV: AVAIL_COVERAGE_THRESHOLD")

    import asyncio
    asyncio.run(demo_v2())


@atexit.register
def _close_redis():
    try:
        loop = asyncio.get_event_loop()
        if not loop.is_closed():
            loop.run_until_complete(cache.close())
    except RuntimeError:
        pass
