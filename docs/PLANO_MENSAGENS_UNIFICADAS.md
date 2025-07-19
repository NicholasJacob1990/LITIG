# 📋 PLANO COMPLETO: INTEGRAÇÃO DE MENSAGENS UNIFICADAS

## **🎯 OBJETIVO ESTRATÉGICO**

Criar uma **caixa de entrada unificada** que consolide mensagens de todas as plataformas em um único chat, eliminando a necessidade de alternar entre aplicativos e mantendo histórico centralizado.

---

## **🏗️ ARQUITETURA PROPOSTA**

### **📱 Frontend Flutter**
```
┌─────────────────────────────────┐
│ 🎯 Chat Unificado              │
├─────────────────────────────────┤
│ 📧 Gmail/Outlook               │
│ 💼 LinkedIn Messages           │
│ 📸 Instagram DMs               │
│ 📱 WhatsApp Business           │
│ 📅 Google/Outlook Calendar     │
└─────────────────────────────────┘
```

### **🔧 Backend FastAPI + Unipile**
```
┌─────────────────────────────────┐
│ 🚀 API Gateway                 │
├─────────────────────────────────┤
│ 📡 Unipile SDK Integration     │
│ 🔄 Webhook Handlers            │
│ 💾 Message Storage             │
│ 🔐 OAuth Management            │
└─────────────────────────────────┘
```

---

## **📋 FASE 1: INFRAESTRUTURA BASE**

### **1.1 Configuração Unipile SDK**

#### **Backend - Serviço de Mensagens Unificadas**
```python
# packages/backend/services/unified_messaging_service.py
from unipile_node_sdk import UnipileClient
import asyncio
from typing import Dict, List, Optional

class UnifiedMessagingService:
    def __init__(self):
        self.client = UnipileClient(
            base_url="https://api.unipile.com",
            access_token=os.getenv("UNIPILE_API_TOKEN")
        )
    
    async def connect_account(self, provider: str, credentials: Dict):
        """Conecta conta de qualquer provedor"""
        try:
            if provider == "LINKEDIN":
                return await self.client.account.connectLinkedin(credentials)
            elif provider == "INSTAGRAM":
                return await self.client.account.connectInstagram(credentials)
            elif provider == "WHATSAPP":
                return await self.client.account.connectWhatsapp(credentials)
            elif provider == "GMAIL":
                return await self.client.account.connectGmail(credentials)
            elif provider == "OUTLOOK":
                return await self.client.account.connectOutlook(credentials)
        except Exception as e:
            raise Exception(f"Erro ao conectar {provider}: {str(e)}")
    
    async def get_all_chats(self, account_id: str):
        """Lista todos os chats de uma conta"""
        return await self.client.messaging.getAllChats(account_id=account_id)
    
    async def get_chat_messages(self, chat_id: str):
        """Recupera mensagens de um chat específico"""
        return await self.client.messaging.getAllMessagesFromChat(chat_id=chat_id)
    
    async def send_message(self, chat_id: str, message: str, attachments: List = None):
        """Envia mensagem para um chat"""
        return await self.client.messaging.sendMessage(
            chat_id=chat_id,
            message=message,
            attachments=attachments
        )
```

#### **Database Schema - Mensagens Unificadas**
```sql
-- packages/backend/migrations/014_create_unified_messages_tables.sql

-- Tabela de contas conectadas
CREATE TABLE user_connected_accounts (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    provider VARCHAR(50) NOT NULL, -- 'linkedin', 'instagram', 'whatsapp', 'gmail', 'outlook'
    account_id VARCHAR(255) NOT NULL,
    account_name VARCHAR(255),
    account_email VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    last_sync_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, provider, account_id)
);

-- Tabela de chats unificados
CREATE TABLE unified_chats (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    provider VARCHAR(50) NOT NULL,
    provider_chat_id VARCHAR(255) NOT NULL,
    chat_name VARCHAR(255),
    chat_type VARCHAR(50), -- 'direct', 'group', 'channel'
    last_message_at TIMESTAMP,
    unread_count INTEGER DEFAULT 0,
    is_archived BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, provider, provider_chat_id)
);

-- Tabela de mensagens unificadas
CREATE TABLE unified_messages (
    id SERIAL PRIMARY KEY,
    chat_id INTEGER REFERENCES unified_chats(id),
    provider_message_id VARCHAR(255) NOT NULL,
    sender_id VARCHAR(255),
    sender_name VARCHAR(255),
    sender_email VARCHAR(255),
    message_type VARCHAR(50), -- 'text', 'image', 'video', 'file', 'audio'
    content TEXT,
    attachments JSONB,
    is_outgoing BOOLEAN DEFAULT false,
    is_read BOOLEAN DEFAULT false,
    sent_at TIMESTAMP,
    received_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(chat_id, provider_message_id)
);

-- Tabela de calendários
CREATE TABLE user_calendars (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    provider VARCHAR(50) NOT NULL, -- 'google', 'outlook'
    calendar_id VARCHAR(255) NOT NULL,
    calendar_name VARCHAR(255),
    is_primary BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    last_sync_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, provider, calendar_id)
);

-- Índices para performance
CREATE INDEX idx_unified_messages_chat_id ON unified_messages(chat_id);
CREATE INDEX idx_unified_messages_sent_at ON unified_messages(sent_at);
CREATE INDEX idx_unified_chats_user_id ON unified_chats(user_id);
CREATE INDEX idx_user_connected_accounts_user_id ON user_connected_accounts(user_id);
```

### **1.2 Rotas FastAPI para Mensagens**

#### **Endpoints de Conexão**
```python
# packages/backend/routes/unified_messaging.py
from fastapi import APIRouter, Depends, HTTPException
from typing import List, Dict

router = APIRouter(prefix="/api/v1/messaging", tags=["Unified Messaging"])

@router.post("/connect/{provider}")
async def connect_account(
    provider: str,
    credentials: Dict,
    current_user: User = Depends(get_current_user)
):
    """Conecta conta de mensagens"""
    try:
        service = UnifiedMessagingService()
        result = await service.connect_account(provider.upper(), credentials)
        
        # Salva no banco
        await save_connected_account(current_user.id, provider, result)
        
        return {"success": True, "account_id": result.get("account_id")}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/accounts")
async def list_connected_accounts(
    current_user: User = Depends(get_current_user)
):
    """Lista contas conectadas do usuário"""
    accounts = await get_user_connected_accounts(current_user.id)
    return {"accounts": accounts}

@router.get("/chats")
async def list_unified_chats(
    current_user: User = Depends(get_current_user),
    provider: Optional[str] = None
):
    """Lista todos os chats unificados"""
    chats = await get_user_unified_chats(current_user.id, provider)
    return {"chats": chats}

@router.get("/chats/{chat_id}/messages")
async def get_chat_messages(
    chat_id: int,
    current_user: User = Depends(get_current_user),
    limit: int = 50,
    offset: int = 0
):
    """Recupera mensagens de um chat"""
    messages = await get_chat_messages(chat_id, limit, offset)
    return {"messages": messages}

@router.post("/chats/{chat_id}/send")
async def send_message(
    chat_id: int,
    message: Dict,
    current_user: User = Depends(get_current_user)
):
    """Envia mensagem para um chat"""
    try:
        service = UnifiedMessagingService()
        result = await service.send_message(
            chat_id=chat_id,
            message=message["content"],
            attachments=message.get("attachments", [])
        )
        return {"success": True, "message_id": result.get("message_id")}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
```

---

## **📋 FASE 2: FRONTEND FLUTTER**

### **2.1 Tela de Chat Unificado**

#### **Widget Principal**
```dart
// apps/app_flutter/lib/src/features/messaging/presentation/screens/unified_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UnifiedChatScreen extends StatefulWidget {
  final int chatId;
  final String chatName;
  final String provider;
  
  const UnifiedChatScreen({
    Key? key,
    required this.chatId,
    required this.chatName,
    required this.provider,
  }) : super(key: key);

  @override
  State<UnifiedChatScreen> createState() => _UnifiedChatScreenState();
}

class _UnifiedChatScreenState extends State<UnifiedChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _buildProviderIcon(widget.provider),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.chatName),
                  Text(
                    _getProviderName(widget.provider),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showChatOptions(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<UnifiedChatBloc, UnifiedChatState>(
              builder: (context, state) {
                if (state is UnifiedChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state is UnifiedChatLoaded) {
                  return _buildMessageList(state.messages);
                }
                
                return const Center(child: Text('Nenhuma mensagem'));
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildProviderIcon(String provider) {
    IconData iconData;
    Color iconColor;
    
    switch (provider.toLowerCase()) {
      case 'linkedin':
        iconData = Icons.business;
        iconColor = const Color(0xFF0077B5);
        break;
      case 'instagram':
        iconData = Icons.camera_alt;
        iconColor = const Color(0xFFE4405F);
        break;
      case 'whatsapp':
        iconData = Icons.whatsapp;
        iconColor = const Color(0xFF25D366);
        break;
      case 'gmail':
        iconData = Icons.email;
        iconColor = const Color(0xFFEA4335);
        break;
      case 'outlook':
        iconData = Icons.email_outlined;
        iconColor = const Color(0xFF0078D4);
        break;
      default:
        iconData = Icons.message;
        iconColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  Widget _buildMessageList(List<UnifiedMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(UnifiedMessage message) {
    final isOutgoing = message.isOutgoing;
    
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOutgoing 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOutgoing 
              ? Colors.transparent
              : Theme.of(context).dividerColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOutgoing) ...[
              Text(
                message.senderName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.content,
              style: TextStyle(
                color: isOutgoing ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.sentAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isOutgoing ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () => _showAttachmentOptions(),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Digite sua mensagem...',
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendMessage(),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    context.read<UnifiedChatBloc>().add(
      SendMessageRequested(
        chatId: widget.chatId,
        content: _messageController.text.trim(),
      ),
    );
    
    _messageController.clear();
  }
}
```

### **2.2 Lista de Chats Unificados**

#### **Tela Principal**
```dart
// apps/app_flutter/lib/src/features/messaging/presentation/screens/unified_chats_screen.dart
class UnifiedChatsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensagens Unificadas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showConnectAccountDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<UnifiedChatsBloc, UnifiedChatsState>(
        builder: (context, state) {
          if (state is UnifiedChatsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is UnifiedChatsLoaded) {
            return _buildChatsList(state.chats);
          }
          
          return const Center(child: Text('Nenhum chat encontrado'));
        },
      ),
    );
  }

  Widget _buildChatsList(List<UnifiedChat> chats) {
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return _buildChatTile(chat);
      },
    );
  }

  Widget _buildChatTile(UnifiedChat chat) {
    return ListTile(
      leading: _buildProviderAvatar(chat.provider),
      title: Text(chat.chatName),
      subtitle: Text(
        chat.lastMessage ?? 'Nenhuma mensagem',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTimestamp(chat.lastMessageAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (chat.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
      onTap: () => _openChat(context, chat),
    );
  }
}
```

---

## **📋 FASE 3: WEBHOOKS E SINCRONIZAÇÃO**

### **3.1 Webhook Handlers**

#### **Endpoint para Receber Mensagens**
```python
# packages/backend/routes/webhooks.py
from fastapi import APIRouter, Request, HTTPException
import json

router = APIRouter(prefix="/api/v1/webhooks", tags=["Webhooks"])

@router.post("/unipile/messages")
async def handle_unipile_message_webhook(request: Request):
    """Recebe webhooks da Unipile para novas mensagens"""
    try:
        payload = await request.json()
        
        # Processa diferentes tipos de eventos
        event_type = payload.get("type")
        
        if event_type == "message_received":
            await process_new_message(payload)
        elif event_type == "message_sent":
            await process_sent_message(payload)
        elif event_type == "message_read":
            await process_message_read(payload)
        
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

async def process_new_message(payload: Dict):
    """Processa nova mensagem recebida"""
    message_data = payload.get("data", {})
    
    # Salva mensagem no banco
    await save_unified_message(
        chat_id=message_data.get("chat_id"),
        provider_message_id=message_data.get("message_id"),
        sender_id=message_data.get("sender_id"),
        sender_name=message_data.get("sender_name"),
        content=message_data.get("content"),
        message_type=message_data.get("type", "text"),
        is_outgoing=False,
        sent_at=message_data.get("timestamp")
    )
    
    # Atualiza contador de não lidas
    await update_chat_unread_count(message_data.get("chat_id"))
    
    # Envia notificação push se necessário
    await send_push_notification(message_data)

async def process_sent_message(payload: Dict):
    """Processa mensagem enviada"""
    message_data = payload.get("data", {})
    
    await save_unified_message(
        chat_id=message_data.get("chat_id"),
        provider_message_id=message_data.get("message_id"),
        content=message_data.get("content"),
        message_type=message_data.get("type", "text"),
        is_outgoing=True,
        sent_at=message_data.get("timestamp")
    )
```

### **3.2 Sincronização em Tempo Real**

#### **Service de Sincronização**
```python
# packages/backend/services/message_sync_service.py
import asyncio
from datetime import datetime, timedelta

class MessageSyncService:
    def __init__(self):
        self.unified_service = UnifiedMessagingService()
    
    async def sync_all_accounts(self, user_id: str):
        """Sincroniza mensagens de todas as contas do usuário"""
        accounts = await get_user_connected_accounts(user_id)
        
        for account in accounts:
            if account["is_active"]:
                await self.sync_account_messages(account)
    
    async def sync_account_messages(self, account: Dict):
        """Sincroniza mensagens de uma conta específica"""
        try:
            # Lista todos os chats
            chats = await self.unified_service.get_all_chats(account["account_id"])
            
            for chat in chats:
                # Salva/atualiza chat no banco
                chat_id = await save_or_update_chat(account["user_id"], chat)
                
                # Sincroniza mensagens do chat
                await self.sync_chat_messages(chat_id, chat["id"])
                
        except Exception as e:
            logger.error(f"Erro ao sincronizar conta {account['id']}: {str(e)}")
    
    async def sync_chat_messages(self, db_chat_id: int, provider_chat_id: str):
        """Sincroniza mensagens de um chat específico"""
        try:
            # Busca última mensagem sincronizada
            last_message = await get_last_synced_message(db_chat_id)
            
            # Busca mensagens mais recentes
            messages = await self.unified_service.get_chat_messages(
                provider_chat_id,
                since=last_message.sent_at if last_message else None
            )
            
            # Salva novas mensagens
            for message in messages:
                await save_unified_message(
                    chat_id=db_chat_id,
                    provider_message_id=message["id"],
                    sender_id=message.get("sender_id"),
                    sender_name=message.get("sender_name"),
                    content=message["content"],
                    message_type=message.get("type", "text"),
                    is_outgoing=message.get("is_outgoing", False),
                    sent_at=message["timestamp"]
                )
                
        except Exception as e:
            logger.error(f"Erro ao sincronizar chat {db_chat_id}: {str(e)}")
```

---

## **📋 FASE 4: CALENDÁRIOS INTEGRADOS**

### **4.1 Serviço de Calendário**

#### **Integração Google/Outlook Calendar**
```python
# packages/backend/services/calendar_service.py
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from datetime import datetime, timedelta

class CalendarService:
    def __init__(self):
        self.unified_service = UnifiedMessagingService()
    
    async def connect_google_calendar(self, user_id: str, credentials: Dict):
        """Conecta calendário do Google"""
        try:
            # Conecta via Unipile
            result = await self.unified_service.connect_account("GOOGLE", credentials)
            
            # Salva no banco
            await save_user_calendar(
                user_id=user_id,
                provider="google",
                calendar_id=result["account_id"],
                calendar_name="Google Calendar"
            )
            
            return result
        except Exception as e:
            raise Exception(f"Erro ao conectar Google Calendar: {str(e)}")
    
    async def connect_outlook_calendar(self, user_id: str, credentials: Dict):
        """Conecta calendário do Outlook"""
        try:
            result = await self.unified_service.connect_account("OUTLOOK", credentials)
            
            await save_user_calendar(
                user_id=user_id,
                provider="outlook",
                calendar_id=result["account_id"],
                calendar_name="Outlook Calendar"
            )
            
            return result
        except Exception as e:
            raise Exception(f"Erro ao conectar Outlook Calendar: {str(e)}")
    
    async def get_calendar_events(self, user_id: str, start_date: datetime, end_date: datetime):
        """Busca eventos de todos os calendários do usuário"""
        calendars = await get_user_calendars(user_id)
        all_events = []
        
        for calendar in calendars:
            events = await self.get_provider_events(
                calendar["provider"],
                calendar["calendar_id"],
                start_date,
                end_date
            )
            all_events.extend(events)
        
        return sorted(all_events, key=lambda x: x["start_time"])
    
    async def create_calendar_event(self, user_id: str, event_data: Dict):
        """Cria evento em calendário"""
        calendar = await get_primary_calendar(user_id)
        
        if not calendar:
            raise Exception("Nenhum calendário primário configurado")
        
        return await self.create_provider_event(
            calendar["provider"],
            calendar["calendar_id"],
            event_data
        )
```

### **4.2 Widget de Calendário no Flutter**

#### **Tela de Calendário Integrado**
```dart
// apps/app_flutter/lib/src/features/calendar/presentation/screens/unified_calendar_screen.dart
class UnifiedCalendarScreen extends StatefulWidget {
  @override
  State<UnifiedCalendarScreen> createState() => _UnifiedCalendarScreenState();
}

class _UnifiedCalendarScreenState extends State<UnifiedCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  List<CalendarEvent> _events = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário Unificado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateEventDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendarHeader(),
          Expanded(
            child: _buildEventsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _previousMonth(),
          ),
          Text(
            _formatMonthYear(_selectedDate),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _nextMonth(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        if (state is CalendarLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is CalendarLoaded) {
          return ListView.builder(
            itemCount: state.events.length,
            itemBuilder: (context, index) {
              final event = state.events[index];
              return _buildEventTile(event);
            },
          );
        }
        
        return const Center(child: Text('Nenhum evento encontrado'));
      },
    );
  }

  Widget _buildEventTile(CalendarEvent event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildProviderIcon(event.provider),
        title: Text(event.title),
        subtitle: Text(
          '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showEventOptions(event),
        ),
        onTap: () => _openEventDetails(event),
      ),
    );
  }
}
```

---

## **📋 FASE 5: NOTIFICAÇÕES E PUSH**

### **5.1 Sistema de Notificações**

#### **Service de Notificações**
```python
# packages/backend/services/notification_service.py
import asyncio
from typing import Dict, List

class NotificationService:
    def __init__(self):
        self.expo_client = ExpoPushClient()
    
    async def send_message_notification(self, user_id: str, message_data: Dict):
        """Envia notificação de nova mensagem"""
        try:
            # Busca tokens do usuário
            tokens = await get_user_push_tokens(user_id)
            
            if not tokens:
                return
            
            # Cria notificação
            notification = {
                "title": f"Nova mensagem de {message_data['sender_name']}",
                "body": message_data["content"][:100] + "..." if len(message_data["content"]) > 100 else message_data["content"],
                "data": {
                    "type": "new_message",
                    "chat_id": message_data["chat_id"],
                    "provider": message_data["provider"]
                }
            }
            
            # Envia para todos os dispositivos
            for token in tokens:
                await self.expo_client.send_notification(token, notification)
                
        except Exception as e:
            logger.error(f"Erro ao enviar notificação: {str(e)}")
    
    async def send_calendar_reminder(self, user_id: str, event_data: Dict):
        """Envia lembrança de evento"""
        try:
            tokens = await get_user_push_tokens(user_id)
            
            notification = {
                "title": f"Lembrete: {event_data['title']}",
                "body": f"Evento em {event_data['start_time'].strftime('%H:%M')}",
                "data": {
                    "type": "calendar_reminder",
                    "event_id": event_data["id"]
                }
            }
            
            for token in tokens:
                await self.expo_client.send_notification(token, notification)
                
        except Exception as e:
            logger.error(f"Erro ao enviar lembrança: {str(e)}")
```

---

## **📋 FASE 6: TESTES E VALIDAÇÃO**

### **6.1 Testes de Integração**

#### **Testes de Mensagens**
```python
# packages/backend/tests/test_unified_messaging.py
import pytest
from unittest.mock import Mock, patch

class TestUnifiedMessaging:
    
    @pytest.mark.asyncio
    async def test_connect_linkedin_account(self):
        """Testa conexão de conta LinkedIn"""
        with patch('services.unified_messaging_service.UnipileClient') as mock_client:
            mock_client.return_value.account.connectLinkedin.return_value = {
                "account_id": "test_account_123"
            }
            
            service = UnifiedMessagingService()
            result = await service.connect_account("LINKEDIN", {
                "username": "test@email.com",
                "password": "test_password"
            })
            
            assert result["account_id"] == "test_account_123"
    
    @pytest.mark.asyncio
    async def test_send_message(self):
        """Testa envio de mensagem"""
        with patch('services.unified_messaging_service.UnipileClient') as mock_client:
            mock_client.return_value.messaging.sendMessage.return_value = {
                "message_id": "msg_123"
            }
            
            service = UnifiedMessagingService()
            result = await service.send_message(
                chat_id="chat_123",
                message="Test message",
                attachments=[]
            )
            
            assert result["message_id"] == "msg_123"
```

### **6.2 Testes de Frontend**

#### **Testes de Widgets**
```dart
// apps/app_flutter/test/features/messaging/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  group('UnifiedChatScreen Tests', () {
    testWidgets('should display message list', (WidgetTester tester) async {
      // Arrange
      final mockMessages = [
        UnifiedMessage(
          id: 1,
          content: 'Test message',
          senderName: 'John Doe',
          isOutgoing: false,
          sentAt: DateTime.now(),
        ),
      ];
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => UnifiedChatBloc()..add(
              LoadChatMessages(chatId: 1)
            ),
            child: UnifiedChatScreen(
              chatId: 1,
              chatName: 'Test Chat',
              provider: 'linkedin',
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Test message'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });
    
    testWidgets('should send message when send button pressed', (WidgetTester tester) async {
      // Arrange
      final mockBloc = MockUnifiedChatBloc();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: mockBloc,
            child: UnifiedChatScreen(
              chatId: 1,
              chatName: 'Test Chat',
              provider: 'linkedin',
            ),
          ),
        ),
      );
      
      await tester.enterText(find.byType(TextField), 'New message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      
      // Assert
      verify(mockBloc.add(SendMessageRequested(
        chatId: 1,
        content: 'New message',
      ))).called(1);
    });
  });
}
```

---

## **📋 CRONOGRAMA DE IMPLEMENTAÇÃO**

### **🗓️ Fase 1: Infraestrutura (Semana 1-2)**
- ✅ Configuração Unipile SDK
- ✅ Database schema
- ✅ Rotas FastAPI básicas
- ✅ Testes de integração

### **🗓️ Fase 2: Frontend (Semana 3-4)**
- ✅ Tela de chat unificado
- ✅ Lista de chats
- ✅ Envio de mensagens
- ✅ Testes de widgets

### **🗓️ Fase 3: Webhooks (Semana 5)**
- ✅ Handlers de webhook
- ✅ Sincronização em tempo real
- ✅ Notificações push

### **🗓️ Fase 4: Calendários (Semana 6)**
- ✅ Integração Google Calendar
- ✅ Integração Outlook Calendar
- ✅ Widget de calendário

### **🗓️ Fase 5: Polimento (Semana 7)**
- ✅ Testes completos
- ✅ Documentação
- ✅ Deploy em produção

---

## **🎯 RESULTADO ESPERADO**

### **✅ Funcionalidades Implementadas:**
- ✅ **Chat Unificado**: Todas as mensagens em uma interface
- ✅ **Múltiplos Provedores**: LinkedIn, Instagram, WhatsApp, Gmail, Outlook
- ✅ **Calendários Integrados**: Google e Outlook
- ✅ **Notificações Push**: Tempo real
- ✅ **Sincronização**: Webhooks automáticos
- ✅ **Interface Responsiva**: Flutter nativo

### **📊 Métricas de Sucesso:**
- ✅ **Redução de 80%** no tempo de resposta
- ✅ **Centralização** de todas as comunicações
- ✅ **Experiência unificada** para usuários
- ✅ **Escalabilidade** para novos provedores

---

## **🔗 REFERÊNCIAS**

- [Unipile Documentation](https://developer.unipile.com/docs)
- [Firebase Flutter Social Auth](https://firebase.flutter.dev/docs/auth/social/)
- [Instagram API Guide](https://www.unipile.com/instagram-profile-api-a-complete-developers-guide-to-smarter-integration-with-unipile/)
- [LinkedIn Messaging API](https://developer.unipile.com/reference/linkedincontroller_getrawdata) 
- https://developer.unipile.com/reference/linkedincontroller_search
- https://developer.unipile.com/reference/linkedincontroller_getsearchparameterslist
- https://developer.unipile.com/reference/linkedincontroller_endorseprofile
- https://developer.unipile.com/reference/linkedincontroller_getcompanyprofile
- https://developer.unipile.com/reference/linkedincontroller_performactiononmember
- https://developer.unipile.com/reference/mailscontroller_listmails
- https://developer.unipile.com/reference/mailscontroller_sendmail
- https://developer.unipile.com/reference/mailscontroller_getmail
- https://developer.unipile.com/reference/mailscontroller_deletemail
- https://developer.unipile.com/reference/mailscontroller_updatemail
- https://developer.unipile.com/reference/mailscontroller_getattachment
- https://developer.unipile.com/reference/folderscontroller_listfolders
- https://developer.unipile.com/reference/folderscontroller_getfolder
- https://developer.unipile.com/reference/draftscontroller_createdraft
- https://developer.unipile.com/reference/calendarscontroller_listcalendars
- https://developer.unipile.com/reference/calendarscontroller_getcalendar
- https://developer.unipile.com/reference/calendarscontroller_listcalendareventsbycalendar
- https://developer.unipile.com/reference/calendarscontroller_createcalendarevent
- https://developer.unipile.com/reference/calendarscontroller_getcalendarevent
- https://developer.unipile.com/reference/calendarscontroller_editcalendarevent
- https://developer.unipile.com/reference/calendarscontroller_deletecalendarevent
- https://developer.unipile.com/reference/chatscontroller_listallchats
- https://developer.unipile.com/reference/chatscontroller_startnewchat
- https://developer.unipile.com/reference/chatscontroller_getchat
- https://developer.unipile.com/reference/chatscontroller_patchchat
- https://developer.unipile.com/reference/chatscontroller_listchatmessages
- https://developer.unipile.com/reference/chatscontroller_sendmessageinchat
- https://developer.unipile.com/reference/chatscontroller_listattendees