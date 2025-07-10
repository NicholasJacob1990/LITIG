# PLANO DE MELHORIA – CENTRAL DE SUPORTE (LITGO5)

Data de criação: **03/07/2025**  
Versão: **1.0**

---

## 1 · Visão Geral
A Central de Suporte está funcional, porém carece de recursos críticos de usabilidade, produtividade e automação.  
Objetivo: evoluir o módulo para nível "pronto para produção" (MVP → v1).

---

## 2 · Backlog de Funcionalidades

| # | Funcionalidade | Valor | Esforço | Dependências |
|---|----------------|-------|---------|--------------|
| **F01** | Notificações Push (nova resposta / mudança de status) | Alto | Médio | Expo Notifications, Supabase Row-Level Changes |
| **F02** | Chat em tempo real (WebSocket) | Alto | Alto | Supabase Realtime / Pusher |
| **F03** | Anexos (imagem / PDF) nos tickets | Alto | Alto | Supabase Storage |
| **F04** | Menu de ações no ticket (Fechar·Reabrir·Alterar prioridade) | Alto | Médio | RPC no Supabase |
| **F05** | Filtros de Status & Prioridade + Busca | Médio | Médio | N/A |
| **F06** | SLA / prazos visíveis (tempo de 1ª resposta) | Médio | Baixo | Campo `first_response_at` (DB) |
| **F07** | Avaliação ⭐⭐⭐⭐⭐ após ticket fechado | Médio | Baixo | Tabela `support_ratings` |
| **F08** | Indicador de "mensagem lida" | Baixo | Médio | Campo `last_viewed_at` (DB) |
| **F09** | Skeleton loading & animações | Baixo | Baixo | N/A |
| **F10** | Internacionalização (i18n) | Baixo | Baixo | Arquivos `.json` |
| **F11** | Painel Web para agentes (back-office) | Alto | Alto | Supabase Auth + RLS |

---

## 3 · Arquitetura de Backend

### 3.1 Novas Funções RPC
| Função | Descrição |
|--------|-----------|
| `update_ticket_status(ticket_id, new_status)` | Altera status ( `open`, `in_progress`, `closed`, `on_hold` ) |
| `update_ticket_priority(ticket_id, new_priority)` | Altera prioridade ( `low` → `critical` ) |
| `mark_ticket_read(ticket_id)` | Atualiza `last_viewed_at` para indicadores de leitura |
| `rate_ticket(ticket_id, stars, comment)` | Insere avaliação ao fechar |

### 3.2 Storage
* Bucket `support-attachments` (RLS: somente criador & suporte).

### 3.3 Realtime
* Canal `support_tickets` – broadcast de novas mensagens e updates de status.

### 3.4 Tabelas Extras
* `support_ratings (id, ticket_id, stars, comment, created_at)`  
* **Views** para cálculo de SLA (tempo médio primeira resposta).

---

## 4 · Frontend (Expo + Router)

1. **Botões de Voltar** em `/support/new` e `/support/[id]`
2. **Menu de Ações** (Sheet) no chat  
   • Fechar / Reabrir / Alterar prioridade  
   • Chama RPC corresp.
3. **Upload de Anexos**  
   • Botão 📎 habilita Camera Roll ou File Picker  
   • Mostra thumbnails na mensagem
4. **Chat WebSocket**  
   • `useEffect` escuta canal Realtime  
   • Scroll automático
5. **Filtros & Busca** na lista  
   • Dropdown Status / Prioridade  
   • `TextInput` de busca
6. **SLA Badge** no card  
   • Ex: "⏱ 45 min para 1ª resposta"
7. **Rating Modal** ao fechar ticket
8. **Skeleton loading** (Shimmer) para lista e chat
9. **i18n** inicial – pt-BR / en‐US strings

---

## 5 · Roadmap de Sprints

| Sprint | Itens | Meta |
|--------|-------|------|
| **S1** (1 sem) | F01 · F04 · RPCs · Botões Voltar | Gestão básica de tickets & push |
| **S2** (1 sem) | F02 · F03 (upload) | Chat realtime + anexos |
| **S3** (1 sem) | F05 · F06 · F08 | Usabilidade avançada & SLA |
| **S4** (1 sem) | F07 · F09 · F10 | Feedback & polimento |
| **S5** (2 sem) | F11 (Painel agentes) | Back-office completo |

---

## 6 · Métricas de Sucesso

* Tempo médio de 1ª resposta < **1 h**  
* 80 % dos tickets avaliados ≥ ★4  
* Entrega de push ≥ 98 %  
* Engajamento de anexos (≥ 50 % dos tickets com arquivo)

---

## 7 · Ações Imediatas

1. **Criar migração SQL** com RPC `update_ticket_status` & `update_ticket_priority` (já esboçado).  
2. **Adicionar Botão Voltar** em `/support/new` e `/support/[id]`.  
3. **Publicar este documento** em `docs/PLANO_DE_MELHORIA_CENTRAL_SUPORTE.md` e abrir issues no repositório seguindo a tabela de backlog.

---

> Este plano foi consolidado para execução; todas as tarefas estão estimadas e priorizadas em português conforme solicitado. 