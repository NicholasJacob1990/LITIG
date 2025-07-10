Segue a próxima etapa — **plugando o algoritmo ao back-end e deixando pronto para o app React/Expo**. Não alterei o arquivo; vou apenas mostrar como envolvê-lo em uma API REST mínima e persistir dados no Supabase (ou outro Postgres).

---

## 1 · Estrutura do projeto Python

```
backend/
├── algoritmo.py              # (o arquivo que já está no canvas)
├── main.py                   # FastAPI + endpoints
├── requirements.txt          # fastapi, uvicorn, numpy, supabase-py
└── Dockerfile                # para deploy em Render / Railway
```

---

## 2 · `main.py` — FastAPI enxuto

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from supabase import create_client
import numpy as np
import os, uuid

from algoritmo import Case, Lawyer, KPI, MatchmakingAlgorithm

# --- config -----------------------------------------------------------------
supabase = create_client(os.getenv("SUPABASE_URL"),
                         os.getenv("SUPABASE_SERVICE_KEY"))
algo = MatchmakingAlgorithm()
app = FastAPI()

# --- Pydantic DTOs ----------------------------------------------------------
class TriagemDTO(BaseModel):
    texto_cliente: str
    area: str
    subarea: str
    urgency_h: int
    summary_embedding: list[float] = Field(..., min_items=384, max_items=384)
    coords: tuple[float, float]

class MatchRequest(BaseModel):
    case_id: str
    k: int = 5

# --- endpoint: salvar caso pós-triagem --------------------------------------
@app.post("/cases")
def create_case(dto: TriagemDTO):
    case_id = str(uuid.uuid4())
    supabase.table("cases").insert({
        "id": case_id,
        "area": dto.area,
        "subarea": dto.subarea,
        "urgency_h": dto.urgency_h,
        "coords": dto.coords,
        "summary_embedding": dto.summary_embedding,
        "texto_cliente": dto.texto_cliente,
    }).execute()
    return {"case_id": case_id}

# --- endpoint: match --------------------------------------------------------
@app.post("/match")
def match(req: MatchRequest):
    # 1) carregar caso
    row = supabase.table("cases").select("*").eq("id", req.case_id).single().execute().data
    if not row:
        raise HTTPException(404, "case not found")
    case = Case(
        id=row["id"],
        area=row["area"],
        subarea=row["subarea"],
        urgency_h=row["urgency_h"],
        coords=tuple(row["coords"]),
        summary_embedding=np.array(row["summary_embedding"], dtype=np.float32),
    )

    # 2) carregar advogados da mesma área
    lw_rows = supabase.table("lawyers").select("*").contains("tags_expertise", [case.area]).execute().data
    candidates: list[Lawyer] = []
    for r in lw_rows:
        candidates.append(
            Lawyer(
                id=r["id"],
                nome=r["nome"],
                tags_expertise=r["tags_expertise"],
                geo_latlon=tuple(r["geo_latlon"]),
                curriculo_json=r["curriculo_json"],
                casos_historicos_embeddings=[np.array(v, dtype=np.float32) for v in r["historico_embeddings"]],
                kpi=KPI(**r["kpi"]),
            )
        )

    top = algo.rank(case, candidates, k=req.k)

    # 3) serializar resposta
    return {
        "case_id": case.id,
        "matches": [
            {
                "lawyer_id": lw.id,
                "nome": lw.nome,
                "score": lw.scores["fair"],
                "taxa_sucesso": lw.kpi.success_rate,
                "explain": f"{round(lw.scores['features']['A']*100)} % aderência • "
                           f"{round(lw.kpi.success_rate*100)} % êxito • "
                           f"equidade {round(lw.scores['equity']*100)} %",
            }
            for lw in top
        ],
    }
```

---

## 3 · `requirements.txt`

```
fastapi
uvicorn[standard]
numpy
supabase-py
```

Execute local:

```bash
uvicorn main:app --reload
```

---

## 4 · Ajustes no front-end React/Expo

* **POST `/cases`**  → envia texto+triagem (Claude) e recebe `case_id`.
* **POST `/match`**  → recebe lista ordenada de advogados.
* Renderize com o mesmo `MatchList` que já mostrei; não há lógica no cliente.

---

## 5 · Persistência extra

* **Tabela `lawyers`** precisa ter colunas `kpi` (JSON) e `historico_embeddings` (jsonb\[]).
* Atualize `kpi.cases_30d` e `kpi.last_offered` no banco dentro do FastAPI sempre que exibir um advogado - já está no algoritmo (`lw.kpi.last_offered = now`): basta fazer um UPDATE após `algo.rank`.

---

## 6 · Deploy em Render/Railway

`Dockerfile`

```dockerfile
FROM python:3.10-slim
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir -r requirements.txt
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Push para GitHub e vincule no Render → “Deploy”.

---

### Pronto!

Você tem:

1. **Algoritmo** em módulo separado (já no canvas).
2. **API REST** que chama esse algoritmo e conversa com Supabase.
3. **App React/Expo** consumindo `/cases` e `/match` via `fetch`.

