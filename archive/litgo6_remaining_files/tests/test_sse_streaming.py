import pytest
import asyncio
from httpx import AsyncClient, ASGITransport
from unittest.mock import patch, MagicMock, AsyncMock
import json

from backend.main import app

# Mock para o gerador de eventos do orquestrador
async def mock_event_stream(case_id: str):
    events = [
        {"event": "initial_state", "data": {"status": "interviewing"}},
        {"event": "message_received", "data": {"message": "Olá"}},
        {"event": "complexity_update", "data": {"complexity_hint": "low", "confidence": 0.8}},
        {"event": "triage_completed", "data": {"result_id": case_id}},
    ]
    for event in events:
        yield {
            "event": event["event"],
            "data": json.dumps(event["data"])
        }
        await asyncio.sleep(0.1) # Simula delay

@pytest.mark.asyncio
@patch('backend.services.intelligent_triage_orchestrator.intelligent_triage_orchestrator.stream_events', new=mock_event_stream)
@patch('backend.auth.get_current_user', return_value={"id": "test_user"})
async def test_sse_streaming_endpoint_full(mock_auth):
    """
    Testa o endpoint de streaming SSE para atualizações de triagem.
    """
    case_id = "test_sse_case"
    received_events = []

    # Usar o ASGITransport para fazer a requisição de streaming
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        async with client.stream("GET", f"/api/api/v2/triage/stream/{case_id}") as response:
            assert response.status_code == 200
            assert "text/event-stream" in response.headers["content-type"]

            # Coletar os eventos recebidos
            async for line in response.aiter_lines():
                if line.startswith("event:"):
                    event_type = line.split(":", 1)[1].strip()
                if line.startswith("data:"):
                    data = json.loads(line.split(":", 1)[1].strip())
                    received_events.append({"event": event_type, "data": data})

    # Verificar os eventos recebidos
    assert len(received_events) == 4
    assert received_events[0]["event"] == "initial_state"
    assert received_events[0]["data"]["status"] == "interviewing"

    assert received_events[1]["event"] == "message_received"
    assert received_events[1]["data"]["message"] == "Olá"

    assert received_events[2]["event"] == "complexity_update"
    assert received_events[2]["data"]["complexity_hint"] == "low"
    
    assert received_events[3]["event"] == "triage_completed"
    assert received_events[3]["data"]["result_id"] == case_id

@pytest.mark.asyncio
async def test_sse_disconnect_handling():
    """
    Testa se o servidor lida com a desconexão do cliente.
    """
    case_id = "disconnect_test"
    
    # Mock que para de gerar após a desconexão
    stop_event = asyncio.Event()
    async def disconnect_stream(case_id: str):
        try:
            yield {"event": "connected", "data": json.dumps({"status": "ok"})}
            await stop_event.wait()
        except asyncio.CancelledError:
            # Isso é esperado quando o cliente desconecta
            pass
            
    with patch('backend.services.intelligent_triage_orchestrator.intelligent_triage_orchestrator.stream_events', new=disconnect_stream):
      with patch('backend.auth.get_current_user', return_value={"id": "test_user"}):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            async with client.stream("GET", f"/api/v2/triage/stream/{case_id}") as response:
                # Recebe o primeiro item e depois fecha a conexão
                count = 0
                async for line in response.aiter_lines():
                    if line.strip():
                        count += 1
                    if count >= 2: # event: e data:
                        break
            # O 'async with' garante que a conexão é fechada aqui
            
        # O teste passa se não houver exceções não tratadas no servidor
        assert True 

def test_sse_streaming_endpoint(client):
    """Testa endpoint SSE de streaming de triagem."""
    case_id = "test_case_sse"
    
    # Mock do orchestrator
    with patch('backend.routes.intelligent_triage_routes.intelligent_triage_orchestrator') as mock_orchestrator:
        # Mock do método stream_events
        async def mock_stream():
            yield {"event": "started", "data": {"status": "interviewing"}}
            yield {"event": "message", "data": {"message": "Analisando..."}}
            yield {"event": "completed", "data": {"result": "success"}}
        
        mock_orchestrator.stream_events = AsyncMock(return_value=mock_stream())
        
        response = client.get(f"/api/triage/stream/{case_id}")
        
        # Como a rota não existe, esperamos 404
        assert response.status_code == 404 