"""
Análise de Soft Skills com Padrão Strategy

Este módulo implementa diferentes estratégias para análise de soft skills,
permitindo fallback gracioso e configuração via variáveis de ambiente.
"""

import os
import re
import logging
from abc import ABC, abstractmethod
from typing import List, Optional, Dict, Any
import unicodedata

# Configuração do logger
logger = logging.getLogger(__name__)

# Configuração via ENV
SOFTSKILL_MODEL = os.getenv("SOFTSKILL_MODEL", "regex")  # "regex", "roberta", "custom"
SOFTSKILL_FALLBACK = os.getenv("SOFTSKILL_FALLBACK", "true").lower() == "true"


class SoftSkillAnalyzer(ABC):
    """Interface abstrata para análise de soft skills."""
    
    @abstractmethod
    def analyze_reviews(self, reviews: List[str]) -> float:
        """
        Analisa uma lista de reviews e retorna score de soft skills.
        
        Args:
            reviews: Lista de textos de avaliação
            
        Returns:
            Score normalizado entre 0 e 1
        """
        pass
    
    @abstractmethod
    def is_available(self) -> bool:
        """Verifica se o analisador está disponível/funcional."""
        pass


class RegexSoftSkillAnalyzer(SoftSkillAnalyzer):
    """Análise de soft skills baseada em regex (fallback robusto)."""
    
    def __init__(self):
        # Padrões regex precompilados
        self._positive_patterns = [
            r'\batencioso\b', r'\bdedicado\b', r'\bprofissional\b', r'\bcompetente\b',
            r'\beficiente\b', r'\bcordial\b', r'\bprestativo\b', r'\bresponsavel\b',
            r'\bpontual\b', r'\borganizado\b', r'\bcomunicativo\b', r'\bclaro\b',
            r'\btransparente\b', r'\bconfiavel\b', r'\bexcelente\b', r'\botimo\b',
            r'\bbom\b', r'\bsatisfeito\b', r'\brecomendo\b', r'\bgentil\b',
            r'\beducado\b', r'\bpaciente\b', r'\bcompreensivo\b', r'\bdisponivel\b',
            r'\bagil\b', r'\brapido\b', r'\bpositivo\b'
        ]
        
        self._negative_patterns = [
            r'\bdesatento\b', r'\bnegligente\b', r'\bdespreparado\b', r'\bincompetente\b',
            r'\blento\b', r'\brude\b', r'\bgrosseiro\b', r'\birresponsavel\b',
            r'\batrasado\b', r'\bdesorganizado\b', r'\bconfuso\b', r'\bobscuro\b',
            r'\binsatisfeito\b', r'\bnao\s+recomendo\b', r'\bpessimo\b', r'\bruim\b',
            r'\bhorrivel\b', r'\bdemorado\b', r'\bindisponivel\b',
            r'\bausente\b', r'\bnegativo\b'
        ]
        
        self._pos_regex = [re.compile(p, re.I) for p in self._positive_patterns]
        self._neg_regex = [re.compile(p, re.I) for p in self._negative_patterns]
    
    def is_available(self) -> bool:
        """Regex sempre disponível."""
        return True
    
    def analyze_reviews(self, reviews: List[str]) -> float:
        """
        Analisa reviews usando heurísticas de regex.
        
        Melhorias v2.8:
        - Normalização de acentos
        - Suporte a emojis
        - Validação de reviews mobile-friendly
        """
        if not reviews:
            return 0.5  # Neutro quando não há dados
        
        total_score = 0.0
        valid_reviews = 0
        
        for review in reviews:
            if not self._is_valid_review(review):
                continue
                
            # Preprocessamento
            normalized_review = self._preprocess_text(review)
            
            # Contagem de padrões
            pos_count = sum(len(pattern.findall(normalized_review)) for pattern in self._pos_regex)
            neg_count = sum(len(pattern.findall(normalized_review)) for pattern in self._neg_regex)
            
            # Score individual
            if pos_count + neg_count > 0:
                score = pos_count / (pos_count + neg_count)
            else:
                score = 0.5  # Neutro se não há padrões
            
            total_score += score
            valid_reviews += 1
        
        if valid_reviews == 0:
            return 0.5
        
        # Score médio com boost para alta qualidade
        avg_score = total_score / valid_reviews
        boost = 0.1 if avg_score > 0.7 and valid_reviews >= 3 else 0.0
        
        return min(1.0, avg_score + boost)
    
    def _preprocess_text(self, text: str) -> str:
        """Preprocessa texto para análise."""
        # Substituir emojis por palavras
        text = (text.replace('👍', ' positivo ')
                   .replace('👎', ' negativo ')
                   .replace(':+1:', ' positivo ')
                   .replace(':-1:', ' negativo '))
        
        # Substituir -1 isolado
        text = re.sub(r'\b-1\b', ' negativo ', text)
        
        # Normalizar acentos
        text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower()
        
        return text
    
    def _is_valid_review(self, text: str) -> bool:
        """Valida se review é adequado para análise."""
        if not text or len(text.strip()) < 10:
            return False
        
        tokens = text.split()
        if len(tokens) < 2:
            return False
        
        # Variedade de tokens
        if len(tokens) >= 3:
            return True
        
        # Para reviews curtos, verificar unicidade
        unique_ratio = len(set(tokens)) / len(tokens)
        return unique_ratio >= 0.5


class TransformerSoftSkillAnalyzer(SoftSkillAnalyzer):
    """Análise avançada usando modelos Transformer (opcional)."""
    
    def __init__(self, model_name: str = "roberta-base-portuguese-sentiment"):
        self.model_name = model_name
        self._pipeline = None
        self._available = False
        
        try:
            self._load_model()
        except Exception as e:
            logger.warning(f"Não foi possível carregar modelo {model_name}: {e}")
    
    def _load_model(self):
        """Carrega modelo Transformer sob demanda."""
        try:
            from transformers import pipeline
            self._pipeline = pipeline(
                "sentiment-analysis",
                model=self.model_name,
                return_all_scores=True
            )
            self._available = True
            logger.info(f"Modelo {self.model_name} carregado com sucesso")
        except ImportError:
            logger.warning("Biblioteca 'transformers' não encontrada. Instale com: pip install transformers torch")
        except Exception as e:
            logger.error(f"Erro ao carregar modelo {self.model_name}: {e}")
    
    def is_available(self) -> bool:
        """Verifica se o modelo está disponível."""
        return self._available
    
    def analyze_reviews(self, reviews: List[str]) -> float:
        """
        Analisa reviews usando modelo Transformer.
        
        Args:
            reviews: Lista de textos de avaliação
            
        Returns:
            Score médio de sentiment positivo (0-1)
        """
        if not self._available or not reviews:
            return 0.5
        
        # Filtrar reviews válidos
        valid_reviews = [r for r in reviews if self._is_valid_review(r)]
        if not valid_reviews:
            return 0.5
        
        try:
            # Análise em batch para eficiência
            results = self._pipeline(valid_reviews)
            
            scores = []
            for result in results:
                # Extrair score positivo (formato pode variar por modelo)
                positive_score = self._extract_positive_score(result)
                scores.append(positive_score)
            
            # Retornar média ponderada
            return sum(scores) / len(scores)
            
        except Exception as e:
            logger.error(f"Erro na análise Transformer: {e}")
            return 0.5
    
    def _extract_positive_score(self, result: List[Dict[str, Any]]) -> float:
        """Extrai score positivo do resultado do modelo."""
        # Formato típico: [{'label': 'POSITIVE', 'score': 0.9}, {'label': 'NEGATIVE', 'score': 0.1}]
        for item in result:
            if item['label'].upper() in ['POSITIVE', 'POS', 'POSITIVO']:
                return item['score']
        
        # Fallback: assumir que primeiro item é positivo
        return result[0]['score'] if result else 0.5
    
    def _is_valid_review(self, text: str) -> bool:
        """Validação básica de review."""
        return text and len(text.strip()) >= 10


class SoftSkillAnalyzerFactory:
    """Factory para criar analisadores de soft skills."""
    
    @staticmethod
    def create_analyzer(model_type: Optional[str] = None) -> SoftSkillAnalyzer:
        """
        Cria analisador baseado na configuração.
        
        Args:
            model_type: Tipo do modelo ("regex", "roberta", "custom") ou None para usar ENV
            
        Returns:
            Instância do analisador apropriado
        """
        model_type = model_type or SOFTSKILL_MODEL
        
        if model_type == "regex":
            return RegexSoftSkillAnalyzer()
        
        elif model_type in ["roberta", "roberta-base-portuguese-sentiment"]:
            transformer = TransformerSoftSkillAnalyzer("roberta-base-portuguese-sentiment")
            if transformer.is_available():
                logger.info("Usando análise Transformer para soft skills")
                return transformer
            elif SOFTSKILL_FALLBACK:
                logger.info("Fallback para análise regex")
                return RegexSoftSkillAnalyzer()
            else:
                raise RuntimeError("Modelo Transformer não disponível e fallback desabilitado")
        
        elif model_type == "custom":
            # Placeholder para modelo customizado
            transformer = TransformerSoftSkillAnalyzer(os.getenv("CUSTOM_MODEL_NAME", "custom-model"))
            if transformer.is_available():
                return transformer
            elif SOFTSKILL_FALLBACK:
                logger.info("Fallback para análise regex")
                return RegexSoftSkillAnalyzer()
            else:
                raise RuntimeError("Modelo customizado não disponível e fallback desabilitado")
        
        else:
            logger.warning(f"Tipo de modelo desconhecido: {model_type}. Usando regex.")
            return RegexSoftSkillAnalyzer()


# Instância global (singleton) para reutilização
_analyzer_instance: Optional[SoftSkillAnalyzer] = None


def get_soft_skill_analyzer() -> SoftSkillAnalyzer:
    """
    Retorna instância singleton do analisador.
    
    Returns:
        Analisador de soft skills configurado
    """
    global _analyzer_instance
    
    if _analyzer_instance is None:
        _analyzer_instance = SoftSkillAnalyzerFactory.create_analyzer()
    
    return _analyzer_instance


def analyze_soft_skills(reviews: List[str]) -> float:
    """
    Função de conveniência para análise de soft skills.
    
    Args:
        reviews: Lista de textos de avaliação
        
    Returns:
        Score normalizado entre 0 e 1
    """
    analyzer = get_soft_skill_analyzer()
    return analyzer.analyze_reviews(reviews) 