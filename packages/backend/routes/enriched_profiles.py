from fastapi import APIRouter, HTTPException, Depends, Query, BackgroundTasks
from fastapi.responses import JSONResponse
from typing import Optional, List
from datetime import datetime
import logging

from ..services.hybrid_legal_data_service_complete import (
    hybrid_legal_data_service,
    DataSourceType,
    ConsolidatedLawyerProfile
)
from ..schemas.linkedin_schemas import (
    LinkedInProfileUpdateRequest,
    LinkedInDataQualityReport
)
from ..schemas.academic_schemas import (
    AcademicDataQualityReport,
    PerplexityAcademicQuery
)
from ..dependencies.auth import get_current_user
from ..dependencies.rate_limiting import rate_limit

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/enriched-profiles", tags=["Enriched Profiles"])

@router.get("/lawyer/{lawyer_id}/complete")
@rate_limit(max_calls=10, window_seconds=60)
async def get_complete_lawyer_profile(
    lawyer_id: str,
    force_refresh: bool = Query(False, description="Forçar atualização de todas as fontes"),
    include_sources: Optional[List[str]] = Query(None, description="Fontes específicas (linkedin,academic,escavador)"),
    background_tasks: BackgroundTasks = BackgroundTasks(),
    current_user = Depends(get_current_user)
):
    """
    Obter perfil completo consolidado de um advogado
    
    Inclui dados de:
    - LinkedIn (formação, experiência, competências, contatos)
    - Perplexity (dados acadêmicos, publicações, rankings)
    - Escavador/JusBrasil (dados processuais)
    - Deep Research (insights de mercado)
    - Dados internos da plataforma
    
    **Exemplo de resposta:**
    ```json
    {
        "lawyer_id": "adv_123",
        "full_name": "Dr. João Silva",
        "linkedin_profile": {
            "education": [...],
            "experience": [...],
            "skills": [...],
            "contact_info": {...}
        },
        "academic_profile": {
            "degrees": [...],
            "publications": [...],
            "academic_prestige_score": 85.2
        },
        "scores": {
            "social_influence_score": 78.5,
            "academic_prestige_score": 85.2,
            "legal_expertise_score": 82.1,
            "overall_success_probability": 81.2
        },
        "data_sources": {...},
        "last_updated": "2024-01-15T10:30:00Z"
    }
    ```
    """
    try:
        logger.info(f"Solicitação de perfil completo: {lawyer_id} por usuário {current_user.get('user_id')}")
        
        # Converter nomes de fontes para enum
        source_types = None
        if include_sources:
            try:
                source_types = [DataSourceType(source) for source in include_sources]
            except ValueError as e:
                raise HTTPException(
                    status_code=400,
                    detail=f"Fonte inválida: {str(e)}. Fontes válidas: {[t.value for t in DataSourceType]}"
                )
        
        # Buscar perfil consolidado
        profile = await hybrid_legal_data_service.get_complete_lawyer_profile(
            lawyer_id=lawyer_id,
            force_refresh=force_refresh,
            include_sources=source_types
        )
        
        if not profile:
            raise HTTPException(
                status_code=404,
                detail=f"Perfil não encontrado para advogado: {lawyer_id}"
            )
        
        # Preparar resposta estruturada
        response_data = {
            "lawyer_id": profile.lawyer_id,
            "full_name": profile.full_name,
            "alternative_names": profile.alternative_names,
            
            # Dados LinkedIn
            "linkedin_profile": _serialize_linkedin_profile(profile.linkedin_profile) if profile.linkedin_profile else None,
            
            # Dados acadêmicos
            "academic_profile": _serialize_academic_profile(profile.academic_profile) if profile.academic_profile else None,
            
            # Dados processuais
            "legal_cases_summary": _serialize_legal_data(profile.legal_cases_data) if profile.legal_cases_data else None,
            
            # Insights de mercado
            "market_insights": profile.market_insights,
            
            # Métricas da plataforma
            "platform_metrics": profile.platform_metrics,
            
            # Scores consolidados
            "scores": {
                "social_influence_score": profile.social_influence_score,
                "academic_prestige_score": profile.academic_prestige_score,
                "legal_expertise_score": profile.legal_expertise_score,
                "market_reputation_score": profile.market_reputation_score,
                "overall_success_probability": profile.overall_success_probability
            },
            
            # Metadados de qualidade
            "data_quality": {
                "overall_quality_score": profile.overall_quality_score,
                "completeness_score": profile.completeness_score,
                "last_consolidated": profile.last_consolidated.isoformat(),
                "consolidation_version": profile.consolidation_version
            },
            
            # Transparência de fontes
            "data_sources": {
                source_type.value: {
                    "last_updated": source_info.last_updated.isoformat(),
                    "quality": source_info.quality.value,
                    "confidence_score": source_info.confidence_score,
                    "fields_available": source_info.fields_available,
                    "cost_per_query": source_info.cost_per_query
                }
                for source_type, source_info in profile.data_sources.items()
            }
        }
        
        # Agendar atualização em background se dados estão antigos
        if not force_refresh and profile.overall_quality_score < 0.8:
            background_tasks.add_task(
                _schedule_profile_refresh,
                lawyer_id,
                current_user.get('user_id')
            )
        
        return JSONResponse(
            status_code=200,
            content=response_data
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar perfil completo {lawyer_id}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor ao buscar perfil"
        )

@router.get("/lawyer/{lawyer_id}/linkedin")
@rate_limit(max_calls=20, window_seconds=60)
async def get_linkedin_profile_detailed(
    lawyer_id: str,
    include_activity: bool = Query(True, description="Incluir atividade recente"),
    include_network: bool = Query(True, description="Incluir métricas de rede"),
    current_user = Depends(get_current_user)
):
    """
    Obter dados detalhados do LinkedIn de um advogado
    
    **Dados incluídos:**
    - Formação acadêmica completa
    - Experiência profissional detalhada
    - Competências com endorsements
    - Certificações
    - Idiomas
    - Informações de contato
    - Métricas de rede profissional
    - Atividade recente (opcional)
    """
    try:
        # Buscar perfil consolidado
        profile = await hybrid_legal_data_service.get_complete_lawyer_profile(
            lawyer_id=lawyer_id,
            include_sources=[DataSourceType.LINKEDIN]
        )
        
        if not profile or not profile.linkedin_profile:
            raise HTTPException(
                status_code=404,
                detail="Perfil LinkedIn não encontrado para este advogado"
            )
        
        linkedin_data = profile.linkedin_profile
        
        # Preparar resposta detalhada
        response_data = {
            "lawyer_id": lawyer_id,
            "linkedin_id": linkedin_data.linkedin_id,
            "profile_url": linkedin_data.profile_url,
            
            # Dados básicos
            "basic_info": {
                "full_name": linkedin_data.full_name,
                "headline": linkedin_data.headline,
                "summary": linkedin_data.summary,
                "location": linkedin_data.location,
                "industry": linkedin_data.industry,
                "profile_picture_url": linkedin_data.profile_picture_url
            },
            
            # Formação acadêmica
            "education": [
                {
                    "institution": edu.institution,
                    "degree_name": edu.degree_name,
                    "field_of_study": edu.field_of_study,
                    "start_date": edu.start_date.isoformat() if edu.start_date else None,
                    "end_date": edu.end_date.isoformat() if edu.end_date else None,
                    "description": edu.description,
                    "logo_url": edu.logo_url
                }
                for edu in linkedin_data.education
            ],
            
            # Experiência profissional
            "experience": [
                {
                    "company_name": exp.company_name,
                    "title": exp.title,
                    "employment_type": exp.employment_type,
                    "location": exp.location,
                    "start_date": exp.start_date.isoformat() if exp.start_date else None,
                    "end_date": exp.end_date.isoformat() if exp.end_date else None,
                    "duration_months": exp.duration_months,
                    "description": exp.description,
                    "is_current": exp.is_current,
                    "company_logo_url": exp.company_logo_url
                }
                for exp in linkedin_data.experience
            ],
            
            # Competências
            "skills": [
                {
                    "name": skill.name,
                    "endorsement_count": skill.endorsement_count,
                    "proficiency_level": skill.proficiency_level.value if skill.proficiency_level else None,
                    "category": skill.category
                }
                for skill in linkedin_data.skills
            ],
            
            # Certificações
            "certifications": [
                {
                    "name": cert.name,
                    "organization": cert.organization,
                    "issue_date": cert.issue_date.isoformat() if cert.issue_date else None,
                    "expiration_date": cert.expiration_date.isoformat() if cert.expiration_date else None,
                    "credential_id": cert.credential_id,
                    "credential_url": cert.credential_url
                }
                for cert in linkedin_data.certifications
            ],
            
            # Idiomas
            "languages": [
                {
                    "name": lang.name,
                    "proficiency": lang.proficiency.value if lang.proficiency else None
                }
                for lang in linkedin_data.languages
            ],
            
            # Informações de contato
            "contact_info": {
                "emails": linkedin_data.contact_info.emails,
                "phone_numbers": linkedin_data.contact_info.phone_numbers,
                "websites": linkedin_data.contact_info.websites,
                "social_networks": linkedin_data.contact_info.social_networks
            } if linkedin_data.contact_info else None,
            
            # Métricas de qualidade
            "data_quality": {
                "data_quality_score": linkedin_data.data_quality_score,
                "completeness_score": linkedin_data.completeness_score,
                "last_updated": linkedin_data.last_updated.isoformat(),
                "source_confidence": linkedin_data.source_confidence
            }
        }
        
        # Incluir métricas de rede se solicitado
        if include_network and linkedin_data.network_metrics:
            response_data["network_metrics"] = {
                "connections_count": linkedin_data.network_metrics.connections_count,
                "followers_count": linkedin_data.network_metrics.followers_count,
                "following_count": linkedin_data.network_metrics.following_count,
                "degree_of_connection": linkedin_data.network_metrics.degree_of_connection
            }
        
        # Incluir atividade recente se solicitado
        if include_activity and linkedin_data.recent_activity:
            response_data["recent_activity"] = [
                {
                    "post_id": activity.post_id,
                    "content": activity.content[:200] + "..." if len(activity.content) > 200 else activity.content,
                    "post_type": activity.post_type,
                    "published_at": activity.published_at.isoformat(),
                    "engagement_metrics": {
                        "likes_count": activity.likes_count,
                        "comments_count": activity.comments_count,
                        "shares_count": activity.shares_count,
                        "engagement_rate": activity.engagement_rate
                    }
                }
                for activity in linkedin_data.recent_activity[:5]  # Últimas 5 atividades
            ]
        
        return JSONResponse(
            status_code=200,
            content=response_data
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar perfil LinkedIn {lawyer_id}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor ao buscar dados LinkedIn"
        )

@router.get("/lawyer/{lawyer_id}/academic")
@rate_limit(max_calls=15, window_seconds=60)
async def get_academic_profile_detailed(
    lawyer_id: str,
    include_publications: bool = Query(True, description="Incluir publicações acadêmicas"),
    include_awards: bool = Query(True, description="Incluir prêmios e reconhecimentos"),
    current_user = Depends(get_current_user)
):
    """
    Obter dados acadêmicos detalhados de um advogado
    
    **Dados incluídos:**
    - Formação acadêmica com rankings de instituições
    - Publicações acadêmicas com métricas de impacto
    - Prêmios e reconhecimentos
    - Scores de prestígio acadêmico
    """
    try:
        # Buscar perfil consolidado
        profile = await hybrid_legal_data_service.get_complete_lawyer_profile(
            lawyer_id=lawyer_id,
            include_sources=[DataSourceType.ACADEMIC]
        )
        
        if not profile or not profile.academic_profile:
            raise HTTPException(
                status_code=404,
                detail="Perfil acadêmico não encontrado para este advogado"
            )
        
        academic_data = profile.academic_profile
        
        # Preparar resposta detalhada
        response_data = {
            "lawyer_id": lawyer_id,
            "full_name": academic_data.full_name,
            "alternative_names": academic_data.alternative_names,
            "highest_degree": academic_data.highest_degree,
            
            # Formação acadêmica
            "degrees": [
                {
                    "degree_type": degree.degree_type,
                    "degree_name": degree.degree_name,
                    "field_of_study": degree.field_of_study,
                    "specialization": degree.specialization,
                    "institution": {
                        "name": degree.institution.name,
                        "country": degree.institution.country,
                        "rank_tier": degree.institution.rank_tier.value,
                        "national_rank": degree.institution.national_rank,
                        "law_school_rank": degree.institution.law_school_rank,
                        "academic_reputation_score": degree.institution.academic_reputation_score
                    },
                    "start_date": degree.start_date.isoformat() if degree.start_date else None,
                    "end_date": degree.end_date.isoformat() if degree.end_date else None,
                    "duration_years": degree.duration_years,
                    "honors": degree.honors,
                    "thesis_title": degree.thesis_title,
                    "is_verified": degree.is_verified
                }
                for degree in academic_data.degrees
            ],
            
            # Especializações jurídicas
            "legal_specializations": academic_data.legal_specializations,
            "main_research_areas": academic_data.main_research_areas,
            
            # Métricas consolidadas
            "academic_metrics": {
                "academic_prestige_score": academic_data.academic_prestige_score,
                "research_productivity_score": academic_data.research_productivity_score,
                "institution_quality_score": academic_data.institution_quality_score,
                "total_citations": academic_data.total_citations,
                "h_index": academic_data.h_index,
                "i10_index": academic_data.i10_index
            },
            
            # Metadados
            "data_quality": {
                "confidence_score": academic_data.confidence_score,
                "last_updated": academic_data.last_updated.isoformat(),
                "data_sources": academic_data.data_sources
            }
        }
        
        # Incluir publicações se solicitado
        if include_publications and academic_data.publications:
            response_data["publications"] = [
                {
                    "title": pub.title,
                    "authors": pub.authors,
                    "author_position": pub.author_position,
                    "venue_name": pub.venue_name,
                    "venue_type": pub.venue_type,
                    "publication_tier": pub.publication_tier.value,
                    "published_date": pub.published_date.isoformat() if pub.published_date else None,
                    "citation_count": pub.citation_count,
                    "impact_factor": pub.impact_factor,
                    "legal_areas": pub.legal_areas,
                    "brazilian_law_relevance": pub.brazilian_law_relevance,
                    "doi": pub.doi,
                    "url": pub.url
                }
                for pub in academic_data.publications
            ]
        
        # Incluir prêmios se solicitado
        if include_awards and academic_data.awards:
            response_data["awards"] = [
                {
                    "award_name": award.award_name,
                    "granting_organization": award.granting_organization,
                    "award_year": award.award_year,
                    "award_level": award.award_level,
                    "description": award.description,
                    "prestige_score": award.prestige_score,
                    "legal_field_relevance": award.legal_field_relevance
                }
                for award in academic_data.awards
            ]
        
        return JSONResponse(
            status_code=200,
            content=response_data
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar perfil acadêmico {lawyer_id}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor ao buscar dados acadêmicos"
        )

@router.get("/lawyer/{lawyer_id}/transparency-report")
@rate_limit(max_calls=5, window_seconds=60)
async def get_data_transparency_report(
    lawyer_id: str,
    current_user = Depends(get_current_user)
):
    """
    Gerar relatório de transparência dos dados
    
    Mostra:
    - Fontes de dados utilizadas
    - Qualidade e confiabilidade de cada fonte
    - Custos de coleta
    - Recomendações de melhoria
    """
    try:
        report = await hybrid_legal_data_service.get_data_transparency_report(lawyer_id)
        
        if "error" in report:
            raise HTTPException(
                status_code=404 if "não encontrado" in report["error"] else 500,
                detail=report["error"]
            )
        
        return JSONResponse(
            status_code=200,
            content=report
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao gerar relatório de transparência {lawyer_id}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor ao gerar relatório"
        )

@router.post("/lawyer/{lawyer_id}/refresh")
@rate_limit(max_calls=3, window_seconds=300)  # Máximo 3 atualizações a cada 5 minutos
async def refresh_lawyer_profile(
    lawyer_id: str,
    request: LinkedInProfileUpdateRequest,
    background_tasks: BackgroundTasks,
    current_user = Depends(get_current_user)
):
    """
    Forçar atualização completa do perfil de um advogado
    
    **Processo:**
    1. Coleta dados frescos de todas as fontes
    2. Reconstrói perfil consolidado
    3. Recalcula scores
    4. Atualiza cache
    
    **Atenção:** Operação custosa, usar com moderação
    """
    try:
        logger.info(f"Iniciando refresh completo para {lawyer_id} por usuário {current_user.get('user_id')}")
        
        # Agendar atualização completa em background
        background_tasks.add_task(
            _perform_complete_refresh,
            lawyer_id,
            request.dict(),
            current_user.get('user_id')
        )
        
        return JSONResponse(
            status_code=202,
            content={
                "message": "Atualização iniciada em background",
                "lawyer_id": lawyer_id,
                "estimated_completion_time": "2-5 minutos",
                "status_endpoint": f"/api/enriched-profiles/lawyer/{lawyer_id}/refresh-status"
            }
        )
        
    except Exception as e:
        logger.error(f"Erro ao iniciar refresh {lawyer_id}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor ao iniciar atualização"
        )

# Funções auxiliares

def _serialize_linkedin_profile(linkedin_profile) -> dict:
    """Serializar perfil LinkedIn para JSON"""
    if not linkedin_profile:
        return None
    
    return {
        "basic_info": {
            "full_name": linkedin_profile.full_name,
            "headline": linkedin_profile.headline,
            "summary": linkedin_profile.summary,
            "location": linkedin_profile.location,
            "industry": linkedin_profile.industry
        },
        "education_count": len(linkedin_profile.education),
        "experience_count": len(linkedin_profile.experience),
        "skills_count": len(linkedin_profile.skills),
        "certifications_count": len(linkedin_profile.certifications),
        "data_quality_score": linkedin_profile.data_quality_score,
        "last_updated": linkedin_profile.last_updated.isoformat()
    }

def _serialize_academic_profile(academic_profile) -> dict:
    """Serializar perfil acadêmico para JSON"""
    if not academic_profile:
        return None
    
    return {
        "highest_degree": academic_profile.highest_degree,
        "degrees_count": len(academic_profile.degrees),
        "publications_count": len(academic_profile.publications),
        "awards_count": len(academic_profile.awards),
        "academic_prestige_score": academic_profile.academic_prestige_score,
        "institution_quality_score": academic_profile.institution_quality_score,
        "research_productivity_score": academic_profile.research_productivity_score,
        "total_citations": academic_profile.total_citations,
        "h_index": academic_profile.h_index,
        "last_updated": academic_profile.last_updated.isoformat()
    }

def _serialize_legal_data(legal_data) -> dict:
    """Serializar dados legais para JSON"""
    if not legal_data:
        return None
    
    # TODO: Implementar serialização específica dos dados legais
    return {
        "summary": "Dados processuais disponíveis",
        "source": "escavador_jusbrasil"
    }

async def _schedule_profile_refresh(lawyer_id: str, user_id: str):
    """Agendar refresh do perfil em background"""
    try:
        logger.info(f"Agendando refresh automático para {lawyer_id}")
        # TODO: Implementar queue de background tasks
        
    except Exception as e:
        logger.error(f"Erro ao agendar refresh: {str(e)}")

async def _perform_complete_refresh(lawyer_id: str, request_data: dict, user_id: str):
    """Executar refresh completo em background"""
    try:
        logger.info(f"Executando refresh completo para {lawyer_id}")
        
        # Forçar atualização de todas as fontes
        profile = await hybrid_legal_data_service.get_complete_lawyer_profile(
            lawyer_id=lawyer_id,
            force_refresh=True
        )
        
        if profile:
            logger.info(f"Refresh completo finalizado para {lawyer_id}. Qualidade: {profile.overall_quality_score:.2f}")
        else:
            logger.error(f"Falha no refresh completo para {lawyer_id}")
            
    except Exception as e:
        logger.error(f"Erro no refresh completo {lawyer_id}: {str(e)}") 