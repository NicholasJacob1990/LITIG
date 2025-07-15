#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
backend/api/schemas.py

Esquemas Pydantic para validação de dados da API de matching jurídico.
Baseado nas melhores práticas de FastAPI para Machine Learning.
"""

from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional, Union

from pydantic import BaseModel, Field, validator
import uuid


class AreaJuridica(str, Enum):
    """Áreas jurídicas suportadas"""
    TRABALHISTA = "Trabalhista"
    CIVIL = "Civil"
    CRIMINAL = "Criminal"
    TRIBUTARIO = "Tributário"
    PREVIDENCIARIO = "Previdenciário"
    CONSUMIDOR = "Consumidor"
    FAMILIA = "Família"
    EMPRESARIAL = "Empresarial"


class ComplexidadeCaso(str, Enum):
    """Níveis de complexidade do caso"""
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"


class PresetPesos(str, Enum):
    """Presets de pesos para o algoritmo"""
    FAST = "fast"
    EXPERT = "expert"
    BALANCED = "balanced"
    ECONOMIC = "economic"
    B2B = "b2b"
    CORRESPONDENT = "correspondent"
    EXPERT_OPINION = "expert_opinion"


class StatusCaso(str, Enum):
    """Status do caso"""
    ACTIVE = "active"
    PENDING = "pending"
    COMPLETED = "completed"
    SUMMARY_GENERATED = "summary_generated"


class CoordenadaSchema(BaseModel):
    """Coordenadas geográficas"""
    latitude: float = Field(..., ge=-90, le=90, description="Latitude (-90 a 90)")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude (-180 a 180)")


class CaseRequestSchema(BaseModel):
    """Schema para solicitação de matching de caso"""
    title: str = Field(..., min_length=5, max_length=200, description="Título do caso")
    description: str = Field(..., min_length=20, max_length=2000,
                             description="Descrição detalhada")
    area: AreaJuridica = Field(..., description="Área jurídica principal")
    subarea: str = Field(..., min_length=2, max_length=100,
                         description="Subárea específica")
    urgency_hours: int = Field(..., gt=0, le=8760,
                               description="Urgência em horas (máx 1 ano)")
    coordinates: CoordenadaSchema = Field(..., description="Localização do cliente")
    complexity: ComplexidadeCaso = Field(
        ComplexidadeCaso.MEDIUM, description="Complexidade estimada")
    estimated_value: Optional[float] = Field(
        None, ge=0, description="Valor estimado da causa (R$)")

    class Config:
        schema_extra = {
            "example": {
                "title": "Rescisão Indireta por Assédio Moral",
                "description": "Cliente sofreu assédio moral por 6 meses, tem provas documentais e testemunhas. Necessita rescisão indireta e indenização por danos morais.",
                "area": "Trabalhista",
                "subarea": "Rescisão",
                "urgency_hours": 48,
                "coordinates": {
                    "latitude": -23.5505,
                    "longitude": -46.6333
                },
                "complexity": "MEDIUM",
                "estimated_value": 25000.0
            }
        }


class MatchRequestSchema(BaseModel):
    """Schema para solicitação de matching"""
    case: CaseRequestSchema = Field(..., description="Dados do caso")
    top_n: int = Field(5, ge=1, le=20, description="Número de advogados a retornar")
    preset: PresetPesos = Field(
        PresetPesos.BALANCED,
        description="Preset de pesos do algoritmo")
    include_jusbrasil_data: bool = Field(
        True, description="Incluir dados históricos do Jusbrasil")
    custom_coords: Optional[CoordenadaSchema] = Field(None, description="Coordenadas customizadas para busca geográfica")
    radius_km: Optional[int] = Field(None, ge=1, le=500, description="Raio de busca em km")


class LawyerKPISchema(BaseModel):
    """Schema para KPIs do advogado"""
    success_rate: float = Field(..., ge=0, le=1, description="Taxa de sucesso geral")
    cases_30d: int = Field(..., ge=0, description="Casos nos últimos 30 dias")
    capacidade_mensal: int = Field(..., ge=0, description="Capacidade mensal")
    avaliacao_media: float = Field(..., ge=0, le=5, description="Avaliação média (0-5)")
    tempo_resposta_h: int = Field(..., ge=0, description="Tempo de resposta em horas")
    cv_score: float = Field(0.0, ge=0, le=1, description="Score do CV/currículo")


class LawyerJusbrasilSchema(BaseModel):
    """Schema para dados do Jusbrasil"""
    total_cases: int = Field(0, ge=0, description="Total de casos processados")
    victories: int = Field(0, ge=0, description="Número de vitórias")
    defeats: int = Field(0, ge=0, description="Número de derrotas")
    success_rate: float = Field(0.0, ge=0, le=1, description="Taxa de sucesso real")
    last_sync: Optional[datetime] = Field(None, description="Última sincronização")


class LawyerScoresSchema(BaseModel):
    """Schema para scores detalhados do advogado"""
    # Features individuais
    area_match: float = Field(..., ge=0, le=1, description="Match de área (A)")
    case_similarity: float = Field(..., ge=0, le=1,
                                   description="Similaridade de casos (S)")
    success_rate: float = Field(..., ge=0, le=1, description="Taxa de sucesso (T)")
    geo_score: float = Field(..., ge=0, le=1, description="Score geográfico (G)")
    qualification: float = Field(..., ge=0, le=1, description="Qualificação (Q)")
    urgency_capacity: float = Field(..., ge=0, le=1,
                                    description="Capacidade urgência (U)")
    review_score: float = Field(..., ge=0, le=1, description="Score de reviews (R)")
    soft_skills: float = Field(..., ge=0, le=1, description="Soft skills (C)")

    # Scores finais
    raw_score: float = Field(..., ge=0, le=1, description="Score bruto")
    equity_weight: float = Field(..., ge=0, le=1, description="Peso de equidade")
    fair_score: float = Field(..., ge=0, le=1, description="Score final justo")

    # Breakdown por feature
    delta: Dict[str, float] = Field(..., description="Contribuição por feature")

    # Dados do Jusbrasil
    jusbrasil_data: Optional[LawyerJusbrasilSchema] = Field(
        None, description="Dados históricos")


class MatchedLawyerSchema(BaseModel):
    """Schema para advogado no resultado do matching"""
    id: str = Field(..., description="ID único do advogado")
    nome: str = Field(..., description="Nome completo")
    oab_numero: Optional[str] = Field(None, description="Número da OAB")
    uf: Optional[str] = Field(None, description="UF da OAB")
    expertise_areas: List[str] = Field(
        default_factory=list,
        description="Áreas de especialidade")

    # Localização
    coordinates: Optional[Dict[str, float]] = Field(None, description="Coordenadas")
    distance_km: Optional[float] = Field(
        None, ge=0, description="Distância em km do cliente")

    # Dados do matching
    score: float = Field(0.0, ge=0, le=1, description="Score final do matching")
    estimated_response_time_hours: int = Field(0, ge=0, description="Tempo estimado de resposta")
    rating: float = Field(0.0, ge=0, le=5, description="Avaliação média")
    review_texts: List[str] = Field(default_factory=list, description="Textos de reviews")
    is_available: bool = Field(True, description="Disponibilidade atual")
    
    # Dados do Jusbrasil
    total_cases: int = Field(0, ge=0, description="Total de casos processados")
    estimated_success_rate: float = Field(0.0, ge=0, le=1, description="Taxa de sucesso estimada")
    specialization_score: float = Field(0.0, ge=0, le=1, description="Score de especialização")
    activity_level: str = Field("low", description="Nível de atividade")
    data_quality: str = Field("unavailable", description="Qualidade dos dados")
    data_limitations: List[str] = Field(default_factory=list, description="Limitações dos dados")

    # Informações adicionais
    phone: Optional[str] = Field(None, description="Telefone de contato")
    email: Optional[str] = Field(None, description="Email de contato")


class MatchResponseSchema(BaseModel):
    """Schema para resposta do matching"""
    success: bool = Field(..., description="Se o matching foi bem-sucedido")
    case_id: str = Field(..., description="ID único do caso gerado")
    match_id: str = Field(..., description="ID único do matching para explicabilidade")
    lawyers: List[MatchedLawyerSchema] = Field(..., description="Advogados rankeados")

    # Metadados do matching
    total_lawyers_evaluated: int = Field(..., ge=0,
                                         description="Total de advogados avaliados")
    algorithm_version: str = Field(..., description="Versão do algoritmo utilizada")
    preset_used: PresetPesos = Field(..., description="Preset de pesos utilizado")
    execution_time_ms: float = Field(..., ge=0, description="Tempo de execução em ms")

    # Dados para explicabilidade
    weights_used: Dict[str, float] = Field(...,
                                           description="Pesos utilizados no algoritmo")
    case_complexity: ComplexidadeCaso = Field(..., description="Complexidade detectada")

    # (v2.6) Dados do A/B Test
    ab_test_group: Optional[str] = Field(
        None, description="Grupo do teste A/B (control ou treatment)")
    model_version_used: Optional[str] = Field(
        None, description="Versão específica do modelo/algoritmo usada")

    class Config:
        schema_extra = {
            "example": {
                "success": True,
                "case_id": "case_12345",
                "match_id": "match_67890",
                "lawyers": [
                    {
                        "id": "lawyer_001",
                        "nome": "Dr. João Silva",
                        "oab_numero": "123456",
                        "uf": "SP",
                        "expertise_areas": ["Trabalhista", "Previdenciário"],
                        "coordinates": {"latitude": -23.5505, "longitude": -46.6333},
                        "distance_km": 2.5,
                        "score": 0.89,
                        "total_cases": 150,
                        "estimated_success_rate": 0.85
                    }
                ],
                "total_lawyers_evaluated": 147,
                "algorithm_version": "v2.2",
                "execution_time_ms": 245.6
            }
        }


class ErrorResponseSchema(BaseModel):
    """Schema para respostas de erro"""
    success: bool = Field(False, description="Sempre False para erros")
    error_code: str = Field(..., description="Código do erro")
    message: str = Field(..., description="Mensagem de erro")
    details: Optional[Dict[str, Any]] = Field(
        None, description="Detalhes adicionais do erro")
    timestamp: datetime = Field(
        default_factory=datetime.utcnow,
        description="Timestamp do erro")


class HealthCheckSchema(BaseModel):
    """Schema para health check"""
    status: str = Field(..., description="Status da API")
    version: str = Field(..., description="Versão da API")
    timestamp: datetime = Field(
        default_factory=datetime.utcnow,
        description="Timestamp atual")
    services: Dict[str, str] = Field(..., description="Status dos serviços")


class LawyerListRequestSchema(BaseModel):
    """Schema para listagem de advogados"""
    area: Optional[AreaJuridica] = Field(None, description="Filtrar por área")
    uf: Optional[str] = Field(
        None,
        min_length=2,
        max_length=2,
        description="Filtrar por UF")
    coordinates: Optional[CoordenadaSchema] = Field(
        None, description="Centro para busca geográfica")
    radius_km: Optional[float] = Field(
        None, ge=0, le=1000, description="Raio em km para busca")
    min_rating: Optional[float] = Field(
        None, ge=0, le=5, description="Avaliação mínima")
    limit: int = Field(20, ge=1, le=100, description="Limite de resultados")
    offset: int = Field(0, ge=0, description="Offset para paginação")


class LawyerListResponseSchema(BaseModel):
    """Schema para resposta da listagem de advogados"""
    success: bool = Field(..., description="Se a busca foi bem-sucedida")
    lawyers: List[MatchedLawyerSchema] = Field(..., description="Lista de advogados")
    total: int = Field(..., ge=0, description="Total de advogados encontrados")
    limit: int = Field(..., description="Limite aplicado")
    offset: int = Field(..., description="Offset aplicado")


class SyncStatusSchema(BaseModel):
    """Schema para status da sincronização com Jusbrasil"""
    lawyer_id: str = Field(..., description="ID do advogado")
    last_sync: Optional[datetime] = Field(None, description="Última sincronização")
    total_cases: int = Field(0, ge=0, description="Total de casos sincronizados")
    sync_status: str = Field(..., description="Status da sincronização")
    next_sync: Optional[datetime] = Field(
        None, description="Próxima sincronização prevista")


class LawyerProfileUpdate(BaseModel):
    name: Optional[str] = None
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    practice_areas: Optional[List[str]] = None
    office_address: Optional[str] = None
    languages: Optional[List[str]] = None
    consultation_methods: Optional[List[str]] = None


class EquityDataUpdate(BaseModel):
    gender: Optional[str] = Field(None, description="Gênero autodeclarado")
    ethnicity: Optional[str] = Field(None, description="Etnia autodeclarada")
    pcd: Optional[bool] = Field(None, description="Pessoa com deficiência")
    orientation: Optional[str] = Field(
        None, description="Orientação sexual autodeclarada")
    consent_ts: float = Field(..., description="Timestamp do consentimento do usuário")

    class Config:
        extra = "forbid"


class CaseCreate(BaseModel):
    description: str


class CaseSchema(BaseModel):
    id: str
    client_id: str


class CaseOutcome(str, Enum):
    won = "won"
    lost = "lost"
    settled = "settled"
    ongoing = "ongoing"

class ReviewCreate(BaseModel):
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None
    outcome: Optional[CaseOutcome] = None
    communication_rating: Optional[int] = Field(None, ge=1, le=5)
    expertise_rating: Optional[int] = Field(None, ge=1, le=5)
    timeliness_rating: Optional[int] = Field(None, ge=1, le=5)
    would_recommend: Optional[bool] = None

class ReviewResponse(ReviewCreate):
    id: uuid.UUID
    contract_id: uuid.UUID
    created_at: datetime

    class Config:
        orm_mode = True


# Schemas para Sistema de Parcerias

class PartnershipType(str, Enum):
    """Tipos de parceria jurídica"""
    CONSULTORIA = "consultoria"
    REDACAO_TECNICA = "redacao_tecnica"
    AUDIENCIA = "audiencia"
    SUPORTE_TOTAL = "suporte_total"
    PARCERIA_RECORRENTE = "parceria_recorrente"


class PartnershipStatus(str, Enum):
    """Status da parceria"""
    PENDENTE = "pendente"
    ACEITA = "aceita"
    REJEITADA = "rejeitada"
    CONTRATO_PENDENTE = "contrato_pendente"
    ATIVA = "ativa"
    FINALIZADA = "finalizada"
    CANCELADA = "cancelada"


class PartnershipCreateSchema(BaseModel):
    """Schema para criação de proposta de parceria"""
    partner_id: str = Field(..., description="ID do advogado/escritório parceiro")
    case_id: Optional[str] = Field(None, description="ID do caso vinculado (opcional)")
    type: PartnershipType = Field(..., description="Tipo de colaboração")
    honorarios: str = Field(..., min_length=1, max_length=200, description="Honorários propostos")
    proposal_message: Optional[str] = Field(None, max_length=1000, description="Mensagem da proposta")

    class Config:
        schema_extra = {
            "example": {
                "partner_id": "lawyer_123",
                "case_id": "case_456",
                "type": "consultoria",
                "honorarios": "R$ 1.500,00",
                "proposal_message": "Preciso de apoio especializado em Direito Ambiental para este caso."
            }
        }


class PartnershipResponseSchema(BaseModel):
    """Schema para resposta de parceria"""
    id: str = Field(..., description="ID único da parceria")
    creator_id: str = Field(..., description="ID de quem criou a proposta")
    partner_id: str = Field(..., description="ID do parceiro")
    case_id: Optional[str] = Field(None, description="ID do caso vinculado")
    type: PartnershipType = Field(..., description="Tipo de parceria")
    status: PartnershipStatus = Field(..., description="Status atual")
    honorarios: str = Field(..., description="Honorários acordados")
    proposal_message: Optional[str] = Field(None, description="Mensagem da proposta")
    contract_url: Optional[str] = Field(None, description="URL do contrato gerado")
    contract_accepted_at: Optional[datetime] = Field(None, description="Data de aceite do contrato")
    created_at: datetime = Field(..., description="Data de criação")
    updated_at: datetime = Field(..., description="Data da última atualização")
    
    # Dados adicionais para UI
    creator_name: Optional[str] = Field(None, description="Nome do criador")
    partner_name: Optional[str] = Field(None, description="Nome do parceiro")
    case_title: Optional[str] = Field(None, description="Título do caso")

    class Config:
        orm_mode = True


class PartnershipListResponseSchema(BaseModel):
    """Schema para listagem separada de parcerias"""
    sent: List[PartnershipResponseSchema] = Field(..., description="Parcerias enviadas")
    received: List[PartnershipResponseSchema] = Field(..., description="Parcerias recebidas")


class PartnershipStatsSchema(BaseModel):
    """Schema para estatísticas de parcerias"""
    total_partnerships: int = Field(..., description="Total de parcerias")
    active_partnerships: int = Field(..., description="Parcerias ativas")
    pending_partnerships: int = Field(..., description="Parcerias pendentes")
    completed_partnerships: int = Field(..., description="Parcerias finalizadas")
    success_rate: float = Field(..., ge=0, le=1, description="Taxa de sucesso")
    average_duration_days: Optional[float] = Field(None, description="Duração média em dias")
    total_revenue: Optional[float] = Field(None, description="Receita total gerada")


class ContractGenerationSchema(BaseModel):
    """Schema para geração de contrato"""
    partnership_id: str = Field(..., description="ID da parceria")
    template_type: str = Field("default", description="Tipo de template")
    custom_clauses: Optional[List[str]] = Field(None, description="Cláusulas customizadas")

    class Config:
        schema_extra = {
            "example": {
                "partnership_id": "partnership_123",
                "template_type": "consultoria",
                "custom_clauses": ["Cláusula de confidencialidade específica"]
            }
        }


class ContractResponseSchema(BaseModel):
    """Schema para resposta do contrato gerado"""
    contract_url: str = Field(..., description="URL do contrato PDF")
    contract_html: str = Field(..., description="Conteúdo HTML do contrato")
    expires_at: datetime = Field(..., description="Data de expiração do link")


class ExplainabilitySchema(BaseModel):
    """Schema para explicabilidade de um matching"""
    match_id: str = Field(..., description="ID do matching")
    lawyers: List[Dict[str, Any]] = Field(..., description="Scores detalhados dos advogados")
    weights_used: Dict[str, float] = Field(..., description="Pesos aplicados no algoritmo")
    preset: str = Field(..., description="Preset utilizado")
    case_complexity: str = Field(..., description="Complexidade do caso")
    algorithm_version: str = Field(..., description="Versão do algoritmo")
    
    class Config:
        schema_extra = {
            "example": {
                "match_id": "match_12345",
                "lawyers": [
                    {
                        "id": "lawyer_001",
                        "features": {"A": 1.0, "S": 0.85, "T": 0.92},
                        "delta": {"A": 0.28, "S": 0.20, "T": 0.13},
                        "fair_base": 0.89
                    }
                ],
                "weights_used": {"A": 0.28, "S": 0.23, "T": 0.14},
                "preset": "balanced",
                "case_complexity": "MEDIUM",
                "algorithm_version": "v2.7-rc"
            }
        }


class PartnerSearchSchema(BaseModel):
    """Schema para busca de parceiros"""
    description: str = Field(..., min_length=10, max_length=500, description="Descrição da necessidade")
    area: Optional[AreaJuridica] = Field(None, description="Área jurídica específica")
    urgency_hours: Optional[int] = Field(None, gt=0, le=8760, description="Urgência em horas")
    coordinates: Optional[CoordenadaSchema] = Field(None, description="Localização")
    radius_km: Optional[float] = Field(50, ge=1, le=1000, description="Raio de busca em km")
    limit: int = Field(10, ge=1, le=20, description="Número máximo de resultados")

    class Config:
        schema_extra = {
            "example": {
                "description": "Preciso de apoio especializado em Direito Ambiental para licenciamento",
                "area": "EMPRESARIAL",
                "urgency_hours": 72,
                "coordinates": {
                    "latitude": -23.5505,
                    "longitude": -46.6333
                },
                "radius_km": 50,
                "limit": 5
            }
        }
