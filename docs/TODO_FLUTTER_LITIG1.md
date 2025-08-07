## To‑dos LITIG-1 Flutter

- Mensagens (WhatsApp/LinkedIn/Email)
  - Integrar Unipile: listar contas, chats e mensagens; enviar/responder/encaminhar
  - Implementar telas de detalhe: `_openMessageDetail`, `_openEmailDetail`, `_openEventDetail` (unified_chats_screen.dart)
  - Finalizar ações de Email: arquivar, desfazer, mover, marcar lido (email_actions_widget.dart) e compor com rich composer
  - Anexos: upload/download e vínculo com `caseId`
  - Realtime (Supabase): badges de não lidas e atualização ao vivo
  - LinkedIn: voice note, comentar post, conexões/perfil empresa (ligar endpoints backend)
  - WhatsApp Business: catálogo, pedido, agendamento, pagamento (WhatsAppActionsWidget)

- Calendário (Agenda)
  - Usar `ScheduleScreen` real no branch `/schedule` (app_router.dart)
  - Criar `ScheduleBloc` + repositório; listar/criar/editar/cancelar eventos
  - OAuth/sincronização Google/Microsoft via Unipile
  - Ações a partir dos casos: implementar `_scheduleMeetingType` e callbacks de agenda
  - Lembretes/notificações de eventos/prazos

- Emails
  - Conectar envio/recepção via Unipile (IMAP/Google/Microsoft) no fluxo de Mensagens
  - Compositor rico integrado a casos (templates/anexos)
  - Backend SMTP/flags (EMAIL_ENABLED) como fallback quando não usar Unipile

- Dashboards
  - KPIs reais e gráficos em `LawyerDashboard` e `ContractorDashboard`
  - Padronizar DI no `LawyerDashboard` (mover para `injection_container.dart`)
  - Ampliar “Ações Rápidas” por perfil
  - `ClientDashboard`: CTA/triagem e cards de progresso

- Perfis (Profile)
  - Persistência real nas telas (ProfileBloc + repo + endpoints)
  - Upload de avatar/documentos e sincronização
  - Seções condicionais por perfil (lawyer_individual, lawyer_firm_member, firm, super_associate)
  - Navegação contextual das sub‑rotas (profileGoRoute)

- Navegação + Permissões
  - Remover fallback em `MainTabsShell` e usar `getVisibleTabsForUser`
  - Validar `tabOrderByProfile`/`getInitialRouteForUser` e seed de permissões no backend

- Financeiro
  - Feedback visual para `MarkPaymentReceived`/`RequestPaymentRepass` e refresh
  - Filtros por período/tipo e export (PDF/CSV) na UI
  - Detalhes de pagamentos (timeline/status/links)

- Busca de advogados e Parceiros
  - Clientes: validar 2 abas (Buscar + Recomendações com presets)
  - Advogados/Firm: padronizar `partners_screen.dart` com as mesmas 2 abas e triagem IA separada

- Realtime/Notificações
  - Ativar Supabase Realtime para mensagens, eventos e casos; badges e toasts

- Observabilidade/Analytics
  - Corrigir serialização de `Duration` no `AnalyticsService`
  - Validar imagem/placeholder para evitar “Invalid image data”

- Contratação (Hiring)
  - Implementar `LawyerHiringModal`, rotas e repositório
  - Backend: validar/implementar `hiring_proposals.py`

- Limpeza de TODOs críticos
  - unified_chats_screen.dart: detalhes e undo de arquivamento
  - cases/* sections: chat interno, e‑mail, pasta de trabalho, recursos, agendamento
  - partners/*: navegações de contato/explicabilidade
  - injection_container.dart: baseUrl/config centralizados e DI pendente
  - Testes de integração (troca de usuário por role)

- Configuração/Ambiente
  - Centralizar base URLs/tokens em config/env service
  - Confirmar chaves Unipile, Supabase, SMTP e OAuth

- Testes
  - Widgets: Mensagens, Agenda, Financeiro, Dashboards
  - Integração: busca (presets/manual), financeiro (marcar/repasse)
  - E2E: login → navegação por perfil → mensagens/agenda/financeiro

- Documentação
  - Atualizar READMEs e guias de integração (Unipile, Financeiro, Agenda)
  - Checklist de permissões por perfil e rotas

- Performance/UX
  - Placeholders/skeletons em mensagens, agenda e financeiro

- Segurança
  - Remover tokens hardcoded (ex.: “Bearer TOKEN”) e sanitizar inputs

- Devedores técnicos
  - Migrar Agenda para BLoC com DI
  - Remover imports mortos e TODOs obsoletos

- Sprints sugeridos
  - A: Mensagens (+ provedores + anexos) e navegação por permissão
  - B: Agenda (OAuth + CRUD + integrações)
  - C: Financeiro (UX completa + export + feedback)
  - D: Perfis (persistência completa + uploads) e testes


