# -*- coding: utf-8 -*-
"""
Configurações centralizadas para o pipeline de Learning-to-Rank (LTR)
=====================================================================

Este módulo contém todas as configurações necessárias para o pipeline LTR,
incluindo as features do algoritmo de matching, mapeamento de labels de
relevância e parâmetros do modelo LightGBM LambdaMART.
"""

# =============================================================================
# Features do Algoritmo de Matching
# =============================================================================

FEATURES = ["A", "S", "T", "G", "Q", "U", "R", "C", "E", "P", "M"]
"""
Lista ordenada das features utilizadas no algoritmo de matching:

A - Area Match: Compatibilidade entre área do caso e especialização do advogado
S - Case Similarity: Similaridade com casos históricos (embeddings)
T - Success Rate: Taxa de sucesso ponderada por valor econômico
G - Geographic Score: Proximidade geográfica normalizada
Q - Qualification Score: Qualificação e reputação (experiência, títulos, publicações)
U - Urgency Capacity: Capacidade de atender à urgência do caso
R - Review Score: Avaliações de clientes (com filtro anti-spam)
C - Soft Skills: Análise de sentimento dos reviews
E - Firm Reputation: Reputação do escritório (Feature-E v2.7)
P - Price Fit: Aderência de honorários ao orçamento (Feature-P v2.7)
M - Maturity Score: Maturidade profissional (Feature-M v2.8)
"""

# =============================================================================
# Mapeamento de Labels de Relevância
# =============================================================================

LABEL_MAP = {
    "match_recommendation":      0.0,  # Apenas recomendação gerada
    "offer_feedback/click":      0.3,  # Usuário visualizou perfil do advogado
    "offer_feedback/contact":    0.6,  # Usuário entrou em contato
    "offer_feedback/contract":   1.0,  # Contrato assinado (maior relevância)
}
"""
Mapeamento de eventos do usuário para scores de relevância numérica.

Os valores são baseados na progressão natural do funil de conversão:
- 0.0: Impressão (baseline)
- 0.3: Engajamento inicial (click no perfil)
- 0.6: Interesse real (contato direto)
- 1.0: Conversão completa (contrato assinado)

Estes scores são utilizados como labels no treinamento do LGBMRanker.
"""

# =============================================================================
# Parâmetros do LightGBM LambdaMART
# =============================================================================

LGB_PARAMS = {
    "objective":        "lambdarank",    # Objetivo específico para ranking
    "metric":           "ndcg",          # Métrica de avaliação (Normalized DCG)
    "ndcg_eval_at":     [5],            # Avaliar nDCG@5 (top 5 recomendações)
    "learning_rate":    0.05,           # Taxa de aprendizado conservadora
    "num_leaves":       48,             # Número de folhas por árvore
    "min_data_in_leaf": 20,             # Mínimo de amostras por folha (regularização)
    "feature_fraction": 0.9,            # Fração de features usadas por árvore
    "lambda_l1":        0.2,            # Regularização L1 (para poucos dados)
    "lambda_l2":        0.2,            # Regularização L2 (para poucos dados)
    "verbose":          -1,             # Silenciar logs do LightGBM
    "seed":             42,             # Semente para reprodutibilidade
}
"""
Parâmetros otimizados para o LightGBM LambdaMART.

Configuração conservadora adequada para datasets pequenos (~500 linhas):
- Regularização elevada (L1/L2) para evitar overfitting
- Learning rate baixo para convergência estável
- Feature fraction < 1.0 para diversidade nas árvores
- Min_data_in_leaf alto para robustez com poucos dados

Treinamento típico: < 30 segundos em CPU comum.
"""

# =============================================================================
# Configurações Adicionais
# =============================================================================

# Caminhos padrão dos artefatos
DEFAULT_MODEL_PATH = "packages/backend/models/ltr_model.txt"
DEFAULT_WEIGHTS_PATH = "packages/backend/models/ltr_weights.json"
DEFAULT_DATASET_PATH = "packages/backend/ltr_pipeline/data/processed/ltr_dataset.parquet"

# Thresholds de qualidade para gate de aprovação
QUALITY_THRESHOLDS = {
    "ndcg_at_5_min": 0.65,      # nDCG@5 mínimo
    "mrr_improvement": 0.03,     # Melhoria mínima no MRR vs baseline
    "fair_gap_max": 0.05,       # Máximo gap de fairness permitido
    "latency_p95_ms": 15,       # Latência p95 máxima em ms
}

# Configurações de versionamento
MODEL_VERSION_FORMAT = "%Y%m%d_%H%M%S"  # Formato timestamp para versionamento
MLFLOW_EXPERIMENT_NAME = "ltr_matching_algorithm" 