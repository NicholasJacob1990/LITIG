"""
backend/services/firm_service.py

Serviço para gerenciar escritórios de advocacia e seus KPIs.
Feature-E: Firm Reputation - Sistema B2B Matching
"""

import logging
from typing import List, Optional, Dict, Any
from uuid import UUID, uuid4
from datetime import datetime

import psycopg2
from psycopg2.extras import RealDictCursor
from pydantic import BaseModel, Field, validator

from config import get_database_url

logger = logging.getLogger(__name__)

# Modelos Pydantic para API
class FirmKPIBase(BaseModel):
    """Modelo base para KPIs de escritório"""
    success_rate: float = Field(..., ge=0.0, le=1.0, description="Taxa de sucesso (0-1)")
    nps: float = Field(..., ge=-1.0, le=1.0, description="Net Promoter Score (-1 a 1)")
    reputation_score: float = Field(..., ge=0.0, le=1.0, description="Score de reputação (0-1)")
    diversity_index: float = Field(..., ge=0.0, le=1.0, description="Índice de diversidade (0-1)")
    active_cases: int = Field(..., ge=0, description="Número de casos ativos")

class FirmKPICreate(FirmKPIBase):
    """Modelo para criação de KPIs"""
    pass

class FirmKPIUpdate(BaseModel):
    """Modelo para atualização de KPIs (campos opcionais)"""
    success_rate: Optional[float] = Field(None, ge=0.0, le=1.0)
    nps: Optional[float] = Field(None, ge=-1.0, le=1.0)
    reputation_score: Optional[float] = Field(None, ge=0.0, le=1.0)
    diversity_index: Optional[float] = Field(None, ge=0.0, le=1.0)
    active_cases: Optional[int] = Field(None, ge=0)

class FirmKPI(FirmKPIBase):
    """Modelo completo de KPI com metadados"""
    firm_id: UUID
    updated_at: datetime

class LawFirmBase(BaseModel):
    """Modelo base para escritório"""
    name: str = Field(..., min_length=2, max_length=255)
    team_size: int = Field(default=1, ge=1, le=1000)
    main_lat: Optional[float] = Field(None, ge=-90.0, le=90.0)
    main_lon: Optional[float] = Field(None, ge=-180.0, le=180.0)

class LawFirmCreate(LawFirmBase):
    """Modelo para criação de escritório"""
    pass

class LawFirmUpdate(BaseModel):
    """Modelo para atualização de escritório (campos opcionais)"""
    name: Optional[str] = Field(None, min_length=2, max_length=255)
    team_size: Optional[int] = Field(None, ge=1, le=1000)
    main_lat: Optional[float] = Field(None, ge=-90.0, le=90.0)
    main_lon: Optional[float] = Field(None, ge=-180.0, le=180.0)

class LawFirm(LawFirmBase):
    """Modelo completo de escritório"""
    id: UUID
    created_at: datetime
    updated_at: datetime
    kpis: Optional[FirmKPI] = None
    lawyers_count: Optional[int] = None

class FirmStats(BaseModel):
    """Estatísticas agregadas de escritórios"""
    total_firms: int
    total_lawyers_associated: int
    avg_success_rate: float
    avg_nps: float
    avg_reputation_score: float
    top_performing_firms: List[Dict[str, Any]]

class FirmService:
    """Serviço para gerenciar escritórios de advocacia"""
    
    def __init__(self):
        self.db_url = get_database_url()
    
    def _get_connection(self):
        """Obter conexão com o banco de dados"""
        return psycopg2.connect(self.db_url, cursor_factory=RealDictCursor)
    
    async def create_firm(self, firm_data: LawFirmCreate) -> LawFirm:
        """Criar um novo escritório"""
        firm_id = uuid4()
        
        with self._get_connection() as conn:
            with conn.cursor() as cur:
                # Verificar se já existe um escritório com o mesmo nome
                cur.execute("SELECT id FROM law_firms WHERE name = %s", (firm_data.name,))
                if cur.fetchone():
                    raise ValueError(f"Escritório com nome '{firm_data.name}' já existe")
                
                # Inserir escritório
                cur.execute("""
                    INSERT INTO law_firms (id, name, team_size, main_lat, main_lon)
                    VALUES (%s, %s, %s, %s, %s)
                    RETURNING id, name, team_size, main_lat, main_lon, created_at, updated_at
                """, (
                    firm_id, firm_data.name, firm_data.team_size,
                    firm_data.main_lat, firm_data.main_lon
                ))
                
                result = cur.fetchone()
                conn.commit()
                
                logger.info(f"Escritório criado: {firm_data.name} (ID: {firm_id})")
                
                return LawFirm(
                    id=result['id'],
                    name=result['name'],
                    team_size=result['team_size'],
                    main_lat=result['main_lat'],
                    main_lon=result['main_lon'],
                    created_at=result['created_at'],
                    updated_at=result['updated_at']
                )
    
    async def get_firm(self, firm_id: UUID, include_kpis: bool = True, include_lawyers_count: bool = True) -> Optional[LawFirm]:
        """Buscar escritório por ID"""
        with self._get_connection() as conn:
            with conn.cursor() as cur:
                # Query base
                query = """
                    SELECT lf.id, lf.name, lf.team_size, lf.main_lat, lf.main_lon,
                           lf.created_at, lf.updated_at
                """
                
                # Adicionar KPIs se solicitado
                if include_kpis:
                    query += """,
                           fk.success_rate, fk.nps, fk.reputation_score,
                           fk.diversity_index, fk.active_cases, fk.updated_at as kpis_updated_at
                    """
                
                # Adicionar contagem de advogados se solicitado
                if include_lawyers_count:
                    query += ", COUNT(l.id) as lawyers_count"
                
                query += " FROM law_firms lf"
                
                if include_kpis:
                    query += " LEFT JOIN firm_kpis fk ON fk.firm_id = lf.id"
                
                if include_lawyers_count:
                    query += " LEFT JOIN lawyers l ON l.firm_id = lf.id"
                
                query += " WHERE lf.id = %s"
                
                if include_lawyers_count:
                    query += " GROUP BY lf.id, lf.name, lf.team_size, lf.main_lat, lf.main_lon, lf.created_at, lf.updated_at"
                    if include_kpis:
                        query += ", fk.success_rate, fk.nps, fk.reputation_score, fk.diversity_index, fk.active_cases, fk.updated_at"
                
                cur.execute(query, (firm_id,))
                result = cur.fetchone()
                
                if not result:
                    return None
                
                # Construir objeto LawFirm
                firm_data = {
                    'id': result['id'],
                    'name': result['name'],
                    'team_size': result['team_size'],
                    'main_lat': result['main_lat'],
                    'main_lon': result['main_lon'],
                    'created_at': result['created_at'],
                    'updated_at': result['updated_at']
                }
                
                # Adicionar KPIs se disponíveis
                if include_kpis and result.get('success_rate') is not None:
                    firm_data['kpis'] = FirmKPI(
                        firm_id=result['id'],
                        success_rate=float(result['success_rate']),
                        nps=float(result['nps']),
                        reputation_score=float(result['reputation_score']),
                        diversity_index=float(result['diversity_index']),
                        active_cases=result['active_cases'],
                        updated_at=result['kpis_updated_at']
                    )
                
                # Adicionar contagem de advogados
                if include_lawyers_count:
                    firm_data['lawyers_count'] = result['lawyers_count'] or 0
                
                return LawFirm(**firm_data)
    
    async def list_firms(
        self, 
        limit: int = 50, 
        offset: int = 0,
        include_kpis: bool = True,
        include_lawyers_count: bool = True,
        min_success_rate: Optional[float] = None,
        min_team_size: Optional[int] = None
    ) -> List[LawFirm]:
        """Listar escritórios com filtros opcionais"""
        with self._get_connection() as conn:
            with conn.cursor() as cur:
                # Query base
                query = """
                    SELECT lf.id, lf.name, lf.team_size, lf.main_lat, lf.main_lon,
                           lf.created_at, lf.updated_at
                """
                
                if include_kpis:
                    query += """,
                           fk.success_rate, fk.nps, fk.reputation_score,
                           fk.diversity_index, fk.active_cases, fk.updated_at as kpis_updated_at
                    """
                
                if include_lawyers_count:
                    query += ", COUNT(l.id) as lawyers_count"
                
                query += " FROM law_firms lf"
                
                if include_kpis:
                    query += " LEFT JOIN firm_kpis fk ON fk.firm_id = lf.id"
                
                if include_lawyers_count:
                    query += " LEFT JOIN lawyers l ON l.firm_id = lf.id"
                
                # Filtros
                where_conditions = []
                params = []
                
                if min_success_rate is not None:
                    where_conditions.append("fk.success_rate >= %s")
                    params.append(min_success_rate)
                
                if min_team_size is not None:
                    where_conditions.append("lf.team_size >= %s")
                    params.append(min_team_size)
                
                if where_conditions:
                    query += " WHERE " + " AND ".join(where_conditions)
                
                if include_lawyers_count:
                    group_by = " GROUP BY lf.id, lf.name, lf.team_size, lf.main_lat, lf.main_lon, lf.created_at, lf.updated_at"
                    if include_kpis:
                        group_by += ", fk.success_rate, fk.nps, fk.reputation_score, fk.diversity_index, fk.active_cases, fk.updated_at"
                    query += group_by
                
                query += " ORDER BY lf.name LIMIT %s OFFSET %s"
                params.extend([limit, offset])
                
                cur.execute(query, params)
                results = cur.fetchall()
                
                firms = []
                for result in results:
                    firm_data = {
                        'id': result['id'],
                        'name': result['name'],
                        'team_size': result['team_size'],
                        'main_lat': result['main_lat'],
                        'main_lon': result['main_lon'],
                        'created_at': result['created_at'],
                        'updated_at': result['updated_at']
                    }
                    
                    if include_kpis and result.get('success_rate') is not None:
                        firm_data['kpis'] = FirmKPI(
                            firm_id=result['id'],
                            success_rate=float(result['success_rate']),
                            nps=float(result['nps']),
                            reputation_score=float(result['reputation_score']),
                            diversity_index=float(result['diversity_index']),
                            active_cases=result['active_cases'],
                            updated_at=result['kpis_updated_at']
                        )
                    
                    if include_lawyers_count:
                        firm_data['lawyers_count'] = result['lawyers_count'] or 0
                    
                    firms.append(LawFirm(**firm_data))
                
                return firms
    
    async def update_firm(self, firm_id: UUID, firm_data: LawFirmUpdate) -> Optional[LawFirm]:
        """Atualizar dados do escritório"""
        with self._get_connection() as conn:
            with conn.cursor() as cur:
                # Verificar se escritório existe
                cur.execute("SELECT id FROM law_firms WHERE id = %s", (firm_id,))
                if not cur.fetchone():
                    return None
                
                # Construir query de atualização dinâmica
                update_fields = []
                params = []
                
                if firm_data.name is not None:
                    # Verificar se o novo nome não está em uso
                    cur.execute("SELECT id FROM law_firms WHERE name = %s AND id != %s", 
                               (firm_data.name, firm_id))
                    if cur.fetchone():
                        raise ValueError(f"Escritório com nome '{firm_data.name}' já existe")
                    
                    update_fields.append("name = %s")
                    params.append(firm_data.name)
                
                if firm_data.team_size is not None:
                    update_fields.append("team_size = %s")
                    params.append(firm_data.team_size)
                
                if firm_data.main_lat is not None:
                    update_fields.append("main_lat = %s")
                    params.append(firm_data.main_lat)
                
                if firm_data.main_lon is not None:
                    update_fields.append("main_lon = %s")
                    params.append(firm_data.main_lon)
                
                if not update_fields:
                    # Nenhum campo para atualizar, retornar escritório atual
                    return await self.get_firm(firm_id)
                
                update_fields.append("updated_at = now()")
                params.append(firm_id)
                
                query = f"""
                    UPDATE law_firms 
                    SET {', '.join(update_fields)}
                    WHERE id = %s
                    RETURNING id, name, team_size, main_lat, main_lon, created_at, updated_at
                """
                
                cur.execute(query, params)
                result = cur.fetchone()
                conn.commit()
                
                logger.info(f"Escritório atualizado: {result['name']} (ID: {firm_id})")
                
                return await self.get_firm(firm_id)
    
    async def delete_firm(self, firm_id: UUID) -> bool:
        """Deletar escritório (e desassociar advogados)"""
        with self._get_connection() as conn:
            with conn.cursor() as cur:
                # Verificar se escritório existe
                cur.execute("SELECT id, name FROM law_firms WHERE id = %s", (firm_id,))
                firm = cur.fetchone()
                if not firm:
                    return False
                
                # Desassociar advogados (firm_id = NULL)
                cur.execute("UPDATE lawyers SET firm_id = NULL WHERE firm_id = %s", (firm_id,))
                lawyers_updated = cur.rowcount
                
                # Deletar KPIs (CASCADE automático)
                # Deletar escritório
                cur.execute("DELETE FROM law_firms WHERE id = %s", (firm_id,))
                
                conn.commit()
                
                logger.info(f"Escritório deletado: {firm['name']} (ID: {firm_id}), {lawyers_updated} advogados desassociados")
                
                return True
    
    async def update_firm_kpis(self, firm_id: UUID, kpi_data: FirmKPIUpdate) -> Optional[FirmKPI]:
        """Atualizar ou criar KPIs do escritório"""
        with self._get_connection() as conn:
            with conn.cursor() as cur:
                # Verificar se escritório existe
                cur.execute("SELECT id FROM law_firms WHERE id = %s", (firm_id,))
                if not cur.fetchone():
                    return None
                
                # Verificar se KPIs já existem
                cur.execute("SELECT firm_id FROM firm_kpis WHERE firm_id = %s", (firm_id,))
                kpis_exist = cur.fetchone() is not None
                
                if kpis_exist:
                    # Atualizar KPIs existentes
                    update_fields = []
                    params = []
                    
                    if kpi_data.success_rate is not None:
                        update_fields.append("success_rate = %s")
                        params.append(kpi_data.success_rate)
                    
                    if kpi_data.nps is not None:
                        update_fields.append("nps = %s")
                        params.append(kpi_data.nps)
                    
                    if kpi_data.reputation_score is not None:
                        update_fields.append("reputation_score = %s")
                        params.append(kpi_data.reputation_score)
                    
                    if kpi_data.diversity_index is not None:
                        update_fields.append("diversity_index = %s")
                        params.append(kpi_data.diversity_index)
                    
                    if kpi_data.active_cases is not None:
                        update_fields.append("active_cases = %s")
                        params.append(kpi_data.active_cases)
                    
                    if not update_fields:
                        # Nenhum campo para atualizar
                        cur.execute("""
                            SELECT success_rate, nps, reputation_score, diversity_index, 
                                   active_cases, updated_at
                            FROM firm_kpis WHERE firm_id = %s
                        """, (firm_id,))
                        result = cur.fetchone()
                        return FirmKPI(firm_id=firm_id, **result)
                    
                    update_fields.append("updated_at = now()")
                    params.append(firm_id)
                    
                    query = f"""
                        UPDATE firm_kpis 
                        SET {', '.join(update_fields)}
                        WHERE firm_id = %s
                        RETURNING success_rate, nps, reputation_score, diversity_index, 
                                  active_cases, updated_at
                    """
                    
                    cur.execute(query, params)
                    result = cur.fetchone()
                    
                else:
                    # Criar novos KPIs (todos os campos são obrigatórios)
                    if any(getattr(kpi_data, field) is None for field in 
                          ['success_rate', 'nps', 'reputation_score', 'diversity_index', 'active_cases']):
                        raise ValueError("Para criar KPIs, todos os campos são obrigatórios")
                    
                    cur.execute("""
                        INSERT INTO firm_kpis (
                            firm_id, success_rate, nps, reputation_score, 
                            diversity_index, active_cases
                        )
                        VALUES (%s, %s, %s, %s, %s, %s)
                        RETURNING success_rate, nps, reputation_score, diversity_index, 
                                  active_cases, updated_at
                    """, (
                        firm_id, kpi_data.success_rate, kpi_data.nps,
                        kpi_data.reputation_score, kpi_data.diversity_index,
                        kpi_data.active_cases
                    ))
                    
                    result = cur.fetchone()
                
                conn.commit()
                
                logger.info(f"KPIs atualizados para escritório ID: {firm_id}")
                
                return FirmKPI(
                    firm_id=firm_id,
                    success_rate=float(result['success_rate']),
                    nps=float(result['nps']),
                    reputation_score=float(result['reputation_score']),
                    diversity_index=float(result['diversity_index']),
                    active_cases=result['active_cases'],
                    updated_at=result['updated_at']
                )
    
    async def get_firm_stats(self) -> FirmStats:
        """Obter estatísticas agregadas dos escritórios"""
        with self._get_connection() as conn:
            with conn.cursor() as cur:
                # Estatísticas gerais
                cur.execute("""
                    SELECT 
                        COUNT(DISTINCT lf.id) as total_firms,
                        COUNT(DISTINCT l.id) as total_lawyers_associated,
                        AVG(fk.success_rate) as avg_success_rate,
                        AVG(fk.nps) as avg_nps,
                        AVG(fk.reputation_score) as avg_reputation_score
                    FROM law_firms lf
                    LEFT JOIN lawyers l ON l.firm_id = lf.id
                    LEFT JOIN firm_kpis fk ON fk.firm_id = lf.id
                """)
                
                stats = cur.fetchone()
                
                # Top escritórios por reputação
                cur.execute("""
                    SELECT 
                        lf.id, lf.name, lf.team_size,
                        fk.success_rate, fk.nps, fk.reputation_score,
                        COUNT(l.id) as lawyers_count
                    FROM law_firms lf
                    LEFT JOIN firm_kpis fk ON fk.firm_id = lf.id
                    LEFT JOIN lawyers l ON l.firm_id = lf.id
                    WHERE fk.reputation_score IS NOT NULL
                    GROUP BY lf.id, lf.name, lf.team_size, fk.success_rate, fk.nps, fk.reputation_score
                    ORDER BY fk.reputation_score DESC, fk.success_rate DESC
                    LIMIT 5
                """)
                
                top_firms = []
                for firm in cur.fetchall():
                    top_firms.append({
                        'id': str(firm['id']),
                        'name': firm['name'],
                        'team_size': firm['team_size'],
                        'success_rate': float(firm['success_rate']) if firm['success_rate'] else 0,
                        'nps': float(firm['nps']) if firm['nps'] else 0,
                        'reputation_score': float(firm['reputation_score']) if firm['reputation_score'] else 0,
                        'lawyers_count': firm['lawyers_count']
                    })
                
                return FirmStats(
                    total_firms=stats['total_firms'] or 0,
                    total_lawyers_associated=stats['total_lawyers_associated'] or 0,
                    avg_success_rate=float(stats['avg_success_rate']) if stats['avg_success_rate'] else 0.0,
                    avg_nps=float(stats['avg_nps']) if stats['avg_nps'] else 0.0,
                    avg_reputation_score=float(stats['avg_reputation_score']) if stats['avg_reputation_score'] else 0.0,
                    top_performing_firms=top_firms
                )

# Instância global do serviço
firm_service = FirmService() 