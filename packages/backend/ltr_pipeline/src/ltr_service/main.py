# -*- coding: utf-8 -*-
"""
LTR Scoring Service - FastAPI
============================

Serviço de scoring do modelo LightGBM LambdaMART para o sistema de matching.
Baseado na documentação LTR.MD para servir predições em tempo real.
"""

import os
import pickle
import logging
from pathlib import Path
from typing import Dict, List, Optional

import lightgbm as lgb
import numpy as np
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import prometheus_client
from prometheus_client import Counter, Histogram, generate_latest

# Configuração de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Métricas Prometheus
PREDICTION_COUNTER = Counter('ltr_predictions_total', 'Total LTR predictions served')
PREDICTION_LATENCY = Histogram('ltr_prediction_duration_seconds', 'LTR prediction latency')
ERROR_COUNTER = Counter('ltr_errors_total', 'Total LTR errors', ['error_type'])

# Configurações de ambiente
MODEL_PATH = os.getenv("MODEL_PATH", "/opt/models/ltr_model.txt")
FEATURE_MAP_PATH = os.getenv("FEATURE_MAP", "/opt/models/feature_map.pkl")

# App FastAPI
app = FastAPI(
    title="LitGo LTR Scoring Service",
    description="Serviço de scoring do modelo LambdaMART para matching jurídico",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Variáveis globais para modelo
MODEL: Optional[lgb.Booster] = None
FEATURE_ORDER: Optional[List[str]] = None

# Modelos Pydantic
class LTRFeatures(BaseModel):
    """Features para scoring LTR"""
    A: float = Field(..., description="Area Match")
    S: float = Field(..., description="Case Similarity") 
    T: float = Field(..., description="Success Rate")
    G: float = Field(..., description="Geographic Score")
    Q: float = Field(..., description="Qualification Score")
    U: float = Field(..., description="Urgency Capacity")
    R: float = Field(..., description="Review Score")
    C: float = Field(..., description="Soft Skills")
    E: float = Field(..., description="Firm Reputation")
    P: float = Field(..., description="Price Fit")
    M: float = Field(..., description="Maturity Score")

class LTRRequest(BaseModel):
    """Requisição de scoring"""
    features: LTRFeatures

class LTRResponse(BaseModel):
    """Resposta de scoring"""
    score: float
    model_version: str = "production"

def load_model():
    """Carrega modelo LightGBM e mapa de features"""
    global MODEL, FEATURE_ORDER
    
    try:
        # Verificar se arquivos existem
        if not Path(MODEL_PATH).exists():
            logger.warning(f"Modelo não encontrado em {MODEL_PATH}, usando mock")
            MODEL = None
            FEATURE_ORDER = ["A", "S", "T", "G", "Q", "U", "R", "C", "E", "P", "M"]
            return
            
        # Carregar modelo LightGBM
        MODEL = lgb.Booster(model_file=MODEL_PATH)
        logger.info(f"Modelo LightGBM carregado de {MODEL_PATH}")
        
        # Carregar ordem das features
        if Path(FEATURE_MAP_PATH).exists():
            with open(FEATURE_MAP_PATH, "rb") as f:
                FEATURE_ORDER = pickle.load(f)
        else:
            # Fallback para ordem padrão
            FEATURE_ORDER = ["A", "S", "T", "G", "Q", "U", "R", "C", "E", "P", "M"]
            
        logger.info(f"Feature order: {FEATURE_ORDER}")
        
    except Exception as e:
        logger.error(f"Erro ao carregar modelo: {e}")
        ERROR_COUNTER.labels(error_type="model_load").inc()
        MODEL = None
        FEATURE_ORDER = ["A", "S", "T", "G", "Q", "U", "R", "C", "E", "P", "M"]

@app.on_event("startup")
async def startup_event():
    """Inicialização do serviço"""
    logger.info("Iniciando LTR Scoring Service...")
    load_model()
    logger.info("Serviço iniciado com sucesso")

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model_loaded": MODEL is not None,
        "feature_order": FEATURE_ORDER
    }

@app.get("/metrics")
async def metrics():
    """Endpoint de métricas Prometheus"""
    return generate_latest()

@app.post("/ltr/score", response_model=LTRResponse)
async def ltr_score(request: LTRRequest):
    """
    Endpoint principal de scoring LTR
    
    Recebe features normalizadas e retorna score de relevância.
    """
    with PREDICTION_LATENCY.time():
        try:
            # Converter features para array numpy
            features_dict = request.features.dict()
            
            if FEATURE_ORDER is None:
                raise HTTPException(status_code=500, detail="Feature order not loaded")
            
            # Ordenar features conforme esperado pelo modelo
            feature_vector = np.array([[features_dict[f] for f in FEATURE_ORDER]])
            
            # Predição
            if MODEL is not None:
                # Usar modelo real
                score = MODEL.predict(feature_vector, num_iteration=MODEL.best_iteration)[0]
            else:
                # Mock para desenvolvimento/teste
                logger.warning("Usando mock do modelo - soma ponderada das features")
                weights = [0.23, 0.18, 0.11, 0.07, 0.07, 0.05, 0.05, 0.03, 0.02, 0.02, 0.17]
                score = float(np.dot(feature_vector[0], weights))
            
            PREDICTION_COUNTER.inc()
            
            return LTRResponse(score=float(score))
            
        except KeyError as e:
            ERROR_COUNTER.labels(error_type="missing_feature").inc()
            raise HTTPException(status_code=422, detail=f"Missing feature: {e}")
        except Exception as e:
            ERROR_COUNTER.labels(error_type="prediction_error").inc()
            logger.error(f"Erro na predição: {e}")
            raise HTTPException(status_code=500, detail="Internal prediction error")

@app.post("/ltr/reload")
async def reload_model():
    """
    Endpoint para recarregar modelo sem restart
    Útil para deploy de novos modelos
    """
    try:
        load_model()
        return {"status": "success", "message": "Modelo recarregado"}
    except Exception as e:
        logger.error(f"Erro ao recarregar modelo: {e}")
        raise HTTPException(status_code=500, detail=f"Erro ao recarregar: {e}")

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "LitGo LTR Scoring Service",
        "version": "1.0.0",
        "status": "running",
        "endpoints": [
            "/health",
            "/ltr/score", 
            "/ltr/reload",
            "/metrics"
        ]
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080) 