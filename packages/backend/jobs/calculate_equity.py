#!/usr/bin/env python3
"""
Job para calcular métricas de equidade para todos os advogados.
Executa diariamente às 2:00 AM para manter os campos atualizados:
- cases_30d: casos dos últimos 30 dias
- capacidade_mensal: capacidade baseada no perfil do advogado
"""
import asyncio
import logging
import os
from datetime import datetime, timedelta
from typing import Any, Dict

from dotenv import load_dotenv

from supabase import Client, create_client

# Configuração
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)


def get_supabase_client() -> Client:
    """Retorna cliente Supabase configurado."""
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


def calculate_monthly_capacity(lawyer: Dict[str, Any]) -> int:
    """
    Calcula capacidade mensal baseada no perfil do advogado.

    Fatores considerados:
    - Experiência (anos)
    - Tipo de atuação (individual, escritório pequeno, grande)
    - Especialização
    - Histórico de casos
    """
    base_capacity = 10  # Capacidade base

    # Ajuste por experiência
    years_experience = lawyer.get("anos_experiencia", 0)
    if years_experience > 10:
        base_capacity += 5
    elif years_experience > 5:
        base_capacity += 3
    elif years_experience > 2:
        base_capacity += 1

    # Ajuste por tipo de atuação
    firm_type = lawyer.get("tipo_atuacao", "individual")
    if firm_type == "escritorio_grande":
        base_capacity += 10
    elif firm_type == "escritorio_medio":
        base_capacity += 5
    elif firm_type == "escritorio_pequeno":
        base_capacity += 2

    # Ajuste por performance histórica
    success_rate = lawyer.get("success_rate", 0.5)
    if success_rate > 0.8:
        base_capacity += 3
    elif success_rate > 0.6:
        base_capacity += 1

    # Limite máximo e mínimo
    return max(5, min(base_capacity, 30))


async def calculate_equity_metrics():
    """Calcula métricas de equidade para todos os advogados ativos."""
    logger.info("=== INICIANDO CÁLCULO DE MÉTRICAS DE EQUIDADE ===")
    start_time = datetime.utcnow()

    try:
        supabase = get_supabase_client()

        # Buscar todos os advogados ativos
        lawyers_response = supabase.table("lawyers").select("*").execute()
        lawyers = lawyers_response.data

        logger.info(f"Processando {len(lawyers)} advogados...")

        # Data limite para casos dos últimos 30 dias
        thirty_days_ago = (datetime.now() - timedelta(days=30)).isoformat()

        updated_count = 0
        error_count = 0

        for lawyer in lawyers:
            try:
                # Contar casos dos últimos 30 dias
                # Busca em contracts (casos confirmados) e offers (casos oferecidos)
                contracts_response = supabase.table("contracts")\
                    .select("id", count="exact")\
                    .eq("lawyer_id", lawyer["id"])\
                    .gte("created_at", thirty_days_ago)\
                    .execute()

                offers_response = supabase.table("offers")\
                    .select("id", count="exact")\
                    .eq("lawyer_id", lawyer["id"])\
                    .eq("status", "interested")\
                    .gte("created_at", thirty_days_ago)\
                    .execute()

                cases_30d = contracts_response.count + offers_response.count

                # Calcular capacidade mensal
                capacidade_mensal = calculate_monthly_capacity(lawyer)

                # Preparar dados para atualização
                update_data = {
                    "cases_30d": cases_30d,
                    "capacidade_mensal": capacidade_mensal,
                    "equity_updated_at": datetime.utcnow().isoformat()
                }

                # Se o advogado tem KPI, atualizar também
                if lawyer.get("kpi"):
                    kpi = lawyer["kpi"]
                    kpi["cases_30d"] = cases_30d
                    kpi["capacidade_mensal"] = capacidade_mensal
                    update_data["kpi"] = kpi

                # Atualizar advogado
                supabase.table("lawyers").update(
                    update_data).eq("id", lawyer["id"]).execute()

                logger.debug(
                    f"Advogado {lawyer['id']}: cases_30d={cases_30d}, capacidade={capacidade_mensal}")
                updated_count += 1

            except Exception as e:
                logger.error(f"Erro ao processar advogado {lawyer['id']}: {e}")
                error_count += 1

        # Estatísticas finais
        duration = (datetime.utcnow() - start_time).total_seconds()
        logger.info(f"Cálculo concluído em {duration:.2f} segundos")
        logger.info(f"Advogados atualizados: {updated_count}")
        logger.info(f"Erros: {error_count}")
        logger.info("=== FIM DO CÁLCULO DE EQUIDADE ===")

        return {
            "updated": updated_count,
            "errors": error_count,
            "duration": duration
        }

    except Exception as e:
        logger.error(f"Erro crítico no cálculo de equidade: {e}")
        raise


# Tarefa Celery para agendamento automático
try:
    from backend.celery_app import celery_app

    @celery_app.task(name='backend.jobs.calculate_equity.calculate_equity_task')
    def calculate_equity_task():
        """Tarefa Celery que executa o cálculo de equidade"""
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        try:
            result = loop.run_until_complete(calculate_equity_metrics())
            return {
                'status': 'success',
                'result': result
            }
        except Exception as e:
            logger.error(f"Erro na tarefa Celery: {e}")
            return {
                'status': 'error',
                'error': str(e)
            }
        finally:
            loop.close()

except ImportError:
    # Se não conseguir importar Celery, continua funcionando como script standalone
    pass


if __name__ == "__main__":
    # Executar como script standalone
    asyncio.run(calculate_equity_metrics())
