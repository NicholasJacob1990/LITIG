#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Partnership Retrain Job
=======================

Job automático para retreinamento do sistema ML de recomendações de parceria.
Executa gradient descent para otimizar pesos baseado no feedback dos usuários.

Funcionalidades:
1. Coleta feedback dos últimos N dias
2. Valida se há dados suficientes para retreino
3. Executa gradient descent optimization
4. Atualiza pesos do PartnershipMLService
5. Monitora performance do modelo
6. Gera relatórios de otimização

Agendamento: Diário às 1h (após jobs de clustering)
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, Optional

from celery import shared_task
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from database import get_async_session
from services.partnership_ml_service import PartnershipMLService, PartnershipFeedback
from backend.metrics import job_executions_total

logger = logging.getLogger(__name__)


@shared_task(name="partnership_retrain.auto_retrain_partnerships_task")
def auto_retrain_partnerships_task(
    days_back: int = 14,  # 🔧 OTIMIZADO: 14 dias (vs. 7) para maior estabilidade
    min_feedback_count: int = 75,  # 🔧 OTIMIZADO: 75 samples (vs. 50) para maior robustez
    force_retrain: bool = False
) -> Dict[str, Any]:
    """
    Task principal de retreino automático do algoritmo de parcerias.
    
    Args:
        days_back: Dias de histórico para coletar feedback
        min_feedback_count: Mínimo de feedbacks para executar retreino
        force_retrain: Forçar retreino mesmo com poucos dados
    
    Returns:
        Dict com resultado da execução
    """
    
    logger.info("🤝 Iniciando retreino automático de recomendações de parceria")
    
    try:
        # Incrementar contador de retreinos
        job_executions_total.labels(
            job_name="partnership_retrain",
            status="started"
        ).inc()
        
        # Executar retreino assíncrono
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        result = loop.run_until_complete(
            _execute_partnership_retrain(days_back, min_feedback_count, force_retrain)
        )
        
        # Registrar sucesso
        job_executions_total.labels(
            job_name="partnership_retrain",
            status="success"
        ).inc()
        
        logger.info(f"✅ Retreino de parcerias concluído: {result}")
        return result
        
    except Exception as e:
        # Registrar falha
        job_executions_total.labels(
            job_name="partnership_retrain", 
            status="failure"
        ).inc()
        
        logger.error(f"❌ Erro no retreino de parcerias: {e}")
        raise
    finally:
        loop.close()


async def _execute_partnership_retrain(
    days_back: int,
    min_feedback_count: int,
    force_retrain: bool
) -> Dict[str, Any]:
    """Executa o retreino do algoritmo de parcerias."""
    
    start_time = datetime.now()
    
    async with get_async_session() as db:
        # Inicializar serviço ML
        ml_service = PartnershipMLService(db)
        
        # 1. Coletar feedback dos últimos dias
        logger.info(f"📊 Coletando feedback dos últimos {days_back} dias")
        
        feedback_data = await ml_service.collect_training_data(days_back=days_back)
        feedback_count = len(feedback_data)
        
        logger.info(f"📈 Coletados {feedback_count} registros de feedback")
        
        # 2. Validar se há dados suficientes
        if feedback_count < min_feedback_count and not force_retrain:
            logger.warning(f"Dados insuficientes para retreino: {feedback_count}/{min_feedback_count}")
            return {
                "status": "skipped",
                "reason": "insufficient_data",
                "feedback_count": feedback_count,
                "min_required": min_feedback_count,
                "execution_time_seconds": (datetime.now() - start_time).total_seconds()
            }
        
        # 3. Calcular métricas antes do retreino
        old_weights = ml_service.weights.to_dict() if ml_service.weights else {}
        
        logger.info("🔄 Executando otimização de pesos via gradient descent")
        
        # 4. Executar retreino
        optimization_result = await ml_service.optimize_weights_from_feedback(
            min_feedback_count=min_feedback_count
        )
        
        if not optimization_result["success"]:
            logger.error(f"❌ Falha na otimização: {optimization_result['error']}")
            return {
                "status": "failed",
                "reason": "optimization_failed",
                "error": optimization_result["error"],
                "feedback_count": feedback_count,
                "execution_time_seconds": (datetime.now() - start_time).total_seconds()
            }
        
        # 5. Obter novos pesos
        new_weights = ml_service.weights.to_dict()
        
        # 6. Calcular mudanças nos pesos
        weight_changes = {}
        for key in new_weights:
            old_value = old_weights.get(key, 0.0)
            new_value = new_weights[key]
            change = new_value - old_value
            weight_changes[key] = {
                "old": old_value,
                "new": new_value,
                "change": change,
                "change_percent": (change / old_value * 100) if old_value > 0 else 0
            }
        
        # 7. Log das mudanças significativas
        significant_changes = {
            k: v for k, v in weight_changes.items() 
            if abs(v["change_percent"]) > 5.0  # Mudanças > 5%
        }
        
        if significant_changes:
            logger.info("📊 Mudanças significativas nos pesos:")
            for key, change in significant_changes.items():
                logger.info(
                    f"   {key}: {change['old']:.3f} → {change['new']:.3f} "
                    f"({change['change_percent']:+.1f}%)"
                )
        else:
            logger.info("📊 Pesos estáveis - mudanças menores que 5%")
        
        # 8. Métricas de performance
        performance_metrics = optimization_result.get("metrics", {})
        
        execution_time = (datetime.now() - start_time).total_seconds()
        
        # 9. Resultado final
        result = {
            "status": "success",
            "feedback_count": feedback_count,
            "training_samples": optimization_result.get("training_samples", 0),
            "epochs_completed": optimization_result.get("epochs", 0),
            "final_loss": optimization_result.get("final_loss", 0.0),
            "weight_changes": weight_changes,
            "significant_changes_count": len(significant_changes),
            "performance_metrics": performance_metrics,
            "execution_time_seconds": execution_time,
            "timestamp": datetime.now().isoformat()
        }
        
        logger.info(
            f"🎉 Retreino concluído em {execution_time:.1f}s - "
            f"{optimization_result.get('epochs', 0)} epochs, "
            f"loss final: {optimization_result.get('final_loss', 0.0):.6f}"
        )
        
        return result


@shared_task(name="partnership_retrain.generate_performance_report")
def generate_performance_report(days_back: int = 30) -> Dict[str, Any]:
    """
    Gera relatório de performance do algoritmo de parcerias.
    
    Args:
        days_back: Período para análise de performance
    
    Returns:
        Dict com métricas de performance
    """
    
    logger.info(f"📊 Gerando relatório de performance de parcerias ({days_back} dias)")
    
    try:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        result = loop.run_until_complete(
            _generate_performance_report(days_back)
        )
        
        logger.info(f"✅ Relatório de performance gerado: {result}")
        return result
        
    except Exception as e:
        logger.error(f"❌ Erro ao gerar relatório: {e}")
        raise
    finally:
        loop.close()


async def _generate_performance_report(days_back: int) -> Dict[str, Any]:
    """Gera relatório detalhado de performance."""
    
    async with get_async_session() as db:
        ml_service = PartnershipMLService(db)
        
        # Coletar métricas de performance
        cutoff_date = datetime.now() - timedelta(days=days_back)
        
        # Query para métricas básicas
        metrics_query = """
        SELECT 
            COUNT(*) as total_recommendations,
            COUNT(CASE WHEN feedback_type = 'accepted' THEN 1 END) as accepted_count,
            COUNT(CASE WHEN feedback_type = 'contacted' THEN 1 END) as contacted_count,
            COUNT(CASE WHEN feedback_type = 'rejected' THEN 1 END) as rejected_count,
            AVG(feedback_score) as avg_feedback_score,
            AVG(interaction_time_seconds) as avg_interaction_time
        FROM partnership_feedback 
        WHERE timestamp >= :cutoff_date
        """
        
        result = await db.execute(
            text(metrics_query), 
            {"cutoff_date": cutoff_date}
        )
        metrics_row = result.fetchone()
        
        if metrics_row:
            total = metrics_row.total_recommendations or 0
            accepted = metrics_row.accepted_count or 0
            contacted = metrics_row.contacted_count or 0
            rejected = metrics_row.rejected_count or 0
            
            # Calcular taxas
            acceptance_rate = (accepted / total * 100) if total > 0 else 0
            contact_rate = (contacted / total * 100) if total > 0 else 0
            rejection_rate = (rejected / total * 100) if total > 0 else 0
            
            performance_report = {
                "period_days": days_back,
                "total_recommendations": total,
                "acceptance_rate_percent": round(acceptance_rate, 2),
                "contact_rate_percent": round(contact_rate, 2),
                "rejection_rate_percent": round(rejection_rate, 2),
                "avg_feedback_score": round(metrics_row.avg_feedback_score or 0, 3),
                "avg_interaction_time_seconds": round(metrics_row.avg_interaction_time or 0, 1),
                "current_weights": ml_service.weights.to_dict() if ml_service.weights else {},
                "report_generated_at": datetime.now().isoformat()
            }
        else:
            performance_report = {
                "period_days": days_back,
                "total_recommendations": 0,
                "message": "Nenhum dado de feedback encontrado para o período",
                "report_generated_at": datetime.now().isoformat()
            }
        
        return performance_report


@shared_task(name="partnership_retrain.validate_model_health")  
def validate_model_health() -> Dict[str, Any]:
    """
    Valida a saúde do modelo de parcerias.
    Verifica pesos, performance recente e alertas.
    """
    
    logger.info("🔍 Validando saúde do modelo de parcerias")
    
    try:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        result = loop.run_until_complete(_validate_model_health())
        
        logger.info(f"✅ Validação de saúde concluída: {result}")
        return result
        
    except Exception as e:
        logger.error(f"❌ Erro na validação: {e}")
        raise
    finally:
        loop.close()


async def _validate_model_health() -> Dict[str, Any]:
    """Executa validação de saúde do modelo."""
    
    async with get_async_session() as db:
        ml_service = PartnershipMLService(db)
        
        health_status = {
            "model_loaded": ml_service.weights is not None,
            "weights_valid": False,
            "recent_activity": False,
            "performance_healthy": False,
            "alerts": [],
            "timestamp": datetime.now().isoformat()
        }
        
        # Verificar pesos
        if ml_service.weights:
            weights_dict = ml_service.weights.to_dict()
            weights_sum = sum(weights_dict.values())
            
            # Validar se pesos somam aproximadamente 1.0
            if 0.95 <= weights_sum <= 1.05:
                health_status["weights_valid"] = True
            else:
                health_status["alerts"].append(
                    f"Pesos não somam 1.0: {weights_sum:.3f}"
                )
            
            # Verificar se há pesos negativos ou muito altos
            for key, value in weights_dict.items():
                if value < 0:
                    health_status["alerts"].append(f"Peso negativo: {key} = {value}")
                elif value > 0.8:
                    health_status["alerts"].append(f"Peso muito alto: {key} = {value}")
        else:
            health_status["alerts"].append("Modelo não carregado")
        
        # Verificar atividade recente (últimos 7 dias)
        recent_feedback_query = """
        SELECT COUNT(*) as recent_count
        FROM partnership_feedback 
        WHERE timestamp >= :cutoff_date
        """
        
        cutoff_date = datetime.now() - timedelta(days=7)
        result = await db.execute(
            text(recent_feedback_query),
            {"cutoff_date": cutoff_date}
        )
        recent_count = result.scalar() or 0
        
        if recent_count > 10:  # Pelo menos 10 feedbacks por semana
            health_status["recent_activity"] = True
        else:
            health_status["alerts"].append(
                f"Pouca atividade recente: {recent_count} feedbacks em 7 dias"
            )
        
        # Score geral de saúde
        health_checks = [
            health_status["model_loaded"],
            health_status["weights_valid"], 
            health_status["recent_activity"]
        ]
        
        health_score = sum(health_checks) / len(health_checks)
        health_status["health_score"] = round(health_score, 2)
        
        if health_score >= 0.8:
            health_status["overall_status"] = "healthy"
        elif health_score >= 0.5:
            health_status["overall_status"] = "warning"
        else:
            health_status["overall_status"] = "critical"
        
        return health_status


@shared_task(name="partnership_retrain.quick_weights_update_task")
def quick_weights_update_task(
    min_feedback_count: int = 20,
    max_time_minutes: int = 15
) -> Dict[str, Any]:
    """
    Task de atualização rápida de pesos - execução diária.
    
    Aplica apenas ajustes incrementais aos pesos baseado no feedback recente,
    sem retreino completo do modelo.
    
    Args:
        min_feedback_count: Mínimo de feedbacks para executar atualização
        max_time_minutes: Tempo máximo de execução
    
    Returns:
        Dict com status da atualização e métricas
    """
    
    start_time = datetime.now()
    
    try:
        logger.info("🔄 Iniciando atualização rápida de pesos - Partnership ML")
        
        # Incrementar contador
        job_executions_total.labels(
            job_name="partnership_quick_update",
            status="started"
        ).inc()
        
        async def _execute_quick_update():
            """Execução assíncrona da atualização rápida"""
            
            async with get_async_session() as session:
                try:
                    # Inicializar serviço ML
                    ml_service = PartnershipMLService()
                    
                    # Coletar feedback dos últimos 2 dias apenas
                    training_data = await ml_service.collect_training_data(days_back=2)
                    
                    if len(training_data) < min_feedback_count:
                        logger.info(f"📊 Feedback insuficiente para atualização rápida: {len(training_data)} < {min_feedback_count}")
                        return {
                            "status": "skipped",
                            "reason": "insufficient_feedback",
                            "feedback_count": len(training_data),
                            "execution_time_seconds": (datetime.now() - start_time).total_seconds()
                        }
                    
                    logger.info(f"📊 Coletados {len(training_data)} feedbacks para atualização rápida")
                    
                    # Aplicar ajuste incremental de pesos (gradiente descent limitado)
                    optimization_result = await ml_service.optimize_weights_from_feedback(
                        min_feedback_count=min_feedback_count,
                        max_iterations=10,  # Limitado para execução rápida
                        learning_rate=0.001  # Learning rate menor para ajustes suaves
                    )
                    
                    # Log resultado
                    duration = (datetime.now() - start_time).total_seconds()
                    
                    logger.info(f"✅ Atualização rápida concluída em {duration:.1f}s")
                    logger.info(f"   Feedback processado: {len(training_data)}")
                    logger.info(f"   Loss improvement: {optimization_result.get('loss_improvement', 0):.4f}")
                    
                    # Incrementar contador de sucesso
                    job_executions_total.labels(
                        job_name="partnership_quick_update", 
                        status="success"
                    ).inc()
                    
                    return {
                        "status": "success",
                        "feedback_count": len(training_data),
                        "loss_improvement": optimization_result.get("loss_improvement", 0),
                        "weights_updated": optimization_result.get("weights_updated", False),
                        "execution_time_seconds": duration,
                        "next_full_retrain": "Domingo ou Quarta-feira"
                    }
                    
                except Exception as e:
                    logger.error(f"❌ Erro na atualização rápida: {e}")
                    raise
        
        # Executar atualização assíncrona
        result = asyncio.run(_execute_quick_update())
        
        return result
        
    except Exception as e:
        duration = (datetime.now() - start_time).total_seconds()
        
        logger.error(f"❌ Erro na atualização rápida de pesos: {e}")
        
        # Incrementar contador de erro
        job_executions_total.labels(
            job_name="partnership_quick_update",
            status="error"
        ).inc()
        
        return {
            "status": "error",
            "error": str(e),
            "execution_time_seconds": duration
        }
        
    finally:
        duration = (datetime.now() - start_time).total_seconds()
        logger.info(f"⏱️  Atualização rápida finalizada em {duration:.1f}s")


# Função de teste para execução manual
async def test_partnership_retrain():
    """Função para testar o retreino manualmente."""
    
    print("🧪 Teste manual do retreino de parcerias")
    
    result = await _execute_partnership_retrain(
        days_back=30,
        min_feedback_count=10,  # Baixo para teste
        force_retrain=True
    )
    
    print(f"📊 Resultado: {result}")
    return result


if __name__ == "__main__":
    # Teste local
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        asyncio.run(test_partnership_retrain())
    else:
        print("Para testar: python partnership_retrain.py test") 