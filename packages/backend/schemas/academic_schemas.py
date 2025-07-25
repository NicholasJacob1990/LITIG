from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class InstitutionRank(str, Enum):
    """Rankings de instituições acadêmicas"""
    TOP_10 = "top_10"
    TOP_50 = "top_50"
    TOP_100 = "top_100"
    TOP_500 = "top_500"
    REGIONAL = "regional"
    UNKNOWN = "unknown"

class PublicationTier(str, Enum):
    """Tier/qualidade de publicações acadêmicas"""
    Q1 = "q1"  # Qualis A1/A2
    Q2 = "q2"  # Qualis B1/B2
    Q3 = "q3"  # Qualis B3/B4
    Q4 = "q4"  # Qualis B5/C
    CONFERENCE = "conference"
    BOOK = "book"
    UNKNOWN = "unknown"

class AcademicInstitution(BaseModel):
    """Instituição acadêmica com rankings e reputação"""
    name: str = Field(..., description="Nome da instituição")
    country: str = Field(..., description="País da instituição")
    state: Optional[str] = Field(None, description="Estado/província")
    city: Optional[str] = Field(None, description="Cidade")
    
    # Rankings e reputação
    world_rank: Optional[int] = Field(None, description="Ranking mundial")
    national_rank: Optional[int] = Field(None, description="Ranking nacional")
    regional_rank: Optional[int] = Field(None, description="Ranking regional")
    rank_tier: InstitutionRank = Field(InstitutionRank.UNKNOWN, description="Tier do ranking")
    
    # Scores de reputação
    academic_reputation_score: Optional[float] = Field(None, description="Score de reputação acadêmica (0-100)")
    employer_reputation_score: Optional[float] = Field(None, description="Score de reputação entre empregadores (0-100)")
    research_impact_score: Optional[float] = Field(None, description="Score de impacto de pesquisa (0-100)")
    
    # Especialização em direito
    law_school_rank: Optional[int] = Field(None, description="Ranking específico da faculdade de direito")
    law_program_quality: Optional[float] = Field(None, description="Qualidade do programa de direito (0-10)")
    
    # Metadados
    founded_year: Optional[int] = Field(None, description="Ano de fundação")
    institution_type: Optional[str] = Field(None, description="Tipo (pública, privada, federal, etc.)")
    website_url: Optional[str] = Field(None, description="Website oficial")
    logo_url: Optional[str] = Field(None, description="URL do logo")

class AcademicDegree(BaseModel):
    """Grau acadêmico com detalhes completos"""
    degree_type: str = Field(..., description="Tipo do grau (Bacharel, Mestrado, Doutorado, etc.)")
    degree_name: str = Field(..., description="Nome completo do grau")
    field_of_study: str = Field(..., description="Área de estudo")
    specialization: Optional[str] = Field(None, description="Especialização específica")
    
    # Instituição
    institution: AcademicInstitution = Field(..., description="Dados da instituição")
    
    # Datas e duração
    start_date: Optional[datetime] = Field(None, description="Data de início")
    end_date: Optional[datetime] = Field(None, description="Data de conclusão")
    duration_years: Optional[float] = Field(None, description="Duração em anos")
    
    # Performance acadêmica
    gpa: Optional[float] = Field(None, description="GPA/CRA")
    honors: Optional[str] = Field(None, description="Honras acadêmicas (magna cum laude, etc.)")
    thesis_title: Optional[str] = Field(None, description="Título da tese/dissertação")
    thesis_advisor: Optional[str] = Field(None, description="Orientador")
    
    # Validação
    is_verified: bool = Field(False, description="Se o grau foi verificado")
    verification_source: Optional[str] = Field(None, description="Fonte de verificação")

class AcademicPublication(BaseModel):
    """Publicação acadêmica com métricas de impacto"""
    title: str = Field(..., description="Título da publicação")
    authors: List[str] = Field(..., description="Lista de autores")
    author_position: Optional[int] = Field(None, description="Posição do autor na lista (1=primeiro)")
    
    # Venue/periódico
    venue_name: str = Field(..., description="Nome do periódico/conferência")
    venue_type: str = Field(..., description="Tipo (journal, conference, book, etc.)")
    publication_tier: PublicationTier = Field(PublicationTier.UNKNOWN, description="Tier da publicação")
    
    # Datas
    published_date: Optional[datetime] = Field(None, description="Data de publicação")
    submission_date: Optional[datetime] = Field(None, description="Data de submissão")
    
    # Métricas de impacto
    citation_count: int = Field(0, description="Número de citações")
    h_index_contribution: Optional[float] = Field(None, description="Contribuição para h-index")
    impact_factor: Optional[float] = Field(None, description="Impact factor do periódico")
    
    # Conteúdo
    abstract: Optional[str] = Field(None, description="Resumo/abstract")
    keywords: List[str] = Field(default_factory=list, description="Palavras-chave")
    doi: Optional[str] = Field(None, description="DOI da publicação")
    url: Optional[str] = Field(None, description="URL da publicação")
    
    # Classificação jurídica
    legal_areas: List[str] = Field(default_factory=list, description="Áreas jurídicas abordadas")
    brazilian_law_relevance: Optional[float] = Field(None, description="Relevância para direito brasileiro (0-1)")

class AcademicRecognition(BaseModel):
    """Reconhecimentos e prêmios acadêmicos"""
    award_name: str = Field(..., description="Nome do prêmio/reconhecimento")
    granting_organization: str = Field(..., description="Organização que concedeu")
    award_date: Optional[datetime] = Field(None, description="Data do prêmio")
    award_year: Optional[int] = Field(None, description="Ano do prêmio")
    
    # Detalhes
    description: Optional[str] = Field(None, description="Descrição do prêmio")
    category: Optional[str] = Field(None, description="Categoria do prêmio")
    award_level: Optional[str] = Field(None, description="Nível (nacional, internacional, regional)")
    
    # Relevância
    prestige_score: Optional[float] = Field(None, description="Score de prestígio (0-10)")
    legal_field_relevance: Optional[float] = Field(None, description="Relevância para área jurídica (0-1)")

class AcademicProfile(BaseModel):
    """Perfil acadêmico completo"""
    # Identificação
    full_name: str = Field(..., description="Nome completo")
    alternative_names: List[str] = Field(default_factory=list, description="Nomes alternativos/anteriores")
    
    # Formação acadêmica
    degrees: List[AcademicDegree] = Field(default_factory=list, description="Lista de graus acadêmicos")
    highest_degree: Optional[str] = Field(None, description="Maior grau obtido")
    
    # Publicações e pesquisa
    publications: List[AcademicPublication] = Field(default_factory=list, description="Lista de publicações")
    total_citations: int = Field(0, description="Total de citações")
    h_index: Optional[int] = Field(None, description="Índice H")
    i10_index: Optional[int] = Field(None, description="Índice i10")
    
    # Reconhecimentos
    awards: List[AcademicRecognition] = Field(default_factory=list, description="Prêmios e reconhecimentos")
    
    # Especialização jurídica
    legal_specializations: List[str] = Field(default_factory=list, description="Especializações jurídicas")
    main_research_areas: List[str] = Field(default_factory=list, description="Principais áreas de pesquisa")
    
    # Métricas consolidadas
    academic_prestige_score: float = Field(0.0, description="Score de prestígio acadêmico (0-100)")
    research_productivity_score: float = Field(0.0, description="Score de produtividade em pesquisa (0-100)")
    institution_quality_score: float = Field(0.0, description="Score de qualidade das instituições (0-100)")
    
    # Metadados
    data_sources: List[str] = Field(default_factory=list, description="Fontes dos dados")
    last_updated: datetime = Field(default_factory=datetime.utcnow, description="Última atualização")
    confidence_score: float = Field(0.0, description="Confiança nos dados (0-1)")

class PerplexityAcademicQuery(BaseModel):
    """Query para busca acadêmica via Perplexity"""
    lawyer_name: str = Field(..., description="Nome do advogado")
    institution_hints: List[str] = Field(default_factory=list, description="Dicas de instituições")
    degree_hints: List[str] = Field(default_factory=list, description="Dicas de graus")
    time_period: Optional[str] = Field(None, description="Período temporal (ex: '2010-2020')")
    focus_areas: List[str] = Field(default_factory=list, description="Áreas de foco da busca")

class AcademicDataQualityReport(BaseModel):
    """Relatório de qualidade dos dados acadêmicos"""
    profile_id: str = Field(..., description="ID do perfil")
    
    # Completude
    degrees_found: int = Field(0, description="Número de graus encontrados")
    publications_found: int = Field(0, description="Número de publicações encontradas")
    awards_found: int = Field(0, description="Número de prêmios encontrados")
    
    # Qualidade
    institution_verification_rate: float = Field(0.0, description="Taxa de verificação de instituições")
    publication_verification_rate: float = Field(0.0, description="Taxa de verificação de publicações")
    data_consistency_score: float = Field(0.0, description="Score de consistência dos dados")
    
    # Fontes
    perplexity_queries_made: int = Field(0, description="Número de queries feitas à Perplexity")
    external_sources_consulted: List[str] = Field(default_factory=list, description="Fontes externas consultadas")
    
    # Recomendações
    missing_data_areas: List[str] = Field(default_factory=list, description="Áreas com dados faltantes")
    quality_improvement_suggestions: List[str] = Field(default_factory=list, description="Sugestões de melhoria")
    
    # Metadados
    generated_at: datetime = Field(default_factory=datetime.utcnow, description="Data de geração do relatório")
    processing_time_seconds: float = Field(0.0, description="Tempo de processamento em segundos") 
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class InstitutionRank(str, Enum):
    """Rankings de instituições acadêmicas"""
    TOP_10 = "top_10"
    TOP_50 = "top_50"
    TOP_100 = "top_100"
    TOP_500 = "top_500"
    REGIONAL = "regional"
    UNKNOWN = "unknown"

class PublicationTier(str, Enum):
    """Tier/qualidade de publicações acadêmicas"""
    Q1 = "q1"  # Qualis A1/A2
    Q2 = "q2"  # Qualis B1/B2
    Q3 = "q3"  # Qualis B3/B4
    Q4 = "q4"  # Qualis B5/C
    CONFERENCE = "conference"
    BOOK = "book"
    UNKNOWN = "unknown"

class AcademicInstitution(BaseModel):
    """Instituição acadêmica com rankings e reputação"""
    name: str = Field(..., description="Nome da instituição")
    country: str = Field(..., description="País da instituição")
    state: Optional[str] = Field(None, description="Estado/província")
    city: Optional[str] = Field(None, description="Cidade")
    
    # Rankings e reputação
    world_rank: Optional[int] = Field(None, description="Ranking mundial")
    national_rank: Optional[int] = Field(None, description="Ranking nacional")
    regional_rank: Optional[int] = Field(None, description="Ranking regional")
    rank_tier: InstitutionRank = Field(InstitutionRank.UNKNOWN, description="Tier do ranking")
    
    # Scores de reputação
    academic_reputation_score: Optional[float] = Field(None, description="Score de reputação acadêmica (0-100)")
    employer_reputation_score: Optional[float] = Field(None, description="Score de reputação entre empregadores (0-100)")
    research_impact_score: Optional[float] = Field(None, description="Score de impacto de pesquisa (0-100)")
    
    # Especialização em direito
    law_school_rank: Optional[int] = Field(None, description="Ranking específico da faculdade de direito")
    law_program_quality: Optional[float] = Field(None, description="Qualidade do programa de direito (0-10)")
    
    # Metadados
    founded_year: Optional[int] = Field(None, description="Ano de fundação")
    institution_type: Optional[str] = Field(None, description="Tipo (pública, privada, federal, etc.)")
    website_url: Optional[str] = Field(None, description="Website oficial")
    logo_url: Optional[str] = Field(None, description="URL do logo")

class AcademicDegree(BaseModel):
    """Grau acadêmico com detalhes completos"""
    degree_type: str = Field(..., description="Tipo do grau (Bacharel, Mestrado, Doutorado, etc.)")
    degree_name: str = Field(..., description="Nome completo do grau")
    field_of_study: str = Field(..., description="Área de estudo")
    specialization: Optional[str] = Field(None, description="Especialização específica")
    
    # Instituição
    institution: AcademicInstitution = Field(..., description="Dados da instituição")
    
    # Datas e duração
    start_date: Optional[datetime] = Field(None, description="Data de início")
    end_date: Optional[datetime] = Field(None, description="Data de conclusão")
    duration_years: Optional[float] = Field(None, description="Duração em anos")
    
    # Performance acadêmica
    gpa: Optional[float] = Field(None, description="GPA/CRA")
    honors: Optional[str] = Field(None, description="Honras acadêmicas (magna cum laude, etc.)")
    thesis_title: Optional[str] = Field(None, description="Título da tese/dissertação")
    thesis_advisor: Optional[str] = Field(None, description="Orientador")
    
    # Validação
    is_verified: bool = Field(False, description="Se o grau foi verificado")
    verification_source: Optional[str] = Field(None, description="Fonte de verificação")

class AcademicPublication(BaseModel):
    """Publicação acadêmica com métricas de impacto"""
    title: str = Field(..., description="Título da publicação")
    authors: List[str] = Field(..., description="Lista de autores")
    author_position: Optional[int] = Field(None, description="Posição do autor na lista (1=primeiro)")
    
    # Venue/periódico
    venue_name: str = Field(..., description="Nome do periódico/conferência")
    venue_type: str = Field(..., description="Tipo (journal, conference, book, etc.)")
    publication_tier: PublicationTier = Field(PublicationTier.UNKNOWN, description="Tier da publicação")
    
    # Datas
    published_date: Optional[datetime] = Field(None, description="Data de publicação")
    submission_date: Optional[datetime] = Field(None, description="Data de submissão")
    
    # Métricas de impacto
    citation_count: int = Field(0, description="Número de citações")
    h_index_contribution: Optional[float] = Field(None, description="Contribuição para h-index")
    impact_factor: Optional[float] = Field(None, description="Impact factor do periódico")
    
    # Conteúdo
    abstract: Optional[str] = Field(None, description="Resumo/abstract")
    keywords: List[str] = Field(default_factory=list, description="Palavras-chave")
    doi: Optional[str] = Field(None, description="DOI da publicação")
    url: Optional[str] = Field(None, description="URL da publicação")
    
    # Classificação jurídica
    legal_areas: List[str] = Field(default_factory=list, description="Áreas jurídicas abordadas")
    brazilian_law_relevance: Optional[float] = Field(None, description="Relevância para direito brasileiro (0-1)")

class AcademicRecognition(BaseModel):
    """Reconhecimentos e prêmios acadêmicos"""
    award_name: str = Field(..., description="Nome do prêmio/reconhecimento")
    granting_organization: str = Field(..., description="Organização que concedeu")
    award_date: Optional[datetime] = Field(None, description="Data do prêmio")
    award_year: Optional[int] = Field(None, description="Ano do prêmio")
    
    # Detalhes
    description: Optional[str] = Field(None, description="Descrição do prêmio")
    category: Optional[str] = Field(None, description="Categoria do prêmio")
    award_level: Optional[str] = Field(None, description="Nível (nacional, internacional, regional)")
    
    # Relevância
    prestige_score: Optional[float] = Field(None, description="Score de prestígio (0-10)")
    legal_field_relevance: Optional[float] = Field(None, description="Relevância para área jurídica (0-1)")

class AcademicProfile(BaseModel):
    """Perfil acadêmico completo"""
    # Identificação
    full_name: str = Field(..., description="Nome completo")
    alternative_names: List[str] = Field(default_factory=list, description="Nomes alternativos/anteriores")
    
    # Formação acadêmica
    degrees: List[AcademicDegree] = Field(default_factory=list, description="Lista de graus acadêmicos")
    highest_degree: Optional[str] = Field(None, description="Maior grau obtido")
    
    # Publicações e pesquisa
    publications: List[AcademicPublication] = Field(default_factory=list, description="Lista de publicações")
    total_citations: int = Field(0, description="Total de citações")
    h_index: Optional[int] = Field(None, description="Índice H")
    i10_index: Optional[int] = Field(None, description="Índice i10")
    
    # Reconhecimentos
    awards: List[AcademicRecognition] = Field(default_factory=list, description="Prêmios e reconhecimentos")
    
    # Especialização jurídica
    legal_specializations: List[str] = Field(default_factory=list, description="Especializações jurídicas")
    main_research_areas: List[str] = Field(default_factory=list, description="Principais áreas de pesquisa")
    
    # Métricas consolidadas
    academic_prestige_score: float = Field(0.0, description="Score de prestígio acadêmico (0-100)")
    research_productivity_score: float = Field(0.0, description="Score de produtividade em pesquisa (0-100)")
    institution_quality_score: float = Field(0.0, description="Score de qualidade das instituições (0-100)")
    
    # Metadados
    data_sources: List[str] = Field(default_factory=list, description="Fontes dos dados")
    last_updated: datetime = Field(default_factory=datetime.utcnow, description="Última atualização")
    confidence_score: float = Field(0.0, description="Confiança nos dados (0-1)")

class PerplexityAcademicQuery(BaseModel):
    """Query para busca acadêmica via Perplexity"""
    lawyer_name: str = Field(..., description="Nome do advogado")
    institution_hints: List[str] = Field(default_factory=list, description="Dicas de instituições")
    degree_hints: List[str] = Field(default_factory=list, description="Dicas de graus")
    time_period: Optional[str] = Field(None, description="Período temporal (ex: '2010-2020')")
    focus_areas: List[str] = Field(default_factory=list, description="Áreas de foco da busca")

class AcademicDataQualityReport(BaseModel):
    """Relatório de qualidade dos dados acadêmicos"""
    profile_id: str = Field(..., description="ID do perfil")
    
    # Completude
    degrees_found: int = Field(0, description="Número de graus encontrados")
    publications_found: int = Field(0, description="Número de publicações encontradas")
    awards_found: int = Field(0, description="Número de prêmios encontrados")
    
    # Qualidade
    institution_verification_rate: float = Field(0.0, description="Taxa de verificação de instituições")
    publication_verification_rate: float = Field(0.0, description="Taxa de verificação de publicações")
    data_consistency_score: float = Field(0.0, description="Score de consistência dos dados")
    
    # Fontes
    perplexity_queries_made: int = Field(0, description="Número de queries feitas à Perplexity")
    external_sources_consulted: List[str] = Field(default_factory=list, description="Fontes externas consultadas")
    
    # Recomendações
    missing_data_areas: List[str] = Field(default_factory=list, description="Áreas com dados faltantes")
    quality_improvement_suggestions: List[str] = Field(default_factory=list, description="Sugestões de melhoria")
    
    # Metadados
    generated_at: datetime = Field(default_factory=datetime.utcnow, description="Data de geração do relatório")
    processing_time_seconds: float = Field(0.0, description="Tempo de processamento em segundos") 