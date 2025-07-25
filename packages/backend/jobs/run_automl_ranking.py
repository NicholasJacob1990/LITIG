#!/usr/bin/env python3
# backend/jobs/run_automl_ranking.py
"""
Job de AutoML para otimizar automaticamente os pesos do algoritmo de ranqueamento (LTR - Learning-to-Rank).

Este script usa PyCaret para testar dezenas de modelos de machine learning e encontrar 
automaticamente a melhor combinação de pesos para maximizar a precisão do matching 
entre casos e advogados.

Uso:
    python packages/backend/jobs/run_automl_ranking.py --data_path packages/backend/data/automl_training/matches_history.csv
"""

import os
import sys
import json
import argparse
import pandas as pd
from datetime import datetime
from pathlib import Path

# Adicionar o diretório backend ao path para importar módulos locais
sys.path.append(str(Path(__file__).parent.parent))

def run_automl_ranking(data_path: str, output_path: str = "ltr_weights_automl.json", test_size: float = 0.2):
    """
    Executa AutoML para encontrar os melhores pesos para o algoritmo de ranqueamento.
    
    Args:
        data_path: Caminho para o dataset de treinamento (CSV)
        output_path: Caminho para salvar os novos pesos otimizados
        test_size: Porcentagem dos dados para usar como teste (0.0 a 1.0)
    """
    print("🚀 Iniciando AutoML para otimização do algoritmo de ranqueamento...")
    
    # 1. Carregar e validar dados
    print(f"📊 Carregando dados de: {data_path}")
    
    if not os.path.exists(data_path):
        print(f"❌ ERRO: Arquivo de dados não encontrado: {data_path}")
        print("💡 Certifique-se de que o arquivo existe e contém os dados históricos de matches.")
        return False
    
    try:
        df = pd.read_csv(data_path)
        print(f"✅ Dataset carregado: {len(df)} registros, {len(df.columns)} colunas")
    except Exception as e:
        print(f"❌ ERRO ao carregar dataset: {e}")
        return False
    
    # 2. Validar estrutura do dataset
    required_columns = [
        'case_id', 'lawyer_id', 'feature_S_qualis', 'feature_T_titulacao', 
        'feature_E_experiencia', 'feature_M_multidisciplinar', 'feature_C_complexidade', 
        'feature_P_honorarios', 'feature_R_reputacao', 'feature_Q_qualificacao', 
        'similarity_score', 'offer_accepted'
    ]
    
    missing_columns = [col for col in required_columns if col not in df.columns]
    if missing_columns:
        print(f"❌ ERRO: Colunas obrigatórias ausentes: {missing_columns}")
        print("💡 Verifique o arquivo README.md em data/automl_training/ para o formato correto.")
        return False
    
    print(f"✅ Estrutura do dataset validada")
    
    # 3. Preparar dados para AutoML
    print("🔧 Preparando dados para AutoML...")
    
    # Selecionar apenas as features e o target
    feature_columns = [col for col in df.columns if col.startswith('feature_') or col == 'similarity_score']
    X = df[feature_columns].copy()
    y = df['offer_accepted'].copy()
    
    print(f"✅ Features selecionadas: {feature_columns}")
    print(f"✅ Distribuição do target: {y.value_counts().to_dict()}")
    
    # Verificar se há dados suficientes
    if len(df) < 50:
        print("⚠️  AVISO: Dataset muito pequeno (< 50 registros). Resultados podem não ser confiáveis.")
    
    # 4. Configurar e executar PyCaret AutoML
    print("🤖 Configurando PyCaret AutoML...")
    
    try:
        import pycaret.classification as pc
        
        # Configurar ambiente PyCaret
        # Usamos session_id para reprodutibilidade e silent=True para menos verbose
        clf_setup = pc.setup(
            data=df[feature_columns + ['offer_accepted']], 
            target='offer_accepted',
            session_id=123,
            train_size=0.8 if len(df) >= 50 else 0.9, # Aumentar treino para datasets pequenos
            verbose=False,
            html=False,  # Não gerar HTML
            n_jobs=1  # Usar apenas 1 core para evitar problemas
        )
        
        print("✅ Ambiente PyCaret configurado com sucesso")
        
        # Comparar múltiplos modelos automaticamente
        print("🔍 Comparando múltiplos modelos de ML...")
        print("⏳ Isso pode levar alguns minutos...")
        
        # Ajustar modelos a serem testados com base no tamanho do dataset
        models_to_include = ['lr', 'rf', 'gbc', 'xgboost', 'lightgbm', 'nb', 'svm']
        if len(df) < 50:
            print("ℹ️  Dataset pequeno, usando modelos mais simples: 'lr', 'rf', 'nb'")
            models_to_include = ['lr', 'rf', 'nb']

        # compare_models() testa automaticamente ~15 algoritmos diferentes
        best_models = pc.compare_models(
            include=models_to_include,
            sort='Accuracy',
            n_select=1,  # Pegar apenas o melhor
            verbose=False,
            cross_validation=False  # Desativar CV para datasets pequenos
        )
        
        print("✅ Comparação de modelos concluída")

        # Verificar se algum modelo foi treinado com sucesso
        if not best_models:
            print("❌ ERRO: Nenhum modelo foi treinado com sucesso.")
            print("💡 O dataset pode ser muito pequeno ou ter problemas de qualidade.")
            return False
        
        # Selecionar o melhor modelo
        best_model = best_models
            
        print(f"🏆 Melhor modelo encontrado: {type(best_model).__name__}")
        
        # Finalizar o modelo (treinar no dataset completo)
        print("🎯 Finalizando modelo com dataset completo...")
        final_model = pc.finalize_model(best_model)
        
        # Avaliar o modelo
        print("📊 Avaliando performance do modelo...")
        evaluation = pc.evaluate_model(final_model)
        
        print("✅ Modelo treinado e avaliado com sucesso")
        
    except Exception as e:
        print(f"❌ ERRO durante AutoML: {e}")
        print("💡 Tente reduzir o tamanho do dataset ou verificar a qualidade dos dados.")
        return False
    
    # 5. Extrair importância das features (novos pesos)
    print("⚖️  Extraindo importância das features...")
    
    try:
        # Tentar diferentes métodos para extrair importância
        feature_importance = None
        
        if hasattr(final_model, 'feature_importances_'):
            # Random Forest, XGBoost, LightGBM, etc.
            feature_importance = final_model.feature_importances_
        elif hasattr(final_model, 'coef_'):
            # Regressão Logística, SVM, etc.
            feature_importance = abs(final_model.coef_[0])  # Valor absoluto dos coeficientes
        else:
            print("⚠️  Modelo não fornece importância das features. Usando pesos uniformes.")
            feature_importance = [1.0] * len(feature_columns)
        
        # Criar dicionário de pesos
        feature_weights = {}
        for i, feature in enumerate(feature_columns):
            # Mapear nomes das features para os nomes esperados pelo algoritmo
            if feature == 'feature_S_qualis':
                feature_weights['peso_qualis'] = float(feature_importance[i])
            elif feature == 'feature_T_titulacao':
                feature_weights['peso_titulacao'] = float(feature_importance[i])
            elif feature == 'feature_E_experiencia':
                feature_weights['peso_experiencia'] = float(feature_importance[i])
            elif feature == 'feature_M_multidisciplinar':
                feature_weights['peso_multidisciplinar'] = float(feature_importance[i])
            elif feature == 'feature_C_complexidade':
                feature_weights['peso_complexidade'] = float(feature_importance[i])
            elif feature == 'feature_P_honorarios':
                feature_weights['peso_honorarios'] = float(feature_importance[i])
            elif feature == 'feature_R_reputacao':
                feature_weights['peso_reputacao'] = float(feature_importance[i])
            elif feature == 'feature_Q_qualificacao':
                feature_weights['peso_qualificacao'] = float(feature_importance[i])
            elif feature == 'similarity_score':
                feature_weights['peso_similarity'] = float(feature_importance[i])
        
        print("✅ Importância das features extraída com sucesso")
        
    except Exception as e:
        print(f"❌ ERRO ao extrair importância: {e}")
        return False
    
    # 6. Criar arquivo de pesos otimizados
    print("💾 Salvando novos pesos otimizados...")
    
    # Estrutura esperada pelo algoritmo de matching
    ltr_weights = {
        "version": "automl_v1.0",
        "generated_at": datetime.now().isoformat(),
        "model_type": type(final_model).__name__,
        "dataset_size": len(df),
        "test_accuracy": "N/A",  # Seria necessário calcular separadamente
        "weights": feature_weights,
        "metadata": {
            "automl_library": "pycaret",
            "pycaret_version": "3.3.2",
            "features_used": feature_columns,
            "total_features": len(feature_columns)
        }
    }
    
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(ltr_weights, f, indent=2, ensure_ascii=False)
        print(f"✅ Arquivo de pesos salvo em: {output_path}")
    except Exception as e:
        print(f"❌ ERRO ao salvar arquivo: {e}")
        return False
    
    # 7. Resumo dos resultados
    print("\n" + "="*60)
    print("🎉 AUTOML CONCLUÍDO COM SUCESSO!")
    print("="*60)
    print(f"📊 Dataset processado: {len(df)} registros")
    print(f"🏆 Melhor modelo: {type(final_model).__name__}")
    print(f"💾 Pesos salvos em: {output_path}")
    print("\n🔍 NOVOS PESOS OTIMIZADOS:")
    for peso, valor in feature_weights.items():
        print(f"   {peso}: {valor:.4f}")
    print("\n💡 Para aplicar os novos pesos:")
    print(f"   1. Teste os resultados com os novos pesos")
    print(f"   2. Se satisfeito, substitua o arquivo ltr_weights.json principal")
    print(f"   3. O sistema recarregará automaticamente os novos pesos")
    print("="*60)
    
    return True


def main():
    """Função principal do script."""
    parser = argparse.ArgumentParser(
        description='AutoML para otimização do algoritmo de ranqueamento',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos de uso:
  python run_automl_ranking.py --data_path ../data/automl_training/matches_history.csv
  python run_automl_ranking.py --data_path ../data/automl_training/matches_history.csv --output_path custom_weights.json
  python run_automl_ranking.py --data_path ../data/automl_training/matches_history.csv --test_size 0.3
        """
    )
    
    parser.add_argument(
        '--data_path',
        type=str,
        required=True,
        help='Caminho para o arquivo CSV com histórico de matches'
    )
    
    parser.add_argument(
        '--output_path',
        type=str,
        default='ltr_weights_automl.json',
        help='Caminho para salvar os pesos otimizados (padrão: ltr_weights_automl.json)'
    )
    
    parser.add_argument(
        '--test_size',
        type=float,
        default=0.2,
        help='Porcentagem para teste (0.0 a 1.0, padrão: 0.2)'
    )
    
    args = parser.parse_args()
    
    # Validar argumentos
    if not 0.0 <= args.test_size <= 0.9:
        print("❌ ERRO: test_size deve estar entre 0.0 e 0.9")
        return 1
    
    # Executar AutoML
    success = run_automl_ranking(
        data_path=args.data_path,
        output_path=args.output_path,
        test_size=args.test_size
    )
    
    return 0 if success else 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code) 
 