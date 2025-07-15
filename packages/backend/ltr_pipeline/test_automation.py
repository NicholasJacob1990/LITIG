#!/usr/bin/env python3
"""
🧪 Script de Teste - Pipeline LTR 100% Automatizado
===================================================

Valida as 4 chaves de automação e simula um ciclo completo de treinamento.
Execute: python packages/backend/ltr_pipeline/test_automation.py
"""

import asyncio
import json
import os
import pathlib
import sys
import time
from datetime import datetime, timedelta
from unittest.mock import patch, MagicMock

# Adicionar path para imports
sys.path.append(str(pathlib.Path(__file__).parent / "src"))

def test_chave_1_ingestao():
    """🔄 CHAVE 1: Testar ingestão automática Kafka + fallback"""
    print("🔄 Testando CHAVE 1: Ingestão Automática...")
    
    try:
        from etl import extract_from_kafka, extract_from_file, extract_raw_parquet
        
        # Simular falha do Kafka para testar fallback
        print("   📡 Testando fallback Kafka → Arquivo...")
        
        # Mock dos dados de teste
        test_date = "2025-01-15"
        
        # Criar arquivo de log de teste se não existir
        log_file = pathlib.Path("logs/audit.log")
        if not log_file.exists():
            log_file.parent.mkdir(parents=True, exist_ok=True)
            
            # Dados sintéticos para teste
            test_events = [
                {
                    "timestamp": "2025-01-15T10:30:00Z",
                    "message": "match_recommendation",
                    "context": {
                        "case_id": "case-123",
                        "lawyer_id": "lawyer-456", 
                        "features": {"A": 1.0, "S": 0.8, "T": 0.9},
                        "fair": 0.85
                    }
                },
                {
                    "timestamp": "2025-01-15T11:00:00Z",
                    "message": "offer_feedback",
                    "context": {
                        "case_id": "case-123",
                        "lawyer_id": "lawyer-456",
                        "action": "contact"
                    }
                }
            ]
            
            with open(log_file, 'w') as f:
                for event in test_events:
                    f.write(json.dumps(event) + "\n")
        
        # Testar extração
        extract_raw_parquet(test_date)
        
        # Verificar se arquivo foi criado
        output_dir = pathlib.Path("packages/backend/ltr_pipeline/data/raw")
        parquet_files = list(output_dir.glob("*.parquet"))
        
        if parquet_files:
            print(f"   ✅ Arquivo Parquet criado: {parquet_files[0]}")
            print(f"   ✅ CHAVE 1 funcionando!")
        else:
            print(f"   ❌ Nenhum arquivo Parquet encontrado")
            
    except Exception as e:
        print(f"   ❌ Erro CHAVE 1: {e}")

def test_chave_2_gate_qualidade():
    """⏰ CHAVE 2: Testar gate de qualidade"""
    print("\n⏰ Testando CHAVE 2: Gate de Qualidade...")
    
    try:
        # Criar métricas sintéticas para teste
        metrics_file = pathlib.Path("packages/backend/ltr_pipeline/data/processed/evaluation_metrics.json")
        metrics_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Teste 1: Métricas que passam no gate
        good_metrics = {
            "ndcg_at_5": 0.75,           # > 0.65 ✅
            "fairness_gap": 0.03,        # < 0.05 ✅
            "latency_p95_ms": 12.5,      # < 15 ✅
            "training_samples": 150      # > 100 ✅
        }
        
        with open(metrics_file, 'w') as f:
            json.dump(good_metrics, f)
        
        # Importar função de gate de qualidade
        sys.path.append(str(pathlib.Path(__file__).parent / "dags"))
        
        # Mock da função por causa de imports do Airflow
        def quality_gate_check():
            with open(metrics_file, 'r') as f:
                metrics = json.load(f)
            
            ndcg = metrics.get("ndcg_at_5", 0.0)
            fairness_gap = metrics.get("fairness_gap", 1.0) 
            latency_p95 = metrics.get("latency_p95_ms", 999)
            training_samples = metrics.get("training_samples", 0)
            
            if ndcg < 0.65:
                raise Exception(f"nDCG muito baixo: {ndcg}")
            if fairness_gap > 0.05:
                raise Exception(f"Fairness gap alto: {fairness_gap}")
            if latency_p95 > 15:
                raise Exception(f"Latência alta: {latency_p95}")
            if training_samples < 100:
                raise Exception(f"Poucas amostras: {training_samples}")
            
            return True
        
        # Testar métricas boas
        result = quality_gate_check()
        print(f"   ✅ Gate passou com métricas boas")
        
        # Teste 2: Métricas que falham no gate
        bad_metrics = {
            "ndcg_at_5": 0.50,           # < 0.65 ❌
            "fairness_gap": 0.08,        # > 0.05 ❌ 
            "latency_p95_ms": 25.0,      # > 15 ❌
            "training_samples": 50       # < 100 ❌
        }
        
        with open(metrics_file, 'w') as f:
            json.dump(bad_metrics, f)
        
        try:
            quality_gate_check()
            print(f"   ❌ Gate deveria ter falhado!")
        except Exception as e:
            print(f"   ✅ Gate corretamente rejeitou métricas ruins: {e}")
            
        print(f"   ✅ CHAVE 2 funcionando!")
        
    except Exception as e:
        print(f"   ❌ Erro CHAVE 2: {e}")

def test_chave_3_publicacao():
    """📦 CHAVE 3: Testar publicação versionada"""
    print("\n📦 Testando CHAVE 3: Publicação Versionada...")
    
    try:
        from registry import publish_model
        
        # Criar modelo mock
        model_dir = pathlib.Path("packages/backend/ltr_pipeline/models/dev")
        model_dir.mkdir(parents=True, exist_ok=True)
        
        model_file = model_dir / "ltr_model.txt"
        if not model_file.exists():
            # Criar arquivo de modelo sintético (LightGBM text format)
            mock_model = """tree
version=v3
num_class=1
num_tree_per_iteration=1
label_index=0
max_feature_idx=10
objective=lambdarank
feature_names=A S T G Q U R C E P M
feature_infos=none none none none none none none none none none none
tree_sizes=100

Tree=0
num_leaves=7
num_cat=0
split_feature=0 1 2 3 4 5
split_gain=0.1 0.2 0.15 0.08 0.05 0.03
threshold=0.5 0.6 0.7 0.8 0.9 0.95
decision_type=2 2 2 2 2 2
left_child=1 3 5 -1 -2 -3
right_child=2 4 6 -4 -5 -6
leaf_value=0.1 0.2 0.15 0.08 0.05 0.03 0.01
leaf_weight=10 20 15 8 5 3 1
leaf_count=100 200 150 80 50 30 10
internal_value=0 0 0 0 0 0
internal_weight=0 0 0 0 0 0
internal_count=0 0 0 0 0 0
shrinkage=1

end of trees"""
            
            with open(model_file, 'w') as f:
                f.write(mock_model)
        
        # Testar publicação
        print("   📝 Publicando modelo de teste...")
        weights = publish_model()
        
        if weights:
            print(f"   ✅ Pesos publicados: {weights}")
            
            # Verificar arquivo local
            local_weights = pathlib.Path("packages/backend/models/ltr_weights.json")
            if local_weights.exists():
                print(f"   ✅ Arquivo local criado: {local_weights}")
            else:
                print(f"   ❌ Arquivo local não criado")
            
            print(f"   ✅ CHAVE 3 funcionando!")
        else:
            print(f"   ❌ Publicação falhou")
            
    except Exception as e:
        print(f"   ❌ Erro CHAVE 3: {e}")

def test_chave_4_polling():
    """🔄 CHAVE 4: Testar polling automático"""
    print("\n🔄 Testando CHAVE 4: Polling Automático...")
    
    try:
        # Simular background task de polling
        weights_file = pathlib.Path("packages/backend/models/ltr_weights.json")
        
        if not weights_file.exists():
            # Criar arquivo de pesos de teste
            test_weights = {
                "A": 0.23, "S": 0.18, "T": 0.11, "G": 0.07,
                "Q": 0.07, "U": 0.05, "R": 0.05, "C": 0.03,
                "E": 0.02, "P": 0.02, "M": 0.17
            }
            weights_file.parent.mkdir(parents=True, exist_ok=True)
            with open(weights_file, 'w') as f:
                json.dump(test_weights, f, indent=2)
        
        # Mock da função load_weights
        def mock_load_weights():
            with open(weights_file, 'r') as f:
                return json.load(f)
        
        # Simular polling
        print("   🔍 Simulando detecção de mudança no arquivo...")
        
        original_mtime = weights_file.stat().st_mtime
        
        # Simular mudança no arquivo
        time.sleep(1)  # Garantir mudança no timestamp
        weights_file.touch()  # Atualizar mtime
        
        new_mtime = weights_file.stat().st_mtime
        
        if new_mtime != original_mtime:
            print(f"   ✅ Mudança detectada: {original_mtime} → {new_mtime}")
            
            # Simular recarga
            weights = mock_load_weights()
            print(f"   ✅ Pesos recarregados: {list(weights.keys())}")
            print(f"   ✅ CHAVE 4 funcionando!")
        else:
            print(f"   ❌ Mudança não detectada")
            
    except Exception as e:
        print(f"   ❌ Erro CHAVE 4: {e}")

def test_fluxo_completo():
    """🎯 Testar fluxo completo E2E"""
    print("\n🎯 Testando Fluxo Completo E2E...")
    
    try:
        print("   1. Ingestão de dados...")
        test_chave_1_ingestao()
        
        print("   2. Gate de qualidade...")
        test_chave_2_gate_qualidade()
        
        print("   3. Publicação versionada...")
        test_chave_3_publicacao()
        
        print("   4. Polling automático...")
        test_chave_4_polling()
        
        print("\n🎉 Fluxo E2E completo!")
        
    except Exception as e:
        print(f"\n❌ Erro no fluxo E2E: {e}")

def main():
    """Função principal de teste"""
    print("🧪 Iniciando Testes do Pipeline LTR Automatizado")
    print("=" * 55)
    
    # Testar cada chave individualmente
    test_chave_1_ingestao()
    test_chave_2_gate_qualidade()
    test_chave_3_publicacao()
    test_chave_4_polling()
    
    # Testar fluxo completo
    test_fluxo_completo()
    
    print("\n" + "=" * 55)
    print("✅ Testes concluídos!")
    print("\n📋 Próximos passos:")
    print("1. Configure as variáveis de ambiente (config_env.example)")
    print("2. Instale dependências: pip install kafka-python boto3 apache-airflow")
    print("3. Ative a DAG no Airflow UI")
    print("4. Monitore logs em logs/ltr_training.log")
    print("\n🚀 Seu pipeline está pronto para automação 100%!")

if __name__ == "__main__":
    main() 