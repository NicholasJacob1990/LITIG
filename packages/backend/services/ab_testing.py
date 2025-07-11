"""
Serviço de A/B Testing para validação de modelos LTR.
Implementa distribuição de tráfego, coleta de métricas e rollback automático.
"""

import asyncio
import json
import logging
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Dict, List, Optional, Tuple

import numpy as np

from ..config import get_settings
from ..metrics import (
    ab_test_conversions_total,
    ab_test_exposure_total,
    ab_test_performance_gauge,
    model_performance_gauge,
)
from supabase import Client, create_client

settings = get_settings()
logger = logging.getLogger(__name__)


class TestStatus(Enum):
    ACTIVE = "active"
    PAUSED = "paused"
    COMPLETED = "completed"
    ROLLED_BACK = "rolled_back"


@dataclass
class ABTestConfig:
    """Configuração de um teste A/B"""
    test_id: str
    name: str
    description: str
    control_model: str  # Modelo de controle (atual)
    treatment_model: str  # Modelo de tratamento (novo)
    traffic_split: float  # % de tráfego para tratamento (0.0-1.0)
    start_date: datetime
    end_date: datetime
    min_sample_size: int
    significance_level: float  # Nível de significância (ex: 0.05)
    success_metric: str  # Métrica principal (ex: "conversion_rate")
    status: TestStatus
    created_at: datetime
    updated_at: datetime


@dataclass
class ABTestResult:
    """Resultado de um teste A/B"""
    test_id: str
    control_conversions: int
    control_exposures: int
    treatment_conversions: int
    treatment_exposures: int
    control_rate: float
    treatment_rate: float
    lift: float  # % de melhoria
    p_value: float
    is_significant: bool
    confidence_interval: Tuple[float, float]
    recommendation: str


class ABTestingService:
    """Serviço para gerenciar testes A/B de modelos LTR"""

    def __init__(self):
        self.supabase: Client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY
        )
        self.current_tests: Dict[str, ABTestConfig] = {}
        self.load_active_tests()

    def load_active_tests(self) -> None:
        """Carrega testes ativos do banco de dados"""
        try:
            response = self.supabase.table("ab_tests").select(
                "*").eq("status", "active").execute()

            for test_data in response.data:
                config = ABTestConfig(
                    test_id=test_data["test_id"],
                    name=test_data["name"],
                    description=test_data["description"],
                    control_model=test_data["control_model"],
                    treatment_model=test_data["treatment_model"],
                    traffic_split=test_data["traffic_split"],
                    start_date=datetime.fromisoformat(test_data["start_date"]),
                    end_date=datetime.fromisoformat(test_data["end_date"]),
                    min_sample_size=test_data["min_sample_size"],
                    significance_level=test_data["significance_level"],
                    success_metric=test_data["success_metric"],
                    status=TestStatus(test_data["status"]),
                    created_at=datetime.fromisoformat(test_data["created_at"]),
                    updated_at=datetime.fromisoformat(test_data["updated_at"])
                )
                self.current_tests[config.test_id] = config

            logger.info(f"Carregados {len(self.current_tests)} testes A/B ativos")

        except Exception as e:
            logger.error(f"Erro ao carregar testes A/B: {e}")

    def create_test(self, config: ABTestConfig) -> bool:
        """Cria um novo teste A/B"""
        try:
            # Inserir no banco
            test_data = asdict(config)
            test_data["start_date"] = config.start_date.isoformat()
            test_data["end_date"] = config.end_date.isoformat()
            test_data["created_at"] = config.created_at.isoformat()
            test_data["updated_at"] = config.updated_at.isoformat()
            test_data["status"] = config.status.value

            self.supabase.table("ab_tests").insert(test_data).execute()

            # Adicionar ao cache local
            self.current_tests[config.test_id] = config

            logger.info(f"Teste A/B criado: {config.test_id}")
            return True

        except Exception as e:
            logger.error(f"Erro ao criar teste A/B: {e}")
            return False

    def get_model_for_request(
            self, user_id: str, test_id: Optional[str] = None) -> Tuple[str, str, Optional[str]]:
        """
        Determina qual modelo usar para uma requisição específica.
        Retorna: (modelo_a_usar, grupo_teste, test_id)
        """
        # Se não há teste especificado, usar o primeiro teste ativo
        if test_id is None:
            active_tests = [
                t for t in self.current_tests.values() if t.status == TestStatus.ACTIVE]
            if not active_tests:
                return "production", "control", None
            test_config = active_tests[0]
        else:
            test_config = self.current_tests.get(test_id)
            if not test_config or test_config.status != TestStatus.ACTIVE:
                return "production", "control", None

        # Verificar se o teste está no período ativo
        now = datetime.now()
        if now < test_config.start_date or now > test_config.end_date:
            return test_config.control_model, "control", test_config.test_id

        # Determinar grupo baseado no hash do user_id
        user_hash = hash(f"{user_id}_{test_config.test_id}") % 100
        threshold = int(test_config.traffic_split * 100)

        if user_hash < threshold:
            # Usuário no grupo de tratamento
            ab_test_exposure_total.labels(
                test_id=test_config.test_id,
                group="treatment"
            ).inc()
            return test_config.treatment_model, "treatment", test_config.test_id
        else:
            # Usuário no grupo de controle
            ab_test_exposure_total.labels(
                test_id=test_config.test_id,
                group="control"
            ).inc()
            return test_config.control_model, "control", test_config.test_id

    def record_conversion(self, user_id: str, test_id: str,
                          group: str, converted: bool = True) -> None:
        """Registra uma conversão para o teste A/B"""
        try:
            # Registrar métrica
            if converted:
                ab_test_conversions_total.labels(
                    test_id=test_id,
                    group=group
                ).inc()

            # Salvar no banco para análise posterior
            conversion_data = {
                "test_id": test_id,
                "user_id": user_id,
                "group": group,
                "converted": converted,
                "timestamp": datetime.now().isoformat()
            }

            self.supabase.table("ab_test_conversions").insert(conversion_data).execute()

        except Exception as e:
            logger.error(f"Erro ao registrar conversão: {e}")

    def analyze_test_results(self, test_id: str) -> Optional[ABTestResult]:
        """Analisa os resultados de um teste A/B"""
        try:
            # Buscar dados de conversão
            response = self.supabase.table("ab_test_conversions").select(
                "*").eq("test_id", test_id).execute()

            control_conversions = 0
            control_exposures = 0
            treatment_conversions = 0
            treatment_exposures = 0

            for record in response.data:
                if record["group"] == "control":
                    control_exposures += 1
                    if record["converted"]:
                        control_conversions += 1
                elif record["group"] == "treatment":
                    treatment_exposures += 1
                    if record["converted"]:
                        treatment_conversions += 1

            # Calcular taxas de conversão
            control_rate = control_conversions / control_exposures if control_exposures > 0 else 0
            treatment_rate = treatment_conversions / \
                treatment_exposures if treatment_exposures > 0 else 0

            # Calcular lift
            lift = ((treatment_rate - control_rate) /
                    control_rate * 100) if control_rate > 0 else 0

            # Teste de significância (teste Z para proporções)
            p_value, is_significant, confidence_interval = self._statistical_test(
                control_conversions, control_exposures,
                treatment_conversions, treatment_exposures
            )

            # Gerar recomendação
            recommendation = self._generate_recommendation(
                is_significant, lift, control_rate, treatment_rate
            )

            result = ABTestResult(
                test_id=test_id,
                control_conversions=control_conversions,
                control_exposures=control_exposures,
                treatment_conversions=treatment_conversions,
                treatment_exposures=treatment_exposures,
                control_rate=control_rate,
                treatment_rate=treatment_rate,
                lift=lift,
                p_value=p_value,
                is_significant=is_significant,
                confidence_interval=confidence_interval,
                recommendation=recommendation
            )

            # Atualizar métricas
            ab_test_performance_gauge.labels(
                test_id=test_id,
                group="control"
            ).set(control_rate)

            ab_test_performance_gauge.labels(
                test_id=test_id,
                group="treatment"
            ).set(treatment_rate)

            return result

        except Exception as e:
            logger.error(f"Erro ao analisar resultados do teste: {e}")
            return None

    def _statistical_test(self, c_conv: int, c_exp: int, t_conv: int,
                          t_exp: int) -> Tuple[float, bool, Tuple[float, float]]:
        """Realiza teste estatístico de significância"""
        if c_exp == 0 or t_exp == 0:
            return 1.0, False, (0.0, 0.0)

        p1 = c_conv / c_exp
        p2 = t_conv / t_exp

        # Pooled proportion
        p_pool = (c_conv + t_conv) / (c_exp + t_exp)

        # Standard error
        se = np.sqrt(p_pool * (1 - p_pool) * (1 / c_exp + 1 / t_exp))

        if se == 0:
            return 1.0, False, (0.0, 0.0)

        # Z-score
        z = (p2 - p1) / se

        # P-value (two-tailed)
        p_value = 2 * (1 - self._norm_cdf(abs(z)))

        # Significância
        is_significant = p_value < 0.05

        # Intervalo de confiança
        diff = p2 - p1
        margin_error = 1.96 * se  # 95% confidence
        confidence_interval = (diff - margin_error, diff + margin_error)

        return p_value, is_significant, confidence_interval

    def _norm_cdf(self, x: float) -> float:
        """Aproximação da função CDF da distribuição normal"""
        return 0.5 * (1 + np.tanh(x * np.sqrt(2 / np.pi)))

    def _generate_recommendation(
            self, is_significant: bool, lift: float, control_rate: float, treatment_rate: float) -> str:
        """Gera recomendação baseada nos resultados"""
        if not is_significant:
            return "Não há diferença estatisticamente significativa. Continue o teste ou implemente o modelo com mais dados."

        if lift > 5:  # Melhoria > 5%
            return f"Recomendado: Implementar modelo de tratamento. Melhoria de {lift:.1f}% é significativa."
        elif lift < -5:  # Piora > 5%
            return f"Recomendado: Manter modelo de controle. Modelo de tratamento piora {abs(lift):.1f}%."
        else:
            return "Diferença significativa mas pequena. Considere outros fatores além da métrica principal."

    def should_rollback(self, test_id: str) -> bool:
        """Verifica se um teste deve ser revertido automaticamente"""
        result = self.analyze_test_results(test_id)
        if not result:
            return False

        # Critérios para rollback automático
        min_sample_size = 100  # Tamanho mínimo da amostra
        max_degradation = -10  # Máxima degradação permitida (%)

        # Verificar se há amostra suficiente
        if result.treatment_exposures < min_sample_size:
            return False

        # Verificar se há degradação significativa
        if result.is_significant and result.lift < max_degradation:
            logger.warning(
                f"Rollback automático ativado para teste {test_id}: degradação de {result.lift:.1f}%")
            return True

        return False

    def rollback_test(self, test_id: str) -> bool:
        """Reverte um teste A/B"""
        try:
            # Atualizar status no banco
            self.supabase.table("ab_tests").update({
                "status": "rolled_back",
                "updated_at": datetime.now().isoformat()
            }).eq("test_id", test_id).execute()

            # Atualizar cache local
            if test_id in self.current_tests:
                self.current_tests[test_id].status = TestStatus.ROLLED_BACK
                self.current_tests[test_id].updated_at = datetime.now()

            logger.info(f"Teste A/B revertido: {test_id}")
            return True

        except Exception as e:
            logger.error(f"Erro ao reverter teste A/B: {e}")
            return False

    def get_active_tests(self) -> List[ABTestConfig]:
        """Retorna lista de testes ativos"""
        return [test for test in self.current_tests.values() if test.status ==
                TestStatus.ACTIVE]

    def pause_test(self, test_id: str) -> bool:
        """Pausa um teste A/B"""
        try:
            self.supabase.table("ab_tests").update({
                "status": "paused",
                "updated_at": datetime.now().isoformat()
            }).eq("test_id", test_id).execute()

            if test_id in self.current_tests:
                self.current_tests[test_id].status = TestStatus.PAUSED
                self.current_tests[test_id].updated_at = datetime.now()

            logger.info(f"Teste A/B pausado: {test_id}")
            return True

        except Exception as e:
            logger.error(f"Erro ao pausar teste A/B: {e}")
            return False


# Instância global
ab_testing_service = ABTestingService()
