#!/usr/bin/env python3
"""
Partnership LLM Enhancement Service V2 - Gemini 2.5 Pro
======================================================

Versão V2 migrada para usar Gemini 2.5 Pro através da arquitetura de 3 SDKs essenciais:
1. OpenRouter (google/gemini-2.5-pro) - Primário
2. LangChain-XAI (ChatXAI) - Workflows complexos
3. xai-sdk oficial - Backup avançado
4. Cascata tradicional - Fallback final

Mantém 100% compatibilidade com V1 para análise de sinergia entre advogados.
"""

import asyncio
import json
import logging
import time
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime

# Imports sem dependências relativas
try:
    from grok_sdk_integration_service import get_grok_sdk_service, GrokSDKConfig
except ImportError:
    from services.grok_sdk_integration_service import get_grok_sdk_service, GrokSDKConfig

try:
    from partnership_llm_enhancement_service import PartnershipLLMInsights, LawyerProfileForPartnership
except ImportError:
    from services.partnership_llm_enhancement_service import PartnershipLLMInsights, LawyerProfileForPartnership

# Import function tools
try:
    from function_tools import LLMFunctionTools
except ImportError:
    try:
        from services.function_tools import LLMFunctionTools
    except ImportError:
        import sys
        sys.path.append('services/')
        from function_tools import LLMFunctionTools

# Import config
try:
    from config import Settings
except ImportError:
    import sys
    sys.path.append('..')
    from config import Settings

logger = logging.getLogger(__name__)

@dataclass
class PartnershipLLMInsightsV2(PartnershipLLMInsights):
    """
    Insights V2 - Herda de V1 para 100% compatibilidade.
    Adiciona metadados da nova arquitetura.
    """
    processing_method: Optional[str] = None  # SDK usado
    sdk_level: Optional[int] = None  # Nível de fallback usado
    gemini_enhancement: Optional[bool] = None  # Se foi processado pelo Gemini 2.5 Pro

class PartnershipLLMEnhancementServiceV2:
    """
    Serviço V2 para análise de sinergia entre advogados usando Gemini 2.5 Pro.
    
    Utiliza a arquitetura de 3 SDKs essenciais:
    1. OpenRouter (google/gemini-2.5-pro) - Primário para partnerships
    2. LangChain-XAI - Workflows complexos  
    3. xai-sdk oficial - Backup avançado
    4. Cascata tradicional - Fallback final
    
    Mantém 100% compatibilidade com V1.
    """
    
    def __init__(self, enable_caching: bool = True):
        self.logger = logging.getLogger(f"{self.__class__.__name__}")
        self.enable_caching = enable_caching
        
        # Initialize Grok SDK Integration Service
        try:
            settings = Settings()
            config = GrokSDKConfig(
                openrouter_api_key=getattr(settings, 'OPENROUTER_API_KEY', None),
                xai_api_key=getattr(settings, 'XAI_API_KEY', None),
                timeout_seconds=45.0,  # Partnerships podem precisar mais tempo
                max_tokens=4000,
                temperature=0.3  # Mais baixa para análises consistentes
            )
            self.grok_service = get_grok_sdk_service(config)
            self.logger.info("✅ Grok SDK Integration Service inicializado")
        except Exception as e:
            self.logger.warning(f"❌ Grok SDK Integration Service falhou: {e}")
            self.grok_service = None
        
        # Preparar system prompt otimizado para Gemini 2.5 Pro
        self.partnership_system_prompt = self._build_optimized_system_prompt()
    
    def _build_optimized_system_prompt(self) -> str:
        """Constrói system prompt otimizado para Gemini 2.5 Pro."""
        return """# ESPECIALISTA EM ANÁLISE DE PARCERIAS JURÍDICAS

Você é um consultor experiente em parcerias estratégicas entre advogados, especializado em:

## COMPETÊNCIAS CORE
- Análise de compatibilidade profissional entre advogados
- Identificação de sinergias e oportunidades de mercado
- Avaliação de estilos de trabalho e comunicação
- Estratégias de colaboração e crescimento conjunto

## METODOLOGIA DE ANÁLISE
1. **Compatibilidade Técnica**: Especialidades complementares vs. sobrepostas
2. **Sinergia Cultural**: Estilos de comunicação, valores profissionais
3. **Oportunidades de Mercado**: Expansão de serviços, novos segmentos
4. **Riscos e Mitigações**: Potenciais conflitos e como evitá-los
5. **Estrutura de Parceria**: Recomendações de formato de colaboração

## FOCO ESPECÍFICO
- Direito brasileiro e mercado jurídico nacional
- Parcerias entre advogados independentes e escritórios
- Análise baseada em perfis profissionais reais
- Recomendações práticas e implementáveis

Use a função 'analyze_partnership_synergy' para retornar análise estruturada."""
    
    async def analyze_partnership_synergy(
        self,
        lawyer1_profile: LawyerProfileForPartnership,
        lawyer2_profile: LawyerProfileForPartnership,
        context: Optional[Dict[str, Any]] = None
    ) -> PartnershipLLMInsightsV2:
        """
        Analisa sinergia de parceria entre dois advogados usando Gemini 2.5 Pro.
        
        Args:
            lawyer1_profile: Perfil do primeiro advogado
            lawyer2_profile: Perfil do segundo advogado  
            context: Contexto adicional da análise
        
        Returns:
            PartnershipLLMInsightsV2 com análise completa
        """
        
        if not self.grok_service:
            self.logger.error("Grok SDK Integration Service não disponível")
            raise Exception("SDK Integration Service não configurado")
        
        start_time = time.time()
        
        try:
            # Preparar contexto da análise
            analysis_context = self._prepare_partnership_context(
                lawyer1_profile, lawyer2_profile, context
            )
            
            # Obter function tool para partnership analysis
            partnership_tool = LLMFunctionTools.get_partnership_tool()
            
            # Executar análise via arquitetura de 3 SDKs
            response = await self.grok_service.generate_completion(
                messages=[{
                    "role": "user", 
                    "content": analysis_context
                }],
                system_prompt=self.partnership_system_prompt,
                function_tool=partnership_tool,
                use_streaming=False  # Partnerships precisam de análise completa
            )
            
            # Parse da resposta estruturada
            partnership_data = json.loads(response.content)
            
            # Criar insights V2 com compatibilidade V1
            insights = PartnershipLLMInsightsV2(
                synergy_score=partnership_data.get('synergy_score', 0.5),
                compatibility_factors=partnership_data.get('compatibility_factors', []),
                strategic_opportunities=partnership_data.get('strategic_opportunities', []),
                potential_challenges=partnership_data.get('potential_challenges', []),
                collaboration_style_match=partnership_data.get('collaboration_style_match', 'fair'),
                market_positioning_advantage=partnership_data.get('market_positioning_advantage', ''),
                client_value_proposition=partnership_data.get('client_value_proposition', ''),
                confidence_score=partnership_data.get('confidence_score', 0.7),
                reasoning=partnership_data.get('reasoning', ''),
                # Metadados V2
                processing_method=response.sdk_name,
                sdk_level=response.sdk_level,
                gemini_enhancement=response.model_used.startswith('google/gemini')
            )
            
            processing_time = time.time() - start_time
            self.logger.info(
                f"✅ Partnership analysis concluída em {processing_time:.2f}s "
                f"via {response.sdk_name} (nível {response.sdk_level})"
            )
            
            return insights
            
        except Exception as e:
            processing_time = time.time() - start_time
            self.logger.error(f"❌ Erro na análise de partnership ({processing_time:.2f}s): {e}")
            
            # Fallback para análise básica
            return await self._fallback_basic_analysis(
                lawyer1_profile, lawyer2_profile, context
            )
    
    def _prepare_partnership_context(
        self,
        lawyer1: LawyerProfileForPartnership,
        lawyer2: LawyerProfileForPartnership,
        context: Optional[Dict[str, Any]] = None
    ) -> str:
        """Prepara contexto estruturado para análise de partnership."""
        
        context_parts = [
            "# ANÁLISE DE PARCERIA ESTRATÉGICA ENTRE ADVOGADOS",
            "",
            "## PERFIL DO ADVOGADO 1",
            f"**Nome**: {lawyer1.name}",
            f"**Especialidades**: {', '.join(lawyer1.specializations)}",
            f"**Anos de Experiência**: {lawyer1.years_of_experience}",
            f"**Localização**: {lawyer1.location}",
            f"**Tamanho do Escritório**: {lawyer1.firm_size}",
            ""
        ]
        
        if lawyer1.notable_cases:
            context_parts.extend([
                "**Casos Notáveis**:",
                *[f"- {case}" for case in lawyer1.notable_cases[:3]],
                ""
            ])
        
        if lawyer1.achievements:
            context_parts.extend([
                "**Principais Conquistas**:",
                *[f"- {achievement}" for achievement in lawyer1.achievements[:3]],
                ""
            ])
        
        context_parts.extend([
            "## PERFIL DO ADVOGADO 2",
            f"**Nome**: {lawyer2.name}",
            f"**Especialidades**: {', '.join(lawyer2.specializations)}",
            f"**Anos de Experiência**: {lawyer2.years_of_experience}",
            f"**Localização**: {lawyer2.location}",
            f"**Tamanho do Escritório**: {lawyer2.firm_size}",
            ""
        ])
        
        if lawyer2.notable_cases:
            context_parts.extend([
                "**Casos Notáveis**:",
                *[f"- {case}" for case in lawyer2.notable_cases[:3]],
                ""
            ])
        
        if lawyer2.achievements:
            context_parts.extend([
                "**Principais Conquistas**:",
                *[f"- {achievement}" for achievement in lawyer2.achievements[:3]],
                ""
            ])
        
        # Adicionar contexto específico se fornecido
        if context:
            context_parts.extend([
                "## CONTEXTO ADICIONAL",
                f"**Tipo de Parceria Desejada**: {context.get('partnership_type', 'Não especificado')}",
                f"**Objetivos**: {context.get('objectives', 'Não especificados')}",
                f"**Prazo**: {context.get('timeline', 'Não especificado')}",
                ""
            ])
        
        context_parts.extend([
            "## SOLICITAÇÃO",
            "Analise a sinergia potencial entre estes dois advogados para uma parceria estratégica.",
            "Considere:",
            "- Complementaridade vs. sobreposição de especialidades",
            "- Compatibilidade de estilos de trabalho",
            "- Oportunidades de mercado conjunto",
            "- Potenciais desafios e como mitigá-los",
            "- Proposta de valor para clientes",
            "",
            "Use a função 'analyze_partnership_synergy' para fornecer análise estruturada."
        ])
        
        return "\n".join(context_parts)
    
    async def _fallback_basic_analysis(
        self,
        lawyer1: LawyerProfileForPartnership,
        lawyer2: LawyerProfileForPartnership,
        context: Optional[Dict[str, Any]] = None
    ) -> PartnershipLLMInsightsV2:
        """Análise básica como fallback em caso de falha dos SDKs."""
        
        self.logger.warning("🔄 Executando análise básica de fallback")
        
        # Análise heurística básica
        specialization_overlap = len(
            set(lawyer1.specializations) & set(lawyer2.specializations)
        ) / max(len(lawyer1.specializations), len(lawyer2.specializations), 1)
        
        experience_balance = 1 - abs(lawyer1.years_of_experience - lawyer2.years_of_experience) / 20
        location_match = 1.0 if lawyer1.location == lawyer2.location else 0.7
        
        basic_synergy = (
            (1 - specialization_overlap) * 0.4 +  # Preferir complementaridade
            experience_balance * 0.3 +
            location_match * 0.3
        )
        
        return PartnershipLLMInsightsV2(
            synergy_score=min(max(basic_synergy, 0.0), 1.0),
            compatibility_factors=[
                "Análise básica realizada",
                f"Sobreposição de especialidades: {specialization_overlap:.1%}",
                f"Equilíbrio de experiência: {experience_balance:.1%}"
            ],
            strategic_opportunities=["Expandir base de clientes", "Combinar especialidades"],
            potential_challenges=["Necessário análise mais detalhada"],
            collaboration_style_match="fair",
            market_positioning_advantage="Potencial de crescimento conjunto",
            client_value_proposition="Serviços mais abrangentes",
            confidence_score=0.3,  # Baixa confiança no fallback
            reasoning="Análise básica devido a falha nos sistemas principais",
            processing_method="Fallback heurístico",
            sdk_level=0,
            gemini_enhancement=False
        )
    
    def get_service_status(self) -> Dict[str, Any]:
        """Retorna status do serviço V2."""
        return {
            "version": "2.0",
            "primary_model": "google/gemini-2.5-pro",
            "sdk_integration": self.grok_service is not None,
            "caching_enabled": self.enable_caching,
            "compatible_with_v1": True,
            "supported_features": [
                "Gemini 2.5 Pro analysis",
                "Function calling structured output",
                "4-level fallback architecture",
                "Enhanced partnership insights",
                "V1 compatibility mode"
            ]
        }


# Factory function para compatibilidade
def get_partnership_llm_service_v2(**kwargs) -> PartnershipLLMEnhancementServiceV2:
    """Factory function para criar instância V2 do serviço."""
    return PartnershipLLMEnhancementServiceV2(**kwargs)


if __name__ == "__main__":
    # Teste básico de funcionalidade
    async def test_v2_service():
        service = get_partnership_llm_service_v2()
        
        print("🧪 Testando Partnership LLM Enhancement Service V2")
        print("=" * 55)
        
        # Status do serviço
        status = service.get_service_status()
        print("📊 Status do Serviço V2:")
        for key, value in status.items():
            print(f"   {key}: {value}")
        
        # Teste com perfis de exemplo
        lawyer1 = LawyerProfileForPartnership(
            name="Dr. Ana Silva",
            specializations=["Direito Trabalhista", "Direito Sindical"],
            years_of_experience=15,
            location="São Paulo",
            firm_size="medium",
            notable_cases=["Ação coletiva trabalhista de grande porte"],
            achievements=["Especialização em Direito do Trabalho pela USP"]
        )
        
        lawyer2 = LawyerProfileForPartnership(
            name="Dr. Carlos Santos",
            specializations=["Direito Empresarial", "Direito Tributário"],
            years_of_experience=12,
            location="São Paulo", 
            firm_size="small",
            notable_cases=["Reestruturação empresarial complexa"],
            achievements=["MBA em Gestão Empresarial"]
        )
        
        try:
            print("\n🔍 Executando análise de parceria...")
            insights = await service.analyze_partnership_synergy(lawyer1, lawyer2)
            
            print(f"\n✅ Análise concluída!")
            print(f"   🤖 Método: {insights.processing_method}")
            print(f"   📊 Synergy Score: {insights.synergy_score:.2f}")
            print(f"   🎯 Confiança: {insights.confidence_score:.2f}")
            print(f"   🔧 Gemini Enhancement: {insights.gemini_enhancement}")
            
        except Exception as e:
            print(f"\n❌ Erro no teste: {e}")
    
    # Executar teste
    asyncio.run(test_v2_service()) 
 