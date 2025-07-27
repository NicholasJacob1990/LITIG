"""
LEX-9000 Integration Service V2 - OpenRouter + Function Calling
==============================================================

🆕 V2.1: Web Search para Jurisprudência Atualizada
- Busca jurisprudência recente (STF, STJ, TST)
- Informações atualizadas sobre alterações legislativas
- Posicionamentos doutrinários atuais
- Precedentes de casos similares

Nova versão do LEX-9000 usando:
- Grok 4 via OpenRouter (primário)
- Function Calling para estruturação confiável
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
    from lex9000_integration_service import LEXAnalysisResult
except ImportError:
    from services.lex9000_integration_service import LEXAnalysisResult

try:
    from function_tools import LLMFunctionTools
except ImportError:
    try:
        from services.function_tools import LLMFunctionTools
    except ImportError:
        # Fallback for validation script
        import sys
        sys.path.append('services/')
        from function_tools import LLMFunctionTools

logger = logging.getLogger(__name__)


@dataclass
class LEXAnalysisResultV2(LEXAnalysisResult):
    """
    Resultado da análise LEX-9000 V2.
    Herda de LEXAnalysisResult para manter 100% de compatibilidade.
    """
    model_used: Optional[str] = None
    fallback_level: Optional[int] = None
    processing_metadata: Optional[Dict[str, Any]] = None


class LEX9000IntegrationServiceV2:
    """
    LEX-9000 V2: Análise jurídica com Grok 4 + Function Calling.
    
    🆕 V2.1: Web Search para Jurisprudência Atualizada
    - Consulta informações atualizadas em tempo real
    - Jurisprudência dos últimos 2 anos prioritariamente
    - Fontes confiáveis: STF, STJ, TST, JusBrasil, ConJur
    
    Benefícios sobre V1:
    - Grok 4: Melhor raciocínio jurídico que GPT-4o
    - Function Calling: Estruturação confiável das respostas
    - Fallback robusto: 4 níveis de resiliência
    - Web Search: Informações jurídicas atualizadas
    """
    
    def __init__(self):
        self.openrouter_client = get_openrouter_client()
        self.function_tools = LLMFunctionTools()
        
        # Configuração de sources confiáveis para web search jurídico
        self.legal_web_sources = [
            "stf.jus.br",
            "stj.jus.br", 
            "tst.jus.br",
            "jusbrasil.com.br",
            "conjur.com.br",
            "planalto.gov.br"
        ]
        
        # Ferramentas de função para análise estruturada
        self.analysis_tool = {
            "type": "function",
            "function": {
                "name": "analyze_legal_case",
                "description": "Analisa um caso jurídico e fornece análise estruturada com jurisprudência atualizada",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "viability_score": {
                            "type": "number",
                            "minimum": 0,
                            "maximum": 1,
                            "description": "Score de viabilidade jurídica (0-1)"
                        },
                        "main_legal_issues": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "Principais questões jurídicas identificadas"
                        },
                        "applicable_laws": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "Leis e normas aplicáveis"
                        },
                        "recent_jurisprudence": {
                            "type": "array",
                            "items": {
                                "type": "object",
                                "properties": {
                                    "court": {"type": "string", "description": "Tribunal"},
                                    "decision": {"type": "string", "description": "Decisão"},
                                    "relevance": {"type": "string", "description": "Relevância para o caso"},
                                    "date": {"type": "string", "description": "Data da decisão"},
                                    "source_url": {"type": "string", "description": "URL da fonte"}
                                }
                            },
                            "description": "Jurisprudência recente encontrada via web search"
                        },
                        "recommended_strategy": {
                            "type": "string",
                            "description": "Estratégia jurídica recomendada"
                        },
                        "expected_timeline": {
                            "type": "string",
                            "description": "Cronograma esperado do processo"
                        },
                        "success_probability": {
                            "type": "number",
                            "minimum": 0,
                            "maximum": 1,
                            "description": "Probabilidade de sucesso baseada em precedentes"
                        },
                        "cost_estimate": {
                            "type": "object",
                            "properties": {
                                "min_range": {"type": "number"},
                                "max_range": {"type": "number"},
                                "currency": {"type": "string", "default": "BRL"}
                            },
                            "description": "Estimativa de custos"
                        },
                        "web_search_summary": {
                            "type": "string",
                            "description": "Resumo das informações atualizadas encontradas via web search"
                        },
                        "information_freshness": {
                            "type": "string",
                            "description": "Data das informações mais recentes consultadas"
                        }
                    },
                    "required": [
                        "viability_score", 
                        "main_legal_issues", 
                        "applicable_laws", 
                        "recommended_strategy",
                        "success_probability"
                    ]
                }
            }
        }
    
    async def analyze_complex_case(
        self, 
        conversation_data: str, 
        enable_web_search: bool = True,
        web_search_focus: str = "jurisprudencia"
    ) -> LEXAnalysisResultV2:
        """
        🆕 V2.1: Análise jurídica com Web Search para informações atualizadas.
        
        Args:
            conversation_data: Dados da conversa/caso
            enable_web_search: Habilita busca por jurisprudência atualizada
            web_search_focus: Foco da busca ("jurisprudencia", "doutrina", "legislacao")
        
        Returns:
            LEXAnalysisResultV2 com informações atualizadas
        """
        start_time = time.time()
        
        try:
            # Preparar contexto otimizado para web search
            if enable_web_search:
                context = self._prepare_web_search_context(conversation_data, web_search_focus)
                system_prompt = self.lex_system_prompt_with_search
                model = "openai/gpt-4o-search-preview"  # Modelo otimizado para web search
            else:
                context = self._prepare_lex_context(conversation_data)
                system_prompt = self.lex_system_prompt
                model = Settings.OPENROUTER_LEX9000_MODEL
            
            # Executar análise com web search se habilitado
            response = await self.openrouter_client.chat_completion_with_web_search(
                model=model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": context}
                ],
                tools=[self.analysis_tool],
                tool_choice={"type": "function", "function": {"name": "analyze_legal_case"}},
                enable_web_search=enable_web_search,
                web_search_sources=self.legal_web_sources if enable_web_search else None,
                search_focus=web_search_focus if enable_web_search else None,
                temperature=0.1,
                max_tokens=2000
            )
            
            # Processar resultado
            analysis_result = self._parse_lex_response_v2(response)
            
            # Adicionar metadados V2.1
            analysis_result.model_used = response.get("model_used")
            analysis_result.fallback_level = response.get("fallback_level")
            analysis_result.processing_metadata = {
                "web_search_enabled": enable_web_search,
                "web_search_used": response.get("web_search_used", False),
                "search_focus": web_search_focus if enable_web_search else None,
                "processing_time_ms": int((time.time() - start_time) * 1000),
                "provider": response.get("provider"),
                "sources_consulted": len(self.legal_web_sources) if enable_web_search else 0
            }
            
            logger.info(f"✅ LEX-9000 V2.1: Análise concluída em {analysis_result.processing_metadata['processing_time_ms']}ms")
            if enable_web_search:
                logger.info(f"🌐 Web Search: {response.get('web_search_used', False)} | Fontes: {len(self.legal_web_sources)}")
            
            return analysis_result
            
        except Exception as e:
            logger.error(f"❌ Erro na análise LEX-9000 V2.1: {e}")
            
            # Fallback para análise sem web search
            if enable_web_search:
                logger.warning("🔄 Fallback: Tentando análise sem web search")
                return await self.analyze_complex_case(
                    conversation_data=conversation_data,
                    enable_web_search=False
                )
            
            raise e
    
    def _prepare_web_search_context(self, conversation_data: str, search_focus: str = "jurisprudencia") -> str:
        """
        Prepara contexto otimizado para web search jurídico.
        
        Args:
            conversation_data: Dados do caso
            search_focus: Foco da busca web
        
        Returns:
            Contexto estruturado para web search
        """
        return f"""
        🔍 BUSCA WEB JURÍDICA OBRIGATÓRIA

        Antes de analisar este caso jurídico, busque na web informações ATUALIZADAS sobre:

        **Prioridade 1 - Jurisprudência Recente:**
        • Decisões dos tribunais superiores (STF, STJ, TST) dos últimos 24 meses
        • Precedentes de casos similares com desfecho conhecido
        • Súmulas e entendimentos consolidados atuais

        **Prioridade 2 - Legislação Atualizada:**
        • Alterações legislativas recentes na área específica
        • Regulamentações e normativas em vigor
        • MPs e decretos relevantes

        **Prioridade 3 - Posicionamento Doutrinário:**
        • Artigos e análises doutrinárias atuais
        • Posições de juristas reconhecidos
        • Tendências jurisprudenciais emergentes

        **CONTEXTO DO CASO:**
        {conversation_data}

        **INSTRUÇÕES DE BUSCA:**
        • Use APENAS fontes confiáveis: STF, STJ, TST, JusBrasil, ConJur, Planalto
        • Priorize informações dos últimos 2 anos
        • Cite SEMPRE a fonte e data das informações
        • Indique o grau de relevância de cada precedente
        • Use a função 'analyze_legal_case' para estruturar a resposta

        **FOCO ESPECIAL:** {search_focus}
        """
    
    @property
    def lex_system_prompt_with_search(self) -> str:
        """
        System prompt otimizado para análise com web search.
        """
        return """
        # PERSONA: LEX-9000 V2.1 - Assistente Jurídico com Web Search
        
        Você é o "LEX-9000", um assistente jurídico especializado em Direito Brasileiro, 
        evoluído para trabalhar com informações jurídicas ATUALIZADAS via web search.
        
        ## METODOLOGIA APRIMORADA V2.1
        
        1. **BUSCA WEB OBRIGATÓRIA**: SEMPRE consulte fontes atualizadas na web antes da análise
        2. **JURISPRUDÊNCIA PRIORITÁRIA**: Priorize decisões dos últimos 2 anos dos tribunais superiores
        3. **CITAÇÃO DE FONTES**: Cite SEMPRE as fontes utilizadas com data e relevância
        4. **PRECEDENTES ATUAIS**: Use apenas jurisprudência e doutrina atualizadas
        5. **ESTRUTURAÇÃO**: Use a função 'analyze_legal_case' para organizar a resposta
        6. **TRANSPARÊNCIA**: Indique claramente a data das informações consultadas
        
        ## FONTES PREFERENCIAIS (em ordem de prioridade)
        
        **Jurisprudência (Prioridade Máxima):**
        • STF - Supremo Tribunal Federal
        • STJ - Superior Tribunal de Justiça  
        • TST - Tribunal Superior do Trabalho
        
        **Análise e Doutrina:**
        • JusBrasil - Decisões e artigos especializados
        • ConJur - Análises doutrinárias atuais
        
        **Legislação:**
        • Planalto.gov.br - Legislação oficial atualizada
        
        ## QUALIDADE DA ANÁLISE
        
        • **Precisão**: Base suas conclusões em precedentes recentes e consolidados
        • **Atualidade**: Priorize informações dos últimos 24 meses
        • **Relevância**: Indique o grau de aplicabilidade de cada precedente
        • **Transparência**: Mostre quando e onde encontrou cada informação
        • **Probabilidade**: Calcule success_probability baseada em dados reais recentes
        
        ## ESTRUTURA DA RESPOSTA
        
        Use OBRIGATORIAMENTE a função 'analyze_legal_case' com:
        • viability_score baseado em precedentes atuais
        • recent_jurisprudence com decisões encontradas via web search
        • web_search_summary resumindo informações atualizadas
        • information_freshness indicando a data das informações mais recentes
        """
    
    def _prepare_conversation_context(self, conversation_data: Dict[str, Any]) -> str:
        """
        Prepara contexto da conversa para análise.
        Método preservado da versão V1 para compatibilidade.
        """
        case_id = conversation_data.get("case_id", "N/A")
        user_id = conversation_data.get("user_id", "N/A")
        
        # Extrair dados da conversa
        messages = conversation_data.get("messages", [])
        final_summary = conversation_data.get("final_summary", "")
        case_type = conversation_data.get("case_type", "")
        complexity_level = conversation_data.get("complexity_level", "")
        urgency_indicators = conversation_data.get("urgency_indicators", [])
        
        context = f"""
=== DADOS DA CONVERSA DE TRIAGEM ===
ID do Caso: {case_id}
ID do Usuário: {user_id}
Tipo de Caso Detectado: {case_type}
Nível de Complexidade: {complexity_level}
Indicadores de Urgência: {urgency_indicators}

=== RESUMO FINAL DA ENTREVISTA ===
{final_summary}

=== CONVERSA COMPLETA ===
"""
        
        # Adicionar mensagens da conversa
        for i, message in enumerate(messages, 1):
            role = "ENTREVISTADOR" if message.get("role") == "assistant" else "CLIENTE"
            content = message.get("content", "")
            context += f"\n{i}. {role}: {content}"
        
        context += """

=== SOLICITAÇÃO ===
Com base na conversa de triagem acima, realize uma análise jurídica detalhada e estruturada conforme sua especialização em Direito Brasileiro. Use a função 'analyze_legal_case' para retornar a análise em formato estruturado.
"""
        
        return context
    
    def _calculate_confidence(self, analysis_data: Dict[str, Any]) -> float:
        """
        Calcula score de confiança baseado na completude dos dados.
        Método preservado da versão V1.
        """
        total_fields = 0
        filled_fields = 0
        
        # Verificar seções obrigatórias
        required_sections = ["classificacao", "analise_viabilidade", "urgencia"]
        
        for section in required_sections:
            if section in analysis_data and analysis_data[section]:
                section_data = analysis_data[section]
                if isinstance(section_data, dict):
                    for key, value in section_data.items():
                        total_fields += 1
                        if value and str(value).strip():
                            filled_fields += 1
        
        # Verificar seções opcionais
        optional_sections = ["dados_extraidos", "aspectos_tecnicos"]
        for section in optional_sections:
            if section in analysis_data and analysis_data[section]:
                section_data = analysis_data[section]
                if isinstance(section_data, dict):
                    for key, value in section_data.items():
                        total_fields += 1
                        if value and str(value).strip():
                            filled_fields += 1
        
        return min(filled_fields / max(total_fields, 1), 1.0)
    
    def _generate_recommendations(self, analysis_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Gera recomendações baseadas na análise.
        Método preservado da versão V1.
        """
        recommendations = {
            "proximos_passos": [],
            "documentos_necessarios": [],
            "prazos_importantes": [],
            "consideracoes_estrategicas": []
        }
        
        # Análise de viabilidade
        viabilidade = analysis_data.get("analise_viabilidade", {})
        classificacao_viab = viabilidade.get("classificacao", "")
        
        if classificacao_viab == "Viável":
            recommendations["proximos_passos"].append("Prosseguir com ação judicial")
            recommendations["consideracoes_estrategicas"].append("Caso com boa perspectiva de êxito")
        elif classificacao_viab == "Parcialmente Viável":
            recommendations["proximos_passos"].append("Avaliar riscos e benefícios antes de prosseguir")
            recommendations["consideracoes_estrategicas"].append("Analisar custos vs. benefícios")
        else:
            recommendations["proximos_passos"].append("Buscar alternativas extrajudiciais")
            recommendations["consideracoes_estrategicas"].append("Reavaliar estratégia jurídica")
        
        # Urgência
        urgencia = analysis_data.get("urgencia", {})
        nivel_urgencia = urgencia.get("nivel", "")
        
        if nivel_urgencia in ["Crítica", "Alta"]:
            recommendations["proximos_passos"].insert(0, "AÇÃO IMEDIATA NECESSÁRIA")
            recommendations["prazos_importantes"].append("Verificar prazos decadenciais e prescricionais")
        
        return recommendations
    
    async def _fallback_to_traditional_analysis(
        self, 
        conversation_data: Dict[str, Any], 
        processing_time: int,
        failed_response: Dict[str, Any]
    ) -> LEXAnalysisResultV2:
        """
        Fallback para análise tradicional quando Function Calling falha.
        """
        logger.info("Usando fallback tradicional para LEX-9000")
        
        # Análise básica baseada no texto da resposta (se disponível)
        text_response = failed_response.get("text_response", "")
        
        # Estrutura mínima viável
        analysis_data = {
            "classificacao": {
                "area_principal": "A definir",
                "assunto_principal": "Análise em andamento",
                "natureza": "Contencioso"
            },
            "analise_viabilidade": {
                "classificacao": "Parcialmente Viável",
                "probabilidade_exito": "Média",
                "complexidade": "Média"
            },
            "urgencia": {
                "nivel": "Média",
                "motivo": "Análise automática indisponível"
            }
        }
        
        return LEXAnalysisResultV2(
            classificacao=analysis_data["classificacao"],
            dados_extraidos={},
            analise_viabilidade=analysis_data["analise_viabilidade"],
            urgencia=analysis_data["urgencia"],
            aspectos_tecnicos={},
            recomendacoes={"proximos_passos": ["Análise manual necessária"]},
            confidence_score=0.3,  # Baixa confiança no fallback
            processing_time_ms=processing_time,
            model_used=failed_response.get("model_used", "fallback"),
            fallback_level=failed_response.get("fallback_level", 999),
            processing_metadata={
                "version": "v2_fallback_traditional",
                "error": failed_response.get("error"),
                "text_response": text_response[:500]  # Primeiros 500 chars
            }
        )
    
    async def _emergency_fallback_analysis(
        self,
        conversation_data: Dict[str, Any],
        processing_time: int,
        error_msg: str
    ) -> LEXAnalysisResultV2:
        """
        Fallback de emergência quando tudo falha.
        """
        logger.error(f"Usando fallback de emergência para LEX-9000: {error_msg}")
        
        return LEXAnalysisResultV2(
            classificacao={
                "area_principal": "Erro na Análise",
                "assunto_principal": "Sistema Indisponível",
                "natureza": "Contencioso"
            },
            dados_extraidos={},
            analise_viabilidade={
                "classificacao": "Inviável",
                "probabilidade_exito": "Baixa",
                "complexidade": "Alta"
            },
            urgencia={
                "nivel": "Baixa",
                "motivo": "Análise não realizada devido a erro técnico"
            },
            aspectos_tecnicos={},
            recomendacoes={
                "proximos_passos": [
                    "Contatar suporte técnico",
                    "Tentar análise manual",
                    "Reagendar análise automática"
                ]
            },
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
async def get_lex9000_service_v2() -> LEX9000IntegrationServiceV2:
    """Factory function para obter instância do LEX-9000 V2."""
    return LEX9000IntegrationServiceV2()


# Instância global para uso direto
lex9000_service_v2 = LEX9000IntegrationServiceV2() 
 