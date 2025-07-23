"""
Job de retreino automático de modelos LTR.
Coleta dados de feedback, treina novos modelos e executa testes A/B.
"""

import json
import logging
import os
import pickle
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

import joblib
import numpy as np
import pandas as pd
from celery import Celery
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.model_selection import train_test_split

from config import get_settings
from metrics import model_performance_gauge, model_retrain_total
from services.ab_testing import ABTestConfig, TestStatus, ab_testing_service
from supabase import create_client

settings = get_settings()
logger = logging.getLogger(__name__)

# Configuração do Celery
celery_app = Celery('auto_retrain')
celery_app.config_from_object(settings, namespace='CELERY')


class LTRModelTrainer:
    """Classe para treinar modelos LTR (Learning to Rank)"""

    def __init__(self):
        self.supabase = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY)
        self.model_path = "backend/models/"
        self.features = [
            'T',  # Tempo de resposta
            'G',  # Geolocalização
            'Q',  # Qualidade/Rating
            'R',  # Reputação
            'A',  # Availability
            'S',  # Specialization
            'U',  # Utilization
            'C'   # Soft Skills
        ]

    def collect_training_data(self, days_back: int = 30) -> pd.DataFrame:
        """Coleta dados de treinamento dos últimos N dias"""
        try:
            # Data limite
            cutoff_date = (datetime.now() - timedelta(days=days_back)).isoformat()

            # Query para coletar dados de matches e seus resultados
            query = """
            SELECT
                m.lawyer_id,
                m.case_id,
                m.rank_position,
                m.score,
                m.features,
                CASE
                    WHEN o.id IS NOT NULL AND o.status = 'accepted' THEN 3
                    WHEN o.id IS NOT NULL AND o.status = 'pending' THEN 2
                    WHEN o.id IS NOT NULL AND o.status = 'rejected' THEN 1
                    ELSE 0
                END as relevance_score,
                m.created_at
            FROM matches m
            LEFT JOIN offers o ON m.lawyer_id = o.lawyer_id AND m.case_id = o.case_id
            WHERE m.created_at >= %s
            ORDER BY m.created_at DESC
            """

            # Executar query usando conexão direta
            import psycopg2
            conn = psycopg2.connect(
                host=settings.DATABASE_HOST,
                database=settings.DATABASE_NAME,
                user=settings.DATABASE_USER,
                password=settings.DATABASE_PASSWORD,
                port=settings.DATABASE_PORT
            )

            df = pd.read_sql_query(query, conn, params=[cutoff_date])
            conn.close()

            # Processar features (assumindo que estão em formato JSON)
            if not df.empty:
                features_df = pd.json_normalize(df['features'].apply(json.loads))
                df = pd.concat([df.drop('features', axis=1), features_df], axis=1)

            logger.info(f"Coletados {len(df)} registros de treinamento")
            return df

        except Exception as e:
            logger.error(f"Erro ao coletar dados de treinamento: {e}")
            return pd.DataFrame()

    def prepare_features(self, df: pd.DataFrame) -> Tuple[np.ndarray, np.ndarray]:
        """Prepara features e labels para treinamento"""
        try:
            # Extrair features
            X = df[self.features].fillna(0).values

            # Labels são os scores de relevância
            y = df['relevance_score'].values

            return X, y

        except Exception as e:
            logger.error(f"Erro ao preparar features: {e}")
            return np.array([]), np.array([])

    def train_model(self, X: np.ndarray,
                    y: np.ndarray) -> Optional[RandomForestRegressor]:
        """Treina um novo modelo LTR"""
        try:
            if len(X) == 0 or len(y) == 0:
                logger.warning("Dados insuficientes para treinamento")
                return None

            # Dividir dados
            X_train, X_test, y_train, y_test = train_test_split(
                X, y, test_size=0.2, random_state=42
            )

            # Treinar modelo
            model = RandomForestRegressor(
                n_estimators=100,
                max_depth=10,
                min_samples_split=5,
                min_samples_leaf=2,
                random_state=42
            )

            model.fit(X_train, y_train)

            # Avaliar modelo
            y_pred = model.predict(X_test)
            mse = mean_squared_error(y_test, y_pred)
            r2 = r2_score(y_test, y_pred)

            logger.info(f"Modelo treinado - MSE: {mse:.4f}, R²: {r2:.4f}")

            # Atualizar métricas
            model_performance_gauge.labels(
                model_type="ltr_rf",
                metric="mse"
            ).set(mse)

            model_performance_gauge.labels(
                model_type="ltr_rf",
                metric="r2"
            ).set(r2)

            return model

        except Exception as e:
            logger.error(f"Erro ao treinar modelo: {e}")
            return None

    def save_model(self, model: RandomForestRegressor, version: str) -> str:
        """Salva modelo treinado"""
        try:
            os.makedirs(self.model_path, exist_ok=True)

            model_filename = f"ltr_model_{version}.pkl"
            model_filepath = os.path.join(self.model_path, model_filename)

            # Salvar modelo
            joblib.dump(model, model_filepath)

            # Salvar metadados
            metadata = {
                "version": version,
                "created_at": datetime.now().isoformat(),
                "features": self.features,
                "model_type": "RandomForestRegressor"
            }

            metadata_filepath = os.path.join(
                self.model_path, f"ltr_metadata_{version}.json")
            with open(metadata_filepath, 'w') as f:
                json.dump(metadata, f, indent=2)

            logger.info(f"Modelo salvo: {model_filepath}")
            return model_filename

        except Exception as e:
            logger.error(f"Erro ao salvar modelo: {e}")
            return ""

    def get_feature_importance(self, model: RandomForestRegressor) -> Dict[str, float]:
        """Retorna importância das features"""
        try:
            importance = model.feature_importances_
            return dict(zip(self.features, importance))
        except Exception as e:
            logger.error(f"Erro ao obter importância das features: {e}")
            return {}


class ModelValidator:
    """Classe para validar novos modelos"""

    def __init__(self):
        self.supabase = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY)

    def validate_model_performance(
            self, model_path: str, validation_data: pd.DataFrame) -> Dict[str, float]:
        """Valida performance do modelo em dados de validação"""
        try:
            # Carregar modelo
            model = joblib.load(model_path)

            # Preparar dados de validação
            trainer = LTRModelTrainer()
            X, y = trainer.prepare_features(validation_data)

            if len(X) == 0:
                return {"error": "Dados de validação insuficientes"}

            # Fazer predições
            y_pred = model.predict(X)

            # Calcular métricas
            mse = mean_squared_error(y, y_pred)
            r2 = r2_score(y, y_pred)

            # Calcular NDCG (Normalized Discounted Cumulative Gain)
            ndcg = self._calculate_ndcg(y, y_pred)

            return {
                "mse": mse,
                "r2": r2,
                "ndcg": ndcg
            }

        except Exception as e:
            logger.error(f"Erro ao validar modelo: {e}")
            return {"error": str(e)}

    def _calculate_ndcg(self, y_true: np.ndarray,
                        y_pred: np.ndarray, k: int = 10) -> float:
        """Calcula NDCG (Normalized Discounted Cumulative Gain)"""
        try:
            # Ordenar por predição
            sorted_indices = np.argsort(y_pred)[::-1][:k]

            # DCG
            dcg = sum(y_true[i] / np.log2(idx + 2)
                      for idx, i in enumerate(sorted_indices))

            # IDCG (Ideal DCG)
            ideal_sorted = np.sort(y_true)[::-1][:k]
            idcg = sum(ideal_sorted[i] / np.log2(i + 2)
                       for i in range(len(ideal_sorted)))

            return dcg / idcg if idcg > 0 else 0.0

        except Exception as e:
            logger.error(f"Erro ao calcular NDCG: {e}")
            return 0.0


@celery_app.task(bind=True, max_retries=3)
def auto_retrain_task(self, force_retrain: bool = False):
    """Task principal de retreino automático"""
    try:
        logger.info("Iniciando retreino automático de modelo LTR")

        # Incrementar contador de retreinos
        model_retrain_total.labels(trigger="scheduled").inc()

        trainer = LTRModelTrainer()
        validator = ModelValidator()

        # 1. Coletar dados de treinamento
        training_data = trainer.collect_training_data(days_back=30)

        if len(training_data) < 100 and not force_retrain:
            logger.warning("Dados insuficientes para retreino automático")
            return {"status": "skipped", "reason": "insufficient_data"}

        # 2. Preparar features
        X, y = trainer.prepare_features(training_data)

        # 3. Treinar novo modelo
        new_model = trainer.train_model(X, y)

        if new_model is None:
            logger.error("Falha ao treinar novo modelo")
            return {"status": "failed", "reason": "training_failed"}

        # 4. Salvar modelo
        version = datetime.now().strftime("%Y%m%d_%H%M%S")
        model_filename = trainer.save_model(new_model, version)

        if not model_filename:
            logger.error("Falha ao salvar modelo")
            return {"status": "failed", "reason": "save_failed"}

        # 5. Validar modelo em dados de validação
        validation_data = trainer.collect_training_data(days_back=7)  # Últimos 7 dias
        model_path = os.path.join(trainer.model_path, model_filename)
        validation_metrics = validator.validate_model_performance(
            model_path, validation_data)

        # 6. Criar teste A/B se a validação for bem-sucedida
        if "error" not in validation_metrics and validation_metrics.get("r2", 0) > 0.1:
            test_config = ABTestConfig(
                test_id=f"ltr_test_{version}",
                name=f"LTR Model Test {version}",
                description=f"Teste automático do modelo LTR retreinado em {
                    datetime.now().strftime('%Y-%m-%d')}",
                control_model="production",
                treatment_model=model_filename,
                traffic_split=0.1,  # 10% do tráfego
                start_date=datetime.now(),
                end_date=datetime.now() + timedelta(days=7),
                min_sample_size=100,
                significance_level=0.05,
                success_metric="conversion_rate",
                status=TestStatus.ACTIVE,
                created_at=datetime.now(),
                updated_at=datetime.now()
            )

            # Criar teste A/B
            test_created = ab_testing_service.create_test(test_config)

            if test_created:
                logger.info(f"Teste A/B criado para modelo {model_filename}")
                return {
                    "status": "success",
                    "model_version": version,
                    "model_filename": model_filename,
                    "validation_metrics": validation_metrics,
                    "ab_test_id": test_config.test_id
                }
            else:
                logger.warning("Modelo treinado mas falha ao criar teste A/B")
                return {
                    "status": "partial_success",
                    "model_version": version,
                    "model_filename": model_filename,
                    "validation_metrics": validation_metrics,
                    "ab_test_created": False
                }
        else:
            logger.warning("Modelo não passou na validação")
            return {
                "status": "failed",
                "reason": "validation_failed",
                "validation_metrics": validation_metrics
            }

    except Exception as e:
        logger.error(f"Erro no retreino automático: {e}")
        # Tentar novamente em caso de erro
        raise self.retry(countdown=300, exc=e)


@celery_app.task
def cleanup_old_models():
    """Remove modelos antigos para economizar espaço"""
    try:
        model_path = "backend/models/"

        if not os.path.exists(model_path):
            return {"status": "no_models_directory"}

        # Listar todos os arquivos de modelo
        model_files = [f for f in os.listdir(model_path) if f.startswith(
            "ltr_model_") and f.endswith(".pkl")]

        if len(model_files) <= 5:  # Manter pelo menos 5 modelos
            return {"status": "no_cleanup_needed", "models_count": len(model_files)}

        # Ordenar por data de criação
        model_files.sort(key=lambda x: os.path.getctime(os.path.join(model_path, x)))

        # Remover modelos mais antigos (manter apenas os 5 mais recentes)
        removed_count = 0
        for model_file in model_files[:-5]:
            try:
                os.remove(os.path.join(model_path, model_file))

                # Remover metadados correspondentes
                metadata_file = model_file.replace(
                    "ltr_model_", "ltr_metadata_").replace(".pkl", ".json")
                metadata_path = os.path.join(model_path, metadata_file)
                if os.path.exists(metadata_path):
                    os.remove(metadata_path)

                removed_count += 1
                logger.info(f"Modelo antigo removido: {model_file}")

            except Exception as e:
                logger.error(f"Erro ao remover modelo {model_file}: {e}")

        return {
            "status": "success",
            "removed_count": removed_count,
            "remaining_count": len(model_files) - removed_count
        }

    except Exception as e:
        logger.error(f"Erro na limpeza de modelos: {e}")
        return {"status": "error", "message": str(e)}


@celery_app.task
def monitor_ab_tests():
    """Monitora testes A/B ativos e executa rollback se necessário"""
    try:
        active_tests = ab_testing_service.get_active_tests()

        if not active_tests:
            return {"status": "no_active_tests"}

        rollback_count = 0

        for test in active_tests:
            # Verificar se deve fazer rollback
            if ab_testing_service.should_rollback(test.test_id):
                success = ab_testing_service.rollback_test(test.test_id)
                if success:
                    rollback_count += 1
                    logger.warning(
                        f"Rollback automático executado para teste {
                            test.test_id}")

        return {
            "status": "success",
            "active_tests": len(active_tests),
            "rollbacks_executed": rollback_count
        }

    except Exception as e:
        logger.error(f"Erro no monitoramento de testes A/B: {e}")
        return {"status": "error", "message": str(e)}
