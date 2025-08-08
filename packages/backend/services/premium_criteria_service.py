from typing import List, Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import or_

from models.premium_criteria import PremiumCriteria

# Import opcional do cliente Supabase
try:
    from config import get_supabase_client  # type: ignore
except Exception:
    get_supabase_client = None  # type: ignore


def _canonical_area(area: str) -> str:
    """Normalizes area names to a canonical format."""
    return area.lower().strip().replace(" ", "_")


def _matches_rule(case_data: Dict[str, Any], rule: PremiumCriteria) -> bool:
    """Checks if a specific case matches the criteria of a premium rule."""
    # Check case value
    valor_causa = case_data.get("valor_causa")
    if valor_causa is not None:
        if rule.min_valor_causa is not None and valor_causa < rule.min_valor_causa:
            return False
        if rule.max_valor_causa is not None and valor_causa > rule.max_valor_causa:
            return False

    # Check urgency
    urgency_h = case_data.get("prazo_resposta_h", case_data.get("urgency_h"))
    if urgency_h is not None and rule.min_urgency_h is not None:
        if urgency_h > rule.min_urgency_h:  # Less urgent than the minimum
            return False

    # Check complexity
    complexity = case_data.get("complexity")
    if complexity and rule.complexity_levels:
        if complexity not in rule.complexity_levels:
            return False

    # Check client's VIP plan
    client_plan = case_data.get("cliente_plan")
    if client_plan and rule.vip_client_plans:
        if client_plan not in rule.vip_client_plans:
            return False

    return True


async def get_client_plan_from_db(client_id: str) -> str:
    """Fetch client plan from Supabase profiles table (optional in tests)."""
    if get_supabase_client is None:
        return "FREE"
    try:
        supabase = get_supabase_client()
        result = supabase.rpc('get_client_plan', {'client_user_id': client_id}).execute()
        if result.data:
            return result.data
        else:
            profile_result = supabase.table('profiles').select('plan').eq('user_id', client_id).single().execute()
            if profile_result.data:
                return profile_result.data.get('plan', 'FREE')
        return 'FREE'
    except Exception as e:
        # If any error occurs, default to FREE
        print(f"Error fetching client plan for {client_id}: {e}")
        return 'FREE'


async def evaluate_case_premium(
    case_data: Dict[str, Any], 
    db: AsyncSession,
    client_id: Optional[str] = None
) -> tuple[bool, Optional[PremiumCriteria]]:
    """
    Evaluates if a case should be marked as premium.
    """
    area = _canonical_area(case_data.get("area", ""))
    subarea = _canonical_area(case_data.get("subarea", ""))

    # Fetch client plan from database if client_id provided
    if client_id and "cliente_plan" not in case_data:
        client_plan = await get_client_plan_from_db(client_id)
        case_data["cliente_plan"] = client_plan

    # Query premium criteria from database
    query = (
        select(PremiumCriteria)
        .where(PremiumCriteria.enabled == True)
        .where(PremiumCriteria.service_code == area)
        .where(
            or_(
                PremiumCriteria.subservice_code.is_(None),
                PremiumCriteria.subservice_code == subarea,
            )
        )
        .order_by(PremiumCriteria.subservice_code.desc())  # Specific rules first
    )
    
    result = await db.execute(query)
    applicable_rules = result.scalars().all()
    
    # Check each rule in order of specificity
    for rule in applicable_rules:
        if _matches_rule(case_data, rule):
            return True, rule

    return False, None


async def classify_case_premium(
    case_data: Dict[str, Any],
    db: AsyncSession,
    client_id: Optional[str] = None
) -> Dict[str, Any]:
    """
    Main function to classify a case as premium and return enriched data.
    """
    is_premium, matching_rule = await evaluate_case_premium(case_data, db, client_id)
    
    result = {
        "is_premium": is_premium,
        "cliente_plan": case_data.get("cliente_plan", "FREE"),
        "premium_rule_id": matching_rule.id if matching_rule else None,
        "premium_rule_name": matching_rule.name if matching_rule else None,
    }
    
    # Add premium metadata if applicable
    if matching_rule:
        result.update({
            "premium_criteria": {
                "service_code": matching_rule.service_code,
                "subservice_code": matching_rule.subservice_code,
                "name": matching_rule.name,
                "min_valor_causa": matching_rule.min_valor_causa,
                "max_valor_causa": matching_rule.max_valor_causa,
                "min_urgency_h": matching_rule.min_urgency_h,
                "complexity_levels": matching_rule.complexity_levels,
                "vip_client_plans": matching_rule.vip_client_plans,
            }
        })
    
    return result 