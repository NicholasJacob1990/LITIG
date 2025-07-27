"""
Lawyer Profile Analysis Service V2 - OpenRouter + Function Calling
================================================================

🆕 V2.1: Web Search para Reputação Online Atualizada
- Busca publicações recentes em veículos jurídicos
- Participação em eventos e palestras
- Artigos publicados ou entrevistas
- Prêmios ou reconhecimentos recentes
- Casos de destaque noticiados

Nova versão usando:
- Gemini 2.5 Pro via OpenRouter (primário)
- Function Calling para estruturação confiável
- Fallback de 4 níveis automático
- 100% compatível com versão atual

Migração conforme PLANO_EVOLUCAO_COMPLETO_OPENROUTER_LANGGRAPH.md
"""

import asyncio
import time
import logging
import json
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

# Imports sem dependências relativas
try:
    from openrouter_client import get_openrouter_client
except ImportError:
    from services.openrouter_client import get_openrouter_client

try:
    from lawyer_profile_analysis_service import LawyerProfileInsights
except ImportError:
    from services.lawyer_profile_analysis_service import LawyerProfileInsights

logger = logging.getLogger(__name__)


@dataclass
class LawyerProfileAnalysisResultV2(LawyerProfileInsights):
    """
    Resultado da análise de perfil V2.
    Herda de LawyerProfileInsights para manter 100% de compatibilidade.
    """
    model_used: Optional[str] = None
    fallback_level: Optional[int] = None
    processing_metadata: Optional[Dict[str, Any]] = None
    online_reputation_data: Optional[Dict[str, Any]] = None


class LawyerProfileAnalysisServiceV2:
    """
    Lawyer Profile Analysis V2: Análise de perfil com Gemini 2.5 Pro + Function Calling.
    
    🆕 V2.1: Web Search para Reputação Online Atualizada
    - Busca informações reputacionais em tempo real
    - Publicações e reconhecimentos recentes
    - Participação em eventos jurídicos
    - Score de reputação dinâmico baseado em fontes online
    
    Benefícios sobre V1:
    - Gemini 2.5 Pro: Melhor análise de perfis profissionais
    - Function Calling: Estruturação confiável das respostas
    - Fallback robusto: 4 níveis de resiliência
    - Web Search: Informações reputacionais atualizadas
    """
    
    def __init__(self):
        self.openrouter_client = get_openrouter_client()
        
        # Configuração de sources confiáveis para reputação profissional
        self.professional_sources = [
            "linkedin.com",
            "jusbrasil.com.br",
            "conjur.com.br",
            "migalhas.com.br",
            "jota.info",
            "oab.org.br"
        ]
        
        # Ferramenta de função para análise estruturada com reputação online
        self.profile_tool_enhanced = {
            "type": "function",
            "function": {
                "name": "extract_lawyer_insights_enhanced",
                "description": "Extrai insights detalhados do perfil de advogado com informações de reputação online atualizadas",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "professional_summary": {
                            "type": "string",
                            "description": "Resumo profissional do advogado"
                        },
                        "specialization_areas": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "Áreas de especialização identificadas"
                        },
                        "experience_level": {
                            "type": "string",
                            "enum": ["junior", "pleno", "senior", "especialista"],
                            "description": "Nível de experiência profissional"
                        },
                        "key_qualifications": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "Principais qualificações e certificações"
                        },
                        "professional_maturity_score": {
                            "type": "number",
                            "minimum": 0,
                            "maximum": 1,
                            "description": "Score de maturidade profissional (0-1)"
                        },
                        "recent_publications": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "Publicações recentes encontradas na web"
                        },
                        "online_reputation_score": {
                            "type": "number",
                            "minimum": 0,
                            "maximum": 1,
                            "description": "Score de reputação baseado em informações online"
                        },
                        "recent_achievements": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "Conquistas ou reconhecimentos recentes"
                        },
                        "event_participation": {
                            "type": "array",
                            "items": {
                                "type": "object",
                                "properties": {
                                    "event_name": {"type": "string"},
                                    "role": {"type": "string"},
                                    "date": {"type": "string"},
                                    "relevance": {"type": "string"}
                                }
                            },
                            "description": "Participação em eventos identificada via web search"
                        },
                        "media_mentions": {
                            "type": "array",
                            "items": {
                                "type": "object",
                                "properties": {
                                    "source": {"type": "string"},
                                    "title": {"type": "string"},
                                    "date": {"type": "string"},
                                    "context": {"type": "string"}
                                }
                            },
                            "description": "Menções na mídia jurídica"
                        },
                        "strengths": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "Pontos fortes identificados"
                        },
                        "potential_concerns": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "Potenciais pontos de atenção"
                        },
                        "recommendation_score": {
                            "type": "number",
                            "minimum": 0,
                            "maximum": 1,
                            "description": "Score geral de recomendação"
                        },
                        "web_search_summary": {
                            "type": "string",
                            "description": "Resumo das informações encontradas via web search"
                        },
                        "web_search_date": {
                            "type": "string",
                            "format": "date",
                            "description": "Data da última busca web realizada"
                        }
                    },
                    "required": [
                        "professional_summary",
                        "specialization_areas", 
                        "experience_level",
                        "professional_maturity_score",
                        "recommendation_score"
                    ]
                }
            }
        }
    
    async def analyze_lawyer_profile(
        self, 
        lawyer_data: Dict[str, Any], 
        enable_reputation_search: bool = True,
        search_depth: str = "standard"
    ) -> LawyerProfileAnalysisResultV2:
        """
        🆕 V2.1: Análise de perfil com Web Search para reputação atualizada.
        
        Args:
            lawyer_data: Dados do advogado
            enable_reputation_search: Habilita busca por reputação online
            search_depth: Profundidade da busca ("quick", "standard", "deep")
        
        Returns:
            LawyerProfileAnalysisResultV2 com informações reputacionais atualizadas
        """
        start_time = time.time()
        
        try:
            # Preparar contexto otimizado para web search
            if enable_reputation_search:
                context = self._prepare_reputation_search_context(lawyer_data, search_depth)
                system_prompt = self.profile_system_prompt_with_search
                model = "google/gemini-2.5-pro:online"  # Modelo com web search
            else:
                context = self._prepare_analysis_context(lawyer_data)
                system_prompt = self.profile_system_prompt
                model = Settings.OPENROUTER_LAWYER_PROFILE_MODEL
            
            # Executar análise com web search se habilitado
            response = await self.openrouter_client.chat_completion_with_web_search(
                model=model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": context}
                ],
                tools=[self.profile_tool_enhanced],
                tool_choice={"type": "function", "function": {"name": "extract_lawyer_insights_enhanced"}},
                enable_web_search=enable_reputation_search,
                web_search_sources=self.professional_sources if enable_reputation_search else None,
                search_focus="professional_reputation" if enable_reputation_search else None,
                temperature=0.2,
                max_tokens=2000
            )
            
            # Processar resultado
            analysis_result = self._parse_profile_insights_v2(response)
            
            # Adicionar metadados V2.1
            analysis_result.model_used = response.get("model_used")
            analysis_result.fallback_level = response.get("fallback_level")
            analysis_result.processing_metadata = {
                "reputation_search_enabled": enable_reputation_search,
                "web_search_used": response.get("web_search_used", False),
                "search_depth": search_depth if enable_reputation_search else None,
                "processing_time_ms": int((time.time() - start_time) * 1000),
                "provider": response.get("provider"),
                "sources_consulted": len(self.professional_sources) if enable_reputation_search else 0
            }
            
            # Extrair dados de reputação online se disponíveis
            if enable_reputation_search and response.get("web_search_used"):
                analysis_result.online_reputation_data = self._extract_reputation_data(response)
            
            logger.info(f"✅ Lawyer Profile V2.1: Análise concluída em {analysis_result.processing_metadata['processing_time_ms']}ms")
            if enable_reputation_search:
                logger.info(f"🌐 Reputation Search: {response.get('web_search_used', False)} | Score: {analysis_result.online_reputation_data.get('score', 'N/A') if analysis_result.online_reputation_data else 'N/A'}")
            
            return analysis_result
            
        except Exception as e:
            logger.error(f"❌ Erro na análise Lawyer Profile V2.1: {e}")
            
            # Fallback para análise sem web search
            if enable_reputation_search:
                logger.warning("🔄 Fallback: Tentando análise sem reputation search")
                return await self.analyze_lawyer_profile(
                    lawyer_data=lawyer_data,
                    enable_reputation_search=False
                )
            
            raise e
    
    def _prepare_reputation_search_context(self, lawyer_data: Dict[str, Any], search_depth: str = "standard") -> str:
        """
        Prepara contexto otimizado para busca de reputação online.
        
        Args:
            lawyer_data: Dados do advogado
            search_depth: Profundidade da busca
        
        Returns:
            Contexto estruturado para reputation search
        """
        lawyer_name = lawyer_data.get('nome', lawyer_data.get('name', ''))
        oab_number = lawyer_data.get('oab', lawyer_data.get('oab_numero', ''))
        firm_name = lawyer_data.get('escritorio', lawyer_data.get('firm_name', ''))
        
        depth_instructions = {
            "quick": "Busque apenas informações básicas e mais recentes (últimos 6 meses)",
            "standard": "Busque informações relevantes dos últimos 2 anos",
            "deep": "Busque informações abrangentes dos últimos 5 anos, incluindo histórico acadêmico"
        }
        
        return f"""
        🔍 BUSCA DE REPUTAÇÃO PROFISSIONAL OBRIGATÓRIA

        Busque informações ATUALIZADAS sobre o(a) advogado(a):
        
        **DADOS DO ADVOGADO:**
        • Nome: {lawyer_name}
        • OAB: {oab_number}
        • Escritório: {firm_name}
        
        **INFORMAÇÕES A BUSCAR:**
        
        **Prioridade 1 - Publicações e Reconhecimentos:**
        • Artigos publicados em veículos jurídicos
        • Entrevistas ou declarações à imprensa
        • Prêmios ou reconhecimentos profissionais
        • Rankings jurídicos (Chambers, Legal 500, etc.)
        
        **Prioridade 2 - Participação Profissional:**
        • Palestras e eventos jurídicos
        • Participação em comissões da OAB
        • Docência ou atividade acadêmica
        • Casos de destaque noticiados
        
        **Prioridade 3 - Reputação Digital:**
        • Perfil LinkedIn atualizado
        • Menções em redes sociais profissionais
        • Presença em diretórios jurídicos
        • Avaliações ou feedbacks públicos
        
        **INSTRUÇÕES DE BUSCA:**
        • {depth_instructions.get(search_depth, depth_instructions['standard'])}
        • Foque em fontes profissionais confiáveis
        • Ignore redes sociais pessoais
        • Cite sempre a fonte e data das informações
        • Use a função 'extract_lawyer_insights_enhanced' para estruturar
        
        **DADOS COMPLETOS DO PERFIL:**
        {json.dumps(lawyer_data, indent=2, ensure_ascii=False)}
        
        **PROFUNDIDADE DE BUSCA:** {search_depth.upper()}
        """
    
    @property
    def profile_system_prompt_with_search(self) -> str:
        """
        System prompt otimizado para análise com web search.
        """
        return """
        # PERSONA: Lawyer Profile Analyzer V2.1 - com Web Search
        
        Você é um especialista em análise de perfis profissionais jurídicos, 
        evoluído para trabalhar com informações de reputação ATUALIZADAS via web search.
        
        ## METODOLOGIA APRIMORADA V2.1
        
        1. **REPUTAÇÃO ONLINE**: SEMPRE busque informações atualizadas sobre o advogado na web
        2. **FONTES PROFISSIONAIS**: Priorize LinkedIn, veículos jurídicos especializados, OAB
        3. **RECONHECIMENTOS RECENTES**: Identifique prêmios, rankings, menções na mídia
        4. **ATIVIDADE PROFISSIONAL**: Mapeie participação em eventos, publicações, palestras
        5. **SCORING DINÂMICO**: Calcule online_reputation_score baseado em evidências reais
        6. **TRANSPARÊNCIA**: Indique claramente as fontes e datas das informações
        
        ## FONTES PREFERENCIAIS (em ordem de prioridade)
        
        **Reputação Profissional:**
        • LinkedIn - Perfil profissional atualizado
        • JusBrasil - Publicações e atividade jurídica
        • ConJur - Artigos e entrevistas
        • Migalhas - Notícias e reconhecimentos
        • JOTA - Análises e posicionamentos
        • OAB - Atividades institucionais
        
        ## CRITÉRIOS DE AVALIAÇÃO
        
        **Online Reputation Score (0-1):**
        • 0.9-1.0: Reputação excepcional (múltiplas fontes, reconhecimentos recentes)
        • 0.7-0.8: Reputação muito boa (presença consistente, publicações relevantes)
        • 0.5-0.6: Reputação adequada (presença básica, atividade moderada)
        • 0.3-0.4: Reputação limitada (poucas informações públicas)
        • 0.0-0.2: Reputação insuficiente (ausência de informações relevantes)
        
        **Professional Maturity Score considera:**
        • Tempo de carreira evidenciado
        • Qualidade das posições ocupadas
        • Reconhecimento pelos pares
        • Contribuições para a comunidade jurídica
        • Especialização demonstrada
        
        ## ESTRUTURA DA RESPOSTA
        
        Use OBRIGATORIAMENTE a função 'extract_lawyer_insights_enhanced' com:
        • online_reputation_score baseado em evidências web
        • recent_publications encontradas via search
        • recent_achievements identificados online
        • event_participation mapeada via fontes
        • media_mentions com fontes e contexto
        • web_search_summary resumindo achados
        • web_search_date indicando atualidade
        
        ## QUALIDADE DA ANÁLISE
        
        • **Evidência**: Base conclusões em informações verificáveis online
        • **Atualidade**: Priorize informações dos últimos 2 anos
        • **Relevância**: Avalie impacto real na reputação profissional
        • **Objetividade**: Mantenha análise imparcial e fundamentada
        • **Completude**: Explore todas as dimensões da reputação profissional
        """
    
    def _parse_profile_insights_v2(self, response: Dict[str, Any]) -> LawyerProfileAnalysisResultV2:
        """
        Parses the response from OpenRouter to extract insights.
        """
        insights = response.get("result", {})
        
        # Map insights to LawyerProfileAnalysisResultV2 fields
        return LawyerProfileAnalysisResultV2(
            expertise_level=insights.get("expertise_level", 0.5),
            specialization_confidence=insights.get("specialization_confidence", 0.5),
            communication_style=insights.get("communication_style", "accessible"),
            experience_quality=insights.get("experience_quality", "mid"),
            niche_specialties=insights.get("niche_specialties", []),
            soft_skills_score=insights.get("soft_skills_score", 0.5),
            innovation_indicator=insights.get("innovation_indicator", 0.5),
            client_profile_match=insights.get("client_profile_match", []),
            risk_assessment=insights.get("risk_assessment", "balanced"),
            confidence_score=insights.get("confidence_score", 0.5),
            processing_time_ms=response.get("processing_time_ms"),
            model_used=response.get("model_used"),
            fallback_level=response.get("fallback_level"),
            processing_metadata=response.get("processing_metadata"),
            online_reputation_data=insights.get("online_reputation_data")
        )
    
    def _extract_reputation_data(self, response: Dict[str, Any]) -> Dict[str, Any]:
        """
        Extracts specific reputation data from the response.
        """
        insights = response.get("result", {})
        return {
            "score": insights.get("online_reputation_score", 0.0),
            "summary": insights.get("web_search_summary"),
            "date": insights.get("web_search_date"),
            "recent_publications": insights.get("recent_publications", []),
            "recent_achievements": insights.get("recent_achievements", []),
            "event_participation": insights.get("event_participation", []),
            "media_mentions": insights.get("media_mentions", []),
            "strengths": insights.get("strengths", []),
            "potential_concerns": insights.get("potential_concerns", []),
            "recommendation_score": insights.get("recommendation_score", 0.0)
        }
    
    def _prepare_analysis_context(self, lawyer_data: Dict[str, Any]) -> str:
        """
        Prepara contexto da análise de perfil.
        Método adaptado da versão V1 para compatibilidade.
        """
        lawyer_id = lawyer_data.get("lawyer_id", "N/A")
        name = lawyer_data.get("name", "Nome não informado")
        
        # Dados básicos
        basic_info = lawyer_data.get("basic_info", {})
        oab_number = basic_info.get("oab_number", "N/A")
        years_experience = basic_info.get("years_experience", 0)
        location = basic_info.get("location", "N/A")
        
        # Formação acadêmica
        education = lawyer_data.get("education", [])
        education_text = "\n".join([
            f"- {edu.get('degree', '')} em {edu.get('institution', '')} ({edu.get('year', 'Ano N/A')})"
            for edu in education
        ]) if education else "Formação não informada"
        
        # Experiência profissional
        experience = lawyer_data.get("experience", [])
        experience_text = "\n".join([
            f"- {exp.get('position', '')} em {exp.get('company', '')} ({exp.get('duration', 'Período N/A')})\n  {exp.get('description', '')}"
            for exp in experience
        ]) if experience else "Experiência não informada"
        
        # Especialidades declaradas
        specialties = lawyer_data.get("specialties", [])
        specialties_text = ", ".join(specialties) if specialties else "Não declaradas"
        
        # Casos e sucessos
        cases = lawyer_data.get("cases", [])
        cases_text = "\n".join([
            f"- {case.get('title', 'Caso sem título')}: {case.get('outcome', 'Resultado N/A')} ({case.get('area', 'Área N/A')})"
            for case in cases[:5]  # Primeiros 5 casos
        ]) if cases else "Casos não informados"
        
        # Avaliações de clientes
        reviews = lawyer_data.get("reviews", [])
        reviews_text = "\n".join([
            f"- {review.get('rating', 'N/A')}/5 estrelas: '{review.get('comment', 'Sem comentário')}'"
            for review in reviews[:3]  # Primeiras 3 avaliações
        ]) if reviews else "Avaliações não disponíveis"
        
        # Certificações e cursos
        certifications = lawyer_data.get("certifications", [])
        cert_text = "\n".join([
            f"- {cert.get('name', '')} ({cert.get('institution', '')}, {cert.get('year', 'Ano N/A')})"
            for cert in certifications
        ]) if certifications else "Certificações não informadas"
        
        # Publicações e atividades acadêmicas
        publications = lawyer_data.get("publications", [])
        pub_text = "\n".join([
            f"- {pub.get('title', 'Título N/A')} ({pub.get('type', 'Tipo N/A')}, {pub.get('year', 'Ano N/A')})"
            for pub in publications
        ]) if publications else "Publicações não informadas"
        
        context = f"""
=== DADOS BÁSICOS DO ADVOGADO ===
ID: {lawyer_id}
Nome: {name}
OAB: {oab_number}
Anos de Experiência: {years_experience}
Localização: {location}

=== FORMAÇÃO ACADÊMICA ===
{education_text}

=== EXPERIÊNCIA PROFISSIONAL ===
{experience_text}

=== ESPECIALIDADES DECLARADAS ===
{specialties_text}

=== CASOS E SUCESSOS REPRESENTATIVOS ===
{cases_text}

=== AVALIAÇÕES DE CLIENTES ===
{reviews_text}

=== CERTIFICAÇÕES E CURSOS ===
{cert_text}

=== PUBLICAÇÕES E ATIVIDADES ACADÊMICAS ===
{pub_text}

=== SOLICITAÇÃO ===
Com base nos dados acima, realize uma análise qualitativa profunda do perfil deste advogado. Identifique insights não óbvios sobre:

1. Estilo de comunicação e soft skills
2. Qualidade real da experiência (além da quantidade)
3. Especialidades de nicho não declaradas explicitamente
4. Propensão à inovação e modernidade
5. Perfis de cliente que mais se beneficiariam dos serviços
6. Nível de expertise baseado em evidências qualitativas

Use a função 'extract_lawyer_insights' para retornar sua análise estruturada.
"""
        
        return context
    
    async def _fallback_to_traditional_analysis(
        self, 
        lawyer_data: Dict[str, Any], 
        processing_time: int,
        failed_response: Dict[str, Any]
    ) -> LawyerProfileAnalysisResultV2:
        """
        Fallback para análise tradicional quando Function Calling falha.
        """
        logger.info("Usando fallback tradicional para análise de perfil")
        
        # Análise básica baseada em heurísticas simples
        years_exp = lawyer_data.get("basic_info", {}).get("years_experience", 0)
        specialties = lawyer_data.get("specialties", [])
        reviews = lawyer_data.get("reviews", [])
        cases = lawyer_data.get("cases", [])
        
        # Calcular métricas básicas
        expertise_level = min(years_exp / 20.0, 1.0)  # Máximo em 20 anos
        specialization_confidence = min(len(specialties) / 5.0, 1.0)  # Máximo em 5 especialidades
        
        # Inferir estilo de comunicação
        communication_style = "accessible"  # Padrão
        if any("técnico" in spec.lower() for spec in specialties):
            communication_style = "technical"
        elif any("empresarial" in spec.lower() for spec in specialties):
            communication_style = "formal"
        
        # Inferir qualidade da experiência
        experience_quality = "mid"  # Padrão
        if years_exp >= 15:
            experience_quality = "expert"
        elif years_exp >= 8:
            experience_quality = "senior"
        elif years_exp <= 3:
            experience_quality = "junior"
        
        # Soft skills baseado em avaliações
        avg_rating = sum(r.get("rating", 3) for r in reviews) / max(len(reviews), 1)
        soft_skills_score = min(avg_rating / 5.0, 1.0)
        
        return LawyerProfileAnalysisResultV2(
            expertise_level=expertise_level,
            specialization_confidence=specialization_confidence,
            communication_style=communication_style,
            experience_quality=experience_quality,
            niche_specialties=specialties[:3],  # Primeiras 3 como nicho
            soft_skills_score=soft_skills_score,
            innovation_indicator=0.5,  # Neutro no fallback
            client_profile_match=["clientes_gerais"],
            risk_assessment="balanced",
            confidence_score=0.4,  # Baixa confiança no fallback
            processing_time_ms=processing_time,
            model_used=failed_response.get("model_used", "fallback_heuristic"),
            fallback_level=failed_response.get("fallback_level", 999),
            processing_metadata={
                "version": "v2_fallback_heuristic",
                "error": failed_response.get("error"),
                "heuristic_analysis": True
            },
            online_reputation_data=None # No reputation data in fallback
        )
    
    async def _emergency_fallback_analysis(
        self,
        lawyer_data: Dict[str, Any],
        processing_time: int,
        error_msg: str
    ) -> LawyerProfileAnalysisResultV2:
        """
        Fallback de emergência quando tudo falha.
        """
        logger.error(f"Usando fallback de emergência para análise de perfil: {error_msg}")
        
        return LawyerProfileAnalysisResultV2(
            expertise_level=0.5,
            specialization_confidence=0.3,
            communication_style="accessible",
            experience_quality="mid",
            niche_specialties=[],
            soft_skills_score=0.5,
            innovation_indicator=0.5,
            client_profile_match=["clientes_gerais"],
            risk_assessment="balanced",
            confidence_score=0.0,
            processing_time_ms=processing_time,
            model_used="emergency_fallback",
            fallback_level=999,
            processing_metadata={
                "version": "v2_emergency_fallback",
                "error": error_msg,
                "timestamp": time.time()
            },
            online_reputation_data=None # No reputation data in emergency fallback
        )


# Factory function para compatibilidade
async def get_lawyer_profile_service_v2() -> LawyerProfileAnalysisServiceV2:
    """Factory function para obter instância do serviço V2."""
    return LawyerProfileAnalysisServiceV2()


# Instância global para uso direto
lawyer_profile_service_v2 = LawyerProfileAnalysisServiceV2() 
 