from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class ProficiencyLevel(str, Enum):
    """Níveis de proficiência"""
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"
    NATIVE = "native"
    PROFESSIONAL = "professional"

class LinkedInEducation(BaseModel):
    """Formação acadêmica completa do LinkedIn"""
    institution: str = Field(..., description="Nome da instituição")
    degree_name: Optional[str] = Field(None, description="Nome do grau (Bacharel, Mestrado, etc.)")
    field_of_study: Optional[str] = Field(None, description="Área de estudo/curso")
    start_date: Optional[datetime] = Field(None, description="Data de início")
    end_date: Optional[datetime] = Field(None, description="Data de conclusão")
    grade: Optional[str] = Field(None, description="Nota/conceito obtido")
    activities: Optional[str] = Field(None, description="Atividades e grupos")
    description: Optional[str] = Field(None, description="Descrição adicional")
    logo_url: Optional[str] = Field(None, description="URL do logo da instituição")

class LinkedInExperience(BaseModel):
    """Experiência profissional detalhada"""
    company_name: str = Field(..., description="Nome da empresa")
    title: str = Field(..., description="Cargo/posição")
    employment_type: Optional[str] = Field(None, description="Tipo de emprego (CLT, PJ, etc.)")
    location: Optional[str] = Field(None, description="Localização do trabalho")
    start_date: Optional[datetime] = Field(None, description="Data de início")
    end_date: Optional[datetime] = Field(None, description="Data de término (None se atual)")
    duration_months: Optional[int] = Field(None, description="Duração em meses")
    description: Optional[str] = Field(None, description="Descrição das atividades")
    company_logo_url: Optional[str] = Field(None, description="URL do logo da empresa")
    company_url: Optional[str] = Field(None, description="URL da empresa")
    is_current: bool = Field(False, description="Se é o trabalho atual")

class LinkedInSkill(BaseModel):
    """Competência/habilidade com endorsements"""
    name: str = Field(..., description="Nome da habilidade")
    endorsement_count: int = Field(0, description="Número de endorsements")
    endorsers: Optional[List[str]] = Field(None, description="Lista de pessoas que endossaram")
    proficiency_level: Optional[ProficiencyLevel] = Field(None, description="Nível de proficiência")
    category: Optional[str] = Field(None, description="Categoria da skill")

class LinkedInCertification(BaseModel):
    """Certificação profissional"""
    name: str = Field(..., description="Nome da certificação")
    organization: str = Field(..., description="Organização emissora")
    issue_date: Optional[datetime] = Field(None, description="Data de emissão")
    expiration_date: Optional[datetime] = Field(None, description="Data de expiração")
    credential_id: Optional[str] = Field(None, description="ID da credencial")
    credential_url: Optional[str] = Field(None, description="URL da credencial")
    organization_logo: Optional[str] = Field(None, description="Logo da organização")

class LinkedInLanguage(BaseModel):
    """Idioma com nível de proficiência"""
    name: str = Field(..., description="Nome do idioma")
    proficiency: Optional[ProficiencyLevel] = Field(None, description="Nível de proficiência")

class LinkedInVolunteerExperience(BaseModel):
    """Experiência voluntária"""
    organization: str = Field(..., description="Nome da organização")
    role: str = Field(..., description="Função exercida")
    cause: Optional[str] = Field(None, description="Causa apoiada")
    start_date: Optional[datetime] = Field(None, description="Data de início")
    end_date: Optional[datetime] = Field(None, description="Data de término")
    description: Optional[str] = Field(None, description="Descrição das atividades")

class LinkedInContact(BaseModel):
    """Informações de contato"""
    emails: List[str] = Field(default_factory=list, description="Lista de emails")
    phone_numbers: List[str] = Field(default_factory=list, description="Lista de telefones")
    addresses: List[str] = Field(default_factory=list, description="Lista de endereços")
    websites: List[str] = Field(default_factory=list, description="Lista de websites pessoais")
    social_networks: Dict[str, str] = Field(default_factory=dict, description="Outras redes sociais")

class LinkedInNetworkMetrics(BaseModel):
    """Métricas de rede profissional"""
    connections_count: int = Field(0, description="Número de conexões")
    followers_count: int = Field(0, description="Número de seguidores")
    following_count: int = Field(0, description="Número de pessoas seguindo")
    degree_of_connection: Optional[int] = Field(None, description="Grau de conexão (1º, 2º, 3º)")
    mutual_connections: List[str] = Field(default_factory=list, description="Conexões em comum")

class LinkedInActivity(BaseModel):
    """Atividade recente no LinkedIn"""
    post_id: str = Field(..., description="ID do post")
    content: str = Field(..., description="Conteúdo do post")
    post_type: str = Field(..., description="Tipo do post (article, post, share)")
    published_at: datetime = Field(..., description="Data de publicação")
    likes_count: int = Field(0, description="Número de curtidas")
    comments_count: int = Field(0, description="Número de comentários")
    shares_count: int = Field(0, description="Número de compartilhamentos")
    engagement_rate: float = Field(0.0, description="Taxa de engajamento")

class LinkedInComprehensiveProfile(BaseModel):
    """Perfil LinkedIn completo com todos os dados disponíveis"""
    # Dados básicos
    linkedin_id: str = Field(..., description="ID único do LinkedIn")
    full_name: str = Field(..., description="Nome completo")
    first_name: Optional[str] = Field(None, description="Primeiro nome")
    last_name: Optional[str] = Field(None, description="Último nome")
    headline: Optional[str] = Field(None, description="Headline profissional")
    summary: Optional[str] = Field(None, description="Resumo/sobre do perfil")
    location: Optional[str] = Field(None, description="Localização atual")
    industry: Optional[str] = Field(None, description="Indústria de atuação")
    profile_picture_url: Optional[str] = Field(None, description="URL da foto de perfil")
    background_image_url: Optional[str] = Field(None, description="URL da imagem de fundo")
    profile_url: str = Field(..., description="URL do perfil LinkedIn")
    
    # Formação acadêmica
    education: List[LinkedInEducation] = Field(default_factory=list, description="Lista de formações")
    
    # Experiência profissional
    experience: List[LinkedInExperience] = Field(default_factory=list, description="Lista de experiências")
    
    # Competências e certificações
    skills: List[LinkedInSkill] = Field(default_factory=list, description="Lista de habilidades")
    certifications: List[LinkedInCertification] = Field(default_factory=list, description="Lista de certificações")
    
    # Idiomas e voluntariado
    languages: List[LinkedInLanguage] = Field(default_factory=list, description="Lista de idiomas")
    volunteer_experience: List[LinkedInVolunteerExperience] = Field(default_factory=list, description="Experiência voluntária")
    
    # Contatos e rede
    contact_info: LinkedInContact = Field(default_factory=LinkedInContact, description="Informações de contato")
    network_metrics: LinkedInNetworkMetrics = Field(default_factory=LinkedInNetworkMetrics, description="Métricas de rede")
    
    # Atividade recente
    recent_activity: List[LinkedInActivity] = Field(default_factory=list, description="Atividade recente")
    
    # Metadados
    last_updated: datetime = Field(default_factory=datetime.utcnow, description="Última atualização")
    data_quality_score: float = Field(0.0, description="Score de qualidade dos dados (0-1)")
    completeness_score: float = Field(0.0, description="Score de completude do perfil (0-1)")
    source_confidence: float = Field(1.0, description="Confiança na fonte dos dados")
    
class LinkedInProfileUpdateRequest(BaseModel):
    """Request para atualização de perfil LinkedIn"""
    lawyer_id: str = Field(..., description="ID do advogado")
    linkedin_url: Optional[str] = Field(None, description="URL do perfil LinkedIn")
    force_refresh: bool = Field(False, description="Forçar atualização mesmo com cache válido")
    include_activity: bool = Field(True, description="Incluir atividade recente")
    include_network_metrics: bool = Field(True, description="Incluir métricas de rede")
    
class LinkedInDataQualityReport(BaseModel):
    """Relatório de qualidade dos dados LinkedIn"""
    profile_id: str = Field(..., description="ID do perfil")
    total_fields: int = Field(..., description="Total de campos possíveis")
    completed_fields: int = Field(..., description="Campos preenchidos")
    completeness_percentage: float = Field(..., description="Percentual de completude")
    missing_critical_data: List[str] = Field(default_factory=list, description="Dados críticos faltantes")
    data_freshness_hours: int = Field(..., description="Idade dos dados em horas")
    source_reliability: float = Field(..., description="Confiabilidade da fonte (0-1)")
    last_validation: datetime = Field(..., description="Última validação dos dados")
    recommendations: List[str] = Field(default_factory=list, description="Recomendações de melhoria") 