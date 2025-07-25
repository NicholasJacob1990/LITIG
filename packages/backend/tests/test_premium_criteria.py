import pytest
from unittest.mock import MagicMock

# Importar as funções e "db" mockada
from ..services.premium_criteria_service import evaluate_case_premium
from ..api.admin_premium import fake_criteria_db
from .. import models

@pytest.fixture(autouse=True)
def clear_fake_db():
    """Limpa o 'banco de dados' em memória antes de cada teste."""
    fake_criteria_db.clear()
    yield
    fake_criteria_db.clear()

def test_classify_premium_rule_match_specific():
    """Testa se uma regra específica (área + subárea) é aplicada corretamente."""
    # Adicionar uma regra ao nosso DB fake
    fake_criteria_db.append(models.PremiumCriteria(
        id=1, name="Tributário Alto Valor", service_code="tributario",
        subservice_code="imposto_de_renda", enabled=True, min_valor_causa=100000
    ))

    # Caso que deve bater com a regra
    case_data = {
        "area": "Tributário", "subarea": "Imposto de Renda", "valor_causa": 150000
    }
    
    is_premium, rule = evaluate_case_premium(case_data, db=MagicMock())
    
    assert is_premium is True
    assert rule is not None
    assert rule.id == 1

def test_classify_premium_rule_match_general():
    """Testa se uma regra geral (só área) é aplicada quando não há regra específica."""
    fake_criteria_db.append(models.PremiumCriteria(
        id=2, name="Civil Geral Urgente", service_code="civil",
        subservice_code=None, enabled=True, min_urgency_h=24
    ))
    
    case_data = {"area": "Civil", "subarea": "Divórcio", "prazo_resposta_h": 12}
    
    is_premium, rule = evaluate_case_premium(case_data, db=MagicMock())
    
    assert is_premium is True
    assert rule is not None
    assert rule.id == 2

def test_no_match_if_disabled():
    """Testa se uma regra desabilitada não classifica o caso como premium."""
    fake_criteria_db.append(models.PremiumCriteria(
        id=3, name="Regra Inativa", service_code="empresarial",
        enabled=False, min_valor_causa=1
    ))
    
    case_data = {"area": "Empresarial", "valor_causa": 1000}
    
    is_premium, rule = evaluate_case_premium(case_data, db=MagicMock())
    
    assert is_premium is False
    assert rule is None

def test_no_match_if_criteria_not_met():
    """Testa se o caso não é premium se os critérios não são atendidos."""
    fake_criteria_db.append(models.PremiumCriteria(
        id=4, name="Trabalhista Alto Valor", service_code="trabalhista",
        enabled=True, min_valor_causa=50000
    ))
    
    # Valor da causa é muito baixo
    case_data = {"area": "Trabalhista", "valor_causa": 10000}
    
    is_premium, rule = evaluate_case_premium(case_data, db=MagicMock())
    
    assert is_premium is False
    assert rule is None

def test_specificity_preference():
    """Testa se a regra mais específica (com subárea) tem preferência."""
    # Regra geral
    fake_criteria_db.append(models.PremiumCriteria(
        id=10, name="Criminal Geral", service_code="criminal", enabled=True
    ))
    # Regra específica
    fake_criteria_db.append(models.PremiumCriteria(
        id=11, name="Homicídio é Premium", service_code="criminal",
        subservice_code="homicidio", enabled=True, complexity_levels=["HIGH"]
    ))
    
    case_data = {"area": "Criminal", "subarea": "Homicídio", "complexity": "HIGH"}
    
    is_premium, rule = evaluate_case_premium(case_data, db=MagicMock())
    
    assert is_premium is True
    assert rule is not None
    assert rule.id == 11 # Deve preferir a regra 11 sobre a 10 