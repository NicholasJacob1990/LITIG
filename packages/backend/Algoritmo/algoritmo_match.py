# -*- coding: utf-8 -*-
"""algoritmo_match.py
Algoritmo de Match Jurídico Inteligente — v2.11-full-escavador
======================================================================
Versão consolidada que combina funcionalidades das versões:
- v2.7-rc3: Sponsored recommendations, premium cases, complete logging
- v2.8-academic: Academic enrichment, LTR service, async features
- v2.9-unified: Sistema híbrido completo
- v2.10-iep: 🆕 Feature I - Índice de Engajamento na Plataforma (IEP)
- v2.11-full-escavador: 🆕 Uso completo dos dados do Escavador (100%)

Funcionalidades v2.11-full-escavador 🚀
----------------------------------------
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
8.  🆕 **IEP Integration**: Feature I - Índice de Engajamento na Plataforma
    - Recompensa advogados engajados e penaliza oportunismo
    - Pré-calculado pelo job calculate_engagement_scores.py
    - Integrado em todos os presets de matching
    - Beneficia tanto cliente→advogado quanto advogado→advogado
9.  🆕 **100% Escavador Data Usage**: Uso completo dos dados do currículo Lattes
    - Feature Q expandida com projetos de pesquisa e prêmios
    - Feature L nova para idiomas e participação em eventos
    - Análise avançada de formação acadêmica e experiência
    - Scoring inteligente de atividades de networking e atualização profissional

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
# Imports relativos condicionais para evitar problemas quando arquivo é executado diretamente
try:
    from ..schemas.recommendation import Recommendation
    from ..services.ads_service import fetch_ads_for_case
    from ..services.weight_optimizer_service import get_optimized_weights
except ImportError:
    # Fallback quando executado diretamente ou em contexto diferente
    try:
        from schemas.recommendation import Recommendation
        from services.ads_service import fetch_ads_for_case
        from services.weight_optimizer_service import get_optimized_weights
    except ImportError:
        # Último fallback: definir classes/funções mock
        try:
            from .logging import log_warning
            log_warning("Imports de schemas/services não disponíveis - usando fallbacks", 
                        component="initialization", fallback_mode=True)
        except ImportError:
            print("⚠️ Imports de schemas/services não disponíveis - usando fallbacks")
        class Recommendation:
            pass
        def fetch_ads_for_case(*args, **kwargs):
            return []
        def get_optimized_weights(*args, **kwargs):
            return {}
import re
import unicodedata
import hashlib
import math

# type: ignore - para ignorar erros de importação não resolvidos
import numpy as np
import redis.asyncio as aioredis

# Logging estruturado (importado no topo para evitar problemas de ordem)
from .logging import log_warning, log_error, log_info, log_debug

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

# 🆕 FASE 1: Unified Cache Service Integration
try:
    from .services.unified_cache_service import UnifiedCacheService, CachedFeatures, unified_cache
    UNIFIED_CACHE_AVAILABLE = True
except ImportError:
    UNIFIED_CACHE_AVAILABLE = False
    unified_cache = None
    try:
        from .logging import log_warning
        log_warning("UnifiedCacheService não disponível - usando cache Redis básico",
                    component="cache", cache_type="redis_fallback")
    except ImportError:
        print("⚠️ UnifiedCacheService não disponível - usando cache Redis básico")

# 🆕 FASE 2: Case Match ML Service Integration  
try:
    from .services.case_match_ml_service import CaseMatchMLService, create_case_match_ml_service
    CASE_MATCH_ML_AVAILABLE = True
except ImportError:
    CASE_MATCH_ML_AVAILABLE = False
    try:
        from .logging import log_warning
        log_warning("CaseMatchMLService não disponível - usando pesos estáticos",
                    component="ml_service", fallback="static_weights")
    except ImportError:
        print("⚠️ CaseMatchMLService não disponível - usando pesos estáticos")

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
    "A": 0.22, "S": 0.17, "T": 0.10, "G": 0.07,
    "Q": 0.07, "U": 0.05, "R": 0.05, "C": 0.03,
    "E": 0.02, "P": 0.02, "M": 0.14, "I": 0.02,
    "L": 0.04  # 🆕 Feature L (Languages & Events)
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
        "A": 0.38, "S": 0.15, "T": 0.18, "G": 0.15,
        "Q": 0.07, "U": 0.03, "R": 0.01,
        "C": 0.00, "P": 0.00, "E": 0.00, "M": 0.00, "I": 0.01, "L": 0.02  # 🆕 Features I+L
    },
    "expert": {
        "A": 0.18, "S": 0.24, "T": 0.13, "G": 0.05,
        "Q": 0.15, "U": 0.05, "R": 0.03,
        "C": 0.02, "P": 0.01, "E": 0.00, "M": 0.08, "I": 0.02, "L": 0.04  # 🆕 Features I+L
    },
    "balanced": DEFAULT_WEIGHTS,
    "economic": {
        "A": 0.16, "S": 0.11, "T": 0.06, "G": 0.16,
        "Q": 0.04, "U": 0.16, "R": 0.05,
        "C": 0.05, "P": 0.11, "E": 0.00, "M": 0.04, "I": 0.01, "L": 0.05  # 🆕 Features I+L
    },
    "b2b": {
        "A": 0.11, "S": 0.14, "T": 0.13, "Q": 0.16,
        "E": 0.10, "G": 0.05, "U": 0.05, "R": 0.03,
        "C": 0.03, "P": 0.09, "M": 0.04, "I": 0.02, "L": 0.05  # 🆕 Features I+L (importante para B2B)
    },
    "correspondent": {
        "A": 0.09, "S": 0.05, "T": 0.04, "G": 0.24,
        "Q": 0.09, "U": 0.19, "R": 0.03, "C": 0.05,
        "E": 0.02, "P": 0.14, "M": 0.00, "I": 0.01, "L": 0.05  # 🆕 Features I+L
    },
    "expert_opinion": {
        "A": 0.09, "S": 0.29, "T": 0.02, "G": 0.00,
        "Q": 0.34, "U": 0.00, "R": 0.00, "C": 0.00,
        "E": 0.02, "P": 0.00, "M": 0.19, "I": 0.01, "L": 0.04  # 🆕 Features I+L
    }
}

# Validação automática dos presets na inicialização
def _validate_preset_weights():
    """Valida se todos os presets somam 1.0 (±1e-6)."""
    for name, weights in PRESET_WEIGHTS.items():
        total = sum(weights.values())
        if abs(total - 1.0) > 1e-6:
            raise ValueError(f"Preset '{name}' não soma 1.0 (soma={total:.6f})")
    try:
        from .logging import log_info
        log_info("Todos os presets validados", 
                 component="configuration", validation="weights", sum_check=1.0)
    except ImportError:
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

        # ── 5. Projetos de pesquisa (NOVO) ──────────────────────────
        projetos = cv.get("projetos_pesquisa", [])
        score_projetos = 0.0
        if projetos:
            # Contar projetos relevantes para a área do caso
            projetos_relevantes = [
                p for p in projetos 
                if self.case.area.lower() in str(p.get("area", "")).lower() or
                   self.case.area.lower() in str(p.get("descricao", "")).lower()
            ]
            # Score baseado no número de projetos relevantes
            score_projetos = min(1.0, len(projetos_relevantes) / 3.0)  # Máximo 3 projetos
        
        # ── 6. Prêmios e títulos acadêmicos (NOVO) ──────────────────
        premios = cv.get("premios", [])
        score_premios = 0.0
        if premios:
            # Peso por tipo de prêmio
            pontos_premios = 0.0
            for premio in premios:
                nome_premio = str(premio.get("nome", "")).lower()
                if any(keyword in nome_premio for keyword in [
                    "melhor", "excelência", "destaque", "prêmio", "honra"
                ]):
                    pontos_premios += 0.3
                elif any(keyword in nome_premio for keyword in [
                    "participação", "conclusão", "certificado"
                ]):
                    pontos_premios += 0.1
                else:
                    pontos_premios += 0.2  # Prêmio genérico
            score_premios = min(1.0, pontos_premios)
        
        # ── 7. Reconhecimentos de mercado (expandido) ───────────────
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

        # ── 8. Combinação final enriquecida (100% dados Escavador) ──
        final_score = (
            0.25 * score_exp +        # 25% experiência
            0.18 * score_titles +     # 18% títulos acadêmicos 
            0.15 * score_uni +        # 15% reputação das universidades
            0.10 * score_pub_qual +   # 10% qualidade dos periódicos
            0.05 * score_pub_qty +    # 5% quantidade de publicações
            0.08 * score_projetos +   # 8% projetos de pesquisa (NOVO)
            0.07 * score_premios +    # 7% prêmios acadêmicos (NOVO)
            0.07 * score_par +        # 7% pareceres
            0.05 * score_rec          # 5% reconhecimentos de mercado
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

    def interaction_score(self) -> float:
        """
        🆕 Feature-I: Índice de Engajamento na Plataforma (IEP)
        
        Pontuação de 0 a 1 baseada no engajamento do advogado na plataforma.
        Recompensa comportamento positivo e penaliza oportunismo.
        
        O IEP é pré-calculado pelo job calculate_engagement_scores.py e armazenado
        na coluna interaction_score da tabela lawyers.
        
        Returns:
            float: Score de engajamento normalizado entre 0 e 1
        """
        # Obter o IEP pré-calculado do perfil do advogado
        iep_score = getattr(self.lawyer, 'interaction_score', None)
        
        # Se não houver IEP calculado, usar valor neutro
        if iep_score is None:
            return 0.5  # Neutro para advogados sem histórico suficiente
        
        # Garantir que está no range [0, 1]
        return float(np.clip(iep_score, 0.0, 1.0))

    def languages_events_score(self) -> float:
        """
        🆕 Feature-L: Languages & Events (Idiomas e Participação em Eventos)
        
        Pontuação baseada em:
        1. Proficiência em idiomas (importantes para casos internacionais)
        2. Participação em eventos acadêmicos/profissionais
        3. Atividade de networking e atualização profissional
        
        Returns:
            float: Score normalizado entre 0 e 1
        """
        cv = self.cv
        
        # ── 1. Score de idiomas ──────────────────────────────────────
        idiomas = cv.get("idiomas", [])
        score_idiomas = 0.0
        
        if idiomas:
            pontos_idiomas = 0.0
            for idioma in idiomas:
                idioma_nome = str(idioma.get("idioma", "")).lower()
                nivel = str(idioma.get("nivel", "")).lower()
                
                # Peso por idioma (inglês e espanhol são mais valorizados no direito)
                peso_idioma = 1.0
                if "inglês" in idioma_nome or "english" in idioma_nome:
                    peso_idioma = 1.5  # Inglês é muito importante
                elif any(lang in idioma_nome for lang in ["espanhol", "spanish", "français", "francês"]):
                    peso_idioma = 1.2  # Outros idiomas importantes
                
                # Peso por nível de proficiência
                peso_nivel = 0.3  # Básico
                if any(keyword in nivel for keyword in ["fluente", "avançado", "advanced", "fluent"]):
                    peso_nivel = 1.0
                elif any(keyword in nivel for keyword in ["intermediário", "intermediate", "médio"]):
                    peso_nivel = 0.7
                elif any(keyword in nivel for keyword in ["básico", "basic", "iniciante"]):
                    peso_nivel = 0.3
                
                pontos_idiomas += peso_idioma * peso_nivel
            
            # Normalizar score de idiomas (máximo 3 idiomas fluentes = score 1.0)
            score_idiomas = min(1.0, pontos_idiomas / 4.5)
        
        # ── 2. Score de eventos ──────────────────────────────────────
        eventos = cv.get("eventos", [])
        score_eventos = 0.0
        
        if eventos:
            # Contar eventos por tipo e relevância
            pontos_eventos = 0.0
            eventos_recentes = 0  # Últimos 3 anos
            
            from datetime import datetime
            ano_atual = datetime.now().year
            
            for evento in eventos:
                ano_evento = evento.get("ano")
                tipo_evento = str(evento.get("tipo", "")).lower()
                nome_evento = str(evento.get("nome", "")).lower()
                
                # Peso por tipo de evento
                peso_tipo = 0.2  # Padrão
                if any(keyword in tipo_evento for keyword in [
                    "congresso", "conference", "seminário", "simpósio"
                ]):
                    peso_tipo = 1.0  # Eventos acadêmicos importantes
                elif any(keyword in tipo_evento for keyword in [
                    "workshop", "curso", "treinamento", "capacitação"
                ]):
                    peso_tipo = 0.8  # Eventos de capacitação
                elif any(keyword in tipo_evento for keyword in [
                    "palestra", "lecture", "webinar"
                ]):
                    peso_tipo = 0.6  # Eventos menores
                
                # Bonus por eventos recentes (últimos 3 anos)
                bonus_recencia = 1.0
                if ano_evento and ano_atual - ano_evento <= 3:
                    bonus_recencia = 1.3
                    eventos_recentes += 1
                elif ano_evento and ano_atual - ano_evento <= 5:
                    bonus_recencia = 1.1
                
                # Bonus por relevância à área do caso
                bonus_relevancia = 1.0
                if self.case.area.lower() in nome_evento or self.case.area.lower() in tipo_evento:
                    bonus_relevancia = 1.4
                
                pontos_eventos += peso_tipo * bonus_recencia * bonus_relevancia
            
            # Bonus por participação consistente (5+ eventos recentes)
            if eventos_recentes >= 5:
                pontos_eventos *= 1.2
            
            # Normalizar score de eventos (máximo ~8 pontos = score 1.0)
            score_eventos = min(1.0, pontos_eventos / 8.0)
        
        # ── 3. Combinação final ──────────────────────────────────────
        # 60% idiomas (mais importante para casos internacionais)
        # 40% eventos (importante para networking e atualização)
        final_score = 0.6 * score_idiomas + 0.4 * score_eventos
        
        return float(np.clip(final_score, 0.0, 1.0))

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
            "I": self.interaction_score(),  # 🆕 Feature I (IEP - Índice de Engajamento)
            "L": self.languages_events_score(),  # 🆕 Feature L (Languages & Events)
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
            "I": self.interaction_score(),  # 🆕 Feature I (IEP - Índice de Engajamento)
            "L": self.languages_events_score(),  # 🆕 Feature L (Languages & Events)
        }

    # 🆕 FASE 1: Cache Inteligente de Features
    async def all_async_cached(self) -> Dict[str, float]:
        """
        🆕 FASE 1: Versão com cache inteligente usando UnifiedCacheService.
        
        Evita recálculos desnecessários de features pesadas como Q (qualification_score_async)
        mantendo TTL otimizado de 24h para máxima performance.
        """
        if not UNIFIED_CACHE_AVAILABLE or not unified_cache:
            # Fallback para cálculo direto se cache não disponível
            return await self.all_async()
        
        try:
            # Tentar obter features do cache unificado
            cached_features = await self._get_or_calculate_cached_features()
            
            if cached_features:
                return {
                    "A": cached_features.area_match_score or self.area_match(),
                    "S": cached_features.similarity_score or self.case_similarity(),
                    "T": cached_features.success_rate_score or self.success_rate(),
                    "G": cached_features.geo_score or self.geo_score(),
                    "Q": cached_features.qualification_score,  # Sempre do cache se disponível
                    "U": cached_features.urgency_score or self.urgency_capacity(),
                    "R": cached_features.review_score or self.review_score(),
                    "C": cached_features.soft_skill_score,
                    "E": cached_features.firm_reputation_score,
                    "P": cached_features.price_fit_score or self.price_fit(),
                    "M": cached_features.maturity_score,
                    "I": cached_features.interaction_score,
                }
            
        except Exception as e:
            print(f"⚠️ Erro no cache unificado: {e} - usando cálculo direto")
        
        # Fallback para cálculo direto
        return await self.all_async()

    async def _get_or_calculate_cached_features(self) -> Optional[CachedFeatures]:
        """
        🆕 FASE 1: Obtém features do cache ou calcula e armazena.
        
        Implementa o padrão get-or-calculate para máxima eficiência.
        """
        if not UNIFIED_CACHE_AVAILABLE or not unified_cache:
            return None
        
        try:
            # Inicializar cache se necessário
            if not unified_cache.is_connected:
                await unified_cache.initialize()
            
            # Gerar chave de cache baseada no contexto do caso
            cache_key = self._generate_cache_key()
            
            # Tentar obter do cache
            cached = await unified_cache.get_cached_features(cache_key)
            if cached and self._is_cache_valid(cached):
                return cached
            
            # Cache miss ou stale - calcular features pesadas
            features = await self._calculate_heavy_features()
            
            # Armazenar no cache com TTL otimizado
            cached_features = CachedFeatures(
                lawyer_id=self.lawyer.id,
                cached_at=datetime.now(),
                qualification_score=features["Q"],
                maturity_score=features["M"],
                interaction_score=features["I"],
                soft_skill_score=features["C"],
                firm_reputation_score=features["E"],
                # Scores adicionais para cache completo
                area_match_score=features.get("A"),
                similarity_score=features.get("S"),
                success_rate_score=features.get("T"),
                geo_score=features.get("G"),
                urgency_score=features.get("U"),
                review_score=features.get("R"),
                price_fit_score=features.get("P"),
                source="algorithm_match_v2.10",
                ttl_seconds=86400  # 24h TTL otimizado
            )
            
            await unified_cache.set_cached_features(cache_key, cached_features)
            return cached_features
            
        except Exception as e:
            print(f"❌ Erro no cache unificado: {e}")
            return None
    
    def _generate_cache_key(self) -> str:
        """Gera chave de cache baseada no contexto lawyer+case."""
        # Combinar ID do advogado com contexto do caso para cache contextual
        case_context = f"{self.case.area}:{self.case.complexity}:{self.case.type}"
        return f"{self.lawyer.id}:{case_context}"
    
    def _is_cache_valid(self, cached: CachedFeatures) -> bool:
        """Verifica se o cache ainda é válido (TTL + validações de negócio)."""
        from datetime import datetime
        
        # TTL básico (24h)
        if (datetime.now() - cached.cached_at).total_seconds() > cached.ttl_seconds:
            return False
        
        # Validações de negócio específicas
        # Features Q, M, I mudam pouco (perfil do advogado), safe para 24h
        # Features como G, U, P dependem mais do caso, mas 24h ainda é aceitável
        return True
    
    async def _calculate_heavy_features(self) -> Dict[str, float]:
        """Calcula apenas as features pesadas que valem a pena cachear."""
        return {
            "Q": await self.qualification_score_async(),  # Academic enrichment
            "M": self.maturity_score(),  # Maturity calculation
            "I": self.interaction_score(),  # IEP calculation  
            "C": self.soft_skill(),  # NLP sentiment analysis
            "E": self.firm_reputation(),  # Firm analysis
            # Features leves para cache completo
            "A": self.area_match(),
            "S": self.case_similarity(),
            "T": self.success_rate(),
            "G": self.geo_score(),
            "U": self.urgency_capacity(),
            "R": self.review_score(),
            "P": self.price_fit(),
        }

# =============================================================================
# 7. Core algorithm expandido
# =============================================================================


class MatchmakingAlgorithm:
    """Gera ranking justo de advogados para um caso com features v2.2."""
    
    def __init__(self, cache=None, db_session=None):
        """Inicializa algoritmo com templates acadêmicos e ML service."""
        self.cache = cache
        self.db_session = db_session
        
        # 🆕 FASE 2: Inicializar ML Service para AutoML avançado
        self.ml_service = None
        if CASE_MATCH_ML_AVAILABLE and db_session:
            try:
                # Usar factory async em sync context (será inicializado depois)
                self._ml_service_initialized = False
                self.logger = logging.getLogger(__name__)
            except Exception as e:
                print(f"⚠️ Erro ao preparar ML service: {e}")
        
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

    async def _ensure_ml_service_initialized(self):
        """🆕 FASE 2: Inicializa ML service de forma lazy e assíncrona."""
        if not CASE_MATCH_ML_AVAILABLE or not self.db_session:
            return
            
        if not self._ml_service_initialized:
            try:
                self.ml_service = await create_case_match_ml_service(self.db_session)
                self._ml_service_initialized = True
                if self.ml_service:
                    print("✅ CaseMatchMLService inicializado - AutoML ativo")
                else:
                    print("⚠️ CaseMatchMLService falhou - usando pesos estáticos")
            except Exception as e:
                print(f"❌ Erro ao inicializar ML service: {e}")
                self._ml_service_initialized = True  # Evitar retry infinito

    def _get_ml_optimized_weights(self, preset: str) -> Dict[str, float]:
        """🆕 FASE 2: Obtém pesos otimizados do ML service ou fallback."""
        if self.ml_service and self._ml_service_initialized:
            try:
                return self.ml_service.get_optimized_weights(preset)
            except Exception as e:
                print(f"⚠️ Erro ao obter pesos ML: {e} - usando fallback")
        
        # Fallback para pesos estáticos originais
        return load_preset(preset)

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
            
            # 🆕 FASE 4: Aplicar MultiDimensionalScoring
            enhanced_score = await self._calculate_multidimensional_score(
                lw, case, score_ltr, features, preset
            )
            
            # Atribuir scores e deltas
            lw.scores["ltr"] = enhanced_score  # Score final multi-dimensional
            lw.scores["base_ltr"] = score_ltr  # Score LTR original
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

    # 🆕 FASE 4: MultiDimensionalScoring
    async def _calculate_multidimensional_score(
        self, 
        lawyer: Lawyer, 
        case: Case, 
        base_ltr_score: float, 
        features: Dict[str, float], 
        preset: str
    ) -> float:
        """
        🆕 FASE 4: Calcula score multi-dimensional combinando LTR base com contexto.
        
        Composição do score final:
        - 60% Score base do LTR
        - 20% Score de contexto (urgência, complexidade, etc.) 
        - 15% Score de performance histórica
        - 5% Score de disponibilidade real-time
        
        Args:
            lawyer: Advogado candidato
            case: Caso para matching
            base_ltr_score: Score LTR original
            features: Features calculadas (A, S, T, etc.)
            preset: Preset usado
            
        Returns:
            Score multi-dimensional final
        """
        try:
            # 1. Score de contexto (20%)
            context_score = await self._calculate_context_relevance(lawyer, case, features, preset)
            
            # 2. Score de performance histórica (15%)
            historical_score = await self._calculate_historical_performance(lawyer, case)
            
            # 3. Score de disponibilidade real-time (5%)
            availability_score = await self._get_real_time_availability_score(lawyer)
            
            # 4. Combinar scores com pesos otimizados
            final_score = (
                base_ltr_score * 0.60 +          # Base LTR score
                context_score * 0.20 +          # Contexto do caso
                historical_score * 0.15 +       # Performance histórica
                availability_score * 0.05       # Disponibilidade real-time
            )
            
            # 5. Aplicar multiplicadores contextuais se ML service disponível
            if self.ml_service:
                multipliers = self._get_contextual_multipliers(case, preset)
                final_score = self._apply_contextual_multipliers(final_score, case, multipliers)
            
            # 6. Garantir score no range [0, 1]
            final_score = max(0.0, min(1.0, final_score))
            
            # 7. Armazenar breakdown para auditoria
            lawyer.scores["multidimensional_breakdown"] = {
                "base_ltr": base_ltr_score,
                "context": context_score,
                "historical": historical_score,
                "availability": availability_score,
                "final": final_score,
                "boost_applied": final_score > base_ltr_score
            }
            
            return final_score
            
        except Exception as e:
            print(f"❌ Erro no cálculo multi-dimensional: {e}")
            # Fallback para score LTR base
            return base_ltr_score

    async def _calculate_context_relevance(
        self, 
        lawyer: Lawyer, 
        case: Case, 
        features: Dict[str, float], 
        preset: str
    ) -> float:
        """Calcula relevância contextual baseada nas características do caso."""
        try:
            context_factors = []
            
            # 1. Urgência vs capacidade de resposta
            if case.urgency_h <= 24:  # Caso urgente
                urgency_factor = features.get("U", 0.0)  # Feature U (urgency_capacity)
                if urgency_factor > 0.8:
                    context_factors.append(0.3)  # Boost para advogados rápidos
                elif urgency_factor < 0.3:
                    context_factors.append(-0.2)  # Penalidade para lentos
                else:
                    context_factors.append(0.1)
            
            # 2. Complexidade vs qualificação
            if case.complexity == "HIGH":
                qual_factor = features.get("Q", 0.0)  # Feature Q (qualification)
                if qual_factor > 0.7:
                    context_factors.append(0.25)  # Boost para altamente qualificados
                else:
                    context_factors.append(-0.1)   # Penalidade para baixa qualificação
            elif case.complexity == "LOW":
                # Para casos simples, priorizar custo-benefício
                price_factor = features.get("P", 0.0)  # Feature P (price_fit)
                context_factors.append(price_factor * 0.2)
            
            # 3. Tipo de caso vs expertise
            if case.type == "CORPORATE":
                firm_factor = features.get("E", 0.0)  # Feature E (firm_reputation)
                maturity_factor = features.get("M", 0.0)  # Feature M (maturity)
                context_factors.append((firm_factor + maturity_factor) * 0.15)
            elif case.type == "INDIVIDUAL":
                soft_skill_factor = features.get("C", 0.0)  # Feature C (soft_skills)
                review_factor = features.get("R", 0.0)  # Feature R (reviews)
                context_factors.append((soft_skill_factor + review_factor) * 0.1)
            
            # 4. Preset específico
            if preset == "fast":
                # Para preset fast, priorizar velocidade
                speed_factors = [features.get("U", 0.0), features.get("G", 0.0)]
                context_factors.append(max(speed_factors) * 0.2)
            elif preset == "expert":
                # Para preset expert, priorizar qualificação  
                expert_factors = [features.get("Q", 0.0), features.get("S", 0.0)]
                context_factors.append(max(expert_factors) * 0.25)
            elif preset == "economic":
                # Para preset economic, priorizar preço
                price_factor = features.get("P", 0.0)
                context_factors.append(price_factor * 0.3)
            
            # Calcular score médio dos fatores contextuais
            if context_factors:
                context_score = sum(context_factors) / len(context_factors)
                return max(0.0, min(1.0, 0.5 + context_score))  # Base 0.5 + ajustes
            
            return 0.5  # Score neutro se não há fatores contextuais
            
        except Exception as e:
            print(f"❌ Erro no cálculo de contexto: {e}")
            return 0.5

    async def _calculate_historical_performance(self, lawyer: Lawyer, case: Case) -> float:
        """Calcula performance histórica específica para o contexto do caso."""
        try:
            # 1. Performance na área específica
            area_performance = lawyer.kpi_subarea.get(f"{case.area}/{case.subarea}", None)
            if area_performance is not None:
                base_score = area_performance
            else:
                base_score = lawyer.kpi.success_rate
            
            # 2. Ajustar por volume de casos (confiabilidade)
            cases_volume = lawyer.kpi.cases_30d
            confidence_factor = min(1.0, cases_volume / 20.0)  # Confiança máxima com 20+ casos
            
            # 3. Ajustar por status de sucesso (V/P/N)
            status_multiplier = {"V": 1.0, "P": 0.8, "N": 0.5}.get(
                lawyer.kpi.success_status, 0.7
            )
            
            # 4. Score histórico final
            historical_score = base_score * confidence_factor * status_multiplier
            
            return max(0.0, min(1.0, historical_score))
            
        except Exception as e:
            print(f"❌ Erro no cálculo histórico: {e}")
            return 0.5

    async def _get_real_time_availability_score(self, lawyer: Lawyer) -> float:
        """Calcula score de disponibilidade real-time."""
        try:
            # 1. Carga atual vs capacidade máxima
            current_load = lawyer.kpi.active_cases
            max_capacity = lawyer.max_concurrent_cases
            
            if max_capacity > 0:
                load_ratio = current_load / max_capacity
                
                if load_ratio < 0.5:
                    availability_score = 1.0  # Baixa carga = alta disponibilidade
                elif load_ratio < 0.8:
                    availability_score = 0.7  # Carga média
                elif load_ratio < 1.0:
                    availability_score = 0.4  # Alta carga
                else:
                    availability_score = 0.1  # Sobrecarga
                    
                return availability_score
            
            return 0.5  # Score neutro se não há dados
            
        except Exception as e:
            print(f"❌ Erro no cálculo de disponibilidade: {e}")
            return 0.5

    def _get_contextual_multipliers(self, case: Case, preset: str) -> Dict[str, float]:
        """Obtém multiplicadores contextuais do ML service."""
        if not self.ml_service:
            return {"urgency": 1.0, "complexity": 1.0, "premium": 1.0}
        
        try:
            weights_dict = self.ml_service.get_optimized_weights(preset)
            return {
                "urgency": weights_dict.get("urgency_multiplier", 1.0),
                "complexity": weights_dict.get("complexity_multiplier", 1.0),
                "premium": weights_dict.get("premium_multiplier", 1.0)
            }
        except Exception:
            return {"urgency": 1.0, "complexity": 1.0, "premium": 1.0}

    def _apply_contextual_multipliers(
        self, 
        base_score: float, 
        case: Case, 
        multipliers: Dict[str, float]
    ) -> float:
        """Aplica multiplicadores contextuais ao score base."""
        enhanced_score = base_score
        
        # Multiplicador de urgência
        if case.urgency_h <= 24:
            enhanced_score *= multipliers["urgency"]
        
        # Multiplicador de complexidade
        if case.complexity == "HIGH":
            enhanced_score *= multipliers["complexity"]
        
        # Multiplicador premium
        if case.is_premium:
            enhanced_score *= multipliers["premium"]
        
        return enhanced_score

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
                   exclude_ids: Optional[Set[str]] = None, expand_search: bool = False) -> List['Recommendation']:
        """Classifica advogados para um caso e mescla com recomendações patrocinadas.
        
        Args:
            expand_search: Se True, habilita busca híbrida (interna + externa)
        """
        
        if not lawyers:
            return []

        # 🆕 FASE 2: Inicializar ML Service para AutoML
        await self._ensure_ml_service_initialized()

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
            "segmented_cache_enabled": is_segmented_cache_enabled(),
            "expand_search": expand_search,  # Log do novo parâmetro
            "ml_service_active": self.ml_service is not None  # 🆕 FASE 2: Log do ML service
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

        # 1. 🆕 FASE 2: Carregar pesos otimizados do ML service
        experimental_weights = load_experimental_weights(model_version) if model_version else None
        if experimental_weights:
            # Usar pesos experimentais se especificados
            base_weights = experimental_weights
            AUDIT_LOGGER.info("Using experimental weights", {
                "case_id": case.id,
                "model_version": model_version
            })
        else:
            # 🆕 FASE 2: Usar pesos otimizados do ML service
            base_weights = self._get_ml_optimized_weights(preset)
            AUDIT_LOGGER.info("Using ML optimized weights", {
                "case_id": case.id,
                "preset": preset,
                "ml_service_active": self.ml_service is not None,
                "weights_source": "ml_service" if self.ml_service else "static"
            })
        
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
            lw.scores["features"] = await calculator.all_async_cached()  # 🆕 FASE 1: Cache inteligente

        # 3.5. 🆕 BUSCA HÍBRIDA: Expandir resultados se necessário
        if expand_search and len(available_lawyers) < top_n:
            try:
                # Importar o serviço de busca externa
                from .services.external_profile_enrichment_service import ExternalProfileEnrichmentService
                
                external_service = ExternalProfileEnrichmentService()
                needed_profiles = top_n - len(available_lawyers)
                
                AUDIT_LOGGER.info("Iniciando busca externa", {
                    "case_id": case.id,
                    "internal_results": len(available_lawyers),
                    "needed_external": needed_profiles,
                    "case_area": case.area
                })
                
                # Buscar perfis externos
                external_profiles = await external_service.search_public_profiles(
                    case_area=case.area,
                    location=case.coords,
                    urgency_h=case.urgency_h,
                    limit=needed_profiles + 2  # Buscar alguns extras para filtragem
                )
                
                # Converter perfis externos para Lawyer objects
                external_lawyers = []
                for profile in external_profiles:
                    # Criar objeto Lawyer para perfil externo
                    external_lawyer = Lawyer(
                        id=f"ext_{hash(profile.name)}",  # ID único para perfil externo
                        nome=profile.name,
                        tags_expertise=[case.area] + profile.specializations,
                        geo_latlon=case.coords,  # Usar coordenadas do caso como aproximação
                        curriculo_json={
                            "anos_experiencia": 5,  # Valor neutro
                            "pos_graduacoes": [],
                            "num_publicacoes": 0,
                            "is_external": True  # Marcador para perfil externo
                        },
                        kpi=KPI(
                            success_rate=0.5,  # Valores neutros para perfis externos
                            cases_30d=10,
                            avaliacao_media=3.5,
                            tempo_resposta_h=48,
                            cv_score=0.5,
                            success_status="N"
                        ),
                        max_concurrent_cases=20,
                        diversity=None,
                        kpi_subarea={},
                        kpi_softskill=0.5,
                        case_outcomes=[],
                        review_texts=[],
                        last_offered_at=time.time(),
                        casos_historicos_embeddings=[],
                        scores={"is_external": True},  # Marcador importante
                        pareceres=[],
                        reconhecimentos=[],
                        firm_id=None,
                        firm=None,
                        avg_hourly_fee=0.0,
                        flat_fee=None,
                        success_fee_pct=None,
                        maturity_data=None
                    )
                    
                    # Calcular features para perfil externo (limitadas)
                    calculator = FeatureCalculator(case, external_lawyer)
                    external_lawyer.scores["features"] = {
                        "A": calculator.area_match(),  # Pode calcular
                        "S": 0.3,  # Score baixo sem histórico
                        "T": 0.5,  # Neutro
                        "G": calculator.geo_score(),  # Pode calcular
                        "Q": 0.4,  # Score inferido baixo
                        "U": 0.5,  # Neutro
                        "R": 0.3,  # Baixo sem reviews
                        "C": 0.5,  # Neutro
                        "E": 0.0,  # Sem firma
                        "P": 0.5,  # Neutro
                        "M": 0.4,  # Score inferido baixo
                        "I": 0.3,  # Baixo engajamento (novo na plataforma)
                    }
                    
                    # Score LTR reduzido para perfis externos
                    external_lawyer.scores["ltr"] = sum(
                        external_lawyer.scores["features"].get(k, 0) * weights.get(k, 0) 
                        for k in weights
                    ) * 0.7  # Penalização de 30% para perfis externos
                    
                    external_lawyer.scores["source"] = "external"
                    external_lawyer.scores["external_confidence"] = profile.confidence_score
                    
                    # Armazenar dados originais do perfil para uso posterior
                    external_lawyer.scores["external_profile"] = {
                        "email": profile.email,
                        "linkedin_url": profile.linkedin_url,
                        "firm_name": profile.firm_name,
                        "location": profile.location,
                        "experience_description": profile.experience_description
                    }
                    
                    external_lawyers.append(external_lawyer)
                
                # Adicionar advogados externos à lista
                available_lawyers.extend(external_lawyers)
                
                AUDIT_LOGGER.info("Busca externa concluída", {
                    "case_id": case.id,
                    "external_profiles_found": len(external_profiles),
                    "external_lawyers_added": len(external_lawyers),
                    "total_candidates": len(available_lawyers)
                })
                
            except Exception as e:
                AUDIT_LOGGER.error("Erro na busca externa", {
                    "case_id": case.id,
                    "error": str(e)
                })
                # Continuar sem busca externa em caso de erro

        # 4. Calcular scores LTR (apenas para advogados internos, externos já calculados)
        internal_lawyers = [lw for lw in available_lawyers if not lw.scores.get("is_external", False)]
        if internal_lawyers:
            await self._calculate_ltr_scores_parallel(internal_lawyers, weights, case, preset, degraded_mode)

        if not available_lawyers:
            return []

        # 5. Aplicar ε-cluster, equidade e diversidade
        max_score = max(lw.scores["ltr"] for lw in available_lawyers) if available_lawyers else 0
        elite = [lw for lw in available_lawyers if lw.scores["ltr"] >= max_score - max(MIN_EPSILON, 0.10 * max_score)]
        
        for lw in elite:
            # Pular cálculo de equity para perfis externos (não têm dados reais)
            if lw.scores.get("is_external", False):
                lw.scores["equity_raw"] = 0.5  # Neutro
                lw.scores["fair_base"] = lw.scores["ltr"]  # Sem ajuste de equity
            else:
                equity = self.equity_weight(lw.kpi, lw.max_concurrent_cases)
                lw.scores["equity_raw"] = equity
                lw.scores["fair_base"] = (1 - BETA_EQUITY) * lw.scores["ltr"] + BETA_EQUITY * equity
        
        current_ranking = sorted(elite, key=lambda l: l.scores["fair_base"], reverse=True)
        
        # Aplicar diversity apenas para advogados internos (externos não têm dados de diversidade)
        internal_ranking = [lw for lw in current_ranking if not lw.scores.get("is_external", False)]
        external_ranking = [lw for lw in current_ranking if lw.scores.get("is_external", False)]
        
        # 🆕 FASE 5: AdvancedDiversification por múltiplas dimensões
        if internal_ranking:
            diversified_internal = await self._apply_advanced_diversification(
                internal_ranking, case, top_n
            )
        else:
            diversified_internal = []
        
        # Aplicar diversity tradicional apenas se advanced falhar
        if not diversified_internal and internal_ranking:
            for dimension in ["gender", "ethnicity", "pcd", "orientation"]:
                boosts = self._calculate_dimension_boost(internal_ranking, dimension)
                for lw in internal_ranking:
                    lw.scores["fair_base"] += boosts.get(lw.id, 0.0)
            diversified_internal = internal_ranking
        
        # Recombinar e reordenar
        final_ranking = diversified_internal + external_ranking
        final_ranking.sort(key=lambda l: l.scores["fair_base"], reverse=True)

        # 6. Log e ordenação final
        for lw in final_ranking[:top_n]:
            log_data = {
                "case_id": case.id, 
                "lawyer_id": lw.id, 
                "scores": safe_json_dump(lw.scores), 
                "model_version": model_version or "production", 
                "preset": preset,
                "is_external": lw.scores.get("is_external", False)
            }
            AUDIT_LOGGER.info(f"Lawyer {lw.id} ranked for case {case.id}", log_data)
        
        final_ranking.sort(key=lambda l: (-l.scores["fair_base"], l.last_offered_at))
        
        now = time.time()
        for lw in final_ranking[:top_n]:
            if not lw.scores.get("is_external", False):  # Só atualizar para advogados internos
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

    # 🆕 FASE 3: Case Feedback Collection para AutoML
    async def record_case_outcome(
        self, 
        case_id: str, 
        lawyer_id: str, 
        client_id: str,
        hired: bool, 
        client_satisfaction: float = 3.0,
        case_success: bool = False,
        case_outcome_value: Optional[float] = None,
        response_time_hours: Optional[float] = None,
        case_duration_days: Optional[int] = None,
        lawyer_rank_position: int = 1,
        total_candidates: int = 5,
        match_score: float = 0.0,
        features_used: Optional[Dict[str, float]] = None,
        preset_used: str = "balanced",
        feedback_notes: Optional[str] = None
    ) -> bool:
        """
        🆕 FASE 3: Registra outcome de um caso para aprendizado do algoritmo.
        
        Este método deve ser chamado quando:
        1. Cliente contrata um advogado (hired=True)
        2. Cliente rejeita todos os candidatos (hired=False)
        3. Caso é finalizado com sucesso/insucesso
        4. Cliente avalia a experiência
        
        Args:
            case_id: ID do caso
            lawyer_id: ID do advogado (o que foi contratado ou melhor ranqueado)
            client_id: ID do cliente  
            hired: Se o cliente contratou este advogado
            client_satisfaction: Rating 0.0-5.0 da satisfação do cliente
            case_success: Se o caso foi bem-sucedido
            case_outcome_value: Valor recuperado/economizado (opcional)
            response_time_hours: Tempo real de resposta do advogado
            case_duration_days: Duração total do caso
            lawyer_rank_position: Posição do advogado no ranking original
            total_candidates: Total de candidatos apresentados
            match_score: Score que o algoritmo deu para este match
            features_used: Features calculadas no momento do match
            preset_used: Preset usado no matching
            feedback_notes: Notas adicionais do feedback
            
        Returns:
            True se feedback foi registrado com sucesso
        """
        if not self.ml_service:
            print("⚠️ ML service não disponível - feedback não será registrado")
            return False
        
        try:
            # Importar a classe CaseFeedback
            from .services.case_match_ml_service import CaseFeedback
            
            # Obter contexto do caso se não fornecido
            if features_used is None:
                features_used = {}
            
            # Criar objeto de feedback
            feedback = CaseFeedback(
                case_id=case_id,
                lawyer_id=lawyer_id,
                client_id=client_id,
                hired=hired,
                client_satisfaction=min(5.0, max(0.0, client_satisfaction)),
                case_success=case_success,
                case_outcome_value=case_outcome_value,
                response_time_hours=response_time_hours,
                case_duration_days=case_duration_days,
                lawyer_rank_position=max(1, lawyer_rank_position),
                total_candidates=max(1, total_candidates),
                match_score=min(1.0, max(0.0, match_score)),
                features_used=features_used,
                preset_used=preset_used,
                feedback_source="client",
                feedback_notes=feedback_notes,
                timestamp=datetime.utcnow()
            )
            
            # Registrar no ML service
            await self.ml_service.record_feedback(feedback)
            
            AUDIT_LOGGER.info("Case outcome recorded for ML learning", {
                "case_id": case_id,
                "lawyer_id": lawyer_id,
                "hired": hired,
                "client_satisfaction": client_satisfaction,
                "case_success": case_success,
                "preset_used": preset_used,
                "feedback_source": "algorithm_match"
            })
            
            return True
            
        except Exception as e:
            AUDIT_LOGGER.error("Failed to record case outcome", {
                "case_id": case_id,
                "lawyer_id": lawyer_id,
                "error": str(e)
            })
            return False

    async def record_multiple_outcomes(
        self,
        case_id: str,
        client_id: str,
        outcomes: List[Dict[str, Any]],
        case_context: Optional[Dict[str, Any]] = None
    ) -> int:
        """
        🆕 FASE 3: Registra múltiplos outcomes de um caso (para todos os candidatos apresentados).
        
        Útil quando o cliente avalia múltiplos advogados ou quando o sistema
        quer registrar o outcome de todos os candidatos apresentados.
        
        Args:
            case_id: ID do caso
            client_id: ID do cliente
            outcomes: Lista de outcomes, cada um com formato:
                {
                    "lawyer_id": str,
                    "hired": bool,
                    "client_rating": float,  # opcional
                    "rank_position": int,
                    "match_score": float,
                    "features": Dict[str, float]  # opcional
                }
            case_context: Contexto adicional do caso (opcional)
                {
                    "case_success": bool,
                    "case_value": float,
                    "duration_days": int,
                    "preset_used": str
                }
        
        Returns:
            Número de outcomes registrados com sucesso
        """
        if not outcomes:
            return 0
        
        success_count = 0
        context = case_context or {}
        
        for outcome in outcomes:
            try:
                success = await self.record_case_outcome(
                    case_id=case_id,
                    lawyer_id=outcome["lawyer_id"],
                    client_id=client_id,
                    hired=outcome.get("hired", False),
                    client_satisfaction=outcome.get("client_rating", 3.0),
                    case_success=context.get("case_success", False),
                    case_outcome_value=context.get("case_value"),
                    case_duration_days=context.get("duration_days"),
                    lawyer_rank_position=outcome.get("rank_position", 1),
                    total_candidates=len(outcomes),
                    match_score=outcome.get("match_score", 0.0),
                    features_used=outcome.get("features", {}),
                    preset_used=context.get("preset_used", "balanced"),
                    feedback_notes=f"Batch feedback for case {case_id}"
                )
                
                if success:
                    success_count += 1
                    
            except Exception as e:
                AUDIT_LOGGER.warning("Failed to record individual outcome", {
                    "case_id": case_id,
                    "lawyer_id": outcome.get("lawyer_id"),
                    "error": str(e)
                })
                continue
        
        AUDIT_LOGGER.info("Batch outcome recording completed", {
            "case_id": case_id,
            "total_outcomes": len(outcomes),
            "successful_recordings": success_count
        })
        
        return success_count

    async def trigger_manual_optimization(self) -> bool:
        """
        🆕 FASE 3: Força otimização manual dos pesos (para admins/devs).
        
        Returns:
            True se otimização foi iniciada com sucesso
        """
        if not self.ml_service:
            print("⚠️ ML service não disponível")
            return False
        
        try:
            await self.ml_service._trigger_optimization()
            AUDIT_LOGGER.info("Manual optimization triggered", {
                "triggered_by": "algorithm_match",
                "timestamp": datetime.utcnow().isoformat()
            })
            return True
        except Exception as e:
            AUDIT_LOGGER.error("Manual optimization failed", {"error": str(e)})
            return False

    async def get_ml_performance_report(self) -> Optional[Dict[str, Any]]:
        """
        🆕 FASE 3: Obtém relatório de performance do ML service.
        
        Returns:
            Dict com métricas de performance ou None se ML service não disponível
        """
        if not self.ml_service:
            return None
        
        try:
            return await self.ml_service.get_performance_report()
        except Exception as e:
            AUDIT_LOGGER.error("Failed to get ML performance report", {"error": str(e)})
            return None

    async def _apply_advanced_diversification(
        self,
        lawyers: List[Lawyer],
        case: Case,
        top_n: int
    ) -> List[Lawyer]:
        """
        🆕 FASE 5: Aplica diversificação avançada por múltiplas dimensões.
        
        Diversifica por:
        1. Escritório/Firma (evitar concentração)
        2. Área de expertise (garantir variedade)  
        3. Faixa de preço (opções econômicas e premium)
        4. Experiência (júnior, pleno, sênior)
        5. Tipo de atuação (individual, corporativo, boutique)
        6. Localização (diferentes regiões)
        7. Demografia tradicional (gênero, etnia, etc.)
        
        Args:
            lawyers: Lista de advogados candidatos ordenados por score
            case: Caso para matching
            top_n: Número máximo de advogados a retornar
        
        Returns:
            Lista de advogados diversificados mantendo qualidade
        """
        if not lawyers:
            return []
        
        try:
            diversified = []
            
            # Contadores para cada dimensão de diversidade
            dimension_counts = {
                "firm": {},           # ID da firma
                "area": {},           # Área de expertise principal  
                "price_range": {},    # Faixa de preço (low/medium/high)
                "experience": {},     # Nível de experiência (junior/pleno/senior)
                "practice_type": {},  # Tipo de prática (individual/corporate/boutique)
                "location": {},       # Localização (cidade/região)
                "gender": {},         # Demografia: gênero
                "ethnicity": {},      # Demografia: etnia
                "pcd": {},           # Demografia: PcD
                "orientation": {}     # Demografia: orientação
            }
            
            # Limites máximos por dimensão (configurável por tipo de caso)
            max_limits = self._get_diversification_limits(case, top_n)
            
            # Processar advogados em ordem de score (manter qualidade)
            for lawyer in lawyers:
                if len(diversified) >= top_n:
                    break
                
                # Extrair características do advogado para cada dimensão
                characteristics = self._extract_lawyer_characteristics(lawyer)
                
                # Verificar se advogado pode ser adicionado sem violar limites
                if self._can_add_lawyer(characteristics, dimension_counts, max_limits):
                    diversified.append(lawyer)
                    
                    # Atualizar contadores
                    self._update_dimension_counts(characteristics, dimension_counts)
                    
                    # Aplicar boost de diversidade ao score
                    diversity_boost = self._calculate_diversity_boost(
                        characteristics, dimension_counts, max_limits
                    )
                    lawyer.scores["fair_base"] += diversity_boost
                    lawyer.scores["diversity_boost"] = diversity_boost
                
                # Se não conseguiu diversidade suficiente, relaxar critérios
                elif len(diversified) < top_n * 0.6:  # Se tem menos que 60% do target
                    # Adicionar mesmo violando algum limite (priorizar qualidade)
                    diversified.append(lawyer)
                    self._update_dimension_counts(characteristics, dimension_counts)
                    lawyer.scores["diversity_boost"] = 0.0  # Sem boost se violou limite
            
            # Se ainda não tem advogados suficientes, preencher com os melhores restantes
            if len(diversified) < top_n:
                remaining = [lw for lw in lawyers if lw not in diversified]
                needed = top_n - len(diversified)
                diversified.extend(remaining[:needed])
            
            # Log de auditoria da diversificação
            AUDIT_LOGGER.info("Advanced diversification applied", {
                "case_id": case.id,
                "original_count": len(lawyers),
                "diversified_count": len(diversified),
                "dimension_distribution": self._get_distribution_summary(diversified),
                "top_n": top_n
            })
            
            return diversified
            
        except Exception as e:
            AUDIT_LOGGER.error("Advanced diversification failed", {
                "case_id": case.id,
                "error": str(e)
            })
            # Fallback para lista original
            return lawyers[:top_n]

    def _get_diversification_limits(self, case: Case, top_n: int) -> Dict[str, int]:
        """Define limites máximos por dimensão baseado no contexto do caso."""
        
        # Limites base (ajustáveis por tipo de caso)
        if case.type == "CORPORATE":
            # Casos corporativos: permitir mais concentração em firmas grandes
            return {
                "firm": min(3, top_n // 2),           # Até 3 da mesma firma
                "area": top_n,                        # Sem limite de área (foco)
                "price_range": min(3, top_n // 2),    # Máximo 3 por faixa de preço
                "experience": top_n,                  # Sem limite de experiência
                "practice_type": top_n,               # Sem limite de tipo
                "location": top_n,                    # Sem limite de localização
                "gender": top_n,                      # Sem limite demográfico
                "ethnicity": top_n,                   # Sem limite demográfico
                "pcd": top_n,                        # Sem limite demográfico
                "orientation": top_n                  # Sem limite demográfico
            }
        else:
            # Casos individuais: máxima diversificação
            return {
                "firm": min(2, top_n // 3),           # Máximo 2 da mesma firma
                "area": min(3, top_n // 2),           # Máximo 3 da mesma área
                "price_range": min(2, top_n // 3),    # Máximo 2 por faixa de preço
                "experience": min(3, top_n // 2),     # Máximo 3 do mesmo nível
                "practice_type": min(3, top_n // 2),  # Máximo 3 do mesmo tipo
                "location": min(3, top_n // 2),       # Máximo 3 da mesma região
                "gender": min(4, int(top_n * 0.8)),   # Máximo 80% do mesmo gênero
                "ethnicity": min(4, int(top_n * 0.8)), # Máximo 80% da mesma etnia
                "pcd": top_n,                         # Sem limite PcD
                "orientation": top_n                  # Sem limite orientação
            }

    def _extract_lawyer_characteristics(self, lawyer: Lawyer) -> Dict[str, str]:
        """Extrai características do advogado para cada dimensão de diversidade."""
        
        characteristics = {}
        
        # 1. Firma
        characteristics["firm"] = lawyer.firm_id or "independent"
        
        # 2. Área de expertise (primeira tag como principal)
        characteristics["area"] = lawyer.tags_expertise[0] if lawyer.tags_expertise else "geral"
        
        # 3. Faixa de preço
        characteristics["price_range"] = self._get_price_range(lawyer.avg_hourly_fee)
        
        # 4. Nível de experiência
        exp_years = lawyer.curriculo_json.get("anos_experiencia", 5)
        if exp_years < 3:
            characteristics["experience"] = "junior"
        elif exp_years < 8:
            characteristics["experience"] = "pleno"  
        else:
            characteristics["experience"] = "senior"
        
        # 5. Tipo de prática
        if lawyer.firm and hasattr(lawyer.firm, 'is_boutique') and lawyer.firm.is_boutique:
            characteristics["practice_type"] = "boutique"
        elif lawyer.firm_id:
            characteristics["practice_type"] = "corporate"
        else:
            characteristics["practice_type"] = "individual"
        
        # 6. Localização (baseada em coordenadas - simplificado)
        lat, lon = lawyer.geo_latlon
        if lat == 0 and lon == 0:
            characteristics["location"] = "unknown"
        elif -24.0 <= lat <= -22.0 and -47.0 <= lon <= -46.0:
            characteristics["location"] = "sao_paulo"
        elif -23.0 <= lat <= -22.0 and -44.0 <= lon <= -43.0:
            characteristics["location"] = "rio_janeiro"
        else:
            characteristics["location"] = "other"
        
        # 7-10. Demografia tradicional
        if lawyer.diversity:
            characteristics["gender"] = lawyer.diversity.gender or "unknown"
            characteristics["ethnicity"] = lawyer.diversity.ethnicity or "unknown"
            characteristics["pcd"] = "yes" if lawyer.diversity.pcd else "no"
            characteristics["orientation"] = lawyer.diversity.orientation or "unknown"
        else:
            characteristics["gender"] = "unknown"
            characteristics["ethnicity"] = "unknown"
            characteristics["pcd"] = "unknown"
            characteristics["orientation"] = "unknown"
        
        return characteristics

    def _get_price_range(self, hourly_fee: float) -> str:
        """Categoriza advogado por faixa de preço."""
        if hourly_fee <= 0:
            return "unknown"
        elif hourly_fee < 200:
            return "low"        # Até R$ 200/h
        elif hourly_fee < 500:
            return "medium"     # R$ 200-500/h
        else:
            return "high"       # R$ 500+/h

    def _can_add_lawyer(
        self, 
        characteristics: Dict[str, str], 
        dimension_counts: Dict[str, Dict[str, int]], 
        max_limits: Dict[str, int]
    ) -> bool:
        """Verifica se advogado pode ser adicionado sem violar limites de diversidade."""
        
        for dimension, char_value in characteristics.items():
            current_count = dimension_counts[dimension].get(char_value, 0)
            max_limit = max_limits[dimension]
            
            if current_count >= max_limit:
                return False  # Violaria limite desta dimensão
        
        return True  # Pode adicionar sem violar nenhum limite

    def _update_dimension_counts(
        self, 
        characteristics: Dict[str, str], 
        dimension_counts: Dict[str, Dict[str, int]]
    ):
        """Atualiza contadores de diversidade ao adicionar um advogado."""
        
        for dimension, char_value in characteristics.items():
            if char_value not in dimension_counts[dimension]:
                dimension_counts[dimension][char_value] = 0
            dimension_counts[dimension][char_value] += 1

    def _calculate_diversity_boost(
        self, 
        characteristics: Dict[str, str], 
        dimension_counts: Dict[str, Dict[str, int]], 
        max_limits: Dict[str, int]
    ) -> float:
        """Calcula boost de diversidade baseado na raridade das características."""
        
        boost_factors = []
        
        for dimension, char_value in characteristics.items():
            current_count = dimension_counts[dimension].get(char_value, 0)
            max_limit = max_limits[dimension]
            
            if max_limit > 1:  # Só aplicar boost se há limite de diversidade
                # Boost inversamente proporcional à frequência atual
                rarity_factor = 1.0 - (current_count / max_limit)
                boost_factors.append(rarity_factor * 0.02)  # Boost máximo de 2% por dimensão
        
        # Boost total é a média dos boosts por dimensão
        total_boost = sum(boost_factors) / len(boost_factors) if boost_factors else 0.0
        
        return min(0.1, total_boost)  # Limitar boost total a 10%

    def _get_distribution_summary(self, lawyers: List[Lawyer]) -> Dict[str, Dict[str, int]]:
        """Gera resumo da distribuição final para logs de auditoria."""
        
        distribution = {
            "firm": {},
            "area": {},
            "price_range": {},
            "experience": {},
            "practice_type": {},
            "location": {},
            "gender": {},
            "ethnicity": {}
        }
        
        for lawyer in lawyers:
            characteristics = self._extract_lawyer_characteristics(lawyer)
            
            for dimension, char_value in characteristics.items():
                if dimension in distribution:
                    if char_value not in distribution[dimension]:
                        distribution[dimension][char_value] = 0
                    distribution[dimension][char_value] += 1
        
        return distribution

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
                "publicacoes": [
                    {"ano": 2023, "titulo": "Artigo sobre Direito do Trabalho", "journal": "Revista Trabalhista"},
                    {"ano": 2022, "titulo": "Tendências em Rescisão", "journal": "Revista dos Tribunais"}
                ],
                "projetos_pesquisa": [
                    {"nome": "Pesquisa sobre CLT", "area": "Trabalhista", "ano_inicio": 2022}
                ],
                "premios": [
                    {"nome": "Melhor Advogado Trabalhista 2023", "ano": 2023, "instituicao": "OAB-SP"}
                ],
                "idiomas": [
                    {"idioma": "inglês", "nivel": "fluente"},
                    {"idioma": "espanhol", "nivel": "intermediário"}
                ],
                "eventos": [
                    {"nome": "Congresso de Direito do Trabalho", "tipo": "congresso", "ano": 2023},
                    {"nome": "Workshop CLT Atualizada", "tipo": "workshop", "ano": 2023}
                ]
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
            print(
                f"           E={feats['E']:.2f} P={feats['P']:.2f} M={feats['M']:.2f} I={feats['I']:.2f} L={feats['L']:.2f}")
            print(f"  Delta: {delta}")
            print(f"  Preset: {scores['preset']} | Complexity: {scores['complexity']}")
            print(f"  Degraded Mode: {'SIM' if scores.get('degraded_mode', False) else 'NÃO'}")
            print(f"  Last offered: {datetime.fromtimestamp(adv.last_offered_at).isoformat()}")
            print()

        print(f"\n📊 Observações v2.11-full-escavador:")
        print("• 🎓 Academic Enrichment: Universidades e periódicos avaliados via APIs externas")
        print("• 🏆 100% Dados Escavador: Projetos, prêmios, idiomas e eventos totalmente integrados")
        print("• 🌐 Feature L (Languages & Events): Nova feature para idiomas e networking")
        print("• 📈 Feature Q Expandida: Inclui projetos de pesquisa e prêmios acadêmicos")
        print("• 🚀 Sponsored recommendations e lógica de casos premium integradas")
        print("• 🔒 Validação robusta: Sanitização e validação de inputs")
        print("• 🏢 Feature-E (Firm Reputation) e B2B Two-Pass mantidos")
        print("• 🛡️ Safe conflict scan e configurações via ENV")
        print("• 📊 Logs estruturados com métricas acadêmicas completas")

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

# =============================================================================
# 5.5. Academic Enrichment Service
# =============================================================================


class AcademicEnricher:
    """
    Serviço de enriquecimento acadêmico que avalia universidades e periódicos
    usando APIs externas (Perplexity + Deep Research) com cache inteligente.
    """
    
    def __init__(self, cache: RedisCache):
        self.cache = cache
        self.validator = AcademicPromptValidator()
        self.templates = AcademicPromptTemplates()
        
    async def score_universities(self, uni_names: List[str]) -> Dict[str, float]:
        """
        Avalia universidades usando APIs externas com cache Redis.
        
        Args:
            uni_names: Lista de nomes de universidades
            
        Returns:
            Dicionário {nome_universidade: score_0_1}
        """
        if not uni_names:
            return {}
            
        try:
            # Validar input
            self.validator.validate_batch_size(uni_names, 15)
            
            # Processar em lotes para eficiência
            results = {}
            for chunk in self._chunks(uni_names, 5):  # Lotes de 5
                chunk_results = await self._score_universities_batch(chunk)
                results.update(chunk_results)
                
            return results
            
        except Exception as e:
            AUDIT_LOGGER.error("Erro no scoring de universidades", {
                "error": str(e),
                "universities": uni_names
            })
            # Fallback: scores neutros
            return {name: 0.5 for name in uni_names}
    
    async def score_journals(self, journ_names: List[str]) -> Dict[str, float]:
        """
        Avalia periódicos/journals usando APIs externas com cache Redis.
        
        Args:
            journ_names: Lista de nomes de periódicos
            
        Returns:
            Dicionário {nome_periodico: score_0_1}
        """
        if not journ_names:
            return {}
            
        try:
            # Validar input
            self.validator.validate_batch_size(journ_names, 10)
            
            # Processar em lotes
            results = {}
            for chunk in self._chunks(journ_names, 3):  # Lotes menores para journals
                chunk_results = await self._score_journals_batch(chunk)
                results.update(chunk_results)
                
            return results
            
        except Exception as e:
            AUDIT_LOGGER.error("Erro no scoring de periódicos", {
                "error": str(e),
                "journals": journ_names
            })
            # Fallback: scores neutros
            return {name: 0.5 for name in journ_names}
    
    async def _score_universities_batch(self, universities: List[str]) -> Dict[str, float]:
        """Processa um lote de universidades."""
        results = {}
        
        for uni_name in universities:
            # Chave de cache normalizada
            cache_key = canonical(uni_name)
            
            # Tentar obter do cache
            cached_score = await self.cache.get_academic_score(f"uni:{cache_key}")
            if cached_score is not None:
                results[uni_name] = cached_score
                continue
            
            # Cache miss - consultar APIs externas
            score = await self._query_university_reputation(uni_name)
            
            # Armazenar no cache com TTL configurável
            await self.cache.set_academic_score(
                f"uni:{cache_key}", 
                score, 
                ttl_h=UNI_RANK_TTL_H
            )
            
            results[uni_name] = score
            
            # Rate limiting entre requisições
            await asyncio.sleep(0.5)
        
        return results
    
    async def _score_journals_batch(self, journals: List[str]) -> Dict[str, float]:
        """Processa um lote de periódicos."""
        results = {}
        
        for journ_name in journals:
            # Chave de cache normalizada
            cache_key = canonical(journ_name)
            
            # Tentar obter do cache
            cached_score = await self.cache.get_academic_score(f"jour:{cache_key}")
            if cached_score is not None:
                results[journ_name] = cached_score
                continue
            
            # Cache miss - consultar APIs externas
            score = await self._query_journal_impact(journ_name)
            
            # Armazenar no cache
            await self.cache.set_academic_score(
                f"jour:{cache_key}", 
                score, 
                ttl_h=JOUR_RANK_TTL_H
            )
            
            results[journ_name] = score
            
            # Rate limiting
            await asyncio.sleep(0.3)
        
        return results
    
    async def _query_university_reputation(self, uni_name: str) -> float:
        """
        Consulta reputação de universidade usando Perplexity + Deep Research.
        
        Returns:
            Score normalizado entre 0 e 1
        """
        try:
            # Template para avaliação de universidade
            prompt = self.templates.get_university_evaluation_prompt(uni_name)
            
            # Tentar Perplexity primeiro (mais rápido)
            payload = {
                "model": "llama-3.1-sonar-small-128k-online",
                "messages": [{"role": "user", "content": prompt}],
                "max_tokens": 500,
                "temperature": 0.1
            }
            
            result = await perplexity_chat(payload)
            if result and "score" in result:
                return self._normalize_score(result["score"])
            
            # Fallback para Deep Research (mais lento mas preciso)
            deep_payload = {
                "model": "gpt-4o-deep",
                "messages": [{"role": "user", "content": prompt}],
                "max_completion_tokens": 300
            }
            
            deep_result = await deep_research_request(deep_payload)
            if deep_result and "score" in deep_result:
                return self._normalize_score(deep_result["score"])
            
            # Fallback baseado em heurísticas simples
            return self._heuristic_university_score(uni_name)
            
        except Exception as e:
            AUDIT_LOGGER.warning("Erro na consulta de universidade", {
                "university": uni_name,
                "error": str(e)
            })
            return self._heuristic_university_score(uni_name)
    
    async def _query_journal_impact(self, journ_name: str) -> float:
        """
        Consulta fator de impacto de periódico usando APIs externas.
        
        Returns:
            Score normalizado entre 0 e 1
        """
        try:
            # Template para avaliação de periódico
            prompt = self.templates.get_journal_evaluation_prompt(journ_name)
            
            # Usar Perplexity para busca de impacto
            payload = {
                "model": "llama-3.1-sonar-small-128k-online",
                "messages": [{"role": "user", "content": prompt}],
                "max_tokens": 400,
                "temperature": 0.1
            }
            
            result = await perplexity_chat(payload)
            if result and "score" in result:
                return self._normalize_score(result["score"])
            
            # Fallback heurístico
            return self._heuristic_journal_score(journ_name)
            
        except Exception as e:
            AUDIT_LOGGER.warning("Erro na consulta de periódico", {
                "journal": journ_name,
                "error": str(e)
            })
            return self._heuristic_journal_score(journ_name)
    
    def _normalize_score(self, raw_score: Any) -> float:
        """Normaliza score retornado pelas APIs para range 0-1."""
        try:
            if isinstance(raw_score, (int, float)):
                # Se já for numérico, normalizar
                if 0 <= raw_score <= 1:
                    return float(raw_score)
                elif 0 <= raw_score <= 10:
                    return float(raw_score / 10)
                elif 0 <= raw_score <= 100:
                    return float(raw_score / 100)
                else:
                    return 0.5  # Valor fora do esperado
            elif isinstance(raw_score, str):
                # Tentar converter string para float
                return float(raw_score.strip()) if raw_score.strip() else 0.5
            else:
                return 0.5
        except (ValueError, TypeError):
            return 0.5
    
    def _heuristic_university_score(self, uni_name: str) -> float:
        """Fallback heurístico para universidades quando APIs falham."""
        name_lower = uni_name.lower()
        
        # Universidades top mundial
        if any(keyword in name_lower for keyword in [
            "harvard", "stanford", "mit", "yale", "princeton", 
            "cambridge", "oxford", "sorbonne"
        ]):
            return 1.0
        
        # Universidades brasileiras reconhecidas
        if any(keyword in name_lower for keyword in [
            "usp", "unicamp", "ufrj", "puc", "fgv", "insper", 
            "universidade de sao paulo", "pontifícia universidade"
        ]):
            return 0.8
        
        # Universidades federais/estaduais
        if any(keyword in name_lower for keyword in [
            "federal", "estadual", "ufmg", "ufrgs", "ufsc"
        ]):
            return 0.7
        
        # Outras universidades
        if "universidade" in name_lower or "faculdade" in name_lower:
            return 0.6
        
        # Default para instituições não reconhecidas
        return 0.4
    
    def _heuristic_journal_score(self, journ_name: str) -> float:
        """Fallback heurístico para periódicos quando APIs falham."""
        name_lower = journ_name.lower()
        
        # Periódicos internacionais top
        if any(keyword in name_lower for keyword in [
            "harvard law review", "yale law", "columbia law", 
            "stanford law", "nature", "science"
        ]):
            return 1.0
        
        # Periódicos brasileiros reconhecidos
        if any(keyword in name_lower for keyword in [
            "revista de direito administrativo", "revista dos tribunais",
            "revista de direito constitucional", "conjur"
        ]):
            return 0.8
        
        # Revistas acadêmicas gerais
        if any(keyword in name_lower for keyword in [
            "revista", "journal", "law review", "direito"
        ]):
            return 0.6
        
        # Default
        return 0.4
    
    def _chunks(self, lst: List[str], n: int):
        """Divide lista em chunks de tamanho n."""
        for i in range(0, len(lst), n):
            yield lst[i:i + n]


# Importar templates acadêmicos
try:
    from services.academic_prompt_templates import AcademicPromptTemplates, AcademicPromptValidator
except ImportError:
    # Fallback básico se templates não estiverem disponíveis
    class AcademicPromptTemplates:
        def get_university_evaluation_prompt(self, uni_name: str) -> str:
            return f"Evaluate the academic reputation of {uni_name} university on a scale from 0 to 1, considering global rankings, research output, and legal education quality. Return only a JSON with 'score' field."
        
        def get_journal_evaluation_prompt(self, journ_name: str) -> str:
            return f"Evaluate the impact factor and academic reputation of the journal '{journ_name}' on a scale from 0 to 1. Consider JCR impact factor, Qualis classification, and citation metrics. Return only a JSON with 'score' field."
    
    class AcademicPromptValidator:
        def validate_batch_size(self, items: List[str], max_size: int):
            if len(items) > max_size:
                raise ValueError(f"Batch size {len(items)} exceeds maximum {max_size}")
# =============================================================================
# BACKWARD COMPATIBILITY RE-EXPORTS
# Importa classes dos novos módulos para manter compatibilidade com código existente
# =============================================================================

# Re-export domain models
from .models.domain import (
    DiversityMeta,
    ProfessionalMaturityData, 
    Case,
    KPI,
    FirmKPI,
    Parecer,
    Reconhecimento,
    Lawyer,
    LawFirm,
    EMBEDDING_DIM as _EMBEDDING_DIM,
)

# Re-export utilities
from .utils import (
    haversine,
    cosine_similarity,
    canonical,
    _chunks,
    safe_json_dump,
)

# Re-export services
from .services import (
    RedisCache,
    create_redis_cache,
    AcademicEnricher,
    AcademicPromptTemplates,
    AcademicPromptValidator,
    create_academic_enricher,
)

# Re-export features
from .features import (
    ModernFeatureCalculator,
    create_feature_calculator,
    FeatureStrategy,
    CoreMatchingFeatures,
    GeographicFeatures,
    PerformanceFeatures,
)

# Re-export core facades
from .core import (
    MatchingOrchestrator,
    create_matching_orchestrator,
    RankingFacade,
    create_ranking_facade,
    FeedbackFacade,
    create_feedback_facade,
)

# Re-export DI system
from .di import (
    setup_di_container,
    get_container,
    get_service,
    get_matching_orchestrator,
    inject,
)

# Re-export modern matching
from .modern_matching import (
    ModernMatchmakingAlgorithm,
    create_modern_matching_algorithm,
)

# Re-export logging system
from .logging import (
    StructuredLogger,
    get_main_logger,
    get_audit_logger,
    log_info,
    log_warning,
    log_error,
    log_debug,
)

# Re-export observability system
from .observability import (
    MatchingMetrics,
    get_metrics,
    start_metrics_server,
    instrument_function,
)

# Re-export performance system
from .performance import (
    RateLimitConfig,
    get_rate_limiter_pool,
    rate_limited,
    rate_limit,
)

# Ensure EMBEDDING_DIM constant is available
EMBEDDING_DIM = _EMBEDDING_DIM

# Export all re-exported symbols for backward compatibility
__all__ = [
    "DiversityMeta",
    "ProfessionalMaturityData",
    "Case", 
    "KPI",
    "FirmKPI",
    "Parecer",
    "Reconhecimento",
    "Lawyer",
    "LawFirm",
    "EMBEDDING_DIM",
    "haversine",
    "cosine_similarity",
    "canonical", 
    "_chunks",
    "safe_json_dump",
    "MatchmakingAlgorithm",
    "FeatureCalculator",
    "RedisCache",
    "create_redis_cache",
    "AcademicEnricher",
    "AcademicPromptTemplates",
    "AcademicPromptValidator", 
    "create_academic_enricher",
    "ModernFeatureCalculator",
    "create_feature_calculator",
    "FeatureStrategy",
    "CoreMatchingFeatures",
    "GeographicFeatures",
    "PerformanceFeatures",
    "MatchingOrchestrator",
    "create_matching_orchestrator",
    "RankingFacade",
    "create_ranking_facade",
    "FeedbackFacade",
    "create_feedback_facade",
    "setup_di_container",
    "get_container",
    "get_service",
    "get_matching_orchestrator",
    "inject",
    "ModernMatchmakingAlgorithm",
    "create_modern_matching_algorithm",
    "StructuredLogger",
    "get_main_logger",
    "get_audit_logger",
    "log_info",
    "log_warning",
    "log_error",
    "log_debug",
    "MatchingMetrics",
    "get_metrics",
    "start_metrics_server",
    "instrument_function",
    "RateLimitConfig",
    "get_rate_limiter_pool",
    "rate_limited",
    "rate_limit",
]

# Nota: Testes unitários estão disponíveis em Algoritmo.tests
# Execute: python -m Algoritmo.tests.test_runner para todos os testes

