#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cluster Schemas
===============

Schemas Pydantic para respostas das APIs de clusterização.
Define estruturas de dados para endpoints de clusters, recomendações e estatísticas.
"""

from datetime import datetime
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field


class TrendingClusterResponse(BaseModel):
    """Resposta para clusters em tendência."""
    
    cluster_id: str = Field(description="ID único do cluster")
    cluster_label: str = Field(description="Rótulo humano do cluster")
    momentum_score: float = Field(ge=0.0, le=1.0, description="Score de momentum/crescimento")
    total_cases: int = Field(ge=0, description="Total de casos no cluster")
    total_lawyers: int = Field(ge=0, description="Total de advogados no cluster") 
    growth_trend: str = Field(description="Tendência: rapidly_increasing, increasing, stable, decreasing, rapidly_decreasing")
    is_emergent: bool = Field(description="Se é um cluster emergente")
    emergent_since: Optional[datetime] = Field(None, description="Data de detecção como emergente")
    confidence_score: float = Field(ge=0.0, le=1.0, description="Confiança no rótulo gerado")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat() if v else None
        }


class ClusterMemberInfo(BaseModel):
    """Informações de um membro do cluster."""
    
    entity_id: str = Field(description="ID da entidade (caso ou advogado)")
    entity_name: str = Field(description="Nome/título da entidade")
    description: Optional[str] = Field(None, description="Descrição breve")
    confidence_score: float = Field(ge=0.0, le=1.0, description="Confiança na atribuição ao cluster")
    assignment_method: str = Field(description="Método de atribuição: hdbscan, similarity, manual")
    added_to_cluster_at: datetime = Field(description="Data de adição ao cluster")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class ClusterDetailResponse(BaseModel):
    """Resposta detalhada de um cluster específico."""
    
    cluster_id: str = Field(description="ID único do cluster")
    cluster_type: str = Field(description="Tipo: case ou lawyer")
    cluster_label: str = Field(description="Rótulo humano do cluster")
    description: Optional[str] = Field(None, description="Descrição detalhada")
    total_members: int = Field(ge=0, description="Total de membros")
    momentum_score: float = Field(ge=0.0, le=1.0, description="Score de momentum")
    is_emergent: bool = Field(description="Se é emergente")
    emergent_since: Optional[datetime] = Field(None, description="Data de emergência")
    
    quality_metrics: Dict[str, Any] = Field(description="Métricas de qualidade do cluster")
    label_info: Dict[str, Any] = Field(description="Informações sobre o rótulo gerado")
    members: List[ClusterMemberInfo] = Field(default_factory=list, description="Membros do cluster")
    
    created_at: datetime = Field(description="Data de criação")
    last_updated: datetime = Field(description="Última atualização")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class PartnershipRecommendationResponse(BaseModel):
    """Resposta para recomendação de parceria."""
    
    recommended_lawyer_id: str = Field(description="ID do advogado recomendado")
    lawyer_name: str = Field(description="Nome do advogado")
    firm_name: Optional[str] = Field(None, description="Nome do escritório")
    cluster_expertise: str = Field(description="Área de expertise (cluster)")
    compatibility_score: float = Field(ge=0.0, le=1.0, description="Score de compatibilidade")
    confidence_in_expertise: float = Field(ge=0.0, le=1.0, description="Confiança na expertise")
    complementarity_score: float = Field(ge=0.0, le=1.0, description="Score de complementaridade")
    recommendation_reason: str = Field(description="Razão da recomendação")
    potential_synergies: List[str] = Field(default_factory=list, description="Sinergias potenciais")


class ClusteringStatsDetailed(BaseModel):
    """Estatísticas detalhadas de clusterização por tipo."""
    
    total_clusters: int = Field(ge=0, description="Total de clusters")
    total_entities: int = Field(ge=0, description="Total de entidades clusterizadas")
    avg_cluster_size: float = Field(ge=0.0, description="Tamanho médio dos clusters")
    emergent_clusters: int = Field(ge=0, description="Clusters emergentes")
    avg_momentum: float = Field(ge=0.0, le=1.0, description="Momentum médio")
    last_clustering_run: Optional[datetime] = Field(None, description="Última execução de clusterização")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat() if v else None
        }


class ClusterStatsResponse(BaseModel):
    """Resposta completa de estatísticas de clusterização."""
    
    case_clustering: ClusteringStatsDetailed = Field(description="Estatísticas de clusters de casos")
    lawyer_clustering: ClusteringStatsDetailed = Field(description="Estatísticas de clusters de advogados")
    quality_metrics: Dict[str, Any] = Field(description="Métricas de qualidade geral")
    system_health: Dict[str, Any] = Field(description="Saúde do sistema")
    detailed_breakdown: Optional[Dict[str, Any]] = Field(None, description="Breakdown detalhado")
    generated_at: datetime = Field(description="Data/hora de geração")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


# Schemas para requests específicos

class ClusterSearchRequest(BaseModel):
    """Request para busca de clusters."""
    
    query: Optional[str] = Field(None, description="Termo de busca")
    cluster_type: str = Field(default="case", description="Tipo: case ou lawyer")
    min_items: int = Field(default=5, ge=1, description="Mínimo de itens")
    emergent_only: bool = Field(default=False, description="Apenas emergentes")
    limit: int = Field(default=10, ge=1, le=100, description="Limite de resultados")


class PartnershipSearchRequest(BaseModel):
    """Request para busca de parcerias."""
    
    lawyer_id: str = Field(description="ID do advogado")
    expertise_areas: Optional[List[str]] = Field(None, description="Áreas de expertise desejadas")
    min_compatibility: float = Field(default=0.6, ge=0.0, le=1.0, description="Compatibilidade mínima")
    geographic_preference: Optional[str] = Field(None, description="Preferência geográfica")
    exclude_same_firm: bool = Field(default=True, description="Excluir mesmo escritório")
    limit: int = Field(default=10, ge=1, le=50, description="Limite de recomendações")


# Schemas para respostas de análise

class ClusterAnalysisResponse(BaseModel):
    """Resposta de análise de cluster."""
    
    cluster_id: str = Field(description="ID do cluster analisado")
    analysis_type: str = Field(description="Tipo de análise realizada")
    insights: List[str] = Field(description="Insights gerados")
    recommendations: List[str] = Field(description="Recomendações")
    market_trends: Optional[List[str]] = Field(None, description="Tendências de mercado identificadas")
    competitive_analysis: Optional[str] = Field(None, description="Análise competitiva")
    growth_potential: float = Field(ge=0.0, le=1.0, description="Potencial de crescimento")
    risk_factors: List[str] = Field(default_factory=list, description="Fatores de risco")
    generated_at: datetime = Field(description="Data de geração")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class EmergentClusterAlert(BaseModel):
    """Alerta de cluster emergente."""
    
    cluster_id: str = Field(description="ID do cluster emergente")
    cluster_label: str = Field(description="Rótulo do cluster")
    detection_date: datetime = Field(description="Data de detecção")
    momentum_score: float = Field(ge=0.0, le=1.0, description="Score de momentum")
    growth_rate: float = Field(description="Taxa de crescimento")
    market_opportunity: str = Field(description="Oportunidade de mercado")
    recommended_actions: List[str] = Field(description="Ações recomendadas")
    urgency_level: str = Field(description="Nível de urgência: low, medium, high, critical")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


# Schemas para configuração e administração

class ClusteringConfigResponse(BaseModel):
    """Configuração atual do sistema de clusterização."""
    
    embedding_providers: List[str] = Field(description="Provedores de embedding habilitados")
    clustering_algorithm: str = Field(description="Algoritmo de clusterização")
    update_frequency: str = Field(description="Frequência de atualização")
    quality_thresholds: Dict[str, float] = Field(description="Thresholds de qualidade")
    data_sources: List[str] = Field(description="Fontes de dados integradas")
    last_updated: datetime = Field(description="Última atualização da configuração")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class ClusterHealthCheck(BaseModel):
    """Health check do sistema de clusters."""
    
    status: str = Field(description="Status: healthy, degraded, unhealthy")
    checks: Dict[str, bool] = Field(description="Resultados de verificações individuais")
    errors: List[str] = Field(default_factory=list, description="Erros encontrados")
    warnings: List[str] = Field(default_factory=list, description="Avisos")
    performance_metrics: Dict[str, Any] = Field(description="Métricas de performance")
    timestamp: datetime = Field(description="Timestamp da verificação")
    version: str = Field(description="Versão do sistema")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


# Schemas para integrações específicas (Flutter)

class DashboardClusterWidget(BaseModel):
    """Dados para widget de cluster no dashboard Flutter."""
    
    trending_clusters: List[TrendingClusterResponse] = Field(description="Top 3 clusters trending")
    emergent_alerts: List[EmergentClusterAlert] = Field(description="Alertas de nichos emergentes")
    partnership_suggestions: List[PartnershipRecommendationResponse] = Field(description="Sugestões de parceria")
    market_insights: List[str] = Field(description="Insights de mercado")
    last_updated: datetime = Field(description="Última atualização")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class ClusterBadgeData(BaseModel):
    """Dados para badge de cluster em casos/advogados."""
    
    cluster_id: str = Field(description="ID do cluster")
    cluster_label: str = Field(description="Label para exibição")
    badge_type: str = Field(description="Tipo: trending, emergent, stable")
    momentum_score: float = Field(ge=0.0, le=1.0, description="Score de momentum")
    color_theme: str = Field(description="Tema de cor: primary, success, warning, info")
    show_icon: bool = Field(default=True, description="Se deve mostrar ícone")
    tooltip_text: str = Field(description="Texto do tooltip")


# Resposta para modal completo no Flutter
class ClusterModalData(BaseModel):
    """Dados completos para modal de cluster no Flutter."""
    
    cluster_details: ClusterDetailResponse = Field(description="Detalhes do cluster")
    related_clusters: List[TrendingClusterResponse] = Field(description="Clusters relacionados")
    market_analysis: ClusterAnalysisResponse = Field(description="Análise de mercado")
    partnership_opportunities: List[PartnershipRecommendationResponse] = Field(description="Oportunidades de parceria")
    action_items: List[str] = Field(description="Itens de ação recomendados")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        } 