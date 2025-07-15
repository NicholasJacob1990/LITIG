import pandas as pd, numpy as np, lightgbm as lgb, json, pathlib
from sklearn.metrics import ndcg_score
from .config import FEATURES

DATA = pathlib.Path("packages/backend/ltr_pipeline/data/processed/matrix.parquet")
MODEL = pathlib.Path("packages/backend/ltr_pipeline/models/dev/ltr_model.txt")
OUT  = pathlib.Path("packages/backend/ltr_pipeline/models/dev/metrics.json")

def eval_lgbm():
    df = pd.read_parquet(DATA)
    test = df[df["split"]=="test"]
    booster = lgb.Booster(model_file=str(MODEL))
    preds = booster.predict(test[FEATURES].values)

    ndcgs, mrrs = [], []
    for cid, grp in test.groupby("case_id"):
        y_true = grp["label"].values.reshape(1,-1)
        y_pred = preds[grp.index].reshape(1,-1)
        ndcgs.append(ndcg_score(y_true, y_pred, k=5))
        rank = np.argsort(-y_pred)[0]
        first = np.where(grp["label"].values[rank]==1)[0]
        mrrs.append(1/(first[0]+1) if len(first) else 0)

    metrics = {"ndcg@5": float(np.mean(ndcgs)), "mrr@5": float(np.mean(mrrs))}
    OUT.write_text(json.dumps(metrics, indent=2))
    print("✓ Métricas:", metrics) 