"""
Rotas para validação de planos e funcionalidades.
Demonstra a implementação da restrição de Unipile messaging por tipo de usuário.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional, Dict, List
from ..dependencies import get_db, get_current_user
from ..services.plan_validation_service import PlanValidationService
from ..services.user_type_migration_service import UserTypeMigrationService
from ..schemas.user_types import EntityType, ClientType

router = APIRouter(prefix="/api/v1/plan-validation", tags=["Plan Validation"])

@router.get("/check-feature/{feature}")
async def check_feature_access(
    feature: str,
    entity_type: str = Query(..., description="Tipo de entidade do usuário"),
    plan: str = Query(..., description="Plano atual do usuário"),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Verifica se o usuário pode acessar uma funcionalidade específica.
    
    Features suportadas:
    - unipile_messaging: Envio de mensagens via Unipile SDK
    - advanced_search: Busca avançada com IA
    - hybrid_search: Busca híbrida interna + externa
    - priority_support: Suporte prioritário
    - multi_user: Múltiplos usuários (PJ)
    """
    try:
        validation_service = PlanValidationService()
        
        # Obter metadados do usuário para casos de migração
        user_metadata = current_user.get("user_metadata", {})
        
        # Validar acesso à funcionalidade
        result = validation_service.validate_feature_access(
            feature=feature,
            entity_type=entity_type,
            plan=plan,
            user_metadata=user_metadata
        )
        
        if result["allowed"]:
            return {
                "status": "allowed",
                "feature": feature,
                "entity_type": entity_type,
                "plan": plan,
                "message": f"Acesso liberado para {feature}"
            }
        else:
            return {
                "status": "restricted",
                "feature": feature,
                "entity_type": entity_type,
                "plan": plan,
                "reason": result["reason"],
                "suggested_plan": result["suggested_plan"],
                "upgrade_required": True
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro na validação: {str(e)}")

@router.get("/unipile-messaging/status")
async def check_unipile_messaging_status(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Verifica especificamente o status do Unipile messaging para o usuário atual.
    """
    try:
        validation_service = PlanValidationService()
        
        # Obter dados do usuário atual
        entity_type = current_user.get("user_metadata", {}).get("entity_type", "client")
        plan = current_user.get("subscription", {}).get("plan", "free")
        user_metadata = current_user.get("user_metadata", {})
        
        # Verificar acesso ao Unipile
        can_use_unipile = validation_service.can_use_unipile_messaging(
            entity_type=entity_type,
            plan=plan,
            user_metadata=user_metadata
        )
        
        if can_use_unipile:
            return {
                "unipile_enabled": True,
                "message": "Unipile messaging disponível",
                "features": [
                    "Envio automático de e-mails",
                    "Integração com LinkedIn",
                    "Mensagens via WhatsApp Business",
                    "Sincronização de contatos"
                ]
            }
        else:
            result = validation_service.validate_feature_access(
                "unipile_messaging", entity_type, plan, user_metadata
            )
            return {
                "unipile_enabled": False,
                "reason": result.get("reason", "Funcionalidade não disponível no seu plano"),
                "suggested_plan": result.get("suggested_plan"),
                "current_plan": plan,
                "entity_type": entity_type,
                "upgrade_benefits": [
                    "Comunicação automática com advogados",
                    "Maior taxa de resposta",
                    "Economia de tempo",
                    "Integração completa"
                ]
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro na verificação: {str(e)}")

@router.get("/plans/comparison")
async def get_plan_comparison(
    entity_type: str = Query(..., description="Tipo de entidade"),
    current_user: dict = Depends(get_current_user)
):
    """
    Retorna comparação de planos para o tipo de entidade específico.
    """
    try:
        validation_service = PlanValidationService()
        
        # Obter comparação de funcionalidades
        comparison = validation_service.get_feature_comparison(entity_type)
        
        if not comparison:
            # Retornar comparação básica se não houver específica
            return {
                "entity_type": entity_type,
                "message": "Comparação detalhada não disponível",
                "general_benefits": {
                    "free": ["Funcionalidades básicas", "Suporte limitado"],
                    "paid": ["Unipile messaging", "Busca avançada", "Suporte prioritário"]
                }
            }
        
        return {
            "entity_type": entity_type,
            "comparison": comparison,
            "recommendation": validation_service._get_suggested_plan(entity_type)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro na comparação: {str(e)}")

@router.post("/migrate-user-type")
async def migrate_user_type(
    target_type: str = Query(..., description="Tipo de destino para migração"),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Migra o tipo de usuário (usado para corrigir inconsistências).
    Exemplo: lawyer_office -> firm
    """
    try:
        migration_service = UserTypeMigrationService(db)
        
        current_type = current_user.get("user_metadata", {}).get("entity_type", "client")
        user_metadata = current_user.get("user_metadata", {})
        
        # Executar migração
        new_type, updated_metadata = migration_service.migrate_entity_type(
            current_type, user_metadata
        )
        
        return {
            "migration_executed": True,
            "old_type": current_type,
            "new_type": new_type,
            "updated_metadata": updated_metadata,
            "message": f"Usuário migrado de {current_type} para {new_type}",
            "next_steps": [
                "Verificar se o plano atual é compatível",
                "Atualizar funcionalidades disponíveis",
                "Notificar usuário sobre mudanças"
            ]
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro na migração: {str(e)}")

@router.get("/user-limits")
async def get_user_limits(
    current_user: dict = Depends(get_current_user)
):
    """
    Retorna os limites específicos do usuário baseados no seu tipo e plano.
    """
    try:
        validation_service = PlanValidationService()
        
        entity_type = current_user.get("user_metadata", {}).get("entity_type", "client")
        plan = current_user.get("subscription", {}).get("plan", "free")
        
        return {
            "entity_type": entity_type,
            "plan": plan,
            "limits": {
                "max_cases": validation_service.get_max_cases_limit(entity_type, plan),
                "max_partnerships": validation_service.get_max_partnerships_limit(entity_type, plan),
                "client_invitations": validation_service.get_client_invitations_limit(entity_type, plan),
            },
            "features": {
                "unipile_messaging": validation_service.can_use_unipile_messaging(entity_type, plan),
                "advanced_search": validation_service.can_use_advanced_search(entity_type, plan),
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao obter limites: {str(e)}")

@router.get("/entity-types")
async def list_entity_types():
    """
    Lista todos os tipos de entidade suportados pelo sistema.
    """
    return {
        "entity_types": {
            EntityType.CLIENT_PF: "Cliente Pessoa Física",
            EntityType.CLIENT_PJ: "Cliente Pessoa Jurídica",
            EntityType.LAWYER_INDIVIDUAL: "Advogado Individual",
            EntityType.LAWYER_FIRM_MEMBER: "Advogado Associado a Escritório",
            EntityType.FIRM: "Escritório de Advocacia",
            EntityType.SUPER_ASSOCIATE: "Super Associado"
        },
        "client_types": {
            ClientType.PF: "Pessoa Física",
            ClientType.PJ: "Pessoa Jurídica"
        },
        "migration_mappings": {
            "client": "client_pf (padrão para migração)",
            "lawyer": "lawyer_individual", 
            "lawyer_office": "firm (CORREÇÃO)",
            "lawyer_associated": "lawyer_firm_member (CORREÇÃO)",
            "firm": "firm"
        }
    } 