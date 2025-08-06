# Preservação e Aprimoramento dos Prompts Ricos - Exemplo LEX-9000

## Prompt Original Preservado (200+ linhas)

```python
# ✅ PROMPT ORIGINAL MANTIDO INTEGRALMENTE
lex_system_prompt = """
# PERSONA
Você é o "LEX-9000", um assistente jurídico especializado em Direito Brasileiro, evoluído para trabalhar com dados conversacionais estruturados. Sua função é realizar análise jurídica profissional detalhada baseada em conversas de triagem já finalizadas.

# ESPECIALIZAÇÃO
- Conhecimento profundo do ordenamento jurídico brasileiro
- Experiência em todas as áreas do direito (civil, trabalhista, criminal, administrativo, etc.)
- Capacidade de identificar urgência, complexidade e viabilidade processual
- Foco em aspectos práticos e estratégicos

# CONTEXTO DE USO
Você recebe dados estruturados de uma conversa de triagem inteligente já finalizada e deve produzir uma análise jurídica completa e detalhada.

# METODOLOGIA DE ANÁLISE
## ANÁLISE ESTRUTURADA COMPLETA
- Classificação jurídica precisa
- Extração de dados factuais organizados
- Análise de viabilidade fundamentada
- Avaliação de urgência e prazos
- Aspectos técnicos e jurisprudenciais
- Recomendações estratégicas práticas

# IMPORTANTE
- Mantenha linguagem profissional e técnica
- Use terminologia jurídica brasileira correta
- Seja específico e fundamentado nas análises
- Considere sempre o contexto brasileiro
- Baseie-se apenas nas informações fornecidas
- Se uma informação não estiver disponível, use "N/A" ou array vazio

# INSTRUÇÃO FINAL
Use SEMPRE a função 'analyze_legal_case' para retornar sua análise de forma estruturada e precisa.
"""
```

## Implementação: Antes vs. Depois

### ❌ ANTES: Parsing Manual Frágil

```python
async def analyze_complex_case_old(self, conversation_data):
    try:
        response = await self.openai_client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": self.lex_system_prompt},  # ✅ Prompt rico
                {"role": "user", "content": context}
            ],
            max_tokens=4000,
            temperature=0.1
        )
        
        # ❌ PROBLEMA: Parsing manual pode falhar
        response_text = response.choices[0].message.content
        
        # Tentar extrair JSON (pode falhar)
        try:
            return json.loads(response_text)
        except json.JSONDecodeError:
            # Hack frágil com regex
            match = re.search(r'\{.*\}', response_text, re.DOTALL)
            if match:
                return json.loads(match.group(0))
            else:
                raise ValueError("Não foi possível extrair JSON válido")
                
    except Exception as e:
        # ❌ Fallback manual para outros modelos...
        try:
            # Repetir lógica para Claude...
            pass
        except:
            # Repetir lógica para outro modelo...
            pass
```

### ✅ DEPOIS: Function Calling Robusto + Mesmo Prompt Rico

```python
async def analyze_complex_case_new(self, conversation_data):
    context = self._prepare_lex_context(conversation_data)
    
    try:
        # ✅ Nível 1: Grok 4 com mesmo prompt rico + function calling
        response = await self.openrouter_client.chat.completions.create(
            model="x-ai/grok-4",  # Grok 4
            messages=[
                {"role": "system", "content": self.lex_system_prompt},  # ✅ MESMO PROMPT RICO
                {"role": "user", "content": context}
            ],
            tools=[self.lex_analysis_tool],  # ✅ Estrutura JSON garantida
            tool_choice={"type": "function", "function": {"name": "analyze_legal_case"}},
            temperature=0.1
        )
        
        # ✅ Parsing robusto garantido pelo function calling
        tool_call = response.choices[0].message.tool_calls[0]
        return json.loads(tool_call.function.arguments)
        
    except Exception as e:
        logger.warning(f"Grok 4 falhou: {e}")
        
        # ✅ Nível 2: Auto-router com mesmo prompt + function calling
        try:
            response = await self.openrouter_client.chat.completions.create(
                model="openrouter/auto",  # Router escolhe melhor modelo
                messages=[
                    {"role": "system", "content": self.lex_system_prompt},  # ✅ MESMO PROMPT
                    {"role": "user", "content": context}
                ],
                tools=[self.lex_analysis_tool],
                tool_choice={"type": "function", "function": {"name": "analyze_legal_case"}}
            )
            
            tool_call = response.choices[0].message.tool_calls[0]
            return json.loads(tool_call.function.arguments)
            
        except Exception as e:
            logger.warning(f"Auto-router falhou: {e}")
            
            # ✅ Nível 3: Cascata direta com mesmo prompt
            return await self._direct_fallback_with_tools(context, self.lex_analysis_tool)
```

## Function Tool: Estrutura JSON Garantida

```python
# ✅ Tool que garante a estrutura exata que o LEX-9000 sempre retornou
lex_analysis_tool = {
    "type": "function",
    "function": {
        "name": "analyze_legal_case",
        "description": "Perform comprehensive Brazilian legal case analysis",
        "parameters": {
            "type": "object",
            "properties": {
                "classificacao": {
                    "type": "object",
                    "properties": {
                        "area_principal": {"type": "string"},
                        "assunto_principal": {"type": "string"},
                        "subarea": {"type": "string"},
                        "natureza": {"type": "string", "enum": ["Preventivo", "Contencioso"]}
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
                            "items": {"type": "string"}
                        },
                        "valor_causa": {"type": "string"},
                        "documentos_mencionados": {
                            "type": "array",
                            "items": {"type": "string"}
                        }
                    }
                },
                "analise_viabilidade": {
                    "type": "object",
                    "properties": {
                        "classificacao": {"type": "string", "enum": ["Viável", "Parcialmente Viável", "Inviável"]},
                        "pontos_fortes": {"type": "array", "items": {"type": "string"}},
                        "pontos_fracos": {"type": "array", "items": {"type": "string"}},
                        "probabilidade_exito": {"type": "string", "enum": ["Alta", "Média", "Baixa"]},
                        "justificativa": {"type": "string"},
                        "complexidade": {"type": "string", "enum": ["Baixa", "Média", "Alta"]},
                        "custos_estimados": {"type": "string", "enum": ["Baixo", "Médio", "Alto"]}
                    },
                    "required": ["classificacao", "probabilidade_exito", "complexidade"]
                },
                "urgencia": {
                    "type": "object",
                    "properties": {
                        "nivel": {"type": "string", "enum": ["Crítica", "Alta", "Média", "Baixa"]},
                        "motivo": {"type": "string"},
                        "prazo_limite": {"type": "string"},
                        "acoes_imediatas": {"type": "array", "items": {"type": "string"}}
                    },
                    "required": ["nivel", "motivo"]
                },
                "aspectos_tecnicos": {
                    "type": "object",
                    "properties": {
                        "legislacao_aplicavel": {"type": "array", "items": {"type": "string"}},
                        "jurisprudencia_relevante": {"type": "array", "items": {"type": "string"}},
                        "competencia": {"type": "string"},
                        "foro": {"type": "string"},
                        "alertas": {"type": "array", "items": {"type": "string"}}
                    }
                },
                "recomendacoes": {
                    "type": "object",
                    "properties": {
                        "estrategia_sugerida": {"type": "string", "enum": ["Judicial", "Extrajudicial", "Negociação"]},
                        "proximos_passos": {"type": "array", "items": {"type": "string"}},
                        "documentos_necessarios": {"type": "array", "items": {"type": "string"}},
                        "observacoes": {"type": "string"}
                    }
                }
            },
            "required": ["classificacao", "analise_viabilidade", "urgencia"]
        }
    }
}
```

## Resultado: Melhor dos Dois Mundos

### ✅ **O Que Ganhamos:**
1. **Prompts Ricos Preservados**: Toda expertise e sofisticação mantida
2. **Parsing Robusto**: Function calling elimina falhas de JSON
3. **Fallback Inteligente**: 4 níveis de resiliência
4. **Código Limpo**: Eliminação de repetição de lógica
5. **Performance**: Modelos mais rápidos (Grok 4, Gemini 2.5 Pro)

### ✅ **O Que Mantemos:**
1. **Lógica de Triagem Manual**: `simple` → `failover` → `ensemble`
2. **Prompts Especializados**: LEX-9000, Justus, etc.
3. **Expertise Jurídica**: Terminologia brasileira, legislação, jurisprudência
4. **Metodologia Refinada**: Identificação → Detalhamento → Aspectos Técnicos
5. **Saídas Estruturadas**: Mesmos campos JSON detalhados

## Exemplo de Resposta: Antes vs. Depois

### Entrada (Igual)
```json
{
  "conversation_data": {
    "user_description": "Fui demitido sem justa causa, mas a empresa não pagou as verbas rescisórias...",
    "additional_details": "Trabalho registrado há 2 anos, último salário R$ 3.500..."
  }
}
```

### Saída (Idêntica em estrutura e qualidade)
```json
{
  "classificacao": {
    "area_principal": "Direito Trabalhista",
    "assunto_principal": "Rescisão de Contrato de Trabalho",
    "subarea": "Verbas Rescisórias",
    "natureza": "Contencioso"
  },
  "analise_viabilidade": {
    "classificacao": "Viável",
    "pontos_fortes": [
      "Demissão sem justa causa comprovada",
      "Vínculo empregatício registrado",
      "Direito líquido e certo às verbas rescisórias"
    ],
    "probabilidade_exito": "Alta",
    "complexidade": "Baixa"
  }
  // ... resto da análise detalhada igual
}
```

**A diferença é invisível para o usuário final, mas a infraestrutura é muito mais robusta.** 
 