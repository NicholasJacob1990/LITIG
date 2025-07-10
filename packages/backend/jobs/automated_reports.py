"""
Jobs do Celery para geração e envio de relatórios automatizados.
Executa relatórios semanais e mensais conforme agendamento.
"""
import logging
import os
from datetime import datetime

from celery import shared_task

from backend.metrics import job_executions_total
from backend.services.automated_reports import automated_reports_service

logger = logging.getLogger(__name__)


@shared_task(name="generate_weekly_report")
def generate_weekly_report():
    """
    Job para gerar e enviar relatório semanal.
    Configurado para executar toda segunda-feira às 9h.
    """
    logger.info("Iniciando job de relatório semanal")

    try:
        # Executar geração do relatório
        import asyncio
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        result = loop.run_until_complete(
            automated_reports_service.generate_weekly_report()
        )

        # Registrar métrica de sucesso
        job_executions_total.labels(
            job_name="generate_weekly_report",
            status="success"
        ).inc()

        logger.info(f"Relatório semanal gerado com sucesso: {result}")
        return result

    except Exception as e:
        # Registrar métrica de falha
        job_executions_total.labels(
            job_name="generate_weekly_report",
            status="failure"
        ).inc()

        logger.error(f"Erro ao gerar relatório semanal: {e}")
        raise
    finally:
        loop.close()


@shared_task(name="generate_monthly_report")
def generate_monthly_report():
    """
    Job para gerar e envio relatório mensal.
    Configurado para executar no primeiro dia de cada mês às 10h.
    """
    logger.info("Iniciando job de relatório mensal")

    try:
        # Executar geração do relatório
        import asyncio
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        result = loop.run_until_complete(
            automated_reports_service.generate_monthly_report()
        )

        # Registrar métrica de sucesso
        job_executions_total.labels(
            job_name="generate_monthly_report",
            status="success"
        ).inc()

        logger.info(f"Relatório mensal gerado com sucesso: {result}")
        return result

    except Exception as e:
        # Registrar métrica de falha
        job_executions_total.labels(
            job_name="generate_monthly_report",
            status="failure"
        ).inc()

        logger.error(f"Erro ao gerar relatório mensal: {e}")
        raise
    finally:
        loop.close()


@shared_task(name="test_report_generation")
def test_report_generation(report_type="weekly"):
    """
    Job de teste para gerar relatório sob demanda.
    Útil para validar a funcionalidade sem esperar o agendamento.

    Args:
        report_type: "weekly" ou "monthly"
    """
    logger.info(f"Testando geração de relatório {report_type}")

    try:
        import asyncio
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        if report_type == "monthly":
            result = loop.run_until_complete(
                automated_reports_service.generate_monthly_report()
            )
        else:
            result = loop.run_until_complete(
                automated_reports_service.generate_weekly_report()
            )

        logger.info(f"Teste de relatório {report_type} concluído: {result}")
        return result

    except Exception as e:
        logger.error(f"Erro no teste de relatório {report_type}: {e}")
        raise
    finally:
        loop.close()
