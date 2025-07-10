#!/usr/bin/env python
"""train_ltr_model.py – Proof‑of‑Concept para o Pipeline de LTR 🔖

Este script lê os **logs de recomendação** (JSON lines), gera um dataset
{query_id, doc_id, features[8], label} onde *label = 1* se o cliente aceitou
a indicação e 0 caso contrário, treina um modelo **Learning‑to‑Rank** com
LightGBM e produz dois artefatos:

* **ltr_model.txt**  – arquivo binário do LightGBM com os trees.
* **models/ltr_weights.json** – ganho de importância por feature (soma dos *gain* dos splits),
  pronto para ser consumido pelo algoritmo v2.x.

Requisitos:
    pip install pandas lightgbm tqdm

Uso:
    python scripts/train_ltr_model.py --logfile data/reco_logs.jsonl \
        --outdir backend/models/ --preset expert
"""

import argparse
import json
import os
from pathlib import Path
from typing import Dict, List

import lightgbm as lgb
import pandas as pd
from tqdm import tqdm

# ---------------------------------------------------------------------------
# 1. Argumentos CLI
# ---------------------------------------------------------------------------

def parse_args():
    ap = argparse.ArgumentParser(description="Treina modelo LTR a partir dos logs")
    ap.add_argument("--logfile", required=False, default="data/reco_logs.jsonl",
                    help="Caminho p/ JSONL de logs (recommend_v2.*)")
    ap.add_argument("--outdir", default="backend/models/", help="Pasta para salvar artefatos")
    ap.add_argument("--preset", default="balanced", choices=["fast", "expert", "balanced"],
                    help="Preset de pesos em caso de empate (meta‑info)")
    ap.add_argument("--quick", action="store_true",
                    help="Gera dataset sintético‑demo se logfile não existir")
    return ap.parse_args()

# ---------------------------------------------------------------------------
# 2. Carrega logs ou gera dados sintéticos
# ---------------------------------------------------------------------------

def load_logs(path: str, quick: bool) -> pd.DataFrame:
    """Converte logs JSONL em DataFrame [qid, docid, feat_*, label]."""
    if not os.path.exists(path):
        if not quick:
            raise FileNotFoundError(f"Logfile '{path}' não encontrado. Use --quick para demo.")
        # --- Demo synthetic ---
        import numpy as np
        n_cases, candidates = 200, 5
        rows = []
        for cid in range(n_cases):
            for lid in range(candidates):
                feats = np.random.rand(8)
                label = 1 if lid == np.random.randint(0, candidates) else 0
                rows.append([cid, f"adv_{lid}", *feats, label])
        cols = ["qid", "docid"] + list("ASTGQURC") + ["label"]
        return pd.DataFrame(rows, columns=cols)

    # Real log
    feats_cols = list("ASTGQURC")
    records: List[List] = []
    with open(path, "r", encoding="utf-8") as f:
        for line in tqdm(f, desc="Parsing logs"):
            try:
                j = json.loads(line)
                log_msg = j.get("msg", "")
                if not log_msg.startswith("recommend_v"):
                    continue
                
                extra = j.get("extra", {})
                qid = extra.get("case")
                doc = extra.get("lawyer")
                features = extra.get("features", {})
                
                if not all([qid, doc, features]):
                    continue

                feats = [features.get(k, 0.0) for k in feats_cols]
                # Simula que o primeiro recomendado foi aceito
                label = 1 if extra.get("accepted", False) else 0 
                records.append([qid, doc, *feats, label])
            except (json.JSONDecodeError, KeyError):
                continue

    cols = ["qid", "docid", *feats_cols, "label"]
    return pd.DataFrame(records, columns=cols)

# ---------------------------------------------------------------------------
# 3. Treina LightGBM Ranker
# ---------------------------------------------------------------------------

def train_lgb_ltr(df: pd.DataFrame) -> lgb.Booster:
    feats = list("ASTGQURC")
    X = df[feats]
    y = df["label"]
    qid = df["qid"]
    groups = qid.value_counts().sort_index().values
    dtrain = lgb.Dataset(X, label=y, group=groups, feature_name=feats)
    params = {
        "objective": "lambdarank",
        "metric": "ndcg",
        "num_leaves": 15,
        "learning_rate": 0.1,
        "verbose": -1,
    }
    model = lgb.train(params, dtrain, num_boost_round=120)
    return model

# ---------------------------------------------------------------------------
# 4. Extrai importâncias → json
# ---------------------------------------------------------------------------

def save_weights(model: lgb.Booster, out_json: Path):
    gain = model.feature_importance(importance_type="gain")
    feats = model.feature_name()
    total = sum(gain) or 1.0
    weights: Dict[str, float] = {f: round(g / total, 4) for f, g in zip(feats, gain)}
    
    print("--- Pesos Aprendidos ---")
    print(json.dumps(weights, indent=2))
    print("------------------------")

    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(weights, f, indent=2)
    print(f"Pesos salvos em {out_json.relative_to(Path.cwd())}")

# ---------------------------------------------------------------------------
# 5. Main
# ---------------------------------------------------------------------------

def main():
    args = parse_args()
    outdir = Path(args.outdir)
    os.makedirs(outdir, exist_ok=True)
    
    df = load_logs(args.logfile, args.quick)
    if df.empty:
        print("Nenhum dado de log válido encontrado para treinamento.")
        return

    print(f"Dataset: {len(df)} linhas, {df['qid'].nunique()} queries")
    
    model = train_lgb_ltr(df)
    
    model_path = outdir / "ltr_model.txt"
    model.save_model(str(model_path))
    print(f"Modelo salvo → {model_path}")
    
    save_weights(model, outdir / "ltr_weights.json")

if __name__ == "__main__":
    main() 