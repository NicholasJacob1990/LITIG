# backend/jobs/ltr_export.py
"""
Job para exportar dados de match para treinamento do modelo LTR.
Versão expandida v2.2 com novas features e labels numéricas.

Features v2.2:
- Inclui feature C (soft-skills)
- Labels numéricas (0-3) para relevância
- Group ID para casos
- Dados granulares de KPI
"""
import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

import numpy as np
import pandas as pd

# --- Configuração ---
LOG_FILE = Path("logs/audit.log")
OUTPUT_FILE = Path("data/ltr_dataset.parquet")
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s')


def map_label_to_numeric(label_str: str) -> int:
    """
    Mapeia labels textuais para valores numéricos de relevância.
    v2.2: Escala 0-3 para melhor granularidade.
    """
    label_mapping = {
        'lost': 0,        # Perdeu o caso
        'declined': 1,    # Declinou a oferta
        'accepted': 2,    # Aceitou mas não ganhou
        'won': 3         # Ganhou o caso
    }
    return label_mapping.get(label_str.lower(), 0)


def extract_features_v2(log_entry: Dict) -> Dict:
    """
    Extrai features do log incluindo as novas features v2.2.
    """
    features = log_entry.get("features", {})

    # Features v2.1 existentes
    feature_dict = {
        'f_A': features.get('A', 0.0),  # Area match
        'f_S': features.get('S', 0.0),  # Case similarity
        'f_T': features.get('T', 0.0),  # Success rate
        'f_G': features.get('G', 0.0),  # Geographic score
        'f_Q': features.get('Q', 0.0),  # Qualification score
        'f_U': features.get('U', 0.0),  # Urgency capacity
        'f_R': features.get('R', 0.0),  # Review score
    }

    # Feature v2.2 nova
    feature_dict['f_C'] = features.get('C', 0.0)  # Soft-skills

    return feature_dict


def validate_features(features: Dict) -> bool:
    """
    Valida se as features estão dentro dos ranges esperados.
    """
    expected_features = ['f_A', 'f_S', 'f_T', 'f_G', 'f_Q', 'f_U', 'f_R', 'f_C']

    # Verificar se todas as features estão presentes
    for feature in expected_features:
        if feature not in features:
            return False

        # Verificar se estão no range [0,1]
        value = features[feature]
        if not (0.0 <= value <= 1.0):
            return False

    return True


def add_derived_features(record: Dict) -> Dict:
    """
    Adiciona features derivadas para melhorar o modelo.
    """
    # Feature de qualidade geral (média ponderada)
    quality_score = (
        record['f_Q'] * 0.4 +  # Qualificação
        record['f_T'] * 0.3 +  # Taxa de sucesso
        record['f_R'] * 0.2 +  # Reviews
        record['f_C'] * 0.1    # Soft-skills
    )
    record['f_quality'] = quality_score

    # Feature de disponibilidade (geográfica + urgência)
    availability_score = (record['f_G'] + record['f_U']) / 2
    record['f_availability'] = availability_score

    # Feature de match total (área + similaridade)
    match_score = (record['f_A'] + record['f_S']) / 2
    record['f_match'] = match_score

    return record


def create_ltr_dataset():
    """
    Lê os logs de auditoria, extrai dados de match e salva em um dataset Parquet.
    Versão expandida v2.2 com novas features e labels numéricas.
    """
    if not LOG_FILE.exists():
        logging.error(f"Arquivo de log não encontrado em '{LOG_FILE}'")
        return

    logging.info(f"Iniciando ETL v2.2 do arquivo de log: {LOG_FILE}")

    records = []
    processed_count = 0
    valid_count = 0

    with open(LOG_FILE, 'r') as f:
        for line_num, line in enumerate(f, 1):
            try:
                log_entry = json.loads(line)
                processed_count += 1

                # Processar apenas logs de 'match' ou 'recommend'
                event_type = log_entry.get("event")
                if event_type not in ["match", "recommend"]:
                    continue

                # Verificar se tem as chaves necessárias
                required_keys = ["features", "label", "case_id", "lawyer_id"]
                if not all(key in log_entry for key in required_keys):
                    continue

                # Extrair features v2.2
                features = extract_features_v2(log_entry)

                # Validar features
                if not validate_features(features):
                    logging.warning(
                        f"Features inválidas na linha {line_num}: {features}")
                    continue

                # Adicionar features derivadas
                features = add_derived_features(features)

                # Criar registro para o dataset
                record = {
                    'case_id': log_entry.get('case_id'),
                    'lawyer_id': log_entry.get('lawyer_id'),
                    'label_str': log_entry.get('label'),
                    'label_num': map_label_to_numeric(log_entry.get('label')),
                    'group_id': log_entry.get('case_id'),  # Para ranking por caso
                    'timestamp': log_entry.get('timestamp', ''),
                    **features  # Adicionar todas as features
                }

                records.append(record)
                valid_count += 1

            except json.JSONDecodeError:
                logging.warning(f"Linha {line_num} mal formatada: {line.strip()}")
                continue
            except Exception as e:
                logging.error(f"Erro processando linha {line_num}: {e}")
                continue

    if not records:
        logging.warning("Nenhum registro de match válido encontrado nos logs.")
        return

    # Criar DataFrame
    df = pd.DataFrame(records)

    # Estatísticas do dataset
    logging.info(
        f"Dataset criado com {
            len(df)} registros válidos de {processed_count} processados")
    logging.info(f"Distribuição de labels: {df['label_str'].value_counts().to_dict()}")
    logging.info(f"Distribuição numérica: {df['label_num'].value_counts().to_dict()}")
    logging.info(f"Casos únicos: {df['case_id'].nunique()}")
    logging.info(f"Advogados únicos: {df['lawyer_id'].nunique()}")

    # Adicionar metadados
    df['export_date'] = datetime.now().isoformat()
    df['version'] = 'v2.2'

    # Salvar em Parquet
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(OUTPUT_FILE, index=False)

    logging.info(f"Dataset salvo em '{OUTPUT_FILE}'")

    # Salvar também em CSV para debug
    csv_file = OUTPUT_FILE.with_suffix('.csv')
    df.to_csv(csv_file, index=False)
    logging.info(f"Dataset de debug salvo em '{csv_file}'")

    # Estatísticas finais das features
    feature_cols = [col for col in df.columns if col.startswith('f_')]
    feature_stats = df[feature_cols].describe()
    logging.info(f"Estatísticas das features:\n{feature_stats}")


def create_test_dataset():
    """
    Cria um dataset de teste com dados sintéticos para validação.
    """
    logging.info("Criando dataset de teste com dados sintéticos...")

    np.random.seed(42)  # Para reprodutibilidade

    # Gerar dados sintéticos
    n_cases = 100
    n_lawyers_per_case = 5

    records = []

    for case_id in range(n_cases):
        for lawyer_id in range(n_lawyers_per_case):
            # Features aleatórias mas correlacionadas
            area_match = np.random.choice([0.0, 1.0], p=[0.3, 0.7])
            similarity = np.random.beta(2, 5) if area_match else np.random.beta(1, 9)
            success_rate = np.random.beta(8, 2)
            geo_score = np.random.beta(3, 3)
            qual_score = np.random.beta(5, 3)
            urgency_cap = np.random.beta(4, 4)
            review_score = np.random.beta(7, 3)
            soft_skills = np.random.beta(6, 4)

            # Label baseado nas features (mais realista)
            total_score = (
                area_match * 0.3 + similarity * 0.25 + success_rate * 0.15 +
                geo_score * 0.1 + qual_score * 0.1 + urgency_cap * 0.05 +
                review_score * 0.05
            )

            if total_score > 0.8:
                label = 'won'
            elif total_score > 0.6:
                label = 'accepted'
            elif total_score > 0.3:
                label = 'declined'
            else:
                label = 'lost'

            record = {
                'case_id': f'case_{case_id}',
                'lawyer_id': f'lawyer_{lawyer_id}',
                'label_str': label,
                'label_num': map_label_to_numeric(label),
                'group_id': f'case_{case_id}',
                'f_A': area_match,
                'f_S': similarity,
                'f_T': success_rate,
                'f_G': geo_score,
                'f_Q': qual_score,
                'f_U': urgency_cap,
                'f_R': review_score,
                'f_C': soft_skills,
                'timestamp': datetime.now().isoformat(),
                'export_date': datetime.now().isoformat(),
                'version': 'v2.2_test'
            }

            # Adicionar features derivadas
            record = add_derived_features(record)
            records.append(record)

    # Salvar dataset de teste
    df_test = pd.DataFrame(records)
    test_file = OUTPUT_FILE.parent / "ltr_dataset_test.parquet"
    df_test.to_parquet(test_file, index=False)

    logging.info(f"Dataset de teste criado com {len(df_test)} registros")
    logging.info(f"Salvo em '{test_file}'")

    return test_file


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "--test":
        create_test_dataset()
    else:
        create_ltr_dataset()
