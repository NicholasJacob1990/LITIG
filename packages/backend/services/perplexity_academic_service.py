import asyncio
import logging
import json
import re
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta
import openai
from ..schemas.academic_schemas import (
    AcademicProfile,
    AcademicDegree,
    AcademicInstitution,
    AcademicPublication,
    AcademicRecognition,
    PerplexityAcademicQuery,
    AcademicDataQualityReport,
    InstitutionRank,
    PublicationTier
)
from ..config.settings import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

class PerplexityAcademicService:
    """
    Serviço para coleta de dados acadêmicos via Perplexity API
    
    Características:
    - Busca dados acadêmicos detalhados de advogados
    - Verifica formação, publicações e reconhecimentos
    - Calcula scores de prestígio acadêmico
    - Integração com rankings universitários
    - Cache inteligente para otimização de custos
    """
    
    def __init__(self):
        self.api_key = getattr(settings, 'PERPLEXITY_API_KEY', None)
        self.client = None
        self.cache_ttl_hours = getattr(settings, 'ACADEMIC_CACHE_TTL_HOURS', 24)
        self.max_retries = 3
        self.rate_limit_delay = 1  # segundo entre chamadas
        
        # Templates de busca estruturada
        self.education_query_template = """
        Encontre informações acadêmicas detalhadas sobre {lawyer_name}, advogado(a) brasileiro(a):
        
        1. FORMAÇÃO ACADÊMICA:
        - Graduação em Direito: instituição, ano de conclusão
        - Pós-graduação: especializações, mestrado, doutorado
        - Instituições de ensino: rankings e reputação
        
        2. PUBLICAÇÕES ACADÊMICAS:
        - Artigos em revistas jurídicas
        - Livros e capítulos de livros
        - Teses e dissertações
        - Citações e impacto acadêmico
        
        3. RECONHECIMENTOS:
        - Prêmios acadêmicos
        - Títulos honoríficos
        - Participação em bancas
        - Atividade docente
        
        Foque apenas em informações verificáveis e cite as fontes quando possível.
        Formato de resposta: JSON estruturado.
        """
        
        self.institution_ranking_template = """
        Forneça informações detalhadas sobre a reputação e ranking da instituição {institution_name}:
        
        1. RANKINGS:
        - Ranking nacional e mundial
        - Posição específica em Direito
        - Classificação por agências (MEC, QS, Times Higher Education)
        
        2. REPUTAÇÃO:
        - Score de reputação acadêmica
        - Reconhecimento do mercado
        - Qualidade do corpo docente
        
        3. CARACTERÍSTICAS:
        - Tipo de instituição (pública/privada)
        - Ano de fundação
        - Principais especializações em Direito
        
        Resposta em formato JSON com scores numéricos quando disponíveis.
        """
        
        if self.api_key:
            self._initialize_client()
    
    def _initialize_client(self):
        """Inicializar cliente Perplexity via OpenAI API"""
        try:
            self.client = openai.OpenAI(
                api_key=self.api_key,
                base_url="https://api.perplexity.ai"
            )
            logger.info("Cliente Perplexity inicializado com sucesso")
        except Exception as e:
            logger.error(f"Erro ao inicializar cliente Perplexity: {str(e)}")
            self.client = None
    
    async def get_comprehensive_academic_profile(
        self,
        lawyer_name: str,
        additional_hints: Optional[Dict[str, Any]] = None
    ) -> Optional[AcademicProfile]:
        """
        Obter perfil acadêmico completo via Perplexity
        
        Args:
            lawyer_name: Nome do advogado
            additional_hints: Dicas adicionais (instituições, períodos, etc.)
            
        Returns:
            AcademicProfile completo ou None se falhar
        """
        try:
            if not self.client:
                logger.error("Cliente Perplexity não inicializado")
                return None
            
            logger.info(f"Coletando perfil acadêmico: {lawyer_name}")
            
            # Construir query estruturada
            query = self._build_academic_query(lawyer_name, additional_hints)
            
            # Executar busca via Perplexity
            academic_data = await self._execute_perplexity_search(query)
            
            if not academic_data:
                logger.warning(f"Nenhum dado acadêmico encontrado para: {lawyer_name}")
                return None
            
            # Parse e estruturação dos dados
            profile = await self._parse_academic_data(lawyer_name, academic_data)
            
            # Enriquecimento com dados de instituições
            profile = await self._enrich_institution_data(profile)
            
            # Cálculo de métricas consolidadas
            profile = await self._calculate_academic_scores(profile)
            
            logger.info(f"Perfil acadêmico coletado. Prestígio: {profile.academic_prestige_score:.1f}")
            return profile
            
        except Exception as e:
            logger.error(f"Erro ao coletar perfil acadêmico {lawyer_name}: {str(e)}")
            return None
    
    def _build_academic_query(
        self,
        lawyer_name: str,
        hints: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Construir query estruturada para busca acadêmica
        
        Args:
            lawyer_name: Nome do advogado
            hints: Dicas adicionais para busca
            
        Returns:
            Query estruturada para Perplexity
        """
        try:
            base_query = self.education_query_template.format(lawyer_name=lawyer_name)
            
            if hints:
                # Adicionar contexto específico
                if 'institutions' in hints:
                    base_query += f"\nInstituições conhecidas: {', '.join(hints['institutions'])}"
                
                if 'time_period' in hints:
                    base_query += f"\nPeríodo de interesse: {hints['time_period']}"
                
                if 'specializations' in hints:
                    base_query += f"\nÁreas de especialização: {', '.join(hints['specializations'])}"
            
            return base_query
            
        except Exception as e:
            logger.error(f"Erro ao construir query acadêmica: {str(e)}")
            return self.education_query_template.format(lawyer_name=lawyer_name)
    
    async def _execute_perplexity_search(self, query: str) -> Optional[Dict[str, Any]]:
        """
        Executar busca estruturada via Perplexity API
        
        Args:
            query: Query estruturada
            
        Returns:
            Dados acadêmicos em formato dict
        """
        try:
            # Rate limiting
            await asyncio.sleep(self.rate_limit_delay)
            
            # Executar busca via Perplexity
            response = self.client.chat.completions.create(
                model="llama-3.1-sonar-large-128k-online",
                messages=[
                    {
                        "role": "system",
                        "content": """Você é um especialista em pesquisa acadêmica jurídica brasileira. 
                        Responda sempre em JSON estruturado com informações verificáveis.
                        Foque em dados específicos: nomes de instituições, anos, títulos exatos.
                        Se não encontrar informação, indique claramente."""
                    },
                    {
                        "role": "user",
                        "content": query
                    }
                ],
                temperature=0.1,  # Baixa variabilidade para dados factuais
                max_tokens=2000
            )
            
            content = response.choices[0].message.content
            
            # Tentar extrair JSON da resposta
            json_data = self._extract_json_from_response(content)
            
            if json_data:
                return json_data
            else:
                # Se não for JSON válido, processar como texto estruturado
                return self._parse_text_response(content)
                
        except Exception as e:
            logger.error(f"Erro na busca Perplexity: {str(e)}")
            return None
    
    def _extract_json_from_response(self, content: str) -> Optional[Dict[str, Any]]:
        """Extrair JSON válido da resposta da Perplexity"""
        try:
            # Tentar parse direto
            if content.strip().startswith('{'):
                return json.loads(content)
            
            # Buscar JSON em markdown code blocks
            json_match = re.search(r'```json\s*(\{.*?\})\s*```', content, re.DOTALL)
            if json_match:
                return json.loads(json_match.group(1))
            
            # Buscar JSON sem marcadores
            json_match = re.search(r'(\{.*\})', content, re.DOTALL)
            if json_match:
                return json.loads(json_match.group(1))
            
            return None
            
        except json.JSONDecodeError:
            return None
    
    def _parse_text_response(self, content: str) -> Dict[str, Any]:
        """Parse de resposta em texto estruturado"""
        try:
            data = {
                'education': [],
                'publications': [],
                'awards': [],
                'institutions': []
            }
            
            # Extrair informações de educação
            education_section = re.search(r'FORMAÇÃO ACADÊMICA:(.+?)(?=\n\d+\.|$)', content, re.DOTALL)
            if education_section:
                edu_text = education_section.group(1)
                # Parse básico de graduação e pós-graduação
                grad_match = re.search(r'Graduação.*?:(.*)', edu_text)
                if grad_match:
                    data['education'].append({
                        'type': 'Graduação',
                        'details': grad_match.group(1).strip()
                    })
            
            # Extrair publicações
            pub_section = re.search(r'PUBLICAÇÕES ACADÊMICAS:(.+?)(?=\n\d+\.|$)', content, re.DOTALL)
            if pub_section:
                pub_text = pub_section.group(1)
                publications = re.findall(r'-\s*(.+)', pub_text)
                data['publications'] = [{'title': pub.strip()} for pub in publications]
            
            # Extrair reconhecimentos
            award_section = re.search(r'RECONHECIMENTOS:(.+?)(?=\n\d+\.|$)', content, re.DOTALL)
            if award_section:
                award_text = award_section.group(1)
                awards = re.findall(r'-\s*(.+)', award_text)
                data['awards'] = [{'name': award.strip()} for award in awards]
            
            return data
            
        except Exception as e:
            logger.error(f"Erro ao fazer parse da resposta texto: {str(e)}")
            return {'education': [], 'publications': [], 'awards': [], 'institutions': []}
    
    async def _parse_academic_data(
        self,
        lawyer_name: str,
        raw_data: Dict[str, Any]
    ) -> AcademicProfile:
        """
        Converter dados brutos em AcademicProfile estruturado
        
        Args:
            lawyer_name: Nome do advogado
            raw_data: Dados brutos da Perplexity
            
        Returns:
            AcademicProfile estruturado
        """
        try:
            # Parse graus acadêmicos
            degrees = []
            for edu_data in raw_data.get('education', []):
                if isinstance(edu_data, dict):
                    institution = AcademicInstitution(
                        name=edu_data.get('institution', 'Não informado'),
                        country='Brasil',
                        rank_tier=InstitutionRank.UNKNOWN
                    )
                    
                    degree = AcademicDegree(
                        degree_type=edu_data.get('type', 'Graduação'),
                        degree_name=edu_data.get('degree_name', 'Bacharel em Direito'),
                        field_of_study=edu_data.get('field', 'Direito'),
                        institution=institution,
                        start_date=self._parse_date(edu_data.get('start_year')),
                        end_date=self._parse_date(edu_data.get('end_year'))
                    )
                    degrees.append(degree)
            
            # Parse publicações
            publications = []
            for pub_data in raw_data.get('publications', []):
                if isinstance(pub_data, dict):
                    publication = AcademicPublication(
                        title=pub_data.get('title', ''),
                        authors=[lawyer_name],
                        venue_name=pub_data.get('venue', 'Não informado'),
                        venue_type=pub_data.get('type', 'journal'),
                        publication_tier=PublicationTier.UNKNOWN,
                        published_date=self._parse_date(pub_data.get('year'))
                    )
                    publications.append(publication)
            
            # Parse reconhecimentos
            awards = []
            for award_data in raw_data.get('awards', []):
                if isinstance(award_data, dict):
                    award = AcademicRecognition(
                        award_name=award_data.get('name', ''),
                        granting_organization=award_data.get('organization', 'Não informado'),
                        award_year=award_data.get('year'),
                        description=award_data.get('description')
                    )
                    awards.append(award)
            
            # Construir perfil
            profile = AcademicProfile(
                full_name=lawyer_name,
                degrees=degrees,
                publications=publications,
                awards=awards,
                data_sources=['perplexity'],
                last_updated=datetime.utcnow(),
                confidence_score=0.7  # Confiança média para dados Perplexity
            )
            
            return profile
            
        except Exception as e:
            logger.error(f"Erro ao fazer parse dos dados acadêmicos: {str(e)}")
            # Retornar perfil básico em caso de erro
            return AcademicProfile(
                full_name=lawyer_name,
                data_sources=['perplexity_error'],
                last_updated=datetime.utcnow(),
                confidence_score=0.0
            )
    
    async def _enrich_institution_data(self, profile: AcademicProfile) -> AcademicProfile:
        """
        Enriquecer dados das instituições com rankings e reputação
        
        Args:
            profile: Perfil acadêmico base
            
        Returns:
            Perfil com dados de instituições enriquecidos
        """
        try:
            for degree in profile.degrees:
                if degree.institution.name and degree.institution.name != 'Não informado':
                    # Buscar dados detalhados da instituição
                    institution_data = await self._get_institution_details(degree.institution.name)
                    
                    if institution_data:
                        # Atualizar dados da instituição
                        degree.institution.world_rank = institution_data.get('world_rank')
                        degree.institution.national_rank = institution_data.get('national_rank')
                        degree.institution.rank_tier = self._determine_rank_tier(institution_data)
                        degree.institution.academic_reputation_score = institution_data.get('reputation_score')
                        degree.institution.law_school_rank = institution_data.get('law_rank')
                        degree.institution.institution_type = institution_data.get('type')
                        degree.institution.founded_year = institution_data.get('founded_year')
            
            return profile
            
        except Exception as e:
            logger.error(f"Erro ao enriquecer dados de instituições: {str(e)}")
            return profile
    
    async def _get_institution_details(self, institution_name: str) -> Optional[Dict[str, Any]]:
        """
        Obter detalhes específicos de uma instituição via Perplexity
        
        Args:
            institution_name: Nome da instituição
            
        Returns:
            Dados detalhados da instituição
        """
        try:
            query = self.institution_ranking_template.format(institution_name=institution_name)
            
            # Rate limiting
            await asyncio.sleep(self.rate_limit_delay)
            
            response = self.client.chat.completions.create(
                model="llama-3.1-sonar-large-128k-online",
                messages=[
                    {
                        "role": "system",
                        "content": """Especialista em rankings universitários brasileiros. 
                        Responda em JSON com dados numéricos precisos sobre rankings e reputação."""
                    },
                    {
                        "role": "user",
                        "content": query
                    }
                ],
                temperature=0.1,
                max_tokens=1000
            )
            
            content = response.choices[0].message.content
            return self._extract_json_from_response(content)
            
        except Exception as e:
            logger.error(f"Erro ao buscar dados da instituição {institution_name}: {str(e)}")
            return None
    
    def _determine_rank_tier(self, institution_data: Dict[str, Any]) -> InstitutionRank:
        """Determinar tier de ranking baseado nos dados"""
        try:
            national_rank = institution_data.get('national_rank')
            world_rank = institution_data.get('world_rank')
            
            if national_rank:
                if national_rank <= 10:
                    return InstitutionRank.TOP_10
                elif national_rank <= 50:
                    return InstitutionRank.TOP_50
                elif national_rank <= 100:
                    return InstitutionRank.TOP_100
                elif national_rank <= 500:
                    return InstitutionRank.TOP_500
                else:
                    return InstitutionRank.REGIONAL
            
            if world_rank:
                if world_rank <= 100:
                    return InstitutionRank.TOP_100
                elif world_rank <= 500:
                    return InstitutionRank.TOP_500
                else:
                    return InstitutionRank.REGIONAL
            
            return InstitutionRank.UNKNOWN
            
        except Exception:
            return InstitutionRank.UNKNOWN
    
    async def _calculate_academic_scores(self, profile: AcademicProfile) -> AcademicProfile:
        """
        Calcular scores consolidados de prestígio acadêmico
        
        Args:
            profile: Perfil acadêmico
            
        Returns:
            Perfil com scores calculados
        """
        try:
            # Score de prestígio das instituições
            institution_score = 0.0
            if profile.degrees:
                for degree in profile.degrees:
                    tier_scores = {
                        InstitutionRank.TOP_10: 100,
                        InstitutionRank.TOP_50: 80,
                        InstitutionRank.TOP_100: 60,
                        InstitutionRank.TOP_500: 40,
                        InstitutionRank.REGIONAL: 20,
                        InstitutionRank.UNKNOWN: 10
                    }
                    institution_score += tier_scores.get(degree.institution.rank_tier, 10)
                
                institution_score = min(institution_score / len(profile.degrees), 100)
            
            # Score de produtividade em pesquisa
            research_score = 0.0
            if profile.publications:
                # Base score por publicação
                research_score = min(len(profile.publications) * 10, 70)
                
                # Bonus por qualidade das publicações
                quality_bonus = 0
                for pub in profile.publications:
                    tier_bonus = {
                        PublicationTier.Q1: 15,
                        PublicationTier.Q2: 10,
                        PublicationTier.Q3: 5,
                        PublicationTier.Q4: 2,
                        PublicationTier.CONFERENCE: 3,
                        PublicationTier.BOOK: 8
                    }
                    quality_bonus += tier_bonus.get(pub.publication_tier, 1)
                
                research_score = min(research_score + quality_bonus, 100)
            
            # Score de prestígio geral (média ponderada)
            prestige_score = (
                institution_score * 0.6 +  # 60% qualidade das instituições
                research_score * 0.3 +      # 30% produtividade em pesquisa
                len(profile.awards) * 2      # 10% reconhecimentos (max 20 pontos)
            )
            prestige_score = min(prestige_score, 100)
            
            # Atualizar perfil
            profile.institution_quality_score = institution_score
            profile.research_productivity_score = research_score
            profile.academic_prestige_score = prestige_score
            
            return profile
            
        except Exception as e:
            logger.error(f"Erro ao calcular scores acadêmicos: {str(e)}")
            profile.institution_quality_score = 0.0
            profile.research_productivity_score = 0.0
            profile.academic_prestige_score = 0.0
            return profile
    
    def _parse_date(self, date_input: Any) -> Optional[datetime]:
        """Parse flexível de datas"""
        if not date_input:
            return None
        
        try:
            if isinstance(date_input, int):
                # Assumir que é um ano
                return datetime(date_input, 1, 1)
            
            if isinstance(date_input, str):
                # Tentar vários formatos
                formats = ['%Y', '%Y-%m', '%Y-%m-%d']
                for fmt in formats:
                    try:
                        return datetime.strptime(date_input, fmt)
                    except ValueError:
                        continue
            
            return None
            
        except Exception:
            return None
    
    async def generate_quality_report(self, profile: AcademicProfile) -> AcademicDataQualityReport:
        """
        Gerar relatório de qualidade dos dados acadêmicos
        
        Args:
            profile: Perfil acadêmico para análise
            
        Returns:
            Relatório de qualidade
        """
        try:
            # Análise de completude
            degrees_found = len(profile.degrees)
            publications_found = len(profile.publications)
            awards_found = len(profile.awards)
            
            # Taxa de verificação das instituições
            verified_institutions = sum(1 for degree in profile.degrees 
                                      if degree.institution.rank_tier != InstitutionRank.UNKNOWN)
            institution_verification_rate = (verified_institutions / degrees_found 
                                           if degrees_found > 0 else 0.0)
            
            # Taxa de verificação das publicações
            verified_publications = sum(1 for pub in profile.publications 
                                      if pub.publication_tier != PublicationTier.UNKNOWN)
            publication_verification_rate = (verified_publications / publications_found 
                                           if publications_found > 0 else 0.0)
            
            # Identificar áreas faltantes
            missing_areas = []
            if degrees_found == 0:
                missing_areas.append("Formação acadêmica")
            if publications_found == 0:
                missing_areas.append("Publicações acadêmicas")
            if awards_found == 0:
                missing_areas.append("Reconhecimentos e prêmios")
            
            # Sugestões de melhoria
            suggestions = []
            if institution_verification_rate < 0.5:
                suggestions.append("Melhorar verificação de rankings das instituições")
            if publication_verification_rate < 0.5:
                suggestions.append("Verificar qualidade e classificação das publicações")
            if profile.confidence_score < 0.8:
                suggestions.append("Buscar fontes adicionais para validação")
            
            report = AcademicDataQualityReport(
                profile_id=profile.full_name,
                degrees_found=degrees_found,
                publications_found=publications_found,
                awards_found=awards_found,
                institution_verification_rate=institution_verification_rate,
                publication_verification_rate=publication_verification_rate,
                data_consistency_score=profile.confidence_score,
                perplexity_queries_made=2,  # Estimativa
                external_sources_consulted=profile.data_sources,
                missing_data_areas=missing_areas,
                quality_improvement_suggestions=suggestions,
                processing_time_seconds=0.0  # Será calculado externamente
            )
            
            return report
            
        except Exception as e:
            logger.error(f"Erro ao gerar relatório de qualidade: {str(e)}")
            raise

# Instância global do serviço
perplexity_academic_service = PerplexityAcademicService() 