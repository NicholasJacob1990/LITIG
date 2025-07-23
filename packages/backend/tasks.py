# backend/tasks.py
import asyncio
import os
import uuid

from dotenv import load_dotenv

from backend.services.match_service import MatchRequest, find_and_notify_matches

# Importar os serviços necessários
from backend.services.triage_router_service import Strategy, triage_router_service
from supabase import Client, create_client

from celery_app import celery_app
from embedding_service import generate_embedding
from triage_service import triage_service
from utils.case_type_mapper import map_area_to_case_type

load_dotenv()

# --- Configuração do Cliente Supabase para o Worker ---
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")


def get_supabase_client() -> Client:
    """Cria e retorna um novo cliente Supabase."""
    if not all([SUPABASE_URL, SUPABASE_SERVICE_KEY]):
        raise ValueError("Variáveis de ambiente do Supabase não configuradas.")
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


async def _process_triage_and_match_flow(
        text: str, user_id: str, coords: tuple = None) -> dict:
    """
    Lógica de negócio completa: roteia, executa a triagem, salva o caso,
    e então aciona o serviço de match.
    """
    supabase = get_supabase_client()

    # 1. Roteamento Inteligente: Classifica a complexidade e define a estratégia
    strategy: Strategy = triage_router_service.classify_complexity(text)

    # 2. Executa a triagem com a estratégia definida
    triage_result = await triage_service.run_triage(text, strategy)

    # 2.5. Executa análise detalhada complementar
    detailed_analysis = await triage_service.run_detailed_analysis(text)

    # 3. Salva o caso no banco de dados
    case_id = str(uuid.uuid4())
    coords_to_save = coords or (-23.5505, -46.6333)
    
    # NOVO: Mapear área jurídica para tipo de caso
    area = triage_result.get("area")
    subarea = triage_result.get("subarea")
    keywords = triage_result.get("keywords", [])
    summary = triage_result.get("summary")
    # Tentar extrair natureza da análise detalhada se disponível
    nature = None
    if detailed_analysis and isinstance(detailed_analysis, dict):
        classificacao = detailed_analysis.get("classificacao", {})
        if isinstance(classificacao, dict):
            nature = classificacao.get("natureza")
    
    case_type = map_area_to_case_type(
        area=area,
        subarea=subarea,
        keywords=keywords,
        summary=summary,
        nature=nature
    )

    case_data = {
        "id": case_id,
        "user_id": user_id,
        "texto_cliente": text,
        "area": area,
        "subarea": subarea,
        "urgency_h": triage_result.get("urgency_h"),
        "summary": summary,
        "keywords": keywords,
        "sentiment": triage_result.get("sentiment"),
        "summary_embedding": triage_result.get("summary_embedding"),
        "detailed_analysis": detailed_analysis,
        "coords": coords_to_save,
        "status": "triage_completed",
        "case_type": case_type  # NOVO campo
    }

    insert_response = supabase.table("cases").insert(case_data).execute()

    if not insert_response.data:
        raise Exception(f"Falha ao inserir caso no Supabase: {insert_response.error}")

    print(f"Caso {case_id} salvo. Estratégia usada: {strategy}. Iniciando match.")

    # 4. Aciona o serviço de match
    # Criamos um objeto simples que simula o `MatchRequest` para o serviço
    match_request = MatchRequest(case_id=case_id, k=5, preset="balanced")
    await find_and_notify_matches(match_request)

    supabase.table("cases").update(
        {"status": "matching_completed"}).eq("id", case_id).execute()

    print(f"Processo de match para o caso {case_id} concluído.")

    return {"case_id": case_id, "status": "matching_completed"}


@celery_app.task(name="tasks.run_full_triage_flow")
def run_full_triage_flow_task(text: str, user_id: str, coords: tuple = None):
    """
    Tarefa Celery que executa o fluxo completo de triagem e match de forma assíncrona.
    """
    print(f"Iniciando fluxo completo de triagem para usuário {user_id}...")
    try:
        result = asyncio.run(_process_triage_and_match_flow(text, user_id, coords))
        print(f"Fluxo completo concluído. Caso ID: {result['case_id']}")
        return {"status": "completed", "result": result}
    except Exception as e:
        print(f"Erro na tarefa de triagem e match: {e}")
        return {"status": "failed", "error": str(e)}


# Funções síncronas "wrappers" para serem usadas pela tarefa Celery
# Em um cenário real, seria melhor usar `asyncio.run` ou refatorar os serviços
# para terem métodos síncronos e assíncronos.


def triage_service_sync_wrapper(text):
    return asyncio.run(triage_service.run_triage(text))


def generate_embedding_sync_wrapper(text):
    return asyncio.run(generate_embedding(text))


# Re-atribuição para clareza
triage_service.run_triage_sync = triage_service_sync_wrapper
generate_embedding_sync = generate_embedding_sync_wrapper
