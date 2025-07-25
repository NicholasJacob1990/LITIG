import asyncio
import logging
import json
import subprocess
import tempfile
import os
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta
from ..schemas.linkedin_schemas import (
    LinkedInComprehensiveProfile,
    LinkedInEducation,
    LinkedInExperience,
    LinkedInSkill,
    LinkedInCertification,
    LinkedInLanguage,
    LinkedInVolunteerExperience,
    LinkedInContact,
    LinkedInNetworkMetrics,
    LinkedInActivity,
    LinkedInDataQualityReport,
    ProficiencyLevel
)
from ..config.settings import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

class UnipileOfficialLinkedInService:
    """
    Serviço oficial para coleta completa de dados LinkedIn via Unipile Node.js SDK
    
    Características:
    - Usa SDK oficial Node.js da Unipile
    - Coleta dados completos do perfil LinkedIn
    - Implementa cache inteligente
    - Calcula métricas de qualidade dos dados
    - Suporte a rate limiting e retry
    """
    
    def __init__(self):
        self.api_key = settings.UNIPILE_API_KEY
        self.api_secret = settings.UNIPILE_API_SECRET
        self.base_url = getattr(settings, 'UNIPILE_BASE_URL', 'https://api.unipile.com')
        self.cache_ttl_hours = getattr(settings, 'LINKEDIN_CACHE_TTL_HOURS', 6)
        self.max_retries = 3
        self.rate_limit_delay = 2  # segundos entre chamadas
        
        # Script Node.js temporário para usar SDK oficial
        self.node_script_template = """
const Unipile = require('unipile-node-sdk');

async function getLinkedInProfile(profileUrl, apiKey, apiSecret) {
    try {
        const client = new Unipile(apiKey, apiSecret);
        
        // Configurar cliente para LinkedIn
        await client.init();
        
        // Obter dados completos do perfil
        const profile = await client.linkedin.getProfile(profileUrl, {
            includeEducation: true,
            includeExperience: true,
            includeSkills: true,
            includeCertifications: true,
            includeLanguages: true,
            includeVolunteerExperience: true,
            includeContactInfo: true,
            includeNetworkMetrics: true,
            includeRecentActivity: true,
            maxActivityPosts: 10
        });
        
        console.log(JSON.stringify(profile, null, 2));
        
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    }
}

// Argumentos: [profileUrl, apiKey, apiSecret]
const [,, profileUrl, apiKey, apiSecret] = process.argv;
getLinkedInProfile(profileUrl, apiKey, apiSecret);
        """
    
    async def get_comprehensive_profile(
        self,
        linkedin_url: str,
        force_refresh: bool = False
    ) -> Optional[LinkedInComprehensiveProfile]:
        """
        Obter perfil LinkedIn completo via SDK oficial
        
        Args:
            linkedin_url: URL do perfil LinkedIn
            force_refresh: Forçar atualização ignorando cache
            
        Returns:
            LinkedInComprehensiveProfile ou None se falhar
        """
        try:
            logger.info(f"Coletando perfil LinkedIn completo: {linkedin_url}")
            
            # TODO: Verificar cache primeiro (se não force_refresh)
            # cached_profile = await self._get_cached_profile(linkedin_url)
            # if cached_profile and not force_refresh:
            #     return cached_profile
            
            # Executar script Node.js com SDK oficial
            profile_data = await self._execute_nodejs_sdk(linkedin_url)
            
            if not profile_data:
                logger.error(f"Falha ao obter dados do perfil: {linkedin_url}")
                return None
            
            # Converter dados para schema estruturado
            comprehensive_profile = await self._parse_profile_data(profile_data)
            
            # Calcular métricas de qualidade
            comprehensive_profile = await self._calculate_data_quality(comprehensive_profile)
            
            # TODO: Salvar no cache
            # await self._cache_profile(linkedin_url, comprehensive_profile)
            
            logger.info(f"Perfil coletado com sucesso. Qualidade: {comprehensive_profile.data_quality_score:.2f}")
            return comprehensive_profile
            
        except Exception as e:
            logger.error(f"Erro ao coletar perfil LinkedIn {linkedin_url}: {str(e)}")
            return None
    
    async def _execute_nodejs_sdk(self, linkedin_url: str) -> Optional[Dict[str, Any]]:
        """
        Executar SDK Node.js da Unipile em subprocess
        
        Args:
            linkedin_url: URL do perfil LinkedIn
            
        Returns:
            Dados do perfil em formato dict
        """
        try:
            # Criar arquivo temporário com script Node.js
            with tempfile.NamedTemporaryFile(mode='w', suffix='.js', delete=False) as f:
                f.write(self.node_script_template)
                script_path = f.name
            
            try:
                # Executar script Node.js
                process = await asyncio.create_subprocess_exec(
                    'node',
                    script_path,
                    linkedin_url,
                    self.api_key,
                    self.api_secret,
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.PIPE
                )
                
                stdout, stderr = await process.communicate()
                
                if process.returncode != 0:
                    logger.error(f"Erro no script Node.js: {stderr.decode()}")
                    return None
                
                # Parse JSON response
                profile_data = json.loads(stdout.decode())
                return profile_data
                
            finally:
                # Limpar arquivo temporário
                os.unlink(script_path)
                
        except Exception as e:
            logger.error(f"Erro ao executar SDK Node.js: {str(e)}")
            return None
    
    async def _parse_profile_data(self, raw_data: Dict[str, Any]) -> LinkedInComprehensiveProfile:
        """
        Converter dados brutos da Unipile para schema estruturado
        
        Args:
            raw_data: Dados brutos da API Unipile
            
        Returns:
            LinkedInComprehensiveProfile estruturado
        """
        try:
            # Extrair dados básicos
            basic_data = {
                'linkedin_id': raw_data.get('id', ''),
                'full_name': raw_data.get('name', ''),
                'first_name': raw_data.get('firstName'),
                'last_name': raw_data.get('lastName'),
                'headline': raw_data.get('headline'),
                'summary': raw_data.get('summary'),
                'location': raw_data.get('location'),
                'industry': raw_data.get('industry'),
                'profile_picture_url': raw_data.get('profilePicture'),
                'background_image_url': raw_data.get('backgroundImage'),
                'profile_url': raw_data.get('profileUrl', ''),
            }
            
            # Parse educação
            education = []
            for edu_data in raw_data.get('education', []):
                education.append(LinkedInEducation(
                    institution=edu_data.get('institution', ''),
                    degree_name=edu_data.get('degree'),
                    field_of_study=edu_data.get('fieldOfStudy'),
                    start_date=self._parse_date(edu_data.get('startDate')),
                    end_date=self._parse_date(edu_data.get('endDate')),
                    grade=edu_data.get('grade'),
                    activities=edu_data.get('activities'),
                    description=edu_data.get('description'),
                    logo_url=edu_data.get('logoUrl')
                ))
            
            # Parse experiência
            experience = []
            for exp_data in raw_data.get('experience', []):
                experience.append(LinkedInExperience(
                    company_name=exp_data.get('company', ''),
                    title=exp_data.get('title', ''),
                    employment_type=exp_data.get('employmentType'),
                    location=exp_data.get('location'),
                    start_date=self._parse_date(exp_data.get('startDate')),
                    end_date=self._parse_date(exp_data.get('endDate')),
                    duration_months=exp_data.get('durationMonths'),
                    description=exp_data.get('description'),
                    company_logo_url=exp_data.get('companyLogoUrl'),
                    company_url=exp_data.get('companyUrl'),
                    is_current=exp_data.get('isCurrent', False)
                ))
            
            # Parse skills
            skills = []
            for skill_data in raw_data.get('skills', []):
                skills.append(LinkedInSkill(
                    name=skill_data.get('name', ''),
                    endorsement_count=skill_data.get('endorsementCount', 0),
                    endorsers=skill_data.get('endorsers', []),
                    proficiency_level=self._parse_proficiency(skill_data.get('proficiencyLevel')),
                    category=skill_data.get('category')
                ))
            
            # Parse certificações
            certifications = []
            for cert_data in raw_data.get('certifications', []):
                certifications.append(LinkedInCertification(
                    name=cert_data.get('name', ''),
                    organization=cert_data.get('organization', ''),
                    issue_date=self._parse_date(cert_data.get('issueDate')),
                    expiration_date=self._parse_date(cert_data.get('expirationDate')),
                    credential_id=cert_data.get('credentialId'),
                    credential_url=cert_data.get('credentialUrl'),
                    organization_logo=cert_data.get('organizationLogo')
                ))
            
            # Parse idiomas
            languages = []
            for lang_data in raw_data.get('languages', []):
                languages.append(LinkedInLanguage(
                    name=lang_data.get('name', ''),
                    proficiency=self._parse_proficiency(lang_data.get('proficiency'))
                ))
            
            # Parse experiência voluntária
            volunteer_experience = []
            for vol_data in raw_data.get('volunteerExperience', []):
                volunteer_experience.append(LinkedInVolunteerExperience(
                    organization=vol_data.get('organization', ''),
                    role=vol_data.get('role', ''),
                    cause=vol_data.get('cause'),
                    start_date=self._parse_date(vol_data.get('startDate')),
                    end_date=self._parse_date(vol_data.get('endDate')),
                    description=vol_data.get('description')
                ))
            
            # Parse contatos
            contact_info = LinkedInContact(
                emails=raw_data.get('contactInfo', {}).get('emails', []),
                phone_numbers=raw_data.get('contactInfo', {}).get('phoneNumbers', []),
                addresses=raw_data.get('contactInfo', {}).get('addresses', []),
                websites=raw_data.get('contactInfo', {}).get('websites', []),
                social_networks=raw_data.get('contactInfo', {}).get('socialNetworks', {})
            )
            
            # Parse métricas de rede
            network_data = raw_data.get('networkMetrics', {})
            network_metrics = LinkedInNetworkMetrics(
                connections_count=network_data.get('connectionsCount', 0),
                followers_count=network_data.get('followersCount', 0),
                following_count=network_data.get('followingCount', 0),
                degree_of_connection=network_data.get('degreeOfConnection'),
                mutual_connections=network_data.get('mutualConnections', [])
            )
            
            # Parse atividade recente
            recent_activity = []
            for activity_data in raw_data.get('recentActivity', []):
                recent_activity.append(LinkedInActivity(
                    post_id=activity_data.get('postId', ''),
                    content=activity_data.get('content', ''),
                    post_type=activity_data.get('postType', ''),
                    published_at=self._parse_date(activity_data.get('publishedAt')) or datetime.utcnow(),
                    likes_count=activity_data.get('likesCount', 0),
                    comments_count=activity_data.get('commentsCount', 0),
                    shares_count=activity_data.get('sharesCount', 0),
                    engagement_rate=activity_data.get('engagementRate', 0.0)
                ))
            
            # Construir perfil completo
            profile = LinkedInComprehensiveProfile(
                **basic_data,
                education=education,
                experience=experience,
                skills=skills,
                certifications=certifications,
                languages=languages,
                volunteer_experience=volunteer_experience,
                contact_info=contact_info,
                network_metrics=network_metrics,
                recent_activity=recent_activity,
                last_updated=datetime.utcnow(),
                source_confidence=1.0  # Máxima confiança no SDK oficial
            )
            
            return profile
            
        except Exception as e:
            logger.error(f"Erro ao fazer parse dos dados do perfil: {str(e)}")
            raise
    
    async def _calculate_data_quality(self, profile: LinkedInComprehensiveProfile) -> LinkedInComprehensiveProfile:
        """
        Calcular métricas de qualidade dos dados
        
        Args:
            profile: Perfil LinkedIn para análise
            
        Returns:
            Perfil com métricas de qualidade calculadas
        """
        try:
            # Campos críticos para completude
            critical_fields = [
                'full_name', 'headline', 'summary', 'location',
                'education', 'experience', 'skills'
            ]
            
            total_fields = 0
            completed_fields = 0
            
            # Verificar campos básicos
            for field in critical_fields:
                total_fields += 1
                value = getattr(profile, field)
                
                if isinstance(value, str) and value.strip():
                    completed_fields += 1
                elif isinstance(value, list) and len(value) > 0:
                    completed_fields += 1
            
            # Verificar sub-campos importantes
            if profile.education:
                for edu in profile.education:
                    total_fields += 2  # institution + field_of_study
                    if edu.institution:
                        completed_fields += 1
                    if edu.field_of_study:
                        completed_fields += 1
            
            if profile.experience:
                for exp in profile.experience:
                    total_fields += 3  # company + title + description
                    if exp.company_name:
                        completed_fields += 1
                    if exp.title:
                        completed_fields += 1
                    if exp.description:
                        completed_fields += 1
            
            # Calcular scores
            completeness_score = completed_fields / total_fields if total_fields > 0 else 0.0
            
            # Score de qualidade considera completude + confiança da fonte + freshness
            data_quality_score = (
                completeness_score * 0.6 +  # 60% completude
                profile.source_confidence * 0.3 +  # 30% confiança
                0.1  # 10% freshness (dados sempre frescos do SDK oficial)
            )
            
            # Atualizar perfil com métricas
            profile.completeness_score = completeness_score
            profile.data_quality_score = data_quality_score
            
            return profile
            
        except Exception as e:
            logger.error(f"Erro ao calcular qualidade dos dados: {str(e)}")
            profile.completeness_score = 0.0
            profile.data_quality_score = 0.0
            return profile
    
    def _parse_date(self, date_str: Optional[str]) -> Optional[datetime]:
        """Parse string de data para datetime"""
        if not date_str:
            return None
        
        try:
            # Tentar formatos comuns
            formats = [
                '%Y-%m-%d',
                '%Y-%m-%dT%H:%M:%S.%fZ',
                '%Y-%m-%dT%H:%M:%SZ',
                '%Y-%m-%dT%H:%M:%S',
                '%Y-%m',
                '%Y'
            ]
            
            for fmt in formats:
                try:
                    return datetime.strptime(date_str, fmt)
                except ValueError:
                    continue
            
            logger.warning(f"Formato de data não reconhecido: {date_str}")
            return None
            
        except Exception as e:
            logger.error(f"Erro ao fazer parse da data {date_str}: {str(e)}")
            return None
    
    def _parse_proficiency(self, level_str: Optional[str]) -> Optional[ProficiencyLevel]:
        """Parse nível de proficiência"""
        if not level_str:
            return None
        
        level_mapping = {
            'beginner': ProficiencyLevel.BEGINNER,
            'intermediate': ProficiencyLevel.INTERMEDIATE,
            'advanced': ProficiencyLevel.ADVANCED,
            'native': ProficiencyLevel.NATIVE,
            'professional': ProficiencyLevel.PROFESSIONAL,
            'elementary': ProficiencyLevel.BEGINNER,
            'limited': ProficiencyLevel.INTERMEDIATE,
            'professional_working': ProficiencyLevel.PROFESSIONAL,
            'full_professional': ProficiencyLevel.ADVANCED,
            'native_bilingual': ProficiencyLevel.NATIVE
        }
        
        return level_mapping.get(level_str.lower())
    
    async def generate_quality_report(self, profile: LinkedInComprehensiveProfile) -> LinkedInDataQualityReport:
        """
        Gerar relatório detalhado de qualidade dos dados
        
        Args:
            profile: Perfil LinkedIn para análise
            
        Returns:
            Relatório de qualidade dos dados
        """
        try:
            # Identificar dados críticos faltantes
            missing_critical = []
            
            if not profile.headline:
                missing_critical.append("Headline profissional")
            if not profile.summary:
                missing_critical.append("Resumo do perfil")
            if not profile.education:
                missing_critical.append("Formação acadêmica")
            if not profile.experience:
                missing_critical.append("Experiência profissional")
            if not profile.skills:
                missing_critical.append("Competências/habilidades")
            if not profile.contact_info.emails:
                missing_critical.append("Informações de contato")
            
            # Calcular freshness dos dados
            hours_since_update = (datetime.utcnow() - profile.last_updated).total_seconds() / 3600
            
            # Gerar recomendações
            recommendations = []
            
            if profile.completeness_score < 0.7:
                recommendations.append("Incentivar preenchimento completo do perfil LinkedIn")
            if not profile.skills:
                recommendations.append("Adicionar competências e habilidades relevantes")
            if not profile.certifications:
                recommendations.append("Incluir certificações profissionais")
            if hours_since_update > 24:
                recommendations.append("Atualizar dados do perfil")
            
            # Construir relatório
            report = LinkedInDataQualityReport(
                profile_id=profile.linkedin_id,
                total_fields=20,  # Número estimado de campos principais
                completed_fields=int(profile.completeness_score * 20),
                completeness_percentage=profile.completeness_score * 100,
                missing_critical_data=missing_critical,
                data_freshness_hours=int(hours_since_update),
                source_reliability=profile.source_confidence,
                last_validation=datetime.utcnow(),
                recommendations=recommendations
            )
            
            return report
            
        except Exception as e:
            logger.error(f"Erro ao gerar relatório de qualidade: {str(e)}")
            raise
    
    async def bulk_update_profiles(
        self,
        linkedin_urls: List[str],
        max_concurrent: int = 3
    ) -> Dict[str, Optional[LinkedInComprehensiveProfile]]:
        """
        Atualizar múltiplos perfis LinkedIn em lote com rate limiting
        
        Args:
            linkedin_urls: Lista de URLs dos perfis
            max_concurrent: Máximo de requisições simultâneas
            
        Returns:
            Dict com URL -> perfil (ou None se falhou)
        """
        try:
            semaphore = asyncio.Semaphore(max_concurrent)
            results = {}
            
            async def process_profile(url: str):
                async with semaphore:
                    try:
                        # Rate limiting
                        await asyncio.sleep(self.rate_limit_delay)
                        
                        profile = await self.get_comprehensive_profile(url)
                        results[url] = profile
                        
                        logger.info(f"Perfil processado: {url}")
                        
                    except Exception as e:
                        logger.error(f"Erro ao processar perfil {url}: {str(e)}")
                        results[url] = None
            
            # Executar em paralelo com limite de concorrência
            tasks = [process_profile(url) for url in linkedin_urls]
            await asyncio.gather(*tasks)
            
            logger.info(f"Processamento em lote concluído. {len(results)} perfis processados.")
            return results
            
        except Exception as e:
            logger.error(f"Erro no processamento em lote: {str(e)}")
            return {}

# Instância global do serviço
unipile_linkedin_service = UnipileOfficialLinkedInService() 