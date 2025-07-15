# -*- coding: utf-8 -*-
"""
ETL Module - Learning-to-Rank Pipeline
======================================

Módulo responsável pela extração e transformação dos dados brutos dos logs
de auditoria para o formato adequado ao treinamento do modelo LTR.

Funcionalidades:
- Extração de eventos de matching e feedback dos logs
- Transformação para formato Parquet
- Estruturação dos dados para o pipeline de treinamento
"""

import json
import pathlib
import uuid
import datetime as dt
import pandas as pd
import os

# Configurações de caminhos
RAW_LOG = pathlib.Path("logs/audit.log")                 # ajuste se necessário
OUT_DIR = pathlib.Path("packages/backend/ltr_pipeline/data/raw")
OUT_DIR.mkdir(parents=True, exist_ok=True)

def extract_raw_parquet():
    """
    Extrai eventos de matching e feedback dos logs de auditoria e salva em Parquet.
    
    Processa os logs JSON linha por linha, filtrando apenas eventos relevantes:
    - match_recommendation: Recomendações geradas pelo algoritmo
    - offer_feedback: Ações do usuário (click, contact, contract)
    
    O arquivo resultante é salvo como {YYYYMMDD}.parquet no diretório raw.
    """
    rows = []
    
    if not RAW_LOG.exists():
        print("⚠️  logs/audit.log não encontrado.")
        return
    
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
            
            # Construir tipo de evento detalhado
            event_type = ev["message"]
            if ev["message"] == "offer_feedback":
                action = ev.get("context", {}).get("action", "")
                event_type += f"/{action}" if action else ""
            
            row = {
                "event_id":   uuid.uuid4().hex,
                "ts_utc":     ev.get("timestamp", dt.datetime.utcnow().isoformat()),
                "case_id":    ev.get("context", {}).get("case_id", ""),
                "lawyer_id":  ev.get("context", {}).get("lawyer_id", ""),
                "event_type": event_type,
                "features":   ev.get("context", {}).get("features", {}),
            }
            rows.append(row)
    
    if not rows:
        print("⚠️  Nenhum evento elegível encontrado nos logs.")
        return
    
    # Criar DataFrame e salvar
    df = pd.DataFrame(rows)
    date = dt.datetime.utcnow().strftime("%Y%m%d")
    out = OUT_DIR / f"{date}.parquet"
    
    df.to_parquet(out, index=False)
    
    print(f"✓ Parquet bruto salvo em {out}")
    print(f"📊 Total de eventos processados: {len(rows)}")
    print(f"📈 Distribuição por tipo:")
    
    # Mostrar estatísticas dos eventos processados
    event_counts = df['event_type'].value_counts()
    for event_type, count in event_counts.items():
        print(f"   {event_type}: {count}")

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