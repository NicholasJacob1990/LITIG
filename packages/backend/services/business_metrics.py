"""
Serviço de métricas de negócio para relatórios e análises.
Calcula conversões, performance por área e métricas de advogados.
"""
import logging
import os
from datetime import datetime, timedelta
from typing import Any, Dict, List

import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

logger = logging.getLogger(__name__)


def get_db_connection():
    """Cria e retorna uma conexão com o banco de dados."""
    try:
        conn = psycopg2.connect(DATABASE_URL)
        return conn
    except psycopg2.OperationalError as e:
        logger.error(f"Erro de conexão com o banco de dados: {e}")
        raise


class BusinessMetricsService:
    """Serviço para cálculo de métricas de negócio."""

    async def _execute_query(self, query: str, params: tuple = ()
                             ) -> List[Dict[str, Any]]:
        """Executa uma query e retorna os resultados como uma lista de dicionários."""
        conn = None
        try:
            conn = get_db_connection()
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute(query, params)
                results = cur.fetchall()
                return [dict(row) for row in results] if results else []
        except Exception as e:
            logger.error(f"Erro ao executar query: {e}")
            return []
        finally:
            if conn:
                conn.close()

    async def calculate_conversion_metrics(
        self, period_days: int = 30) -> Dict[str, Any]:
        """Calcula métricas de conversão do funil."""
        start_date = (datetime.now() - timedelta(days=period_days)).isoformat()

        try:
            total_cases_result = await self._execute_query(
                "SELECT COUNT(id) as count FROM cases WHERE created_at >= %s", (start_date,)
            )
            total_cases = total_cases_result[0]['count'] if total_cases_result else 0

            cases_with_offers_result = await self._execute_query(
                "SELECT COUNT(DISTINCT case_id) as count FROM offers WHERE created_at >= %s", (start_date,)
            )
            cases_with_offers = cases_with_offers_result[0]['count'] if cases_with_offers_result else 0

            accepted_offers_result = await self._execute_query(
                "SELECT COUNT(id) as count FROM offers WHERE status = 'interested' AND created_at >= %s", (start_date,)
            )
            offers_accepted = accepted_offers_result[0]['count'] if accepted_offers_result else 0

            contracts_signed_result = await self._execute_query(
                "SELECT COUNT(id) as count FROM contracts WHERE status = 'signed' AND created_at >= %s", (start_date,)
            )
            contracts_signed = contracts_signed_result[0]['count'] if contracts_signed_result else 0

            offer_rate = cases_with_offers / total_cases if total_cases > 0 else 0
            acceptance_rate = offers_accepted / cases_with_offers if cases_with_offers > 0 else 0
            signing_rate = contracts_signed / offers_accepted if offers_accepted > 0 else 0
            overall_conversion = contracts_signed / total_cases if total_cases > 0 else 0

            return {
                'period_days': period_days,
                'period_start': start_date,
                'total_cases': total_cases,
                'cases_with_offers': cases_with_offers,
                'offers_accepted': offers_accepted,
                'contracts_signed': contracts_signed,
                'offer_rate': round(offer_rate, 3),
                'acceptance_rate': round(acceptance_rate, 3),
                'signing_rate': round(signing_rate, 3),
                'overall_conversion': round(overall_conversion, 3)
            }
        except Exception as e:
            logger.error(f"Erro ao calcular métricas de conversão: {e}")
            return {'period_days': period_days, 'error': str(e)}

    async def analyze_by_legal_area(self, period_days: int = 30) -> Dict[str, Any]:
        """Análise segmentada por área jurídica."""
        conn = None
        try:
            conn = get_db_connection()
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                start_date = (datetime.now() - timedelta(days=period_days)).isoformat()

                query = """
                SELECT
                    c.area,
                    COUNT(DISTINCT c.id) as total_cases,
                    COUNT(DISTINCT o.id) as total_offers,
                    COUNT(DISTINCT CASE WHEN o.status = 'interested' THEN o.id END) as accepted_offers,
                    COUNT(DISTINCT ct.id) as signed_contracts,
                    AVG(r.rating) as avg_rating,
                    AVG(EXTRACT(EPOCH FROM (o.updated_at - o.created_at))/3600) as avg_response_time_hours
                FROM cases c
                LEFT JOIN offers o ON c.id = o.case_id
                LEFT JOIN contracts ct ON c.id = ct.case_id
                LEFT JOIN reviews r ON ct.id = r.contract_id
                WHERE c.created_at >= %s
                GROUP BY c.area
                ORDER BY total_cases DESC
                """

                cur.execute(query, (start_date,))
                results = cur.fetchall()

                return {
                    'period_days': period_days,
                    'areas': [dict(row) for row in results] if results else []
                }

        except Exception as e:
            logger.error(f"Erro ao analisar por área jurídica: {e}")
            return {
                'period_days': period_days,
                'areas': []
            }
        finally:
            if conn:
                conn.close()

    async def calculate_lawyer_performance(
        self, period_days: int = 30) -> Dict[str, Any]:
        """Métricas de performance dos advogados."""
        conn = None
        try:
            conn = get_db_connection()
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                start_date = (datetime.now() - timedelta(days=period_days)).isoformat()

                query = """
                SELECT
                    l.id,
                    l.nome as name,
                    COUNT(DISTINCT o.id) as offers_received,
                    COUNT(DISTINCT CASE WHEN o.status = 'interested' THEN o.id END) as offers_accepted,
                    COUNT(DISTINCT ct.id) as contracts_signed,
                    AVG(r.rating) as avg_rating,
                    AVG(EXTRACT(EPOCH FROM (o.updated_at - o.created_at))/3600) as avg_response_time_hours,
                    SUM(ct.value) as total_revenue
                FROM lawyers l
                LEFT JOIN offers o ON l.id = o.lawyer_id AND o.created_at >= %s
                LEFT JOIN contracts ct ON l.id = ct.lawyer_id AND ct.created_at >= %s
                LEFT JOIN reviews r ON ct.id = r.contract_id
                WHERE l.status = 'active'
                GROUP BY l.id, l.nome
                HAVING COUNT(DISTINCT o.id) > 0
                ORDER BY contracts_signed DESC, avg_rating DESC
                LIMIT 50
                """

                cur.execute(query, (start_date, start_date))
                results = cur.fetchall()

                return {
                    'period_days': period_days,
                    'lawyers': [dict(row) for row in results] if results else []
                }

        except Exception as e:
            logger.error(f"Erro ao calcular performance dos advogados: {e}")
            return {
                'period_days': period_days,
                'lawyers': []
            }
        finally:
            if conn:
                conn.close()

    async def calculate_system_health(self) -> Dict[str, Any]:
        """Calcula métricas de saúde do sistema."""
        now = datetime.now()
        hour_ago = (now - timedelta(hours=1)).isoformat()
        day_ago = (now - timedelta(days=1)).isoformat()

        try:
            recent_cases_result = await self._execute_query(
                "SELECT COUNT(id) as count FROM cases WHERE created_at >= %s", (hour_ago,)
            )
            recent_cases = recent_cases_result[0]['count'] if recent_cases_result else 0

            recent_offers_result = await self._execute_query(
                "SELECT COUNT(id) as count FROM offers WHERE created_at >= %s", (hour_ago,)
            )
            recent_offers = recent_offers_result[0]['count'] if recent_offers_result else 0

            expiring_offers_result = await self._execute_query(
                "SELECT COUNT(id) as count FROM offers WHERE status = 'pending' AND expires_at <= %s",
                (now.isoformat(),)
            )
            expiring_offers = expiring_offers_result[0]['count'] if expiring_offers_result else 0

            active_lawyers_result = await self._execute_query(
                "SELECT COUNT(id) as count FROM lawyers WHERE status = 'active'"
            )
            active_lawyers = active_lawyers_result[0]['count'] if active_lawyers_result else 0

            day_offers_result = await self._execute_query(
                "SELECT status FROM offers WHERE created_at >= %s", (day_ago,)
            )
            responded = sum(1 for o in day_offers_result if o['status'] != 'pending')
            response_rate = responded / \
                len(day_offers_result) if day_offers_result else 0

            return {
                'timestamp': now.isoformat(),
                'cases_last_hour': recent_cases,
                'offers_last_hour': recent_offers,
                'expiring_offers': expiring_offers,
                'active_lawyers': active_lawyers,
                'response_rate_24h': round(response_rate, 3),
                'health_score': min(100, int(response_rate * 100)),
                'recent_activity': {
                    'cases_last_hour': recent_cases,
                    'offers_last_hour': recent_offers
                },
                'response_times': {
                    'avg_24h': 0  # Placeholder
                }
            }
        except Exception as e:
            logger.error(f"Erro ao calcular saúde do sistema: {e}")
            return {
                'timestamp': now.isoformat(),
                'error': str(e),
                'recent_activity': {
                    'cases_last_hour': 0,
                    'offers_last_hour': 0
                },
                'expiring_offers': 0,
                'active_lawyers': 0,
                'response_times': {}
            }


# Instância global do serviço
business_metrics = BusinessMetricsService()
