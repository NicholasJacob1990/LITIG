# 🚀 Plano de Sprints - Migração Flutter LITGO5

## 📊 Análise Consolidada

### Status Atual da Migração
Baseado na análise comparativa entre o backend, React Native (LITGO6) e Flutter, identificamos:

- **Arquitetura Flutter**: ✅ Estrutura Clean Architecture implementada
- **Features Base**: ✅ Pastas de features criadas (auth, triage, cases, lawyers, profile, etc.)
- **Conectividade**: 🟡 DioService básico implementado, precisa expansão
- **UI Implementada**: 🔴 Maioria das telas precisam ser conectadas aos BLoCs
- **Funcionalidades Críticas**: 🔴 Pagamentos, OCR, Contratos não implementados

---

## 🎯 Objetivos dos Sprints

### Metas Principais
1. **Paridade Funcional**: Igualar todas as funcionalidades do React Native
2. **Novas Features**: Implementar funcionalidades críticas ausentes no RN
3. **Performance**: Superar a performance do app React Native
4. **Monetização**: Habilitar fluxo de pagamentos e receita

### Métricas de Sucesso
- [ ] 100% das funcionalidades do RN migradas
- [ ] Fluxo de pagamento funcional
- [ ] Seção financeira do advogado completa
- [ ] Performance 40% superior ao RN
- [ ] 0 funcionalidades perdidas na migração

---

## 📅 Cronograma de Sprints (16 semanas)

### Sprint 1-2: Fundação e Conectividade (Semanas 1-2)
**Objetivo**: Estabelecer conectividade completa com backend

#### Sprint 1 (Semana 1)
**Foco**: Expansão do DioService e Supabase Service

**Tasks**:
- [ ] **Expandir DioService** com todos os endpoints da API
  - [ ] POST /api/triage
  - [ ] GET /api/triage/status/{task_id}
  - [ ] POST /api/match
  - [ ] POST /api/explain
  - [ ] GET /api/cases/my-cases
  - [ ] GET /api/cases/{case_id}
  - [ ] POST/GET /api/cases/{case_id}/messages
  - [ ] POST /api/documents/upload/{case_id}
  - [ ] GET /api/documents/case/{case_id}

- [ ] **Criar SupabaseService completo**
  - [ ] Auth (signUp, signIn, signOut, onAuthStateChange)
  - [ ] Storage (upload, download, getPublicUrl)
  - [ ] Realtime (subscribe to channels)

- [ ] **Configurar Dependency Injection**
  - [ ] Registrar todos os serviços no GetIt
  - [ ] Configurar injeção automática

**Critérios de Aceitação**:
- DioService possui métodos para todos os endpoints documentados
- SupabaseService gerencia auth, storage e realtime
- Injeção de dependência configurada e funcional

#### Sprint 2 (Semana 2)
**Foco**: Implementação da camada de dados (Repositories)

**Tasks**:
- [ ] **AuthRepository e AuthDataSource**
  - [ ] Implementar login/logout
  - [ ] Registro de cliente e advogado
  - [ ] Gestão de sessão

- [ ] **TriageRepository e TriageDataSource**
  - [ ] Iniciar triagem
  - [ ] Polling de status
  - [ ] Recuperar resultado

- [ ] **CasesRepository e CasesDataSource**
  - [ ] Buscar casos do usuário
  - [ ] Detalhes do caso
  - [ ] Upload de documentos

**Critérios de Aceitação**:
- Repositories implementados seguindo Clean Architecture
- DataSources consomem DioService e SupabaseService
- Testes unitários para repositories críticos

### Sprint 3-4: Autenticação e Navegação (Semanas 3-4)

#### Sprint 3 (Semana 3)
**Foco**: Sistema de Autenticação Completo

**Tasks**:
- [ ] **AuthBloc completo**
  - [ ] Estados: Initial, Loading, Authenticated, Unauthenticated, Error
  - [ ] Eventos: Login, Logout, Register, CheckAuth
  - [ ] Integração com AuthRepository

- [ ] **Telas de Autenticação**
  - [ ] LoginScreen conectada ao AuthBloc
  - [ ] RegisterClientScreen com validação
  - [ ] RegisterLawyerScreen com upload de documentos

- [ ] **Navegação Principal (GoRouter)**
  - [ ] Rotas protegidas por autenticação
  - [ ] Redirecionamento baseado no role do usuário

**Critérios de Aceitação**:
- Login/logout funcionais
- Registro de cliente e advogado completos
- Navegação protegida implementada

#### Sprint 4 (Semana 4)
**Foco**: MainTabsShell e Dashboards

**Tasks**:
- [ ] **MainTabsShell (5 abas adaptativas)**
  - [ ] Navegação diferenciada por perfil (cliente/advogado)
  - [ ] Bottom navigation responsivo
  - [ ] Gestão de estado da aba ativa

- [ ] **Dashboard do Cliente (Aba 1)**
  - [ ] Tela inicial com CTA para triagem
  - [ ] Estatísticas básicas de casos
  - [ ] Navegação para triagem

- [ ] **Dashboard do Advogado (Aba 1)**
  - [ ] KPIs: casos ativos, novos leads, alertas
  - [ ] Ações rápidas: casos, mensagens, agenda
  - [ ] Links para gestão de perfil

**Critérios de Aceitação**:
- Navegação principal funcional com 5 abas
- Dashboards diferenciados por perfil
- Navegação entre telas funcionando

### Sprint 5-6: Triagem e Matching (Semanas 5-6)

#### Sprint 5 (Semana 5)
**Foco**: Sistema de Triagem Inteligente

**Tasks**:
- [ ] **TriageBloc e UI**
  - [ ] TriageScreen para descrição do caso
  - [ ] TaskPollingService para acompanhar status
  - [ ] Estados: Initial, Loading, InProgress, Completed, Error
  - [ ] Navegação automática para matches ao completar

- [ ] **Chat de Triagem (se aplicável)**
  - [ ] Interface conversacional com IA
  - [ ] Indicador de digitação
  - [ ] Histórico de mensagens

**Critérios de Aceitação**:
- Cliente pode descrever caso e iniciar triagem
- Polling de status funcional
- Navegação automática para resultados

#### Sprint 6 (Semana 6)
**Foco**: Sistema de Matching de Advogados

**Tasks**:
- [ ] **LawyersBloc e RecommendationsBloc**
  - [ ] Buscar matches baseado no case_id
  - [ ] Explicações de match
  - [ ] Filtros e ordenação

- [ ] **LawyerMatchCard e UI de Matches**
  - [ ] Card com informações do advogado
  - [ ] Score de match visual
  - [ ] Botão "Por que este advogado?"
  - [ ] Seleção de advogado

- [ ] **Tela de Explicações**
  - [ ] Modal ou tela com explicação detalhada
  - [ ] Breakdown das features do algoritmo

**Critérios de Aceitação**:
- Lista de advogados recomendados funcional
- LawyerMatchCard com dados reais do backend
- Explicações de match implementadas

### Sprint 7-8: Gestão de Casos (Semanas 7-8)

#### Sprint 7 (Semana 7)
**Foco**: Lista e Detalhes de Casos

**Tasks**:
- [ ] **CasesBloc e CasesScreen**
  - [ ] Lista de casos do usuário
  - [ ] Filtros por status
  - [ ] Busca por nome/área

- [ ] **CaseDetailScreen**
  - [ ] Informações completas do caso
  - [ ] Timeline de progresso
  - [ ] Ações disponíveis (chat, documentos)

- [ ] **CaseCard component**
  - [ ] Informações resumidas
  - [ ] Status visual
  - [ ] Navegação para detalhes

**Critérios de Aceitação**:
- Lista de casos carregada do backend
- Detalhes do caso com informações completas
- Navegação entre lista e detalhes

#### Sprint 8 (Semana 8)
**Foco**: Chat e Documentos

**Tasks**:
- [ ] **Sistema de Chat em Tempo Real**
  - [ ] MessagesBloc com Supabase Realtime
  - [ ] MessageBubble component
  - [ ] ChatInput com envio de mensagens
  - [ ] Notificações de mensagens não lidas

- [ ] **Gestão de Documentos**
  - [ ] DocumentsBloc para upload/download
  - [ ] Upload usando image_picker/file_picker
  - [ ] Lista de documentos do caso
  - [ ] Visualização/download de arquivos

**Critérios de Aceitação**:
- Chat em tempo real funcional
- Upload de documentos implementado
- Lista e visualização de documentos

### Sprint 9-10: Perfil e Seção Financeira (Semanas 9-10)

#### Sprint 9 (Semana 9)
**Foco**: Tela de Perfil

**Tasks**:
- [ ] **ProfileBloc e ProfileScreen**
  - [ ] Informações do usuário
  - [ ] Edição de perfil
  - [ ] Configurações da conta

- [ ] **ProfileCard component**
  - [ ] Avatar do usuário
  - [ ] Informações básicas
  - [ ] Links para edição

- [ ] **Configurações**
  - [ ] Notificações
  - [ ] Privacidade
  - [ ] Logout

**Critérios de Aceitação**:
- Perfil do usuário carregado e editável
- Configurações funcionais
- Logout implementado

#### Sprint 10 (Semana 10)
**Foco**: Seção Financeira do Advogado

**Tasks**:
- [ ] **FinancialBloc e FinancialScreen**
  - [ ] 3 tipos de honorários (contratuais, êxito, sucumbenciais)
  - [ ] Filtros por período e tipo
  - [ ] Exportação de dados

- [ ] **FinancialCard components**
  - [ ] Cards para cada tipo de honorário
  - [ ] Visualização de valores
  - [ ] Ações específicas (marcar recebido, solicitar repasse)

- [ ] **Gráficos e Relatórios**
  - [ ] Evolução mensal
  - [ ] Timeline de repasses
  - [ ] Indicadores de progresso

**Critérios de Aceitação**:
- Seção financeira completa conforme FLUTTER_FINANCIAL_IMPLEMENTATION.md
- 3 tipos de honorários implementados
- Ações de gestão financeira funcionais

### Sprint 11-12: Funcionalidades Críticas de Negócio (Semanas 11-12)

#### Sprint 11 (Semana 11)
**Foco**: Sistema de Pagamentos

**Tasks**:
- [ ] **PaymentBloc e PaymentService**
  - [ ] Integração com Stripe
  - [ ] Geração de PIX (Pagar.me ou similar)
  - [ ] Webhook handlers

- [ ] **PaymentScreen e PaymentModal**
  - [ ] Seleção de método de pagamento
  - [ ] Formulário de cartão
  - [ ] QR Code PIX
  - [ ] Confirmação de pagamento

- [ ] **Integração com Backend**
  - [ ] Endpoints de pagamento no DioService
  - [ ] Webhooks para confirmação
  - [ ] Atualização de status

**Critérios de Aceitação**:
- Fluxo de pagamento funcional
- Integração com gateway de pagamento
- Confirmação de transações

#### Sprint 12 (Semana 12)
**Foco**: OCR e Validação de Documentos

**Tasks**:
- [ ] **OCRService e DocumentValidationBloc**
  - [ ] Upload e processamento de documentos
  - [ ] Extração de dados (CPF, OAB, etc.)
  - [ ] Validação automática

- [ ] **UI para OCR**
  - [ ] Câmera para captura de documentos
  - [ ] Preview e confirmação
  - [ ] Resultado da extração

- [ ] **Validação de Dados**
  - [ ] Verificação de CPF/CNPJ
  - [ ] Validação de OAB
  - [ ] Feedback visual de validação

**Critérios de Aceitação**:
- OCR funcional para documentos
- Validação automática implementada
- Feedback claro para o usuário

### Sprint 13-14: Assinatura de Contratos (Semanas 13-14)

#### Sprint 13 (Semana 13)
**Foco**: Integração DocuSign

**Tasks**:
- [ ] **ContractService e ContractBloc**
  - [ ] Integração com DocuSign API
  - [ ] Criação de envelopes
  - [ ] Envio para assinatura

- [ ] **Templates de Contrato**
  - [ ] Template HTML/PDF
  - [ ] Campos dinâmicos
  - [ ] Geração automática

**Critérios de Aceitação**:
- Integração com DocuSign funcional
- Templates de contrato configurados

#### Sprint 14 (Semana 14)
**Foco**: UI de Assinatura de Contratos

**Tasks**:
- [ ] **ContractScreen e ContractModal**
  - [ ] Visualização do contrato
  - [ ] Assinatura eletrônica
  - [ ] Status de assinatura

- [ ] **Fluxo Completo**
  - [ ] Geração → Envio → Assinatura → Armazenamento
  - [ ] Notificações de status
  - [ ] Histórico de contratos

**Critérios de Aceitação**:
- Fluxo de assinatura completo
- Contratos armazenados e acessíveis

### Sprint 15-16: Polimento e Deploy (Semanas 15-16)

#### Sprint 15 (Semana 15)
**Foco**: Testes e Otimização

**Tasks**:
- [ ] **Testes Automatizados**
  - [ ] Testes unitários para BLoCs críticos
  - [ ] Testes de integração para fluxos principais
  - [ ] Testes de UI para telas importantes

- [ ] **Otimização de Performance**
  - [ ] Lazy loading de imagens
  - [ ] Cache de dados
  - [ ] Otimização de builds

- [ ] **Correção de Bugs**
  - [ ] Testes de regressão
  - [ ] Correções de UI
  - [ ] Melhorias de UX

**Critérios de Aceitação**:
- Cobertura de testes > 80%
- Performance otimizada
- Bugs críticos corrigidos

#### Sprint 16 (Semana 16)
**Foco**: Deploy e Lançamento

**Tasks**:
- [ ] **Preparação para Produção**
  - [ ] Build de release
  - [ ] Configuração de ambiente
  - [ ] Testes finais

- [ ] **Deploy**
  - [ ] Play Store (Android)
  - [ ] App Store (iOS)
  - [ ] Monitoramento de crash

- [ ] **Documentação**
  - [ ] Documentação técnica
  - [ ] Guia de usuário
  - [ ] Plano de rollback

**Critérios de Aceitação**:
- App em produção
- Monitoramento ativo
- Documentação completa

---

## 📊 Métricas de Acompanhamento

### Métricas por Sprint
- **Velocity**: Story points completados
- **Quality**: Bugs encontrados/corrigidos  
- **Coverage**: Cobertura de testes
- **Performance**: Tempo de build/deploy

### Métricas de Produto
- **User Satisfaction**: NPS e ratings
- **Crash Rate**: Crashes por sessão
- **Performance**: Tempo de resposta
- **Adoption**: Usuários ativos

### Dashboard de Progresso
```
┌─────────────────────────────────────────────────────────────┐
│                    Sprint Progress Dashboard                 │
├─────────────────────────────────────────────────────────────┤
│ Sprint Atual: X/16          Progresso: XX%      Status: ✅   │
│                                                             │
│ Métricas da Semana:                                         │
│ • Features Completadas: X/Y                                │
│ • Cobertura de Testes: XX%                                 │
│ • Bugs Corrigidos: X/X                                     │
│ • Performance: +XX%                                        │
│                                                             │
│ Próximos Marcos:                                            │
│ • Triagem Funcional: Sprint 5                              │
│ • Pagamentos: Sprint 11                                    │
│ • Deploy: Sprint 16                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚨 Riscos e Mitigações

### Riscos Identificados
| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| Delay na integração de pagamentos | Média | Alto | Começar integração no Sprint 11, buffer de 1 semana |
| Problemas de performance | Baixa | Alto | Testes de performance contínuos |
| Bugs na migração | Média | Alto | Testes automatizados desde Sprint 1 |
| Resistência da equipe | Baixa | Médio | Treinamento e mentoria |

### Plano de Contingência
- **Rollback**: Capacidade de voltar para React Native em 24h
- **Hotfix**: Pipeline para correções críticas
- **Support**: Suporte paralelo durante transição

---

## 🎯 Definição de Pronto (DoD)

### Para cada Feature
- [ ] Código implementado e testado
- [ ] Testes unitários com cobertura > 80%
- [ ] UI responsiva e acessível
- [ ] Integração com backend funcional
- [ ] Documentação atualizada
- [ ] Code review aprovado
- [ ] Testes de regressão passando

### Para cada Sprint
- [ ] Todas as tasks completadas
- [ ] Demo funcional preparada
- [ ] Métricas de qualidade atingidas
- [ ] Bugs críticos resolvidos
- [ ] Retrospectiva realizada
- [ ] Próximo sprint planejado

---

## 📚 Recursos Necessários

### Equipe
- **2-3 Desenvolvedores Flutter** (senior/pleno)
- **1 Designer UI/UX** (para validação)
- **1 QA** (testes específicos)
- **1 DevOps** (CI/CD Flutter)

### Ferramentas
- **Flutter SDK 3.16+**
- **Android Studio / VS Code**
- **Supabase CLI**
- **Stripe SDK**
- **DocuSign SDK**

### Treinamento
- **Flutter/Dart**: 40h por desenvolvedor
- **BLoC Pattern**: 16h por desenvolvedor
- **Testing**: 8h por desenvolvedor

---

**Última atualização**: Janeiro 2025  
**Versão**: 1.0  
**Status**: Pronto para execução 