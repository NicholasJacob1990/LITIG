"""
Serviço de Análise Inteligente de Perfil de Advogados com LLM
===========================================================

Este serviço usa LLMs para analisar currículos e perfis de advogados,
extraindo insights que o algoritmo tradicional não consegue capturar.
"""

import asyncio
import json
import os
from typing import Dict, List, Optional, Any
from dataclasses import dataclass

import openai
import anthropic
import google.generativeai as genai

# Import config sem dependências relativas
try:
    from config import Settings
except ImportError:
    import sys
    sys.path.append('..')
    from config import Settings

settings = Settings()

@dataclass
class LawyerProfileInsights:
    """Insights extraídos do perfil do advogado via LLM"""
    expertise_level: float  # 0-1
    specialization_confidence: float  # 0-1
    communication_style: str  # "formal", "accessible", "technical"
    experience_quality: str  # "junior", "mid", "senior", "expert"
    niche_specialties: List[str]  # Especialidades específicas detectadas
    soft_skills_score: float  # 0-1
    innovation_indicator: float  # 0-1 (usa tecnologia, métodos modernos)
    client_profile_match: List[str]  # Tipos de cliente que mais combina
    risk_assessment: str  # "conservative", "balanced", "aggressive"
    confidence_score: float  # 0-1 (confiança da análise)

class LawyerProfileAnalysisService:
    """
    Serviço que usa LLMs para análise profunda de perfis de advogados.
    
    Benefícios sobre o algoritmo tradicional:
    - Compreende contexto e nuances
    - Identifica soft skills
    - Detecta especialidades de nicho
    - Avalia qualidade da experiência (não só quantidade)
    """
    
    def __init__(self):
        # Configurar clientes LLM
        self.gemini_client = None
        self.anthropic_client = None
        self.openai_client = None
        
        # Inicializar Gemini (mais econômico para análise em lote)
        if settings.GEMINI_API_KEY:
            genai.configure(api_key=settings.GEMINI_API_KEY)
            self.gemini_client = genai.GenerativeModel("gemini-pro")
        
        # Inicializar Claude (melhor para análise qualitativa)
        if settings.ANTHROPIC_API_KEY:
            self.anthropic_client = anthropic.AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)
        
        # Inicializar OpenAI (backup)
        if settings.OPENAI_API_KEY:
            self.openai_client = openai.AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
    
    async def analyze_lawyer_profile(self, lawyer_data: Dict[str, Any]) -> LawyerProfileInsights:
        """
        Analisa o perfil completo de um advogado usando LLM.
        
        Args:
            lawyer_data: Dados do advogado (currículo, cases, reviews, etc.)
        
        Returns:
            LawyerProfileInsights com análise detalhada
        """
        
        # Preparar contexto para análise
        context = self._prepare_analysis_context(lawyer_data)
        
        # Usar Gemini como primário (mais econômico)
        if self.gemini_client:
            try:
                return await self._analyze_with_gemini(context)
            except Exception as e:
                print(f"Falha no Gemini para análise de perfil: {e}")
        
        # Fallback para Claude (melhor qualidade)
        if self.anthropic_client:
            try:
                return await self._analyze_with_claude(context)
            except Exception as e:
                print(f"Falha no Claude para análise de perfil: {e}")
        
        # Fallback final para OpenAI
        if self.openai_client:
            try:
                return await self._analyze_with_openai(context)
            except Exception as e:
                print(f"Falha no OpenAI para análise de perfil: {e}")
        
        # Fallback para análise básica
        return self._basic_fallback_analysis(lawyer_data)
    
    def _prepare_analysis_context(self, lawyer_data: Dict[str, Any]) -> str:
        """Prepara o contexto formatado para análise LLM"""
        
        curriculo = lawyer_data.get('curriculo_json', {})
        cases = lawyer_data.get('casos_historicos', [])
        reviews = lawyer_data.get('reviews', [])
        
        context = f"""
        PERFIL DO ADVOGADO PARA ANÁLISE:
        
        === DADOS BÁSICOS ===
        Nome: {lawyer_data.get('nome', 'N/A')}
        OAB: {lawyer_data.get('oab_numero', 'N/A')} - {lawyer_data.get('uf', 'N/A')}
        Anos de Experiência: {curriculo.get('anos_experiencia', 0)}
        
        === FORMAÇÃO ACADÊMICA ===
        Graduação: {curriculo.get('graduacao', {})}
        Pós-Graduações: {curriculo.get('pos_graduacoes', [])}
        Publicações: {curriculo.get('publicacoes', [])}
        
        === EXPERIÊNCIA PROFISSIONAL ===
        Escritórios: {curriculo.get('escritorios', [])}
        Cargos: {curriculo.get('cargos', [])}
        Especializações: {lawyer_data.get('tags_expertise', [])}
        
        === HISTÓRICO DE CASOS ===
        Total de casos: {len(cases)}
        Casos recentes: {cases[:3] if cases else 'Nenhum'}
        
        === AVALIAÇÕES DE CLIENTES ===
        Total de reviews: {len(reviews)}
        Reviews recentes: {reviews[:5] if reviews else 'Nenhum'}
        
        === MÉTRICAS ATUAIS ===
        KPI: {lawyer_data.get('kpi', {})}
        Taxa de sucesso: {lawyer_data.get('kpi', {}).get('success_rate', 'N/A')}
        """
        
        return context
    
    async def _analyze_with_gemini(self, context: str) -> LawyerProfileInsights:
        """Análise usando Gemini Pro"""
        
        prompt = f"""
        Você é um especialista em análise de perfis profissionais do mercado jurídico brasileiro. 
        Analise o perfil do advogado abaixo e extraia insights profundos que vão além de métricas básicas.

        {context}

        Responda APENAS com um JSON no seguinte formato:
        {{
            "expertise_level": 0.85,
            "specialization_confidence": 0.92,
            "communication_style": "accessible",
            "experience_quality": "senior",
            "niche_specialties": ["direito digital", "startups"],
            "soft_skills_score": 0.78,
            "innovation_indicator": 0.65,
            "client_profile_match": ["empresas", "pessoas físicas"],
            "risk_assessment": "balanced",
            "confidence_score": 0.88,
            "analysis_reasoning": "Breve justificativa da análise"
        }}

        Critérios de análise:
        - expertise_level: Nível real de expertise (não só tempo de experiência)
        - specialization_confidence: Quão confiante é a especialização declarada
        - communication_style: Estilo de comunicação inferido
        - experience_quality: Qualidade da experiência profissional
        - niche_specialties: Especialidades específicas identificadas
        - soft_skills_score: Habilidades interpessoais inferidas dos reviews
        - innovation_indicator: Uso de tecnologia/métodos modernos
        - client_profile_match: Perfis de cliente que mais combinam
        - risk_assessment: Perfil de risco do advogado
        - confidence_score: Sua confiança nesta análise (0-1)
        """
        
        response = await asyncio.wait_for(
            self.gemini_client.generate_content_async(prompt),
            timeout=30
        )
        
        # Extrair JSON da resposta
        import re
        response_text = response.text
        match = re.search(r'\{.*\}', response_text, re.DOTALL)
        if match:
            analysis_data = json.loads(match.group(0))
            return LawyerProfileInsights(**analysis_data)
        else:
            raise ValueError("Resposta do Gemini não contém JSON válido")
    
    async def _analyze_with_claude(self, context: str) -> LawyerProfileInsights:
        """Análise usando Claude 3.5 Sonnet"""
        
        prompt = f"""
        Analise este perfil de advogado e extraia insights profundos para melhorar recomendações:

        {context}

        Forneça uma análise JSON estruturada focando em aspectos qualitativos que algoritmos tradicionais não capturam.
        """
        
        message = await self.anthropic_client.messages.create(
            model="claude-3-5-sonnet-20240620",
            max_tokens=1024,
            messages=[{"role": "user", "content": prompt}]
        )
        
        response_text = message.content[0].text
        # Processar resposta similar ao Gemini
        import re
        match = re.search(r'\{.*\}', response_text, re.DOTALL)
        if match:
            analysis_data = json.loads(match.group(0))
            return LawyerProfileInsights(**analysis_data)
        else:
            raise ValueError("Resposta do Claude não contém JSON válido")
    
    async def _analyze_with_openai(self, context: str) -> LawyerProfileInsights:
        """Análise usando GPT-4"""
        
        response = await self.openai_client.chat.completions.create(
            model="gpt-4o",
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": "Você é um especialista em análise de perfis jurídicos."},
                {"role": "user", "content": f"Analise este perfil: {context}"}
            ]
        )
        
        analysis_data = json.loads(response.choices[0].message.content)
        return LawyerProfileInsights(**analysis_data)
    
    def _basic_fallback_analysis(self, lawyer_data: Dict[str, Any]) -> LawyerProfileInsights:
        """Análise básica quando LLMs não estão disponíveis"""
        
        curriculo = lawyer_data.get('curriculo_json', {})
        anos_exp = curriculo.get('anos_experiencia', 0)
        
        return LawyerProfileInsights(
            expertise_level=min(anos_exp / 20, 1.0),  # Normalizar por 20 anos
            specialization_confidence=0.5,  # Neutro
            communication_style="unknown",
            experience_quality="mid" if anos_exp > 5 else "junior",
            niche_specialties=lawyer_data.get('tags_expertise', [])[:3],
            soft_skills_score=0.5,
            innovation_indicator=0.5,
            client_profile_match=["geral"],
            risk_assessment="balanced",
            confidence_score=0.3  # Baixa confiança na análise básica
        )

    async def enhance_matching_with_llm_insights(
        self, 
        case_data: Dict[str, Any], 
        candidates: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """
        Usa insights LLM para melhorar o matching de candidatos.
        
        Args:
            case_data: Dados do caso
            candidates: Lista de advogados candidatos
        
        Returns:
            Lista de candidatos com scores LLM adicionados
        """
        
        enhanced_candidates = []
        
        for candidate in candidates:
            # Obter insights LLM do advogado
            insights = await self.analyze_lawyer_profile(candidate)
            
            # Calcular score de compatibilidade baseado em LLM
            llm_compatibility_score = await self._calculate_llm_compatibility(
                case_data, candidate, insights
            )
            
            # Adicionar score LLM ao candidato
            candidate['llm_insights'] = insights.__dict__
            candidate['llm_compatibility_score'] = llm_compatibility_score
            
            enhanced_candidates.append(candidate)
        
        return enhanced_candidates
    
    async def _calculate_llm_compatibility(
        self, 
        case_data: Dict[str, Any], 
        lawyer_data: Dict[str, Any], 
        insights: LawyerProfileInsights
    ) -> float:
        """
        Calcula score de compatibilidade baseado em insights LLM.
        
        Este é um exemplo de como usar LLM para análise contextual
        que algoritmos tradicionais não conseguem fazer.
        """
        
        if not self.gemini_client:
            return 0.5  # Score neutro se LLM não disponível
        
        prompt = f"""
        Analise a compatibilidade entre este caso e este advogado:
        
        CASO:
        Área: {case_data.get('area', 'N/A')}
        Complexidade: {case_data.get('complexity', 'medium')}
        Urgência: {case_data.get('urgency_h', 72)} horas
        Budget: {case_data.get('expected_fee_max', 'N/A')}
        Resumo: {case_data.get('summary', 'N/A')}
        
        ADVOGADO:
        Nome: {lawyer_data.get('nome', 'N/A')}
        Experiência: {insights.experience_quality}
        Especialização: {insights.niche_specialties}
        Estilo: {insights.communication_style}
        Score de soft skills: {insights.soft_skills_score}
        Perfil de risco: {insights.risk_assessment}
        
        Responda apenas com um número de 0 a 1 representando a compatibilidade.
        Considere fatores como:
        - Match de especialização específica
        - Compatibilidade de estilo comunicativo
        - Adequação do perfil de risco
        - Experiência para a complexidade do caso
        """
        
        try:
            response = await asyncio.wait_for(
                self.gemini_client.generate_content_async(prompt),
                timeout=15
            )
            
            # Extrair número da resposta
            import re
            score_match = re.search(r'0\.\d+|1\.0|0|1', response.text)
            if score_match:
                return float(score_match.group(0))
            else:
                return 0.5
                
        except Exception as e:
            print(f"Erro no cálculo de compatibilidade LLM: {e}")