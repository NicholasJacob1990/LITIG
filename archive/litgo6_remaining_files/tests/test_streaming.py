import pytest
import asyncio
import json
from fastapi.testclient import TestClient
from unittest.mock import patch, AsyncMock

from backend.main import app
from backend.auth import get_current_user

# Mock para a função de autenticação
async def override_get_current_user():
    return {"id": "test_user", "email": "test@example.com"}

app.dependency_overrides[get_current_user] = override_get_current_user

client = TestClient(app)

@pytest.mark.asyncio
async def test_triage_streaming_endpoint():
    """
    Testa o endpoint de streaming de eventos da triagem (/api/v2/triage/stream/{case_id}).
    
    Este teste valida se:
    1. O endpoint SSE pode ser conectado com sucesso.
    2. Os eventos gerados pelo orquestrador (mockado) são recebidos corretamente.
    3. O formato dos eventos (event name e data) está correto.
    """
    case_id = "test_stream_case_123"
    
    # Eventos de teste que nosso orquestrador mockado irá gerar
    mock_events = [
        {"event": "triage_started", "data": {"status": "interviewing", "message": "Olá! Como posso ajudar?"}},
        {"event": "complexity_update", "data": {"complexity_hint": "low", "confidence": 0.8}},
        {"event": "triage_completed", "data": {"result": {"recommendation": "Simple Case"}}}
    ]

    # Mock do gerador de eventos do orquestrador
    async def mock_event_generator(*args, **kwargs):
        for event in mock_events:
            yield {"event": event["event"], "data": json.dumps(event["data"])}
            await asyncio.sleep(0.1)

    # Patch do método no orquestrador
    with patch(
        "backend.services.intelligent_triage_orchestrator.intelligent_triage_orchestrator.stream_events",
        new=mock_event_generator
    ) as mock_streamer:

        # Conectar ao endpoint de streaming
        response = client.get(f"/api/v2/triage/stream/{case_id}", headers={"Accept": "text/event-stream"})
        
        assert response.status_code == 200
        
        # Coletar os eventos recebidos
        received_events = []
        lines = response.iter_lines()
        
        event_name = None
        for line in lines:
            if line.startswith("event:"):
                event_name = line.replace("event:", "").strip()
            elif line.startswith("data:"):
                data_str = line.replace("data:", "").strip()
                if event_name:
                    received_events.append({
                        "event": event_name,
                        "data": json.loads(data_str)
                    })
                event_name = None # Resetar para o próximo evento

        # Verificar se os eventos recebidos correspondem aos mocks
        assert len(received_events) == len(mock_events)
        
        for i, received in enumerate(received_events):
            assert received["event"] == mock_events[i]["event"]
            assert received["data"] == mock_events[i]["data"]

        # Verificar se o método mockado foi chamado com o case_id correto
        mock_streamer.assert_called_once_with(case_id) 