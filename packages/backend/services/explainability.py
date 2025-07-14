# -*- coding: utf-8 -*-
"""explainability.py
Módulo de Explicabilidade do Sistema de Matching Jurídico
=========================================================
Este módulo centraliza a lógica para traduzir scores internos do algoritmo
de matching em explicações estruturadas e seguras para diferentes públicos,
seguindo os princípios de transparência graduada e proteção de IP.

Versão: explanation_v1
Data: Janeiro 2025
"""

from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from pydantic import BaseModel
import hashlib
import json
import logging

# Setup do logger
logger = logging.getLogger(__name__)

# =============================================================================
# 1. Schemas e Modelos de Dados
# =============================================================================

class PublicExplanation(BaseModel):
    """Schema versionado para explicações públicas (clientes)."""
    lawyer_id: str
    case_id: str
    ranking_position: int
    top_factors: List[str]  # ["⭐ Excelente Avaliação", "📍 Próximo a Você"]
    summary: str           # "Selecionado por sua excelente avaliação..."
    confidence_level: str  # "Alta", "Média", "Baixa"
    version: str = "explanation_v1"

class WeakPoint(BaseModel):
    """Ponto fraco identificado na performance do prestador."""
    feature: str           # "review_score"
    feature_name: str      # "Avaliações"
    current_value: float   # 0.65
    status: str           # "Pode Melhorar"
    suggestion: str       # "Você tem poucas avaliações..."
    priority: str         # "Alta", "Média", "Baixa"

class Benchmark(BaseModel):
    """Benchmark anônimo para comparação de performance."""
    feature_name: str     # "Avaliações"
    your_score: float     # 4.1
    percentile_50: float  # 4.3
    percentile_75: float  # 4.6
    percentile_90: float  # 4.9
    market_position: str  # "Abaixo da Média", "Médio", "Acima da Média"

class Suggestion(BaseModel):
    """Sugestão prática de melhoria."""
    title: str           # "Peça mais avaliações"
    description: str     # "Entre em contato com seus últimos 5 clientes..."
    effort: str         # "Baixo", "Médio", "Alto"
    impact: str         # "Baixo", "Médio", "Alto"
    timeline: str       # "1-2 semanas"

class PerformanceInsights(BaseModel):
    """Schema para insights de performance do prestador."""
    overall_score: int  # 0-100
    grade: str         # "Excelente", "Bom", "Pode Melhorar"
    weak_points: List[WeakPoint]
    benchmarks: Dict[str, Benchmark]
    improvement_suggestions: List[Suggestion]
    trend: str         # "Melhorando", "Estável", "Declinando"
    last_updated: str  # ISO timestamp

# =============================================================================
# 2. Mapeamentos e Configurações
# =============================================================================

# Mapeamento de features internas para rótulos amigáveis
FEATURE_LABELS = {
    "A": {"name": "Área de Especialização", "icon": "🎯", "description": "Compatibilidade com a área jurídica do caso"},
    "S": {"name": "Similaridade de Casos", "icon": "📋", "description": "Experiência em casos similares"},
    "T": {"name": "Taxa de Sucesso", "icon": "🏆", "description": "Histórico de resultados positivos"},
    "G": {"name": "Proximidade Geográfica", "icon": "📍", "description": "Distância física do advogado"},
    "Q": {"name": "Qualificação Profissional", "icon": "🎓", "description": "Formação acadêmica e experiência"},
    "U": {"name": "Capacidade de Urgência", "icon": "⚡", "description": "Disponibilidade para casos urgentes"},
    "R": {"name": "Avaliações de Clientes", "icon": "⭐", "description": "Feedback e reputação"},
    "C": {"name": "Habilidades Interpessoais", "icon": "🤝", "description": "Soft skills e comunicação"},
    "E": {"name": "Reputação do Escritório", "icon": "🏢", "description": "Prestígio da firma"},
    "P": {"name": "Adequação de Preço", "icon": "💰", "description": "Compatibilidade com orçamento"},
    "M": {"name": "Maturidade Profissional", "icon": "🧠", "description": "Experiência e networking"}
}

# Templates de sugestões por feature
IMPROVEMENT_SUGGESTIONS = {
    "review_score": {
        "title": "Melhore suas avaliações",
        "description": "Entre em contato com seus últimos clientes e peça feedback. Avaliações positivas aumentam significativamente sua visibilidade.",
        "effort": "Baixo",
        "impact": "Alto",
        "timeline": "1-2 semanas"
    },
    "kpi_softskill": {
        "title": "Desenvolva suas soft skills",
        "description": "Invista em comunicação clara e empática com clientes. Considere cursos de atendimento ao cliente ou comunicação jurídica.",
        "effort": "Médio",
        "impact": "Alto",
        "timeline": "1-3 meses"
    },
    "cv_score": {
        "title": "Complete seu perfil",
        "description": "Adicione mais informações ao seu currículo: especializações, publicações, casos de destaque e certificações.",
        "effort": "Baixo",
        "impact": "Médio",
        "timeline": "1 semana"
    },
    "tempo_resposta_h": {
        "title": "Melhore seu tempo de resposta",
        "description": "Responda mais rapidamente aos clientes. Configure notificações e estabeleça horários específicos para check-in.",
        "effort": "Baixo",
        "impact": "Alto",
        "timeline": "Imediato"
    },
    "success_rate": {
        "title": "Documente seus sucessos",
        "description": "Registre e comprove seus resultados positivos. Mantenha um histórico detalhado de casos bem-sucedidos.",
        "effort": "Médio",
        "impact": "Alto",
        "timeline": "2-4 semanas"
    }
}

# =============================================================================
# 3. Funções Principais de Explicabilidade
# =============================================================================

def extract_top_factors(delta: Dict[str, float], limit: int = 2) -> List[Tuple[str, float]]:
    """
    Extrai os principais fatores que contribuíram para o ranking.
    
    Args:
        delta: Dicionário com contribuições ponderadas de cada feature
        limit: Número máximo de fatores a retornar
        
    Returns:
        Lista de tuplas (feature_key, contribution) ordenada por impacto
    """
    if not delta:
        return []
    
    # Ordenar por contribuição absoluta (maior impacto, positivo ou negativo)
    sorted_factors = sorted(
        delta.items(), 
        key=lambda x: abs(x[1]), 
        reverse=True
    )
    
    return sorted_factors[:limit]

def generate_factor_labels(top_factors: List[Tuple[str, float]]) -> List[str]:
    """
    Converte features técnicas em rótulos amigáveis com ícones.
    
    Args:
        top_factors: Lista de (feature_key, contribution)
        
    Returns:
        Lista de rótulos formatados para exibição
    """
    labels = []
    
    for feature_key, contribution in top_factors:
        feature_info = FEATURE_LABELS.get(feature_key)
        if not feature_info:
            continue
            
        icon = feature_info["icon"]
        name = feature_info["name"]
        
        # Determinar qualificador baseado na contribuição
        if contribution > 0.1:  # Contribuição alta positiva
            qualifier = "Excelente"
        elif contribution > 0.05:  # Contribuição média positiva
            qualifier = "Boa"
        elif contribution > 0:  # Contribuição baixa positiva
            qualifier = "Adequada"
        else:  # Contribuição negativa (raro, mas possível)
            qualifier = "Limitada"
            
        label = f"{icon} {qualifier} {name}"
        labels.append(label)
    
    return labels

def generate_summary(top_factors_labels: List[str]) -> str:
    """
    Gera um resumo em linguagem natural dos principais fatores.
    
    Args:
        top_factors_labels: Lista de rótulos dos principais fatores
        
    Returns:
        Frase resumindo os motivos da seleção
    """
    if not top_factors_labels:
        return "Selecionado com base no perfil geral do profissional."
    
    if len(top_factors_labels) == 1:
        return f"Selecionado principalmente por: {top_factors_labels[0].lower()}."
    
    # Múltiplos fatores
    factors_text = ", ".join(top_factors_labels[:-1]) + f" e {top_factors_labels[-1]}"
    return f"Selecionado por: {factors_text.lower()}."

def calculate_confidence_level(ltr_score: float, equity_score: float) -> str:
    """
    Calcula o nível de confiança da recomendação.
    
    Args:
        ltr_score: Score bruto do algoritmo LTR
        equity_score: Score ajustado por equidade
        
    Returns:
        Nível de confiança: "Alta", "Média", "Baixa"
    """
    # Score final considerando ambos os componentes
    final_score = (ltr_score + equity_score) / 2
    
    if final_score >= 0.8:
        return "Alta"
    elif final_score >= 0.6:
        return "Média"
    else:
        return "Baixa"

def generate_public_explanation(
    scores: Dict[str, Any], 
    case_context: Optional[Dict[str, Any]] = None
) -> PublicExplanation:
    """
    Função principal para gerar explicação pública de um match.
    
    Args:
        scores: Dicionário completo de scores do algoritmo
        case_context: Contexto adicional do caso (opcional)
        
    Returns:
        Explicação estruturada para exibição ao cliente
    """
    # Extrair dados necessários do scores
    delta = scores.get("delta", {})
    features = scores.get("features", {})
    ltr_score = scores.get("ltr", 0.0)
    equity_score = scores.get("equity_raw", 0.0)
    
    # Extrair metadados do contexto
    lawyer_id = case_context.get("lawyer_id", "") if case_context else ""
    case_id = case_context.get("case_id", "") if case_context else ""
    ranking_position = case_context.get("ranking_position", 0) if case_context else 0
    
    # Processar fatores principais
    top_factors_raw = extract_top_factors(delta, limit=2)
    top_factors_labels = generate_factor_labels(top_factors_raw)
    
    # Gerar resumo e nível de confiança
    summary = generate_summary(top_factors_labels)
    confidence = calculate_confidence_level(ltr_score, equity_score)
    
    return PublicExplanation(
        lawyer_id=lawyer_id,
        case_id=case_id,
        ranking_position=ranking_position,
        top_factors=top_factors_labels,
        summary=summary,
        confidence_level=confidence
    )

# =============================================================================
# 4. Funções para Insights de Performance (Prestadores)
# =============================================================================

def identify_weak_points(
    lawyer_kpis: Dict[str, float], 
    benchmarks: Dict[str, Dict[str, float]]
) -> List[WeakPoint]:
    """
    Identifica os 3 pontos mais fracos na performance do advogado.
    
    Args:
        lawyer_kpis: KPIs atuais do advogado
        benchmarks: Benchmarks de mercado por feature
        
    Returns:
        Lista de pontos fracos ordenados por prioridade
    """
    weak_points = []
    
    # Features principais para análise
    key_features = {
        "review_score": "Avaliações",
        "kpi_softskill": "Habilidades Interpessoais", 
        "cv_score": "Completude do Perfil",
        "tempo_resposta_h": "Tempo de Resposta",
        "success_rate": "Taxa de Sucesso"
    }
    
    for feature_key, feature_name in key_features.items():
        current_value = lawyer_kpis.get(feature_key, 0.0)
        benchmark = benchmarks.get(feature_key, {})
        percentile_50 = benchmark.get("percentile_50", 0.5)
        
        # Considerar ponto fraco se estiver abaixo da mediana
        if current_value < percentile_50:
            # Calcular prioridade baseada na distância da mediana
            gap = percentile_50 - current_value
            if gap > 0.3:
                priority = "Alta"
                status = "Precisa Melhorar"
            elif gap > 0.15:
                priority = "Média"
                status = "Pode Melhorar"
            else:
                priority = "Baixa"
                status = "Levemente Abaixo"
            
            suggestion_template = IMPROVEMENT_SUGGESTIONS.get(feature_key, {})
            suggestion = suggestion_template.get("description", "Considere melhorar este aspecto.")
            
            weak_point = WeakPoint(
                feature=feature_key,
                feature_name=feature_name,
                current_value=current_value,
                status=status,
                suggestion=suggestion,
                priority=priority
            )
            weak_points.append(weak_point)
    
    # Ordenar por prioridade (Alta > Média > Baixa) e retornar top 3
    priority_order = {"Alta": 3, "Média": 2, "Baixa": 1}
    weak_points.sort(key=lambda x: priority_order.get(x.priority, 0), reverse=True)
    
    return weak_points[:3]

def generate_benchmarks(
    lawyer_kpis: Dict[str, float],
    market_data: Dict[str, Dict[str, float]]
) -> Dict[str, Benchmark]:
    """
    Gera benchmarks anônimos para comparação.
    
    Args:
        lawyer_kpis: KPIs do advogado
        market_data: Dados agregados do mercado
        
    Returns:
        Dicionário de benchmarks por feature
    """
    benchmarks = {}
    
    feature_mapping = {
        "review_score": "Avaliações",
        "kpi_softskill": "Habilidades Interpessoais",
        "cv_score": "Completude do Perfil",
        "success_rate": "Taxa de Sucesso"
    }
    
    for feature_key, feature_name in feature_mapping.items():
        your_score = lawyer_kpis.get(feature_key, 0.0)
        market_stats = market_data.get(feature_key, {})
        
        p50 = market_stats.get("percentile_50", 0.5)
        p75 = market_stats.get("percentile_75", 0.7)
        p90 = market_stats.get("percentile_90", 0.9)
        
        # Determinar posição no mercado
        if your_score >= p75:
            position = "Acima da Média"
        elif your_score >= p50:
            position = "Médio"
        else:
            position = "Abaixo da Média"
        
        benchmark = Benchmark(
            feature_name=feature_name,
            your_score=your_score,
            percentile_50=p50,
            percentile_75=p75,
            percentile_90=p90,
            market_position=position
        )
        benchmarks[feature_key] = benchmark
    
    return benchmarks

def calculate_overall_score(lawyer_kpis: Dict[str, float]) -> Tuple[int, str]:
    """
    Calcula nota global do perfil (0-100) e classificação.
    
    Args:
        lawyer_kpis: KPIs do advogado
        
    Returns:
        Tupla (score_0_100, grade_text)
    """
    # Pesos para cálculo da nota global
    weights = {
        "review_score": 0.25,
        "success_rate": 0.25,
        "kpi_softskill": 0.20,
        "cv_score": 0.15,
        "tempo_resposta_h": 0.15  # Invertido: menor tempo = melhor score
    }
    
    weighted_sum = 0.0
    total_weight = 0.0
    
    for feature, weight in weights.items():
        value = lawyer_kpis.get(feature, 0.0)
        
        # Normalizar tempo de resposta (inverter: menos tempo = melhor)
        if feature == "tempo_resposta_h":
            # Assumir que 24h ou menos = 1.0, 48h = 0.5, 72h+ = 0.0
            value = max(0.0, 1.0 - (value - 24) / 48) if value > 24 else 1.0
        
        weighted_sum += value * weight
        total_weight += weight
    
    # Calcular score final (0-100)
    final_score = int((weighted_sum / total_weight) * 100) if total_weight > 0 else 0
    
    # Determinar classificação
    if final_score >= 85:
        grade = "Excelente"
    elif final_score >= 70:
        grade = "Bom"
    elif final_score >= 55:
        grade = "Regular"
    else:
        grade = "Pode Melhorar"
    
    return final_score, grade

def generate_improvement_suggestions(weak_points: List[WeakPoint]) -> List[Suggestion]:
    """
    Gera sugestões práticas baseadas nos pontos fracos identificados.
    
    Args:
        weak_points: Lista de pontos fracos
        
    Returns:
        Lista de sugestões ordenadas por impacto
    """
    suggestions = []
    
    for weak_point in weak_points:
        template = IMPROVEMENT_SUGGESTIONS.get(weak_point.feature, {})
        
        if template:
            suggestion = Suggestion(
                title=template["title"],
                description=template["description"],
                effort=template["effort"],
                impact=template["impact"],
                timeline=template["timeline"]
            )
            suggestions.append(suggestion)
    
    # Ordenar por impacto (Alto > Médio > Baixo)
    impact_order = {"Alto": 3, "Médio": 2, "Baixo": 1}
    suggestions.sort(key=lambda x: impact_order.get(x.impact, 0), reverse=True)
    
    return suggestions

# =============================================================================
# 5. Utilitários e Helpers
# =============================================================================

def generate_explanation_hash(explanation: PublicExplanation) -> str:
    """
    Gera hash único da explicação para auditoria e cache.
    
    Args:
        explanation: Objeto de explicação
        
    Returns:
        Hash SHA256 da explicação
    """
    explanation_dict = explanation.model_dump()
    explanation_str = json.dumps(explanation_dict, sort_keys=True)
    return hashlib.sha256(explanation_str.encode()).hexdigest()

def validate_scores_structure(scores: Dict[str, Any]) -> bool:
    """
    Valida se a estrutura de scores está completa.
    
    Args:
        scores: Dicionário de scores do algoritmo
        
    Returns:
        True se válido, False caso contrário
    """
    required_keys = ["features", "delta", "ltr"]
    return all(key in scores for key in required_keys)

def log_explanation_access(
    user_id: str, 
    explanation: PublicExplanation, 
    access_type: str = "view"
) -> None:
    """
    Registra acesso a explicações para auditoria.
    
    Args:
        user_id: ID do usuário que acessou
        explanation: Explicação acessada
        access_type: Tipo de acesso ("view", "expand", "download")
    """
    log_data = {
        "user_id": user_id,
        "case_id": explanation.case_id,
        "lawyer_id": explanation.lawyer_id,
        "access_type": access_type,
        "explanation_version": explanation.version,
        "explanation_hash": generate_explanation_hash(explanation)
    }
    
    logger.info("Explanation accessed", extra=log_data)

# =============================================================================
# 6. Funções de Mock para Desenvolvimento/Testes
# =============================================================================

def get_mock_market_data() -> Dict[str, Dict[str, float]]:
    """
    Dados de mercado simulados para desenvolvimento.
    Em produção, estes dados virão de queries agregadas no banco.
    """
    return {
        "review_score": {
            "percentile_50": 4.2,
            "percentile_75": 4.6,
            "percentile_90": 4.9
        },
        "kpi_softskill": {
            "percentile_50": 0.65,
            "percentile_75": 0.80,
            "percentile_90": 0.92
        },
        "cv_score": {
            "percentile_50": 0.70,
            "percentile_75": 0.85,
            "percentile_90": 0.95
        },
        "success_rate": {
            "percentile_50": 0.75,
            "percentile_75": 0.85,
            "percentile_90": 0.95
        },
        "tempo_resposta_h": {
            "percentile_50": 18.0,
            "percentile_75": 12.0,
            "percentile_90": 6.0
        }
    }

def get_mock_lawyer_kpis() -> Dict[str, float]:
    """
    KPIs simulados de um advogado para desenvolvimento.
    """
    return {
        "review_score": 4.1,
        "kpi_softskill": 0.58,
        "cv_score": 0.75,
        "success_rate": 0.82,
        "tempo_resposta_h": 24.0
    }

# =============================================================================
# 7. Exemplo de Uso
# =============================================================================

if __name__ == "__main__":
    # Exemplo de uso das funções principais
    
    # Mock de scores do algoritmo
    mock_scores = {
        "features": {"A": 0.9, "S": 0.8, "T": 0.75, "G": 0.6, "Q": 0.85, "U": 0.7, "R": 0.8, "C": 0.65},
        "delta": {"A": 0.18, "S": 0.12, "T": 0.15, "G": -0.05, "Q": 0.10, "U": 0.08, "R": 0.06, "C": 0.03},
        "ltr": 0.74,
        "equity_raw": 0.95,
        "fair_base": 0.82
    }
    
    mock_context = {
        "lawyer_id": "ADV123",
        "case_id": "CASE456",
        "ranking_position": 1
    }
    
    # Gerar explicação pública
    explanation = generate_public_explanation(mock_scores, mock_context)
    print("=== Explicação Pública ===")
    print(f"Fatores: {explanation.top_factors}")
    print(f"Resumo: {explanation.summary}")
    print(f"Confiança: {explanation.confidence_level}")
    
    # Exemplo de insights para prestador
    lawyer_kpis = get_mock_lawyer_kpis()
    market_data = get_mock_market_data()
    
    overall_score, grade = calculate_overall_score(lawyer_kpis)
    benchmarks = generate_benchmarks(lawyer_kpis, market_data)
    weak_points = identify_weak_points(lawyer_kpis, market_data)
    suggestions = generate_improvement_suggestions(weak_points)
    
    print(f"\n=== Insights de Performance ===")
    print(f"Nota Global: {overall_score}/100 ({grade})")
    print(f"Pontos Fracos: {len(weak_points)}")
    for wp in weak_points:
        print(f"  - {wp.feature_name}: {wp.status}")
    print(f"Sugestões: {len(suggestions)}")
    for sug in suggestions:
        print(f"  - {sug.title} (Impacto: {sug.impact})") 