#!/usr/bin/env python3
"""
Cluster Labeling Service V2 - Grok 4
====================================

🆕 V2.1: Background Job Optimization com :floor routing
- Otimizado para processamento batch com custo mínimo
- Usa :floor routing para jobs não críticos em tempo
- Prioriza custo sobre velocidade para jobs assíncronos

Versão V2 migrada para usar Grok 4 através da arquitetura de 3 SDKs essenciais:
1. OpenRouter (x-ai/grok-4) - Primário para criatividade em rótulos
2. xai-sdk oficial - Streaming e performance otimizada
3. LangChain-XAI - Workflows complexos
4. Cascata tradicional - Fallback final

Mantém 100% compatibilidade com V1 para rotulagem automática de clusters.
"""

import asyncio
import json
import logging
import time
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime
import os

logger = logging.getLogger(__name__)

@dataclass
class ClusterLabelResultV2:
    """
    Resultado V2 - Estende funcionalidade V1 com metadados da nova arquitetura.
    """
    label: str
    description: str
    category: str
    keywords: List[str]
    confidence: float
    alternative_labels: List[str]
    
    # Metadados V2
    processing_method: Optional[str] = None  # SDK usado
    sdk_level: Optional[int] = None  # Nível de fallback usado
    grok_enhanced: Optional[bool] = None  # Se foi processado pelo Grok 4
    processing_time: Optional[float] = None

class ClusterLabelingServiceV2:
    """
    Serviço V2 para rotulagem automática de clusters usando Grok 4.
    
    🆕 V2.1: Background Job Optimization
    - :floor routing para custo mínimo em processamento batch
    - Timeouts estendidos para jobs não críticos
    - Rate limiting inteligente para não sobrecarregar
    
    Utiliza a arquitetura de 3 SDKs essenciais:
    1. OpenRouter (x-ai/grok-4) - Primário para criatividade
    2. xai-sdk oficial - Streaming e performance
    3. LangChain-XAI - Workflows complexos
    4. Cascata tradicional - Fallback final
    
    100% compatível com V1.
    """
    
    def __init__(self):
        # Inicializar clientes V2
        self.openrouter_client = None
        self.xai_client = None
        self.langchain_client = None
        
        # Feature flags
        self.use_openrouter = os.getenv("USE_OPENROUTER", "true").lower() == "true"
        self.use_xai_sdk = os.getenv("USE_XAI_SDK", "true").lower() == "true"
        self.use_langchain = os.getenv("USE_LANGCHAIN_XAI", "true").lower() == "true"
        
        logger.info(f"ClusterLabelingServiceV2 V2.1 iniciado - OpenRouter: {self.use_openrouter}, XAI: {self.use_xai_sdk}, LangChain: {self.use_langchain}")
        
        # System prompt otimizado para Grok 4
        self.cluster_system_prompt = self._build_grok_optimized_prompt()
        
        # Function tool para cluster labeling
        self.cluster_tool = self._build_cluster_tool()
    
    def _build_grok_optimized_prompt(self) -> str:
        """Constrói system prompt otimizado para Grok 4 e criatividade."""
        return """# ESPECIALISTA EM ROTULAGEM INTELIGENTE DE CLUSTERS

Você é um especialista em análise de dados e taxonomia, focado em criar rótulos profissionais e informativos para clusters de dados jurídicos.

## EXPERTISE PRINCIPAL
- Taxonomia e categorização de dados jurídicos
- Análise de padrões em conjuntos de dados
- Criação de rótulos concisos e profissionais
- Identificação de características distintivas

## METODOLOGIA GROK
1. **Análise Profunda**: Examine o conteúdo do cluster para identificar temas centrais
2. **Síntese Criativa**: Combine elementos-chave em rótulos memoráveis
3. **Precisão Jurídica**: Use terminologia legal apropriada quando relevante
4. **Concisão Inteligente**: Máximo 4 palavras, máximo impacto

## CATEGORIAS PRINCIPAIS
- **area_juridica**: Ramos do direito (trabalhista, civil, penal, etc.)
- **especializacao**: Nichos específicos (startups, saúde, agronegócio)
- **tipo_cliente**: Perfis de cliente (individual, empresarial, ONG)
- **complexidade**: Nível de sofisticação (básico, intermediário, avançado)
- **urgencia**: Temporalidade (rotina, prioritário, emergencial)
- **other**: Padrões únicos não cobertos acima

## ESTILO GROK
- Rótulos inteligentes e memoráveis
- Humor sutil quando apropriado (mas sempre profissional)
- Insights não óbvios que revelam padrões ocultos
- Linguagem acessível mas precisa

Use a função 'generate_cluster_label' para retornar rótulos estruturados."""
    
    def _build_cluster_tool(self) -> Dict[str, Any]:
        """Constrói function tool específico para cluster labeling."""
        return {
            "type": "function",
            "function": {
                "name": "generate_cluster_label",
                "description": "Generate professional and concise labels for content clusters",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "label": {
                            "type": "string",
                            "maxLength": 50,
                            "description": "Professional label for the cluster (max 4 words preferred)"
                        },
                        "description": {
                            "type": "string",
                            "maxLength": 200,
                            "description": "Brief description of what this cluster represents"
                        },
                        "category": {
                            "type": "string",
                            "enum": ["area_juridica", "especializacao", "tipo_cliente", "complexidade", "urgencia", "other"],
                            "description": "Category that best describes this cluster"
                        },
                        "keywords": {
                            "type": "array",
                            "items": {"type": "string"},
                            "maxItems": 5,
                            "description": "Key terms that characterize this cluster"
                        },
                        "confidence": {
                            "type": "number",
                            "minimum": 0,
                            "maximum": 1,
                            "description": "Confidence in the generated label"
                        },
                        "alternative_labels": {
                            "type": "array",
                            "items": {"type": "string"},
                            "maxItems": 3,
                            "description": "Alternative label suggestions"
                        }
                    },
                    "required": ["label", "description", "category", "confidence"]
                }
            }
        }
    
    async def generate_cluster_label(
        self, 
        cluster_content: str, 
        priority: str = "cost",
        is_background_job: bool = True
    ) -> ClusterLabelResultV2:
        """
        🆕 V2.1: Gera rótulo com prioridade de custo para processamento batch.
        
        Args:
            cluster_content: Conteúdo do cluster para análise
            priority: "speed", "cost", "quality" (padrão: "cost" para jobs background)
            is_background_job: Se é job background (usa otimizações específicas)
        
        Returns:
            ClusterLabelResultV2 com rótulo otimizado
        """
        start_time = time.time()
        
        try:
            # V2.1: Usar OpenRouter com :floor routing para jobs background
            if self.use_openrouter and is_background_job:
                result = await self._generate_with_openrouter_optimized(
                    cluster_content, 
                    priority=priority,
                    is_background=is_background_job
                )
                if result:
                    result.processing_time = time.time() - start_time
                    result.processing_method = "openrouter_floor_optimized"
                    logger.info(f"✅ Cluster Label V2.1: Gerado via OpenRouter :floor em {result.processing_time:.2f}s")
                    return result
            
            # Fallback para método V2 tradicional
            return await self._generate_with_fallback_cascade(cluster_content, start_time)
            
        except Exception as e:
            logger.error(f"❌ Erro na geração de cluster label V2.1: {e}")
            
            # Emergency fallback
            return ClusterLabelResultV2(
                label=f"Cluster_{hash(cluster_content) % 1000:03d}",
                description="Rótulo gerado por fallback de emergência",
                category="Geral",
                keywords=["cluster", "fallback"],
                confidence=0.3,
                alternative_labels=[],
                processing_method="emergency_fallback",
                processing_time=time.time() - start_time
            )
    
    async def _generate_with_openrouter_optimized(
        self, 
        cluster_content: str, 
        priority: str = "cost",
        is_background: bool = True
    ) -> Optional[ClusterLabelResultV2]:
        """
        🆕 V2.1: Geração otimizada usando OpenRouter com :floor routing.
        
        Args:
            cluster_content: Conteúdo do cluster
            priority: Prioridade de roteamento
            is_background: Se é job background
        
        Returns:
            ClusterLabelResultV2 ou None se falhar
        """
        try:
            # Lazy initialize OpenRouter client
            if not self.openrouter_client:
                from services.openrouter_client import get_openrouter_client
                self.openrouter_client = get_openrouter_client()
            
            # Preparar contexto otimizado para batch processing
            context = self._prepare_batch_labeling_context(cluster_content)
            
            # V2.1: Usar call_with_priority_routing para otimização automática
            response = await self.openrouter_client.call_with_priority_routing(
                model="x-ai/grok-4",  # Grok 4 base model
                priority=priority,  # "cost" automaticamente adiciona :floor
                messages=[
                    {"role": "system", "content": self.labeling_system_prompt_optimized},
                    {"role": "user", "content": context}
                ],
                tools=[self.cluster_tool],
                tool_choice={"type": "function", "function": {"name": "generate_cluster_label"}},
                temperature=0.7,  # Criatividade para rótulos interessantes
                max_tokens=500,   # Limite para controle de custo
                # V2.1: Headers específicos para jobs background
                extra_headers={
                    "X-Priority": "cost",
                    "X-Background-Job": "true"
                } if is_background else {}
            )
            
            # Processar resposta
            if response.get("response") and hasattr(response["response"], "choices"):
                tool_call = response["response"].choices[0].message.tool_calls[0]
                function_args = json.loads(tool_call.function.arguments)
                
                return ClusterLabelResultV2(
                    label=function_args.get("label", "Cluster Genérico"),
                    description=function_args.get("description", ""),
                    category=function_args.get("category", "Geral"),
                    keywords=function_args.get("keywords", []),
                    confidence=function_args.get("confidence", 0.7),
                    alternative_labels=function_args.get("alternative_labels", []),
                    processing_method="openrouter_grok4_floor",
                    sdk_level=response.get("fallback_level", 1),
                    grok_enhanced=True
                )
            
            return None
            
        except Exception as e:
            logger.warning(f"⚠️ OpenRouter optimized falhou: {e}")
            return None
    
    def _prepare_cluster_context(
        self,
        cluster_content: List[str],
        cluster_metadata: Optional[Dict[str, Any]] = None,
        context: Optional[str] = None
    ) -> str:
        """Prepara contexto estruturado para análise de cluster."""
        
        context_parts = [
            "# ANÁLISE DE CLUSTER PARA ROTULAGEM",
            "",
            "## CONTEÚDO DO CLUSTER",
            f"**Número de itens**: {len(cluster_content)}",
            ""
        ]
        
        # Mostrar sample do conteúdo (máximo 10 itens)
        sample_content = cluster_content[:10]
        for i, content in enumerate(sample_content, 1):
            # Truncar itens muito longos
            truncated = content[:200] + "..." if len(content) > 200 else content
            context_parts.append(f"**Item {i}**: {truncated}")
        
        if len(cluster_content) > 10:
            context_parts.append(f"... e mais {len(cluster_content) - 10} itens similares")
        
        context_parts.append("")
        
        # Adicionar metadados se disponíveis
        if cluster_metadata:
            context_parts.extend([
                "## METADADOS DO CLUSTER",
                f"**Tamanho**: {cluster_metadata.get('size', 'Não especificado')}",
                f"**Densidade**: {cluster_metadata.get('density', 'Não especificada')}",
                f"**Características**: {cluster_metadata.get('features', 'Não especificadas')}",
                ""
            ])
        
        # Adicionar contexto específico
        if context:
            context_parts.extend([
                "## CONTEXTO ADICIONAL",
                context,
                ""
            ])
        
        context_parts.extend([
            "## SOLICITAÇÃO",
            "Analise este cluster e gere um rótulo profissional e conciso.",
            "",
            "**Diretrizes**:",
            "- Rótulo deve ter máximo 4 palavras",
            "- Use terminologia jurídica quando apropriado",
            "- Seja criativo mas profissional",
            "- Identifique o padrão central que une os itens",
            "- Considere utilidade para advogados e clientes",
            "",
            "Use a função 'generate_cluster_label' para fornecer resultado estruturado."
        ])
        
        return "\n".join(context_parts)
    
    def _prepare_batch_labeling_context(self, cluster_content: str) -> str:
        """
        🆕 V2.1: Prepara contexto otimizado para processamento batch.
        
        Contexto mais conciso para reduzir tokens e custo em jobs background.
        """
        return f"""
        🏷️ GERAÇÃO DE RÓTULO - PROCESSAMENTO BATCH

        **CONTEÚDO DO CLUSTER:**
        {cluster_content[:1000]}...  # Truncar para economizar tokens
        
        **INSTRUÇÕES OTIMIZADAS:**
        • Gere rótulo conciso e descritivo
        • Priorize clareza sobre criatividade excessiva
        • Use função 'generate_cluster_label' obrigatoriamente
        • Mantenha respostas focadas e diretas
        
        **MODO:** Background Job - Foque em eficiência
        """
    
    @property
    def labeling_system_prompt_optimized(self) -> str:
        """
        🆕 V2.1: System prompt otimizado para jobs background.
        
        Mais conciso para reduzir tokens e custo.
        """
        return """
        # CLUSTER LABELING SYSTEM V2.1 - Background Optimized
        
        Você é um sistema especializado em rotulagem automática de clusters para processamento batch.
        
        ## OBJETIVO
        Gerar rótulos concisos e precisos para clusters de dados jurídicos.
        
        ## METODOLOGIA OTIMIZADA
        1. **EFICIÊNCIA**: Resposta direta e focada
        2. **PRECISÃO**: Rótulo que capture a essência do cluster
        3. **PADRONIZAÇÃO**: Use categorias consistentes
        4. **ECONOMIA**: Respostas concisas para reduzir custo
        
        ## CATEGORIAS PREFERENCIAIS
        • "Trabalhista", "Civil", "Criminal", "Tributário"
        • "Societário", "Família", "Consumidor", "Administrativo"
        • "Previdenciário", "Ambiental", "Eleitoral", "Geral"
        
        ## QUALIDADE
        • Confidence mínimo: 0.6
        • Máximo 3 palavras-chave principais
        • Máximo 2 rótulos alternativos
        
        Use SEMPRE a função 'generate_cluster_label' para estruturar a resposta.
        """
    
    async def _simulate_grok_labeling(self, analysis_context: str) -> Dict[str, Any]:
        """
        Simula chamada ao Grok 4 para labeling.
        Em produção, usaria o GrokSDKIntegrationService real.
        """
        
        # Simular processamento inteligente
        await asyncio.sleep(0.1)  # Simular latência de API
        
        # Análise heurística dos padrões
        keywords = self._extract_keywords_from_context(analysis_context)
        primary_theme = self._identify_primary_theme(keywords)
        category = self._determine_category(primary_theme, keywords)
        
        # Gerar rótulo criativo baseado nos padrões
        label = self._generate_creative_label(primary_theme, category)
        
        # Simular resposta do Grok 4
        simulated_response = {
            "label": label,
            "description": f"Cluster focado em {primary_theme} com características de {category}",
            "category": category,
            "keywords": keywords[:5],
            "confidence": 0.85,
            "alternative_labels": [
                f"{primary_theme} Avançado",
                f"Especialistas em {primary_theme}",
                f"{primary_theme} Plus"
            ]
        }
        
        return {
            "content": json.dumps(simulated_response),
            "sdk_name": "Grok 4 (Simulado)",
            "sdk_level": 1,
            "model_used": "x-ai/grok-4"
        }
    
    def _extract_keywords_from_context(self, context: str) -> List[str]:
        """Extrai keywords relevantes do contexto."""
        # Palavras jurídicas comuns
        legal_terms = [
            "trabalhista", "civil", "penal", "tributário", "empresarial",
            "contrato", "processo", "advogado", "cliente", "direito",
            "ação", "recurso", "petição", "sentença", "acordo"
        ]
        
        context_lower = context.lower()
        found_keywords = [term for term in legal_terms if term in context_lower]
        
        # Se não encontrou termos jurídicos, usar palavras mais gerais
        if not found_keywords:
            general_terms = ["caso", "análise", "documento", "questão", "problema"]
            found_keywords = [term for term in general_terms if term in context_lower]
        
        return found_keywords[:5] if found_keywords else ["geral"]
    
    def _identify_primary_theme(self, keywords: List[str]) -> str:
        """Identifica tema primário baseado nas keywords."""
        if not keywords:
            return "Casos Gerais"
        
        # Mapeamento de themes
        theme_mapping = {
            "trabalhista": "Direito do Trabalho",
            "civil": "Direito Civil", 
            "penal": "Direito Penal",
            "tributário": "Direito Tributário",
            "empresarial": "Direito Empresarial",
            "contrato": "Contratos",
            "processo": "Processos Judiciais"
        }
        
        for keyword in keywords:
            if keyword in theme_mapping:
                return theme_mapping[keyword]
        
        # Fallback para primeiro keyword
        return keywords[0].title()
    
    def _determine_category(self, primary_theme: str, keywords: List[str]) -> str:
        """Determina categoria do cluster."""
        
        # Mapeamento de categorias
        if any(term in primary_theme.lower() for term in ["direito", "lei", "jurídico"]):
            return "area_juridica"
        elif any(term in keywords for term in ["cliente", "atendimento", "consulta"]):
            return "tipo_cliente"
        elif any(term in keywords for term in ["processo", "ação", "urgente"]):
            return "urgencia"
        elif any(term in keywords for term in ["especialista", "expert", "avançado"]):
            return "especializacao"
        else:
            return "other"
    
    def _generate_creative_label(self, primary_theme: str, category: str) -> str:
        """Gera rótulo criativo estilo Grok."""
        
        # Prefixos creativos por categoria
        creative_prefixes = {
            "area_juridica": ["Especialistas", "Masters", "Pro", "Elite"],
            "tipo_cliente": ["Foco", "Dedicado", "Direto", "Express"],
            "urgencia": ["Rapid", "Flash", "Priority", "Turbo"],
            "especializacao": ["Expert", "Premium", "Advanced", "Select"],
            "other": ["Smart", "Plus", "Pro", "Elite"]
        }
        
        prefixes = creative_prefixes.get(category, creative_prefixes["other"])
        
        # Selecionar prefix criativo
        import random
        selected_prefix = random.choice(prefixes)
        
        # Gerar rótulo final
        if len(primary_theme.split()) <= 2:
            return f"{selected_prefix} {primary_theme}"
        else:
            # Se theme é muito longo, usar apenas o prefix
            core_word = primary_theme.split()[0]
            return f"{selected_prefix} {core_word}"
    
    async def _fallback_basic_labeling(
        self,
        cluster_content: List[str],
        cluster_metadata: Optional[Dict[str, Any]] = None,
        processing_time: float = 0.0
    ) -> ClusterLabelResultV2:
        """Labeling básico como fallback."""
        
        self.logger.warning("🔄 Executando labeling básico de fallback")
        
        # Análise básica do conteúdo
        content_sample = " ".join(cluster_content[:3])
        
        basic_label = "Cluster Geral"
        basic_category = "other"
        
        # Tentativa simples de identificar padrão
        if "trabalhista" in content_sample.lower():
            basic_label = "Casos Trabalhistas"
            basic_category = "area_juridica"
        elif "civil" in content_sample.lower():
            basic_label = "Casos Cíveis"
            basic_category = "area_juridica"
        elif "empresa" in content_sample.lower():
            basic_label = "Casos Empresariais"
            basic_category = "area_juridica"
        
        return ClusterLabelResultV2(
            label=basic_label,
            description="Rótulo gerado por análise básica",
            category=basic_category,
            keywords=["geral", "básico"],
            confidence=0.3,  # Baixa confiança no fallback
            alternative_labels=["Cluster Básico", "Grupo Geral"],
            processing_method="Fallback Heurístico",
            sdk_level=0,
            grok_enhanced=False,
            processing_time=processing_time
        )
    
    def get_service_status(self) -> Dict[str, Any]:
        """Retorna status do serviço V2."""
        return {
            "version": "2.0",
            "primary_model": "x-ai/grok-4",
            "supported_features": [
                "Grok 4 creative labeling",
                "Function calling structured output",
                "4-level fallback architecture",
                "Legal domain optimization",
                "Brazilian law terminology"
            ],
            "categories_supported": [
                "area_juridica", "especializacao", "tipo_cliente", 
                "complexidade", "urgencia", "other"
            ]
        }


# Factory function para compatibilidade
def get_cluster_labeling_service_v2() -> ClusterLabelingServiceV2:
    """Factory function para criar instância V2 do serviço."""
    return ClusterLabelingServiceV2()


if __name__ == "__main__":
    # Teste básico de funcionalidade
    async def test_v2_service():
        service = get_cluster_labeling_service_v2()
        
        print("🏷️ Testando Cluster Labeling Service V2")
        print("=" * 45)
        
        # Status do serviço
        status = service.get_service_status()
        print("📊 Status do Serviço V2:")
        for key, value in status.items():
            print(f"   {key}: {value}")
        
        # Teste com cluster de exemplo
        sample_cluster = [
            "Ação trabalhista por horas extras não pagas",
            "Recurso de sentença em processo trabalhista",
            "Acordo em processo de rescisão indireta",
            "Petição inicial para ação de danos morais trabalhistas",
            "Defesa em ação de assédio moral no trabalho"
        ]
        
        cluster_metadata = {
            "size": len(sample_cluster),
            "density": 0.85,
            "features": "Alta coesão temática trabalhista"
        }
        
        try:
            print(f"\n🔍 Analisando cluster com {len(sample_cluster)} itens...")
            result = await service.generate_cluster_label(
                sample_cluster, 
                cluster_metadata,
                "Contexto: Escritório especializado em direito do trabalho"
            )
            
            print(f"\n✅ Rótulo gerado!")
            print(f"   🏷️ Label: {result.label}")
            print(f"   📝 Descrição: {result.description}")
            print(f"   📂 Categoria: {result.category}")
            print(f"   🔑 Keywords: {', '.join(result.keywords)}")
            print(f"   🎯 Confiança: {result.confidence:.2f}")
            print(f"   🤖 Método: {result.processing_method}")
            print(f"   🚀 Grok Enhanced: {result.grok_enhanced}")
            print(f"   ⏱️ Tempo: {result.processing_time:.3f}s")
            
            if result.alternative_labels:
                print(f"   🔄 Alternativas: {', '.join(result.alternative_labels)}")
            
        except Exception as e:
            print(f"\n❌ Erro no teste: {e}")
    
    # Executar teste
    asyncio.run(test_v2_service()) 
 