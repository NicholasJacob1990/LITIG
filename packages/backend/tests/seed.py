# backend/tests/seed.py
import logging
import os

from dotenv import load_dotenv

from supabase import Client, create_client

# --- Configuração ---
load_dotenv()
logging.basicConfig(level=logging.INFO)

# No ambiente de CI, estas vars virão do `env` do workflow
SUPABASE_URL = os.getenv("SUPABASE_URL", "http://localhost:5432")
# Use uma chave anon/pública segura para testes, nunca a de serviço
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY",
                         "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


def seed_database():
    """Popula o banco de dados de teste com dados iniciais."""
    try:
        logging.info("Iniciando o seeding do banco de dados de teste...")

        # --- Advogado de Teste ---
        lawyer_data = {
            "id": "e2e_lawyer_123",
            "nome": "Advogado de Teste E2E",
            "tags_expertise": ["Trabalhista", "Cível"],
            "geo_latlon": [-23.55, -46.63],
            "kpi": {
                "success_rate": 0.85,
                "cases_30d": 10,
                "capacidade_mensal": 20,
                "avaliacao_media": 4.8,
                "tempo_resposta_h": 8
            }
        }
        supabase.table("lawyers").upsert(lawyer_data).execute()
        logging.info(f"Advogado de teste semeado: {lawyer_data['id']}")

        # --- Caso de Teste ---
        case_data = {
            "id": "e2e_case_123",
            "area": "Trabalhista",
            "subarea": "Verbas Rescisórias",
            "urgency_h": 48,
            "coords": [-23.55, -46.63],
            "summary_embedding": [0.1] * 384  # Vetor de exemplo
        }
        supabase.table("cases").upsert(case_data).execute()
        logging.info(f"Caso de teste semeado: {case_data['id']}")

        logging.info("Seeding concluído com sucesso!")

    except Exception as e:
        logging.error(f"Falha no seeding do banco de dados: {e}")
        raise


if __name__ == "__main__":
    seed_database()
