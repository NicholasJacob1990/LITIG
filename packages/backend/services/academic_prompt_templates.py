# -*- coding: utf-8 -*-
"""
Academic Prompt Templates for Legal Matching Algorithm
======================================================

Templates consolidados para APIs de enriquecimento acadêmico:
- Perplexity API: Universidades e periódicos em lotes
- OpenAI Deep Research: Fallback individual e jobs offline

Todos os templates retornam JSON válido e seguem métricas acadêmicas oficiais
(CAPES, QS Rankings, SJR, Qualis Direito).
"""

from typing import Dict, List, Any
from datetime import datetime


class AcademicPromptTemplates:
    """Templates prontos para APIs de enriquecimento acadêmico."""
    
    @staticmethod
    def perplexity_universities_payload(universities: List[str]) -> Dict[str, Any]:
        """
        Template 1.1: Avaliação de universidades via Perplexity API.
        
        Args:
            universities: Lista de nomes de universidades (máximo 15)
            
        Returns:
            Payload pronto para POST /v1/chat/completions
        """
        uni_list = "\n".join(f"- {uni}" for uni in universities)
        
        return {
            "model": "sonar-deep-research",
            "search_context_size": "medium",
            "response_format": {"type": "json_object"},
            "max_tokens": 1500,
            "temperature": 0.1,
            "messages": [
                {
                    "role": "system",
                    "content": "Retorne SOMENTE JSON mapeando universidades para nota 0‑1."
                },
                {
                    "role": "user",
                    "content": f"Avalie as instituições abaixo:\n{uni_list}\n\n"
                              "Regra: score_capes = (conceito‑1)/6, score_qs = 1 - log(rank)/log(1000).\n"
                              "final_score = max(score_capes, score_qs)."
                }
            ]
        }
    
    @staticmethod
    def perplexity_journals_payload(journals: List[str]) -> Dict[str, Any]:
        """
        Template 1.2: Avaliação de periódicos via Perplexity API.
        
        Args:
            journals: Lista de nomes de periódicos (máximo 15)
            
        Returns:
            Payload pronto para POST /v1/chat/completions
        """
        jour_list = "\n".join(f"- {jour}" for jour in journals)
        
        return {
            "model": "sonar-deep-research",
            "search_mode": "academic",
            "search_context_size": "low",
            "response_format": {"type": "json_object"},
            "max_tokens": 1500,
            "temperature": 0.1,
            "messages": [
                {
                    "role": "system",
                    "content": "Retorne SOMENTE JSON periódico → nota 0‑1."
                },
                {
                    "role": "user",
                    "content": f"Para cada periódico:\n{jour_list}\n\n"
                              "Se aparecer no Qualis Direito 2024 use: A1=1 … C=0.2.\n"
                              "Senão use SJR 2025: nota = min(1, SJR/20)."
                }
            ]
        }
    
    @staticmethod
    def deep_research_journal_fallback_payload(journal_name: str) -> Dict[str, Any]:
        """
        Template 2.1: Fallback Deep Research para periódico individual.
        Atualizado conforme documentação oficial OpenAI (100% spec).
        
        Args:
            journal_name: Nome do periódico para pesquisa detalhada
            
        Returns:
            Payload pronto para POST /v1/responses (com polling)
        """
        return {
            "model": "o3-deep-research",  # ou "o4-mini-deep-research" para casos simples
            "background": True,  # obrigatório - tarefas podem levar dezenas de minutos
            "input": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "input_text",
                            "text": f'Journal: "{journal_name}".\n'
                                   "• Se constar no Qualis Direito 2024: A1=1 … C=0.2\n"
                                   "• Caso contrário, pegue o SCImago SJR 2025 e calcule nota = min(1, SJR/20).\n\n"
                                   "Devolva SOMENTE JSON "
                                   '{"journal":string,"score":number,"method":"QUALIS|SJR","raw_metric":string}'
                        }
                    ]
                }
            ],
            "tools": [
                {
                    "type": "web_search",  # obrigatório - pelo menos uma fonte externa
                    "search_context_size": "medium"
                },
                {
                    "type": "code_interpreter",  # para análises numéricas se necessário
                    "container": {"type": "auto"}
                }
            ],
            "reasoning": {"summary": "auto"},  # <think> automático sem custo extra
            "response_format": {"type": "json_object"},  # garante JSON válido
            "max_tool_calls": 3,  # controla custo/latência (suficiente para periódicos)
            "store": False  # Zero Data Retention conforme spec
        }
    
    @staticmethod
    def deep_research_qualis_update_payload(last_version_date: str) -> Dict[str, Any]:
        """
        Template 2.2: Job offline para verificar nova versão Qualis Direito.
        Atualizado conforme documentação oficial OpenAI (100% spec).
        
        Args:
            last_version_date: Data da última versão conhecida (formato ISO)
            
        Returns:
            Payload pronto para POST /v1/responses (job semanal)
        """
        return {
            "model": "o3-deep-research",
            "background": True,  # job offline pode demorar
            "input": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "input_text",
                            "text": f"Verifique se a CAPES publicou uma nova planilha Qualis Direito depois de {last_version_date}. "
                                   'Responda estritamente no formato: {"has_new_version":bool,"last_version":string,"download_url":string|null}'
                        }
                    ]
                }
            ],
            "tools": [
                {
                    "type": "web_search",  # ferramenta oficial
                    "search_context_size": "high"  # busca abrangente para job offline
                }
            ],
            "reasoning": {"summary": "auto"},  # <think> automático
            "response_format": {"type": "json_object"},  # garante JSON válido
            "max_tool_calls": 5,  # job offline pode precisar de mais buscas
            "store": False  # não reter dados sensíveis
        }


class AcademicPromptValidator:
    """Validador para garantir qualidade dos templates."""
    
    @staticmethod
    def validate_batch_size(items: List[str], max_size: int = 15) -> None:
        """Valida tamanho do lote para APIs externas."""
        if len(items) > max_size:
            raise ValueError(f"Lote muito grande: {len(items)} > {max_size}")
        
        if not items:
            raise ValueError("Lista vazia não é permitida")
    
    @staticmethod
    def sanitize_institution_name(name: str) -> str:
        """Remove caracteres problemáticos de nomes de instituições."""
        if not name or not name.strip():
            raise ValueError("Nome de instituição vazio")
        
        # Remove quebras de linha e caracteres especiais que podem quebrar JSON
        sanitized = name.strip().replace('\n', ' ').replace('\r', ' ')
        sanitized = ' '.join(sanitized.split())  # Remove espaços duplos
        
        return sanitized
    
    @staticmethod
    def validate_date_format(date_str: str) -> str:
        """Valida e normaliza formato de data."""
        try:
            # Tenta parsear a data para garantir formato válido
            dt = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
            return dt.isoformat()
        except ValueError:
            # Fallback para formato brasileiro
            try:
                dt = datetime.strptime(date_str, '%d/%m/%Y')
                return dt.isoformat()
            except ValueError:
                raise ValueError(f"Formato de data inválido: {date_str}")


# Configurações por tipo de API (atualizadas conforme spec oficial)
API_CONFIGS = {
    "perplexity": {
        "max_batch_size": 15,
        "rate_limit_per_min": 30,
        "timeout_seconds": 30,
        "endpoint": "/v1/chat/completions"  # endpoint padrão Perplexity
    },
    "deep_research": {
        "max_batch_size": 1,  # Processamento individual obrigatório
        "monthly_task_limit": 100,
        "polling_interval_seconds": 10,  # configurável via DEEP_POLL_SECS
        "max_polling_minutes": 15,       # configurável via DEEP_MAX_MIN
        "endpoint": "/v1/responses",      # endpoint oficial OpenAI
        "expected_status": 202,           # status inicial esperado
        "max_tool_calls_default": 3,     # controle de custo padrão
        "max_tool_calls_job": 5          # para jobs offline mais complexos
    }
}

# Mapeamento Qualis → Score numérico (oficial CAPES)
QUALIS_SCORE_MAP = {
    "A1": 1.0,
    "A2": 0.85,
    "A3": 0.70,
    "A4": 0.55,
    "B1": 0.40,
    "B2": 0.30,
    "B3": 0.25,
    "B4": 0.20,
    "C": 0.20
}

# Exemplo de uso das funções
def example_usage():
    """Demonstra como usar os templates na prática."""
    templates = AcademicPromptTemplates()
    validator = AcademicPromptValidator()
    
    # Exemplo 1: Universidades
    unis = ["Universidade de São Paulo", "Harvard Law School"]
    validator.validate_batch_size(unis, 15)
    payload_unis = templates.perplexity_universities_payload(unis)
    
    # Exemplo 2: Periódicos
    journals = ["Revista de Direito Administrativo", "Harvard Law Review"]
    validator.validate_batch_size(journals, 15)
    payload_journals = templates.perplexity_journals_payload(journals)
    
    # Exemplo 3: Fallback individual
    single_journal = "Revista dos Tribunais"
    payload_fallback = templates.deep_research_journal_fallback_payload(single_journal)
    
    # Exemplo 4: Job offline
    last_date = validator.validate_date_format("2024-01-15")
    payload_update = templates.deep_research_qualis_update_payload(last_date)
    
    return {
        "universities": payload_unis,
        "journals": payload_journals,
        "fallback": payload_fallback,
        "update_check": payload_update
    }


if __name__ == "__main__":
    # Teste rápido dos templates
    examples = example_usage()
    print("✅ Templates de prompts acadêmicos criados com sucesso!")
    print(f"📊 {len(examples)} templates disponíveis") 