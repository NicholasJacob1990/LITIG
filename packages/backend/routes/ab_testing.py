"""
Rotas para gerenciamento de testes A/B e monitoramento de modelos.
"""

import logging
from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException

from backend.auth import get_current_user
from backend.jobs.auto_retrain import auto_retrain_task
from backend.services.ab_testing import (
    ABTestConfig,
    ABTestResult,
    TestStatus,
    ab_testing_service,
)
from backend.services.model_monitoring import model_monitoring_service

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/ab-testing", tags=["A/B Testing"])

# ============================================================================
# ROTAS DE A/B TESTING
# ============================================================================


@router.post("/tests", response_model=dict)
async def create_ab_test(
    test_config: dict,
    current_user=Depends(get_current_user)
):
    """Cria um novo teste A/B"""
    try:
        # Validar dados
        required_fields = [
            'test_id',
            'name',
            'control_model',
            'treatment_model',
            'traffic_split']
        for field in required_fields:
            if field not in test_config:
                raise HTTPException(
                    status_code=400,
                    detail=f"Campo obrigatório: {field}")

        # Criar configuração
        config = ABTestConfig(
            test_id=test_config['test_id'],
            name=test_config['name'],
            description=test_config.get('description', ''),
            control_model=test_config['control_model'],
            treatment_model=test_config['treatment_model'],
            traffic_split=test_config['traffic_split'],
            start_date=datetime.fromisoformat(test_config.get(
                'start_date', datetime.now().isoformat())),
            end_date=datetime.fromisoformat(test_config.get(
                'end_date', (datetime.now() + timedelta(days=7)).isoformat())),
            min_sample_size=test_config.get('min_sample_size', 100),
            significance_level=test_config.get('significance_level', 0.05),
            success_metric=test_config.get('success_metric', 'conversion_rate'),
            status=TestStatus.ACTIVE,
            created_at=datetime.now(),
            updated_at=datetime.now()
        )

        # Criar teste
        success = ab_testing_service.create_test(config)

        if success:
            return {"status": "success", "test_id": config.test_id}
        else:
            raise HTTPException(status_code=500, detail="Erro ao criar teste A/B")

    except Exception as e:
        logger.error(f"Erro ao criar teste A/B: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/tests", response_model=List[dict])
async def list_ab_tests(
    status: Optional[str] = None,
    current_user=Depends(get_current_user)
):
    """Lista testes A/B"""
    try:
        if status:
            tests = [test for test in ab_testing_service.current_tests.values()
                     if test.status.value == status]
        else:
            tests = list(ab_testing_service.current_tests.values())

        return [
            {
                "test_id": test.test_id,
                "name": test.name,
                "description": test.description,
                "control_model": test.control_model,
                "treatment_model": test.treatment_model,
                "traffic_split": test.traffic_split,
                "start_date": test.start_date.isoformat(),
                "end_date": test.end_date.isoformat(),
                "status": test.status.value,
                "created_at": test.created_at.isoformat()
            }
            for test in tests
        ]

    except Exception as e:
        logger.error(f"Erro ao listar testes A/B: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/tests/{test_id}/results", response_model=dict)
async def get_ab_test_results(
    test_id: str,
    current_user=Depends(get_current_user)
):
    """Obtém resultados de um teste A/B"""
    try:
        result = ab_testing_service.analyze_test_results(test_id)

        if result is None:
            raise HTTPException(status_code=404,
                                detail="Teste não encontrado ou sem dados")

        return {
            "test_id": result.test_id,
            "control": {
                "conversions": result.control_conversions,
                "exposures": result.control_exposures,
                "rate": result.control_rate
            },
            "treatment": {
                "conversions": result.treatment_conversions,
                "exposures": result.treatment_exposures,
                "rate": result.treatment_rate
            },
            "analysis": {
                "lift": result.lift,
                "p_value": result.p_value,
                "is_significant": result.is_significant,
                "confidence_interval": result.confidence_interval,
                "recommendation": result.recommendation
            }
        }

    except Exception as e:
        logger.error(f"Erro ao obter resultados do teste: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/tests/{test_id}/pause", response_model=dict)
async def pause_ab_test(
    test_id: str,
    current_user=Depends(get_current_user)
):
    """Pausa um teste A/B"""
    try:
        success = ab_testing_service.pause_test(test_id)

        if success:
            return {"status": "success", "message": f"Teste {test_id} pausado"}
        else:
            raise HTTPException(status_code=500, detail="Erro ao pausar teste")

    except Exception as e:
        logger.error(f"Erro ao pausar teste: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/tests/{test_id}/rollback", response_model=dict)
async def rollback_ab_test(
    test_id: str,
    current_user=Depends(get_current_user)
):
    """Executa rollback de um teste A/B"""
    try:
        success = ab_testing_service.rollback_test(test_id)

        if success:
            return {"status": "success",
                    "message": f"Rollback executado para teste {test_id}"}
        else:
            raise HTTPException(status_code=500, detail="Erro ao executar rollback")

    except Exception as e:
        logger.error(f"Erro ao executar rollback: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================================================
# ROTAS DE MONITORAMENTO DE MODELOS
# ============================================================================


@router.get("/models/{model_name}/performance", response_model=dict)
async def get_model_performance(
    model_name: str,
    days_back: int = 7,
    current_user=Depends(get_current_user)
):
    """Obtém métricas de performance de um modelo"""
    try:
        performance = model_monitoring_service.monitor_model_performance(
            model_name, days_back)
        return performance

    except Exception as e:
        logger.error(f"Erro ao obter performance do modelo: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/models/{model_name}/drift", response_model=dict)
async def get_model_drift(
    model_name: str,
    days_back: int = 7,
    current_user=Depends(get_current_user)
):
    """Obtém análise de drift de um modelo"""
    try:
        drift_report = model_monitoring_service.detect_data_drift(model_name, days_back)

        return {
            "model_name": drift_report.model_name,
            "overall_drift_score": drift_report.overall_drift_score,
            "drift_detected": drift_report.drift_detected,
            "feature_drifts": drift_report.feature_drifts,
            "recommendations": drift_report.recommendations,
            "timestamp": drift_report.timestamp.isoformat()
        }

    except Exception as e:
        logger.error(f"Erro ao obter drift do modelo: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/models/{model_name}/anomalies", response_model=dict)
async def get_model_anomalies(
    model_name: str,
    days_back: int = 1,
    current_user=Depends(get_current_user)
):
    """Obtém análise de anomalias de um modelo"""
    try:
        anomalies = model_monitoring_service.monitor_prediction_anomalies(
            model_name, days_back)
        return anomalies

    except Exception as e:
        logger.error(f"Erro ao obter anomalias do modelo: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/models/{model_name}/alerts", response_model=List[dict])
async def get_model_alerts(
    model_name: str,
    current_user=Depends(get_current_user)
):
    """Obtém alertas ativos de um modelo"""
    try:
        alerts = model_monitoring_service.get_active_alerts(model_name)

        return [
            {
                "alert_id": alert.alert_id,
                "alert_type": alert.alert_type,
                "level": alert.level.value,
                "message": alert.message,
                "metrics": alert.metrics,
                "timestamp": alert.timestamp.isoformat()
            }
            for alert in alerts
        ]

    except Exception as e:
        logger.error(f"Erro ao obter alertas do modelo: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/models/{model_name}/alerts/{alert_id}/resolve", response_model=dict)
async def resolve_model_alert(
    model_name: str,
    alert_id: str,
    current_user=Depends(get_current_user)
):
    """Marca um alerta como resolvido"""
    try:
        success = model_monitoring_service.resolve_alert(alert_id)

        if success:
            return {"status": "success", "message": f"Alerta {alert_id} resolvido"}
        else:
            raise HTTPException(status_code=500, detail="Erro ao resolver alerta")

    except Exception as e:
        logger.error(f"Erro ao resolver alerta: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/models/{model_name}/report", response_model=dict)
async def get_model_monitoring_report(
    model_name: str,
    days_back: int = 7,
    current_user=Depends(get_current_user)
):
    """Gera relatório completo de monitoramento"""
    try:
        report = model_monitoring_service.generate_monitoring_report(
            model_name, days_back)
        return report

    except Exception as e:
        logger.error(f"Erro ao gerar relatório: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================================================
# ROTAS DE RETREINO AUTOMÁTICO
# ============================================================================


@router.post("/models/retrain", response_model=dict)
async def trigger_model_retrain(
    force: bool = False,
    current_user=Depends(get_current_user)
):
    """Dispara retreino manual de modelo"""
    try:
        # Executar task de retreino
        task = auto_retrain_task.delay(force_retrain=force)

        return {
            "status": "success",
            "message": "Retreino iniciado",
            "task_id": task.id
        }

    except Exception as e:
        logger.error(f"Erro ao disparar retreino: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/models/retrain/status/{task_id}", response_model=dict)
async def get_retrain_status(
    task_id: str,
    current_user=Depends(get_current_user)
):
    """Obtém status do retreino"""
    try:
        from celery.result import AsyncResult

        task = AsyncResult(task_id)

        return {
            "task_id": task_id,
            "status": task.status,
            "result": task.result if task.ready() else None
        }

    except Exception as e:
        logger.error(f"Erro ao obter status do retreino: {e}")
        raise HTTPException(status_code=500, detail=str(e))
