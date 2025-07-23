# 📅 **PLANO DE INTEGRAÇÃO - API DE CALENDÁRIO UNIFICADO (UNIPILE)**

**Data**: 2025-01-04  
**Versão**: 1.0  
**Status**: 📝 **Em Planejamento**

---

## 🎯 **OBJETIVO**

Implementar uma funcionalidade de calendário unificado no LITIG-1, permitindo que os usuários (advogados e clientes) conectem suas contas Google Calendar e Outlook Calendar. A integração será feita através do SDK da Unipile para centralizar a visualização de eventos, agendamentos e disponibilidade.

### **Casos de Uso Principais**
1.  **Advogados**:
    *   Visualizar todos os compromissos (audiências, reuniões, prazos) em uma única interface.
    *   Compartilhar disponibilidade com clientes para agendamento rápido.
    *   Sincronizar eventos do LITIG-1 com seus calendários pessoais/profissionais.
2.  **Clientes**:
    *   Ver a disponibilidade do advogado e agendar consultas.
    *   Receber convites de eventos para reuniões e prazos importantes.
3.  **Sistema**:
    *   Automatizar o agendamento de reuniões com base na disponibilidade mútua.
    *   Enviar lembretes automáticos de eventos.

---

## 🔧 **IMPLEMENTAÇÃO TÉCNICA**

### **FASE 1: Extensão do Backend (Node.js + Python)**

#### **1.1 Adicionar Métodos de Calendário ao Node.js Service**
```javascript
// packages/backend/unipile_sdk_service.js - EXTENSÃO

/**
 * Recupera eventos de calendário de uma conta conectada.
 */
async getCalendarEvents(accountId, startDate, endDate) {
    try {
        const events = await this.client.calendar.getEvents({
            account_id: accountId,
            start_date: startDate, // Formato ISO 'YYYY-MM-DD'
            end_date: endDate,
        });
        
        return { success: true, data: events };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

/**
 * Cria um novo evento no calendário.
 */
async createCalendarEvent(accountId, eventData) {
    try {
        const newEvent = await this.client.calendar.createEvent({
            account_id: accountId,
            title: eventData.title,
            start_time: eventData.startTime, // Formato ISO 8601
            end_time: eventData.endTime,
            participants: eventData.participants, // [{ email: '...', name: '...' }]
            description: eventData.description,
        });

        return { success: true, data: newEvent };
    } catch (error) {
        return { success: false, error: error.message };
    }
}
```

#### **1.2 Atualizar CLI Interface (Node.js)**
```javascript
// Adicionar ao switch em unipile_sdk_service.js
case 'get-calendar-events':
    const [accountId_cal, startDate, endDate] = args;
    result = await service.getCalendarEvents(accountId_cal, startDate, endDate);
    break;
    
case 'create-calendar-event':
    const [accountId_event, eventDataJson] = args;
    result = await service.createCalendarEvent(accountId_event, JSON.parse(eventDataJson));
    break;
```

#### **1.3 Novos Métodos no Python Wrapper**
```python
# packages/backend/services/unipile_sdk_wrapper.py - EXTENSÃO

async def get_calendar_events(self, account_id: str, start_date: str, end_date: str) -> Optional[Dict[str, Any]]:
    """Recupera eventos de calendário."""
    try:
        result = await self._execute_node_command("get-calendar-events", account_id, start_date, end_date)
        return result.get("data") if result.get("success") else None
    except Exception as e:
        self.logger.error(f"Erro ao buscar eventos de calendário: {e}")
        return None

async def create_calendar_event(self, account_id: str, event_data: Dict) -> Optional[Dict[str, Any]]:
    """Cria um novo evento de calendário."""
    try:
        event_data_json = json.dumps(event_data)
        result = await self._execute_node_command("create-calendar-event", account_id, event_data_json)
        return result.get("data") if result.get("success") else None
    except Exception as e:
        self.logger.error(f"Erro ao criar evento de calendário: {e}")
        return None
```

### **FASE 2: Novos Endpoints de API (FastAPI)**

```python
# packages/backend/routes/calendar.py - NOVO ARQUIVO

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from backend.services.unipile_sdk_wrapper import UnipileSDKWrapper
from backend.auth import get_current_user

router = APIRouter(prefix="/api/v1/calendar", tags=["calendar"])

class CalendarEventParticipant(BaseModel):
    email: str
    name: Optional[str]

class CalendarEventRequest(BaseModel):
    title: str
    startTime: str # ISO 8601
    endTime: str # ISO 8601
    participants: List[CalendarEventParticipant]
    description: Optional[str]

# Nota: A conexão da conta (Google/Outlook) já é tratada pelo endpoint existente
# que lida com a conexão de contas de email, pois o escopo do calendário
# é solicitado durante o mesmo fluxo OAuth.

@router.get("/events")
async def get_events(
    start_date: str, 
    end_date: str,
    current_user = Depends(get_current_user)
):
    """Busca eventos do calendário do usuário."""
    unipile_wrapper = UnipileSDKWrapper()
    # Assume que a conta de email/calendário já está conectada
    account = await get_user_primary_account(current_user.id) # Função a ser implementada
    if not account:
        raise HTTPException(status_code=400, detail="Nenhuma conta de calendário conectada.")
    
    events = await unipile_wrapper.get_calendar_events(account['account_id'], start_date, end_date)
    if events is not None:
        return {"success": True, "events": events}
    raise HTTPException(status_code=500, detail="Falha ao buscar eventos.")

@router.post("/events")
async def create_event(
    request: CalendarEventRequest,
    current_user = Depends(get_current_user)
):
    """Cria um novo evento no calendário."""
    unipile_wrapper = UnipileSDKWrapper()
    account = await get_user_primary_account(current_user.id)
    if not account:
        raise HTTPException(status_code=400, detail="Nenhuma conta de calendário conectada.")

    event = await unipile_wrapper.create_calendar_event(account['account_id'], request.dict())
    if event:
        return {"success": True, "message": "Evento criado com sucesso", "event": event}
    raise HTTPException(status_code=500, detail="Falha ao criar evento.")
```

### **FASE 3: Implementação no Frontend (Flutter)**

#### **3.1 Calendar Service**
```dart
// apps/app_flutter/lib/src/core/services/calendar_service.dart - NOVO

import 'package:meu_app/src/core/services/dio_service.dart';

class CalendarService {
  static const String _baseUrl = '/api/v1/calendar';

  Future<List<dynamic>> getEvents(String startDate, String endDate) async {
    final response = await DioService.instance.get(
      '$_baseUrl/events',
      queryParameters: {'start_date': startDate, 'end_date': endDate},
    );
    return response.data['events'];
  }

  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> eventData) async {
    final response = await DioService.instance.post('$_baseUrl/events', data: eventData);
    return response.data;
  }
}
```

#### **3.2 Tela do Calendário Unificado**
- **Componentes**:
    - Utilizar o pacote `table_calendar` para a UI.
    - Exibir eventos de diferentes contas com cores distintas.
    - Permitir a criação de novos eventos através de um formulário modal.
- **Arquivo**: `apps/app_flutter/lib/src/features/calendar/presentation/screens/unified_calendar_screen.dart` (NOVO)
- **Estado (BLoC)**:
    - `CalendarBloc` para gerenciar o estado (loading, success, error).
    - Eventos: `LoadCalendarEvents`, `CreateCalendarEvent`.
    - Estados: `CalendarLoading`, `CalendarLoaded`, `CalendarError`.

---

## 🚀 **CRONOGRAMA ESTIMADO**

| **Fase** | **Atividade** | **Tempo** |
|----------|---------------|-----------|
| **Dia 1** | Backend: Extensão Node.js + Python | 1 dia |
| **Dia 2** | Backend: Endpoints API | 1 dia |
| **Dia 3-4** | Frontend: Calendar BLoC + Service | 2 dias |
| **Dia 5-6** | Frontend: UI com `table_calendar` | 2 dias |
| **Dia 7** | Integração e Testes | 1 dia |

**Total: 7 dias úteis**

---

## 🔒 **SEGURANÇA E ESCOPOS**

Durante o fluxo de conexão de contas Google e Outlook, os seguintes escopos de calendário devem ser solicitados:
- **Google**: `https://www.googleapis.com/auth/calendar.events`
- **Microsoft**: `Calendars.ReadWrite`

A gestão de tokens OAuth é de responsabilidade da Unipile, garantindo a segurança.

---

Este plano fornece um caminho claro para adicionar a funcionalidade de calendário, um dos pilares da visão de comunicação unificada. 