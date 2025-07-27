#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Partnership LLM Enhancement Service
===================================

Serviço que aprimora as recomendações de parcerias com análises LLM para:
- Análise contextual de sinergia entre advogados
- Avaliação de compatibilidade profissional
- Identificação de oportunidades estratégicas
- Explicações inteligentes das recomendações

Integra-se ao partnership_recommendation_service.py existente.
"""

import asyncio
import json
import logging
from dataclasses import dataclass
from typing import Dict, List, Optional, Any
from datetime import datetime

logger = logging.getLogger(__name__)

# Importar clientes LLM
try:
    import openai
    import anthropic
    import google.generativeai as genai
    from config import Settings
    HAS_LLM_CLIENTS = True
except ImportError:
    HAS_LLM_CLIENTS = False
    logger.warning("Clientes LLM não disponíveis - modo fallback")


@dataclass
class PartnershipLLMInsights:
    """Insights gerados por LLM sobre uma parceria."""
    
    synergy_score: float  # 0-1 - Score de sinergia profissional
    compatibility_factors: List[str]  # Fatores de compatibilidade identificados
    strategic_opportunities: List[str]  # Oportunidades estratégicas
    potential_challenges: List[str]  # Possíveis desafios da parceria
    collaboration_style_match: str  # "excellent", "good", "fair", "poor"
    market_positioning_advantage: str  # Vantagem de posicionamento
    client_value_proposition: str  # Proposta de valor para clientes
    confidence_score: float  # 0-1 - Confiança da análise
    reasoning: str  # Explicação detalhada da recomendação


@dataclass
class LawyerProfileForPartnership:
    """Perfil de advogado otimizado para análise de parcerias."""
    
    lawyer_id: str
    name: str
    firm_name: Optional[str]
    experience_years: int
    specialization_areas: List[str]
    recent_cases_summary: str
    communication_style: str  # Inferido de reviews/interações
    collaboration_history: List[str]  # Histórico de parcerias
    market_reputation: str
    client_types: List[str]
    fee_structure_style: str  # "premium", "competitive", "value"
    geographic_focus: List[str]


class PartnershipLLMEnhancementService:
    """
    Serviço que usa LLMs para análise avançada de compatibilidade entre advogados.
    """
    
    def __init__(self):
        self.settings = Settings() if HAS_LLM_CLIENTS else None
        self.logger = logging.getLogger(__name__)
        
        # Inicializar clientes LLM
        self._init_llm_clients()
        
        # Cache de insights (evita re-análise)
        self._insights_cache: Dict[str, PartnershipLLMInsights] = {}

    def _init_llm_clients(self):
        """Inicializa clientes LLM disponíveis."""
        self.openai_client = None
        self.anthropic_client = None
        self.gemini_available = False
        
        if not HAS_LLM_CLIENTS or not self.settings:
            return
            
        # OpenAI
        if self.settings.OPENAI_API_KEY:
            self.openai_client = openai.AsyncOpenAI(
                api_key=self.settings.OPENAI_API_KEY
            )
            
        # Anthropic
        if self.settings.ANTHROPIC_API_KEY:
            self.anthropic_client = anthropic.AsyncAnthropic(
                api_key=self.settings.ANTHROPIC_API_KEY
            )
            
        # Gemini
        if self.settings.GEMINI_API_KEY:
            genai.configure(api_key=self.settings.GEMINI_API_KEY)
            self.gemini_available = True

    async def analyze_partnership_synergy(
        self,
        lawyer_a: LawyerProfileForPartnership,
        lawyer_b: LawyerProfileForPartnership,
        collaboration_context: Optional[str] = None
    ) -> PartnershipLLMInsights:
        """
        Analisa sinergia entre dois advogados usando LLMs.
        
        Args:
            lawyer_a: Perfil do primeiro advogado
            lawyer_b: Perfil do segundo advogado
            collaboration_context: Contexto específico da colaboração
            
        Returns:
            Insights detalhados sobre a parceria
        """
        
        # Verificar cache
        cache_key = f"{lawyer_a.lawyer_id}:{lawyer_b.lawyer_id}"
        if cache_key in self._insights_cache:
            return self._insights_cache[cache_key]
        
        try:
            # Preparar prompt de análise
            analysis_prompt = self._build_partnership_analysis_prompt(
                lawyer_a, lawyer_b, collaboration_context
            )
            
            # Tentar diferentes LLMs em ordem de preferência
            insights = await self._try_llm_analysis(analysis_prompt)
            
            if insights:
                # Cache do resultado
                self._insights_cache[cache_key] = insights
                
                self.logger.info(f"Análise LLM completa para parceria {cache_key}", {
                    "synergy_score": insights.synergy_score,
                    "compatibility": insights.collaboration_style_match,
                    "confidence": insights.confidence_score
                })
                
                return insights
            else:
                # Fallback para análise tradicional
                return self._fallback_analysis(lawyer_a, lawyer_b)
                
        except Exception as e:
            self.logger.error(f"Erro na análise LLM de parceria: {e}")
            return self._fallback_analysis(lawyer_a, lawyer_b)

    def _build_partnership_analysis_prompt(
        self,
        lawyer_a: LawyerProfileForPartnership,
        lawyer_b: LawyerProfileForPartnership,
        context: Optional[str]
    ) -> str:
        """Constrói prompt estruturado para análise de parceria."""
        
        context_section = f"\n**Contexto da Colaboração:** {context}" if context else ""
        
        prompt = f"""
Você é um consultor especializado em desenvolvimento de parcerias estratégicas no setor jurídico. 
Analise a compatibilidade e sinergia entre os dois advogados abaixo.

**ADVOGADO A:**
- Nome: {lawyer_a.name}
- Escritório: {lawyer_a.firm_name or 'Independente'}
- Experiência: {lawyer_a.experience_years} anos
- Especialidades: {', '.join(lawyer_a.specialization_areas)}
- Estilo: {lawyer_a.communication_style}
- Clientes: {', '.join(lawyer_a.client_types)}
- Reputação: {lawyer_a.market_reputation}
- Foco Geográfico: {', '.join(lawyer_a.geographic_focus)}

**ADVOGADO B:**
- Nome: {lawyer_b.name}
- Escritório: {lawyer_b.firm_name or 'Independente'}
- Experiência: {lawyer_b.experience_years} anos
- Especialidades: {', '.join(lawyer_b.specialization_areas)}
- Estilo: {lawyer_b.communication_style}
- Clientes: {', '.join(lawyer_b.client_types)}
- Reputação: {lawyer_b.market_reputation}
- Foco Geográfico: {', '.join(lawyer_b.geographic_focus)}
{context_section}

**ANÁLISE SOLICITADA:**
Avalie a sinergia profissional entre estes advogados considerando:

1. **Complementaridade de Especialidades**: Como as expertises se complementam?
2. **Compatibilidade de Estilo**: Os estilos de trabalho são compatíveis?
3. **Oportunidades de Mercado**: Que oportunidades estratégicas essa parceria criaria?
4. **Proposição de Valor**: Que valor essa parceria entregaria aos clientes?
5. **Desafios Potenciais**: Quais obstáculos poderiam surgir?

**FORMATO DE RESPOSTA (JSON apenas):**
{{
    "synergy_score": <float entre 0 e 1>,
    "compatibility_factors": [<lista de fatores positivos>],
    "strategic_opportunities": [<lista de oportunidades>],
    "potential_challenges": [<lista de desafios>],
    "collaboration_style_match": "<excellent/good/fair/poor>",
    "market_positioning_advantage": "<explicação da vantagem competitiva>",
    "client_value_proposition": "<proposta de valor para clientes>",
    "confidence_score": <float entre 0 e 1>,
    "reasoning": "<explicação detalhada em 2-3 sentenças>"
}}

Responda APENAS com o JSON, sem texto adicional.
"""
        return prompt

    async def _try_llm_analysis(self, prompt: str) -> Optional[PartnershipLLMInsights]:
        """Tenta análise com diferentes LLMs em ordem de preferência."""
        
        # 1. Tentar Gemini (mais econômico)
        if self.gemini_available:
            try:
                model = genai.GenerativeModel("gemini-pro")
                response = await asyncio.wait_for(
                    model.generate_content_async(prompt),
                    timeout=30
                )
                
                # Extrair JSON da resposta
                import re
                json_match = re.search(r'\{.*\}', response.text, re.DOTALL)
                if json_match:
                    data = json.loads(json_match.group(0))
                    return self._parse_llm_response(data)
                    
            except Exception as e:
                self.logger.warning(f"Gemini analysis failed: {e}")
        
        # 2. Tentar Claude (melhor qualidade)
        if self.anthropic_client:
            try:
                message = await self.anthropic_client.messages.create(
                    model="claude-3-5-sonnet-20240620",
                    max_tokens=1000,
                    temperature=0.3,
                    messages=[{"role": "user", "content": prompt}]
                )
                
                content = message.content[0].text
                
                # Extrair JSON
                import re
                json_match = re.search(r'\{.*\}', content, re.DOTALL)
                if json_match:
                    data = json.loads(json_match.group(0))
                    return self._parse_llm_response(data)
                    
            except Exception as e:
                self.logger.warning(f"Claude analysis failed: {e}")
        
        # 3. Tentar OpenAI (fallback)
        if self.openai_client:
            try:
                response = await self.openai_client.chat.completions.create(
                    model="gpt-4o",
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=1000,
                    temperature=0.3,
                    response_format={"type": "json_object"}
                )
                
                content = response.choices[0].message.content
                data = json.loads(content)
                return self._parse_llm_response(data)
                
            except Exception as e:
                self.logger.warning(f"OpenAI analysis failed: {e}")
        
        return None

    def _parse_llm_response(self, data: Dict[str, Any]) -> PartnershipLLMInsights:
        """Converte resposta LLM em dataclass estruturada."""
        
        return PartnershipLLMInsights(
            synergy_score=float(data.get("synergy_score", 0.5)),
            compatibility_factors=data.get("compatibility_factors", []),
            strategic_opportunities=data.get("strategic_opportunities", []),
            potential_challenges=data.get("potential_challenges", []),
            collaboration_style_match=data.get("collaboration_style_match", "fair"),
            market_positioning_advantage=data.get("market_positioning_advantage", ""),
            client_value_proposition=data.get("client_value_proposition", ""),
            confidence_score=float(data.get("confidence_score", 0.7)),
            reasoning=data.get("reasoning", "Análise baseada em compatibilidade geral")
        )

    def _fallback_analysis(
        self,
        lawyer_a: LawyerProfileForPartnership,
        lawyer_b: LawyerProfileForPartnership
    ) -> PartnershipLLMInsights:
        """Análise de fallback quando LLMs não estão disponíveis."""
        
        # Análise heurística simples
        specialty_overlap = len(
            set(lawyer_a.specialization_areas) & set(lawyer_b.specialization_areas)
        )
        
        # Score baseado em complementaridade vs sobreposição
        if specialty_overlap == 0:
            synergy_score = 0.8  # Alta complementaridade
            compatibility = "excellent"
        elif specialty_overlap <= 1:
            synergy_score = 0.6  # Boa complementaridade
            compatibility = "good"
        else:
            synergy_score = 0.4  # Muita sobreposição
            compatibility = "fair"
        
        # Análise de experiência
        exp_diff = abs(lawyer_a.experience_years - lawyer_b.experience_years)
        if exp_diff > 10:
            synergy_score *= 0.9  # Pequena penalidade por grande diferença
        
        return PartnershipLLMInsights(
            synergy_score=synergy_score,
            compatibility_factors=["Análise heurística baseada em especialidades"],
            strategic_opportunities=["Complementaridade de expertise"],
            potential_challenges=["Análise limitada sem LLM"],
            collaboration_style_match=compatibility,
            market_positioning_advantage="Expansão de portfólio de serviços",
            client_value_proposition="Maior cobertura de especialidades",
            confidence_score=0.5,  # Baixa confiança sem LLM
            reasoning="Análise baseada em heurísticas simples (LLM indisponível)"
        )

    async def enhance_partnership_recommendations(
        self,
        recommendations: List[Any],  # Lista de PartnershipRecommendation
        target_lawyer_profile: LawyerProfileForPartnership
    ) -> List[Any]:
        """
        Aprimora recomendações existentes com insights LLM.
        
        Args:
            recommendations: Lista de recomendações do sistema tradicional
            target_lawyer_profile: Perfil do advogado que busca parcerias
            
        Returns:
            Lista de recomendações aprimoradas com insights LLM
        """
        
        enhanced_recommendations = []
        
        for rec in recommendations:
            try:
                # Criar perfil do candidato para análise LLM
                candidate_profile = LawyerProfileForPartnership(
                    lawyer_id=rec.lawyer_id,
                    name=rec.lawyer_name,
                    firm_name=rec.firm_name,
                    experience_years=10,  # Mock - deveria vir do banco
                    specialization_areas=rec.compatibility_clusters,
                    recent_cases_summary="",  # Mock - deveria vir do banco
                    communication_style="professional",  # Mock
                    collaboration_history=[],  # Mock
                    market_reputation="established",  # Mock
                    client_types=["corporate"],  # Mock
                    fee_structure_style="competitive",  # Mock
                    geographic_focus=["São Paulo"]  # Mock
                )
                
                # Análise LLM
                llm_insights = await self.analyze_partnership_synergy(
                    target_lawyer_profile, candidate_profile
                )
                
                # Combinar score tradicional com insights LLM
                traditional_score = rec.final_score
                llm_score = llm_insights.synergy_score
                
                # Score híbrido: 70% tradicional + 30% LLM
                enhanced_score = 0.7 * traditional_score + 0.3 * llm_score
                
                # Aprimorar explicação com insights LLM
                enhanced_reason = self._combine_traditional_llm_reasoning(
                    rec.recommendation_reason,
                    llm_insights
                )
                
                # Atualizar recomendação
                rec.final_score = enhanced_score
                rec.recommendation_reason = enhanced_reason
                
                # Adicionar insights LLM como metadados
                rec.llm_insights = llm_insights
                rec.llm_enhanced = True
                
                enhanced_recommendations.append(rec)
                
            except Exception as e:
                self.logger.error(f"Erro ao aprimorar recomendação {rec.lawyer_id}: {e}")
                # Manter recomendação original em caso de erro
                rec.llm_enhanced = False
                enhanced_recommendations.append(rec)
        
        # Re-ordenar por score aprimorado
        enhanced_recommendations.sort(key=lambda r: r.final_score, reverse=True)
        
        return enhanced_recommendations

    def _combine_traditional_llm_reasoning(
        self,
        traditional_reason: str,
        llm_insights: PartnershipLLMInsights
    ) -> str:
        """Combina explicação tradicional com insights LLM."""
        
        llm_highlights = []
        
        if llm_insights.synergy_score > 0.7:
            llm_highlights.append("excelente sinergia profissional")
        
        if llm_insights.strategic_opportunities:
            top_opportunity = llm_insights.strategic_opportunities[0]
            llm_highlights.append(f"oportunidade de {top_opportunity.lower()}")
        
        if llm_insights.collaboration_style_match in ["excellent", "good"]:
            llm_highlights.append("alta compatibilidade de estilo")
        
        if llm_highlights:
            llm_addition = f" Análise avançada identifica: {', '.join(llm_highlights)}."
            return traditional_reason + llm_addition
        else:
            return traditional_reason + f" {llm_insights.reasoning}"


# Factory function para integração fácil
def create_partnership_llm_enhancer() -> PartnershipLLMEnhancementService:
    """Cria instância do serviço de aprimoramento LLM."""
    return PartnershipLLMEnhancementService()


# Exemplo de uso
async def example_usage():
    """Exemplo de como usar o serviço."""
    
    enhancer = create_partnership_llm_enhancer()
    
    # Perfis de exemplo
    lawyer_a = LawyerProfileForPartnership(
        lawyer_id="LAW001",
        name="Ana Silva",
        firm_name="Silva & Associados",
        experience_years=8,
        specialization_areas=["Direito Empresarial", "Startups"],
        recent_cases_summary="Consultoria para fintech em rodada de investimento",
        communication_style="assertiva e técnica",
        collaboration_history=["Parcerias em M&A"],
        market_reputation="emergente em fintech",
        client_types=["startups", "scale-ups"],
        fee_structure_style="competitive",
        geographic_focus=["São Paulo", "Rio de Janeiro"]
    )
    
    lawyer_b = LawyerProfileForPartnership(
        lawyer_id="LAW002", 
        name="Carlos Santos",
        firm_name="Santos Legal",
        experience_years=15,
        specialization_areas=["Direito Tributário", "Compliance"],
        recent_cases_summary="Reestruturação tributária para multinacional",
        communication_style="conservador e detalhista",
        collaboration_history=["Assessoria fiscal complexa"],
        market_reputation="especialista sênior",
        client_types=["multinacionais", "empresas de médio porte"],
        fee_structure_style="premium",
        geographic_focus=["São Paulo"]
    )
    
    # Análise de sinergia
    insights = await enhancer.analyze_partnership_synergy(
        lawyer_a, lawyer_b, 
        "Assessoria completa para startup em expansão internacional"
    )
    
    print(f"Sinergia Score: {insights.synergy_score:.2f}")
    print(f"Compatibilidade: {insights.collaboration_style_match}")
    print(f"Oportunidades: {insights.strategic_opportunities}")
    print(f"Reasoning: {insights.reasoning}")


if __name__ == "__main__":
    import asyncio
    asyncio.run(example_usage()) 