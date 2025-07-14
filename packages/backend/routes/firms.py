"""
backend/routes/firms.py

Rotas da API para gerenciar escritórios de advocacia e seus KPIs.
Feature-E: Firm Reputation - Sistema B2B Matching
"""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import List, Optional
from uuid import UUID

from services.firm_service import (
    firm_service,
    LawFirm, LawFirmCreate, LawFirmUpdate,
    FirmKPI, FirmKPICreate, FirmKPIUpdate,
    FirmStats
)
from auth import (
    get_current_user_with_role,
    require_admin_role,
    require_lawyer_or_admin_role,
    require_office_or_admin_role,
    require_platform_associate_or_admin_role,
    require_any_authenticated_user,
    FirmAccessScopes,
    get_user_firm_scopes,
    sanitize_firm_data,
    sanitize_firm_kpis
)

router = APIRouter(
    prefix="/firms",
    tags=["Law Firms"],
    responses={404: {"description": "Not found"}},
)

# --- Endpoints para Escritórios ---

@router.post("/", response_model=LawFirm, status_code=status.HTTP_201_CREATED)
async def create_firm(
    firm_data: LawFirmCreate,
    current_user: dict = Depends(require_admin_role)
):
    """
    Criar um novo escritório de advocacia.
    
    Requer permissões de administrador. Apenas administradores podem criar escritórios.
    """
    try:
        return await firm_service.create_firm(firm_data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

@router.get("/", response_model=List[LawFirm])
async def list_firms(
    limit: int = Query(50, ge=1, le=100, description="Número máximo de resultados"),
    offset: int = Query(0, ge=0, description="Número de registros para pular"),
    include_kpis: bool = Query(True, description="Incluir KPIs dos escritórios"),
    include_lawyers_count: bool = Query(True, description="Incluir contagem de advogados"),
    min_success_rate: Optional[float] = Query(None, ge=0.0, le=1.0, description="Taxa mínima de sucesso"),
    min_team_size: Optional[int] = Query(None, ge=1, description="Tamanho mínimo da equipe"),
    current_user: dict = Depends(require_any_authenticated_user)
):
    """
    Listar escritórios com filtros opcionais.
    
    Permite filtrar por taxa de sucesso mínima e tamanho da equipe.
    Aplica sanitização de dados baseada no role do usuário.
    """
    try:
        # Obter dados dos escritórios
        firms = await firm_service.list_firms(
            limit=limit,
            offset=offset,
            include_kpis=include_kpis,
            include_lawyers_count=include_lawyers_count,
            min_success_rate=min_success_rate,
            min_team_size=min_team_size
        )
        
        # Aplicar sanitização baseada no role do usuário
        user_role = current_user.get("role", "client")
        user_scopes = get_user_firm_scopes(user_role)
        
        sanitized_firms = []
        for firm in firms:
            firm_dict = firm.dict() if hasattr(firm, 'dict') else firm
            sanitized_firm = sanitize_firm_data(firm_dict, user_scopes)
            sanitized_firms.append(sanitized_firm)
        
        return sanitized_firms
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

@router.get("/stats", response_model=FirmStats)
async def get_firm_statistics(
    current_user: dict = Depends(require_any_authenticated_user)
):
    """
    Obter estatísticas agregadas dos escritórios.
    
    Retorna métricas como número total de escritórios, advogados associados,
    médias de KPIs e top performers.
    """
    try:
        return await firm_service.get_firm_stats()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

@router.get("/{firm_id}", response_model=LawFirm)
async def get_firm(
    firm_id: UUID,
    include_kpis: bool = Query(True, description="Incluir KPIs do escritório"),
    include_lawyers_count: bool = Query(True, description="Incluir contagem de advogados"),
    current_user: dict = Depends(require_any_authenticated_user)
):
    """
    Buscar escritório por ID.
    
    Retorna detalhes completos do escritório, incluindo KPIs e contagem de advogados.
    Aplica sanitização baseada no role do usuário.
    """
    try:
        firm = await firm_service.get_firm(
            firm_id, 
            include_kpis=include_kpis,
            include_lawyers_count=include_lawyers_count
        )
        if not firm:
            raise HTTPException(status_code=404, detail="Escritório não encontrado")
        
        # Aplicar sanitização baseada no role do usuário
        user_role = current_user.get("role", "client")
        user_scopes = get_user_firm_scopes(user_role)
        
        firm_dict = firm.dict() if hasattr(firm, 'dict') else firm.__dict__
        sanitized_firm = sanitize_firm_data(firm_dict, user_scopes)
        
        return sanitized_firm
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

@router.put("/{firm_id}", response_model=LawFirm)
async def update_firm(
    firm_id: UUID,
    firm_data: LawFirmUpdate,
    current_user: dict = Depends(require_office_or_admin_role)
):
    """
    Atualizar dados do escritório.
    
    Permite atualizar nome, tamanho da equipe e localização.
    Todos os campos são opcionais.
    Requer permissões de escritório ou administrador.
    """
    try:
        firm = await firm_service.update_firm(firm_id, firm_data)
        if not firm:
            raise HTTPException(status_code=404, detail="Escritório não encontrado")
        return firm
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

@router.delete("/{firm_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_firm(
    firm_id: UUID,
    current_user: dict = Depends(require_admin_role)
):
    """
    Deletar escritório.
    
    Remove o escritório e desassocia todos os advogados vinculados.
    Os advogados não são deletados, apenas têm o firm_id definido como NULL.
    Requer permissões de administrador.
    """
    try:
        success = await firm_service.delete_firm(firm_id)
        if not success:
            raise HTTPException(status_code=404, detail="Escritório não encontrado")
        return None
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

# --- Endpoints para KPIs ---

@router.put("/{firm_id}/kpis", response_model=FirmKPI)
async def update_firm_kpis(
    firm_id: UUID,
    kpi_data: FirmKPIUpdate,
    current_user: dict = Depends(require_office_or_admin_role)
):
    """
    Atualizar ou criar KPIs do escritório.
    
    Se os KPIs não existirem, todos os campos são obrigatórios para criação.
    Se já existirem, os campos são opcionais para atualização parcial.
    Requer permissões de escritório ou administrador.
    
    KPIs incluem:
    - success_rate: Taxa de sucesso (0-1)
    - nps: Net Promoter Score (-1 a 1)
    - reputation_score: Score de reputação (0-1)
    - diversity_index: Índice de diversidade (0-1)
    - active_cases: Número de casos ativos
    """
    try:
        kpis = await firm_service.update_firm_kpis(firm_id, kpi_data)
        if not kpis:
            raise HTTPException(status_code=404, detail="Escritório não encontrado")
        return kpis
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

@router.post("/{firm_id}/kpis", response_model=FirmKPI, status_code=status.HTTP_201_CREATED)
async def create_firm_kpis(
    firm_id: UUID,
    kpi_data: FirmKPICreate,
    current_user: dict = Depends(require_office_or_admin_role)
):
    """
    Criar KPIs para um escritório.
    
    Todos os campos são obrigatórios para criação inicial.
    Se os KPIs já existirem, retorna erro 409 (Conflict).
    Requer permissões de escritório ou administrador.
    """
    try:
        # Verificar se escritório existe
        firm = await firm_service.get_firm(firm_id, include_kpis=True, include_lawyers_count=False)
        if not firm:
            raise HTTPException(status_code=404, detail="Escritório não encontrado")
        
        # Verificar se KPIs já existem
        if hasattr(firm, 'kpis') and firm.kpis:
            raise HTTPException(
                status_code=409, 
                detail="KPIs já existem para este escritório. Use PUT para atualizar."
            )
        
        # Converter para FirmKPIUpdate com todos os campos
        kpi_update = FirmKPIUpdate(
            success_rate=kpi_data.success_rate,
            nps=kpi_data.nps,
            reputation_score=kpi_data.reputation_score,
            diversity_index=kpi_data.diversity_index,
            active_cases=kpi_data.active_cases
        )
        
        return await firm_service.update_firm_kpis(firm_id, kpi_update)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

@router.get("/{firm_id}/kpis", response_model=FirmKPI)
async def get_firm_kpis(
    firm_id: UUID,
    current_user: dict = Depends(require_any_authenticated_user)
):
    """
    Buscar KPIs específicos de um escritório.
    
    Retorna apenas os KPIs sem outros dados do escritório.
    Aplica sanitização baseada no role do usuário.
    """
    try:
        firm = await firm_service.get_firm(firm_id, include_kpis=True, include_lawyers_count=False)
        if not firm:
            raise HTTPException(status_code=404, detail="Escritório não encontrado")
        
        if not hasattr(firm, 'kpis') or not firm.kpis:
            raise HTTPException(status_code=404, detail="KPIs não encontrados para este escritório")
        
        # Aplicar sanitização baseada no role do usuário
        user_role = current_user.get("role", "client")
        user_scopes = get_user_firm_scopes(user_role)
        
        kpis_dict = firm.kpis.dict() if hasattr(firm.kpis, 'dict') else firm.kpis.__dict__
        sanitized_kpis = sanitize_firm_kpis(kpis_dict, user_scopes)
        
        return sanitized_kpis
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

# --- Endpoints para Advogados do Escritório ---

@router.get("/{firm_id}/lawyers")
async def get_firm_lawyers(
    firm_id: UUID,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(require_any_authenticated_user)
):
    """
    Listar advogados de um escritório específico.
    
    Retorna todos os advogados associados ao escritório.
    """
    try:
        # Verificar se escritório existe
        firm = await firm_service.get_firm(firm_id, include_kpis=False, include_lawyers_count=False)
        if not firm:
            raise HTTPException(status_code=404, detail="Escritório não encontrado")
        
        # Buscar advogados do escritório diretamente no banco
        from services.firm_service import firm_service as fs
        
        with fs._get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT id, name, oab_number, primary_area, specialties, 
                           rating, is_available, created_at
                    FROM lawyers 
                    WHERE firm_id = %s
                    ORDER BY name
                    LIMIT %s OFFSET %s
                """, (firm_id, limit, offset))
                
                lawyers = []
                for row in cur.fetchall():
                    lawyers.append({
                        'id': str(row[0]) if row[0] else None,
                        'name': row[1] if row[1] else None,
                        'oab_number': row[2] if row[2] else None,
                        'primary_area': row[3] if row[3] else None,
                        'specialties': row[4] if row[4] else None,
                        'rating': float(row[5]) if row[5] else None,
                        'is_available': row[6] if row[6] else None,
                        'created_at': row[7].isoformat() if row[7] else None
                    })
                
                return {
                    'firm_id': str(firm_id),
                    'firm_name': firm.name if hasattr(firm, 'name') else 'N/A',
                    'lawyers': lawyers,
                    'total_count': len(lawyers),
                    'limit': limit,
                    'offset': offset
                }
        
    except HTTPException:
        raise
    except Exception as e: