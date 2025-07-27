"""
Serviço de Análise Contextual de Casos com LLM
==============================================

Este serviço usa LLMs para analisar casos de forma contextual,
extraindo nuances que algoritmos tradicionais não conseguem.
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
class CaseContextInsights:
    """Insights contextuais extraídos do caso via LLM"""
    complexity_factors: List[str]  # Fatores específicos de complexidade
    urgency_reasoning: str  # Por que é urgente
    required_expertise: List[str]  # Expertises específicas necessárias
    case_sensitivity: str  # "high", "medium", "low"
    expected_duration: str  # Duração estimada do caso
    communication_needs: str  # Necessidades de comunicação
    client_personality_type: str  # Tipo de personalidade do cliente
    success_probability: float  # 0-1
    key_challenges: List[str]  # Principais desafios do caso
    recommended_approach: str  # Abordagem recomendada
    confidence_score: float  # 0-1

class CaseContextAnalysisService:
    """
    Serviço que usa LLMs para análise contextual profunda de casos.
    
    Benefícios:
    - Compreende nuances do caso
    - Identifica fatores de complexidade não óbvios
    - Sugere perfil ideal de advogado
    - Avalia probabilidade de sucesso
    """
    
    def __init__(self):
        # Configurar clientes LLM
        self.gemini_client = None
        self.anthropic_client = None
        self.openai_client = None
        
        # Inicializar Gemini (primário)
        if settings.GEMINI_API_KEY:
            genai.configure(api_key=settings.GEMINI_API_KEY)
            self.gemini_client = genai.GenerativeModel("gemini-pro")
        
        # Inicializar Claude (melhor para análise jurídica)
        if settings.ANTHROPIC_API_KEY:
            self.anthropic_client = anthropic.AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)
        
        # Inicializar OpenAI (backup)
        if settings.OPENAI_API_KEY:
            self.openai_client = openai.AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
    
    async def analyze_case_context(self, case_data: Dict[str, Any]) -> CaseContextInsights:
        """
        Analisa o contexto completo de um caso usando LLM.
        
        Args:
            case_data: Dados do caso completo
        
        Returns:
            CaseContextInsights com análise contextual
        """
        
        context = self._prepare_case_context(case_data)
        
        # Usar Claude como primário para análise jurídica
        if self.anthropic_client:
            try:
                return await self._analyze_with_claude(context)
            except Exception as e:
                print(f"Falha no Claude para análise de caso: {e}")
        
        # Fallback para Gemini
        if self.gemini_client:
            try:
                return await self._analyze_with_gemini(context)
            except Exception as e:
                print(f"Falha no Gemini para análise de caso: {e}")
        
        # Fallback para OpenAI
        if self.openai_client:
            try:
                return await self._analyze_with_openai(context)
            except Exception as e:
                print(f"Falha no OpenAI para análise de caso: {e}")
        
        return self._basic_fallback_analysis(case_data)
    
    def _prepare_case_context(self, case_data: Dict[str, Any]) -> str:
        """Prepara contexto do caso para análise LLM"""
        
        context = f"""
        CASO PARA ANÁLISE CONTEXTUAL:
        
        === INFORMAÇÕES BÁSICAS ===
        Área: {case_data.get('area', 'N/A')}
        Subárea: {case_data.get('subarea', 'N/A')}
        Urgência: {case_data.get('urgency_h', 72)} horas
        Resumo: {case_data.get('summary', 'N/A')}
        
        === DETALHES DO CLIENTE ===
        Tipo de cliente: {case_data.get('client_type', 'N/A')}
        Localização: {case_data.get('location', 'N/A')}
        Budget máximo: {case_data.get('expected_fee_max', 'N/A')}
        Budget mínimo: {case_data.get('expected_fee_min', 'N/A')}
        
        === CONTEXTO COMPLETO ===
        Descrição completa: {case_data.get('full_description', 'N/A')}
        Partes envolvidas: {case_data.get('parties_involved', [])}
        Documentos disponíveis: {case_data.get('documents', [])}
        Tentativas anteriores: {case_data.get('previous_attempts', [])}
        
        === EXPECTATIVAS ===
        Resultado esperado: {case_data.get('expected_outcome', 'N/A')}
        Prazo desejado: {case_data.get('desired_timeline', 'N/A')}
        Preferências de comunicação: {case_data.get('communication_preferences', 'N/A')}
        """
        
        return context
    
    async def _analyze_with_claude(self, context: str) -> CaseContextInsights:
        """Análise usando Claude 3.5 Sonnet"""
        
        prompt = f"""
        Você é um experiente advogado sênior brasileiro com 20+ anos de experiência. 
        Analise este caso e extraia insights contextuais profundos.

        {context}

        Forneça uma análise JSON estruturada:
        {{
            "complexity_factors": ["fator 1", "fator 2"],
            "urgency_reasoning": "Por que este caso é urgente",
            "required_expertise": ["expertise 1", "expertise 2"],
            "case_sensitivity": "high",
            "expected_duration": "3-6 meses",
            "communication_needs": "comunicação frequente",
            "client_personality_type": "analítico",
            "success_probability": 0.75,
            "key_challenges": ["desafio 1", "desafio 2"],
            "recommended_approach": "estratégia recomendada",
            "confidence_score": 0.85
        }}

        Analise considerando:
        - Fatores específicos que tornam o caso complexo
        - Expertises muito específicas necessárias
        - Personalidade do cliente inferida do contexto
        - Desafios únicos que este caso apresenta
        - Probabilidade realista de sucesso
        """
        
        message = await self.anthropic_client.messages.create(
            model="claude-3-5-sonnet-20240620",
            max_tokens=1024,
            messages=[{"role": "user", "content": prompt}]
        )
        
        response_text = message.content[0].text
        import re
        match = re.search(r'\{.*\}', response_text, re.DOTALL)
        if match:
            analysis_data = json.loads(match.group(0))
            return CaseContextInsights(**analysis_data)
        else:
            raise ValueError("Resposta do Claude não contém JSON válido")
    
    async def _analyze_with_gemini(self, context: str) -> CaseContextInsights:
        """Análise usando Gemini Pro"""
        
        prompt = f"""
        Analise este caso jurídico e extraia insights contextuais:

        {context}

        Responda apenas com JSON no formato especificado, focando em análise contextual profunda.
        """
        
        response = await asyncio.wait_for(
            self.gemini_client.generate_content_async(prompt),
            timeout=30
        )
        
        import re
        response_text = response.text
        match = re.search(r'\{.*\}', response_text, re.DOTALL)
        if match:
            analysis_data = json.loads(match.group(0))
            return CaseContextInsights(**analysis_data)
        else:
            raise ValueError("Resposta do Gemini não contém JSON válido")
    
    async def _analyze_with_openai(self, context: str) -> CaseContextInsights:
        """Análise usando GPT-4"""
        
        response = await self.openai_client.chat.completions.create(
            model="gpt-4o",
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": "Você é um especialista em análise jurídica contextual."},
                {"role": "user", "content": f"Analise este caso: {context}"}
            ]
        )
        
        analysis_data = json.loads(response.choices[0].message.content)
        return CaseContextInsights(**analysis_data)
    
    def _basic_fallback_analysis(self, case_data: Dict[str, Any]) -> CaseContextInsights:
        """Análise básica quando LLMs não estão disponíveis"""
        
        urgency_h = case_data.get('urgency_h', 72)
        area = case_data.get('area', 'Geral')
        
        return CaseContextInsights(
            complexity_factors=["análise tradicional"],
            urgency_reasoning=f"Prazo de {urgency_h} horas",
            required_expertise=[area],
            case_sensitivity="medium",
            expected_duration="indefinido",
            communication_needs="padrão",
            client_personality_type="desconhecido",
            success_probability=0.5,
            key_challenges=["análise limitada"],
            recommended_approach="abordagem padrão",
            confidence_score=0.3
        )

    async def enhance_case_for_matching(self, case_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Enriquece dados do caso com insights LLM para melhor matching.
        
        Args:
            case_data: Dados originais do caso
        
        Returns:
            Dados do caso enriquecidos com insights LLM
        """
        
        # Obter insights contextuais
        insights = await self.analyze_case_context(case_data)
        
        # Adicionar insights ao caso
        enhanced_case = case_data.copy()
        enhanced_case.update({
            'llm_insights': insights.__dict__,
            'enhanced_complexity_factors': insights.complexity_factors,
            'required_expertise_detailed': insights.required_expertise,
            'communication_style_needed': insights.communication_needs,
            'success_probability': insights.success_probability,
            'key_challenges': insights.key_challenges
        })
        