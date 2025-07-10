"""
Serviço de monitoramento de modelos LTR.
Monitora drift de dados, performance e alertas automáticos.
"""

import json
import logging
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
import pandas as pd

from backend.config import get_settings
from backend.metrics import (
    model_alert_total,
    model_drift_gauge,
    model_performance_gauge,
)
from supabase import create_client

settings = get_settings()
logger = logging.getLogger(__name__)


class AlertLevel(Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


@dataclass
class ModelAlert:
    """Alerta de monitoramento de modelo"""
    alert_id: str
    model_name: str
    alert_type: str
    level: AlertLevel
    message: str
    metrics: Dict[str, float]
    timestamp: datetime
    resolved: bool = False


@dataclass
class DriftReport:
    """Relatório de drift de dados"""
    model_name: str
    feature_drifts: Dict[str, float]
    overall_drift_score: float
    drift_detected: bool
    timestamp: datetime
    recommendations: List[str]


class ModelMonitoringService:
    """Serviço para monitorar modelos LTR em produção"""

    def __init__(self):
        self.supabase = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY)
        self.features = ['T', 'G', 'Q', 'R', 'A', 'S', 'U', 'C']
        self.alerts: List[ModelAlert] = []

        # Thresholds para alertas
        self.thresholds = {
            "performance_degradation": 0.1,  # 10% de degradação
            "drift_score": 0.3,  # Score de drift > 0.3
            "prediction_anomaly": 2.0,  # 2 desvios padrão
            "error_rate": 0.05  # 5% de erro
        }

    def monitor_model_performance(
            self, model_name: str, days_back: int = 7) -> Dict[str, Any]:
        """Monitora performance do modelo nos últimos N dias"""
        try:
            # Coletar dados de performance
            cutoff_date = (datetime.now() - timedelta(days=days_back)).isoformat()

            # Query para buscar predições e resultados reais
            query = """
            SELECT
                m.score as predicted_score,
                CASE
                    WHEN o.status = 'accepted' THEN 3
                    WHEN o.status = 'pending' THEN 2
                    WHEN o.status = 'rejected' THEN 1
                    ELSE 0
                END as actual_score,
                m.created_at
            FROM matches m
            LEFT JOIN offers o ON m.lawyer_id = o.lawyer_id AND m.case_id = o.case_id
            WHERE m.created_at >= %s
            ORDER BY m.created_at DESC
            """

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

            if df.empty:
                return {"error": "Dados insuficientes para monitoramento"}

            # Calcular métricas de performance
            predictions = df['predicted_score'].values
            actuals = df['actual_score'].values

            # MSE e MAE
            mse = np.mean((predictions - actuals) ** 2)
            mae = np.mean(np.abs(predictions - actuals))

            # Correlação
            correlation = np.corrcoef(predictions, actuals)[
                0, 1] if len(predictions) > 1 else 0

            # NDCG
            ndcg = self._calculate_ndcg(actuals, predictions)

            # Atualizar métricas Prometheus
            model_performance_gauge.labels(
                model_type=model_name,
                metric="mse"
            ).set(mse)

            model_performance_gauge.labels(
                model_type=model_name,
                metric="mae"
            ).set(mae)

            model_performance_gauge.labels(
                model_type=model_name,
                metric="correlation"
            ).set(correlation)

            model_performance_gauge.labels(
                model_type=model_name,
                metric="ndcg"
            ).set(ndcg)

            # Verificar se há degradação
            baseline_mse = self._get_baseline_metric(model_name, "mse")
            if baseline_mse and mse > baseline_mse * \
                    (1 + self.thresholds["performance_degradation"]):
                self._create_alert(
                    model_name=model_name,
                    alert_type="performance_degradation",
                    level=AlertLevel.HIGH,
                    message=f"MSE aumentou {((mse /
                                              baseline_mse -
                                              1) *
                                             100):.1f}% comparado ao baseline",
                    metrics={"current_mse": mse, "baseline_mse": baseline_mse}
                )

            return {
                "model_name": model_name,
                "period_days": days_back,
                "samples_count": len(df),
                "metrics": {
                    "mse": mse,
                    "mae": mae,
                    "correlation": correlation,
                    "ndcg": ndcg
                },
                "timestamp": datetime.now().isoformat()
            }

        except Exception as e:
            logger.error(f"Erro no monitoramento de performance: {e}")
            return {"error": str(e)}

    def detect_data_drift(self, model_name: str, days_back: int = 7) -> DriftReport:
        """Detecta drift nos dados de entrada"""
        try:
            # Coletar dados recentes
            recent_data = self._collect_feature_data(days_back)

            # Coletar dados de baseline (período anterior)
            baseline_data = self._collect_feature_data(days_back, offset_days=days_back)

            if recent_data.empty or baseline_data.empty:
                return DriftReport(
                    model_name=model_name,
                    feature_drifts={},
                    overall_drift_score=0.0,
                    drift_detected=False,
                    timestamp=datetime.now(),
                    recommendations=["Dados insuficientes para análise de drift"]
                )

            # Calcular drift para cada feature
            feature_drifts = {}
            for feature in self.features:
                if feature in recent_data.columns and feature in baseline_data.columns:
                    drift_score = self._calculate_feature_drift(
                        baseline_data[feature].values,
                        recent_data[feature].values
                    )
                    feature_drifts[feature] = drift_score

            # Calcular score geral de drift
            overall_drift_score = np.mean(
                list(feature_drifts.values())) if feature_drifts else 0.0

            # Detectar drift
            drift_detected = overall_drift_score > self.thresholds["drift_score"]

            # Atualizar métricas
            model_drift_gauge.labels(
                model_type=model_name,
                feature="overall"
            ).set(overall_drift_score)

            for feature, drift_score in feature_drifts.items():
                model_drift_gauge.labels(
                    model_type=model_name,
                    feature=feature
                ).set(drift_score)

            # Gerar recomendações
            recommendations = self._generate_drift_recommendations(
                feature_drifts, overall_drift_score)

            # Criar alerta se drift for detectado
            if drift_detected:
                self._create_alert(
                    model_name=model_name,
                    alert_type="data_drift",
                    level=AlertLevel.MEDIUM if overall_drift_score < 0.5 else AlertLevel.HIGH,
                    message=f"Drift detectado com score {overall_drift_score:.3f}",
                    metrics={"drift_score": overall_drift_score, **feature_drifts}
                )

            return DriftReport(
                model_name=model_name,
                feature_drifts=feature_drifts,
                overall_drift_score=overall_drift_score,
                drift_detected=drift_detected,
                timestamp=datetime.now(),
                recommendations=recommendations
            )

        except Exception as e:
            logger.error(f"Erro na detecção de drift: {e}")
            return DriftReport(
                model_name=model_name,
                feature_drifts={},
                overall_drift_score=0.0,
                drift_detected=False,
                timestamp=datetime.now(),
                recommendations=[f"Erro na análise: {str(e)}"]
            )

    def monitor_prediction_anomalies(
            self, model_name: str, days_back: int = 1) -> Dict[str, Any]:
        """Monitora anomalias nas predições"""
        try:
            # Coletar predições recentes
            cutoff_date = (datetime.now() - timedelta(days=days_back)).isoformat()

            query = """
            SELECT score, created_at
            FROM matches
            WHERE created_at >= %s
            ORDER BY created_at DESC
            """

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

            if df.empty:
                return {"error": "Dados insuficientes"}

            scores = df['score'].values

            # Calcular estatísticas
            mean_score = np.mean(scores)
            std_score = np.std(scores)

            # Detectar anomalias (valores > 2 desvios padrão)
            anomalies = np.abs(
                scores - mean_score) > (self.thresholds["prediction_anomaly"] * std_score)
            anomaly_count = np.sum(anomalies)
            anomaly_rate = anomaly_count / len(scores)

            # Criar alerta se muitas anomalias
            if anomaly_rate > self.thresholds["error_rate"]:
                self._create_alert(
                    model_name=model_name,
                    alert_type="prediction_anomaly",
                    level=AlertLevel.MEDIUM,
                    message=f"Taxa de anomalias alta: {anomaly_rate:.1%}",
                    metrics={
                        "anomaly_rate": anomaly_rate,
                        "anomaly_count": anomaly_count}
                )

            return {
                "model_name": model_name,
                "period_days": days_back,
                "total_predictions": len(scores),
                "anomaly_count": int(anomaly_count),
                "anomaly_rate": anomaly_rate,
                "score_stats": {
                    "mean": mean_score,
                    "std": std_score,
                    "min": np.min(scores),
                    "max": np.max(scores)
                },
                "timestamp": datetime.now().isoformat()
            }

        except Exception as e:
            logger.error(f"Erro no monitoramento de anomalias: {e}")
            return {"error": str(e)}

    def _collect_feature_data(self, days_back: int,
                              offset_days: int = 0) -> pd.DataFrame:
        """Coleta dados de features para análise"""
        try:
            start_date = (
                datetime.now() -
                timedelta(
                    days=days_back +
                    offset_days)).isoformat()
            end_date = (datetime.now() - timedelta(days=offset_days)).isoformat()

            query = """
            SELECT features, created_at
            FROM matches
            WHERE created_at >= %s AND created_at <= %s
            ORDER BY created_at DESC
            """

            import psycopg2
            conn = psycopg2.connect(
                host=settings.DATABASE_HOST,
                database=settings.DATABASE_NAME,
                user=settings.DATABASE_USER,
                password=settings.DATABASE_PASSWORD,
                port=settings.DATABASE_PORT
            )

            df = pd.read_sql_query(query, conn, params=[start_date, end_date])
            conn.close()

            if not df.empty:
                # Processar features JSON
                features_df = pd.json_normalize(df['features'].apply(json.loads))
                return features_df

            return pd.DataFrame()

        except Exception as e:
            logger.error(f"Erro ao coletar dados de features: {e}")
            return pd.DataFrame()

    def _calculate_feature_drift(self, baseline: np.ndarray,
                                 current: np.ndarray) -> float:
        """Calcula score de drift para uma feature usando KL divergence"""
        try:
            # Remover valores NaN
            baseline = baseline[~np.isnan(baseline)]
            current = current[~np.isnan(current)]

            if len(baseline) == 0 or len(current) == 0:
                return 0.0

            # Criar histogramas
            bins = np.linspace(
                min(np.min(baseline), np.min(current)),
                max(np.max(baseline), np.max(current)),
                20
            )

            hist_baseline, _ = np.histogram(baseline, bins=bins, density=True)
            hist_current, _ = np.histogram(current, bins=bins, density=True)

            # Adicionar pequeno valor para evitar log(0)
            hist_baseline = hist_baseline + 1e-10
            hist_current = hist_current + 1e-10

            # Normalizar
            hist_baseline = hist_baseline / np.sum(hist_baseline)
            hist_current = hist_current / np.sum(hist_current)

            # Calcular KL divergence
            kl_div = np.sum(hist_current * np.log(hist_current / hist_baseline))

            return float(kl_div)

        except Exception as e:
            logger.error(f"Erro ao calcular drift: {e}")
            return 0.0

    def _calculate_ndcg(self, y_true: np.ndarray,
                        y_pred: np.ndarray, k: int = 10) -> float:
        """Calcula NDCG (Normalized Discounted Cumulative Gain)"""
        try:
            if len(y_true) == 0 or len(y_pred) == 0:
                return 0.0

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

    def _get_baseline_metric(self, model_name: str, metric: str) -> Optional[float]:
        """Recupera métrica baseline do modelo"""
        try:
            # Buscar no banco ou cache
            # Por simplicidade, retornando valor fixo
            baselines = {
                "mse": 0.5,
                "mae": 0.3,
                "correlation": 0.7,
                "ndcg": 0.8
            }
            return baselines.get(metric)

        except Exception as e:
            logger.error(f"Erro ao obter baseline: {e}")
            return None

    def _generate_drift_recommendations(
            self, feature_drifts: Dict[str, float], overall_score: float) -> List[str]:
        """Gera recomendações baseadas no drift detectado"""
        recommendations = []

        if overall_score > 0.5:
            recommendations.append("Considere retreinar o modelo com dados recentes")

        if overall_score > 0.3:
            recommendations.append("Monitore mais de perto as predições do modelo")

        # Recomendações específicas por feature
        high_drift_features = [f for f, score in feature_drifts.items() if score > 0.4]
        if high_drift_features:
            recommendations.append(
                f"Features com alto drift: {
                    ', '.join(high_drift_features)}")

        if not recommendations:
            recommendations.append("Drift dentro dos limites aceitáveis")

        return recommendations

    def _create_alert(self, model_name: str, alert_type: str,
                      level: AlertLevel, message: str, metrics: Dict[str, float]) -> None:
        """Cria um alerta de monitoramento"""
        try:
            alert = ModelAlert(
                alert_id=f"{model_name}_{alert_type}_{
                    datetime.now().strftime('%Y%m%d_%H%M%S')}",
                model_name=model_name,
                alert_type=alert_type,
                level=level,
                message=message,
                metrics=metrics,
                timestamp=datetime.now()
            )

            self.alerts.append(alert)

            # Incrementar contador de alertas
            model_alert_total.labels(
                model_type=model_name,
                alert_type=alert_type,
                level=level.value
            ).inc()

            # Salvar no banco
            alert_data = {
                "alert_id": alert.alert_id,
                "model_name": alert.model_name,
                "alert_type": alert.alert_type,
                "level": alert.level.value,
                "message": alert.message,
                "metrics": json.dumps(alert.metrics),
                "timestamp": alert.timestamp.isoformat(),
                "resolved": alert.resolved
            }

            self.supabase.table("model_alerts").insert(alert_data).execute()

            logger.warning(f"Alerta criado: {alert.alert_id} - {alert.message}")

        except Exception as e:
            logger.error(f"Erro ao criar alerta: {e}")

    def get_active_alerts(self, model_name: Optional[str] = None) -> List[ModelAlert]:
        """Retorna alertas ativos"""
        try:
            query = self.supabase.table("model_alerts").select(
                "*").eq("resolved", False)

            if model_name:
                query = query.eq("model_name", model_name)

            response = query.execute()

            alerts = []
            for alert_data in response.data:
                alert = ModelAlert(
                    alert_id=alert_data["alert_id"],
                    model_name=alert_data["model_name"],
                    alert_type=alert_data["alert_type"],
                    level=AlertLevel(alert_data["level"]),
                    message=alert_data["message"],
                    metrics=json.loads(alert_data["metrics"]),
                    timestamp=datetime.fromisoformat(alert_data["timestamp"]),
                    resolved=alert_data["resolved"]
                )
                alerts.append(alert)

            return alerts

        except Exception as e:
            logger.error(f"Erro ao buscar alertas: {e}")
            return []

    def resolve_alert(self, alert_id: str) -> bool:
        """Marca um alerta como resolvido"""
        try:
            self.supabase.table("model_alerts").update({
                "resolved": True,
                "resolved_at": datetime.now().isoformat()
            }).eq("alert_id", alert_id).execute()

            logger.info(f"Alerta resolvido: {alert_id}")
            return True

        except Exception as e:
            logger.error(f"Erro ao resolver alerta: {e}")
            return False

    def generate_monitoring_report(
            self, model_name: str, days_back: int = 7) -> Dict[str, Any]:
        """Gera relatório completo de monitoramento"""
        try:
            # Coletar todas as métricas
            performance_report = self.monitor_model_performance(model_name, days_back)
            drift_report = self.detect_data_drift(model_name, days_back)
            anomaly_report = self.monitor_prediction_anomalies(model_name, days_back)
            active_alerts = self.get_active_alerts(model_name)

            return {
                "model_name": model_name,
                "report_period_days": days_back,
                "generated_at": datetime.now().isoformat(),
                "performance": performance_report,
                "drift_analysis": {
                    "overall_drift_score": drift_report.overall_drift_score,
                    "drift_detected": drift_report.drift_detected,
                    "feature_drifts": drift_report.feature_drifts,
                    "recommendations": drift_report.recommendations
                },
                "anomaly_analysis": anomaly_report,
                "active_alerts": [
                    {
                        "alert_id": alert.alert_id,
                        "type": alert.alert_type,
                        "level": alert.level.value,
                        "message": alert.message,
                        "timestamp": alert.timestamp.isoformat()
                    }
                    for alert in active_alerts
                ],
                "health_score": self._calculate_health_score(performance_report, drift_report, anomaly_report)
            }

        except Exception as e:
            logger.error(f"Erro ao gerar relatório: {e}")
            return {"error": str(e)}

    def _calculate_health_score(self, performance: Dict,
                                drift: DriftReport, anomaly: Dict) -> float:
        """Calcula score de saúde do modelo (0-1)"""
        try:
            score = 1.0

            # Penalizar por drift
            if drift.drift_detected:
                score -= min(drift.overall_drift_score, 0.5)

            # Penalizar por anomalias
            if "anomaly_rate" in anomaly:
                score -= min(anomaly["anomaly_rate"], 0.3)

            # Penalizar por baixa correlação
            if "metrics" in performance and "correlation" in performance["metrics"]:
                correlation = performance["metrics"]["correlation"]
                if correlation < 0.5:
                    score -= (0.5 - correlation)

            return max(0.0, min(1.0, score))

        except Exception as e:
            logger.error(f"Erro ao calcular health score: {e}")
            return 0.5


# Instância global
model_monitoring_service = ModelMonitoringService()
