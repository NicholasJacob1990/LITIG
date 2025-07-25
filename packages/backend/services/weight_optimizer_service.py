#!/usr/bin/env python3
"""
Serviço para carregar e aplicar pesos otimizados no algoritmo de matching.
"""

import json
import os
from pathlib import Path
from typing import Dict, Optional
import logging

logger = logging.getLogger(__name__)

class WeightOptimizerService:
    """Serviço para gerenciar pesos otimizados do algoritmo de matching."""
    
    def __init__(self, weights_path: str = "packages/backend/config/optimized_weights.json"):
        self.weights_path = weights_path
        self._optimized_weights: Optional[Dict[str, float]] = None
        self._default_weights = {
            "WEIGHT_S_QUALIS": 0.15,
            "WEIGHT_T_TITULACAO": 0.10,
            "WEIGHT_E_EXPERIENCIA": 0.20,
            "WEIGHT_M_MULTIDISCIPLINAR": 0.10,
            "WEIGHT_C_COMPLEXIDADE": 0.15,
            "WEIGHT_P_HONORARIOS": 0.10,
            "WEIGHT_R_REPUTACAO": 0.15,
            "WEIGHT_Q_QUALIFICACAO": 0.05,
            "WEIGHT_SIMILARITY_SCORE": 0.10
        }
    
    def load_optimized_weights(self) -> Dict[str, float]:
        """
        Carrega os pesos otimizados do arquivo JSON.
        Se não encontrar, retorna pesos padrão.
        """
        try:
            if Path(self.weights_path).exists():
                with open(self.weights_path, 'r', encoding='utf-8') as f:
                    self._optimized_weights = json.load(f)
                    logger.info(f"✅ Pesos otimizados carregados de: {self.weights_path}")
                    return self._optimized_weights
            else:
                logger.warning(f"⚠️  Arquivo de pesos não encontrado: {self.weights_path}")
                logger.info("📝 Usando pesos padrão")
                return self._default_weights
                
        except Exception as e:
            logger.error(f"❌ Erro ao carregar pesos otimizados: {e}")
            logger.info("📝 Usando pesos padrão como fallback")
            return self._default_weights
    
    def get_weights(self) -> Dict[str, float]:
        """Retorna os pesos atualmente carregados."""
        if self._optimized_weights is None:
            return self.load_optimized_weights()
        return self._optimized_weights
    
    def update_weights(self, new_weights: Dict[str, float]) -> bool:
        """
        Atualiza os pesos otimizados e salva no arquivo.
        """
        try:
            # Validar que os pesos somam aproximadamente 1.0
            total_weight = sum(new_weights.values())
            if abs(total_weight - 1.0) > 0.01:
                logger.warning(f"⚠️  Soma dos pesos ({total_weight:.4f}) difere de 1.0")
            
            # Salvar no arquivo
            os.makedirs(os.path.dirname(self.weights_path), exist_ok=True)
            with open(self.weights_path, 'w', encoding='utf-8') as f:
                json.dump(new_weights, f, indent=2, ensure_ascii=False)
            
            # Atualizar cache
            self._optimized_weights = new_weights
            
            logger.info(f"✅ Pesos atualizados e salvos em: {self.weights_path}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Erro ao atualizar pesos: {e}")
            return False
    
    def get_feature_importance_summary(self) -> str:
        """Retorna um resumo das importâncias das features."""
        weights = self.get_weights()
        
        # Ordenar por importância
        sorted_weights = sorted(weights.items(), key=lambda x: x[1], reverse=True)
        
        summary = "📊 RESUMO DAS IMPORTÂNCIAS DAS FEATURES:\n"
        summary += "=" * 50 + "\n"
        
        for i, (feature, weight) in enumerate(sorted_weights, 1):
            feature_name = feature.replace('WEIGHT_', '').replace('_', ' ').title()
            bar_length = int(weight * 50)  # Barra visual proporcional
            bar = "█" * bar_length + "░" * (50 - bar_length)
            summary += f"{i:2d}. {feature_name:<20} │{bar}│ {weight:.4f}\n"
        
        return summary
    
    def compare_with_defaults(self) -> str:
        """Compara os pesos otimizados com os padrão."""
        current_weights = self.get_weights()
        
        comparison = "📈 COMPARAÇÃO: OTIMIZADO vs PADRÃO:\n"
        comparison += "=" * 60 + "\n"
        comparison += f"{'Feature':<20} │ {'Otimizado':<10} │ {'Padrão':<10} │ {'Diferença':<10}\n"
        comparison += "-" * 60 + "\n"
        
        for feature in self._default_weights.keys():
            optimized = current_weights.get(feature, 0)
            default = self._default_weights[feature]
            diff = optimized - default
            
            feature_name = feature.replace('WEIGHT_', '').replace('_', ' ')[:18]
            diff_sign = "+" if diff > 0 else ""
            
            comparison += f"{feature_name:<20} │ {optimized:.4f}    │ {default:.4f}    │ {diff_sign}{diff:.4f}\n"
        
        return comparison
    
    def reset_to_defaults(self) -> bool:
        """Reseta os pesos para os valores padrão."""
        return self.update_weights(self._default_weights.copy())


# Instância global do serviço
weight_optimizer = WeightOptimizerService()


def get_optimized_weights() -> Dict[str, float]:
    """Função de conveniência para obter os pesos otimizados."""
    return weight_optimizer.get_weights()


def update_optimized_weights(new_weights: Dict[str, float]) -> bool:
    """Função de conveniência para atualizar os pesos otimizados."""
    return weight_optimizer.update_weights(new_weights) 
 