from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import sys, pathlib

BASE = pathlib.Path(__file__).resolve().parents[2] / "src"
sys.path.append(str(BASE))

from etl import extract_raw_parquet
from preprocess import build_matrix
from train import train_lgbm
from evaluate import eval_lgbm
from registry import publish_model

args = {"owner":"mlops","retries":1,"retry_delay":timedelta(minutes=10)}

with DAG(
    dag_id="train_ltr_daily",
    start_date=datetime(2025,7,15),
    schedule_interval="15 2 * * *",
    catchup=False,
    default_args=args,
    tags=["ltr"],
):
    etl      = PythonOperator(task_id="etl",      python_callable=extract_raw_parquet)
    prep     = PythonOperator(task_id="prep",     python_callable=build_matrix)
    train    = PythonOperator(task_id="train",    python_callable=train_lgbm)
    evaluate = PythonOperator(task_id="evaluate", python_callable=eval_lgbm)
    publish  = PythonOperator(task_id="publish",  python_callable=publish_model)

    etl >> prep >> train >> evaluate >> publish 