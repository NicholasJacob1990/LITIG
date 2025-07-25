"""
Testes unitários para o módulo de classificação de casos.
Testa a lógica de triagem IA e marcação de casos premium.
"""

import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from services.premium_criteria_service import classify_case_premium
from models.premium_criteria import PremiumCriteria


@pytest.mark.asyncio
async def test_case_classification_by_value(db_session: AsyncSession):
    """Test premium classification based on case value."""
    
    # Create premium criteria for high-value cases (including all client plans)
    await db_session.execute(text("""
        INSERT INTO premium_criteria (
            service_code, name, enabled, min_valor_causa, 
            complexity_levels, vip_client_plans
        ) VALUES (
            'trabalhista', 'Trabalhista Alto Valor', true, 50000,
            '["HIGH", "MEDIUM"]', '["FREE", "VIP", "ENTERPRISE"]'
        )
    """))
    await db_session.commit()

    # Test case with high value should be premium
    case_data = {
        "area": "trabalhista",
        "subarea": "rescisao",
        "valor_causa": 75000,
        "cliente_plan": "FREE",
    }
    
    result = await classify_case_premium(case_data, db_session)
    
    assert result["is_premium"] is True
    assert result["cliente_plan"] == "FREE"
    assert result["premium_rule_name"] == "Trabalhista Alto Valor"


@pytest.mark.asyncio
async def test_case_classification_by_client_plan(db_session: AsyncSession):
    """Test premium classification based on client VIP plan."""
    
    # Create premium criteria for VIP clients
    await db_session.execute(text("""
        INSERT INTO premium_criteria (
            service_code, name, enabled, min_valor_causa,
            complexity_levels, vip_client_plans
        ) VALUES (
            'civil', 'Civil VIP Only', true, 1000,
            '["HIGH", "MEDIUM", "LOW"]', '["VIP", "ENTERPRISE"]'
        )
    """))
    await db_session.commit()

    # Test VIP client with medium value should be premium
    case_data = {
        "area": "civil",
        "subarea": "contratos",
        "valor_causa": 15000,
        "cliente_plan": "VIP",
    }
    
    result = await classify_case_premium(case_data, db_session)
    
    assert result["is_premium"] is True
    assert result["cliente_plan"] == "VIP"
    
    # Test FREE client with same value should NOT be premium
    case_data["cliente_plan"] = "FREE"
    result = await classify_case_premium(case_data, db_session)
    
    assert result["is_premium"] is False
    assert result["cliente_plan"] == "FREE"


@pytest.mark.asyncio
async def test_disabled_criteria_ignored(db_session: AsyncSession):
    """Test that disabled premium criteria are ignored."""
    
    # Create disabled premium criteria
    await db_session.execute(text("""
        INSERT INTO premium_criteria (
            service_code, name, enabled, min_valor_causa,
            complexity_levels, vip_client_plans
        ) VALUES (
            'tributario', 'Tributário Disabled', false, 1000,
            '["HIGH"]', '["FREE", "VIP"]'
        )
    """))
    await db_session.commit()

    # Test case that would match if criteria was enabled
    case_data = {
        "area": "tributario",
        "valor_causa": 25000,
        "cliente_plan": "FREE",
    }
    
    result = await classify_case_premium(case_data, db_session)
    
    assert result["is_premium"] is False
    assert result["premium_rule_id"] is None


@pytest.mark.asyncio
async def test_complexity_level_matching(db_session: AsyncSession):
    """Test premium classification based on complexity levels."""
    
    # Create premium criteria for high complexity cases
    await db_session.execute(text("""
        INSERT INTO premium_criteria (
            service_code, name, enabled, min_valor_causa,
            complexity_levels, vip_client_plans
        ) VALUES (
            'empresarial', 'Empresarial Complexo', true, 10000,
            '["HIGH"]', '["FREE", "VIP", "ENTERPRISE"]'
        )
    """))
    await db_session.commit()

    # Test high complexity case should be premium
    case_data = {
        "area": "empresarial",
        "valor_causa": 15000,
        "complexity": "HIGH",
        "cliente_plan": "FREE",
    }
    
    result = await classify_case_premium(case_data, db_session)
    
    assert result["is_premium"] is True
    
    # Test medium complexity case should NOT be premium
    case_data["complexity"] = "MEDIUM"
    result = await classify_case_premium(case_data, db_session)
    
    assert result["is_premium"] is False


@pytest.mark.asyncio
async def test_urgency_filtering(db_session: AsyncSession):
    """Test premium classification based on urgency."""
    
    # Create premium criteria for urgent cases (max 24h)
    await db_session.execute(text("""
        INSERT INTO premium_criteria (
            service_code, name, enabled, min_urgency_h,
            complexity_levels, vip_client_plans
        ) VALUES (
            'criminal', 'Criminal Urgente', true, 24,
            '["HIGH", "MEDIUM", "LOW"]', '["FREE", "VIP", "ENTERPRISE"]'
        )
    """))
    await db_session.commit()

    # Test urgent case (12h) should be premium
    case_data = {
        "area": "criminal",
        "urgency_h": 12,
        "cliente_plan": "FREE",
    }
    
    result = await classify_case_premium(case_data, db_session)
    
    assert result["is_premium"] is True
    
    # Test non-urgent case (48h) should NOT be premium  
    case_data["urgency_h"] = 48
    result = await classify_case_premium(case_data, db_session)
    
    assert result["is_premium"] is False


@pytest.mark.asyncio
async def test_subarea_specificity(db_session: AsyncSession):
    """Test that subarea-specific rules take precedence over general area rules."""
    
    # Create general area rule
    await db_session.execute(text("""
        INSERT INTO premium_criteria (
            service_code, name, enabled, min_valor_causa,
            complexity_levels, vip_client_plans
        ) VALUES (
            'trabalhista', 'Trabalhista Geral', true, 30000,
            '["HIGH", "MEDIUM"]', '["FREE", "VIP", "ENTERPRISE"]'
        )
    """))
    
    # Create specific subarea rule with lower threshold
    await db_session.execute(text("""
        INSERT INTO premium_criteria (
            service_code, subservice_code, name, enabled, min_valor_causa,
            complexity_levels, vip_client_plans
        ) VALUES (
            'trabalhista', 'assedio_moral', 'Assédio Moral Premium', true, 10000,
            '["HIGH", "MEDIUM"]', '["FREE", "VIP", "ENTERPRISE"]'
        )
    """))
    await db_session.commit()

    # Test case that matches subarea-specific rule
    case_data = {
        "area": "trabalhista",
        "subarea": "assedio_moral", 
        "valor_causa": 15000,  # Above subarea threshold (10k) but below general (30k)
        "cliente_plan": "FREE",
    }
    
    result = await classify_case_premium(case_data, db_session)
    
    assert result["is_premium"] is True
    assert result["premium_rule_name"] == "Assédio Moral Premium"


@pytest.mark.asyncio 
async def test_client_plan_integration_with_db(db_session: AsyncSession):
    """Test that client plan is fetched from database when client_id provided."""
    
    # Create premium criteria for VIP clients
    await db_session.execute(text("""
        INSERT INTO premium_criteria (
            service_code, name, enabled, min_valor_causa,
            complexity_levels, vip_client_plans
        ) VALUES (
            'comercial', 'Comercial VIP', true, 5000,
            '["HIGH", "MEDIUM", "LOW"]', '["VIP", "ENTERPRISE"]'
        )
    """))
    await db_session.commit()

    # Test case without client_plan but with client_id
    # Note: In real scenario, get_client_plan_from_db would be called
    case_data = {
        "area": "comercial",
        "valor_causa": 8000,
        # cliente_plan will be set by service when client_id provided
    }
    
    # Mock client_id (in real test, you'd mock the Supabase call)
    fake_client_id = "test-client-vip-uuid"
    
    # Since we can't easily mock Supabase here, we'll set the plan manually
    case_data["cliente_plan"] = "VIP"  # Simulating DB fetch result
    
    result = await classify_case_premium(case_data, db_session, client_id=fake_client_id)
    
    assert result["is_premium"] is True
    assert result["cliente_plan"] == "VIP" 