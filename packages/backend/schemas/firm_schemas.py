from pydantic import BaseModel, Field
from typing import List, Dict, Optional, Any
from datetime import datetime

class DataSourceInfo(BaseModel):
    source_name: str
    last_updated: str
    quality_score: float = Field(ge=0.0, le=1.0)
    has_error: bool = False
    error_message: Optional[str] = None

class FirmCertification(BaseModel):
    name: str
    issuer: str
    valid_until: Optional[str] = None
    certificate_url: Optional[str] = None
    is_active: bool = True

class FirmAward(BaseModel):
    name: str
    category: str
    date_received: str
    issuer: Optional[str] = None
    description: Optional[str] = None

class FirmLocation(BaseModel):
    address: str
    city: str
    state: str
    zip_code: Optional[str] = None
    country: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    is_main_office: bool = True
    nearby_landmarks: List[str] = []

class FirmContactInfo(BaseModel):
    phone: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    linkedin_url: Optional[str] = None
    social_media_urls: List[str] = []
    whatsapp: Optional[str] = None

class FirmFinancialInfo(BaseModel):
    revenue_range: Optional[str] = None
    founded_year: Optional[int] = None
    legal_structure: Optional[str] = None
    is_publicly_traded: bool = False
    stock_symbol: Optional[str] = None
    employee_count: Optional[int] = None
    office_locations: List[str] = []

class FirmPartnership(BaseModel):
    partner_firm_id: str
    partner_firm_name: str
    partnership_type: str
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    is_active: bool = True
    description: Optional[str] = None
    collaboration_areas: List[str] = []

class FirmStats(BaseModel):
    total_cases: int
    active_cases: int
    won_cases: int
    success_rate: float = Field(ge=0.0, le=1.0)
    average_rating: float = Field(ge=0.0, le=5.0)
    total_reviews: int
    average_response_time: float
    cases_this_year: int

class LawyerFeatures(BaseModel):
    successRate: float = Field(ge=0.0, le=1.0, alias="success_rate")
    responseTime: int = Field(alias="response_time")
    softSkills: float = Field(ge=0.0, le=1.0, alias="soft_skills")

class EnrichedLawyer(BaseModel):
    id: str
    nome: str
    avatar_url: str = Field(alias="avatarUrl")
    especialidades: List[str]
    fair: float = Field(ge=0.0, le=1.0)
    features: LawyerFeatures

class EnrichedFirmResponse(BaseModel):
    id: str
    name: str
    description: str
    logo_url: Optional[str] = None
    specializations: List[str] = []
    partners: List[EnrichedLawyer] = []
    associates: List[EnrichedLawyer] = []
    total_lawyers: int
    partners_count: int
    associates_count: int
    specialists_count: int
    specialists_by_area: Dict[str, int] = {}
    certifications: List[FirmCertification] = []
    awards: List[FirmAward] = []
    location: Optional[FirmLocation] = None
    contact_info: Optional[FirmContactInfo] = None
    data_sources: Dict[str, DataSourceInfo] = {}
    overall_quality_score: float = Field(ge=0.0, le=1.0)
    completeness_score: float = Field(ge=0.0, le=1.0)
    last_consolidated: str
    financial_info: Optional[FirmFinancialInfo] = None
    partnerships: List[FirmPartnership] = []
    stats: FirmStats

class FirmTeamStats(BaseModel):
    average_experience: float
    average_success_rate: float = Field(ge=0.0, le=1.0)
    average_response_time: float

class FirmTeamData(BaseModel):
    firm_id: str
    partners: List[EnrichedLawyer] = []
    associates: List[EnrichedLawyer] = []
    total_lawyers: int
    specialists_by_area: Dict[str, int] = {}
    team_stats: FirmTeamStats

class QualityBreakdown(BaseModel):
    excellent: int = Field(description="Sources with quality >= 0.9")
    good: int = Field(description="Sources with quality 0.7-0.9")
    fair: int = Field(description="Sources with quality 0.5-0.7")
    poor: int = Field(description="Sources with quality < 0.5")

class DataCollectionPolicy(BaseModel):
    public_sources_only: bool
    regulatory_compliance: bool
    regular_updates: bool
    user_consent_required: bool

class FirmTransparencyReport(BaseModel):
    firm_id: str
    report_generated_at: str
    data_sources: Dict[str, DataSourceInfo]
    overall_quality_score: float = Field(ge=0.0, le=1.0)
    completeness_score: float = Field(ge=0.0, le=1.0)
    last_update: str
    quality_breakdown: QualityBreakdown
    data_collection_policy: DataCollectionPolicy

class GrowthIndicators(BaseModel):
    cases_this_year: int
    success_rate: float = Field(ge=0.0, le=1.0)
    client_retention: float = Field(ge=0.0, le=1.0)

class FirmFinancialSummary(BaseModel):
    firm_id: str
    revenue_range: Optional[str] = None
    founded_year: Optional[int] = None
    legal_structure: Optional[str] = None
    employee_count: Optional[int] = None
    office_locations: List[str] = []
    market_position: str = Field(description="Leading, Established, Growing, etc.")
    growth_indicators: GrowthIndicators

class FirmSearchResult(BaseModel):
    id: str
    name: str
    specializations: List[str]
    location: str
    team_size: int
    success_rate: float = Field(ge=0.0, le=1.0)
    overall_quality_score: float = Field(ge=0.0, le=1.0)

class FirmSearchResponse(BaseModel):
    firms: List[FirmSearchResult]
    total: int
    limit: int
    offset: int
    has_more: bool

class SpecializationCount(BaseModel):
    specialization: str
    count: int

class DataFreshness(BaseModel):
    last_update: str
    sources_count: int

class EnrichedFirmsStats(BaseModel):
    total_firms: int
    total_lawyers: int
    average_quality_score: float
    top_specializations: Dict[str, int]
    data_freshness: DataFreshness 