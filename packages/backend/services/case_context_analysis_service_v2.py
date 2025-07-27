"""
Case Context Analysis Service V2 - OpenRouter + Function Calling
===============================================================

Nova versão do serviço usando:
- Claude Sonnet 4 via OpenRouter (primário)
- Function Calling para extração estruturada
- Fallback de 4 níveis automático
- 100% compatível com versão atual

Migração conforme PLANO_EVOLUCAO_COMPLETO_OPENROUTER_LANGGRAPH.md
"""

import asyncio
import time
import logging
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

# Imports sem dependências relativas
try:
    from openrouter_client import get_openrouter_client
except ImportError:
    from services.openrouter_client import get_openrouter_client

try:
    from case_context_analysis_service import CaseContextInsights
except ImportError:
    from services.case_context_analysis_service import CaseContextInsights

logger = logging.getLogger(__name__)


@dataclass
class CaseContextInsightsV2(CaseContextInsights):
    """
    Resultado da análise de contexto V2.
    Herda de CaseContextInsights para manter 100% de compatibilidade.
    """
    model_used: Optional[str] = None
    fallback_level: Optional[int] = None
    processing_metadata: Optional[Dict[str, Any]] = None


class CaseContextAnalysisServiceV2:
    """
    Case Context Analysis V2: Análise contextual com Claude Sonnet 4 + Function Calling.
    
    Benefícios sobre V1:
    - Claude Sonnet 4: Superior capacidade de análise contextual e raciocínio jurídico
    - Function Calling: Estrutura garantida para fatores de complexidade
    - 4 Níveis Fallback: Máxima disponibilidade
    - Mesma interface: Drop-in replacement
    """
    
    def __init__(self):
        self.openrouter_client = None
        
        # Preservar system prompt original com adaptações para Function Calling
        self.analysis_system_prompt = """
# PERSONA
Você é um especialista em análise contextual de casos jurídicos, com foco em identificar fatores de complexidade, nuances processuais e características específicas que influenciam a estratégia legal e o relacionamento advogado-cliente.

# ESPECIALIZAÇÃO
- Identificação de fatores de complexidade não óbvios
- Análise de urgência e tempo de resolução esperado
- Avaliação de sensibilidade e confidencialidade do caso
- Identificação do perfil psicológico e necessidades do cliente
- Análise de riscos e probabilidade de sucesso
- Recomendações estratégicas personalizadas

# CONTEXTO DE USO
Você recebe dados estruturados sobre um caso jurídico e deve extrair insights contextuais profundos que orientem a seleção do advogado mais adequado e a estratégia a ser adotada.

# METODOLOGIA DE ANÁLISE
## ANÁLISE CONTEXTUAL PROFUNDA
- Identificação de complexidades técnicas, procedimentais e humanas
- Avaliação realística de prazos e expectativas
- Análise do perfil emocional e comunicacional do cliente
- Identificação de fatores de risco e oportunidades
- Recomendações de abordagem estratégica personalizada

# INSTRUÇÃO CRÍTICA
Use SEMPRE a função 'analyze_case_context' para retornar sua análise de forma estruturada e precisa. Baseie-se nos dados fornecidos, mas use sua capacidade de inferência para insights contextuais profundos.
"""
    
    async def _init_client(self):
        """Inicializa cliente OpenRouter se necessário."""
        if not self.openrouter_client:
            self.openrouter_client = await get_openrouter_client()
    
    async def analyze_case_context(self, case_data: Dict[str, Any]) -> CaseContextInsightsV2:
        """
        Analisa contexto de caso usando Claude Sonnet 4 + Function Calling.
        
        Interface idêntica à versão V1 para compatibilidade total.
        
        Args:
            case_data: Dados do caso (descrição, tipo, urgência, etc.)
            
        Returns:
            CaseContextInsightsV2: Insights contextuais (compatível com V1)
        """
        start_time = time.time()
        
        try:
            await self._init_client()
            
            # Preparar contexto da análise
            context = self._prepare_analysis_context(case_data)
            
            # Executar análise contextual com Claude Sonnet 4 + Function Calling
            messages = [
                {"role": "system", "content": self.analysis_system_prompt},
                {"role": "user", "content": context}
            ]
            
            response = await self.openrouter_client.call_with_function_tool(
                service_name="case_context",
                primary_model="anthropic/claude-sonnet-4",  # Claude Sonnet 4 como primário
                messages=messages,
                temperature=0.3,  # Baixa para análise precisa e consistente
                max_tokens=2048
            )
            
            processing_time = int((time.time() - start_time) * 1000)
            
            if response["success"]:
                # Function calling bem-sucedido
                analysis_data = response["result"]
                
                return CaseContextInsightsV2(
                    complexity_factors=analysis_data.get("complexity_factors", []),
                    urgency_reasoning=analysis_data.get("urgency_reasoning", "Análise não disponível"),
                    required_expertise=analysis_data.get("required_expertise", []),
                    case_sensitivity=analysis_data.get("case_sensitivity", "medium"),
                    expected_duration=analysis_data.get("expected_duration", "unclear"),
                    communication_needs=analysis_data.get("communication_needs", "standard"),
                    client_personality_type=analysis_data.get("client_personality_type", "results_focused"),
                    success_probability=analysis_data.get("success_probability", 0.5),
                    key_challenges=analysis_data.get("key_challenges", []),
                    recommended_approach=analysis_data.get("recommended_approach", "Abordagem padrão"),
                    confidence_score=analysis_data.get("confidence_score", 0.5),
                    processing_time_ms=processing_time,
                    model_used=response.get("model_used"),
                    fallback_level=response.get("fallback_level"),
                    processing_metadata={
                        "version": "v2_claude_sonnet4_function_calling",
                        "fallback_used": response.get("fallback_level", 1) > 1,
                        "response_raw": response
                    }
                )
            else:
                # Function calling falhou - usar fallback tradicional
                logger.warning(f"Function calling falhou: {response.get('error')}")
                return await self._fallback_to_traditional_analysis(
                    case_data, processing_time, response
                )
                
        except Exception as e:
            logger.error(f"Erro na análise de contexto V2: {str(e)}")
            
            # Fallback final para análise básica
            processing_time = int((time.time() - start_time) * 1000)
            return await self._emergency_fallback_analysis(
                case_data, processing_time, str(e)
            )
    
    def _prepare_analysis_context(self, case_data: Dict[str, Any]) -> str:
        """
        Prepara contexto da análise de caso.
        Método adaptado da versão V1 para compatibilidade.
        """
        case_id = case_data.get("case_id", "N/A")
        client_id = case_data.get("client_id", "N/A")
        
        # Dados básicos do caso
        basic_info = case_data.get("basic_info", {})
        case_type = basic_info.get("case_type", "Não especificado")
        legal_area = basic_info.get("legal_area", "Não especificada")
        estimated_value = basic_info.get("estimated_value", "Não informado")
        
        # Descrição detalhada
        description = case_data.get("description", "Descrição não fornecida")
        
        # Documentos e evidências
        documents = case_data.get("documents", [])
        documents_text = "\n".join([
            f"- {doc.get('type', 'Documento')}: {doc.get('description', 'Sem descrição')} ({doc.get('status', 'Status N/A')})"
            for doc in documents
        ]) if documents else "Documentos não informados"
        
        # Timeline e prazos
        timeline = case_data.get("timeline", {})
        incident_date = timeline.get("incident_date", "Não informado")
        deadline = timeline.get("deadline", "Não informado")
        urgency_level = timeline.get("urgency_level", "Não especificado")
        
        # Partes envolvidas
        parties = case_data.get("parties", [])
        parties_text = "\n".join([
            f"- {party.get('role', 'Parte')}: {party.get('name', 'Nome N/A')} ({party.get('type', 'Tipo N/A')})"
            for party in parties
        ]) if parties else "Partes não informadas"
        
        # Valor da causa e interesses
        financial_info = case_data.get("financial_info", {})
        cause_value = financial_info.get("cause_value", "Não informado")
        potential_damages = financial_info.get("potential_damages", "Não informado")
        
        # Complexidade inicial detectada
        complexity_indicators = case_data.get("complexity_indicators", [])
        complexity_text = ", ".join(complexity_indicators) if complexity_indicators else "Não identificados"
        
        # Contexto emocional e humano
        client_info = case_data.get("client_info", {})
        client_expectations = client_info.get("expectations", "Não informadas")
        client_concerns = client_info.get("concerns", "Não informadas")
        communication_preference = client_info.get("communication_preference", "Não especificada")
        
        # Histórico de tentativas anteriores
        previous_attempts = case_data.get("previous_attempts", [])
        attempts_text = "\n".join([
            f"- {attempt.get('type', 'Tentativa')}: {attempt.get('result', 'Resultado N/A')} ({attempt.get('date', 'Data N/A')})"
            for attempt in previous_attempts
        ]) if previous_attempts else "Nenhuma tentativa anterior"
        
        context = f"""
=== DADOS BÁSICOS DO CASO ===
ID do Caso: {case_id}
ID do Cliente: {client_id}
Tipo de Caso: {case_type}
Área Jurídica: {legal_area}
Valor Estimado: {estimated_value}

=== DESCRIÇÃO DETALHADA ===
{description}

=== TIMELINE E PRAZOS ===
Data do Incidente: {incident_date}
Prazo Limite: {deadline}
Nível de Urgência: {urgency_level}

=== PARTES ENVOLVIDAS ===
{parties_text}

=== DOCUMENTOS E EVIDÊNCIAS ===
{documents_text}

=== INFORMAÇÕES FINANCEIRAS ===
Valor da Causa: {cause_value}
Danos Potenciais: {potential_damages}

=== INDICADORES DE COMPLEXIDADE ===
{complexity_text}

=== PERFIL E EXPECTATIVAS DO CLIENTE ===
Expectativas: {client_expectations}
Preocupações: {client_concerns}
Preferência de Comunicação: {communication_preference}

=== TENTATIVAS ANTERIORES ===
{attempts_text}

=== SOLICITAÇÃO ===
Com base nos dados acima, realize uma análise contextual profunda deste caso jurídico. Identifique insights não óbvios sobre:

1. Fatores de complexidade específicos (técnicos, procedimentais, humanos)
2. Justificativa detalhada para o nível de urgência
3. Tipos específicos de expertise jurídica necessários
4. Nível de sensibilidade e confidencialidade requeridos
5. Duração esperada do processo e suas etapas
6. Necessidades de comunicação do cliente
7. Perfil psicológico do cliente e abordagem recomendada
8. Probabilidade realística de sucesso
9. Principais desafios e obstáculos esperados
10. Abordagem estratégica recomendada

Use a função 'analyze_case_context' para retornar sua análise estruturada.
"""
        
        return context
    
    async def _fallback_to_traditional_analysis(
        self, 
        case_data: Dict[str, Any], 
        processing_time: int,
        failed_response: Dict[str, Any]
    ) -> CaseContextInsightsV2:
        """
        Fallback para análise tradicional quando Function Calling falha.
        """
        logger.info("Usando fallback tradicional para análise de contexto")
        
        # Análise básica baseada em heurísticas simples
        case_type = case_data.get("basic_info", {}).get("case_type", "")
        urgency_level = case_data.get("timeline", {}).get("urgency_level", "")
        complexity_indicators = case_data.get("complexity_indicators", [])
        estimated_value = case_data.get("basic_info", {}).get("estimated_value", "")
        
        # Inferir fatores de complexidade
        complexity_factors = []
        if "múltiplas partes" in str(case_data).lower():
            complexity_factors.append("Múltiplas partes envolvidas")
        if "prazo" in urgency_level.lower():
            complexity_factors.append("Pressão temporal")
        if complexity_indicators:
            complexity_factors.extend(complexity_indicators[:3])
        
        # Inferir necessidades de comunicação
        communication_needs = "standard"
        if urgency_level.lower() in ["crítica", "alta"]:
            communication_needs = "frequent_updates"
        elif "baixa" in urgency_level.lower():
            communication_needs = "minimal"
        
        # Inferir duração esperada
        expected_duration = "medium_term"
        if "trabalhista" in case_type.lower():
            expected_duration = "short_term"
        elif "civil" in case_type.lower() and "complexo" in str(complexity_indicators).lower():
            expected_duration = "long_term"
        
        # Probabilidade de sucesso baseada em dados básicos
        success_probability = 0.6  # Padrão otimista
        if len(complexity_factors) > 3:
            success_probability = 0.4  # Reduzir se muito complexo
        elif urgency_level.lower() in ["crítica", "alta"]:
            success_probability = 0.5  # Reduzir se muito urgente
        
        return CaseContextInsightsV2(
            complexity_factors=complexity_factors or ["Análise básica indisponível"],
            urgency_reasoning="Análise automática baseada em indicadores básicos",
            required_expertise=[case_type] if case_type else ["Expertise geral"],
            case_sensitivity="medium",
            expected_duration=expected_duration,
            communication_needs=communication_needs,
            client_personality_type="results_focused",  # Padrão
            success_probability=success_probability,
            key_challenges=["Análise detalhada indisponível"],
            recommended_approach="Abordagem padrão baseada no tipo de caso",
            confidence_score=0.3,  # Baixa confiança no fallback
            processing_time_ms=processing_time,
            model_used=failed_response.get("model_used", "fallback_heuristic"),
            fallback_level=failed_response.get("fallback_level", 999),
            processing_metadata={
                "version": "v2_fallback_heuristic",
                "error": failed_response.get("error"),
                "heuristic_analysis": True
            }
        )
    
    async def _emergency_fallback_analysis(
        self,
        case_data: Dict[str, Any],
        processing_time: int,
        error_msg: str
    ) -> CaseContextInsightsV2:
        """
        Fallback de emergência quando tudo falha.
        """
        logger.error(f"Usando fallback de emergência para análise de contexto: {error_msg}")
        
        return CaseContextInsightsV2(
            complexity_factors=["Sistema de análise indisponível"],
            urgency_reasoning="Análise não realizada devido a erro técnico",
            required_expertise=["Expertise geral"],
            case_sensitivity="medium",
            expected_duration="unclear",
            communication_needs="standard",
            client_personality_type="results_focused",
            success_probability=0.5,
            key_challenges=["Análise técnica indisponível"],
            recommended_approach="Consultar análise manual",
            confidence_score=0.0,
            processing_time_ms=processing_time,
            model_used="emergency_fallback",
            fallback_level=999,
            processing_metadata={
                "version": "v2_emergency_fallback",
                "error": error_msg,
                "timestamp": time.time()
            }
        )


# Factory function para compatibilidade
async def get_case_context_service_v2() -> CaseContextAnalysisServiceV2:
    """Factory function para obter instância do serviço V2."""
    return CaseContextAnalysisServiceV2()


# Instância global para uso direto
case_context_service_v2 = CaseContextAnalysisServiceV2() 
 