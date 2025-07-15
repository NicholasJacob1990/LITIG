# -*- coding: utf-8 -*-
"""
ETL Module - Learning-to-Rank Pipeline
======================================

Módulo responsável pela extração e transformação dos dados brutos dos logs
de auditoria para o formato adequado ao treinamento do modelo LTR.

Funcionalidades:
- Extração de eventos de matching e feedback dos logs
- ⚡ CHAVE 1: Ingestão automática via Kafka Connect + fallback para arquivo
- Transformação para formato Parquet
- Estruturação dos dados para o pipeline de treinamento
"""

import json
import pathlib
import uuid
import datetime as dt
import pandas as pd
import os
from typing import List, Dict, Any, Optional

# ⚡ Kafka imports (opcionais - fallback para arquivo se não disponível)
try:
    from kafka import KafkaConsumer
    KAFKA_AVAILABLE = True
except ImportError:
    KAFKA_AVAILABLE = False
    print("⚠️  Kafka não disponível - usando fallback para arquivo local")

# Configurações de caminhos
RAW_LOG = pathlib.Path("logs/audit.log")                 # Fallback para arquivo local
OUT_DIR = pathlib.Path("packages/backend/ltr_pipeline/data/raw")
OUT_DIR.mkdir(parents=True, exist_ok=True)

# ⚡ CHAVE 1: Configuração Kafka
KAFKA_BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "match_events")
KAFKA_GROUP_ID = os.getenv("KAFKA_GROUP_ID", "ltr_etl_consumer")

def extract_from_kafka(date_str: str) -> List[Dict[str, Any]]:
    """
    ⚡ CHAVE 1: Extrai eventos do Kafka para data específica.
    
    Args:
        date_str: Data no formato YYYY-MM-DD
        
    Returns:
        Lista de eventos processados
    """
    if not KAFKA_AVAILABLE:
        return []
    
    try:
        consumer = KafkaConsumer(
            KAFKA_TOPIC,
            bootstrap_servers=[KAFKA_BOOTSTRAP_SERVERS],
            group_id=f"{KAFKA_GROUP_ID}_{date_str}",
            auto_offset_reset='earliest',
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            consumer_timeout_ms=30000  # 30s timeout
        )
        
        events = []
        target_date = dt.datetime.strptime(date_str, "%Y-%m-%d").date()
        
        print(f"📡 Coletando eventos Kafka para {date_str}...")
        
        for message in consumer:
            try:
                event = message.value
                event_date = dt.datetime.fromisoformat(
                    event.get("timestamp", dt.datetime.utcnow().isoformat())
                ).date()
                
                if event_date == target_date:
                    events.append(event)
                    
            except Exception as e:
                print(f"❌ Erro processando mensagem Kafka: {e}")
                continue
        
        consumer.close()
        print(f"✅ Coletados {len(events)} eventos do Kafka")
        return events
        
    except Exception as e:
        print(f"❌ Erro conectando ao Kafka: {e}")
        return []

def extract_from_file() -> List[Dict[str, Any]]:
    """
    Fallback: Extrai eventos do arquivo de log local.
    
    Returns:
        Lista de eventos processados
    """
    rows = []
    
    if not RAW_LOG.exists():
        print("⚠️  logs/audit.log não encontrado.")
        return []
    
    print(f"📂 Processando {RAW_LOG}...")
    
    with RAW_LOG.open() as fp:
        for line_num, line in enumerate(fp, 1):
            try:
                ev = json.loads(line)
            except Exception as e:
                print(f"⚠️  Linha {line_num} inválida: {e}")
                continue
            
            # Filtrar apenas eventos relevantes para LTR
            if ev.get("message") not in ("match_recommendation", "offer_feedback"):
                continue

            ctx = ev.get("context", {})
            
            # Estruturar dados para o dataset
            row = {
                "event_id": str(uuid.uuid4()),
                "ts_utc": dt.datetime.fromisoformat(ev.get("timestamp", dt.datetime.utcnow().isoformat())),
                "event_type": f"{ev['message']}/{ctx.get('action', 'unknown')}",
                "case_id": ctx.get("case_id") or ctx.get("case"),
                "lawyer_id": ctx.get("lawyer_id") or ctx.get("lawyer"),
                "user_id": ctx.get("user_id"),
                "features": ctx.get("features", {}),
                "metadata": {
                    "rank_position": ctx.get("rank_position"),
                    "score": ctx.get("fair") or ctx.get("score"),
                    "preset": ctx.get("preset"),
                    "algorithm_version": ctx.get("algorithm_version")
                }
            }
            
            # Adicionar apenas se tiver case_id e lawyer_id
            if row["case_id"] and row["lawyer_id"]:
                rows.append(row)

    print(f"📊 Processados {len(rows)} eventos válidos")
    return rows


def extract_raw_parquet(date_str: Optional[str] = None):
    """
    ⚡ CHAVE 1: Função principal de extração com suporte híbrido Kafka + arquivo.
    
    Args:
        date_str: Data específica (YYYY-MM-DD). Se None, usa data de ontem.
    """
    if date_str is None:
        yesterday = dt.datetime.utcnow() - dt.timedelta(days=1)
        date_str = yesterday.strftime("%Y-%m-%d")
    
    print(f"🚀 Iniciando extração para {date_str}")
    
    # ⚡ CHAVE 1: Tentar Kafka primeiro, fallback para arquivo
    events = extract_from_kafka(date_str)
    
    if not events and KAFKA_AVAILABLE:
        print("📡 Kafka não retornou eventos - tentando fallback")
    
    if not events:
        print("📂 Usando arquivo local como fonte")
        events = extract_from_file()
    
    if not events:
        print("⚠️  Nenhum evento encontrado")
        return
    
    # Converter para DataFrame e salvar
    df = pd.DataFrame(events)
    
    # Garantir coluna de data se não existir
    if 'ts_utc' in df.columns:
        df['date'] = pd.to_datetime(df['ts_utc']).dt.date
    else:
        df['date'] = dt.datetime.strptime(date_str, "%Y-%m-%d").date()
    
    # Agrupar por data e salvar arquivos separados
    for date, group_df in df.groupby('date'):
        date_str_file = date.strftime("%Y%m%d")
        output_path = OUT_DIR / f"{date_str_file}.parquet"
        
        # Remover coluna auxiliar
        group_df = group_df.drop('date', axis=1)
        
        group_df.to_parquet(output_path, index=False)
        print(f"💾 Salvos {len(group_df)} eventos em {output_path}")

def enrich_kpi_features():
    """
    Placeholder para enriquecimento de dados com KPIs adicionais.
    
    Esta função será expandida na Parte 2 para:
    - Carregar dados adicionais do advogado (KPIs, reviews, etc.)
    - Enriquecer o dataset com features contextuais
    - Preparar dados para o processo de treinamento
    """
    print("📝 Enriquecimento de KPIs - Placeholder para Parte 2")
    pass

if __name__ == "__main__":
    """Execução standalone para testes"""
    print("🚀 Iniciando ETL do LTR Pipeline...")
    extract_raw_parquet()
    enrich_kpi_features()
    print("✅ ETL concluído") 