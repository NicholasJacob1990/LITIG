# 💼 API de Chat B2B - Documentação Completa

## 📋 Visão Geral

O Sistema de Chat B2B da LITIG permite comunicação direta entre advogados e escritórios através de parcerias, oferecendo funcionalidades avançadas como:

- **Chat de Parcerias**: Comunicação entre advogados colaboradores
- **Colaboração entre Escritórios**: Salas multi-participantes para projetos conjuntos
- **Mensagens Contextualizadas**: Categorização por tipo (proposta, contrato, faturamento, etc.)
- **Prioridades**: Sistema de urgência para mensagens críticas
- **Permissões Granulares**: Controle de acesso baseado em planos e roles

## 🔐 Autenticação

Todos os endpoints requerem autenticação via token Bearer JWT:

```http
Authorization: Bearer YOUR_JWT_TOKEN
```

## 📊 Validação de Planos

As funcionalidades B2B são restritas por tipo de usuário e plano:

| Funcionalidade | Free | PRO | Premium | Escritório Free | Escritório Pago |
|----------------|------|-----|---------|-----------------|-----------------|
| Chat B2B Básico | ❌ | ✅ | ✅ | ❌ | ✅ |
| Chat de Parcerias | ❌ | ✅ | ✅ | ❌ | ✅ |
| Colaboração entre Escritórios | ❌ | ❌ | ✅ | ❌ | ✅ |
| Chat Multi-participante | ❌ | ❌ | ✅ | ❌ | ✅ |
| Máx. Participantes | - | 2 | 10 | 2 | 15+ |

## 🔧 Endpoints da API

### Base URL
```
https://api.litig.com/api/v1/b2b-chat
```

---

## 🏠 Criação de Salas

### POST `/partnership-rooms`
Cria sala de chat para parceria entre advogados.

#### Request Body
```json
{
  "partnership_id": "uuid",
  "partnership_type": "collaboration|correspondent|expert_opinion",
  "auto_invite_participants": true
}
```

#### Response
```json
{
  "success": true,
  "room_id": "uuid",
  "partnership_id": "uuid", 
  "room_type": "partnership",
  "participants_count": 2,
  "created_at": "2025-01-25T10:00:00Z"
}
```

#### Códigos de Erro
- `400` - Dados inválidos ou usuário sem permissão
- `403` - Usuário não é participante da parceria
- `404` - Parceria não encontrada

---

### POST `/firm-collaboration-rooms`
Cria sala de colaboração entre escritórios.

#### Request Body
```json
{
  "partner_firm_id": "uuid",
  "collaboration_purpose": "Colaboração em caso complexo empresarial",
  "case_id": "uuid (opcional)"
}
```

#### Response
```json
{
  "success": true,
  "room_id": "uuid",
  "collaboration_type": "firm_collaboration",
  "firm_id": "uuid",
  "partner_firm_id": "uuid",
  "case_id": "uuid"
}
```

---

## 👥 Gestão de Participantes

### POST `/rooms/{room_id}/participants`
Adiciona participantes a uma sala B2B.

#### Request Body
```json
{
  "partnership_id": "uuid",
  "participant_ids": ["uuid1", "uuid2"]
}
```

#### Response
```json
{
  "success": true,
  "added_participants": [
    {
      "user_id": "uuid",
      "role": "observer",
      "added_at": "2025-01-25T10:00:00Z"
    }
  ],
  "total_participants": 4
}
```

### GET `/rooms/{room_id}/participants`
Lista participantes de uma sala.

#### Response
```json
[
  {
    "id": "uuid",
    "partnership_id": "uuid",
    "user_id": "uuid",
    "user_name": "Dr. João Silva",
    "user_email": "joao@exemplo.com",
    "role": "creator|partner|observer|firm_representative",
    "permissions": {
      "can_message": true,
      "can_invite": false,
      "can_archive": false
    },
    "joined_at": "2025-01-25T10:00:00Z"
  }
]
```

---

## 💬 Mensagens

### POST `/rooms/{room_id}/messages`
Envia mensagem em sala B2B.

#### Request Body
```json
{
  "content": "Vamos alinhar os detalhes da parceria",
  "message_type": "text|image|document|audio",
  "message_context": "general|proposal|negotiation|contract|work_update|billing",
  "priority": "low|normal|high|urgent",
  "reply_to_message_id": "uuid (opcional)",
  "attachment_url": "https://... (opcional)"
}
```

#### Response
```json
{
  "success": true,
  "message_id": "uuid",
  "sent_at": "2025-01-25T10:00:00Z",
  "context": "proposal",
  "priority": "high"
}
```

### GET `/rooms/{room_id}/messages`
Retorna mensagens de uma sala.

#### Query Parameters
- `limit` (int): Máximo de mensagens (padrão: 50)
- `offset` (int): Offset para paginação (padrão: 0)
- `context_filter` (string): Filtro por contexto (opcional)

#### Response
```json
[
  {
    "id": "uuid",
    "room_id": "uuid",
    "sender_id": "uuid",
    "sender_name": "Dr. João Silva",
    "content": "Proposta de honorários: 30/70",
    "message_type": "text",
    "message_context": "proposal",
    "priority": "normal",
    "reply_to_message_id": null,
    "attachment_url": null,
    "created_at": "2025-01-25T10:00:00Z",
    "is_read": false
  }
]
```

---

## 📋 Listagem de Salas

### GET `/rooms`
Lista salas B2B do usuário atual.

#### Query Parameters
- `limit` (int): Máximo de salas (padrão: 20)
- `offset` (int): Offset para paginação (padrão: 0)
- `room_type` (string): Filtro por tipo (partnership|firm_collaboration|b2b_negotiation)

#### Response
```json
[
  {
    "id": "uuid",
    "room_type": "partnership",
    "partnership_id": "uuid",
    "firm_id": null,
    "secondary_firm_id": null,
    "status": "active",
    "created_at": "2025-01-25T10:00:00Z",
    "last_message_at": "2025-01-25T15:30:00Z",
    "unread_count": 3,
    "participants_count": 2,
    "partnership_type": "collaboration",
    "creator_name": "Dr. João Silva",
    "partner_name": "Dra. Maria Santos"
  }
]
```

---

## 🔍 Utilidades

### GET `/permissions`
Retorna permissões B2B do usuário atual.

#### Response
```json
{
  "user_type": "lawyer_individual",
  "plan": "pro_lawyer",
  "permissions": {
    "b2b_chat": {
      "allowed": true,
      "reason": null,
      "suggested_plan": null
    },
    "partnership_chat": {
      "allowed": true,
      "reason": null,
      "suggested_plan": null
    },
    "firm_collaboration": {
      "allowed": false,
      "reason": "Para colaboração direta com escritórios, faça upgrade para o plano PREMIUM.",
      "suggested_plan": "premium_lawyer"
    },
    "multi_participant_chat": {
      "allowed": false,
      "reason": "Para chat com múltiplos participantes, faça upgrade para o plano PREMIUM.",
      "suggested_plan": "premium_lawyer"
    }
  },
  "limits": {
    "max_chat_participants": 2,
    "chat_file_sharing": false,
    "chat_delegation": false,
    "chat_analytics": false
  }
}
```

---

## 🔌 WebSocket - Tempo Real

### WS `/ws/{room_id}`
Conexão WebSocket para chat em tempo real.

#### Parâmetros de Conexão
- `room_id`: ID da sala
- `user_id`: ID do usuário (via query string)

#### Mensagem de Entrada
```json
{
  "type": "message",
  "content": "Mensagem de teste",
  "message_context": "general",
  "priority": "normal",
  "sender_id": "uuid"
}
```

#### Mensagem de Saída
```json
{
  "type": "message_received",
  "message_id": "uuid",
  "sender_name": "Dr. João Silva",
  "content": "Mensagem de teste",
  "context": "general",
  "priority": "normal",
  "timestamp": "2025-01-25T10:00:00Z"
}
```

---

## 🏷️ Contextos de Mensagem

| Contexto | Descrição | Uso Recomendado |
|----------|-----------|-----------------|
| `general` | Conversa geral | Discussões cotidianas |
| `proposal` | Propostas comerciais | Orçamentos e ofertas |
| `negotiation` | Negociações | Ajustes de termos |
| `contract` | Contratuais | Discussão de cláusulas |
| `work_update` | Atualizações de trabalho | Status do projeto |
| `billing` | Faturamento | Questões financeiras |

## 🚨 Prioridades de Mensagem

| Prioridade | Comportamento | Notificação |
|------------|---------------|-------------|
| `low` | Sem urgência | Push normal |
| `normal` | Padrão | Push normal |
| `high` | Importante | Push com ❗ |
| `urgent` | Crítica | Push com 🚨 |

---

## 📱 Códigos de Status HTTP

| Código | Significado | Ação |
|--------|-------------|-------|
| `200` | Sucesso | Processar resposta |
| `400` | Dados inválidos | Verificar payload |
| `401` | Não autenticado | Renovar token |
| `403` | Sem permissão | Verificar plano |
| `404` | Recurso não encontrado | Verificar IDs |
| `429` | Rate limit excedido | Aguardar e tentar novamente |
| `500` | Erro interno | Contatar suporte |

---

## 🛠️ Exemplos de Uso

### 1. Criar Parceria e Chat
```javascript
// 1. Criar parceria
const partnership = await api.post('/partnerships', {
  partner_id: 'lawyer_uuid',
  partnership_type: 'collaboration',
  honorarios: 'A combinar'
});

// 2. Criar sala de chat
const chatRoom = await api.post('/b2b-chat/partnership-rooms', {
  partnership_id: partnership.id,
  auto_invite_participants: true
});

// 3. Conectar WebSocket
const ws = new WebSocket(`wss://api.litig.com/api/v1/b2b-chat/ws/${chatRoom.room_id}?user_id=${currentUserId}`);
```

### 2. Enviar Proposta Comercial
```javascript
const message = await api.post(`/b2b-chat/rooms/${roomId}/messages`, {
  content: 'Proposta: 30% dos honorários para consultoria em direito tributário',
  message_context: 'proposal',
  priority: 'high'
});
```

### 3. Adicionar Especialista à Conversa
```javascript
const participants = await api.post(`/b2b-chat/rooms/${roomId}/participants`, {
  partnership_id: partnershipId,
  participant_ids: ['expert_lawyer_uuid']
});
```

---

## 🔐 Segurança e Privacidade

### Criptografia
- Todas as mensagens são transmitidas via HTTPS/WSS
- Tokens JWT com expiração configurável
- Validação de permissões em cada endpoint

### Auditoria
- Log completo de todas as ações
- Rastreamento de acesso às salas
- Histórico de modificações em participantes

### Conformidade
- LGPD: Dados podem ser exportados/deletados
- Retenção: Mensagens mantidas conforme política
- Backup: Cópias seguras para recuperação

---

## 🧪 Testando a API

Execute o script de teste completo:
```bash
cd packages/backend
python scripts/test_b2b_chat_system.py
```

### Teste Manual via cURL

#### Criar Sala de Parceria
```bash
curl -X POST "https://api.litig.com/api/v1/b2b-chat/partnership-rooms" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "partnership_id": "uuid",
    "partnership_type": "collaboration",
    "auto_invite_participants": true
  }'
```

#### Enviar Mensagem
```bash
curl -X POST "https://api.litig.com/api/v1/b2b-chat/rooms/ROOM_ID/messages" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Vamos alinhar os detalhes da parceria",
    "message_context": "general",
    "priority": "normal"
  }'
```

---

## 📞 Suporte

- **Documentação**: `/docs` (Swagger UI)
- **Email**: dev@litig.com
- **Issues**: GitHub Repository
- **Status**: status.litig.com

---

## 🚀 Próximas Funcionalidades

- [ ] **Chat de Voz**: Integração com WebRTC
- [ ] **Compartilhamento de Tela**: Para reuniões virtuais
- [ ] **Bots Inteligentes**: Assistentes IA para parcerias
- [ ] **Analytics Avançados**: Métricas de colaboração
- [ ] **Integração CRM**: Sincronização com sistemas externos

---

**Versão da API**: v1.0  
**Última Atualização**: 25 de Janeiro de 2025  
**Compatibilidade**: Backend LITIG v2.6.3+ 