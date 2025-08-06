# Model Cards Templates - Sistema LITIG-1

## Template Base: Model Card

```markdown
# Model Card: [Nome do Serviço]

**Arquivo:** `packages/backend/services/[nome_do_arquivo].py`  
**Versão:** 2.0 (OpenRouter + Function Calling)  
**Data de Atualização:** Janeiro 2025  

## 1. Objetivo e Escopo

### Propósito
[Descrição clara do que este componente de IA faz]

### Casos de Uso
- [Caso de uso primário]
- [Casos de uso secundários]

### Limitações Conhecidas
- [Limitação 1]
- [Limitação 2]

## 2. Arquitetura de Modelo

### Estratégia de 4 Níveis

#### Nível 1: Modelo Primário Específico
- **Modelo:** [Nome do Modelo]
- **Identificador API:** `[provider/model-name]`
- **Provedor:** OpenRouter
- **Justificativa:** [Por que este modelo específico]

#### Nível 2: Fallback Inteligente
- **Modelo:** `openrouter/auto`
- **Gatilho:** Falha do Nível 1
- **Comportamento:** OpenRouter seleciona melhor modelo disponível

#### Nível 3-4: Cascata Direta
- **Gatilho:** Falha total do OpenRouter
- **Sequência:** Gemini → Claude → Grok/OpenAI
- **Objetivo:** Redundância completa

## 3. Function Calling Tool Definition

```json
{
  "type": "function",
  "function": {
    "name": "[tool_name]",
    "description": "[descrição da função]",
    "parameters": {
      "type": "object",
      "properties": {
        // ... definição dos parâmetros
      },
      "required": ["campo1", "campo2"]
    }
  }
}
```

## 4. Prompt Engineering

### System Prompt
```
[Prompt de sistema otimizado]
```

### Context Template
```
[Template para preparação do contexto]
```

## 5. Métricas e Performance

### KPIs Principais
- **Latência Target:** < [X]ms
- **Taxa de Sucesso:** > [Y]%
- **Precisão:** > [Z]%

### Métricas de Fallback
- **Uso do Nível 2:** < [A]%
- **Uso do Nível 3:** < [B]%

## 6. Riscos e Mitigações

| Risco | Mitigação |
|-------|-----------|
| [Risco 1] | [Mitigação 1] |
| [Risco 2] | [Mitigação 2] |

## 7. Changelog

- **v2.0:** Migração para OpenRouter + Function Calling
- **v1.0:** Implementação inicial com cascata manual
```

---

## Model Card 1: LEX-9000 Integration Service

**Arquivo:** `packages/backend/services/lex9000_integration_service.py`  
**Versão:** 2.0 (OpenRouter + Function Calling)  

### 1. Objetivo e Escopo

#### Propósito
Realizar análise jurídica detalhada e estruturada de casos complexos, extraindo classificação legal, análise de viabilidade, urgência e aspectos técnicos específicos do direito brasileiro.

#### Casos de Uso
- Análise detalhada de casos identificados como "complexos" pela IA entrevistadora
- Estruturação de informações jurídicas para suporte à decisão
- Geração de relatórios de viabilidade processual

#### Limitações Conhecidas
- Focado especificamente no direito brasileiro
- Requer dados de entrada bem estruturados da conversa prévia
- Não substitui análise humana especializada

### 2. Arquitetura de Modelo

#### Nível 1: Grok 4
- **Modelo:** Grok 4
- **Identificador API:** `x-ai/grok-4`
- **Justificativa:** Excelente capacidade de raciocínio jurídico e análise estruturada

#### Nível 2-4: Conforme template base

### 3. Function Calling Tool Definition

```json
{
  "type": "function",
  "function": {
    "name": "analyze_legal_case",
    "description": "Perform comprehensive Brazilian legal case analysis with structured output",
    "parameters": {
      "type": "object",
      "properties": {
        "classificacao": {
          "type": "object",
          "properties": {
            "area_principal": {
              "type": "string",
              "description": "Main legal area (e.g., Direito Trabalhista, Direito Civil)"
            },
            "assunto_principal": {
              "type": "string", 
              "description": "Main legal subject matter"
            },
            "subarea": {
              "type": "string",
              "description": "Legal subspecialty area"
            },
            "natureza": {
              "type": "string",
              "enum": ["Preventivo", "Contencioso"],
              "description": "Nature of legal action"
            }
          },
          "required": ["area_principal", "assunto_principal", "natureza"]
        },
        "dados_extraidos": {
          "type": "object",
          "properties": {
            "partes": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "nome": {"type": "string"},
                  "tipo": {"type": "string", "enum": ["Requerente", "Requerido", "Terceiro"]},
                  "qualificacao": {"type": "string"}
                }
              }
            },
            "fatos_principais": {
              "type": "array",
              "items": {"type": "string"},
              "description": "Main facts in chronological order"
            },
            "valor_causa": {
              "type": "string",
              "description": "Case monetary value or 'Inestimável'"
            }
          }
        },
        "analise_viabilidade": {
          "type": "object",
          "properties": {
            "classificacao": {
              "type": "string",
              "enum": ["Viável", "Parcialmente Viável", "Inviável"]
            },
            "pontos_fortes": {
              "type": "array",
              "items": {"type": "string"}
            },
            "pontos_fracos": {
              "type": "array", 
              "items": {"type": "string"}
            },
            "probabilidade_exito": {
              "type": "string",
              "enum": ["Alta", "Média", "Baixa"]
            },
            "complexidade": {
              "type": "string",
              "enum": ["Baixa", "Média", "Alta"]
            },
            "custos_estimados": {
              "type": "string",
              "enum": ["Baixo", "Médio", "Alto"]
            }
          },
          "required": ["classificacao", "probabilidade_exito", "complexidade"]
        },
        "urgencia": {
          "type": "object",
          "properties": {
            "nivel": {
              "type": "string",
              "enum": ["Crítica", "Alta", "Média", "Baixa"]
            },
            "motivo": {
              "type": "string",
              "description": "Justification for urgency level"
            },
            "prazo_limite": {
              "type": "string",
              "description": "Deadline date or N/A"
            },
            "acoes_imediatas": {
              "type": "array",
              "items": {"type": "string"},
              "description": "Immediate actions required"
            }
          },
          "required": ["nivel", "motivo"]
        },
        "aspectos_tecnicos": {
          "type": "object",
          "properties": {
            "legislacao_aplicavel": {
              "type": "array",
              "items": {"type": "string"},
              "description": "Applicable laws and articles"
            },
            "jurisprudencia_relevante": {
              "type": "array",
              "items": {"type": "string"},
              "description": "Relevant case law and precedents"
            },
            "competencia": {
              "type": "string",
              "description": "Judicial competence"
            },
            "alertas": {
              "type": "array",
              "items": {"type": "string"},
              "description": "Important alerts and warnings"
            }
          }
        }
      },
      "required": ["classificacao", "analise_viabilidade", "urgencia"]
    }
  }
}
```

### 4. Prompt Engineering

#### System Prompt
```
# PERSONA
Você é o "LEX-9000", um assistente jurídico especializado em Direito Brasileiro, evoluído para trabalhar com dados conversacionais estruturados através de function calling. Sua função é realizar análise jurídica profissional detalhada baseada em conversas de triagem já finalizadas.

# ESPECIALIZAÇÃO
- Conhecimento profundo do ordenamento jurídico brasileiro
- Experiência em todas as áreas do direito (civil, trabalhista, criminal, administrativo, etc.)
- Capacidade de identificar urgência, complexidade e viabilidade processual
- Foco em aspectos práticos e estratégicos

# METODOLOGIA
Use SEMPRE a função 'analyze_legal_case' para retornar sua análise de forma estruturada e precisa.
```

### 5. Métricas e Performance

#### KPIs Principais
- **Latência Target:** < 15s
- **Taxa de Sucesso:** > 98%
- **Precisão de Classificação:** > 95%

---

## Model Card 2: Lawyer Profile Analysis Service

**Arquivo:** `packages/backend/services/lawyer_profile_analysis_service.py`  

### 1. Objetivo e Escopo

#### Propósito
Analisar qualitativamente perfis de advogados para extrair insights não estruturados como estilo de comunicação, qualidade da experiência e especialidades de nicho.

### 2. Arquitetura de Modelo

#### Nível 1: Gemini 2.5 Pro
- **Identificador API:** `google/gemini-1.5-pro`
- **Justificativa:** Excelente compreensão contextual e análise qualitativa

### 3. Function Calling Tool Definition

```json
{
  "type": "function",
  "function": {
    "name": "extract_lawyer_insights",
    "description": "Extract structured qualitative insights from lawyer profile data",
    "parameters": {
      "type": "object",
      "properties": {
        "expertise_level": {
          "type": "number",
          "minimum": 0,
          "maximum": 1,
          "description": "Professional expertise level from 0 (novice) to 1 (expert)"
        },
        "specialization_confidence": {
          "type": "number", 
          "minimum": 0,
          "maximum": 1,
          "description": "Confidence in the identified specialization areas"
        },
        "communication_style": {
          "type": "string",
          "enum": ["formal", "accessible", "technical"],
          "description": "Primary communication style based on available data"
        },
        "experience_quality": {
          "type": "string",
          "enum": ["junior", "mid", "senior", "expert"],
          "description": "Quality assessment of professional experience"
        },
        "niche_specialties": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Specific niche specializations detected beyond general practice areas"
        },
        "soft_skills_score": {
          "type": "number",
          "minimum": 0,
          "maximum": 1,
          "description": "Assessment of interpersonal and soft skills"
        },
        "innovation_indicator": {
          "type": "number",
          "minimum": 0,
          "maximum": 1,
          "description": "Tendency to adopt modern technology and innovative methods"
        },
        "client_profile_match": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Types of clients this lawyer would best serve"
        },
        "risk_assessment": {
          "type": "string",
          "enum": ["conservative", "balanced", "aggressive"],
          "description": "Approach to risk in legal strategies"
        },
        "confidence_score": {
          "type": "number",
          "minimum": 0,
          "maximum": 1,
          "description": "Overall confidence in this analysis based on available data"
        }
      },
      "required": [
        "expertise_level",
        "specialization_confidence",
        "communication_style", 
        "experience_quality",
        "confidence_score"
      ]
    }
  }
}
```

---

## Model Card 3: Case Context Analysis Service

**Arquivo:** `packages/backend/services/case_context_analysis_service.py`

### 1. Objetivo e Escopo

#### Propósito
Analisar contexto de casos para identificar fatores de complexidade, perfil de cliente e desafios específicos que algoritmos tradicionais não conseguem capturar.

### 2. Arquitetura de Modelo

#### Nível 1: Claude Sonnet 4
- **Identificador API:** `anthropic/claude-sonnet-4-20250514`
- **Justificativa:** Superior capacidade de análise contextual e raciocínio jurídico

### 3. Function Calling Tool Definition

```json
{
  "type": "function",
  "function": {
    "name": "analyze_case_context",
    "description": "Extract contextual insights and complexity factors from case data",
    "parameters": {
      "type": "object",
      "properties": {
        "complexity_factors": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Specific factors that make this case complex"
        },
        "urgency_reasoning": {
          "type": "string",
          "description": "Detailed reasoning for the urgency assessment"
        },
        "required_expertise": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Specific types of legal expertise needed for this case"
        },
        "case_sensitivity": {
          "type": "string",
          "enum": ["high", "medium", "low"],
          "description": "Level of sensitivity/confidentiality required"
        },
        "expected_duration": {
          "type": "string",
          "enum": ["short_term", "medium_term", "long_term", "unclear"],
          "description": "Expected case duration"
        },
        "communication_needs": {
          "type": "string",
          "enum": ["frequent_updates", "standard", "minimal", "crisis_management"],
          "description": "Client communication requirements"
        },
        "client_personality_type": {
          "type": "string",
          "enum": ["detail_oriented", "results_focused", "emotional_support_needed", "business_minded"],
          "description": "Client personality and needs assessment"
        },
        "success_probability": {
          "type": "number",
          "minimum": 0,
          "maximum": 1,
          "description": "Estimated probability of successful case resolution"
        },
        "key_challenges": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Main challenges expected in this case"
        },
        "recommended_approach": {
          "type": "string",
          "description": "Recommended strategic approach for this case"
        },
        "confidence_score": {
          "type": "number",
          "minimum": 0,
          "maximum": 1,
          "description": "Confidence in this contextual analysis"
        }
      },
      "required": [
        "complexity_factors",
        "urgency_reasoning",
        "success_probability",
        "confidence_score"
      ]
    }
  }
}
```

---

## Model Card 4: Partnership LLM Enhancement Service

**Arquivo:** `packages/backend/services/partnership_llm_enhancement_service.py`

### 1. Objetivo e Escopo

#### Propósito
Analisar sinergia e compatibilidade entre advogados para recomendações de parcerias estratégicas.

### 2. Arquitetura de Modelo

#### Nível 1: Gemini 2.5 Pro
- **Identificador API:** `google/gemini-1.5-pro`
- **Justificativa:** Excelente análise de relacionamentos e compatibilidade

### 3. Function Calling Tool Definition

```json
{
  "type": "function",
  "function": {
    "name": "analyze_partnership_synergy",
    "description": "Analyze compatibility and synergy potential between two lawyers",
    "parameters": {
      "type": "object", 
      "properties": {
        "synergy_score": {
          "type": "number",
          "minimum": 0,
          "maximum": 1,
          "description": "Overall professional synergy score"
        },
        "compatibility_factors": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Specific factors that make these lawyers compatible"
        },
        "strategic_opportunities": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Strategic business opportunities from this partnership"
        },
        "potential_challenges": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Potential challenges or conflicts in the partnership"
        },
        "collaboration_style_match": {
          "type": "string",
          "enum": ["excellent", "good", "fair", "poor"],
          "description": "How well their working styles complement each other"
        },
        "market_positioning_advantage": {
          "type": "string",
          "description": "Market positioning benefits of this partnership"
        },
        "client_value_proposition": {
          "type": "string",
          "description": "Value proposition this partnership offers to clients"
        },
        "confidence_score": {
          "type": "number",
          "minimum": 0,
          "maximum": 1,
          "description": "Confidence in this partnership analysis"
        },
        "reasoning": {
          "type": "string",
          "description": "Detailed reasoning for the partnership recommendation"
        }
      },
      "required": [
        "synergy_score",
        "compatibility_factors",
        "collaboration_style_match",
        "confidence_score",
        "reasoning"
      ]
    }
  }
}
```

---

## Model Card 5: OCR Validation Service

**Arquivo:** `packages/backend/services/ocr_validation_service.py`

### 1. Objetivo e Escopo

#### Propósito
Extrair dados estruturados de documentos após processamento OCR, com foco em documentos brasileiros (CPF, CNPJ, RG, etc.).

### 2. Arquitetura de Modelo

#### Nível 1: GPT-4o-mini
- **Identificador API:** `openai/gpt-4o-mini`
- **Justificativa:** Otimizado para custo/velocidade em tarefas de extração estruturada

### 3. Function Calling Tool Definition

```json
{
  "type": "function",
  "function": {
    "name": "extract_document_data",
    "description": "Extract structured data from OCR-processed Brazilian documents",
    "parameters": {
      "type": "object",
      "properties": {
        "document_type": {
          "type": "string",
          "enum": ["cpf", "cnpj", "rg", "oab", "contrato_trabalho", "holerite", "other"],
          "description": "Type of document identified"
        },
        "person_data": {
          "type": "object",
          "properties": {
            "nome": {"type": "string"},
            "cpf": {"type": "string", "pattern": "^\\d{3}\\.\\d{3}\\.\\d{3}-\\d{2}$"},
            "rg": {"type": "string"},
            "data_nascimento": {"type": "string", "format": "date"},
            "endereco": {"type": "string"},
            "telefone": {"type": "string"},
            "email": {"type": "string", "format": "email"}
          }
        },
        "company_data": {
          "type": "object",
          "properties": {
            "razao_social": {"type": "string"},
            "nome_fantasia": {"type": "string"},
            "cnpj": {"type": "string", "pattern": "^\\d{2}\\.\\d{3}\\.\\d{3}/\\d{4}-\\d{2}$"},
            "endereco": {"type": "string"},
            "atividade_principal": {"type": "string"}
          }
        },
        "extracted_values": {
          "type": "object",
          "properties": {
            "monetary_values": {
              "type": "array",
              "items": {"type": "number"},
              "description": "All monetary values found in the document"
            },
            "dates": {
              "type": "array", 
              "items": {"type": "string", "format": "date"},
              "description": "All dates found in the document"
            }
          }
        },
        "confidence_score": {
          "type": "number",
          "minimum": 0,
          "maximum": 1,
          "description": "Confidence in the extracted data"
        },
        "validation_errors": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Validation errors found in the document"
        }
      },
      "required": ["document_type", "confidence_score"]
    }
  }
}
```

---

## Model Card 6: Cluster Labeling Service

**Arquivo:** `packages/backend/services/cluster_labeling_service.py`

### 1. Objetivo e Escopo

#### Propósito
Gerar rótulos profissionais e concisos para clusters de casos e advogados similares.

### 2. Arquitetura de Modelo

#### Nível 1: Grok 4
- **Identificador API:** `x-ai/grok-4`
- **Justificativa:** Excelente capacidade de síntese e criação de rótulos precisos

### 3. Function Calling Tool Definition

```json
{
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
```

---

## Implementação de Referência

### Classe Base para Function Calling

```python
# packages/backend/services/base_llm_service.py

from typing import Dict, Any, List, Optional
import json
import logging

class BaseLLMService:
    """Classe base para serviços que usam Function Calling."""
    
    def __init__(self, service_name: str):
        self.service_name = service_name
        self.client = OpenRouterClient()
        self.logger = logging.getLogger(f"{service_name}_service")
    
    async def call_with_function(
        self,
        context: str,
        tool_definition: Dict[str, Any],
        primary_model: str,
        system_prompt: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Executa chamada LLM com function calling e fallback de 4 níveis.
        """
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": context})
        
        # Nível 1: Modelo primário específico
        try:
            response = await self.client.chat.completions.create(
                model=primary_model,
                messages=messages,
                tools=[tool_definition],
                tool_choice={"type": "function", "function": {"name": tool_definition["function"]["name"]}}
            )
            return self._parse_function_response(response)
            
        except Exception as e:
            self.logger.warning(f"Nível 1 ({primary_model}) falhou: {e}")
            
            # Nível 2: Auto-router
            try:
                response = await self.client.chat.completions.create(
                    model="openrouter/auto",
                    messages=messages,
                    tools=[tool_definition],
                    tool_choice={"type": "function", "function": {"name": tool_definition["function"]["name"]}}
                )
                return self._parse_function_response(response)
                
            except Exception as e:
                self.logger.warning(f"Nível 2 (auto) falhou: {e}")
                
                # Nível 3-4: Cascata direta
                return await self._direct_fallback_with_function(
                    messages, tool_definition
                )
    
    def _parse_function_response(self, response) -> Dict[str, Any]:
        """Parse da resposta de function calling."""
        try:
            tool_call = response.choices[0].message.tool_calls[0]
            function_args = json.loads(tool_call.function.arguments)
            return function_args
        except Exception as e:
            raise ValueError(f"Erro ao parsear function call: {e}")
    
    async def _direct_fallback_with_function(
        self, 
        messages: List[Dict], 
        tool_definition: Dict
    ) -> Dict[str, Any]:
        """Fallback para chamadas diretas com function calling."""
        # Implementar cascata direta aqui
        # Tentar Gemini → Claude → Grok em sequência
        pass
```

Este documento fornece um template completo e específico para cada serviço, incluindo as definições exatas de Function Calling Tools que tornarão a extração de dados estruturados muito mais confiável do que o parsing manual de JSON. 
 