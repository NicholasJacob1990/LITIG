import pandas as pd, pathlib, datetime as dt, numpy as np, json
from .config import FEATURES, LABEL_MAP

RAW_DIR = pathlib.Path("packages/backend/ltr_pipeline/data/raw")
OUT_DIR = pathlib.Path("packages/backend/ltr_pipeline/data/processed")
OUT_DIR.mkdir(parents=True, exist_ok=True)

def build_matrix():
    files = sorted(RAW_DIR.glob("*.parquet"))[-90:]   # últimos 90 dias
    if not files:
        print("⚠️  Nenhum parquet bruto.")
        return
    df = pd.concat([pd.read_parquet(f) for f in files], ignore_index=True)

    feat_df = df["features"].apply(pd.Series)
    df = pd.concat([df.drop(columns=["features"]), feat_df], axis=1)

    df["label"] = df["event_type"].map(LABEL_MAP).fillna(0)

    cutoff_valid = (dt.datetime.utcnow() - dt.timedelta(days=30)).date()
    cutoff_test  = (dt.datetime.utcnow() - dt.timedelta(days=7)).date()
    df["split"]  = np.where(df["ts_utc"].dt.date < cutoff_valid, "train",
                    np.where(df["ts_utc"].dt.date < cutoff_test, "valid", "test"))

    out = OUT_DIR / "matrix.parquet"
    df.to_parquet(out, index=False)
    print(f"✓ Matrix salva em {out}") 