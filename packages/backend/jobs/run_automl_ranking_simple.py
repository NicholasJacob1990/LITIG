#!/usr/bin/env python3
"""
Script simplificado de AutoML para otimização do algoritmo de ranqueamento.
Esta versão usa scikit-learn diretamente, evitando problemas de compatibilidade do PyCaret.
"""

import argparse
import pandas as pd
import numpy as np
import json
from pathlib import Path
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.naive_bayes import GaussianNB
from sklearn.metrics import accuracy_score, classification_report
from sklearn.preprocessing import StandardScaler
import warnings
warnings.filterwarnings('ignore')

def load_and_validate_data(data_path):
    """Carrega e valida o dataset de treinamento."""
    print(f"📊 Carregando dados de: {data_path}")
    
    if not Path(data_path).exists():
        raise FileNotFoundError(f"Arquivo não encontrado: {data_path}")
    
    df = pd.read_csv(data_path)
    print(f"✅ Dataset carregado: {len(df)} registros, {len(df.columns)} colunas")
    
    # Validar estrutura esperada
    required_columns = [
        'feature_S_qualis', 'feature_T_titulacao', 'feature_E_experiencia',
        'feature_M_multidisciplinar', 'feature_C_complexidade', 'feature_P_honorarios',
        'feature_R_reputacao', 'feature_Q_qualificacao', 'similarity_score',
        'offer_accepted'
    ]
    
    missing_columns = [col for col in required_columns if col not in df.columns]
    if missing_columns:
        raise ValueError(f"Colunas obrigatórias ausentes: {missing_columns}")
    
    print("✅ Estrutura do dataset validada")
    return df

def prepare_features(df):
    """Prepara as features para o treinamento."""
    print("🔧 Preparando dados para AutoML...")
    
    # Features principais (excluindo IDs e target)
    feature_columns = [
        'feature_S_qualis', 'feature_T_titulacao', 'feature_E_experiencia',
        'feature_M_multidisciplinar', 'feature_C_complexidade', 'feature_P_honorarios',
        'feature_R_reputacao', 'feature_Q_qualificacao', 'similarity_score'
    ]
    
    X = df[feature_columns]
    y = df['offer_accepted']
    
    print(f"✅ Features selecionadas: {feature_columns}")
    print(f"✅ Distribuição do target: {dict(y.value_counts())}")
    
    if len(df) < 50:
        print("⚠️  AVISO: Dataset muito pequeno (< 50 registros). Resultados podem não ser confiáveis.")
    
    return X, y, feature_columns

def train_and_evaluate_models(X, y):
    """Treina múltiplos modelos e retorna o melhor, com estratégias para poucos dados."""
    print("🤖 Treinando e comparando modelos...")
    
    is_small_dataset = len(X) < 100  # Definir um limiar para "poucos dados"

    # Dividir dados
    test_size = 0.2 if not is_small_dataset else 0.1
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=test_size, random_state=42, stratify=y
    )
    
    # Normalizar features
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Modelos para testar
    models = {}
    
    if is_small_dataset:
        print("ℹ️  Dataset pequeno detectado. Usando modelos simples e com maior regularização.")
        # Para poucos dados, priorizar modelos lineares e robustos
        models['logistic_regression_strong_reg'] = LogisticRegression(random_state=42, max_iter=1000, C=0.1, penalty='l2') # C baixo = regularização forte
        models['naive_bayes'] = GaussianNB()
    else:
        # Para datasets maiores, podemos testar modelos mais complexos
        models['logistic_regression'] = LogisticRegression(random_state=42, max_iter=1000)
        models['random_forest'] = RandomForestClassifier(random_state=42, n_estimators=100, max_depth=10) # Limitar a profundidade
        models['naive_bayes'] = GaussianNB()

    best_model = None
    best_score = 0
    best_name = ""
    results = {}
    
    print("🔍 Avaliando modelos...")
    
    for name, model in models.items():
        try:
            # Para Logistic Regression e Naive Bayes, usar dados normalizados
            if name in ['logistic_regression', 'naive_bayes']:
                X_train_model = X_train_scaled
                X_test_model = X_test_scaled
            else:
                X_train_model = X_train
                X_test_model = X_test
            
            # Treinar modelo
            model.fit(X_train_model, y_train)
            
            # Avaliar com validação cruzada
            if len(X_train) > 10:  # Só fazer CV se houver dados suficientes
                cv_scores = cross_val_score(model, X_train_model, y_train, cv=3, scoring='accuracy')
                avg_score = np.mean(cv_scores)
            else:
                # Para datasets muito pequenos, usar apenas accuracy no teste
                y_pred = model.predict(X_test_model)
                avg_score = accuracy_score(y_test, y_pred)
            
            results[name] = {
                'score': avg_score,
                'model': model,
                'scaler': scaler if name in ['logistic_regression', 'naive_bayes'] else None
            }
            
            print(f"  📈 {name}: {avg_score:.4f}")
            
            if avg_score > best_score:
                best_score = avg_score
                best_model = model
                best_name = name
                
        except Exception as e:
            print(f"  ❌ {name}: Falha no treinamento - {e}")
            continue
    
    if best_model is None:
        raise Exception("Nenhum modelo foi treinado com sucesso")
    
    print(f"🏆 Melhor modelo: {best_name} (score: {best_score:.4f})")
    
    return best_model, best_name, best_score, results[best_name]

def extract_feature_importances(model, model_name, feature_columns):
    """Extrai importâncias das features do modelo treinado."""
    print("📊 Extraindo importâncias das features...")
    
    if hasattr(model, 'feature_importances_'):
        # Random Forest
        importances = model.feature_importances_
    elif hasattr(model, 'coef_'):
        # Logistic Regression - usar valor absoluto dos coeficientes
        importances = np.abs(model.coef_[0])
    else:
        # Naive Bayes ou outros - criar pesos uniformes
        print("⚠️  Modelo não suporta importâncias. Usando pesos uniformes.")
        importances = np.ones(len(feature_columns)) / len(feature_columns)
    
    # Normalizar para soma = 1
    importances = importances / np.sum(importances)
    
    # Criar dicionário de pesos
    weights = {}
    for i, feature in enumerate(feature_columns):
        # Mapear nomes das features para os pesos no algoritmo
        weight_name = feature.replace('feature_', '').upper()
        weights[f'WEIGHT_{weight_name}'] = float(importances[i])
    
    return weights

def save_optimized_weights(weights, output_path):
    """Salva os pesos otimizados em arquivo JSON."""
    print(f"💾 Salvando pesos otimizados em: {output_path}")
    
    # Criar diretório se não existir
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    
    # Salvar pesos
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(weights, f, indent=2, ensure_ascii=False)
    
    print("✅ Pesos salvos com sucesso!")

def main():
    parser = argparse.ArgumentParser(description='AutoML simplificado para otimização de ranqueamento')
    parser.add_argument('--data_path', required=True, help='Caminho para o arquivo CSV de dados históricos')
    parser.add_argument('--output_path', default='packages/backend/config/optimized_weights.json', 
                       help='Caminho para salvar os pesos otimizados')
    
    args = parser.parse_args()
    
    try:
        print("🚀 Iniciando AutoML simplificado para otimização do algoritmo de ranqueamento...")
        
        # 1. Carregar e validar dados
        df = load_and_validate_data(args.data_path)
        
        # 2. Preparar features
        X, y, feature_columns = prepare_features(df)
        
        # 3. Treinar e avaliar modelos
        best_model, model_name, score, model_info = train_and_evaluate_models(X, y)
        
        # 4. Extrair importâncias das features
        weights = extract_feature_importances(best_model, model_name, feature_columns)
        
        # 5. Salvar pesos otimizados
        save_optimized_weights(weights, args.output_path)
        
        print("\n🎉 PROCESSO CONCLUÍDO COM SUCESSO!")
        print(f"📈 Melhor modelo: {model_name}")
        print(f"📊 Score: {score:.4f}")
        print(f"⚖️  Pesos otimizados salvos em: {args.output_path}")
        
        # Mostrar resumo dos pesos
        print("\n📋 RESUMO DOS PESOS OTIMIZADOS:")
        for weight_name, value in weights.items():
            print(f"  {weight_name}: {value:.4f}")
        
        return True
        
    except Exception as e:
        print(f"❌ ERRO durante AutoML: {e}")
        print("💡 Verifique os dados de entrada e tente novamente.")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1) 
 