#!/usr/bin/env python3
"""
Servidor de teste simples para verificar a integração Unipile
"""

import asyncio
import os
import sys
from pathlib import Path

# Adicionar o diretório atual ao path
sys.path.insert(0, str(Path(__file__).parent))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Importar apenas o wrapper Unipile
from services.unipile_sdk_wrapper import UnipileSDKWrapper

app = FastAPI(
    title="LITIG-1 Test Server",
    description="Servidor de teste para verificar integração Unipile",
    version="1.0.0"
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    """Endpoint raiz"""
    return {
        "status": "ok", 
        "message": "LITIG-1 Test Server - Integração Unipile",
        "version": "1.0.0"
    }

@app.get("/health")
async def health():
    """Health check"""
    return {
        "status": "healthy",
        "services": {
            "unipile": "available"
        }
    }

@app.get("/unipile/test")
async def test_unipile():
    """Teste da integração Unipile"""
    try:
        wrapper = UnipileSDKWrapper()
        
        # Testar health check
        health_result = await wrapper.health_check_calendar()
        
        return {
            "success": True,
            "message": "Integração Unipile testada com sucesso",
            "health_check": health_result,
            "sdk_version": "4.1"
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "message": "Erro ao testar integração Unipile"
        }

@app.get("/unipile/accounts")
async def list_unipile_accounts():
    """Listar contas Unipile"""
    try:
        wrapper = UnipileSDKWrapper()
        accounts = await wrapper.list_accounts()
        
        return {
            "success": True,
            "accounts": [
                {
                    "id": acc.id,
                    "provider": acc.provider,
                    "email": acc.email,
                    "status": acc.status
                }
                for acc in accounts
            ],
            "total": len(accounts)
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "message": "Erro ao listar contas Unipile"
        }

if __name__ == "__main__":
    import uvicorn
    print("🚀 Iniciando servidor de teste LITIG-1...")
    print("📡 Endpoints disponíveis:")
    print("   - GET / - Status do servidor")
    print("   - GET /health - Health check")
    print("   - GET /unipile/test - Teste da integração Unipile")
    print("   - GET /unipile/accounts - Listar contas Unipile")
    print("🌐 Servidor rodando em: http://localhost:8002")
    
    uvicorn.run(app, host="0.0.0.0", port=8002) 