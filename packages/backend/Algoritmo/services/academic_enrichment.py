# -*- coding: utf-8 -*-
"""
services/academic_enrichment.py

Serviço de enriquecimento acadêmico que avalia universidades e periódicos
usando APIs externas com cache inteligente.
"""

import asyncio
from typing import Dict, List, Any, Optional
from ..utils.text_utils import canonical, _chunks


class AcademicPromptTemplates:
    """Templates para prompts de avaliação acadêmica."""
    
    def get_university_evaluation_prompt(self, uni_name: str) -> str:
        return f"Avalie a reputação acadêmica da universidade '{uni_name}' em escala 0-10."
    
    def get_journal_evaluation_prompt(self, journ_name: str) -> str:
        return f"Avalie o fator de impacto do periódico '{journ_name}' em escala 0-10."


class AcademicPromptValidator:
    """Validador para prompts acadêmicos."""
    
    def validate_batch_size(self, items: List[str], max_size: int):
        if len(items) > max_size:
            raise ValueError(f"Batch size {len(items)} exceeds maximum {max_size}")


class AcademicEnricher:
    """
    Serviço de enriquecimento acadêmico que avalia universidades e periódicos
    usando APIs externas (Perplexity + Deep Research) com cache inteligente.
    """
    
    def __init__(self, cache, perplexity_chat_func=None, deep_research_func=None, 
                 uni_ttl_h: int = 720, jour_ttl_h: int = 720, audit_logger=None):
        """
        Inicializa o enriquecedor acadêmico.
        
        Args:
            cache: Instância do cache Redis
            perplexity_chat_func: Função para chamadas à API Perplexity
            deep_research_func: Função para chamadas à API Deep Research
            uni_ttl_h: TTL em horas para cache de universidades
            jour_ttl_h: TTL em horas para cache de periódicos
            audit_logger: Logger para auditoria
        """
        self.cache = cache
        self.perplexity_chat = perplexity_chat_func
        self.deep_research = deep_research_func
        self.uni_ttl_h = uni_ttl_h
        self.jour_ttl_h = jour_ttl_h
        self.audit_logger = audit_logger
        self.validator = AcademicPromptValidator()
        self.templates = AcademicPromptTemplates()
        
    async def score_universities(self, uni_names: List[str]) -> Dict[str, float]:
        """
        Avalia universidades usando APIs externas com cache Redis.
        
        Args:
            uni_names: Lista de nomes de universidades
            
        Returns:
            Dicionário {nome_universidade: score_0_1}
        """
        if not uni_names:
            return {}
            
        try:
            # Validar input
            self.validator.validate_batch_size(uni_names, 15)
            
            # Processar em lotes para eficiência
            results = {}
            for chunk in _chunks(uni_names, 5):  # Lotes de 5
                chunk_results = await self._score_universities_batch(chunk)
                results.update(chunk_results)
                
            return results
            
        except Exception as e:
            if self.audit_logger:
                self.audit_logger.error("Erro no scoring de universidades", {
                    "error": str(e),
                    "universities": uni_names
                })
            # Fallback: scores neutros
            return {name: 0.5 for name in uni_names}
    
    async def score_journals(self, journ_names: List[str]) -> Dict[str, float]:
        """
        Avalia periódicos/journals usando APIs externas com cache Redis.
        
        Args:
            journ_names: Lista de nomes de periódicos
            
        Returns:
            Dicionário {nome_periodico: score_0_1}
        """
        if not journ_names:
            return {}
            
        try:
            # Validar input
            self.validator.validate_batch_size(journ_names, 10)
            
            # Processar em lotes
            results = {}
            for chunk in _chunks(journ_names, 3):  # Lotes menores para journals
                chunk_results = await self._score_journals_batch(chunk)
                results.update(chunk_results)
                
            return results
            
        except Exception as e:
            if self.audit_logger:
                self.audit_logger.error("Erro no scoring de periódicos", {
                    "error": str(e),
                    "journals": journ_names
                })
            # Fallback: scores neutros
            return {name: 0.5 for name in journ_names}
    
    async def _score_universities_batch(self, universities: List[str]) -> Dict[str, float]:
        """Processa um lote de universidades."""
        results = {}
        
        for uni_name in universities:
            # Chave de cache normalizada
            cache_key = canonical(uni_name)
            
            # Tentar obter do cache
            cached_score = await self.cache.get_academic_score(f"uni:{cache_key}")
            if cached_score is not None:
                results[uni_name] = cached_score
                continue
            
            # Cache miss - consultar APIs externas
            score = await self._query_university_reputation(uni_name)
            
            # Armazenar no cache com TTL configurável
            await self.cache.set_academic_score(
                f"uni:{cache_key}", 
                score, 
                ttl_h=self.uni_ttl_h
            )
            
            results[uni_name] = score
            
            # Rate limiting entre requisições
            await asyncio.sleep(0.5)
        
        return results
    
    async def _score_journals_batch(self, journals: List[str]) -> Dict[str, float]:
        """Processa um lote de periódicos."""
        results = {}
        
        for journ_name in journals:
            # Chave de cache normalizada
            cache_key = canonical(journ_name)
            
            # Tentar obter do cache
            cached_score = await self.cache.get_academic_score(f"jour:{cache_key}")
            if cached_score is not None:
                results[journ_name] = cached_score
                continue
            
            # Cache miss - consultar APIs externas
            score = await self._query_journal_impact(journ_name)
            
            # Armazenar no cache
            await self.cache.set_academic_score(
                f"jour:{cache_key}", 
                score, 
                ttl_h=self.jour_ttl_h
            )
            
            results[journ_name] = score
            
            # Rate limiting
            await asyncio.sleep(0.3)
        
        return results
    
    async def _query_university_reputation(self, uni_name: str) -> float:
        """
        Consulta reputação de universidade usando Perplexity + Deep Research.
        
        Returns:
            Score normalizado entre 0 e 1
        """
        try:
            # Template para avaliação de universidade
            prompt = self.templates.get_university_evaluation_prompt(uni_name)
            
            # Tentar Perplexity primeiro (mais rápido)
            if self.perplexity_chat:
                payload = {
                    "model": "llama-3.1-sonar-small-128k-online",
                    "messages": [{"role": "user", "content": prompt}],
                    "max_tokens": 500,
                    "temperature": 0.1
                }
                
                result = await self.perplexity_chat(payload)
                if result and "score" in result:
                    return self._normalize_score(result["score"])
            
            # Fallback para Deep Research (mais lento mas preciso)
            if self.deep_research:
                deep_payload = {
                    "model": "gpt-4o-deep",
                    "messages": [{"role": "user", "content": prompt}],
                    "max_completion_tokens": 300
                }
                
                deep_result = await self.deep_research(deep_payload)
                if deep_result and "score" in deep_result:
                    return self._normalize_score(deep_result["score"])
            
            # Fallback baseado em heurísticas simples
            return self._heuristic_university_score(uni_name)
            
        except Exception as e:
            if self.audit_logger:
                self.audit_logger.warning("Erro na consulta de universidade", {
                    "university": uni_name,
                    "error": str(e)
                })
            return self._heuristic_university_score(uni_name)
    
    async def _query_journal_impact(self, journ_name: str) -> float:
        """
        Consulta fator de impacto de periódico usando APIs externas.
        
        Returns:
            Score normalizado entre 0 e 1
        """
        try:
            # Template para avaliação de periódico
            prompt = self.templates.get_journal_evaluation_prompt(journ_name)
            
            # Usar Perplexity para busca de impacto
            if self.perplexity_chat:
                payload = {
                    "model": "llama-3.1-sonar-small-128k-online",
                    "messages": [{"role": "user", "content": prompt}],
                    "max_tokens": 400,
                    "temperature": 0.1
                }
                
                result = await self.perplexity_chat(payload)
                if result and "score" in result:
                    return self._normalize_score(result["score"])
            
            # Fallback heurístico
            return self._heuristic_journal_score(journ_name)
            
        except Exception as e:
            if self.audit_logger:
                self.audit_logger.warning("Erro na consulta de periódico", {
                    "journal": journ_name,
                    "error": str(e)
                })
            return self._heuristic_journal_score(journ_name)
    
    def _normalize_score(self, raw_score: Any) -> float:
        """Normaliza score retornado pelas APIs para range 0-1."""
        try:
            if isinstance(raw_score, (int, float)):
                # Se já for numérico, normalizar
                if 0 <= raw_score <= 1:
                    return float(raw_score)
                elif 0 <= raw_score <= 10:
                    return float(raw_score / 10)
                elif 0 <= raw_score <= 100:
                    return float(raw_score / 100)
                else:
                    return 0.5  # Valor fora do esperado
            elif isinstance(raw_score, str):
                # Tentar converter string para float
                return float(raw_score.strip()) if raw_score.strip() else 0.5
            else:
                return 0.5
        except (ValueError, TypeError):
            return 0.5
    
    def _heuristic_university_score(self, uni_name: str) -> float:
        """Fallback heurístico para universidades quando APIs falham."""
        name_lower = uni_name.lower()
        
        # Universidades top mundial
        if any(keyword in name_lower for keyword in [
            "harvard", "stanford", "mit", "yale", "princeton", 
            "cambridge", "oxford", "sorbonne"
        ]):
            return 1.0
        
        # Universidades brasileiras reconhecidas
        if any(keyword in name_lower for keyword in [
            "usp", "unicamp", "ufrj", "puc", "fgv", "insper", 
            "universidade de sao paulo", "pontifícia universidade"
        ]):
            return 0.8
        
        # Universidades federais/estaduais
        if any(keyword in name_lower for keyword in [
            "federal", "estadual", "ufmg", "ufrgs", "ufsc"
        ]):
            return 0.7
        
        # Outras universidades
        if "universidade" in name_lower or "faculdade" in name_lower:
            return 0.6
        
        # Default para instituições não reconhecidas
        return 0.4
    
    def _heuristic_journal_score(self, journ_name: str) -> float:
        """Fallback heurístico para periódicos quando APIs falham."""
        name_lower = journ_name.lower()
        
        # Periódicos internacionais top
        if any(keyword in name_lower for keyword in [
            "harvard law review", "yale law", "columbia law", 
            "stanford law", "nature", "science"
        ]):
            return 1.0
        
        # Periódicos brasileiros reconhecidos
        if any(keyword in name_lower for keyword in [
            "revista de direito administrativo", "revista dos tribunais",
            "revista de direito constitucional", "conjur"
        ]):
            return 0.8
        
        # Revistas acadêmicas gerais
        if any(keyword in name_lower for keyword in [
            "revista", "journal", "law review", "direito"
        ]):
            return 0.6
        
        # Default
        return 0.5


def create_academic_enricher(cache, perplexity_func=None, deep_func=None, 
                           uni_ttl_h: int = 720, jour_ttl_h: int = 720, 
                           audit_logger=None) -> AcademicEnricher:
    """Factory function para criar instância do enriquecedor acadêmico."""
    return AcademicEnricher(
        cache=cache,
        perplexity_chat_func=perplexity_func,
        deep_research_func=deep_func,
        uni_ttl_h=uni_ttl_h,
        jour_ttl_h=jour_ttl_h,
        audit_logger=audit_logger
    )
 
 