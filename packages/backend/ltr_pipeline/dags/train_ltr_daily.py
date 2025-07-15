from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.email import EmailOperator
from airflow.models import Variable
from airflow.utils.trigger_rule import TriggerRule
from datetime import datetime, timedelta
import sys, pathlib
import os

BASE = pathlib.Path(__file__).resolve().parents[2] / "src"
sys.path.append(str(BASE))

from etl import extract_raw_parquet
from preprocess import build_matrix
from train import train_lgbm
from evaluate import eval_lgbm
from registry import publish_model

# ⚡ CHAVE 2: Configuração para automação completa
default_args = {
    "owner": "mlops",
    "depends_on_past": False,
    "email": ["ml-alerts@litgo.com"],
    "email_on_failure": True,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=15),
    "execution_timeout": timedelta(hours=2),
}

# ⚡ CHAVE 2: Gate de qualidade configurável via Airflow Variables
QUALITY_GATE_NDCG_MIN = float(Variable.get("ltr_ndcg_min", 0.65))
QUALITY_GATE_FAIRNESS_MAX = float(Variable.get("ltr_fairness_max", 0.05))
MINIMUM_TRAINING_SAMPLES = int(Variable.get("ltr_min_samples", 100))

def quality_gate_check():
    """
    ⚡ CHAVE 2: Gate de qualidade automático.
    
    Verifica se o modelo atende critérios mínimos:
    - nDCG@5 >= threshold
    - Fair-Gap <= threshold  
    - Latência p95 < 15ms
    - Amostras de treino >= mínimo
    """
    import json
    from pathlib import Path
    
    # Carregar métricas do evaluate
    metrics_file = Path("packages/backend/ltr_pipeline/data/processed/evaluation_metrics.json")
    
    if not metrics_file.exists():
        raise Exception("❌ Arquivo de métricas não encontrado")
    
    with open(metrics_file, 'r') as f:
        metrics = json.load(f)
    
    # Verificações do gate de qualidade
    ndcg = metrics.get("ndcg_at_5", 0.0)
    fairness_gap = metrics.get("fairness_gap", 1.0)
    latency_p95 = metrics.get("latency_p95_ms", 999)
    training_samples = metrics.get("training_samples", 0)
    
    print(f"📊 Métricas do modelo:")
    print(f"   nDCG@5: {ndcg:.3f} (min: {QUALITY_GATE_NDCG_MIN})")
    print(f"   Fair-Gap: {fairness_gap:.3f} (max: {QUALITY_GATE_FAIRNESS_MAX})")
    print(f"   Latência p95: {latency_p95:.1f}ms (max: 15ms)")
    print(f"   Amostras: {training_samples} (min: {MINIMUM_TRAINING_SAMPLES})")
    
    # Validações
    if ndcg < QUALITY_GATE_NDCG_MIN:
        raise Exception(f"❌ nDCG muito baixo: {ndcg:.3f} < {QUALITY_GATE_NDCG_MIN}")
    
    if fairness_gap > QUALITY_GATE_FAIRNESS_MAX:
        raise Exception(f"❌ Fairness gap muito alto: {fairness_gap:.3f} > {QUALITY_GATE_FAIRNESS_MAX}")
    
    if latency_p95 > 15:
        raise Exception(f"❌ Latência muito alta: {latency_p95:.1f}ms > 15ms")
    
    if training_samples < MINIMUM_TRAINING_SAMPLES:
        raise Exception(f"❌ Poucas amostras: {training_samples} < {MINIMUM_TRAINING_SAMPLES}")
    
    print("✅ Todas as verificações de qualidade passaram!")
    return True

def notify_success():
    """Notifica sucesso do pipeline LTR."""
    print("🎉 Pipeline LTR executado com sucesso!")
    print("📈 Novo modelo foi promovido para produção")
    
    # Aqui você pode adicionar webhooks, Slack, etc.
    # slack_webhook = Variable.get("slack_webhook", None)
    # if slack_webhook:
    #     send_slack_notification(slack_webhook, "✅ LTR Pipeline concluído")

def handle_failure():
    """Lida com falhas do pipeline."""
    print("❌ Pipeline LTR falhou - modelo anterior mantido")
    
    # Log para análise
    import logging
    logging.error("LTR Pipeline failure - previous model retained")

# ⚡ CHAVE 2: DAG com automação completa
with DAG(
    dag_id="train_ltr_daily",
    description="🚀 Pipeline LTR 100% Automatizado com Gate de Qualidade",
    start_date=datetime(2025, 1, 15),
    schedule_interval="15 2 * * *",  # 02:15 UTC diário
    catchup=False,
    default_args=default_args,
    tags=["ltr", "ml", "automated"],
    max_active_runs=1,  # Evitar sobreposição
) as dag:

    # Task Group: Extração e Preparação
    extract_task = PythonOperator(
        task_id="extract_events",
        python_callable=extract_raw_parquet,
        doc_md="🔍 Extrai eventos do Kafka (primary) ou arquivo local (fallback)"
    )
    
    preprocess_task = PythonOperator(
        task_id="preprocess_data", 
        python_callable=build_matrix,
        doc_md="🔄 Transforma dados brutos em matriz de treinamento"
    )
    
    # Task Group: Treinamento e Avaliação
    train_task = PythonOperator(
        task_id="train_model",
        python_callable=train_lgbm,
        doc_md="🧠 Treina modelo LightGBM LambdaMART"
    )
    
    evaluate_task = PythonOperator(
        task_id="evaluate_model",
        python_callable=eval_lgbm,
        doc_md="📊 Avalia modelo: nDCG, MRR, fairness, latência"
    )
    
    # ⚡ CHAVE 2: Gate de Qualidade Automático
    quality_gate = PythonOperator(
        task_id="quality_gate",
        python_callable=quality_gate_check,
        doc_md="🚪 Gate de qualidade: valida métricas antes da publicação"
    )
    
    # ⚡ CHAVE 3: Publicação Versionada
    publish_task = PythonOperator(
        task_id="publish_model",
        python_callable=publish_model,
        trigger_rule=TriggerRule.ALL_SUCCESS,
        doc_md="📦 Publica pesos versionados local + S3"
    )
    
    # ⚡ CHAVE 4: Trigger para recarga automática
    trigger_reload = BashOperator(
        task_id="trigger_weight_reload",
        bash_command="""
        # Notifica FastAPI para recarregar pesos (background task detectará mudança)
        echo "✅ Pesos publicados - background task detectará mudança automaticamente"
        echo "🔄 Polling configurado para $(echo ${WEIGHTS_POLL_SECONDS:-300})s"
        
        # Opcional: webhook para forçar reload imediato
        if [ -n "$FASTAPI_RELOAD_WEBHOOK" ]; then
            curl -f -X POST "$FASTAPI_RELOAD_WEBHOOK" || true
        fi
        """,
        trigger_rule=TriggerRule.ALL_SUCCESS
    )
    
    # Notificações
    success_notification = PythonOperator(
        task_id="notify_success",
        python_callable=notify_success,
        trigger_rule=TriggerRule.ALL_SUCCESS
    )
    
    failure_notification = PythonOperator(
        task_id="handle_failure", 
        python_callable=handle_failure,
        trigger_rule=TriggerRule.ONE_FAILED
    )
    
    # ⚡ Fluxo automatizado completo
    extract_task >> preprocess_task >> train_task >> evaluate_task
    evaluate_task >> quality_gate >> publish_task >> trigger_reload >> success_notification
    
    # Lidar com falhas em qualquer ponto
    [extract_task, preprocess_task, train_task, evaluate_task, quality_gate, publish_task] >> failure_notification 