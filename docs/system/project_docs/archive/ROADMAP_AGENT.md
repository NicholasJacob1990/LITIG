# 🗺️ Roadmap Técnico do Agente - LITGO5

Este documento serve como um guia técnico para a implementação das próximas funcionalidades no branch `feature/agenda-tarefas-suporte`.

---

## 🎯 **PR #2 – Implementação do OAuth com Google Calendar**

**Objetivo:** Permitir que os usuários conectem suas contas Google para sincronizar eventos da agenda.

**Pré-requisitos:**
- [ ] Obter credenciais OAuth 2.0 do [Google Cloud Console](https://console.cloud.google.com/).
  - **iOS Client ID**: `SEU_CLIENT_ID_IOS.apps.googleusercontent.com`
  - **Android Client ID**: `SEU_CLIENT_ID_ANDROID.apps.googleusercontent.com`
  - **Web Client ID**: `SEU_CLIENT_ID_WEB.apps.googleusercontent.com`

---

### **Passo 1: Configurar `app.json`**

Adicionar o `scheme` de redirecionamento para que o app possa receber a resposta do fluxo OAuth.

```json
{
  "expo": {
    "name": "legaltech-platform",
    "slug": "litgo5",
    "scheme": "com.anonymous.boltexponativewind",
    // ... outras configurações
  }
}
```

---

### **Passo 2: Atualizar o Serviço de Calendário (`lib/services/calendar.ts`)**

Adicionar a lógica de autenticação usando `expo-auth-session`.

```typescript
import * as Google from 'expo-auth-session/providers/google';
import * as WebBrowser from 'expo-web-browser';

WebBrowser.maybeCompleteAuthSession();

// ... (interface e funções existentes)

// Adicionar a função para iniciar o fluxo OAuth
export const useGoogleAuth = () => {
  const [request, response, promptAsync] = Google.useAuthRequest({
    iosClientId: 'SEU_CLIENT_ID_IOS.apps.googleusercontent.com',
    androidClientId: 'SEU_CLIENT_ID_ANDROID.apps.googleusercontent.com',
    webClientId: 'SEU_CLIENT_ID_WEB.apps.googleusercontent.com',
    scopes: ['https://www.googleapis.com/auth/calendar'],
  });

  return { request, response, promptAsync };
};

// Adicionar a função para trocar o código por tokens
export const getGoogleTokens = async (code: string) => {
  // Lógica para fazer a requisição POST para o endpoint de token do Google
  // e retornar { access_token, refresh_token, expires_in }
};
```

---

### **Passo 3: Atualizar a Tela de Agenda (`app/(tabs)/agenda.tsx`)**

Adicionar um botão para iniciar a conexão e exibir o status.

```tsx
import { useCalendar } from '@/lib/contexts/CalendarContext';
import { useGoogleAuth, saveCalendarCredentials } from '@/lib/services/calendar';
import { useAuth } from '@/lib/contexts/AuthContext';
import React, { useEffect } from 'react';
// ... (outros imports)

export default function AgendaScreen() {
  const { user } = useAuth();
  const { events, isLoading } = useCalendar();
  const { request, response, promptAsync } = useGoogleAuth();

  useEffect(() => {
    if (response?.type === 'success') {
      const { code } = response.params;
      // 1. Trocar 'code' por tokens com getGoogleTokens(code)
      // 2. Salvar os tokens no Supabase com saveCalendarCredentials()
      // 3. Chamar refetchEvents() do CalendarContext
    }
  }, [response]);

  return (
    <View>
      {/* ... */}
      <Button
        disabled={!request}
        title="Conectar com Google Calendar"
        onPress={() => {
          promptAsync();
        }}
      />
      {/* Listar os 'events' aqui */}
    </View>
  );
}
```

---

### **Passo 4: Sincronizar Eventos Reais**

Após a conexão, o `CalendarContext` deve ser capaz de buscar eventos diretamente da API do Google.

1.  **Criar `fetchGoogleEvents(accessToken)` em `calendar.ts`**:
    -   Faz uma requisição GET para `https://www.googleapis.com/calendar/v3/calendars/primary/events`.
    -   Usa o `access_token` no header `Authorization`.

2.  **Atualizar `CalendarContext`**:
    -   Verificar se o usuário tem `calendar_credentials` para o Google.
    -   Se sim, chamar `fetchGoogleEvents` em vez de `getEvents` (do nosso DB).
    -   Implementar uma lógica de fallback para buscar do nosso DB se a API do Google falhar.

---

## 🎯 **PR #3 – Sincronização com Outlook**
*Repetir os passos acima, mas usando `expo-auth-session/providers/microsoft` e os endpoints/escopos da Microsoft Graph API (`Calendars.ReadWrite`).*

## 🏛️ **Estratégia de Integração com ERP/Controladoria**

Todas as funcionalidades, especialmente **Tarefas**, **Agenda** e **Suporte**, são construídas com uma futura integração em mente. A estratégia se baseia em três pilares:

### 1. **Supabase como Camada Intermediária (Broker)**
O aplicativo móvel **NUNCA** se comunicará diretamente com o ERP. Ele apenas lê e escreve no banco de dados do Supabase. Toda a lógica de sincronização é uma responsabilidade do backend, implementada através de **Supabase Edge Functions**.

**Vantagens:**
- **Desacoplamento:** O app não precisa ser modificado se o ERP mudar.
- **Segurança:** As credenciais e a lógica de negócio do ERP ficam protegidas no backend.
- **Performance:** O app tem respostas rápidas do Supabase, enquanto a sincronização com o ERP pode ocorrer de forma assíncrona em segundo plano.

### 2. **Preparação no Banco de Dados**
As tabelas já foram criadas com os campos necessários para o "hand-off" de informações:
- **`tasks.erp_synced` (boolean):** Controla se a tarefa já foi enviada para o ERP. `false` por padrão.
- **`tasks.erp_task_id` (text):** Armazena o ID correspondente da tarefa no sistema do ERP após a sincronização, para futuras atualizações.
- **`events.external_id` (text):** Um campo análogo para identificar eventos em sistemas externos.

### 3. **Fluxo de Sincronização (Exemplo com Tarefas)**

O fluxo de dados para uma nova tarefa será o seguinte:

1.  **Criação no App:**
    -   Um advogado cria uma nova tarefa no app.
    -   O app chama a função `createTask` do nosso serviço.
    -   A tarefa é salva na tabela `tasks` do Supabase com **`erp_synced = false`**.

2.  **Sincronização Supabase → ERP (Backend):**
    -   Uma **Edge Function** no Supabase, acionada por um gatilho de banco de dados (Database Webhook) ou um cron job, detecta a nova tarefa com `erp_synced = false`.
    -   Essa função formata os dados e faz uma chamada para a API do ERP (ex: `POST /api/v1/tasks`).

3.  **Confirmação e Mapeamento:**
    -   O ERP processa a tarefa e retorna seu próprio ID (ex: `erp-task-abc-123`).
    -   A Edge Function recebe essa resposta e atualiza a tarefa original no Supabase:
        -   Define **`erp_synced = true`**.
        -   Define **`erp_task_id = 'erp-task-abc-123'`**.

A partir deste ponto, o ERP passa a ser a "fonte da verdade" para aquela tarefa, e futuras atualizações podem seguir um fluxo de sincronização bidirecional.

---

## ✅ **DONE: Controle de Prazos e Tarefas (v1)**

**Objetivo:** Permitir que advogados criem e gerenciem tarefas, com a opção de associá-las a casos específicos.

### **Implementação Realizada:**
1.  **Estrutura de Dados:** Tabela `tasks` criada com campos para `case_id`, `assigned_to`, `priority`, `due_date`, etc.
2.  **Contexto e Serviço:** `TasksContext` e `tasks.ts` implementados para gerenciar o estado das tarefas no app.
3.  **UI da Lista de Tarefas:**
    -   Nova aba "Tarefas" na navegação, visível apenas para advogados.
    -   Tela `app/(tabs)/tasks.tsx` exibe a lista de tarefas, com indicadores visuais para status e prioridade.
4.  **Criação de Tarefas:**
    -   Um FAB na tela abre um modal com o formulário `TaskForm.tsx`.
    -   O formulário permite definir título, descrição, prioridade e associar a um caso existente (lista de casos buscada dinamicamente).
    -   A lista de tarefas é atualizada automaticamente após a criação.

---

## ✅ **DONE: Canal de Suporte Interno (v1)**

**Objetivo:** Fornecer um canal de comunicação interno para advogados abrirem tickets de suporte e conversarem com a equipe de apoio.

### **Implementação Realizada:**
1.  **Estrutura de Dados:** Tabelas `support_tickets` e `support_messages` criadas.
2.  **Contexto e Serviço:** `SupportContext` e `support.ts` implementados.
3.  **UI da Lista de Tickets:**
    -   Aba "Suporte" visível apenas para advogados.
    -   Tela `app/(tabs)/support/index.tsx` lista todos os tickets abertos pelo usuário.
4.  **Criação de Tickets:** Um FAB abre o modal `SupportTicketForm.tsx` para a criação de um novo ticket com um assunto.
5.  **Chat de Suporte:**
    -   Rota dinâmica `app/(tabs)/support/[ticketId].tsx` criada.
    -   Clicar em um ticket navega para uma tela de chat.
    -   A tela de chat exibe o histórico de mensagens e permite o envio de novas mensagens em tempo real (com atualização otimista).

---

## ✅ **DONE: Notificações de Tarefas (v1)**

**Objetivo:** Notificar proativamente os advogados sobre tarefas cujos prazos estão se aproximando.

### **Implementação Realizada:**
1.  **Dependência:** `expo-notifications` instalada e configurada.
2.  **Permissões e Token:**
    -   Um hook customizado, `usePushNotifications`, foi criado para gerenciar o ciclo de vida das notificações.
    -   Ao iniciar o app, ele solicita a permissão do usuário.
    -   Se a permissão for concedida, o `expoPushToken` do dispositivo é obtido.
    -   Uma nova coluna `expo_push_token` foi adicionada à tabela `profiles` via migração.
    -   O hook salva automaticamente o token no perfil do usuário logado.
3.  **Lógica de Envio (Backend):**
    -   Uma **Edge Function** (`task-deadline-notifier`) foi criada no Supabase.
    -   **Gatilho:** Projetada para ser executada em um cronograma (ex: diariamente).
    -   **Ação:** A função verifica todas as tarefas com prazo nas próximas 24 horas, busca o `expo_push_token` do advogado responsável e envia uma notificação push via Expo.

---

## 🎯 **PRÓXIMOS PASSOS SUGERIDOS**

O branch `feature/agenda-tarefas-suporte` agora contém versões funcionais de todas as funcionalidades planejadas. Os próximos passos devem focar em estabilidade, refinamento e completude.

1.  **Testes e Refinamento:** Testar exaustivamente os fluxos implementados, refinar a UI, melhorar o feedback ao usuário e o tratamento de erros.
2.  **Integração com Outlook:** Implementar a autenticação e sincronização para o Microsoft Outlook Calendar.
3.  **Segurança (Criptografia):** Implementar a criptografia para os tokens de calendário salvos no banco de dados.

## Visão Geral
Este documento acompanha o desenvolvimento das funcionalidades avançadas do LITGO5, uma plataforma jurídica que conecta clientes a advogados através de IA.

## Status das Funcionalidades

### ✅ CONCLUÍDO

#### 1. Agenda Integrada (Google Calendar)
- **Status**: ✅ Implementado e Refinado
- **Componentes**:
  - `app/(tabs)/agenda.tsx` - Tela principal com melhor UX
  - `lib/contexts/CalendarContext.tsx` - Contexto para gerenciar estado
  - `lib/services/calendar.ts` - Serviços de integração
- **Recursos Implementados**:
  - ✅ Autenticação OAuth 2.0 com Google
  - ✅ Sincronização de eventos do Google Calendar
  - ✅ UI com `react-native-calendars` em português
  - ✅ Feedback visual durante sincronização
  - ✅ Indicadores de conexão e última sincronização
  - ✅ Tratamento de erros aprimorado
  - ✅ Pull-to-refresh para sincronização manual
- **Melhorias Aplicadas**:
  - Melhor feedback visual durante operações
  - Status de conexão em tempo real
  - Botão de sincronização manual
  - Tratamento de erros mais robusto
  - Interface mais intuitiva

#### 2. Controle de Tarefas e Prazos
- **Status**: ✅ Implementado e Refinado
- **Componentes**:
  - `app/(tabs)/tasks.tsx` - Tela principal com CRUD completo
  - `lib/contexts/TasksContext.tsx` - Contexto para gerenciar estado
  - `lib/services/tasks.ts` - Serviços CRUD expandidos
  - `components/organisms/TaskForm.tsx` - Formulário para criar/editar
- **Recursos Implementados**:
  - ✅ CRUD completo de tarefas (Create, Read, Update, Delete)
  - ✅ Associação de tarefas a casos específicos
  - ✅ Sistema de priorização (1-10)
  - ✅ Controle de status (pendente, em progresso, concluída, atrasada)
  - ✅ Definição de prazos
  - ✅ Interface intuitiva para edição
- **Melhorias Aplicadas**:
  - Edição de tarefas existentes
  - Exclusão com confirmação
  - Alternância rápida de status (toque)
  - Ações contextuais (pressionar e segurar)
  - Campo de descrição e prazo
  - Indicadores visuais de status

#### 3. Suporte ao Time Jurídico
- **Status**: ✅ Implementado
- **Componentes**:
  - `app/(tabs)/support/index.tsx` - Lista de tickets
  - `app/(tabs)/support/[ticketId].tsx` - Chat individual
  - `lib/contexts/SupportContext.tsx` - Contexto para gerenciar estado
  - `lib/services/support.ts` - Serviços de suporte
  - `components/organisms/SupportTicketForm.tsx` - Formulário para criar tickets
- **Recursos Implementados**:
  - ✅ Criação de tickets de suporte
  - ✅ Chat em tempo real para cada ticket
  - ✅ Navegação dinâmica entre tickets
  - ✅ Interface adaptada do chat de triagem
  - ✅ Diferenciação visual usuário/suporte

#### 4. Notificações Push
- **Status**: ✅ Implementado
- **Componentes**:
  - `hooks/usePushNotifications.ts` - Hook para gerenciar notificações
  - `supabase/functions/task-deadline-notifier/index.ts` - Edge Function
- **Recursos Implementados**:
  - ✅ Solicitação de permissões
  - ✅ Registro de tokens no Supabase
  - ✅ Edge Function para notificações de prazos
  - ✅ Integração automática no app

### 🔄 EM REFINAMENTO

#### 5. Melhorias de UX/UI
- **Status**: 🔄 Em Progresso
- **Próximas Melhorias**:
  - [ ] Filtros e busca para tarefas
  - [ ] Badges de notificação nas abas
  - [ ] Temas claro/escuro
  - [ ] Animações de transição

### 📋 PRÓXIMAS FUNCIONALIDADES

#### 6. Integração Microsoft Outlook
- **Status**: 📋 Planejado
- **Componentes Necessários**:
  - Extensão do `calendar.ts` para suporte ao Microsoft Graph API
  - Configuração OAuth Microsoft
  - UI para seleção de provedor

#### 7. Prazos Jurídicos Inteligentes
- **Status**: 📋 Planejado
- **Recursos Planejados**:
  - Cálculo automático de prazos processuais
  - Integração com calendário judicial
  - Alertas personalizados por tipo de prazo

#### 8. Relatórios e Analytics
- **Status**: 📋 Planejado
- **Recursos Planejados**:
  - Dashboard de produtividade
  - Métricas de casos e tarefas
  - Relatórios exportáveis

---

## Arquitetura Implementada

### Estrutura de Dados

#### Tabela `events`
```sql
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id),
    title TEXT NOT NULL,
    description TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    provider TEXT DEFAULT 'local',
    external_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Tabela `tasks`
```sql
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID REFERENCES cases(id),
    assigned_to UUID REFERENCES profiles(id),
    created_by UUID REFERENCES profiles(id),
    title TEXT NOT NULL,
    description TEXT,
    priority INTEGER DEFAULT 5,
    due_date TIMESTAMPTZ,
    status TEXT DEFAULT 'pending',
    erp_synced BOOLEAN DEFAULT FALSE,
    erp_task_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Tabela `support_tickets`
```sql
CREATE TABLE support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES profiles(id),
    subject TEXT NOT NULL,
    status TEXT DEFAULT 'open',
    priority TEXT DEFAULT 'medium',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Contextos React

#### CalendarContext
- Gerencia estado dos eventos
- Controla sincronização
- Trata erros de conexão

#### TasksContext
- Gerencia estado das tarefas
- Controla operações CRUD
- Atualiza em tempo real

#### SupportContext
- Gerencia tickets de suporte
- Controla estado do chat
- Atualiza lista de tickets

### Serviços

#### calendar.ts
- Autenticação OAuth Google
- Sincronização de eventos
- Gerenciamento de tokens

#### tasks.ts
- CRUD completo de tarefas
- Associação com casos
- Controle de status

#### support.ts
- Gerenciamento de tickets
- Chat em tempo real
- Mensagens persistentes

---

## Testes e Validação

### ✅ Testes Realizados

#### Funcionalidade de Agenda
- ✅ Autenticação OAuth Google
- ✅ Sincronização de eventos
- ✅ Exibição em português
- ✅ Feedback visual durante operações

#### Funcionalidade de Tarefas
- ✅ Criação de tarefas
- ✅ Edição de tarefas existentes
- ✅ Exclusão com confirmação
- ✅ Alternância de status
- ✅ Associação com casos

#### Funcionalidade de Suporte
- ✅ Criação de tickets
- ✅ Chat individual
- ✅ Navegação entre tickets
- ✅ Interface intuitiva

### 🔄 Testes Pendentes
- [ ] Testes de performance com muitos dados
- [ ] Testes de conectividade intermitente
- [ ] Testes com diferentes fusos horários
- [ ] Testes de notificações push

---

## Integração com ERP (Preparação)

### Estratégia de Três Pilares

#### 1. Supabase como Broker
- App nunca se comunica diretamente com ERP
- Todas as operações passam pelo Supabase
- Edge Functions fazem a ponte

#### 2. Preparação no Banco
- Campos `erp_synced` e `erp_task_id` já implementados
- Estrutura pronta para sincronização
- Logs de operações

#### 3. Fluxo de Sincronização
- Edge Functions monitoram mudanças
- Sincronização bidirecional
- Tratamento de conflitos

---

## Commits e Versionamento

### Últimos Commits Importantes

#### Refinamentos Implementados (Janeiro 2025)
- **feat**: Implementar edição completa de tarefas
- **feat**: Melhorar feedback visual da agenda
- **feat**: Adicionar ações contextuais para tarefas
- **feat**: Implementar exclusão de tarefas
- **feat**: Melhorar tratamento de erros na agenda
- **feat**: Adicionar sincronização manual
- **docs**: Criar plano de testes e refinamentos

#### Funcionalidades Base (Dezembro 2024)
- **feat**: Implementar agenda com Google Calendar
- **feat**: Implementar sistema de tarefas
- **feat**: Implementar suporte interno
- **feat**: Implementar notificações push
- **feat**: Configurar navegação condicional por role

---

## Próximos Passos

### Curto Prazo (1-2 semanas)
1. **Implementar filtros para tarefas**
   - Filtro por status
   - Filtro por prioridade
   - Filtro por caso
   - Busca por texto

2. **Adicionar badges de notificação**
   - Contador de tarefas pendentes
   - Contador de tickets abertos
   - Contador de eventos próximos

3. **Melhorar notificações**
   - Notificações mais inteligentes
   - Configuração de preferências
   - Diferentes tipos de alerta

### Médio Prazo (1 mês)
1. **Integração Microsoft Outlook**
2. **Prazos jurídicos inteligentes**
3. **Relatórios básicos**
4. **Temas claro/escuro**

### Longo Prazo (2-3 meses)
1. **Integração completa com ERP**
2. **Analytics avançados**
3. **Automações inteligentes**
4. **API pública**

---

*Última atualização: 3 de Janeiro de 2025*
*Branch atual: `feature/agenda-tarefas-suporte`*
*Próxima milestone: Filtros e Busca* 