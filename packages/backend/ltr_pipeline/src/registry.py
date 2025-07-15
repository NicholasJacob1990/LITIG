import json, lightgbm as lgb, pathlib
from .config import FEATURES

MODEL_TXT = pathlib.Path("packages/backend/ltr_pipeline/models/dev/ltr_model.txt")
WEIGHTS   = pathlib.Path("packages/backend/models/ltr_weights.json")

def publish_model():
    booster = lgb.Booster(model_file=str(MODEL_TXT))
    gains = booster.feature_importance(importance_type="gain")
    weights = {f: float(g) for f,g in zip(FEATURES, gains)}
    total = sum(weights.values()) or 1
    weights = {k: v/total for k,v in weights.items()}
    WEIGHTS.parent.mkdir(parents=True, exist_ok=True)
    WEIGHTS.write_text(json.dumps(weights, indent=2))
    print("✓ Pesos publicados em", WEIGHTS) 