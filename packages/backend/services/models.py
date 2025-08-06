
import os
import logging
from sentence_transformers import SentenceTransformer
from typing import Optional

logger = logging.getLogger(__name__)

# Cache para os modelos carregados
_model_cache = {}

def get_embedding_model(model_name_or_path: str) -> Optional[SentenceTransformer]:
    """
    Carrega um modelo de embedding da biblioteca sentence-transformers,
    mantendo-o em cache para evitar recarregamentos.

    Args:
        model_name_or_path: O nome do modelo no Hugging Face Hub ou o
                            caminho para um diretório local.

    Returns:
        A instância do modelo SentenceTransformer ou None se ocorrer um erro.
    """
    if model_name_or_path in _model_cache:
        return _model_cache[model_name_or_path]

    try:
        logger.info(f"Carregando modelo de embedding: '{model_name_or_path}'...")
        # Verificar se o caminho existe localmente primeiro
        if os.path.isdir(model_name_or_path):
             logger.info(f"Modelo encontrado localmente em '{model_name_or_path}'.")
        model = SentenceTransformer(model_name_or_path)
        _model_cache[model_name_or_path] = model
        logger.info(f"Modelo '{model_name_or_path}' carregado com sucesso.")
        return model
    except Exception as e:
        logger.error(f"Falha ao carregar o modelo '{model_name_or_path}': {e}", exc_info=True)
        return None

# Funções de conveniência para modelos específicos

def get_biolegalbert_model() -> Optional[SentenceTransformer]:
    """Carrega o modelo pucpr/biolegalbert-pt."""
    return get_embedding_model('pucpr/biolegalbert-pt')

def get_litig_soup_model() -> Optional[SentenceTransformer]:
    """Carrega o modelo de fallback local 'litig-embedding-soup-v1'."""
    return get_embedding_model('models/litig-embedding-soup-v1')

def get_bertimbau_base_model() -> Optional[SentenceTransformer]:
    """Carrega o modelo BERTimbau Base (768D) para português brasileiro."""
    return get_embedding_model('neuralmind/bert-base-portuguese-cased')

def get_bertimbau_large_model() -> Optional[SentenceTransformer]:
    """Carrega o modelo BERTimbau Large (1024D) para português brasileiro."""
    return get_embedding_model('neuralmind/bert-large-portuguese-cased')