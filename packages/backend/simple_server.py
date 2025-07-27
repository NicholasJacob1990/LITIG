from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime, timedelta
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

# Endpoint de validação de role
@app.get("/api/auth/validate-role")
async def validate_role():
    return {
        "valid_roles": [
            # Tipos atualizados
            "client_pf",              # Cliente Pessoa Física
            "client_pj",              # Cliente Pessoa Jurídica
            "lawyer_individual",      # Advogado Individual
            "lawyer_firm_member",     # Advogado Associado a Escritório
            "firm",                   # Escritório de Advocacia
            "super_associate",        # Super Associado
            "admin",                  # Administrador
            
            # Tipos legados (compatibilidade)
            "client",                 # LEGACY: será migrado para client_pf/client_pj
            "lawyer",                 # LEGACY: será migrado para lawyer_individual
            "lawyer_associated",      # LEGACY: será migrado para lawyer_firm_member
            "lawyer_platform_associate"  # LEGACY: vira super_associate
        ],
        "message": "Roles válidos no sistema"
    }

@app.post("/api/v2/triage/start")
async def triage_start():
    return {
        "case_id": "temp-case-123",
        "status": "interviewing",
        "message": "Olá! Vou te ajudar a entender melhor seu caso. Pode me contar o que aconteceu?"
    }

@app.post("/api/v2/triage/message")
async def triage_message():
    return {
        "case_id": "temp-case-123",
        "message": "Entendi. Pode me dar mais detalhes sobre quando isso aconteceu?",
        "status": "interviewing"
    }

# Endpoints de casos
@app.get("/api/cases/my-cases")
async def get_my_cases():
    return [
        {
            "id": "case-123",
            "title": "Caso de Exemplo 1",
            "description": "Descrição do caso de exemplo",
            "status": "pending_assignment",
            "area": "Direito Trabalhista",
            "created_at": "2025-01-13T10:00:00Z",
            "client_name": "João Silva",
            "priority": "medium",
            "urgency_hours": 48
        },
        {
            "id": "case-456", 
            "title": "Caso de Exemplo 2",
            "description": "Outro caso de exemplo",
            "status": "in_progress",
            "area": "Direito Civil",
            "created_at": "2025-01-12T14:30:00Z",
            "client_name": "Maria Santos",
            "priority": "high",
            "urgency_hours": 24
        }
    ]

@app.get("/api/cases/{case_id}")
async def get_case_details(case_id: str):
    return {
        "id": case_id,
        "title": f"Detalhes do Caso {case_id}",
        "description": "Descrição detalhada do caso",
        "status": "pending_assignment",
        "area": "Direito Trabalhista",
        "created_at": "2025-01-13T10:00:00Z",
        "client_name": "João Silva",
        "priority": "medium",
        "urgency_hours": 48,
        "ai_analysis": {
            "complexity": "medium",
            "estimated_duration": "2-3 meses",
            "success_probability": 0.75
        }
    }

# Endpoints de ofertas
@app.get("/api/offers/pending")
async def get_pending_offers():
    return [
        {
            "id": "offer-1",
            "case_id": "case-123",
            "case_title": "Caso Trabalhista - Horas Extras",
            "case_description": "Cliente busca receber horas extras não pagas",
            "case_area": "Direito Trabalhista",
            "client_name": "João Silva",
            "client_choice_order": 1,
            "status": "pending",
            "created_at": "2025-01-13T10:00:00Z",
            "expires_at": "2025-01-20T10:00:00Z",
            "offer_details": {
                "urgency": "medium",
                "estimated_value": 15000.00,
                "complexity": "medium"
            }
        },
        {
            "id": "offer-2",
            "case_id": "case-456",
            "case_title": "Revisão de Contrato",
            "case_description": "Análise de contrato de prestação de serviços",
            "case_area": "Direito Civil",
            "client_name": "Maria Santos",
            "client_choice_order": 2,
            "status": "pending",
            "created_at": "2025-01-13T11:00:00Z",
            "expires_at": "2025-01-20T11:00:00Z",
            "offer_details": {
                "urgency": "high",
                "estimated_value": 8000.00,
                "complexity": "low"
            }
        }
    ]

@app.patch("/api/offers/{offer_id}/accept")
async def accept_offer(offer_id: str):
    return {
        "id": offer_id,
        "status": "accepted",
        "message": "Oferta aceita com sucesso!",
        "accepted_at": datetime.now().isoformat()
    }

@app.patch("/api/offers/{offer_id}/reject")
async def reject_offer(offer_id: str):
    return {
        "id": offer_id,
        "status": "rejected", 
        "message": "Oferta rejeitada",
        "rejected_at": datetime.now().isoformat()
    }

@app.get("/api/offers/stats")
async def get_offer_stats():
    return {
        "total_offers": 25,
        "pending_offers": 2,
        "accepted_offers": 18,
        "rejected_offers": 5,
        "acceptance_rate": 0.78,
        "avg_response_time_hours": 4.2
    }

# Endpoint para contratos de associação (Super Associados)
@app.get("/api/platform/contracts")
async def get_platform_contracts():
    return [
        {
            "id": "contract-1",
            "title": "Contrato de Associação - Plataforma LITIG",
            "type": "association",
            "version": "1.0",
            "description": "Contrato para Super Associados da Plataforma LITIG",
            "requires_signature": True,
            "is_active": True,
            "created_at": "2025-01-13T10:00:00Z"
        }
    ]

@app.post("/api/platform/contracts/{contract_id}/sign")
async def sign_platform_contract(contract_id: str):
    return {
        "contract_id": contract_id,
        "signed_at": datetime.now().isoformat(),
        "status": "signed",
        "message": "Contrato assinado com sucesso!"
    }

# Endpoints para ativação de perfil
@app.get("/api/platform/activation-status/{user_id}")
async def get_activation_status(user_id: str):
    return {
        "user_id": user_id,
        "is_active": True,
        "contract_signed": True,
        "activated_at": datetime.now().isoformat(),
        "status": "active"
    }

@app.post("/api/platform/activate-profile")
async def activate_profile():
    return {
        "user_id": "temp-user-123",
        "status": "activated",
        "activated_at": datetime.now().isoformat(),
        "message": "Perfil ativado com sucesso!",
        "can_receive_offers": True
    }

# Endpoint para buscar advogados elegíveis (incluindo Super Associados)
@app.get("/api/lawyers/eligible")
async def get_eligible_lawyers():
    return [
        {
            "id": "lawyer-1",
            "name": "Dr. João Advogado",
            "role": "lawyer_individual",
            "specialties": ["Direito Trabalhista", "Direito Civil"],
            "rating": 4.5,
            "is_available": True,
            "is_platform_associate": False
        },
        {
            "id": "lawyer-2", 
            "name": "Dra. Maria Especialista",
            "role": "lawyer_platform_associate",
            "specialties": ["Direito Trabalhista", "Direito Previdenciário"],
            "rating": 4.8,
            "is_available": True,
            "is_platform_associate": True,
            "contract_signed": True
        }
    ]

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080) 