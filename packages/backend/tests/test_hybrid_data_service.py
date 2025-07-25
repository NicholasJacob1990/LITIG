import pytest
import asyncio
from unittest.mock import Mock, AsyncMock, patch
from datetime import datetime, timedelta
from typing import Dict, Any

from ..services.hybrid_legal_data_service_complete import (
    HybridLegalDataServiceComplete,
    DataSourceType,
    DataQuality,
    ConsolidatedLawyerProfile,
    DataSourceInfo
)
from ..schemas.linkedin_schemas import LinkedInComprehensiveProfile
from ..schemas.academic_schemas import AcademicProfile

class TestHybridLegalDataServiceComplete:
    """Testes para o serviço híbrido completo de dados legais"""
    
    @pytest.fixture
    def service(self):
        """Fixture do serviço híbrido"""
        return HybridLegalDataServiceComplete()
    
    @pytest.fixture
    def mock_linkedin_profile(self):
        """Mock de perfil LinkedIn completo"""
        return LinkedInComprehensiveProfile(
            linkedin_id="linkedin_123",
            full_name="Dr. João Silva",
            profile_url="https://linkedin.com/in/joao-silva",
            headline="Advogado Especialista em Direito Civil",
            education=[],
            experience=[],
            skills=[],
            certifications=[],
            languages=[],
            volunteer_experience=[],
            recent_activity=[],
            data_quality_score=0.85,
            completeness_score=0.80,
            source_confidence=1.0
        )
    
    @pytest.fixture
    def mock_academic_profile(self):
        """Mock de perfil acadêmico"""
        return AcademicProfile(
            full_name="Dr. João Silva",
            degrees=[],
            publications=[],
            awards=[],
            academic_prestige_score=75.0,
            research_productivity_score=60.0,
            institution_quality_score=80.0,
            confidence_score=0.75
        )
    
    @pytest.fixture
    def mock_lawyer_basic_info(self):
        """Mock de informações básicas do advogado"""
        return {
            'id': 'adv_123',
            'name': 'Dr. João Silva',
            'oab_number': '123456/SP',
            'email': 'joao.silva@advogado.com',
            'linkedin_url': 'https://linkedin.com/in/joao-silva'
        }

    @pytest.mark.asyncio
    async def test_get_complete_lawyer_profile_success(
        self, 
        service, 
        mock_lawyer_basic_info,
        mock_linkedin_profile,
        mock_academic_profile
    ):
        """Testa coleta completa de perfil com sucesso"""
        
        # Mock das fontes de dados
        with patch.object(service, '_get_lawyer_basic_info', return_value=mock_lawyer_basic_info), \
             patch.object(service, '_collect_multi_source_data') as mock_collect, \
             patch.object(service, '_consolidate_collected_data') as mock_consolidate, \
             patch.object(service, '_calculate_final_scores') as mock_calculate, \
             patch.object(service, '_cache_consolidated_profile') as mock_cache:
            
            # Setup mock return values
            mock_source_results = {
                DataSourceType.LINKEDIN: (mock_linkedin_profile, DataSourceInfo(
                    source_type=DataSourceType.LINKEDIN,
                    last_updated=datetime.utcnow(),
                    quality=DataQuality.HIGH,
                    confidence_score=0.85,
                    fields_available=['education', 'experience', 'skills']
                )),
                DataSourceType.ACADEMIC: (mock_academic_profile, DataSourceInfo(
                    source_type=DataSourceType.ACADEMIC,
                    last_updated=datetime.utcnow(),
                    quality=DataQuality.MEDIUM,
                    confidence_score=0.75,
                    fields_available=['degrees', 'publications']
                ))
            }
            
            mock_collect.return_value = mock_source_results
            
            mock_profile = ConsolidatedLawyerProfile(
                lawyer_id='adv_123',
                full_name='Dr. João Silva',
                alternative_names=['João Silva'],
                linkedin_profile=mock_linkedin_profile,
                academic_profile=mock_academic_profile,
                data_sources={
                    DataSourceType.LINKEDIN: mock_source_results[DataSourceType.LINKEDIN][1],
                    DataSourceType.ACADEMIC: mock_source_results[DataSourceType.ACADEMIC][1]
                },
                overall_quality_score=0.80,
                completeness_score=0.75,
                last_consolidated=datetime.utcnow()
            )
            
            mock_consolidate.return_value = mock_profile
            mock_calculate.return_value = mock_profile
            
            # Executar teste
            result = await service.get_complete_lawyer_profile('adv_123')
            
            # Verificações
            assert result is not None
            assert result.lawyer_id == 'adv_123'
            assert result.full_name == 'Dr. João Silva'
            assert result.linkedin_profile == mock_linkedin_profile
            assert result.academic_profile == mock_academic_profile
            assert result.overall_quality_score == 0.80
            
            # Verificar se métodos foram chamados
            mock_collect.assert_called_once()
            mock_consolidate.assert_called_once()
            mock_calculate.assert_called_once()
            mock_cache.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_get_complete_lawyer_profile_not_found(self, service):
        """Testa comportamento quando advogado não é encontrado"""
        
        with patch.object(service, '_get_lawyer_basic_info', return_value=None):
            result = await service.get_complete_lawyer_profile('adv_inexistente')
            assert result is None
    
    @pytest.mark.asyncio
    async def test_collect_multi_source_data_with_timeout(self, service, mock_lawyer_basic_info):
        """Testa coleta com timeout em algumas fontes"""
        
        # Mock de fontes com diferentes comportamentos
        async def slow_linkedin_mock(*args, **kwargs):
            await asyncio.sleep(10)  # Simular timeout
            return None, DataSourceInfo(
                source_type=DataSourceType.LINKEDIN,
                last_updated=datetime.utcnow(),
                quality=DataQuality.UNKNOWN,
                confidence_score=0.0,
                fields_available=[]
            )
        
        async def fast_academic_mock(*args, **kwargs):
            return None, DataSourceInfo(
                source_type=DataSourceType.ACADEMIC,
                last_updated=datetime.utcnow(),
                quality=DataQuality.MEDIUM,
                confidence_score=0.7,
                fields_available=['degrees']
            )
        
        with patch.object(service, '_collect_linkedin_data', side_effect=slow_linkedin_mock), \
             patch.object(service, '_collect_academic_data', side_effect=fast_academic_mock):
            
            # Reduzir timeout para teste
            original_timeout = service.total_timeout_seconds
            service.total_timeout_seconds = 2
            
            try:
                result = await service._collect_multi_source_data(
                    mock_lawyer_basic_info,
                    [DataSourceType.LINKEDIN, DataSourceType.ACADEMIC],
                    False
                )
                
                # Deve retornar resultados parciais mesmo com timeout
                assert isinstance(result, dict)
                
            finally:
                service.total_timeout_seconds = original_timeout
    
    @pytest.mark.asyncio
    async def test_calculate_overall_quality(self, service):
        """Testa cálculo de qualidade geral"""
        
        data_sources = {
            DataSourceType.LINKEDIN: DataSourceInfo(
                source_type=DataSourceType.LINKEDIN,
                last_updated=datetime.utcnow(),
                quality=DataQuality.HIGH,
                confidence_score=0.9,
                fields_available=['education', 'experience']
            ),
            DataSourceType.ACADEMIC: DataSourceInfo(
                source_type=DataSourceType.ACADEMIC,
                last_updated=datetime.utcnow(),
                quality=DataQuality.MEDIUM,
                confidence_score=0.7,
                fields_available=['degrees']
            )
        }
        
        quality_score = service._calculate_overall_quality(data_sources)
        
        assert 0.0 <= quality_score <= 1.0
        assert quality_score > 0.7  # Esperamos qualidade alta
    
    @pytest.mark.asyncio
    async def test_calculate_completeness(self, service):
        """Testa cálculo de completude"""
        
        source_results = {
            DataSourceType.LINKEDIN: (Mock(), Mock()),
            DataSourceType.ACADEMIC: (Mock(), Mock()),
            DataSourceType.ESCAVADOR: (None, Mock()),  # Fonte sem dados
            DataSourceType.JUSBRASIL: (Mock(), Mock())
        }
        
        completeness = service._calculate_completeness(source_results)
        
        # 3 de 4 fontes com dados = 0.75
        expected_completeness = 3 / len(DataSourceType)
        assert completeness == expected_completeness
    
    @pytest.mark.asyncio
    async def test_data_transparency_report(self, service):
        """Testa geração de relatório de transparência"""
        
        mock_profile = ConsolidatedLawyerProfile(
            lawyer_id='adv_123',
            full_name='Dr. João Silva',
            alternative_names=['João Silva'],
            data_sources={
                DataSourceType.LINKEDIN: DataSourceInfo(
                    source_type=DataSourceType.LINKEDIN,
                    last_updated=datetime.utcnow(),
                    quality=DataQuality.HIGH,
                    confidence_score=0.85,
                    fields_available=['education', 'experience'],
                    cost_per_query=0.05
                )
            },
            overall_quality_score=0.85,
            completeness_score=0.80,
            last_consolidated=datetime.utcnow(),
            social_influence_score=78.5,
            academic_prestige_score=75.0,
            legal_expertise_score=80.0,
            market_reputation_score=70.0,
            overall_success_probability=76.0
        )
        
        with patch.object(service, 'get_complete_lawyer_profile', return_value=mock_profile):
            report = await service.get_data_transparency_report('adv_123')
            
            assert report['lawyer_id'] == 'adv_123'
            assert 'overall_quality_score' in report
            assert 'data_sources' in report
            assert 'scores_breakdown' in report
            assert 'recommendations' in report
            
            # Verificar estrutura do breakdown de scores
            scores = report['scores_breakdown']
            assert 'social_influence' in scores
            assert 'academic_prestige' in scores
            assert 'legal_expertise' in scores
            assert 'overall_success_probability' in scores

class TestDataQualityMetrics:
    """Testes específicos para métricas de qualidade"""
    
    @pytest.mark.asyncio
    async def test_linkedin_quality_calculation(self):
        """Testa cálculo de qualidade específico do LinkedIn"""
        
        from ..services.unipile_official_linkedin_service import UnipileOfficialLinkedInService
        
        service = UnipileOfficialLinkedInService()
        
        # Mock de perfil com diferentes níveis de completude
        mock_profile = LinkedInComprehensiveProfile(
            linkedin_id="test_123",
            full_name="João Silva",
            profile_url="https://linkedin.com/test",
            headline="Advogado",
            summary="Descrição completa",
            education=[Mock(), Mock()],  # 2 formações
            experience=[Mock(), Mock(), Mock()],  # 3 experiências
            skills=[Mock()] * 5,  # 5 skills
            certifications=[],  # Sem certificações
            languages=[Mock()],  # 1 idioma
            volunteer_experience=[],
            recent_activity=[Mock()] * 3,  # 3 atividades
            data_quality_score=0.0,
            completeness_score=0.0,
            source_confidence=1.0
        )
        
        # Calcular qualidade
        result = await service._calculate_data_quality(mock_profile)
        
        assert result.data_quality_score > 0.5  # Deve ter qualidade razoável
        assert result.completeness_score > 0.6  # Completude boa devido aos dados presentes
    
    @pytest.mark.asyncio
    async def test_academic_quality_calculation(self):
        """Testa cálculo de qualidade específico dos dados acadêmicos"""
        
        from ..services.perplexity_academic_service import PerplexityAcademicService
        from ..schemas.academic_schemas import AcademicDegree, AcademicInstitution, InstitutionRank
        
        service = PerplexityAcademicService()
        
        # Mock de perfil acadêmico com boa qualidade
        mock_institution = AcademicInstitution(
            name="Universidade de São Paulo",
            country="Brasil",
            rank_tier=InstitutionRank.TOP_10
        )
        
        mock_degree = AcademicDegree(
            degree_type="Doutorado",
            degree_name="Doutor em Direito",
            field_of_study="Direito Civil",
            institution=mock_institution
        )
        
        mock_profile = AcademicProfile(
            full_name="Dr. João Silva",
            degrees=[mock_degree],
            publications=[Mock()] * 3,  # 3 publicações
            awards=[Mock()],  # 1 prêmio
            academic_prestige_score=0.0,
            research_productivity_score=0.0,
            institution_quality_score=0.0,
            confidence_score=0.8
        )
        
        # Calcular scores
        result = await service._calculate_academic_scores(mock_profile)
        
        assert result.institution_quality_score > 80.0  # USP deve ter score alto
        assert result.research_productivity_score > 0.0  # Tem publicações
        assert result.academic_prestige_score > 70.0  # Score geral alto

class TestDataSourceIntegration:
    """Testes de integração entre fontes de dados"""
    
    @pytest.mark.asyncio
    async def test_linkedin_academic_correlation(self):
        """Testa correlação entre dados LinkedIn e acadêmicos"""
        
        # Dados LinkedIn
        linkedin_education = "Doutor em Direito pela USP"
        
        # Dados acadêmicos  
        academic_degree = "Doutorado em Direito - Universidade de São Paulo"
        
        # Função para verificar correlação
        def check_education_correlation(linkedin_edu: str, academic_edu: str) -> float:
            """Calcula correlação entre formações"""
            linkedin_lower = linkedin_edu.lower()
            academic_lower = academic_edu.lower()
            
            # Verificar elementos comuns
            common_elements = 0
            total_elements = 0
            
            keywords = ['doutor', 'doutorado', 'direito', 'usp', 'universidade', 'são paulo']
            
            for keyword in keywords:
                total_elements += 1
                if keyword in linkedin_lower and keyword in academic_lower:
                    common_elements += 1
                elif keyword in linkedin_lower or keyword in academic_lower:
                    common_elements += 0.5
            
            return common_elements / total_elements if total_elements > 0 else 0.0
        
        correlation = check_education_correlation(linkedin_education, academic_degree)
        
        assert correlation > 0.7  # Alta correlação esperada
    
    @pytest.mark.asyncio
    async def test_data_consistency_validation(self):
        """Testa validação de consistência entre fontes"""
        
        # Dados inconsistentes para teste
        linkedin_name = "João Silva Santos"
        academic_name = "J. S. Santos"
        oab_name = "João Silva Santos"
        
        def validate_name_consistency(names: list) -> float:
            """Valida consistência de nomes"""
            if not names:
                return 0.0
            
            # Normalizar nomes
            normalized = []
            for name in names:
                normalized.append(name.lower().replace('.', '').strip())
            
            # Calcular similaridade
            base_name = normalized[0]
            similarities = []
            
            for name in normalized[1:]:
                # Similaridade simples baseada em palavras comuns
                base_words = set(base_name.split())
                name_words = set(name.split())
                
                if base_words and name_words:
                    intersection = base_words.intersection(name_words)
                    union = base_words.union(name_words)
                    similarity = len(intersection) / len(union)
                    similarities.append(similarity)
            
            return sum(similarities) / len(similarities) if similarities else 1.0
        
        consistency = validate_name_consistency([linkedin_name, academic_name, oab_name])
        
        assert 0.0 <= consistency <= 1.0
        assert consistency > 0.5  # Esperamos consistência razoável

class TestErrorHandling:
    """Testes de tratamento de erros"""
    
    @pytest.mark.asyncio
    async def test_network_timeout_handling(self):
        """Testa tratamento de timeouts de rede"""
        
        from ..services.hybrid_legal_data_service_complete import HybridLegalDataServiceComplete
        
        service = HybridLegalDataServiceComplete()
        
        # Mock de função que simula timeout
        async def timeout_function(*args, **kwargs):
            await asyncio.sleep(5)  # Simular operação lenta
            return None
        
        with patch.object(service, '_collect_linkedin_data', side_effect=timeout_function):
            
            # Reduzir timeout para teste
            original_timeout = service.total_timeout_seconds
            service.total_timeout_seconds = 1
            
            try:
                # Deve lidar graciosamente com timeout
                basic_info = {'id': 'test', 'name': 'Test User'}
                result = await service._collect_multi_source_data(
                    basic_info,
                    [DataSourceType.LINKEDIN],
                    False
                )
                
                # Resultado deve estar presente mesmo com timeout
                assert isinstance(result, dict)
                
            finally:
                service.total_timeout_seconds = original_timeout
    
    @pytest.mark.asyncio
    async def test_api_error_handling(self):
        """Testa tratamento de erros de API"""
        
        from ..services.perplexity_academic_service import PerplexityAcademicService
        
        service = PerplexityAcademicService()
        
        # Mock de erro de API
        with patch.object(service, 'client') as mock_client:
            mock_client.chat.completions.create.side_effect = Exception("API Error")
            
            result = await service.get_comprehensive_academic_profile("Test User")
            
            # Deve retornar None em caso de erro
            assert result is None
    
    @pytest.mark.asyncio 
    async def test_data_parsing_error_handling(self):
        """Testa tratamento de erros de parsing de dados"""
        
        from ..services.perplexity_academic_service import PerplexityAcademicService
        
        service = PerplexityAcademicService()
        
        # Dados mal formados para teste
        malformed_data = {
            'education': [
                {'invalid_field': 'value'},  # Campo inválido
                {'institution': None},  # Valor None inesperado
            ],
            'publications': 'string_instead_of_list'  # Tipo incorreto
        }
        
        # Deve lidar graciosamente com dados mal formados
        result = await service._parse_academic_data("Test User", malformed_data)
        
        assert result is not None
        assert result.full_name == "Test User"
        assert isinstance(result.degrees, list)
        assert isinstance(result.publications, list)

# Configuração de fixtures globais
@pytest.fixture(scope="session") 
def event_loop():
    """Fixture para event loop de teste"""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()

@pytest.fixture
def mock_settings():
    """Mock de configurações para testes"""
    with patch('packages.backend.config.settings.get_settings') as mock:
        mock.return_value = Mock(
            UNIPILE_API_KEY="test_key",
            UNIPILE_API_SECRET="test_secret",
            PERPLEXITY_API_KEY="test_perplexity_key",
            LINKEDIN_CACHE_TTL_HOURS=6,
            ACADEMIC_CACHE_TTL_HOURS=24
        )
        yield mock.return_value 
import asyncio
from unittest.mock import Mock, AsyncMock, patch
from datetime import datetime, timedelta
from typing import Dict, Any

from ..services.hybrid_legal_data_service_complete import (
    HybridLegalDataServiceComplete,
    DataSourceType,
    DataQuality,
    ConsolidatedLawyerProfile,
    DataSourceInfo
)
from ..schemas.linkedin_schemas import LinkedInComprehensiveProfile
from ..schemas.academic_schemas import AcademicProfile

class TestHybridLegalDataServiceComplete:
    """Testes para o serviço híbrido completo de dados legais"""
    
    @pytest.fixture
    def service(self):
        """Fixture do serviço híbrido"""
        return HybridLegalDataServiceComplete()
    
    @pytest.fixture
    def mock_linkedin_profile(self):
        """Mock de perfil LinkedIn completo"""
        return LinkedInComprehensiveProfile(
            linkedin_id="linkedin_123",
            full_name="Dr. João Silva",
            profile_url="https://linkedin.com/in/joao-silva",
            headline="Advogado Especialista em Direito Civil",
            education=[],
            experience=[],
            skills=[],
            certifications=[],
            languages=[],
            volunteer_experience=[],
            recent_activity=[],
            data_quality_score=0.85,
            completeness_score=0.80,
            source_confidence=1.0
        )
    
    @pytest.fixture
    def mock_academic_profile(self):
        """Mock de perfil acadêmico"""
        return AcademicProfile(
            full_name="Dr. João Silva",
            degrees=[],
            publications=[],
            awards=[],
            academic_prestige_score=75.0,
            research_productivity_score=60.0,
            institution_quality_score=80.0,
            confidence_score=0.75
        )
    
    @pytest.fixture
    def mock_lawyer_basic_info(self):
        """Mock de informações básicas do advogado"""
        return {
            'id': 'adv_123',
            'name': 'Dr. João Silva',
            'oab_number': '123456/SP',
            'email': 'joao.silva@advogado.com',
            'linkedin_url': 'https://linkedin.com/in/joao-silva'
        }

    @pytest.mark.asyncio
    async def test_get_complete_lawyer_profile_success(
        self, 
        service, 
        mock_lawyer_basic_info,
        mock_linkedin_profile,
        mock_academic_profile
    ):
        """Testa coleta completa de perfil com sucesso"""
        
        # Mock das fontes de dados
        with patch.object(service, '_get_lawyer_basic_info', return_value=mock_lawyer_basic_info), \
             patch.object(service, '_collect_multi_source_data') as mock_collect, \
             patch.object(service, '_consolidate_collected_data') as mock_consolidate, \
             patch.object(service, '_calculate_final_scores') as mock_calculate, \
             patch.object(service, '_cache_consolidated_profile') as mock_cache:
            
            # Setup mock return values
            mock_source_results = {
                DataSourceType.LINKEDIN: (mock_linkedin_profile, DataSourceInfo(
                    source_type=DataSourceType.LINKEDIN,
                    last_updated=datetime.utcnow(),
                    quality=DataQuality.HIGH,
                    confidence_score=0.85,
                    fields_available=['education', 'experience', 'skills']
                )),
                DataSourceType.ACADEMIC: (mock_academic_profile, DataSourceInfo(
                    source_type=DataSourceType.ACADEMIC,
                    last_updated=datetime.utcnow(),
                    quality=DataQuality.MEDIUM,
                    confidence_score=0.75,
                    fields_available=['degrees', 'publications']
                ))
            }
            
            mock_collect.return_value = mock_source_results
            
            mock_profile = ConsolidatedLawyerProfile(
                lawyer_id='adv_123',
                full_name='Dr. João Silva',
                alternative_names=['João Silva'],
                linkedin_profile=mock_linkedin_profile,
                academic_profile=mock_academic_profile,
                data_sources={
                    DataSourceType.LINKEDIN: mock_source_results[DataSourceType.LINKEDIN][1],
                    DataSourceType.ACADEMIC: mock_source_results[DataSourceType.ACADEMIC][1]
                },
                overall_quality_score=0.80,
                completeness_score=0.75,
                last_consolidated=datetime.utcnow()
            )
            
            mock_consolidate.return_value = mock_profile
            mock_calculate.return_value = mock_profile
            
            # Executar teste
            result = await service.get_complete_lawyer_profile('adv_123')
            
            # Verificações
            assert result is not None
            assert result.lawyer_id == 'adv_123'
            assert result.full_name == 'Dr. João Silva'
            assert result.linkedin_profile == mock_linkedin_profile
            assert result.academic_profile == mock_academic_profile
            assert result.overall_quality_score == 0.80
            
            # Verificar se métodos foram chamados
            mock_collect.assert_called_once()
            mock_consolidate.assert_called_once()
            mock_calculate.assert_called_once()
            mock_cache.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_get_complete_lawyer_profile_not_found(self, service):
        """Testa comportamento quando advogado não é encontrado"""
        
        with patch.object(service, '_get_lawyer_basic_info', return_value=None):
            result = await service.get_complete_lawyer_profile('adv_inexistente')
            assert result is None
    
    @pytest.mark.asyncio
    async def test_collect_multi_source_data_with_timeout(self, service, mock_lawyer_basic_info):
        """Testa coleta com timeout em algumas fontes"""
        
        # Mock de fontes com diferentes comportamentos
        async def slow_linkedin_mock(*args, **kwargs):
            await asyncio.sleep(10)  # Simular timeout
            return None, DataSourceInfo(
                source_type=DataSourceType.LINKEDIN,
                last_updated=datetime.utcnow(),
                quality=DataQuality.UNKNOWN,
                confidence_score=0.0,
                fields_available=[]
            )
        
        async def fast_academic_mock(*args, **kwargs):
            return None, DataSourceInfo(
                source_type=DataSourceType.ACADEMIC,
                last_updated=datetime.utcnow(),
                quality=DataQuality.MEDIUM,
                confidence_score=0.7,
                fields_available=['degrees']
            )
        
        with patch.object(service, '_collect_linkedin_data', side_effect=slow_linkedin_mock), \
             patch.object(service, '_collect_academic_data', side_effect=fast_academic_mock):
            
            # Reduzir timeout para teste
            original_timeout = service.total_timeout_seconds
            service.total_timeout_seconds = 2
            
            try:
                result = await service._collect_multi_source_data(
                    mock_lawyer_basic_info,
                    [DataSourceType.LINKEDIN, DataSourceType.ACADEMIC],
                    False
                )
                
                # Deve retornar resultados parciais mesmo com timeout
                assert isinstance(result, dict)
                
            finally:
                service.total_timeout_seconds = original_timeout
    
    @pytest.mark.asyncio
    async def test_calculate_overall_quality(self, service):
        """Testa cálculo de qualidade geral"""
        
        data_sources = {
            DataSourceType.LINKEDIN: DataSourceInfo(
                source_type=DataSourceType.LINKEDIN,
                last_updated=datetime.utcnow(),
                quality=DataQuality.HIGH,
                confidence_score=0.9,
                fields_available=['education', 'experience']
            ),
            DataSourceType.ACADEMIC: DataSourceInfo(
                source_type=DataSourceType.ACADEMIC,
                last_updated=datetime.utcnow(),
                quality=DataQuality.MEDIUM,
                confidence_score=0.7,
                fields_available=['degrees']
            )
        }
        
        quality_score = service._calculate_overall_quality(data_sources)
        
        assert 0.0 <= quality_score <= 1.0
        assert quality_score > 0.7  # Esperamos qualidade alta
    
    @pytest.mark.asyncio
    async def test_calculate_completeness(self, service):
        """Testa cálculo de completude"""
        
        source_results = {
            DataSourceType.LINKEDIN: (Mock(), Mock()),
            DataSourceType.ACADEMIC: (Mock(), Mock()),
            DataSourceType.ESCAVADOR: (None, Mock()),  # Fonte sem dados
            DataSourceType.JUSBRASIL: (Mock(), Mock())
        }
        
        completeness = service._calculate_completeness(source_results)
        
        # 3 de 4 fontes com dados = 0.75
        expected_completeness = 3 / len(DataSourceType)
        assert completeness == expected_completeness
    
    @pytest.mark.asyncio
    async def test_data_transparency_report(self, service):
        """Testa geração de relatório de transparência"""
        
        mock_profile = ConsolidatedLawyerProfile(
            lawyer_id='adv_123',
            full_name='Dr. João Silva',
            alternative_names=['João Silva'],
            data_sources={
                DataSourceType.LINKEDIN: DataSourceInfo(
                    source_type=DataSourceType.LINKEDIN,
                    last_updated=datetime.utcnow(),
                    quality=DataQuality.HIGH,
                    confidence_score=0.85,
                    fields_available=['education', 'experience'],
                    cost_per_query=0.05
                )
            },
            overall_quality_score=0.85,
            completeness_score=0.80,
            last_consolidated=datetime.utcnow(),
            social_influence_score=78.5,
            academic_prestige_score=75.0,
            legal_expertise_score=80.0,
            market_reputation_score=70.0,
            overall_success_probability=76.0
        )
        
        with patch.object(service, 'get_complete_lawyer_profile', return_value=mock_profile):
            report = await service.get_data_transparency_report('adv_123')
            
            assert report['lawyer_id'] == 'adv_123'
            assert 'overall_quality_score' in report
            assert 'data_sources' in report
            assert 'scores_breakdown' in report
            assert 'recommendations' in report
            
            # Verificar estrutura do breakdown de scores
            scores = report['scores_breakdown']
            assert 'social_influence' in scores
            assert 'academic_prestige' in scores
            assert 'legal_expertise' in scores
            assert 'overall_success_probability' in scores

class TestDataQualityMetrics:
    """Testes específicos para métricas de qualidade"""
    
    @pytest.mark.asyncio
    async def test_linkedin_quality_calculation(self):
        """Testa cálculo de qualidade específico do LinkedIn"""
        
        from ..services.unipile_official_linkedin_service import UnipileOfficialLinkedInService
        
        service = UnipileOfficialLinkedInService()
        
        # Mock de perfil com diferentes níveis de completude
        mock_profile = LinkedInComprehensiveProfile(
            linkedin_id="test_123",
            full_name="João Silva",
            profile_url="https://linkedin.com/test",
            headline="Advogado",
            summary="Descrição completa",
            education=[Mock(), Mock()],  # 2 formações
            experience=[Mock(), Mock(), Mock()],  # 3 experiências
            skills=[Mock()] * 5,  # 5 skills
            certifications=[],  # Sem certificações
            languages=[Mock()],  # 1 idioma
            volunteer_experience=[],
            recent_activity=[Mock()] * 3,  # 3 atividades
            data_quality_score=0.0,
            completeness_score=0.0,
            source_confidence=1.0
        )
        
        # Calcular qualidade
        result = await service._calculate_data_quality(mock_profile)
        
        assert result.data_quality_score > 0.5  # Deve ter qualidade razoável
        assert result.completeness_score > 0.6  # Completude boa devido aos dados presentes
    
    @pytest.mark.asyncio
    async def test_academic_quality_calculation(self):
        """Testa cálculo de qualidade específico dos dados acadêmicos"""
        
        from ..services.perplexity_academic_service import PerplexityAcademicService
        from ..schemas.academic_schemas import AcademicDegree, AcademicInstitution, InstitutionRank
        
        service = PerplexityAcademicService()
        
        # Mock de perfil acadêmico com boa qualidade
        mock_institution = AcademicInstitution(
            name="Universidade de São Paulo",
            country="Brasil",
            rank_tier=InstitutionRank.TOP_10
        )
        
        mock_degree = AcademicDegree(
            degree_type="Doutorado",
            degree_name="Doutor em Direito",
            field_of_study="Direito Civil",
            institution=mock_institution
        )
        
        mock_profile = AcademicProfile(
            full_name="Dr. João Silva",
            degrees=[mock_degree],
            publications=[Mock()] * 3,  # 3 publicações
            awards=[Mock()],  # 1 prêmio
            academic_prestige_score=0.0,
            research_productivity_score=0.0,
            institution_quality_score=0.0,
            confidence_score=0.8
        )
        
        # Calcular scores
        result = await service._calculate_academic_scores(mock_profile)
        
        assert result.institution_quality_score > 80.0  # USP deve ter score alto
        assert result.research_productivity_score > 0.0  # Tem publicações
        assert result.academic_prestige_score > 70.0  # Score geral alto

class TestDataSourceIntegration:
    """Testes de integração entre fontes de dados"""
    
    @pytest.mark.asyncio
    async def test_linkedin_academic_correlation(self):
        """Testa correlação entre dados LinkedIn e acadêmicos"""
        
        # Dados LinkedIn
        linkedin_education = "Doutor em Direito pela USP"
        
        # Dados acadêmicos  
        academic_degree = "Doutorado em Direito - Universidade de São Paulo"
        
        # Função para verificar correlação
        def check_education_correlation(linkedin_edu: str, academic_edu: str) -> float:
            """Calcula correlação entre formações"""
            linkedin_lower = linkedin_edu.lower()
            academic_lower = academic_edu.lower()
            
            # Verificar elementos comuns
            common_elements = 0
            total_elements = 0
            
            keywords = ['doutor', 'doutorado', 'direito', 'usp', 'universidade', 'são paulo']
            
            for keyword in keywords:
                total_elements += 1
                if keyword in linkedin_lower and keyword in academic_lower:
                    common_elements += 1
                elif keyword in linkedin_lower or keyword in academic_lower:
                    common_elements += 0.5
            
            return common_elements / total_elements if total_elements > 0 else 0.0
        
        correlation = check_education_correlation(linkedin_education, academic_degree)
        
        assert correlation > 0.7  # Alta correlação esperada
    
    @pytest.mark.asyncio
    async def test_data_consistency_validation(self):
        """Testa validação de consistência entre fontes"""
        
        # Dados inconsistentes para teste
        linkedin_name = "João Silva Santos"
        academic_name = "J. S. Santos"
        oab_name = "João Silva Santos"
        
        def validate_name_consistency(names: list) -> float:
            """Valida consistência de nomes"""
            if not names:
                return 0.0
            
            # Normalizar nomes
            normalized = []
            for name in names:
                normalized.append(name.lower().replace('.', '').strip())
            
            # Calcular similaridade
            base_name = normalized[0]
            similarities = []
            
            for name in normalized[1:]:
                # Similaridade simples baseada em palavras comuns
                base_words = set(base_name.split())
                name_words = set(name.split())
                
                if base_words and name_words:
                    intersection = base_words.intersection(name_words)
                    union = base_words.union(name_words)
                    similarity = len(intersection) / len(union)
                    similarities.append(similarity)
            
            return sum(similarities) / len(similarities) if similarities else 1.0
        
        consistency = validate_name_consistency([linkedin_name, academic_name, oab_name])
        
        assert 0.0 <= consistency <= 1.0
        assert consistency > 0.5  # Esperamos consistência razoável

class TestErrorHandling:
    """Testes de tratamento de erros"""
    
    @pytest.mark.asyncio
    async def test_network_timeout_handling(self):
        """Testa tratamento de timeouts de rede"""
        
        from ..services.hybrid_legal_data_service_complete import HybridLegalDataServiceComplete
        
        service = HybridLegalDataServiceComplete()
        
        # Mock de função que simula timeout
        async def timeout_function(*args, **kwargs):
            await asyncio.sleep(5)  # Simular operação lenta
            return None
        
        with patch.object(service, '_collect_linkedin_data', side_effect=timeout_function):
            
            # Reduzir timeout para teste
            original_timeout = service.total_timeout_seconds
            service.total_timeout_seconds = 1
            
            try:
                # Deve lidar graciosamente com timeout
                basic_info = {'id': 'test', 'name': 'Test User'}
                result = await service._collect_multi_source_data(
                    basic_info,
                    [DataSourceType.LINKEDIN],
                    False
                )
                
                # Resultado deve estar presente mesmo com timeout
                assert isinstance(result, dict)
                
            finally:
                service.total_timeout_seconds = original_timeout
    
    @pytest.mark.asyncio
    async def test_api_error_handling(self):
        """Testa tratamento de erros de API"""
        
        from ..services.perplexity_academic_service import PerplexityAcademicService
        
        service = PerplexityAcademicService()
        
        # Mock de erro de API
        with patch.object(service, 'client') as mock_client:
            mock_client.chat.completions.create.side_effect = Exception("API Error")
            
            result = await service.get_comprehensive_academic_profile("Test User")
            
            # Deve retornar None em caso de erro
            assert result is None
    
    @pytest.mark.asyncio 
    async def test_data_parsing_error_handling(self):
        """Testa tratamento de erros de parsing de dados"""
        
        from ..services.perplexity_academic_service import PerplexityAcademicService
        
        service = PerplexityAcademicService()
        
        # Dados mal formados para teste
        malformed_data = {
            'education': [
                {'invalid_field': 'value'},  # Campo inválido
                {'institution': None},  # Valor None inesperado
            ],
            'publications': 'string_instead_of_list'  # Tipo incorreto
        }
        
        # Deve lidar graciosamente com dados mal formados
        result = await service._parse_academic_data("Test User", malformed_data)
        
        assert result is not None
        assert result.full_name == "Test User"
        assert isinstance(result.degrees, list)
        assert isinstance(result.publications, list)

# Configuração de fixtures globais
@pytest.fixture(scope="session") 
def event_loop():
    """Fixture para event loop de teste"""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()

@pytest.fixture
def mock_settings():
    """Mock de configurações para testes"""
    with patch('packages.backend.config.settings.get_settings') as mock:
        mock.return_value = Mock(
            UNIPILE_API_KEY="test_key",
            UNIPILE_API_SECRET="test_secret",
            PERPLEXITY_API_KEY="test_perplexity_key",
            LINKEDIN_CACHE_TTL_HOURS=6,
            ACADEMIC_CACHE_TTL_HOURS=24
        )
        yield mock.return_value 