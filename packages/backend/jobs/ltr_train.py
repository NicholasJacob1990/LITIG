#!/usr/bin/env python3
# backend/jobs/ltr_train.py
"""
Job para treinamento do modelo LTR (Learning to Rank) v2.2.
Treina modelo com as novas features e salva pesos otimizados.

Features v2.2:
- Suporte para feature C (soft-skills)
- Modelo LambdaMART para ranking
- Validação cruzada com métricas de ranking
- Exportação de pesos para algoritmo
"""
import json
import logging
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import numpy as np
import pandas as pd

# Adiciona o diretório raiz ao path para importações
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

try:
    import joblib
    import lightgbm as lgb
    from sklearn.metrics import ndcg_score
    from sklearn.model_selection import GroupKFold
except ImportError as e:
    print(f"Dependência faltando: {e}")
    print("Instale com: pip install lightgbm scikit-learn joblib pandas numpy")
    sys.exit(1)

# --- Configuração ---
DATA_FILE = Path("data/ltr_dataset.parquet")
MODEL_FILE = Path("backend/models/ltr_model.txt")
WEIGHTS_FILE = Path("backend/models/ltr_weights.json")
LOG_FILE = Path("logs/ltr_training.log")

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Features v2.2 completas
FEATURE_COLUMNS = [
    'f_A',  # Area match
    'f_S',  # Case similarity
    'f_T',  # Success rate
    'f_G',  # Geographic score
    'f_Q',  # Qualification score
    'f_U',  # Urgency capacity
    'f_R',  # Review score
    'f_C',  # Soft-skills (nova v2.2)
    'f_quality',      # Feature derivada: qualidade geral
    'f_availability',  # Feature derivada: disponibilidade
    'f_match'         # Feature derivada: match total
]


def load_dataset() -> pd.DataFrame:
    """
    Carrega o dataset de treinamento.
    """
    if not DATA_FILE.exists():
        raise FileNotFoundError(
            f"Dataset não encontrado em '{DATA_FILE}'. Execute ltr_export.py primeiro.")

    df = pd.read_parquet(DATA_FILE)
    logger.info(f"Dataset carregado com {len(df)} registros")

    # Verificar se tem as colunas necessárias
    missing_cols = [col for col in FEATURE_COLUMNS if col not in df.columns]
    if missing_cols:
        raise ValueError(f"Colunas faltando no dataset: {missing_cols}")

    return df


def prepare_data(df: pd.DataFrame) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    """
    Prepara dados para treinamento LTR.
    """
    # Features
    X = df[FEATURE_COLUMNS].values

    # Labels (relevância numérica)
    y = df['label_num'].values

    # Grupos (casos) para ranking
    groups = df.groupby('group_id').size().values

    logger.info(
        f"Dados preparados: {X.shape[0]} amostras, {X.shape[1]} features, {len(groups)} grupos")
    logger.info(f"Distribuição de labels: {np.bincount(y)}")

    return X, y, groups


def train_model(X: np.ndarray, y: np.ndarray, groups: np.ndarray) -> lgb.LGBMRanker:
    """
    Treina modelo LambdaMART usando LightGBM.
    """
    logger.info("Iniciando treinamento do modelo LTR...")

    # Configuração do modelo
    model_params = {
        'objective': 'lambdarank',
        'metric': 'ndcg',
        'ndcg_eval_at': [1, 3, 5],
        'num_leaves': 31,
        'learning_rate': 0.05,
        'feature_fraction': 0.9,
        'bagging_fraction': 0.8,
        'bagging_freq': 5,
        'verbose': 0,
        'random_state': 42
    }

    # Criar modelo
    model = lgb.LGBMRanker(**model_params)

    # Validação cruzada com grupos
    cv_scores = []
    group_kfold = GroupKFold(n_splits=5)

    # Criar identificadores de grupo para CV
    group_ids = []
    current_group = 0
    for group_size in groups:
        group_ids.extend([current_group] * group_size)
        current_group += 1
    group_ids = np.array(group_ids)

    for fold, (train_idx, val_idx) in enumerate(group_kfold.split(X, y, group_ids)):
        logger.info(f"Fold {fold + 1}/5...")

        X_train, X_val = X[train_idx], X[val_idx]
        y_train, y_val = y[train_idx], y[val_idx]

        # Recalcular grupos para train/val
        train_groups = np.bincount(group_ids[train_idx])
        val_groups = np.bincount(group_ids[val_idx])

        # Remover grupos vazios
        train_groups = train_groups[train_groups > 0]
        val_groups = val_groups[val_groups > 0]

        # Treinar modelo
        model.fit(
            X_train, y_train, group=train_groups,
            eval_set=[(X_val, y_val)], eval_group=[val_groups],
            callbacks=[lgb.early_stopping(50), lgb.log_evaluation(0)]
        )

        # Avaliar
        y_pred = model.predict(X_val)

        # Calcular NDCG por grupo
        ndcg_scores = []
        start_idx = 0
        for group_size in val_groups:
            end_idx = start_idx + group_size
            if group_size > 1:  # Precisa de pelo menos 2 itens para NDCG
                y_true_group = y_val[start_idx:end_idx]
                y_pred_group = y_pred[start_idx:end_idx]
                ndcg = ndcg_score([y_true_group], [y_pred_group], k=5)
                ndcg_scores.append(ndcg)
            start_idx = end_idx

        if ndcg_scores:
            fold_ndcg = np.mean(ndcg_scores)
            cv_scores.append(fold_ndcg)
            logger.info(f"Fold {fold + 1} NDCG@5: {fold_ndcg:.4f}")

    # Treinar modelo final com todos os dados
    logger.info("Treinando modelo final...")
    model.fit(X, y, group=groups, callbacks=[lgb.log_evaluation(0)])

    # Métricas finais
    avg_ndcg = np.mean(cv_scores) if cv_scores else 0.0
    logger.info(f"NDCG@5 médio (CV): {avg_ndcg:.4f}")

    return model


def extract_feature_weights(model: lgb.LGBMRanker) -> Dict[str, float]:
    """
    Extrai pesos das features do modelo treinado.
    """
    # Importância das features
    feature_importance = model.feature_importances_

    # Normalizar importâncias para soma = 1
    total_importance = np.sum(feature_importance)
    if total_importance > 0:
        normalized_importance = feature_importance / total_importance
    else:
        normalized_importance = np.ones(
            len(feature_importance)) / len(feature_importance)

    # Mapear para features originais do algoritmo (A-R + C)
    feature_mapping = {
        'f_A': 'A',
        'f_S': 'S',
        'f_T': 'T',
        'f_G': 'G',
        'f_Q': 'Q',
        'f_U': 'U',
        'f_R': 'R',
        'f_C': 'C'  # Nova feature v2.2
    }

    weights = {}
    for i, feature in enumerate(FEATURE_COLUMNS):
        importance = normalized_importance[i]

        # Mapear apenas features originais (não derivadas)
        if feature in feature_mapping:
            weights[feature_mapping[feature]] = float(importance)

    # Renormalizar pesos das features originais
    total_weight = sum(weights.values())
    if total_weight > 0:
        weights = {k: v / total_weight for k, v in weights.items()}

    return weights


def save_model_and_weights(model: lgb.LGBMRanker, weights: Dict[str, float]):
    """
    Salva modelo e pesos nos arquivos de destino.
    """
    # Criar diretórios se não existirem
    MODEL_FILE.parent.mkdir(parents=True, exist_ok=True)
    WEIGHTS_FILE.parent.mkdir(parents=True, exist_ok=True)

    # Salvar modelo LightGBM
    model.booster_.save_model(str(MODEL_FILE))
    logger.info(f"Modelo salvo em '{MODEL_FILE}'")

    # Salvar pesos para algoritmo
    weights_data = {
        **weights,
        'version': 'v2.2',
        'trained_at': datetime.now().isoformat(),
        'features': list(weights.keys())
    }

    with open(WEIGHTS_FILE, 'w') as f:
        json.dump(weights_data, f, indent=2)

    logger.info(f"Pesos salvos em '{WEIGHTS_FILE}'")
    logger.info(f"Pesos finais: {weights}")


def evaluate_model(model: lgb.LGBMRanker, X: np.ndarray,
                   y: np.ndarray, groups: np.ndarray):
    """
    Avalia o modelo treinado.
    """
    logger.info("Avaliando modelo...")

    # Predições
    y_pred = model.predict(X)

    # Calcular métricas por grupo
    ndcg_scores = []
    precision_at_5 = []

    start_idx = 0
    for group_size in groups:
        end_idx = start_idx + group_size

        if group_size > 1:
            y_true_group = y[start_idx:end_idx]
            y_pred_group = y_pred[start_idx:end_idx]

            # NDCG@5
            ndcg = ndcg_score([y_true_group], [y_pred_group], k=5)
            ndcg_scores.append(ndcg)

            # Precision@5
            top_5_indices = np.argsort(y_pred_group)[-5:]
            top_5_true = y_true_group[top_5_indices]
            precision = np.sum(top_5_true >= 2) / min(5,
                                                      # Relevantes: label >= 2
                                                      len(top_5_true))
            precision_at_5.append(precision)

        start_idx = end_idx

    # Métricas finais
    avg_ndcg = np.mean(ndcg_scores) if ndcg_scores else 0.0
    avg_precision = np.mean(precision_at_5) if precision_at_5 else 0.0

    logger.info(f"NDCG@5 final: {avg_ndcg:.4f}")
    logger.info(f"Precision@5 final: {avg_precision:.4f}")

    return {
        'ndcg_at_5': avg_ndcg,
        'precision_at_5': avg_precision,
        'num_groups': len(groups)
    }


def main():
    """
    Função principal do treinamento.
    """
    start_time = datetime.now()
    logger.info("=== Iniciando treinamento LTR v2.2 ===")

    try:
        # Carregar dados
        df = load_dataset()

        # Preparar dados
        X, y, groups = prepare_data(df)

        # Treinar modelo
        model = train_model(X, y, groups)

        # Extrair pesos
        weights = extract_feature_weights(model)

        # Salvar modelo e pesos
        save_model_and_weights(model, weights)

        # Avaliar modelo
        metrics = evaluate_model(model, X, y, groups)

        # Log final
        duration = (datetime.now() - start_time).total_seconds()
        logger.info(f"=== Treinamento concluído em {duration:.2f}s ===")
        logger.info(f"Métricas finais: {metrics}")

    except Exception as e:
        logger.error(f"Erro durante treinamento: {e}")
        raise


if __name__ == "__main__":
    main()
