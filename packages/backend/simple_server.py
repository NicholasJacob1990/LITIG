from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

app = FastAPI()

# Configurar CORS para desenvolvimento
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permite todas as origens em desenvolvimento
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"status": "ok", "message": "Servidor temporário rodando!"}

@app.post("/api/v2/triage/start")
async def triage_start():
    return {
        "case_id": "temp-case-123",
        "status": "interviewing",
        "message": "Olá! Vou te ajudar a entender melhor seu caso. Pode me contar o que aconteceu?"
    }

@app.post("/api/v2/triage/continue")
async def triage_continue():
    return {
        "status": "completed",
        "message": "Entendi seu caso! Analisando a situação, parece ser uma questão trabalhista. Vou gerar um relatório para você. [END_OF_TRIAGE]"
    }

@app.get("/api/v2/triage/status/{task_id}")
async def triage_status(task_id: str):
    return {
        "status": "completed",
        "result": {
            "case_id": "temp-case-123",
            "area": "Trabalhista",
            "subarea": "Rescisão",
            "urgency_h": 48
        }
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000) 