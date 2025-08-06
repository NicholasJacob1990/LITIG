#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
services/economy_calculator_service.py

Serviço para calcular economia em tempo real baseado nos preços oficiais da API Escavador.
Fornece métricas precisas de ROI e economia de custos.
"""

from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
from decimal import Decimal, ROUND_HALF_UP
import logging

logger = logging.getLogger(__name__)

# ============================================================================
# PREÇOS OFICIAIS DA API ESCAVADOR (2025)
# ============================================================================

ESCAVADOR_PRICES = {
    # Atualização das informações dos processos
    "ai_summary_update": Decimal("0.08"),        # Atualizar resumo por IA
    "process_update": Decimal("0.10"),           # Atualização do processo
    "process_update_with_docs": Decimal("0.20"), # Atualização + docs públicos
    
    # Consulta de processos de envolvidos
    "processes_by_oab": Decimal("4.50"),         # Até 200 itens + R$ 0,05/200
    "processes_by_person": Decimal("4.50"),      # Até 200 itens + R$ 0,05/200
    "lawyer_summary_by_oab": Decimal("0.40"),    # Resumo advogado por OAB
    "person_summary": Decimal("0.40"),           # Resumo do envolvido
    
    # Consulta de processos por CNJ
    "process_cover": Decimal("0.05"),            # Capa do processo
    "public_documents": Decimal("0.06"),         # Documentos públicos
    "process_parties": Decimal("0.05"),          # Envolvidos do processo
    "process_movements": Decimal("0.05"),        # Movimentações do processo
    "ai_process_summary": Decimal("0.05"),       # Resumo processo por IA
    
    # Monitoramentos (preços mensais)
    "daily_monitoring": Decimal("1.76"),         # Monitoramento diário
    "weekly_monitoring": Decimal("0.32"),        # Monitoramento semanal
    "monthly_monitoring": Decimal("0.08"),       # Monitoramento mensal
    "new_processes_monitoring": Decimal("2.20"), # Novos processos (até 200)
    
    # Custos adicionais
    "extra_200_items": Decimal("0.05"),          # A cada 200 itens extras
}

# ============================================================================
# PADRÕES DE USO POR TAMANHO DE ESCRITÓRIO
# ============================================================================

USAGE_PATTERNS = {
    "small": {  # 500 processos ativos
        "processes": 500,
        "monthly_usage": {
            "process_movements": 2000,        # 4 consultas/processo/mês
            "ai_process_summary": 1000,       # 2 consultas/processo/mês
            "process_update": 500,            # 1 atualização/processo/mês
            "process_cover": 100,             # 100 novos processos
            "process_parties": 100,           # 100 novos processos
            "public_documents": 50,           # Casos específicos
            "lawyer_summary_by_oab": 20,      # Match de advogados
            "processes_by_oab": 5,            # Análises completas
            "weekly_monitoring": 100,         # Processos importantes
            "monthly_monitoring": 50,         # Processos normais
        }
    },
    "medium": {  # 2.000 processos ativos
        "processes": 2000,
        "monthly_usage": {
            "process_movements": 12000,       # 6 consultas/processo/mês
            "ai_process_summary": 6000,       # 3 consultas/processo/mês
            "process_update": 4000,           # 2 atualizações/processo/mês
            "process_cover": 300,             # 300 novos processos
            "process_parties": 300,           # 300 novos processos
            "public_documents": 200,          # Mais análises documentais
            "lawyer_summary_by_oab": 80,      # Mais matches
            "processes_by_oab": 20,           # Mais análises
            "weekly_monitoring": 500,         # Processos importantes
            "monthly_monitoring": 1500,       # Processos normais
        }
    },
    "large": {  # 10.000 processos ativos
        "processes": 10000,
        "monthly_usage": {
            "process_movements": 80000,       # 8 consultas/processo/mês
            "ai_process_summary": 40000,      # 4 consultas/processo/mês
            "process_update": 30000,          # 3 atualizações/processo/mês
            "process_update_with_docs": 1000, # Casos com documentos
            "process_cover": 800,             # 800 novos processos
            "process_parties": 800,           # 800 novos processos
            "public_documents": 1000,         # Muitas análises
            "lawyer_summary_by_oab": 200,     # Muitos matches
            "processes_by_oab": 50,           # Análises complexas
            "processes_by_person": 30,        # Análises de envolvidos
            "weekly_monitoring": 2000,        # Muitos processos importantes
            "monthly_monitoring": 8000,       # Processos normais
        }
    }
}

# ============================================================================
# TAXAS DE ECONOMIA POR FUNÇÃO
# ============================================================================

ECONOMY_RATES = {
    # Consultas frequentes - alta taxa de cache hit
    "process_movements": 0.97,           # 97% economia (dados raramente mudam)
    "ai_process_summary": 0.96,          # 96% economia (resumos estáveis)
    "process_cover": 0.95,               # 95% economia (dados básicos estáveis)
    "process_parties": 0.95,             # 95% economia (envolvidos estáveis)
    
    # Atualizações - cache predictivo
    "process_update": 0.96,              # 96% economia (sync inteligente)
    "process_update_with_docs": 0.95,    # 95% economia (documentos mudam mais)
    
    # Consultas ocasionais - cache de médio prazo
    "public_documents": 0.90,            # 90% economia (documentos mudam)
    "lawyer_summary_by_oab": 0.92,       # 92% economia (perfis estáveis)
    "person_summary": 0.92,              # 92% economia (perfis estáveis)
    
    # Consultas caras - cache agressivo
    "processes_by_oab": 0.98,            # 98% economia (listas grandes, cache longo)
    "processes_by_person": 0.98,         # 98% economia (listas grandes, cache longo)
    
    # Monitoramento - substituído por cache inteligente
    "weekly_monitoring": 0.95,           # 95% economia (sync automático)
    "monthly_monitoring": 0.98,          # 98% economia (sync muito espaçado)
}

class EconomyCalculatorService:
    """
    Serviço para calcular economia de API em tempo real.
    """
    
    def __init__(self):
        self.prices = ESCAVADOR_PRICES
        self.usage_patterns = USAGE_PATTERNS
        self.economy_rates = ECONOMY_RATES
    
    def calculate_monthly_cost_without_cache(self, office_size: str) -> Dict[str, Any]:
        """Calcula custo mensal sem cache para um tamanho de escritório."""
        if office_size not in self.usage_patterns:
            raise ValueError(f"Tamanho de escritório inválido: {office_size}")
        
        pattern = self.usage_patterns[office_size]
        usage = pattern["monthly_usage"]
        costs = {}
        total_cost = Decimal("0")
        
        for function, quantity in usage.items():
            if function in self.prices:
                unit_cost = self.prices[function]
                function_cost = unit_cost * Decimal(str(quantity))
                costs[function] = {
                    "quantity": quantity,
                    "unit_cost": float(unit_cost),
                    "total_cost": float(function_cost),
                }
                total_cost += function_cost
        
        return {
            "office_size": office_size,
            "processes": pattern["processes"],
            "monthly_total": float(total_cost),
            "annual_total": float(total_cost * 12),
            "costs_by_function": costs,
            "most_expensive_functions": self._get_top_expensive_functions(costs, 5)
        }
    
    def calculate_monthly_cost_with_cache(self, office_size: str) -> Dict[str, Any]:
        """Calcula custo mensal com cache inteligente."""
        without_cache = self.calculate_monthly_cost_without_cache(office_size)
        
        costs_with_cache = {}
        total_cost_with_cache = Decimal("0")
        total_economy = Decimal("0")
        
        for function, cost_data in without_cache["costs_by_function"].items():
            original_cost = Decimal(str(cost_data["total_cost"]))
            economy_rate = self.economy_rates.get(function, 0.90)  # Default 90%
            
            cost_with_cache = original_cost * (Decimal("1") - Decimal(str(economy_rate)))
            economy_amount = original_cost - cost_with_cache
            
            costs_with_cache[function] = {
                "quantity": cost_data["quantity"],
                "unit_cost": cost_data["unit_cost"],
                "original_cost": float(original_cost),
                "cost_with_cache": float(cost_with_cache),
                "economy_amount": float(economy_amount),
                "economy_rate": economy_rate * 100,
            }
            
            total_cost_with_cache += cost_with_cache
            total_economy += economy_amount
        
        economy_percentage = (total_economy / Decimal(str(without_cache["monthly_total"]))) * 100
        
        return {
            "office_size": office_size,
            "processes": without_cache["processes"],
            "monthly_total_without_cache": without_cache["monthly_total"],
            "monthly_total_with_cache": float(total_cost_with_cache),
            "monthly_economy": float(total_economy),
            "economy_percentage": float(economy_percentage),
            "annual_economy": float(total_economy * 12),
            "costs_by_function": costs_with_cache,
            "biggest_savings": self._get_top_savings(costs_with_cache, 5)
        }
    
    def calculate_5_year_projection(self, office_size: str) -> Dict[str, Any]:
        """Calcula projeção de economia para 5 anos."""
        monthly_data = self.calculate_monthly_cost_with_cache(office_size)
        
        # Projeção com melhoria progressiva da economia
        yearly_projections = []
        base_economy = Decimal(str(monthly_data["monthly_economy"]))
        
        for year in range(1, 6):
            # Melhoria progressiva: +0.5% ao ano
            improvement_factor = Decimal("1") + (Decimal(str(year - 1)) * Decimal("0.005"))
            yearly_economy = base_economy * 12 * improvement_factor
            
            yearly_projections.append({
                "year": year,
                "monthly_economy": float(base_economy * improvement_factor),
                "yearly_economy": float(yearly_economy),
                "economy_percentage": float(monthly_data["economy_percentage"] + (year - 1) * 0.5),
                "accumulated_economy": float(sum(
                    base_economy * 12 * (Decimal("1") + (Decimal(str(y - 1)) * Decimal("0.005")))
                    for y in range(1, year + 1)
                ))
            })
        
        total_5_year_economy = yearly_projections[-1]["accumulated_economy"]
        investment_cost = 1000  # Custo estimado de implementação
        roi = ((total_5_year_economy - investment_cost) / investment_cost) * 100
        
        return {
            "office_size": office_size,
            "yearly_projections": yearly_projections,
            "total_5_year_economy": total_5_year_economy,
            "investment_cost": investment_cost,
            "roi_percentage": roi,
            "payback_period_days": int((investment_cost / monthly_data["monthly_economy"]) * 30),
        }
    
    def calculate_real_time_metrics(self, 
                                   api_calls_today: int,
                                   cache_hits_today: int,
                                   estimated_daily_limit: int = 100) -> Dict[str, Any]:
        """Calcula métricas em tempo real."""
        total_requests = api_calls_today + cache_hits_today
        cache_hit_rate = (cache_hits_today / total_requests * 100) if total_requests > 0 else 0
        
        # Estimativa de economia diária baseada em calls evitadas
        avg_cost_per_call = Decimal("0.07")  # Média ponderada dos preços
        calls_saved = cache_hits_today
        daily_savings = calls_saved * avg_cost_per_call
        
        # Projeção mensal
        monthly_savings = daily_savings * 30
        
        # Status do limite diário
        usage_percentage = (api_calls_today / estimated_daily_limit * 100) if estimated_daily_limit > 0 else 0
        
        return {
            "today": {
                "total_requests": total_requests,
                "api_calls": api_calls_today,
                "cache_hits": cache_hits_today,
                "cache_hit_rate": round(cache_hit_rate, 2),
                "calls_saved": calls_saved,
                "estimated_savings": float(daily_savings),
                "usage_percentage": round(usage_percentage, 2),
                "remaining_api_calls": max(0, estimated_daily_limit - api_calls_today)
            },
            "projections": {
                "monthly_savings": float(monthly_savings),
                "annual_savings": float(monthly_savings * 12),
                "calls_saved_monthly": calls_saved * 30,
                "calls_saved_annually": calls_saved * 365
            },
            "status": {
                "efficiency": "excellent" if cache_hit_rate >= 95 else 
                             "good" if cache_hit_rate >= 90 else
                             "needs_improvement" if cache_hit_rate >= 80 else "poor",
                "api_usage": "optimal" if usage_percentage <= 50 else
                            "moderate" if usage_percentage <= 80 else "high",
                "recommendation": self._get_optimization_recommendation(cache_hit_rate, usage_percentage)
            }
        }
    
    def compare_scenarios(self) -> Dict[str, Any]:
        """Compara todos os cenários de escritório."""
        scenarios = {}
        
        for size in ["small", "medium", "large"]:
            scenarios[size] = {
                "without_cache": self.calculate_monthly_cost_without_cache(size),
                "with_cache": self.calculate_monthly_cost_with_cache(size),
                "projection_5_years": self.calculate_5_year_projection(size)
            }
        
        # Resumo comparativo
        summary = {
            "total_market_potential": {
                "small_offices": scenarios["small"]["projection_5_years"]["total_5_year_economy"],
                "medium_offices": scenarios["medium"]["projection_5_years"]["total_5_year_economy"],
                "large_offices": scenarios["large"]["projection_5_years"]["total_5_year_economy"],
            },
            "average_economy_rate": sum(
                scenarios[size]["with_cache"]["economy_percentage"] for size in scenarios
            ) / len(scenarios),
            "best_roi": max(
                scenarios[size]["projection_5_years"]["roi_percentage"] for size in scenarios
            )
        }
        
        return {
            "scenarios": scenarios,
            "summary": summary,
            "generated_at": datetime.now().isoformat()
        }
    
    def _get_top_expensive_functions(self, costs: Dict, limit: int) -> List[Dict]:
        """Retorna as funções mais caras."""
        sorted_costs = sorted(
            costs.items(),
            key=lambda x: x[1]["total_cost"],
            reverse=True
        )
        
        return [
            {
                "function": func,
                "cost": data["total_cost"],
                "percentage": (data["total_cost"] / sum(c["total_cost"] for c in costs.values())) * 100
            }
            for func, data in sorted_costs[:limit]
        ]
    
    def _get_top_savings(self, costs: Dict, limit: int) -> List[Dict]:
        """Retorna as maiores economias."""
        sorted_savings = sorted(
            costs.items(),
            key=lambda x: x[1]["economy_amount"],
            reverse=True
        )
        
        return [
            {
                "function": func,
                "economy_amount": data["economy_amount"],
                "economy_rate": data["economy_rate"],
                "original_cost": data["original_cost"]
            }
            for func, data in sorted_savings[:limit]
        ]
    
    def _get_optimization_recommendation(self, cache_hit_rate: float, usage_percentage: float) -> str:
        """Gera recomendação de otimização."""
        if cache_hit_rate < 90:
            return "Aumentar TTL para funções com baixo hit rate"
        elif usage_percentage > 80:
            return "Implementar batch processing para reduzir calls"
        elif cache_hit_rate >= 95 and usage_percentage <= 50:
            return "Sistema otimizado - manter configurações atuais"
        else:
            return "Considerar ajuste fino nos TTLs por fase processual"

# ============================================================================
# INSTÂNCIA GLOBAL DO SERVIÇO
# ============================================================================

economy_calculator = EconomyCalculatorService()

# ============================================================================
# FUNÇÕES DE CONVENIÊNCIA
# ============================================================================

def get_economy_summary(office_size: str = "medium") -> Dict[str, Any]:
    """Retorna resumo rápido de economia."""
    return economy_calculator.calculate_monthly_cost_with_cache(office_size)

def get_5_year_roi(office_size: str = "medium") -> Dict[str, Any]:
    """Retorna ROI de 5 anos."""
    return economy_calculator.calculate_5_year_projection(office_size)

def get_real_time_dashboard(api_calls: int, cache_hits: int) -> Dict[str, Any]:
    """Retorna dashboard em tempo real."""
    return economy_calculator.calculate_real_time_metrics(api_calls, cache_hits) 