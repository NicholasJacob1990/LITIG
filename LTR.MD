## 🚀 Implementação LTR 100 % Automatizada — visão ponta‑a‑ponta

**Parte 1 / 2 – Dados, Pipeline de Treino e Publicação**

> **Objetivo:** colocar um LightGBM (LambdaMART) em produção, treinado diariamente, servindo em *shadow* para 10 % do tráfego, com **fallback** automático para a soma de pesos.

---

### 1. Instrumentação de Eventos (dia 0)

| Evento            | Quando disparar     | Campos mínimos                                  |
| ----------------- | ------------------- | ----------------------------------------------- |
| `impression`      | API devolve ranking | `case_id`, lista `[lawyer_ids]`, `weights_used` |
| `click_profile`   | Usuário abre perfil | `case_id`, `lawyer_id`, `rank_pos`              |
| `contact_made`    | Cria chat/ligação   | idem acima                                      |
| `contract_signed` | Contrato digital    | idem acima                                      |

*Logar em **Kafka topic** `match_events`; fallback direto em Postgres se ainda não tiver Kafka.*

---

### 2. Data Lake & ETL (dia 1 → ∞)

1. **Flink** lê o tópico, grava Parquet em
   `s3://datalake/ltr/raw/YYYY/MM/DD/*.parquet`.
2. **Airflow DAG** (`etl_ltr_daily`) consolida o dia T‑1:

   * Carrega Parquet, enriquece com KPIs do advogado, diversity, etc.
   * Gera dataset tabular com:

     * coluna `qid` = `case_id`
     * coluna `label` (0/0.3/0.6/1)
     * 11 features normalizadas
   * Salva em `s3://datalake/ltr/processed/{date}/matrix.parquet`.

---

### 3. Pipeline de Treinamento (Airflow DAG `train_ltr_daily`)

```mermaid
graph LR
A[Download matrix.parquet] --> B[Split temporal<br>(train/valid/test)]
B --> C[Scaler fit & save<br>(feature_map.json)]
C --> D[Train LightGBM<br>— LambdaMART]
D --> E[Eval nDCG@5 & MRR]
E --> F{Pass thresholds?}
F -- NO --> G[Fail DAG & alert]
F -- YES --> H[Register in MLflow]
H --> I[Upload model & feature_map<br>to S3 / litgo-models/ltr/{ts}/]
```

**Parâmetros LightGBM básicos**

```python
params = {
    "objective":      "lambdarank",
    "metric":         "ndcg",
    "ndcg_eval_at":   [5],
    "learning_rate":  0.05,
    "num_leaves":     48,
    "min_data_in_leaf": 20,
    "feature_fraction": 0.9,
    "lambda_l1": 0.2,          # regularização para poucos dados
    "lambda_l2": 0.2,
    "early_stopping_round": 100,
    "seed": 42
}
```

*Com \~500 linhas o treino leva < 30 s em CPU.*

---

### 4. Gate de Qualidade (offline)

| Métrica            | Alvo                | Implementação                         |
| ------------------ | ------------------- | ------------------------------------- |
| nDCG\@5            | ≥ baseline + 3 p.p. | `lgb.cv` ou função manual             |
| MRR\@5             | ↑ vs baseline       | idem                                  |
| Fair‑Gap Δ         | ≤ 0.05              | comparar `fair_base` por gênero/etnia |
| Latência p95 (inf) | < 15 ms CPU         | teste local `timeit`                  |

Se **qualquer** métrica falhar → DAG falha → modelo **não** é publicado.

---

### 5. Publicação & Versionamento

* Se aprovado, o step `publish_model` faz:

  1. copia `ltr_model.txt` + `feature_map.json` para
     `s3://litgo-models/ltr/{ts}/`
  2. grava registro em **MLflow** (`stage=staging`, tag `ts`).
  3. dispara webhook para o cluster K8s (Helm chart) indicando “novo modelo pronto”.

---

### 6. Deploy no Serviço `/ltr/score`

| Pasta no container         | Valor                                                         |
| -------------------------- | ------------------------------------------------------------- |
| `/opt/models/ltr_current/` | cópia do último **aprovado** (`model.txt`, `feature_map.pkl`) |

O container reinicia via Rolling Update (Argo Rollouts) e carrega o arquivo TXT:

```python
MODEL = lgb.Booster(model_file="/opt/models/ltr_current/model.txt")
FEATURES = pickle.load(open("/opt/models/ltr_current/feature_map.pkl", "rb"))
```

Latência típica: **\~3 ms** p95 em CPU AVX2.

---

### 7. Integração no `MatchmakingAlgorithm`

```python
async def rank_with_fallback(case, lawyers):
    try:
        feat_matrix = build_feature_matrix(case, lawyers, FEATURES)
        ltr_scores = await call_ltr_service(feat_matrix, timeout=0.2)
        for lw, sc in zip(lawyers, ltr_scores):
            lw.scores["ltr"] = sc
            lw.scores["source"] = "ltr"
        return rerank_fairness(lawyers)
    except Exception as e:
        logger.warning("LTR fail (%s) – fallback to weights", e)
        matcher = MatchmakingAlgorithm()
        return await matcher.rank(case, lawyers, preset="balanced")
```

*Timeout curto garante **fail‑fast**; fallback preserva UX.*

## 🚀 Implementação LTR 100 % Automatizada — visão ponta‑a‑ponta

**Parte 2 / 2 – Shadow Traffic, Observabilidade, Rollback & Governança**

---

### 8. Roteamento de Tráfego (10 % Shadow)

| Camada                            | Como fazer                                                                                                                                                                     | Observação                                                 |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------- |
| **API Gateway** (FastAPI)         | Middleware inspeciona `X‑Shadow‑LTR=1` no header; se presente, faz **duas** chamadas: <br>① ranking legacy (retorna ao usuário) <br>② ranking LTR (ignora resposta, mas loga). | Header injetado a partir de um *flag* redis distribuído.   |
| **Load‑Balancer** (NGINX‑Ingress) | Regra `map $request_id $shadow` (10 % hash) → duplica requisição para `ltr-shadow-svc`.                                                                                        | Serve para linguagens ou times sem controle de middleware. |

*Implementação escolhida depende do stack de rede; o padrão mais simples é **middleware no Gateway**.*

---

### 9. Persistência de Resultados Shadow

```sql
CREATE TABLE ltr_shadow_log (
    shadow_id      UUID PRIMARY KEY,
    ts_utc         TIMESTAMPTZ,
    case_id        UUID,
    user_id        UUID,
    lawyer_id      TEXT,
    rank_legacy    SMALLINT,
    rank_ltr       SMALLINT,
    label          REAL      -- 0/0.3/0.6/1 (preenchido dias depois via ETL)
);
```

*Os ETLs diários atualizam `label` quando eventos de click/contrato forem gerados.*

---

### 10. Métricas de Comparação

| Métrica online           | Cálculo                                                             | Painel Grafana            |
| ------------------------ | ------------------------------------------------------------------- | ------------------------- |
| **Hit\@3 Shadow**        | % de casos em que advogado contratado teria ficado no Top 3 do LTR. | Linha diária vs baseline. |
| **MRR Gap**              | `MRR_ltr – MRR_legacy` (em shadow).                                 | Verde se > 0.             |
| **Latência p95 LTR svc** | Prometheus histogram.                                               | Alerta > 20 ms.           |
| **Fallback rate**        | `ltr_fallback_total / requests`                                     | Alerta > 2 %.             |

*Scripts PySpark geram **relatórios semanais** (`shadow_eval_{iso_week}.csv`) colocados no Data Lake.*

---

### 11. Critérios de Promoção

1. **Duração mínima:** ≥ 14 dias **ou** ≥ 3 000 casos.
2. **Hit\@3 Shadow:** melhoria ≥ 5 p.p. sobre legacy.
3. **MRR Gap:** > 0 com 95 % CI.
4. **Fair‑Gap Δ:** não piora (> 0.02) vs legacy.
5. **Latência p95:** < 15 ms CPU.

> Se **todos** ok → *Argo Rollouts* promove tráfego LTR para 100 % através de `set-weight 100`.
> Caso contrário, permanece em shadow e o ciclo de re‑treino continua.

---

### 12. Rollback Automático

```yaml
spec:
  analysis:
    rollback:
      steps:
        - analysisTemplate: latency-check
          threshold: 25ms
        - analysisTemplate: hitrate-check
          threshold: -1pp   # caiu 1 ponto ou mais
```

*Qualquer violação de SLA aciona **automatic rollback** → peso volta a 0 %.*

---

### 13. Monitoramento & Alertas

| Ferramenta     | Painel / Alerta                                                         |
| -------------- | ----------------------------------------------------------------------- |
| **Grafana**    | “LTR Shadow Performance” – 4 métricas chave.                            |
| **Prometheus** | Alertmanager envia Slack: `LTR_FALLBACK_RATE_HIGH`, `LTR_LATENCY_HIGH`. |
| **Sentry**     | Captura exceções no endpoint `/ltr/score`.                              |

---

### 14. Segurança & Conformidade

* **LGPD opt‑out**: se usuário solicitar exclusão → `DELETE FROM match_events WHERE user_id = …`.
* **Pseudonimização**: hash(user\_id, salt) antes de gravar em tabelas shadow.
* **Model Card**: PDF gerado via script, armazenado na Wiki interna, descreve dados, métricas, limitações.

---

### 15. Linha do Tempo (“Critical Path”)

| Semana | Tarefas                                                    |
| ------ | ---------------------------------------------------------- |
| 1      | Instrumentar eventos + topic Kafka                         |
| 2      | ETL Parquet, tabela `match_events`                         |
| 3      | Implementar pipeline `train_ltr_daily`, thresholds offline |
| 4      | Deploy serviço `/ltr/score` com fallback                   |
| 5      | Ativar 10 % shadow via header ou Ingress                   |
| 6‑7    | Coleta de métricas, dashboards, alertas                    |
| 8      | Go/No‑Go – promoção a 100 % se critérios cumpridos         |

---

### 16. Checklist de Go‑Live

* [x] Fallback testado (desligar serviço LTR → ranking legacy ok)
* [x] Dashboards preenchendo em tempo real
* [x] Alertmanager dispara Slack em fallback > 2 %
* [x] Script de rollback manual documentado
* [x] Model Card publicado
* [x] DPIA LGPD atualizado

---

### 📦 Exemplos de implementação (Parte 3 / 3)

> A seguir, blocos completos prontos para copiar‑colar: DAG do Airflow, serviço FastAPI, Helm Chart simplificado, regra Prometheus e consulta SQL Hit\@3.

---

## 17. DAG completo (`dags/train_ltr_daily.py`)

```python
"""
Airflow DAG: Treinamento diário do LightGBM LambdaMART
Agendado para 02:15 UTC (23:15 BRT).
"""
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.task_group import TaskGroup
from datetime import datetime, timedelta
from src import etl, preprocess, train, evaluate, registry

default_args = {
    "owner": "mlops",
    "depends_on_past": False,
    "email": ["ml-alerts@litgo.com"],
    "email_on_failure": True,
    "retries": 1,
    "retry_delay": timedelta(minutes=15),
}

with DAG(
    dag_id="train_ltr_daily",
    description="LightGBM LambdaMART – re‑treino automático",
    start_date=datetime(2025, 7, 1),
    schedule_interval="15 2 * * *",
    catchup=False,
    tags=["ltr", "retrain"],
    default_args=default_args,
) as dag:

    with TaskGroup("etl") as tg_etl:
        extract = PythonOperator(
            task_id="extract",
            python_callable=etl.extract_raw_parquet,
        )
        enrich = PythonOperator(
            task_id="enrich",
            python_callable=etl.enrich_kpi_features,
        )
        extract >> enrich

    preprocess_task = PythonOperator(
        task_id="preprocess",
        python_callable=preprocess.build_matrix,
    )

    train_task = PythonOperator(
        task_id="train",
        python_callable=train.train_lgbm,
    )

    eval_task = PythonOperator(
        task_id="evaluate",
        python_callable=evaluate.eval_lgbm,
    )

    publish_task = PythonOperator(
        task_id="publish",
        python_callable=registry.publish_model,
        trigger_rule="all_success",
    )

    tg_etl >> preprocess_task >> train_task >> eval_task >> publish_task
```

---

## 18. Serviço `/ltr/score` – FastAPI minimal

```python
# app_ltr/main.py
from fastapi import FastAPI, HTTPException
import lightgbm as lgb
import numpy as np, pickle, json, os

MODEL_PATH = os.getenv("MODEL_PATH", "/opt/models/ltr_current/model.txt")
MAP_PATH   = os.getenv("FEATURE_MAP", "/opt/models/ltr_current/feature_map.pkl")

app = FastAPI(title="LitGo LTR Scoring Service")

MODEL = lgb.Booster(model_file=MODEL_PATH)
FEATURE_ORDER = pickle.load(open(MAP_PATH, "rb"))

@app.post("/ltr/score")
async def ltr_score(payload: dict):
    try:
        x = np.array([[payload["features"][f] for f in FEATURE_ORDER]])
        score = MODEL.predict(x, num_iteration=MODEL.best_iteration)[0]
        return {"score": float(score)}
    except KeyError as e:
        raise HTTPException(status_code=422, detail=f"missing feature {e}")
```

*Conteinerize em `Dockerfile` simples (python:3.11‑slim) + `uvicorn app_ltr.main:app --host 0.0.0.0 --port 8080`.*

---

## 19. Helm Chart (resumo)

```yaml
# charts/ltr/values.yaml
image:
  repository: registry.gitlab.com/litgo/ltr-service
  tag: "v0.3.2"
replicaCount: 3

resources:
  limits:
    cpu: "500m"
    memory: "512Mi"

env:
  MODEL_PATH: /models/model.txt
  FEATURE_MAP: /models/feature_map.pkl

shadow:
  weight: 10    # 10 % tráfego duplicado

# charts/ltr/templates/deployment.yaml (excerto)
...
        volumeMounts:
          - name: model-volume
            mountPath: /models
      volumes:
        - name: model-volume
          persistentVolumeClaim:
            claimName: ltr-model-pvc
```

*Argo Rollouts manipula `shadow.weight` alterando route no Ingress.*

---

## 20. Regra Prometheus – Latência & Fallback

```yaml
# prometheus/alert-rules-ltr.yml
groups:
- name: ltr-service
  rules:
  - alert: LTRServiceHighLatency
    expr: histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{job="ltr-service"}[5m])) by (le))
          > 0.020   # 20 ms
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "Latência p95 do LTR > 20 ms"
      runbook: https://wiki.litgo.com/latency-incident

  - alert: LTRFallbackRateHigh
    expr: rate(ltr_fallback_total[10m]) / rate(api_requests_total[10m]) > 0.02
    for: 15m
    labels:
      severity: critical
    annotations:
      summary: "Fallback para algoritmo legado > 2 %"
      runbook: https://wiki.litgo.com/fallback-incident
```

---

## 21. Consulta SQL – Hit\@3 Shadow vs Legacy

```sql
WITH success AS (
  SELECT case_id,
         lawyer_id,
         MAX(label) AS outcome      -- 1.0 se contratado
  FROM   ltr_shadow_log
  WHERE  label = 1.0
  GROUP BY case_id, lawyer_id
),
positions AS (
  SELECT s.case_id,
         s.lawyer_id,
         MIN(s.rank_legacy) FILTER (WHERE s.rank_legacy IS NOT NULL) AS pos_legacy,
         MIN(s.rank_ltr)    FILTER (WHERE s.rank_ltr    IS NOT NULL) AS pos_ltr
  FROM   ltr_shadow_log s
  JOIN   success        u USING (case_id, lawyer_id)
  GROUP BY s.case_id, s.lawyer_id
)
SELECT
  COUNT(*) FILTER (WHERE pos_legacy <= 3) * 1.0 / COUNT(*) AS hit3_legacy,
  COUNT(*) FILTER (WHERE pos_ltr    <= 3) * 1.0 / COUNT(*) AS hit3_ltr
FROM positions;
```

---
### Sim, você consegue montar **todo o fluxo automático** dentro do Cursor IDE — mas é importante lembrar que a IDE em si apenas orquestra o código e os contêineres; quem executa a automação contínua é a stack Docker/Airflow/K8s que você vai subir a partir do projeto. Abaixo segue um roteiro pragmático:

---

## 1 ▪︎ Preparar o ambiente de desenvolvimento no Cursor

1. **Clone o repositório** `ltr_pipeline/` na workspace do Cursor.
2. Crie um **`.devcontainer/`** ou **`docker-compose.yml`** na raiz com:

   * **airflow-scheduler**, **airflow-webserver**, **postgres**
   * **kafka + zookeeper** (ou Redpanda para dev)
   * **minio** (mock S3)
   * **ltr-service** (FastAPI)
3. No Cursor, abra o painel “Containers” → `Compose Up`.

   * Isso já levanta Airflow na porta 8080 e o serviço LTR na 8081.

> **Dica:** o Cursor monta seus volumes locais dentro dos contêineres, então qualquer alteração de código é “hot‑reload”.

---

## 2 ▪︎ Criar os alvos de automação

### `Makefile` minimal

```make
setup:  ## Instala dependências Python
	pip install -r requirements.txt

etl:    ## Roda ETL local usando os Parquets mockados
	python -m src.etl

train:  ## Treina LightGBM com warm‑start
	python -m src.train

evaluate:
	python -m src.evaluate

publish:
	python -m src.registry
```

No Cursor, pressione **⌘⇧P → “Run Make Target…”** e escolha `train` para ver se tudo roda sem sair da IDE.

---

## 3 ▪︎ Subir o Airflow local

1. No painel de Terminais do Cursor, rode:

   ```bash
   docker compose up -d airflow-init
   docker compose up airflow-scheduler airflow-webserver
   ```

2. Abra `http://localhost:8080` → ative a DAG `train_ltr_daily`.

> Quando salvar o arquivo `dags/train_ltr_daily.py`, o Cursor detecta e recarrega o contêiner Airflow automaticamente.

---

## 4 ▪︎ Testar o serviço `/ltr/score`

* Dentro do Cursor: `curl -X POST localhost:8081/ltr/score -d @sample.json`
* Ajuste os **paths** de modelo apontando para `./models/dev/`.

Quando você altera o modelo e roda `publish`, o script copia o novo artefato para a pasta bind‑mountada `/models`; o FastAPI faz **watch** via `watchgod` e recarrega.

---

## 5 ▪︎ Shadow Traffic local (simulado)

```python
# tests/test_shadow.py
from src.shadow import simulate_shadow
simulate_shadow(n_cases=50)
```

Rode pelo painel de testes do Cursor → veja o log JSON em tempo real no console embutido.

---

## 6 ▪︎ Commit, CI e Deploy

* Configure **GitHub Actions** ou **GitLab CI** para:

  1. `docker build` da imagem `ltr-service`.
  2. Push para o registry.
  3. Deploy via **Argo Rollouts** manifest armazenado em `deploy/`.

O Cursor já mostra os pipelines Git em uma aba lateral, permitindo acompanhar o deploy sem sair da IDE.

---

## 7 ▪︎ Agendar em produção

* Crie um arquivo Helm `values-prod.yaml` com `shadow.weight: 10`.
* No Cursor, abra o terminal remoto do cluster (`kubectl`) e rode:

  ```bash
  helm upgrade --install ltr charts/ltr -f deploy/values-prod.yaml
  ```

O Cursor exibe os logs dos pods em tempo real, então você consegue verificar fallback ou latência sem sair do editor.

---

### Checklist rápido

* [x] Contêineres sobem via **Compose** no Cursor
* [x] DAG é detectada e executa no Airflow local
* [x] Scripts `etl → train → evaluate → publish` rodam via Make
* [x] Serviço LTR responde em `/ltr/score`
* [x] Fallback testado manualmente (parar contêiner LTR → ranking legacy)

Se todos os itens acima passarem no ambiente local da IDE, basta “promover” a mesma stack para o cluster de staging/produção.

---

**Conclusão:** o Cursor não substitui Airflow nem Kubernetes, mas facilita **codar, versionar e observar** todo o pipeline sem trocar de ferramenta. Uma vez que Docker + Airflow estejam configurados, o treinamento e o shadow já acontecem de forma **100 % automática** — seu papel passa a ser apenas revisar dashboards e *mergear* pull‑requests.




