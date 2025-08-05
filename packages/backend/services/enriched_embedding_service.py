#!/usr/bin/env python3
"""
Serviço de Embeddings Enriquecidos: CV + KPIs + Performance (1024D)

Combina dados textuais (CV, especialização) com métricas numéricas (KPIs, performance)
em um "super-documento" que é processado pelos modelos V2 especializados.

Características:
- Integração holística de texto + dados
- Templates estruturados para diferentes contextos
- Versionamento para iteração e A/B testing
- Métricas de qualidade e performance
"""
import logging
import json
import time
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime

# Importar serviço V2 base
try:
    from .embedding_service_v2 import legal_embedding_service_v2
    EMBEDDING_V2_AVAILABLE = True
except ImportError:
    logger.warning("EmbeddingServiceV2 não disponível")
    EMBEDDING_V2_AVAILABLE = False

logger = logging.getLogger(__name__)


@dataclass
class LawyerProfile:
    """Perfil estruturado do advogado para geração de embeddings enriquecidos."""
    id: str
    nome: str
    cv_text: str
    tags_expertise: List[str]
    kpi: Dict[str, Any]
    kpi_subarea: Dict[str, Any]
    total_cases: int
    publications: List[str]
    education: str
    professional_experience: str
    city: str
    state: str
    interaction_score: Optional[float] = None
    
    def __post_init__(self):
        """Normaliza e valida dados do perfil."""
        # Garantir que campos obrigatórios não sejam None
        self.cv_text = self.cv_text or ""
        self.tags_expertise = self.tags_expertise or []
        self.kpi = self.kpi or {}
        self.kpi_subarea = self.kpi_subarea or {}
        self.publications = self.publications or []
        self.education = self.education or ""
        self.professional_experience = self.professional_experience or ""


class EnrichedEmbeddingService:
    """
    Serviço para gerar embeddings enriquecidos que combinam:
    1. Dados textuais (CV, especialização, publicações)
    2. Métricas de performance (KPIs, taxa de sucesso)
    3. Contexto profissional (experiência, educação)
    4. Dados de engajamento (interaction_score)
    """
    
    def __init__(self):
        self.version = "v1.0"
        
        if not EMBEDDING_V2_AVAILABLE:
            raise RuntimeError("EmbeddingServiceV2 é obrigatório para embeddings enriquecidos")
        
        # Templates para diferentes tipos de enriquecimento
        self.templates = {
            "complete": self._template_complete,
            "performance_focused": self._template_performance_focused,
            "expertise_focused": self._template_expertise_focused,
            "balanced": self._template_balanced
        }
        
        logger.info(f"🧠 EnrichedEmbeddingService inicializado - versão {self.version}")

    async def generate_enriched_embedding(
        self,
        lawyer_profile: LawyerProfile,
        template_type: str = "balanced",
        force_provider: Optional[str] = None
    ) -> Tuple[List[float], str, Dict[str, Any]]:
        """
        Gera embedding enriquecido combinando texto + métricas.
        
        Args:
            lawyer_profile: Perfil estruturado do advogado
            template_type: Tipo de template ("complete", "performance_focused", etc.)
            force_provider: Forçar provedor específico ("openai", "voyage", "arctic")
            
        Returns:
            Tuple[embedding_vector, provider_name, metadata]
        """
        start_time = time.time()
        
        ab_test_group = "default_strategy"
        provider_to_force = force_provider

        # --- LÓGICA DO A/B TESTE ---
        # Se um provedor não for forçado externamente, aplicamos nosso teste A/B.
        if not provider_to_force:
            # Dividir os advogados em dois grupos com base no último caractere do ID.
            # Grupo 'voyage_primary': 50% dos casos. Força o uso do Voyage Law-2.
            # Grupo 'openai_primary': 50% dos casos. Usa a cascata padrão (que começa com OpenAI).
            last_char = lawyer_profile.id[-1]
            if last_char in '56789abcdef':
                ab_test_group = "voyage_primary"
                provider_to_force = "voyage"
            else:
                ab_test_group = "openai_primary"
                # Não forçamos provedor, usamos a estratégia padrão.

        try:
            # 1. Construir super-documento usando template
            if template_type not in self.templates:
                raise ValueError(f"Template '{template_type}' não encontrado")
            
            enriched_text = self.templates[template_type](lawyer_profile)
            
            # 2. Gerar embedding usando V2, aplicando a lógica do A/B Test
            embedding, provider = await legal_embedding_service_v2.generate_legal_embedding(
                enriched_text,
                "lawyer_cv_enriched",
                force_provider=provider_to_force
            )
            
            # 3. Calcular métricas
            generation_time = time.time() - start_time
            
            metadata = {
                "version": self.version,
                "template_type": template_type,
                "provider": provider,
                "ab_test_group": ab_test_group, # Adiciona rastreabilidade do teste A/B
                "generation_time": generation_time,
                "document_length": len(enriched_text),
                "kpi_fields_used": list(lawyer_profile.kpi.keys()),
                "expertise_areas": len(lawyer_profile.tags_expertise),
                "publications_count": len(lawyer_profile.publications),
                "generated_at": datetime.now().isoformat()
            }
            
            logger.info(f"✅ Embedding enriquecido gerado: {len(embedding)}D via {provider}")
            logger.debug(f"📊 Metadata: {metadata}")
            
            return embedding, provider, metadata
            
        except Exception as e:
            logger.error(f"❌ Erro ao gerar embedding enriquecido: {e}")
            raise

    def _template_complete(self, profile: LawyerProfile) -> str:
        """Template completo com todos os dados disponíveis."""
        
        # Extrair KPIs principais
        kpi = profile.kpi
        success_rate = kpi.get('taxa_sucesso', kpi.get('success_rate', 0))
        avg_rating = kpi.get('avaliacao_media', kpi.get('avg_rating', 0))
        cases_30d = kpi.get('casos_30d', kpi.get('cases_30d', 0))
        capacity = kpi.get('capacidade_mensal', kpi.get('monthly_capacity', 0))
        
        # Construir seções do documento
        sections = []
        
        # Seção 1: Identificação e Localização
        sections.append(f"[PERFIL PROFISSIONAL]\nAdvogado(a): {profile.nome}")
        if profile.city and profile.state:
            sections.append(f"Localização: {profile.city}, {profile.state}")
        
        # Seção 2: Especialização e Expertise
        if profile.tags_expertise:
            expertise_text = ", ".join(profile.tags_expertise)
            sections.append(f"[ESPECIALIZAÇÕES]\nÁreas de atuação: {expertise_text}")
        
        # Seção 3: Dados de Performance (KPIs)
        performance_lines = []
        if success_rate > 0:
            performance_lines.append(f"Taxa de sucesso: {success_rate:.1%}")
        if avg_rating > 0:
            performance_lines.append(f"Avaliação média dos clientes: {avg_rating:.1f}/5.0")
        if cases_30d > 0:
            performance_lines.append(f"Casos ativos (últimos 30 dias): {cases_30d}")
        if capacity > 0:
            performance_lines.append(f"Capacidade mensal: {capacity} casos")
        if profile.total_cases > 0:
            performance_lines.append(f"Total de casos históricos: {profile.total_cases}")
        
        if performance_lines:
            sections.append(f"[MÉTRICAS DE PERFORMANCE]\n" + "\n".join(performance_lines))
        
        # Seção 4: Performance por Subárea
        if profile.kpi_subarea:
            subarea_lines = []
            for subarea, data in profile.kpi_subarea.items():
                if isinstance(data, dict):
                    subarea_success = data.get('success_rate', data.get('taxa_sucesso', 0))
                    subarea_cases = data.get('total_cases', data.get('total_casos', 0))
                    if subarea_success > 0 or subarea_cases > 0:
                        subarea_lines.append(f"{subarea}: {subarea_success:.1%} sucesso, {subarea_cases} casos")
            
            if subarea_lines:
                sections.append(f"[PERFORMANCE POR ÁREA]\n" + "\n".join(subarea_lines[:5]))  # Top 5
        
        # NOVO: Seção 5: Dados de APIs Externas
        external_data = self._extract_external_api_data(profile)
        if external_data:
            sections.append(f"[DADOS ESPECIALIZADOS]\n{external_data}")
        
        # Seção 6: Qualificações e Educação
        if profile.education:
            try:
                education_data = json.loads(profile.education) if isinstance(profile.education, str) else profile.education
                if isinstance(education_data, list) and education_data:
                    education_text = "; ".join([str(ed) for ed in education_data[:3]])  # Top 3
                    sections.append(f"[FORMAÇÃO ACADÊMICA]\n{education_text}")
            except (json.JSONDecodeError, TypeError):
                if profile.education.strip():
                    sections.append(f"[FORMAÇÃO ACADÊMICA]\n{profile.education[:200]}")
        
        # Seção 7: Experiência Profissional
        if profile.professional_experience:
            try:
                exp_data = json.loads(profile.professional_experience) if isinstance(profile.professional_experience, str) else profile.professional_experience
                if isinstance(exp_data, list) and exp_data:
                    exp_text = "; ".join([str(exp) for exp in exp_data[:3]])  # Top 3
                    sections.append(f"[EXPERIÊNCIA PROFISSIONAL]\n{exp_text}")
            except (json.JSONDecodeError, TypeError):
                if profile.professional_experience.strip():
                    sections.append(f"[EXPERIÊNCIA PROFISSIONAL]\n{profile.professional_experience[:200]}")
        
        # Seção 8: Publicações e Produção Acadêmica
        if profile.publications:
            pub_count = len(profile.publications)
            pub_sample = "; ".join(profile.publications[:3])  # Top 3
            sections.append(f"[PRODUÇÃO ACADÊMICA]\n{pub_count} publicações: {pub_sample}")
        
        # Seção 9: Engajamento na Plataforma
        if profile.interaction_score is not None:
            engagement_level = "alto" if profile.interaction_score > 0.7 else "médio" if profile.interaction_score > 0.4 else "baixo"
            sections.append(f"[ENGAJAMENTO]\nNível de engajamento na plataforma: {engagement_level}")
        
        # Seção 10: Descrição do CV (se disponível)
        if profile.cv_text.strip():
            cv_excerpt = profile.cv_text[:300]  # Primeiros 300 caracteres
            sections.append(f"[RESUMO DO CURRÍCULO]\n{cv_excerpt}")
        
        # Seção 11: Contexto de Qualidade
        quality_indicators = []
        if success_rate > 0.8:
            quality_indicators.append("alta taxa de sucesso")
        if avg_rating > 4.0:
            quality_indicators.append("excelente avaliação dos clientes")
        if cases_30d > 10:
            quality_indicators.append("alta atividade recente")
        if len(profile.publications) > 5:
            quality_indicators.append("produção acadêmica significativa")
        
        if quality_indicators:
            sections.append(f"[DESTAQUES]\nAdvogado(a) com {', '.join(quality_indicators)}")
        
        return "\n\n".join(sections)

    def _template_performance_focused(self, profile: LawyerProfile) -> str:
        """Template focado em performance e métricas."""
        
        kpi = profile.kpi
        success_rate = kpi.get('taxa_sucesso', kpi.get('success_rate', 0))
        avg_rating = kpi.get('avaliacao_media', kpi.get('avg_rating', 0))
        cases_30d = kpi.get('casos_30d', kpi.get('cases_30d', 0))
        
        sections = []
        
        # Performance como foco principal
        performance_desc = f"Advogado(a) {profile.nome} com "
        perf_metrics = []
        
        if success_rate > 0:
            perf_metrics.append(f"taxa de sucesso de {success_rate:.1%}")
        if avg_rating > 0:
            perf_metrics.append(f"avaliação média de {avg_rating:.1f}/5.0")
        if cases_30d > 0:
            perf_metrics.append(f"{cases_30d} casos ativos")
        
        if perf_metrics:
            performance_desc += ", ".join(perf_metrics)
        
        sections.append(f"[PERFORMANCE DESTACADA]\n{performance_desc}")
        
        # Especialização com contexto de performance
        if profile.tags_expertise:
            expertise_text = ", ".join(profile.tags_expertise)
            sections.append(f"[ESPECIALIZAÇÃO COMPROVADA]\nEspecialista em {expertise_text}")
        
        # KPIs por subárea (apenas as melhores)
        if profile.kpi_subarea:
            best_subareas = []
            for subarea, data in profile.kpi_subarea.items():
                if isinstance(data, dict):
                    subarea_success = data.get('success_rate', data.get('taxa_sucesso', 0))
                    if subarea_success > 0.7:  # Apenas áreas com alta performance
                        best_subareas.append(f"{subarea} ({subarea_success:.1%})")
            
            if best_subareas:
                sections.append(f"[ÁREAS DE ALTA PERFORMANCE]\n{'; '.join(best_subareas[:3])}")
        
        # Resumo do CV com foco em resultados
        if profile.cv_text:
            sections.append(f"[EXPERIÊNCIA COMPROVADA]\n{profile.cv_text[:200]}")
        
        return "\n\n".join(sections)

    def _template_expertise_focused(self, profile: LawyerProfile) -> str:
        """Template focado em especialização e conhecimento técnico."""
        
        sections = []
        
        # Especialização como foco principal
        if profile.tags_expertise:
            expertise_text = ", ".join(profile.tags_expertise)
            sections.append(f"[ESPECIALIZAÇÃO JURÍDICA]\nAdvogado(a) {profile.nome}, especialista em {expertise_text}")
        
        # Formação e qualificações
        if profile.education:
            sections.append(f"[QUALIFICAÇÕES ACADÊMICAS]\n{profile.education[:300]}")
        
        # Produção acadêmica como diferencial
        if profile.publications:
            pub_count = len(profile.publications)
            sections.append(f"[PRODUÇÃO ACADÊMICA]\n{pub_count} publicações relevantes na área jurídica")
        
        # Experiência específica
        if profile.professional_experience:
            sections.append(f"[EXPERIÊNCIA ESPECIALIZADA]\n{profile.professional_experience[:300]}")
        
        # Performance como validação da expertise
        kpi = profile.kpi
        success_rate = kpi.get('taxa_sucesso', kpi.get('success_rate', 0))
        if success_rate > 0:
            sections.append(f"[EXPERTISE COMPROVADA]\nTaxa de sucesso de {success_rate:.1%} valida a especialização")
        
        # CV completo
        if profile.cv_text:
            sections.append(f"[PERFIL PROFISSIONAL]\n{profile.cv_text[:400]}")
        
        return "\n\n".join(sections)

    def _template_balanced(self, profile: LawyerProfile) -> str:
        """Template balanceado combinando todos os aspectos principais."""
        
        sections = []
        
        # Introdução completa
        intro = f"Advogado(a) {profile.nome}"
        if profile.tags_expertise:
            intro += f", especializado(a) em {', '.join(profile.tags_expertise[:3])}"
        sections.append(f"[PERFIL PROFISSIONAL]\n{intro}")
        
        # Performance equilibrada
        kpi = profile.kpi
        success_rate = kpi.get('taxa_sucesso', kpi.get('success_rate', 0))
        avg_rating = kpi.get('avaliacao_media', kpi.get('avg_rating', 0))
        
        if success_rate > 0 or avg_rating > 0:
            perf_text = []
            if success_rate > 0:
                perf_text.append(f"taxa de sucesso: {success_rate:.1%}")
            if avg_rating > 0:
                perf_text.append(f"avaliação: {avg_rating:.1f}/5.0")
            sections.append(f"[PERFORMANCE]\n{', '.join(perf_text)}")
        
        # Qualificações resumidas
        if profile.education or profile.publications:
            qual_parts = []
            if profile.education:
                qual_parts.append("formação acadêmica sólida")
            if profile.publications:
                qual_parts.append(f"{len(profile.publications)} publicações")
            sections.append(f"[QUALIFICAÇÕES]\n{', '.join(qual_parts)}")
        
        # Experiência resumida
        if profile.total_cases > 0:
            sections.append(f"[EXPERIÊNCIA]\n{profile.total_cases} casos tratados")
        
        # Resumo do CV
        if profile.cv_text:
            sections.append(f"[RESUMO]\n{profile.cv_text[:250]}")
        
        return "\n\n".join(sections)

    def _extract_external_api_data(self, profile: LawyerProfile) -> str:
        """
        Extrai e formata dados de APIs externas para inclusão no embedding.
        
        Busca por:
        - Dados do Escavador (processos, taxa real de sucesso, ESPECIALIZAÇÕES REAIS)
        - Dados do JusBrasil (volume por área)
        - Análise Perplexity (soft skills, sentimento)
        - Hybrid stats (dados unificados)
        - Currículo Lattes via Escavador (expertise acadêmica)
        """
        external_lines = []
        
        # 1. Dados híbridos (Escavador + JusBrasil)
        if hasattr(profile, 'hybrid_stats') and profile.hybrid_stats:
            hybrid = profile.hybrid_stats
            if hasattr(hybrid, 'real_success_rate') and hybrid.real_success_rate > 0:
                external_lines.append(f"Taxa de sucesso verificada (Escavador): {hybrid.real_success_rate:.1%}")
            
            if hasattr(hybrid, 'total_verified_cases') and hybrid.total_verified_cases > 0:
                external_lines.append(f"Casos verificados em tribunais: {hybrid.total_verified_cases}")
            
            if hasattr(hybrid, 'specialization_score') and hybrid.specialization_score > 0:
                external_lines.append(f"Score de especialização: {hybrid.specialization_score:.2f}")
        
        # 2. Dados específicos do Escavador
        escavador_data = profile.kpi.get('escavador_data')
        if escavador_data:
            if escavador_data.get('victories', 0) > 0:
                victories = escavador_data['victories']
                total = escavador_data.get('total_cases', victories)
                external_lines.append(f"Vitórias documentadas: {victories}/{total} casos")
            
            if escavador_data.get('avg_case_value', 0) > 0:
                avg_value = escavador_data['avg_case_value']
                external_lines.append(f"Valor médio por caso: R$ {avg_value:,.2f}")
            
            # 🆕 ESPECIALIZAÇÃO BASEADA EM HISTÓRICO REAL DE PROCESSOS
            if escavador_data.get('area_distribution'):
                area_dist = escavador_data['area_distribution']
                # Ordenar por quantidade de casos (especialização real)
                areas_sorted = sorted(area_dist.items(), key=lambda x: x[1], reverse=True)
                
                if areas_sorted:
                    top_areas = []
                    for area, casos in areas_sorted[:3]:  # Top 3 áreas
                        percentage = (casos / sum(area_dist.values())) * 100
                        if percentage >= 10:  # Só áreas com pelo menos 10% do histórico
                            top_areas.append(f"{area} ({casos} casos, {percentage:.0f}%)")
                    
                    if top_areas:
                        external_lines.append(f"Especialização comprovada por histórico processual: {'; '.join(top_areas)}")
            
            # Performance específica por área jurídica
            if escavador_data.get('area_performance'):
                area_perf = escavador_data['area_performance']
                best_areas = []
                for area, perf in area_perf.items():
                    if isinstance(perf, dict):
                        success_rate = perf.get('success_rate', 0)
                        case_count = perf.get('case_count', 0)
                        if success_rate > 0.8 and case_count >= 5:  # Alta performance com volume
                            best_areas.append(f"{area} ({success_rate:.1%} de sucesso)")
                
                if best_areas:
                    external_lines.append(f"Áreas de alta performance comprovada: {'; '.join(best_areas[:3])}")
        
        # 3. Currículo Lattes via Escavador (expertise acadêmica)
        curriculo_escavador = profile.kpi.get('curriculo_escavador')
        if curriculo_escavador:
            anos_exp = curriculo_escavador.get('anos_experiencia', 0)
            if anos_exp > 0:
                external_lines.append(f"Experiência comprovada: {anos_exp} anos de atuação")
            
            pos_graduacoes = curriculo_escavador.get('pos_graduacoes', [])
            if pos_graduacoes:
                titulos = [pq.get('titulo', '') for pq in pos_graduacoes[:3]]  # Top 3
                if titulos:
                    external_lines.append(f"Títulos acadêmicos: {'; '.join(titulos)}")
            
            publicacoes = curriculo_escavador.get('num_publicacoes', 0)
            if publicacoes > 0:
                external_lines.append(f"Produção acadêmica: {publicacoes} publicações indexadas")
            
            areas_lattes = curriculo_escavador.get('areas_de_atuacao', '')
            if areas_lattes:
                external_lines.append(f"Áreas de atuação acadêmica: {areas_lattes[:100]}")
            
            # Projetos de pesquisa
            projetos = curriculo_escavador.get('projetos_pesquisa', [])
            if projetos:
                external_lines.append(f"Projetos de pesquisa: {len(projetos)} projetos registrados")
        
        # 4. Análise de soft skills (Perplexity)
        soft_skills_data = profile.kpi.get('soft_skills_analysis')
        if soft_skills_data:
            sentiment = soft_skills_data.get('sentiment_score', 0)
            if sentiment > 0:
                sentiment_level = "excelente" if sentiment > 0.8 else "boa" if sentiment > 0.6 else "adequada"
                external_lines.append(f"Análise de comunicação: {sentiment_level} ({sentiment:.1%})")
            
            if soft_skills_data.get('professionalism_score', 0) > 0:
                prof_score = soft_skills_data['professionalism_score']
                external_lines.append(f"Score de profissionalismo: {prof_score:.2f}/5.0")
        
        # 5. Dados de volume por área (JusBrasil)
        area_volume = profile.kpi.get('area_volume_data')
        if area_volume:
            top_areas = []
            for area, count in sorted(area_volume.items(), key=lambda x: x[1], reverse=True)[:3]:
                if count > 5:  # Só áreas com volume significativo
                    top_areas.append(f"{area} ({count} casos)")
            
            if top_areas:
                external_lines.append(f"Volume histórico por área (JusBrasil): {'; '.join(top_areas)}")
        
        # 6. Análise de especialização híbrida (combinando fontes)
        all_specializations = []
        
        # Combinar especializações do CV declarado
        if profile.tags_expertise:
            all_specializations.extend([(area, 'declarado') for area in profile.tags_expertise])
        
        # Combinar especializações do histórico real (Escavador)
        if escavador_data and escavador_data.get('area_distribution'):
            area_dist = escavador_data['area_distribution']
            total_cases = sum(area_dist.values())
            for area, casos in area_dist.items():
                if casos >= 5 and (casos/total_cases) >= 0.15:  # Mínimo 15% dos casos
                    all_specializations.append((area, 'comprovado'))
        
        # Analisar consistência entre declarado vs comprovado
        if all_specializations:
            declarado = [area for area, tipo in all_specializations if tipo == 'declarado']
            comprovado = [area for area, tipo in all_specializations if tipo == 'comprovado']
            
            # Verificar alinhamento
            alinhados = set(declarado) & set(comprovado)
            if alinhados:
                external_lines.append(f"Especialização validada: {', '.join(alinhados)} (declarado + comprovado)")
            
            # Especialização emergente (só no histórico)
            emergente = set(comprovado) - set(declarado)
            if emergente:
                external_lines.append(f"Especialização emergente: {', '.join(emergente)} (não declarado mas comprovado)")
        
        # 7. Transparência dos dados
        transparency = profile.kpi.get('data_transparency')
        if transparency:
            confidence = transparency.get('confidence_score', 0)
            if confidence > 0.7:
                external_lines.append(f"Dados verificados com alta confiabilidade ({confidence:.1%})")
            
            source = transparency.get('primary_source', '')
            if source:
                external_lines.append(f"Fonte primária de dados: {source}")
        
        # 8. Score de maturidade profissional (combinando tudo)
        if curriculo_escavador and escavador_data:
            anos_exp = curriculo_escavador.get('anos_experiencia', 0)
            total_casos = escavador_data.get('total_cases', 0)
            publicacoes = curriculo_escavador.get('num_publicacoes', 0)
            
            # Calcular score de maturidade (0-100)
            maturity_score = 0
            if anos_exp > 0:
                maturity_score += min(30, anos_exp * 2)  # Máximo 30 pontos por experiência
            if total_casos > 0:
                maturity_score += min(40, total_casos)  # Máximo 40 pontos por casos
            if publicacoes > 0:
                maturity_score += min(30, publicacoes * 3)  # Máximo 30 pontos por publicações
            
            if maturity_score > 50:
                maturity_level = "senior" if maturity_score > 75 else "pleno" if maturity_score > 60 else "júnior"
                external_lines.append(f"Perfil de maturidade profissional: {maturity_level} (score: {maturity_score:.0f}/100)")
        
        return "\n".join(external_lines) if external_lines else ""

    async def generate_batch_enriched_embeddings(
        self,
        lawyer_profiles: List[LawyerProfile],
        template_type: str = "balanced",
        batch_size: int = 10
    ) -> List[Tuple[str, List[float], str, Dict[str, Any]]]:
        """
        Gera embeddings enriquecidos em batch para múltiplos advogados.
        
        Returns:
            Lista de tuplas (lawyer_id, embedding, provider, metadata)
        """
        results = []
        
        for i in range(0, len(lawyer_profiles), batch_size):
            batch = lawyer_profiles[i:i + batch_size]
            
            # Processar batch em paralelo
            import asyncio
            tasks = [
                self.generate_enriched_embedding(profile, template_type)
                for profile in batch
            ]
            
            batch_results = await asyncio.gather(*tasks, return_exceptions=True)
            
            for profile, result in zip(batch, batch_results):
                if isinstance(result, Exception):
                    logger.error(f"Erro ao processar {profile.id}: {result}")
                    continue
                
                embedding, provider, metadata = result
                results.append((profile.id, embedding, provider, metadata))
        
        return results

    def get_template_info(self) -> Dict[str, str]:
        """Retorna informações sobre os templates disponíveis."""
        return {
            "complete": "Template completo com todos os dados (máxima informação)",
            "performance_focused": "Foco em KPIs e métricas de performance",
            "expertise_focused": "Foco em especialização e conhecimento técnico",
            "balanced": "Template balanceado para uso geral"
        }


# Factory function
def create_enriched_embedding_service() -> EnrichedEmbeddingService:
    """Factory function para criar instância do serviço."""
    return EnrichedEmbeddingService()


# Instância global
enriched_embedding_service = create_enriched_embedding_service()


# Função de conveniência
async def generate_enriched_embedding(
    lawyer_profile: LawyerProfile,
    template_type: str = "balanced"
) -> Tuple[List[float], str, Dict[str, Any]]:
    """Função de conveniência para gerar embedding enriquecido."""
    return await enriched_embedding_service.generate_enriched_embedding(
        lawyer_profile, template_type
    )