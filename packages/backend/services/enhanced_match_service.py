"""
Serviço de Matching Aprimorado com LLMs
=======================================

Este serviço combina o algoritmo tradicional de matching com análises LLM
para produzir recomendações mais inteligentes e contextuais.
"""

import asyncio
import json
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass

from .lawyer_profile_analysis_service import LawyerProfileAnalysisService
from .case_context_analysis_service import CaseContextAnalysisService
from .match_service import find_and_notify_matches  # Algoritmo tradicional

@dataclass
class EnhancedMatchResult:
    """Resultado de matching aprimorado com insights LLM"""
    lawyer_id: str
    traditional_score: float  # Score do algoritmo tradicional
    llm_compatibility_score: float  # Score LLM
    combined_score: float  # Score final combinado
    match_reasoning: str  # Explicação LLM do porquê do match
    confidence_level: str  # "high", "medium", "low"
    insights: Dict[str, Any]  # Insights detalhados

class EnhancedMatchService:
    """
    Serviço que combina matching tradicional com análises LLM.
    
    Fluxo:
    1. Executa algoritmo tradicional (velocidade)
    2. Analisa caso com LLM (contexto)
    3. Analisa top candidatos com LLM (qualidade)
    4. Combina scores para ranking final
    5. Gera explicações inteligentes
    """
    
    def __init__(self):
        self.lawyer_analysis_service = LawyerProfileAnalysisService()
        self.case_analysis_service = CaseContextAnalysisService()
        
        # Pesos para combinação de scores
        self.traditional_weight = 0.6  # Algoritmo tradicional tem peso maior
        self.llm_weight = 0.4  # LLM adiciona nuances
        
        # Configurações
        self.enable_llm_analysis = True  # Pode ser desabilitado via config
        self.max_llm_candidates = 15  # Limitar análise LLM aos top candidatos
    
    async def find_enhanced_matches(
        self, 
        case_data: Dict[str, Any], 
        top_n: int = 10,
        enable_explanations: bool = True
    ) -> List[EnhancedMatchResult]:
        """
        Encontra matches usando algoritmo tradicional + LLM.
        
        Args:
            case_data: Dados do caso
            top_n: Número de matches finais desejados
            enable_explanations: Se deve gerar explicações LLM
        
        Returns:
            Lista de matches aprimorados com insights LLM
        """
        
        # Etapa 1: Executar algoritmo tradicional (rápido)
        traditional_matches = await self._get_traditional_matches(case_data, top_n * 2)
        
        if not traditional_matches:
            return []
        
        # Etapa 2: Análise LLM do caso (se habilitado)
        enhanced_case = case_data
        if self.enable_llm_analysis:
            try:
                enhanced_case = await self.case_analysis_service.enhance_case_for_matching(case_data)
            except Exception as e:
                print(f"Falha na análise LLM do caso: {e}")
        
        # Etapa 3: Análise LLM dos top candidatos
        enhanced_results = []
        
        # Limitar análise LLM aos melhores candidatos (performance)
        candidates_for_llm = traditional_matches[:self.max_llm_candidates]
        
        # Processar candidatos em paralelo (mas com limite)
        semaphore = asyncio.Semaphore(3)  # Máximo 3 análises LLM simultâneas
        
        tasks = [
            self._enhance_single_match(semaphore, enhanced_case, match, enable_explanations)
            for match in candidates_for_llm
        ]
        
        enhanced_candidates = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Filtrar resultados com erro
        for result in enhanced_candidates:
            if isinstance(result, EnhancedMatchResult):
                enhanced_results.append(result)
            elif isinstance(result, Exception):
                print(f"Erro na análise LLM: {result}")
        
        # Etapa 4: Combinar scores e rankear
        final_results = self._combine_and_rank_scores(enhanced_results)
        
        # Retornar top_n resultados finais
        return final_results[:top_n]
    
    async def _get_traditional_matches(
        self, 
        case_data: Dict[str, Any], 
        limit: int
    ) -> List[Dict[str, Any]]:
        """
        Executa o algoritmo tradicional de matching.
        
        Returns:
            Lista de matches do algoritmo tradicional
        """
        
        try:
            # Usar o serviço de matching existente
            from ..algoritmo_match import MatchingAlgorithm, Case, Lawyer
            
            # Converter case_data para formato do algoritmo
            case = Case(
                id=case_data.get('id'),
                area=case_data.get('area'),
                coords=(case_data.get('latitude', 0), case_data.get('longitude', 0)),
                expected_fee_max=case_data.get('expected_fee_max', 0),
                expected_fee_min=case_data.get('expected_fee_min', 0)
            )
            
            # Buscar candidatos do banco
            # (Simplificado - implementação real carregaria do banco)
            candidates = await self._load_candidates_from_db(case_data)
            
            # Executar algoritmo tradicional
            algo = MatchingAlgorithm()
            ranked_lawyers = await algo.rank(case, candidates, top_n=limit)
            
            return [
                {
                    'lawyer_id': lawyer.id,
                    'traditional_score': lawyer.score,
                    'lawyer_data': lawyer.__dict__
                }
                for lawyer in ranked_lawyers
            ]
            
        except Exception as e:
            print(f"Erro no algoritmo tradicional: {e}")
            return []
    
    async def _load_candidates_from_db(self, case_data: Dict[str, Any]) -> List[Any]:
        """Carrega candidatos do banco de dados (implementação simplificada)"""
        # TODO: Implementar carregamento real do banco
        return []
    
    async def _enhance_single_match(
        self,
        semaphore: asyncio.Semaphore,
        case_data: Dict[str, Any],
        match: Dict[str, Any],
        enable_explanations: bool
    ) -> EnhancedMatchResult:
        """
        Analisa um único match com LLM.
        """
        
        async with semaphore:
            try:
                lawyer_data = match['lawyer_data']
                traditional_score = match['traditional_score']
                
                # Análise LLM do perfil do advogado
                if self.enable_llm_analysis:
                    insights = await self.lawyer_analysis_service.analyze_lawyer_profile(lawyer_data)
                    
                    # Calcular compatibilidade LLM
                    llm_score = await self.lawyer_analysis_service._calculate_llm_compatibility(
                        case_data, lawyer_data, insights
                    )
                else:
                    insights = None
                    llm_score = 0.5
                
                # Combinar scores
                combined_score = (
                    self.traditional_weight * traditional_score +
                    self.llm_weight * llm_score
                )
                
                # Gerar explicação (se habilitado)
                match_reasoning = ""
                confidence_level = "medium"
                
                if enable_explanations and self.enable_llm_analysis:
                    try:
                        explanation_data = await self._generate_match_explanation(
                            case_data, lawyer_data, insights, combined_score
                        )
                        match_reasoning = explanation_data['reasoning']
                        confidence_level = explanation_data['confidence']
                    except Exception as e:
                        print(f"Erro na geração de explicação: {e}")
                        match_reasoning = "Explicação não disponível"
                
                return EnhancedMatchResult(
                    lawyer_id=match['lawyer_id'],
                    traditional_score=traditional_score,
                    llm_compatibility_score=llm_score,
                    combined_score=combined_score,
                    match_reasoning=match_reasoning,
                    confidence_level=confidence_level,
                    insights=insights.__dict__ if insights else {}
                )
                
            except Exception as e:
                print(f"Erro na análise LLM do match: {e}")
                # Fallback para resultado básico
                return EnhancedMatchResult(
                    lawyer_id=match['lawyer_id'],
                    traditional_score=match['traditional_score'],
                    llm_compatibility_score=0.5,
                    combined_score=match['traditional_score'],
                    match_reasoning="Análise LLM não disponível",
                    confidence_level="low",
                    insights={}
                )
    
    async def _generate_match_explanation(
        self,
        case_data: Dict[str, Any],
        lawyer_data: Dict[str, Any],
        insights: Any,
        combined_score: float
    ) -> Dict[str, str]:
        """
        Gera explicação inteligente do match usando LLM.
        """
        
        if not self.lawyer_analysis_service.gemini_client:
            return {
                'reasoning': 'Explicação não disponível',
                'confidence': 'low'
            }
        
        prompt = f"""
        Explique de forma clara e convincente por que este advogado é uma boa opção para este caso:

        CASO:
        - Área: {case_data.get('area', 'N/A')}
        - Resumo: {case_data.get('summary', 'N/A')}
        - Budget: {case_data.get('expected_fee_max', 'N/A')}
        - Urgência: {case_data.get('urgency_h', 72)} horas

        ADVOGADO:
        - Nome: {lawyer_data.get('nome', 'N/A')}
        - Experiência: {insights.experience_quality}
        - Especialidades: {insights.niche_specialties}
        - Score combinado: {combined_score:.2f}

        Forneça uma explicação de 2-3 frases que destaque os principais motivos do match.
        Seja específico e use dados concretos.

        Responda apenas com JSON:
        {{
            "reasoning": "Explicação clara do match",
            "confidence": "high|medium|low"
        }}
        """
        
        try:
            response = await asyncio.wait_for(
                self.lawyer_analysis_service.gemini_client.generate_content_async(prompt),
                timeout=15
            )
            
            import re
            response_text = response.text
            match = re.search(r'\{.*\}', response_text, re.DOTALL)
            if match:
                return json.loads(match.group(0))
            else:
                return {
                    'reasoning': 'Advogado com boa compatibilidade para o caso',
                    'confidence': 'medium'
                }
                
        except Exception as e:
            print(f"Erro na geração de explicação: {e}")
            return {
                'reasoning': 'Análise não disponível',
                'confidence': 'low'
            }
    
    def _combine_and_rank_scores(
        self, 
        enhanced_results: List[EnhancedMatchResult]
    ) -> List[EnhancedMatchResult]:
        """
        Combina scores tradicional + LLM e rankeia resultados finais.
        """
        
        # Normalizar scores combinados
        if enhanced_results:
            max_score = max(result.combined_score for result in enhanced_results)
            min_score = min(result.combined_score for result in enhanced_results)
            
            for result in enhanced_results:
                if max_score > min_score:
                    normalized_score = (result.combined_score - min_score) / (max_score - min_score)
                    result.combined_score = normalized_score
        
        # Rankear por score combinado
        enhanced_results.sort(key=lambda x: x.combined_score, reverse=True)
        
        return enhanced_results
    
    async def explain_match_decision(
        self,
        case_data: Dict[str, Any],
        selected_lawyer_id: str,
        all_matches: List[EnhancedMatchResult]
    ) -> str:
        """
        Gera explicação detalhada de por que um advogado específico foi escolhido.
        """
        
        selected_match = next(
            (match for match in all_matches if match.lawyer_id == selected_lawyer_id),
            None
        )
        
        if not selected_match:
            return "Advogado não encontrado nos resultados."
        
        if not self.lawyer_analysis_service.gemini_client:
            return selected_match.match_reasoning
        
        # Gerar explicação comparativa
        other_scores = [match.combined_score for match in all_matches[:5] if match.lawyer_id != selected_lawyer_id]
        avg_other_scores = sum(other_scores) / len(other_scores) if other_scores else 0
        
        prompt = f"""
        Explique de forma detalhada por que este advogado foi o melhor escolhido:

        ADVOGADO SELECIONADO:
        - Score: {selected_match.combined_score:.2f}
        - Reasoning: {selected_match.match_reasoning}
        
        CONTEXTO:
        - Score médio dos outros: {avg_other_scores:.2f}
        - Posição no ranking: 1º de {len(all_matches)}
        
        Forneça uma explicação de 3-4 frases destacando os diferenciais únicos deste advogado.
        """
        
        try:
            response = await asyncio.wait_for(
                self.lawyer_analysis_service.gemini_client.generate_content_async(prompt),
                timeout=15
            )
            
            return response.text
            
        except Exception as e:
            print(f"Erro na explicação detalhada: {e}")
            return selected_match.match_reasoning 