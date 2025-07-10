#!/usr/bin/env python3
"""Job ETL – gera dataset para LTR a partir dos logs de auditoria.
Extrai eventos 'recommend' (exposição) e 'feedback' (aceite/decline/won/lost)
 1. Lê logs/audit.log (JSON-lines)
 2. Junta features + label
 3. Salva em data/ltr_dataset.parquet

Programação sugerida: 03:30 UTC depois do Jusbrasil.
"""
import json
import logging
from pathlib import Path

import pandas as pd

AUDIT_FILE = Path("logs/audit.log")
OUTPUT_FILE = Path("data/ltr_dataset.parquet")

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger(__name__)


def build_dataset():
    if not AUDIT_FILE.exists():
        logger.error("Arquivo de log %s não encontrado", AUDIT_FILE)
        return

    recommends = {}
    labels = {}

    with AUDIT_FILE.open() as f:
        for line in f:
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            if event.get("message") == "recommend":
                key = (event["context"].get("case"), event["context"].get("lawyer"))
                recommends[key] = event["context"].get("fair")
            elif event.get("message") == "feedback":
                key = (event["context"].get("case"), event["context"].get("lawyer"))
                label = event["context"].get("label")
                labels[key] = 1 if label in {"accepted", "won"} else 0

    # Build dataframe
    rows = []
    for key, score in recommends.items():
        label = labels.get(key, 0)
        rows.append({
            "case_id": key[0],
            "lawyer_id": key[1],
            "relevance": label,
            # placeholder features – real pipeline deve adicionar f_A, f_S ...
            "f_A": score,
            "f_S": score,
            "f_T": score,
            "f_G": score,
            "f_Q": score,
            "f_U": score,
            "f_R": score,
        })

    df = pd.DataFrame(rows)
    OUTPUT_FILE.parent.mkdir(exist_ok=True)
    df.to_parquet(OUTPUT_FILE, index=False)
    logger.info("Dataset LTR salvo em %s (%d linhas)", OUTPUT_FILE, len(df))


if __name__ == "__main__":
    build_dataset()
