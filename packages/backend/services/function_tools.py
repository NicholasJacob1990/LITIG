"""
Function Tools Definitions - Sistema LITIG-1
============================================

Definições centralizadas de todos os Function Calling Tools conforme 
MODEL_CARDS_TEMPLATES.md e PLANO_EVOLUCAO_COMPLETO_OPENROUTER_LANGGRAPH.md

Versão: 2.1 (Janeiro 2025)
"""

from typing import Dict, Any, List

class LLMFunctionTools:
    """Centraliza todas as definições de Function Calling Tools do sistema."""
    
    @staticmethod
    def get_lex9000_tool() -> Dict[str, Any]:
        """Tool para análise jurídica detalhada LEX-9000."""
        return {
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
    
    @staticmethod
    def get_lawyer_profile_tool() -> Dict[str, Any]:
        """Tool para análise de perfil de advogados."""
        return {
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
    
    @staticmethod
    def get_case_context_tool() -> Dict[str, Any]:
        """Tool para análise de contexto de casos."""
        return {
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
    
    @staticmethod
    def get_partnership_tool() -> Dict[str, Any]:
        """Tool para análise de sinergia de parcerias."""
        return {
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
    
    @staticmethod
    def get_cluster_labeling_tool() -> Dict[str, Any]:
        """Tool para rotulagem automática de clusters."""
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
    
    @staticmethod
    def get_ocr_extraction_tool() -> Dict[str, Any]:
        """Tool para extração estruturada de dados OCR."""
        return {
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

    @classmethod
    def get_all_tools(cls) -> Dict[str, Dict[str, Any]]:
        """Retorna todas as ferramentas disponíveis."""
        return {
            "lex9000": cls.get_lex9000_tool(),
            "lawyer_profile": cls.get_lawyer_profile_tool(),
            "case_context": cls.get_case_context_tool(),
            "partnership": cls.get_partnership_tool(),
            "cluster_labeling": cls.get_cluster_labeling_tool(),
            "ocr_extraction": cls.get_ocr_extraction_tool()
        }

    @classmethod
    def get_tool_by_service(cls, service_name: str) -> Dict[str, Any]:
        """Retorna a ferramenta específica para um serviço."""
        tools = cls.get_all_tools()
        if service_name not in tools:
            raise ValueError(f"Serviço '{service_name}' não encontrado. Disponíveis: {list(tools.keys())}")
        return tools[service_name] 
 