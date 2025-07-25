# -*- coding: utf-8 -*-
"""algoritmo_match.py
Algoritmo de Match Jurídico Inteligente — v2.9-unified
======================================================================
Versão consolidada que combina funcionalidades das versões:
- v2.7-rc3: Sponsored recommendations, premium cases, complete logging
- v2.8-academic: Academic enrichment, LTR service, async features

Funcionalidades v2.9-unified 🚀
-------------------------------
1.  **Academic Enrichment**: Feature Q enriquecida com dados acadêmicos externos
    - Avaliação de universidades via rankings QS/THE
    - Análise de periódicos por fator de impacto (JCR/Qualis)
    - Cache Redis com TTL configurável
    - Rate limiting e fallback resiliente
2.  **LTR Service Integration**: Serviço externo para scoring via HTTP
3.  **Async Feature Calculation**: `qualification_score_async()` e `all_async()`
4.  **External APIs Integration**: Perplexity (primária) + Deep Research (fallback)
5.  **Sponsored Recommendations**: Sistema de anúncios patrocinados integrado
6.  **Premium Cases Logic**: Gating/boost para casos premium
7.  **Enhanced Logging**: TTL acadêmico e flags de enriquecimento nos logs

Funcionalidades anteriores mantidas:
- Feature-E (Firm Reputation), B2B Two-Pass Algorithm
- Safe Conflict Scan, SUCCESS_FEE_MULT configurável
- Observabilidade completa, otimizações de performance
======================================================================
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
from typing import Any, Dict, List, Optional, Tuple, Literal, Set, cast
from datetime import datetime, timedelta
from ..schemas.recommendation import Recommendation
from ..services.ads_service import fetch_ads_for_case
from ..services.weight_optimizer_service import get_optimized_weights
import re
import unicodedata
import hashlib
import math

# type: ignore - para ignorar erros de importação não resolvidos
import numpy as np
import redis.asyncio as aioredis

# --- Academic Enrichment Dependencies ---
try:
    import aiohttp
    from aiolimiter import AsyncLimiter
    HAS_ACADEMIC_ENRICHMENT = True
except ImportError:
    # Fallback quando dependências acadêmicas não estão disponíveis
    HAS_ACADEMIC_ENRICHMENT = False
    class AsyncLimiter:
        def __init__(self, *args, **kwargs):
            pass
        async def __aenter__(self):
            return self
        async def __aexit__(self, *args):
            pass
import httpx

# LTR Service Integration
LTR_ENDPOINT = os.getenv("LTR_ENDPOINT", "http://ltr-service:8080/ltr/score")
try:
    from .services.availability_service import get_lawyers_availability_status
except ImportError:
    # Fallback para testes - mock da função
    async def get_lawyers_availability_status(lawyer_ids):
        return {lid: True for lid in lawyer_ids}

# --- Conflitos de interesse --------------------------------------------------
try:
    from .services.conflict_service import conflict_scan  # type: ignore
except ImportError:
    # Fail-open: sem serviço, assume sem conflitos
    def conflict_scan(case, lawyer):  # type: ignore
        return False

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

# Após definição do contador, aplicar cast para agradar o linter
AVAIL_DEGRADED = cast(Any, AVAIL_DEGRADED)

try:
    from .const import algorithm_version  # Nova constante centralizada
except ImportError:
    from const import algorithm_version  # Fallback para execução standalone

# Feature Flags para controle de rollout B2B
try:
    from .services.feature_flags import (
        is_firm_matching_enabled,
        get_corporate_preset,
        is_b2b_enabled_for_user,
        is_segmented_cache_enabled
    )
except ImportError:
    # Fallback para testes - feature flags desabilitadas
    def is_firm_matching_enabled(user_id=None):
        return False
    def get_corporate_preset():
        return "balanced"
    def is_b2b_enabled_for_user(user_id):
        return False
    def is_segmented_cache_enabled():
        return False

# =============================================================================
# 1. Configurações globais
# =============================================================================

# --- Pesos ---
# Caminho para os pesos dinâmicos do LTR, configurável via variável de ambiente
default_path = Path(__file__).parent / "models/ltr_weights.json"
WEIGHTS_FILE = Path(os.getenv("LTR_WEIGHTS_PATH", default_path))

# Pesos fixos, definidos no código, como última camada de segurança
HARDCODED_FALLBACK_WEIGHTS = {
    "A": 0.23, "S": 0.18, "T": 0.11, "G": 0.07,
    "Q": 0.07, "U": 0.05, "R": 0.05, "C": 0.03,
    "E": 0.02, "P": 0.02, "M": 0.17
}

# Tenta carregar os pesos otimizados; se falhar, usa o fallback fixo
try:
    OPTIMIZED_WEIGHTS = get_optimized_weights()
    if not OPTIMIZED_WEIGHTS or sum(OPTIMIZED_WEIGHTS.values()) == 0:
        logging.warning("Pesos otimizados estão vazios ou zerados. Usando fallback fixo.")
        OPTIMIZED_WEIGHTS = HARDCODED_FALLBACK_WEIGHTS
except Exception as e:
    logging.error(f"Falha crítica ao carregar pesos otimizados: {e}. Usando fallback fixo.")
    OPTIMIZED_WEIGHTS = HARDCODED_FALLBACK_WEIGHTS


# O DEFAULT_WEIGHTS agora se refere aos pesos otimizados (ou ao fallback, se falhou)
DEFAULT_WEIGHTS = OPTIMIZED_WEIGHTS

# Presets revisados v2.8 – todos somam 1.0 e incluem chave "M"
PRESET_WEIGHTS = {
    "fast": {
        "A": 0.39, "S": 0.15, "T": 0.20, "G": 0.15,
        "Q": 0.07, "U": 0.03, "R": 0.01,
        "C": 0.00, "P": 0.00, "E": 0.00, "M": 0.00
    },
    "expert": {
        "A": 0.19, "S": 0.25, "T": 0.15, "G": 0.05,
        "Q": 0.15, "U": 0.05, "R": 0.03,
        "C": 0.02, "P": 0.01, "E": 0.00, "M": 0.10
    },
    "balanced": DEFAULT_WEIGHTS,
    "economic": {
        "A": 0.17, "S": 0.12, "T": 0.07, "G": 0.17,
        "Q": 0.04, "U": 0.17, "R": 0.05,
        "C": 0.05, "P": 0.12, "E": 0.00, "M": 0.04
    },
    "b2b": {
        "A": 0.12, "S": 0.15, "T": 0.15, "Q": 0.17,
        "E": 0.10, "G": 0.05, "U": 0.05, "R": 0.03,
        "C": 0.03, "P": 0.10, "M": 0.05
    },
    "correspondent": {
        "A": 0.10, "S": 0.05, "T": 0.05, "G": 0.25,
        "Q": 0.10, "U": 0.20, "R": 0.03, "C": 0.05,
        "E": 0.02, "P": 0.15, "M": 0.00
    },
    "expert_opinion": {
        "A": 0.10, "S": 0.30, "T": 0.03, "G": 0.00,
        "Q": 0.35, "U": 0.00, "R": 0.00, "C": 0.00,
        "E": 0.02, "P": 0.00, "M": 0.20
    }
}

# Validação automática dos presets na inicialização
def _validate_preset_weights():
    """Valida se todos os presets somam 1.0 (±1e-6)."""
    for name, weights in PRESET_WEIGHTS.items():
        total = sum(weights.values())
        if abs(total - 1.0) > 1e-6:
            raise ValueError(f"Preset '{name}' não soma 1.0 (soma={total:.6f})")
    print("✓ Todos os presets validados (soma=1.0)")

# Configurações de timeout e decay
CONFLICT_TIMEOUT_SEC = float(os.getenv("CONFLICT_TIMEOUT", "2.0"))
PRICE_DECAY_K = float(os.getenv("PRICE_DECAY_K", "5.0"))  # Configurável para A/B testing
SUCCESS_FEE_MULT = float(os.getenv("SUCCESS_FEE_MULT", "10.0"))  # Multiplicador para estimar valor do caso

# --- Academic Enrichment Configuration ---
PERPLEXITY_API_KEY = os.getenv("PERPLEXITY_API_KEY")
OPENAI_DEEP_KEY = os.getenv("OPENAI_DEEP_KEY")
UNI_RANK_TTL_H = int(os.getenv("UNI_RANK_TTL_H", "720"))  # 30 dias default para universidades
JOUR_RANK_TTL_H = int(os.getenv("JOUR_RANK_TTL_H", "720"))  # 30 dias default para periódicos

# Deep Research timeouts (conforme documentação oficial)
DEEP_POLL_SECS = int(os.getenv("DEEP_POLL_SECS", "10"))  # intervalo entre polls
DEEP_MAX_MIN = int(os.getenv("DEEP_MAX_MIN", "15"))      # encerra após 15 min

# Rate limiters para APIs externas
if HAS_ACADEMIC_ENRICHMENT:
    PXP_LIM = AsyncLimiter(30, 60)  # 30 req/min para Perplexity
    ESC_LIM = AsyncLimiter(20, 60)  # 20 req/min se já usa Escavador
else:
    PXP_LIM = AsyncLimiter()  # Dummy limiter
    ESC_LIM = AsyncLimiter()  # Dummy limiter

# Executar validação na inicialização
_validate_preset_weights()

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
MIN_EPSILON = float(os.getenv("MIN_EPSILON", "0.02"))  # Limite inferior ε‑cluster - reduzido e configurável
BETA_EQUITY = 0.30               # Peso equidade
DIVERSITY_TAU = float(os.getenv("DIVERSITY_TAU", "0.30"))
DIVERSITY_LAMBDA = float(os.getenv("DIVERSITY_LAMBDA", "0.05"))
OVERLOAD_FLOOR = float(os.getenv("OVERLOAD_FLOOR", "0.01"))

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
        is_np_scalar = hasattr(value, 'item') and hasattr(value, 'dtype') and not isinstance(value, dict)
        is_np_array = hasattr(value, 'tolist') and hasattr(value, 'tobytes') and not isinstance(value, dict)

        if is_np_scalar:
            try:
                item = value.item()
                if isinstance(item, (int, float)):
                    out[key] = round(item, 4) if isinstance(item, float) else item
                else:
                    out[key] = item
            except (AttributeError, TypeError):
                out[key] = str(value)
            continue
        elif is_np_array:
            try:
                arr = value.tolist()
                if len(arr) > max_list_size:
                    checksum = int(hashlib.sha1(value.tobytes()).hexdigest()[:8], 16)
                    out[key] = {
                        "_truncated": True, "size": len(arr), "checksum": checksum,
                        "sample": [round(float(v), 4) for v in arr[:10]],
                    }
                else:
                    out[key] = [round(float(v), 4) for v in arr]
            except (AttributeError, TypeError):
                out[key] = str(value)
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

def canonical(text: str) -> str:
    """Remove acentos, normaliza e converte para slug para uso como chave de cache."""
    if not text:
        return ""
    # Remove acentos e caracteres especiais
    normalized = unicodedata.normalize('NFKD', text)
    ascii_text = normalized.encode('ascii', 'ignore').decode('ascii')
    # Converte para lowercase e substitui espaços por underscores
    slug = re.sub(r'[^a-z0-9\s]', '', ascii_text.lower())
    slug = re.sub(r'\s+', '_', slug.strip())
    return slug


def _chunks(lst: List, n: int):
    """Divide uma lista em chunks de tamanho máximo n."""
    for i in range(0, len(lst), n):
        yield lst[i:i + n]

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
class ProfessionalMaturityData:
    """Estrutura de dados padronizada para a maturidade profissional.
    
    Esta classe define um 'contrato' interno que desacopla o algoritmo
    de matching das especificidades de APIs externas (Unipile, etc.).
    """
    experience_years: float = 0.0
    network_strength: int = 0  # Ex: número de conexões LinkedIn
    reputation_signals: int = 0  # Ex: número de recomendações recebidas
    responsiveness_hours: float = 48.0  # Tempo médio de resposta (pior caso padrão)


@dataclass(slots=True)
class Case:
    id: str
    area: str
    subarea: str
    urgency_h: int
    coords: Tuple[float, float]
    complexity: str = "MEDIUM"  # Nova v2.2: LOW, MEDIUM, HIGH
    summary_embedding: Optional[np.ndarray] = None  # Corrigido tipo
    radius_km: int = 50  # Normalização dinâmica para G (pode ser ajustado por chamada)
    expected_fee_min: float = 0.0  # Faixa de preço desejada (B2C)
    expected_fee_max: float = 0.0
    type: str = "INDIVIDUAL"  # INDIVIDUAL, CORPORATE - para controle de preset B2B
    is_premium: bool = False  # Adicionado para a lógica premium
    premium_exclusive_min: int = 60 # Adicionado para a lógica premium
    
    def __post_init__(self):
        if self.summary_embedding is None:
            self.summary_embedding = np.zeros(EMBEDDING_DIM, dtype=np.float32)
        if self.summary_embedding is not None and self.summary_embedding.ndim != 1:
            raise ValueError("summary_embedding must be a 1D array")


@dataclass(slots=True)
class KPI:
    success_rate: float
    cases_30d: int
    avaliacao_media: float
    tempo_resposta_h: int
    active_cases: int = 0  # número de casos ainda abertos/pendentes
    cv_score: float = 0.0
    success_status: str = "N"
    # 🆕 métricas de valor econômico (últimos 30 dias)
    valor_recuperado_30d: float = 0.0  # soma de valores obtidos/evitados
    valor_total_30d: float = 0.0  # soma de valores demandados


@dataclass(slots=True)
class FirmKPI:
    """KPIs agregados de um escritório."""
    success_rate: float = 0.0
    nps: float = 0.0
    reputation_score: float = 0.0
    diversity_index: float = 0.0
    active_cases: int = 0
    maturity_index: float = 0.0  # 🆕 v2.8 - Índice de Maturidade Agregado


# -- Dataclass principal de Advogado -------------------------------------------------

@dataclass(slots=True)
class Lawyer:
    id: str
    nome: str
    tags_expertise: List[str]
    geo_latlon: Tuple[float, float]
    curriculo_json: Dict[str, Any]
    kpi: KPI
    max_concurrent_cases: int = 10  # Novo (v2.6)
    diversity: Optional[DiversityMeta] = None  # (v2.3)
    kpi_subarea: Dict[str, float] = field(default_factory=dict)
    kpi_softskill: float = 0.0
    case_outcomes: List[bool] = field(default_factory=list)
    review_texts: List[str] = field(default_factory=list)
    last_offered_at: float = field(default_factory=time.time)
    casos_historicos_embeddings: List[np.ndarray] = field(default_factory=list)
    scores: Dict[str, Any] = field(default_factory=dict)
    # v2.7 – autoridade doutrinária e reputação
    pareceres: List['Parecer'] = field(default_factory=list)
    reconhecimentos: List['Reconhecimento'] = field(default_factory=list)
    firm_id: Optional[str] = None  # FK opcional
    firm: Optional['LawFirm'] = None  # Objeto lazy-loaded
    avg_hourly_fee: float = 0.0  # Taxa média de honorários/hora
    # 🆕 v2.7 - Modalidades de preço
    flat_fee: Optional[float] = None  # Honorário fixo por caso
    success_fee_pct: Optional[float] = None  # Percentual sobre êxito (quota litis)
    # 🆕 v2.8 - Dados de maturidade profissional (estrutura padronizada)
    maturity_data: Optional[ProfessionalMaturityData] = None

    def __post_init__(self):
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


# --- Redefinição de LawFirm como subclasse de Lawyer (compatível) ---

@dataclass(slots=True)
class LawFirm(Lawyer):
    """Representa um escritório de advocacia, herdando toda a estrutura de `Lawyer`.
    Adiciona campos específicos do empregador e KPIs agregados.
    """
    team_size: int = 0
    main_latlon: Tuple[float, float] = (0.0, 0.0)
    kpi_firm: FirmKPI = field(default_factory=FirmKPI)
    is_boutique: bool = False  # Novo campo para identificar escritórios boutique


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
        # Cache segmentado por entidade se feature flag habilitada
        if is_segmented_cache_enabled():
            entity = 'firm' if str(lawyer_id).startswith('FIRM') else 'lawyer'
            cache_key = f"{self._prefix}:{entity}:{lawyer_id}"
        else:
            # Cache tradicional para compatibilidade
            cache_key = f"{self._prefix}:{lawyer_id}"
        
        raw = await self._redis.get(cache_key)
        if raw:
            import json
            return json.loads(raw)
        return None

    async def set_static_feats(self, lawyer_id: str, features: Dict[str, float]):
        import json
        
        # Cache segmentado por entidade se feature flag habilitada
        if is_segmented_cache_enabled():
            entity = 'firm' if str(lawyer_id).startswith('FIRM') else 'lawyer'
            cache_key = f"{self._prefix}:{entity}:{lawyer_id}"
        else:
            # Cache tradicional para compatibilidade
            cache_key = f"{self._prefix}:{lawyer_id}"
        
        # TTL configurável via ENV
        ttl = int(os.getenv("CACHE_TTL_SECONDS", "21600"))  # 6 horas padrão
        
        await self._redis.set(cache_key, json.dumps(features), ex=ttl)

    async def get_academic_score(self, key: str) -> Optional[float]:
        """Recupera score acadêmico do cache."""
        cache_key = f"{self._prefix}:acad:{key}"
        raw = await self._redis.get(cache_key)
        if raw:
            try:
                return float(raw)
            except (ValueError, TypeError):
                return None
        return None

    async def set_academic_score(self, key: str, score: float, *, ttl_h: int):
        """Armazena score acadêmico no cache com TTL em horas."""
        cache_key = f"{self._prefix}:acad:{key}"
        await self._redis.set(cache_key, str(score), ex=ttl_h * 3600)

    async def close(self) -> None:
        """Fecha a conexão com o Redis."""
        await self._redis.close()


# Substitui cache fake
cache = RedisCache(REDIS_URL)

# --- Prometheus Counter para ranking ---
try:
    if HAS_PROMETHEUS:
        try:
            MATCH_RANK_TOTAL = prometheus_client.REGISTRY._names_to_collectors['litgo_match_rank_total']
        except KeyError:  # ainda não registrado
            MATCH_RANK_TOTAL = prometheus_client.Counter(
                'litgo_match_rank_total',
                'Total de advogados/escritórios ranqueados',
                ['entity']
            )
    else:
        MATCH_RANK_TOTAL = AVAIL_DEGRADED  # NoOpCounter
except Exception:
    MATCH_RANK_TOTAL = AVAIL_DEGRADED

# Cast para resolver linting
MATCH_RANK_TOTAL = cast(Any, MATCH_RANK_TOTAL)

# =============================================================================
# Academic Enrichment HTTP Wrappers
# =============================================================================

async def perplexity_chat(payload: Dict[str, Any]) -> Optional[Dict]:
    """Wrapper para API do Perplexity com rate limiting e tratamento de erros."""
    if not HAS_ACADEMIC_ENRICHMENT or not PERPLEXITY_API_KEY:
        AUDIT_LOGGER.info("Perplexity API não configurada - usando fallback", {
            "has_enrichment": HAS_ACADEMIC_ENRICHMENT,
            "has_api_key": bool(PERPLEXITY_API_KEY)
        })
        return None
    
    async with PXP_LIM:
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    "https://api.perplexity.ai/chat/completions",
                    headers={
                        "Authorization": f"Bearer {PERPLEXITY_API_KEY}",
                        "Content-Type": "application/json"
                    },
                    json=payload,
                    timeout=aiohttp.ClientTimeout(total=30)
                ) as response:
                    if response.status == 429:
                        # Rate limit hit, aguardar um pouco mais
                        await asyncio.sleep(2)
                        return None
                    
                    if response.status != 200:
                        AUDIT_LOGGER.warning("Perplexity API error", {
                            "status": response.status, 
                            "payload_size": len(str(payload))
                        })
                        return None
                    
                    data = await response.json()
                    content = data.get("choices", [{}])[0].get("message", {}).get("content", "")
                    
                    # Parse JSON da resposta (modelo configurado para retornar JSON)
                    try:
                        return json.loads(content)
                    except json.JSONDecodeError:
                        return None
                        
        except (aiohttp.ClientError, asyncio.TimeoutError) as e:
            AUDIT_LOGGER.warning("Perplexity request failed", {"error": str(e)})
            return None


async def deep_research_request(payload: Dict[str, Any]) -> Optional[Dict]:
    """Wrapper para Deep Research API com polling - 100% spec oficial OpenAI."""
    if not HAS_ACADEMIC_ENRICHMENT or not OPENAI_DEEP_KEY:
        AUDIT_LOGGER.info("Deep Research API não configurada - pulando fallback", {
            "has_enrichment": HAS_ACADEMIC_ENRICHMENT,
            "has_deep_key": bool(OPENAI_DEEP_KEY)
        })
        return None
    
    try:
        async with aiohttp.ClientSession() as session:
            # 1. Enviar requisição inicial (endpoint oficial)
            async with session.post(
                "https://api.openai.com/v1/responses",
                headers={
                    "Authorization": f"Bearer {OPENAI_DEEP_KEY}",
                    "Content-Type": "application/json"
                },
                json=payload,
                timeout=aiohttp.ClientTimeout(total=30)
            ) as response:
                if response.status != 202:
                    AUDIT_LOGGER.warning("Deep Research API error", {
                        "status": response.status,
                        "expected": 202
                    })
                    return None
                
                task_data = await response.json()
                task_id = task_data.get("id")
                
                if not task_id:
                    AUDIT_LOGGER.warning("Deep Research: task_id não retornado")
                    return None
            
            # 2. Polling até completar (conforme timeouts configuráveis)
            max_attempts = (DEEP_MAX_MIN * 60) // DEEP_POLL_SECS  # ex: 15min / 10s = 90
            
            for attempt in range(max_attempts):
                await asyncio.sleep(DEEP_POLL_SECS)
                
                async with session.get(
                    f"https://api.openai.com/v1/responses/{task_id}",
                    headers={"Authorization": f"Bearer {OPENAI_DEEP_KEY}"},
                    timeout=aiohttp.ClientTimeout(total=10)
                ) as poll_response:
                    if poll_response.status != 200:
                        continue
                    
                    result = await poll_response.json()
                    status = result.get("status")
                    
                    if status == "completed":
                        # Extração conforme spec oficial: response.output.message (não choices)
                        output = result.get("response", {}).get("output", {})
                        
                        # Estrutura de saída completa conforme spec:
                        # - web_search_call, code_interpreter_call, mcp_tool_call (para auditoria)
                        # - message (resposta final que precisamos)
                        content = output.get("message", {}).get("content", "")
                        
                        # Log de auditoria com ferramentas usadas
                        tool_calls_used = {
                            "web_search": len(output.get("web_search_call", [])),
                            "code_interpreter": len(output.get("code_interpreter_call", [])),
                            "mcp_tool": len(output.get("mcp_tool_call", []))
                        }
                        
                        try:
                            parsed = json.loads(content)
                            AUDIT_LOGGER.info("Deep Research completed", {
                                "task_id": task_id,
                                "attempts": attempt + 1,
                                "duration_sec": (attempt + 1) * DEEP_POLL_SECS,
                                "tool_calls_used": tool_calls_used
                            })
                            return parsed
                        except json.JSONDecodeError as e:
                            AUDIT_LOGGER.warning("Deep Research: JSON inválido", {
                                "task_id": task_id,
                                "content_preview": content[:100],
                                "tool_calls_used": tool_calls_used,
                                "error": str(e)
                            })
                            return None
                    elif status == "failed":
                        AUDIT_LOGGER.warning("Deep Research task failed", {
                            "task_id": task_id,
                            "attempt": attempt + 1
                        })
                        return None
            
            # Timeout após DEEP_MAX_MIN minutos
            AUDIT_LOGGER.warning("Deep Research timeout", {
                "task_id": task_id,
                "max_minutes": DEEP_MAX_MIN,
                "total_attempts": max_attempts
            })
            return None
            
    except (aiohttp.ClientError, asyncio.TimeoutError) as e:
        AUDIT_LOGGER.warning("Deep Research request failed", {"error": str(e)})
        return None

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
        if embeddings_hist and self.case.summary_embedding is not None:
            sims_hist = [cosine_similarity(self.case.summary_embedding, e) for e in embeddings_hist]
            outcomes = self.lawyer.case_outcomes
            if outcomes and len(outcomes) == len(sims_hist):
                weights = [1.0 if outcome else 0.8 for outcome in outcomes]
                sim_hist = float(np.average(sims_hist, weights=weights))
            else:
                sim_hist = float(np.mean(sims_hist))

        # ── 2-b) Similaridade com pareceres ───────────────────────────
        sim_par = 0.0
        if self.lawyer.pareceres and self.case.summary_embedding is not None:
            sims_par = [cosine_similarity(self.case.summary_embedding, p.embedding) for p in self.lawyer.pareceres]
            sim_par = float(max(sims_par)) if sims_par else 0.0

        # ── 2-c) Combinação ponderada ─────────────────────────────────
        if sim_par == 0:
            return sim_hist
        return 0.6 * sim_hist + 0.4 * sim_par

    def success_rate(self) -> float:
        """Success rate ponderado por valor econômico recuperado.

        Fórmula:
        1. Se houver dados de valor ⇒ taxa_ponderada = valor_recuperado / valor_total.
           • Penaliza amostras < 20 casos com fator (n/20).
        2. Caso contrário, cai no cálculo anterior (wins/cases) com smoothing.
        3. Multiplicador `success_status` mantém lógica V/P/N.
        """
        status_mult = {"V": 1.0, "P": 0.4, "N": 0.0}.get(self.lawyer.kpi.success_status, 0.0)

        kpi = self.lawyer.kpi
        if kpi.valor_total_30d > 0:
            base = kpi.valor_recuperado_30d / kpi.valor_total_30d
            # Penaliza baixa amostragem (<20 casos)
            sample_factor = min(1.0, kpi.cases_30d / 20.0)
            weighted = base * sample_factor
            return np.clip(weighted * status_mult, 0, 1)

        # --- fallback antigo ---
        key = f"{self.case.area}/{self.case.subarea}"
        granular = self.lawyer.kpi_subarea.get(key)
        total_cases = kpi.cases_30d or 1
        alpha = beta = 1
        if granular is not None:
            wins = int(granular * total_cases)
            base = (wins + alpha) / (total_cases + alpha + beta)
        else:
            wins_general = int(kpi.success_rate * total_cases)
            base = (wins_general + alpha) / (total_cases + alpha + beta)

        return np.clip(base * status_mult, 0, 1)

    def geo_score(self) -> float:
        dist = haversine(self.case.coords, self.lawyer.geo_latlon)
        return np.clip(1 - dist / self.case.radius_km, 0, 1)

    async def qualification_score_async(self) -> float:
        """(v2.8) Métrica de reputação enriquecida com dados acadêmicos externos."""
        cv = self.cv
        enricher = AcademicEnricher(cache)

        # ── 1. Experiência (inalterado) ──────────────────────────────
        score_exp = min(1.0, cv.get("anos_experiencia", 0) / 25)

        # ── 2. Universidades com enriquecimento acadêmico ────────────
        titles: List[Dict[str, str]] = cv.get("pos_graduacoes", [])
        
        # Extrair nomes de universidades
        uni_names = [t.get("instituicao", "") for t in titles if t.get("instituicao")]
        uni_names = [name.strip() for name in uni_names if name.strip()]
        
        # Obter scores acadêmicos das universidades
        uni_scores = await enricher.score_universities(uni_names) if uni_names else {}
        score_uni = float(np.mean(list(uni_scores.values()))) if uni_scores else 0.5

        # Contagem de títulos (lógica original mantida)
        counts = {"lato": 0, "mestrado": 0, "doutorado": 0}
        for t in titles:
            level = str(t.get("nivel", "")).lower()
            if level in counts and self.case.area.lower() in str(t.get("area", "")).lower():
                counts[level] += 1

        score_titles = 0.1 * min(counts["lato"], 2) / 2 + \
                       0.2 * min(counts["mestrado"], 2) / 2 + \
                       0.3 * min(counts["doutorado"], 2) / 2

        # ── 3. Publicações com qualidade de periódicos ──────────────
        pubs = cv.get("publicacoes", [])
        
        # Qualidade dos periódicos
        journ_names = [p.get("journal", "") for p in pubs if p.get("journal")]
        journ_names = [name.strip() for name in journ_names if name.strip()]
        journ_scores = await enricher.score_journals(journ_names) if journ_names else {}
        score_pub_qual = float(np.mean(list(journ_scores.values()))) if journ_scores else 0.5
        
        # Quantidade de publicações (lógica original)
        num_pubs = len(pubs) if pubs else cv.get("num_publicacoes", 0)
        score_pub_qty = min(1.0, math.log1p(num_pubs) / math.log1p(20))

        # ── 4. Pareceres relevantes (inalterado) ────────────────────
        num_pareceres_rel = len([p for p in self.lawyer.pareceres if self.case.area.lower() in p.area.lower()])
        score_par = min(1.0, math.log1p(num_pareceres_rel) / math.log1p(5))

        # ── 5. Reconhecimentos de mercado (inalterado) ──────────────
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

        # ── 6. Combinação final enriquecida ─────────────────────────
        final_score = (
            0.30 * score_exp +        # 30% experiência
            0.20 * score_titles +     # 20% títulos acadêmicos 
            0.15 * score_uni +        # 15% reputação das universidades (NOVO)
            0.10 * score_pub_qual +   # 10% qualidade dos periódicos (NOVO)
            0.05 * score_pub_qty +    # 5% quantidade de publicações
            0.10 * score_par +        # 10% pareceres
            0.10 * score_rec          # 10% reconhecimentos
        )

        # Integração com CV score v2.2 (reduzida devido ao enriquecimento)
        cv_score = self.lawyer.kpi.cv_score
        return 0.85 * final_score + 0.15 * cv_score

    def qualification_score(self) -> float:
        """Versão síncrona de fallback para compatibilidade."""
        # Quando APIs acadêmicas não estão disponíveis, usar lógica original simplificada
        cv = self.cv
        
        # Experiência
        score_exp = min(1.0, cv.get("anos_experiencia", 0) / 25)

        # Títulos acadêmicos
        titles: List[Dict[str, str]] = cv.get("pos_graduacoes", [])
        counts = {"lato": 0, "mestrado": 0, "doutorado": 0}
        for t in titles:
            level = str(t.get("nivel", "")).lower()
            if level in counts and self.case.area.lower() in str(t.get("area", "")).lower():
                counts[level] += 1

        score_titles = 0.1 * min(counts["lato"], 2) / 2 + \
                       0.2 * min(counts["mestrado"], 2) / 2 + \
                       0.3 * min(counts["doutorado"], 2) / 2

        # Publicações (lógica original)
        pubs = cv.get("num_publicacoes", 0)
        score_pub = min(1.0, math.log1p(pubs) / math.log1p(10))

        # Pareceres relevantes
        num_pareceres_rel = len([p for p in self.lawyer.pareceres if self.case.area.lower() in p.area.lower()])
        score_par = min(1.0, math.log1p(num_pareceres_rel) / math.log1p(5))

        # Reconhecimentos de mercado
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

        # Combinação final (pesos originais)
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

    # ---------------- Feature-P (Price / Fee Fit) ------------------

    def price_fit(self) -> float:
        """Feature-P: aderência de honorários ao orçamento do cliente.

        Precedência das modalidades (ordem de escolha):
        1. *Flat fee* – valor fixo declarado pelo advogado.
        2. *Success fee* – percentual sobre êxito (`success_fee_pct`).
        3. *Hourly fee* – média de horas.

        Se mais de uma modalidade estiver preenchida, utiliza-se a que
        aparecer primeiro na ordem acima. Caso a modalidade escolhida
        exceda o budget, aplica-se penalização exponencial controlada por
        ``PRICE_DECAY_K``.
        """
        max_budget = self.case.expected_fee_max or 0.0
        min_budget = self.case.expected_fee_min or 0.0
        
        if max_budget <= 0:
            return 0.5  # Neutro se caso não tem budget
        
        # Determinar fee efetivo baseado na modalidade disponível
        fee = 0.0
        
        if self.lawyer.flat_fee and self.lawyer.flat_fee > 0:
            fee = self.lawyer.flat_fee
        elif self.lawyer.success_fee_pct and self.lawyer.success_fee_pct > 0:
            # Estimar fee baseado no percentual sobre valor esperado do caso
            estimated_case_value = max_budget * SUCCESS_FEE_MULT  # Configurável via ENV
            fee = estimated_case_value * (self.lawyer.success_fee_pct / 100)
        elif self.lawyer.avg_hourly_fee > 0:
            fee = self.lawyer.avg_hourly_fee
        
        if fee <= 0:
            return 0.5  # Neutro quando não há dados
        
        # Score máximo quando dentro do intervalo
        if min_budget <= fee <= max_budget:
            return 1.0
        
        # Distância percentual relativa com decay configurável
        if fee < min_budget and min_budget > 0:
            diff = (min_budget - fee) / min_budget
        else:
            diff = (fee - max_budget) / max_budget
        
        # Decay exponencial configurável via ENV
        return float(np.exp(-PRICE_DECAY_K * diff))
    
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

    def firm_semantic_similarity(self) -> float:
        """Calcula a similaridade semântica entre o caso e o perfil do escritório."""
        firm = getattr(self.lawyer, "firm", None)
        if not firm or not hasattr(firm, 'embedding') or firm.embedding is None:
            return 0.0
        
        if self.case.summary_embedding is None:
            return 0.0

        return cosine_similarity(self.case.summary_embedding, firm.embedding)

    def firm_reputation(self) -> float:
        """
        🆕 Feature-E: Employer / Firm Reputation (v2.9 com similaridade semântica)
        Escora reputação do escritório, combinando KPIs com relevância para o caso.
        • Caso o advogado não possua firm_id ⇒ score neutro 0.5
        • Fórmula ponderada: performance, reputação, diversidade, maturidade E similaridade semântica.
        """
        firm = getattr(self.lawyer, "firm", None)
        if not firm or not hasattr(firm, 'kpi_firm'):
            return 0.5
        
        k = firm.kpi_firm
        
        # Parte 1: Score de Reputação (baseado em KPIs)
        reputation_score = np.clip(
            0.35 * k.success_rate +
            0.20 * k.nps +
            0.15 * k.reputation_score +
            0.10 * k.diversity_index +
            0.20 * k.maturity_index,
            0, 1
        )

        # Parte 2: Similaridade Semântica
        semantic_similarity = self.firm_semantic_similarity()

        # Combinação Final Ponderada
        final_score = (0.7 * reputation_score) + (0.3 * semantic_similarity)
        
        return np.clip(final_score, 0, 1)

    def maturity_score(self) -> float:
        """
        🆕 Feature-M: Professional Maturity (Meisterline/PQE proxy)
        
        Calcula a maturidade profissional usando a estrutura de dados padronizada,
        independente da API de origem (Unipile, LinkedIn, etc.).
        
        Returns:
            float: Score de maturidade normalizado entre 0 e 1
        """
        data = self.lawyer.maturity_data
        if not data:
            return 0.5  # Neutro se não houver dados de maturidade

        # 1. Experiência profissional (proxy para PQE)
        # Normaliza até 20 anos de experiência
        score_exp = min(1.0, data.experience_years / 20.0)

        # 2. Força da rede profissional (proxy para networking e reputação)
        # Normaliza logaritmicamente
        score_network = min(1.0, log1p(data.network_strength) / log1p(500))  # 500+ é um bom sinal

        # 3. Sinais de reputação (recomendações, endorsements, etc.)
        score_reco = min(1.0, log1p(data.reputation_signals) / log1p(10))  # 10+ recomendações é excelente

        # 4. Responsividade de comunicação (importante para o cliente)
        # Penaliza tempos de resposta > 24h
        score_resp = np.clip(1 - (data.responsiveness_hours / 48), 0, 1)

        # 5. Combinação Ponderada
        final_score = (
            0.40 * score_exp +       # 40% Experiência
            0.25 * score_network +   # 25% Networking
            0.15 * score_reco +      # 15% Recomendações
            0.20 * score_resp        # 20% Responsividade
        )
        return np.clip(final_score, 0, 1)

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
            "E": self.firm_reputation(), # Nova feature E
            "P": self.price_fit(),       # Nova feature P
            "M": self.maturity_score(),  # 🆕 Feature M (Maturity)
        }

    async def all_async(self) -> Dict[str, float]:
        """Versão assíncrona com enriquecimento acadêmico na feature Q."""
        return {
            "A": self.area_match(),
            "S": self.case_similarity(),
            "T": self.success_rate(),
            "G": self.geo_score(),
            "Q": await self.qualification_score_async(),  # Único await interno
            "U": self.urgency_capacity(),
            "R": self.review_score(),
            "C": self.soft_skill(),
            "E": self.firm_reputation(),
            "P": self.price_fit(),
            "M": self.maturity_score(),
        }

# =============================================================================
# 7. Core algorithm expandido
# =============================================================================


class MatchmakingAlgorithm:
    """Gera ranking justo de advogados para um caso com features v2.2."""
    
    def __init__(self, cache=None):
        """Inicializa algoritmo com templates acadêmicos."""
        self.cache = cache
        # Importar templates organizados
        try:
            from ..services.academic_prompt_templates import AcademicPromptTemplates, AcademicPromptValidator
            self.templates = AcademicPromptTemplates()
            self.validator = AcademicPromptValidator()
        except ImportError:
            # Fallback para execução standalone
            from academic_prompt_templates import AcademicPromptTemplates, AcademicPromptValidator
            self.templates = AcademicPromptTemplates()
            self.validator = AcademicPromptValidator()

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
    async def _safe_conflict_scan(self, case: Case, lawyer: Lawyer) -> bool:
        """
        Versão segura do conflict_scan com timeout para evitar dead-locks.
        
        Returns:
            True se há conflito de interesse, False caso contrário
        """
        try:
            # Wrap função síncrona em task assíncrona com timeout
            return await asyncio.wait_for(
                asyncio.get_event_loop().run_in_executor(
                    None, conflict_scan, case, lawyer
                ),
                timeout=CONFLICT_TIMEOUT_SEC
            )
        except asyncio.TimeoutError:
            # Timeout: fail-open (assume sem conflito) e loga alerta
            AUDIT_LOGGER.warning("Conflict scan timeout - fail-open mode", {
                "case_id": case.id, 
                "lawyer_id": lawyer.id, 
                "timeout": CONFLICT_TIMEOUT_SEC
            })
            return False
        except Exception as e:
            # Outros erros: fail-open e loga erro
            AUDIT_LOGGER.warning("Conflict scan error - fail-open mode", {
                "case_id": case.id, 
                "lawyer_id": lawyer.id, 
                "error": str(e)
            })
            return False

    # ------------------------------------------------------------------
    async def _calculate_ltr_scores_parallel(self, lawyers: List[Lawyer], weights: Dict[str, float], 
                                           case: Case, preset: str, degraded_mode: bool) -> None:
        """
        Calcula scores LTR em paralelo usando httpx.AsyncClient.
        Faz fallback para soma ponderada em caso de erro/timeout.
        """
        async def _single_ltr_request(client: httpx.AsyncClient, lw: Lawyer) -> None:
            features = lw.scores["features"]
            try:
                payload = {"features": features}
                print(f"🔍 DEBUG: Enviando para LTR - Lawyer {lw.id}")
                print(f"    Endpoint: {LTR_ENDPOINT}")
                print(f"    Payload: {payload}")
                
                resp = await client.post(
                    LTR_ENDPOINT, 
                    json=payload, 
                    timeout=2.0
                )
                print(f"    Status: {resp.status_code}")
                resp.raise_for_status()
                score_ltr = resp.json()["score"]
                lw.scores["source"] = "ltr"
                print(f"    ✅ LTR Score: {score_ltr}")
            except Exception as e:
                print(f"    ❌ Erro LTR: {type(e).__name__}: {e}")
                if hasattr(e, 'response') and hasattr(e.response, 'text'):
                    print(f"    Response: {e.response.text}")
                # Fallback para soma ponderada
                score_ltr = sum(features.get(k, 0) * weights.get(k, 0) for k in weights)
                lw.scores["source"] = "weights"
            
            # Atribuir scores e deltas
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

        # Executar todas as requisições LTR em paralelo
        async with httpx.AsyncClient() as client:
            tasks = [_single_ltr_request(client, lw) for lw in lawyers]
            await asyncio.gather(*tasks, return_exceptions=True)

    # ------------------------------------------------------------------
    async def _rank_firms(self, case: Case, firms: List[LawFirm], *, top_n: int = 3) -> List[LawFirm]:
        """
        Ranking específico de escritórios para o passo 1 do algoritmo B2B.
        
        Args:
            case: Caso para matching
            firms: Lista de escritórios candidatos
            top_n: Número máximo de escritórios a retornar
            
        Returns:
            Lista de escritórios ordenados por reputação
        """
        if not firms:
            return []
            
        # 1. Lógica de Gating / Boost para Casos Premium (análoga a advogados)
        if case.is_premium:
            case_creation_time = getattr(case, 'created_at', datetime.utcnow())
            window_end = case_creation_time + timedelta(minutes=case.premium_exclusive_min)

            if datetime.utcnow() < window_end:
                # Durante a janela, filtrar apenas escritórios PRO ou PARTNER
                premium_firms = [
                    f for f in firms 
                    if getattr(f, 'plan', 'FREE').upper() in ["PRO", "PARTNER"]
                ]
                if premium_firms:
                    firms = premium_firms
            else:
                # Após a janela, aplicar boost
                PRO_BOOST = 0.08
                PARTNER_BOOST = 0.05
                TIER_BOOST = {
                    "SILVER": 0.02,
                    "GOLD": 0.04,
                    "PLATINUM": 0.06
                }
                
                for firm in firms:
                    plan = getattr(firm, 'plan', 'FREE').upper()
                    tier = getattr(firm, 'partnerTier', 'STANDARD').upper()
                    
                    boost = 0.0
                    if plan == "PRO":
                        boost += PRO_BOOST
                    elif plan == "PARTNER":
                        boost += PARTNER_BOOST
                    
                    boost += TIER_BOOST.get(tier, 0.0)
                    
                    if boost > 0:
                        firm.scores['premium_boost'] = firm.scores.get('premium_boost', 0) + boost

        # 2. Calcular score de reputação para cada escritório
        for firm in firms:
            calculator = FeatureCalculator(case, firm)
            reputation_score = calculator.firm_reputation()
            
            # Adicionar métricas específicas de escritório
            firm.scores.update({
                "firm_reputation": reputation_score,
                "team_size_score": min(1.0, firm.team_size / 50.0),  # Normalizar até 50 pessoas
                "features": await calculator.all_async(),  # Usar versão assíncrona
                "preset": "b2b_firm",
                "step": "firm_ranking",
                "algorithm_version": algorithm_version  # Versionamento centralizado
            })
            
            # Score final ponderado para escritórios
            base_score = (
                0.7 * reputation_score +
                0.2 * firm.scores["features"].get("A", 0) +
                0.1 * firm.scores["features"].get("G", 0)
            )

            # Aplicar boost, se houver
            final_score = base_score + firm.scores.get('premium_boost', 0.0)
            firm.scores["final_score"] = np.clip(final_score, 0, 1.0)

        # 3. Ordenar por score final
        firms.sort(key=lambda f: f.scores["final_score"], reverse=True)
        
        # 4. Log de auditoria para cada escritório ranqueado
        for i, firm in enumerate(firms[:top_n]):
            AUDIT_LOGGER.info(f"Escritório ranqueado #{i+1}", {
                "case_id": case.id,
                "firm_id": firm.id,
                "firm_name": firm.nome,
                "final_score": round(firm.scores["final_score"], 4),
                "base_score": round(firm.scores.get('base_score', firm.scores['final_score']), 4),
                "premium_boost": round(firm.scores.get('premium_boost', 0.0), 4),
                "reputation_score": round(firm.scores["firm_reputation"], 4),
                "team_size": firm.team_size,
                "area_match": round(firm.scores["features"]["A"], 3),
                "algorithm_version": algorithm_version
            })
        
        return firms[:top_n]

    # ------------------------------------------------------------------
    async def rank(self, case: Case, lawyers: List[Lawyer], *, top_n: int = 5,
                   preset: str = "balanced", model_version: Optional[str] = None,
                   exclude_ids: Optional[Set[str]] = None) -> List['Recommendation']:
        """Classifica advogados para um caso e mescla com recomendações patrocinadas."""
        
        if not lawyers:
            return []

        # --- Feature Flags: Controle de B2B ---
        if preset == "balanced" and hasattr(case, 'type') and case.type == "CORPORATE":
            preset = get_corporate_preset()
        
        if preset == "balanced":
            if hasattr(case, 'expected_fee_max') and case.expected_fee_max and case.expected_fee_max < 1500:
                preset = "economic"
                AUDIT_LOGGER.info("Auto-activated economic preset", {
                    "case_id": case.id,
                    "max_budget": case.expected_fee_max,
                    "threshold": 1500
                })
        
        firm_matching_enabled = is_firm_matching_enabled()
        
        AUDIT_LOGGER.info("Feature flags status", {
            "case_id": case.id,
            "firm_matching_enabled": firm_matching_enabled,
            "preset": preset,
            "segmented_cache_enabled": is_segmented_cache_enabled()
        })

        if exclude_ids:
            lawyers = [lw for lw in lawyers if lw.id not in exclude_ids]
            if not lawyers:
                return []

        # 0. Filtrar conflitos de interesse
        filtered_lawyers = []
        for lw in lawyers:
            if not await self._safe_conflict_scan(case, lw):
                filtered_lawyers.append(lw)
        lawyers = filtered_lawyers
        if not lawyers:
            return []
            
        # 4️⃣ Lógica de Gating / Boost para Casos Premium
        if case.is_premium:
            case_creation_time = getattr(case, 'created_at', datetime.utcnow())
            window_end = case_creation_time + timedelta(minutes=case.premium_exclusive_min)

            if datetime.utcnow() < window_end:
                pro_lawyers = [l for l in lawyers if getattr(l, 'plan', 'FREE').upper() == "PRO"]
                if pro_lawyers:
                    lawyers = pro_lawyers
            else:
                PRO_BONUS = 0.08
                for lawyer in lawyers:
                    if getattr(lawyer, 'plan', 'FREE').upper() == "PRO":
                        if 'pro_boost' not in lawyer.scores:
                             lawyer.scores['pro_boost'] = PRO_BONUS
        
        # --- Two-pass B2B Algorithm ---
        if preset == 'b2b':
            firm_candidates = [lw.firm for lw in lawyers if lw.firm_id and lw.firm]
            if firm_candidates:
                unique_firms = {f.id: f for f in firm_candidates}.values()
                firm_ranking = await self._rank_firms(case, list(unique_firms), top_n=3)
                top_firm_ids = {f.id for f in firm_ranking}
                
                b2b_lawyers = [lw for lw in lawyers if lw.firm_id in top_firm_ids]
                if not b2b_lawyers:
                    b2b_lawyers = [lw for lw in lawyers if not lw.firm_id]
                lawyers = b2b_lawyers

        # 1. Carregar e aplicar pesos
        experimental_weights = load_experimental_weights(model_version) if model_version else None
        base_weights = experimental_weights or (_current_weights or DEFAULT_WEIGHTS).copy()
        base_weights.update(load_preset(preset))
        weights = self.apply_dynamic_weights(case, base_weights)

        # 2. Filtro de disponibilidade
        lawyer_ids = [lw.id for lw in lawyers]
        timeout_sec = float(os.getenv("AVAIL_TIMEOUT", "1.5"))
        coverage_threshold = float(os.getenv("AVAIL_COVERAGE_THRESHOLD", "0.8"))
        
        try:
            availability_map = await asyncio.wait_for(get_lawyers_availability_status(lawyer_ids), timeout=timeout_sec)
            degraded_mode = not availability_map or (len(availability_map) / len(lawyer_ids)) < coverage_threshold
        except asyncio.TimeoutError:
            availability_map, degraded_mode = {}, True
        
        if degraded_mode:
            availability_map = {lw.id: True for lw in lawyers}
            if HAS_PROMETHEUS:
                AVAIL_DEGRADED.inc()

        available_lawyers = [lw for lw in lawyers if availability_map.get(lw.id, not degraded_mode)]

        # 3. Calcular features
        for lw in available_lawyers:
            calculator = FeatureCalculator(case, lw)
            lw.scores["features"] = await calculator.all_async()

        # 4. Calcular scores LTR
        await self._calculate_ltr_scores_parallel(available_lawyers, weights, case, preset, degraded_mode)

        if not available_lawyers:
            return []

        # 5. Aplicar ε-cluster, equidade e diversidade
        max_score = max(lw.scores["ltr"] for lw in available_lawyers) if available_lawyers else 0
        elite = [lw for lw in available_lawyers if lw.scores["ltr"] >= max_score - max(MIN_EPSILON, 0.10 * max_score)]
        
        for lw in elite:
            equity = self.equity_weight(lw.kpi, lw.max_concurrent_cases)
            lw.scores["equity_raw"] = equity
            lw.scores["fair_base"] = (1 - BETA_EQUITY) * lw.scores["ltr"] + BETA_EQUITY * equity
        
        current_ranking = sorted(elite, key=lambda l: l.scores["fair_base"], reverse=True)
        for dimension in ["gender", "ethnicity", "pcd", "orientation"]:
            boosts = self._calculate_dimension_boost(current_ranking, dimension)
            for lw in current_ranking:
                lw.scores["fair_base"] += boosts.get(lw.id, 0.0)
            current_ranking.sort(key=lambda l: l.scores["fair_base"], reverse=True)
        
        final_ranking = current_ranking

        # 6. Log e ordenação final
        for lw in final_ranking[:top_n]:
            AUDIT_LOGGER.info(f"Lawyer {lw.id} ranked for case {case.id}", {"case_id": case.id, "lawyer_id": lw.id, "scores": safe_json_dump(lw.scores), "model_version": model_version or "production", "preset": preset})
        
        final_ranking.sort(key=lambda l: (-l.scores["fair_base"], l.last_offered_at))
        
        now = time.time()
        for lw in final_ranking[:top_n]:
            lw.last_offered_at = now
        
        # 7. Mesclar com recomendações patrocinadas
        organic_recommendations = []
        for lw in final_ranking[:top_n]:
            fair_score = lw.scores.get('fair_base', 0.0)
            if 'pro_boost' in lw.scores:
                fair_score = min(fair_score + lw.scores['pro_boost'], 1.0)
            organic_recommendations.append(Recommendation(lawyer=lw, fair_score=fair_score, is_sponsored=False))

        sponsored_lawyers = await fetch_ads_for_case(case, limit=3)
        sponsored_recommendations = [Recommendation(lawyer=sl, fair_score=sl.scores.get('fair_base', 0.0), is_sponsored=True, ad_campaign_id=getattr(sl, 'ad_meta', {}).get('campaign_id')) for sl in sponsored_lawyers]

        return organic_recommendations + sponsored_recommendations

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
            maturity_data=ProfessionalMaturityData(
                experience_years=exp,
                network_strength=100, # Mock
                reputation_signals=50, # Mock
                responsiveness_hours=24 # Mock
            )
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
        """Demonstração do algoritmo v2.9-unified."""
        print(f"🚀 Demo do Algoritmo de Match {algorithm_version}")
        print("=" * 60)

        matcher = MatchmakingAlgorithm()

        # Teste com preset "expert" para caso complexo
        ranking_v2 = await matcher.rank(case_demo, lawyers_demo, top_n=3, preset="expert")

        header = f"\n—— Resultado do Ranking {algorithm_version} (B2B Two-Pass + Feature-E) ——"
        print(header)
        for pos, rec in enumerate(ranking_v2, 1):
            adv = rec.lawyer
            scores = adv.scores
            feats = scores["features"]
            delta = scores["delta"]

            sponsored_tag = "🚀" if rec.is_sponsored else ""
            print(f"{pos}º {adv.nome} {sponsored_tag}")
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

        print(f"\n📊 Observações {algorithm_version}:")
        print("• Academic Enrichment: Universidades e periódicos avaliados via APIs externas")
        print("• Sponsored recommendations e lógica de casos premium integradas")
        print("• Validação robusta: Sanitização e validação de inputs")
        print("• Feature-E (Firm Reputation) e B2B Two-Pass mantidos")
        print("• Safe conflict scan e configurações via ENV")
        print("• Logs estruturados com métricas acadêmicas")

    async def test_academic_enrichment():
        """Testes mínimos para enriquecimento acadêmico."""
        print("\n🧪 Testando Academic Enrichment com Templates Consolidados")
        print("=" * 60)
        
        enricher = AcademicEnricher(cache)
        
        # Teste validador e canonical
        try:
            enricher.validator.validate_batch_size(['a', 'b'], 15)
            assert canonical("Universidade de São Paulo") == "universidade_de_sao_paulo"
            print("✅ Validador e canonical() funcionando")
        except Exception as e:
            print(f"❌ Erro no validador/canonical: {e}")
            return
        
        if HAS_ACADEMIC_ENRICHMENT and PERPLEXITY_API_KEY:
            print("⚡ Testando com APIs reais...")
            uni_scores = await enricher.score_universities(['Universidade de São Paulo', 'Harvard Law School'])
            print(f"Scores de universidades: {uni_scores}")
            
            jour_scores = await enricher.score_journals(['Revista de Direito Administrativo', 'Harvard Law Review'])
            print(f"Scores de periódicos: {jour_scores}")
        else:
            print("⚠️  APIs acadêmicas não configuradas - pulando testes com APIs reais")
        
        print("🎉 Testes de enriquecimento acadêmico concluídos!")

    async def run_all_demos():
        """Executa todos os demos e testes."""
        await demo_v2()
        await test_academic_enrichment()

    import asyncio
    asyncio.run(run_all_demos())


@atexit.register
def _close_redis():
    try:
        loop = asyncio.get_event_loop()
        if not loop.is_closed():
            loop.run_until_complete(cache.close())
    except RuntimeError:
        pass
