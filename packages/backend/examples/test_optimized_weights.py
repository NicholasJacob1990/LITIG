#!/usr/bin/env python3
"""
Script de teste para demonstrar o uso do serviço de pesos otimizados.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.weight_optimizer_service import weight_optimizer

def main():
    print("🔬 TESTANDO SERVIÇO DE PESOS OTIMIZADOS")
    print("=" * 60)
    
    # 1. Carregar pesos otimizados
    print("\n1️⃣ Carregando pesos otimizados...")
    weights = weight_optimizer.get_weights()
    print("✅ Pesos carregados com sucesso!")
    
    # 2. Mostrar resumo das importâncias
    print("\n2️⃣ Resumo das importâncias das features:")
    print(weight_optimizer.get_feature_importance_summary())
    
    # 3. Comparação com pesos padrão
    print("\n3️⃣ Comparação com pesos padrão:")
    print(weight_optimizer.compare_with_defaults())
    
    # 4. Análise dos resultados
    print("\n4️⃣ ANÁLISE DOS RESULTADOS:")
    print("=" * 40)
    
    # Encontrar as features mais importantes
    sorted_weights = sorted(weights.items(), key=lambda x: x[1], reverse=True)
    
    print(f"🥇 Feature mais importante: {sorted_weights[0][0]} ({sorted_weights[0][1]:.4f})")
    print(f"🥈 Segunda mais importante: {sorted_weights[1][0]} ({sorted_weights[1][1]:.4f})")
    print(f"🥉 Terceira mais importante: {sorted_weights[2][0]} ({sorted_weights[2][1]:.4f})")
    
    print(f"\n📉 Feature menos importante: {sorted_weights[-1][0]} ({sorted_weights[-1][1]:.4f})")
    
    # Insights baseados nos pesos otimizados
    print("\n💡 INSIGHTS DO PROCESSO AUTOML:")
    print("-" * 40)
    
    if weights.get('WEIGHT_E_EXPERIENCIA', 0) > 0.15:
        print("• EXPERIÊNCIA é um fator crítico para aceitação de ofertas")
    
    if weights.get('WEIGHT_R_REPUTACAO', 0) > 0.15:
        print("• REPUTAÇÃO tem impacto significativo no matching")
    
    if weights.get('WEIGHT_S_QUALIS', 0) > 0.15:
        print("• SISTEMA QUALIS (qualidade acadêmica) é altamente valorizado")
    
    if weights.get('WEIGHT_M_MULTIDISCIPLINAR', 0) < 0.05:
        print("• Multidisciplinaridade tem menor impacto que esperado")
    
    if weights.get('WEIGHT_P_HONORARIOS', 0) < 0.10:
        print("• Preferências de honorários têm peso menor que outros fatores")
    
    # Soma total dos pesos
    total_weight = sum(weights.values())
    print(f"\n📊 Soma total dos pesos: {total_weight:.4f}")
    
    if abs(total_weight - 1.0) < 0.01:
        print("✅ Pesos estão corretamente normalizados")
    else:
        print("⚠️  Pesos podem precisar de normalização")
    
    print("\n✨ Teste concluído com sucesso!")

if __name__ == "__main__":
    main() 
 