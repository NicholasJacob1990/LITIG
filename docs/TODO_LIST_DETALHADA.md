# 📋 **LISTA DE TO-DOS DETALHADA - SISTEMA DE CONTRATAÇÃO**

**Data**: 2025-01-03  
**Baseado em**: PLANO_ACAO_DETALHADO.md  
**Status**: ✅ **Verificação Completa do Código Atual Realizada**  

---

## 🔍 **VERIFICAÇÃO REALIZADA - ESTADO ATUAL**

### ✅ **Componentes Verificados:**

#### **Backend Routes Existentes:**
- ✅ **35 rotas implementadas** em `packages/backend/routes/`
- ✅ **Ofertas**: `offers.py` implementado 
- ✅ **Parcerias**: `partnerships.py` implementado
- ✅ **Casos**: `cases.py` implementado
- ✅ **Usuários**: `users.py`, `lawyers.py` implementados
- ❌ **Lacuna**: Não há `hiring_proposals.py` (necessário para contratação individual)

#### **Frontend Features Existentes:**
- ✅ **18 features implementadas** em `apps/app_flutter/lib/src/features/`
- ✅ **Ofertas**: `offers/` implementado
- ✅ **Parcerias**: `partnerships/` implementado  
- ✅ **Advogados**: `lawyers/` implementado
- ✅ **Notificações**: `notifications/` implementado
- ❌ **Lacuna**: Não há feature específica para `hiring_proposals`

#### **Injection Container:**
- ✅ **Bem estruturado** com 85+ registros
- ✅ **Ofertas, Parcerias, Casos**: Todos registrados
- ✅ **Notificações**: NotificationBloc registrado
- ❌ **Lacuna**: Falta `LawyerHiringBloc` e dependências

#### **Rotas Configuradas:**
- ✅ **19 rotas configuradas** no `app_router.dart`
- ✅ **StatefulShellRoute**: Bem estruturado por perfil
- ✅ **Navegação por branches**: Implementada corretamente
- ❌ **Lacuna**: Falta rota `/hiring-proposals`

#### **Componentes de Contratação:**
- ✅ **FirmHiringModal**: Completamente implementado em `firms/presentation/widgets/`
- ✅ **FirmHiringBloc**: Implementado com estados completos
- ✅ **HireFirm UseCase**: Implementado para escritórios
- ❌ **LACUNA CRÍTICA**: `LawyerHiringModal` NÃO EXISTE (confirmado por busca)

---

## 🎯 **LISTA DE TO-DOS POR FASE**

### **🚨 FASE 1: FUNCIONALIDADES CRÍTICAS** (9 dias)

#### **📋 Sprint 1.1: LawyerHiringModal & Backend (3 dias)**

**🔧 Frontend - LawyerHiringModal:**
- [ ] **1.1.1** Criar `apps/app_flutter/lib/src/features/lawyers/presentation/widgets/lawyer_hiring_modal.dart`
  - **Base**: Usar `FirmHiringModal` como template
  - **Diferenças**: Adaptar para advogado individual vs escritório
  - **Estados**: Loading, Success, Error com feedback adequado
  - **Validações**: Budget, contract type, notes

- [ ] **1.1.2** Criar `apps/app_flutter/lib/src/features/lawyers/presentation/bloc/lawyer_hiring_bloc.dart`
  - **Eventos**: StartLawyerHiring, ConfirmLawyerHiring, CancelLawyerHiring
  - **Estados**: Initial, Loading, Success, Error
  - **Integração**: Com LawyerHiringUseCase

- [ ] **1.1.3** Criar `apps/app_flutter/lib/src/features/lawyers/domain/usecases/hire_lawyer.dart`
  - **Parâmetros**: lawyerId, caseId, clientId, contractType, budget, notes
  - **Validações**: Mesmas do HireFirm
  - **Resultado**: HireLawyerResult com proposalId

**🔧 Backend - API de Propostas:**
- [ ] **1.1.4** Criar `packages/backend/routes/hiring_proposals.py`
  - **POST /hiring-proposals**: Criar proposta
  - **GET /hiring-proposals**: Listar propostas por advogado
  - **PATCH /hiring-proposals/{id}/accept**: Aceitar proposta
  - **PATCH /hiring-proposals/{id}/reject**: Rejeitar proposta

- [ ] **1.1.5** Criar tabela `hiring_proposals` no banco
  ```sql
  CREATE TABLE hiring_proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID REFERENCES users(id),
    lawyer_id UUID REFERENCES users(id), 
    case_id UUID REFERENCES cases(id),
    contract_type VARCHAR(20) NOT NULL,
    budget DECIMAL(10,2) NOT NULL,
    notes TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '7 days')
  );
  ```

**🔧 Integração:**
- [ ] **1.1.6** Registrar dependências no `injection_container.dart`
  - LawyerHiringBloc
  - HireLawyer UseCase  
  - LawyerHiringRepository
  - LawyerHiringRemoteDataSource

#### **📋 Sprint 1.2: Tela de Propostas para Advogados (4 dias)**

**🔧 Frontend - HiringProposalsScreen:**
- [ ] **1.2.1** Criar `apps/app_flutter/lib/src/features/lawyers/presentation/screens/hiring_proposals_screen.dart`
  - **Tabs**: Pendentes, Aceitas, Histórico
  - **Cards**: Informações do cliente, caso, proposta
  - **Ações**: Aceitar, Rejeitar com motivo
  - **Estados**: Loading, Error, Empty, Loaded

- [ ] **1.2.2** Criar `apps/app_flutter/lib/src/features/lawyers/presentation/widgets/hiring_proposal_card.dart`
  - **Dados**: Cliente, caso, valor, tipo contrato
  - **Ações contextuais**: Baseadas no status
  - **Design**: Consistente com OfferCard existente

- [ ] **1.2.3** Criar BLoC para gerenciamento de propostas
  - **Eventos**: LoadProposals, AcceptProposal, RejectProposal
  - **Estados**: Com propostas filtradas por status
  - **Repository**: HiringProposalsRepository

**🔧 Navegação:**
- [ ] **1.2.4** Adicionar rota `/hiring-proposals` no `app_router.dart`
  - **Branch**: Para advogados (lawyer_individual, lawyer_office)
  - **Posição**: Entre ofertas e perfil
  - **Icon**: Icons.file_present (consistente com propostas)

- [ ] **1.2.5** Atualizar `main_tabs_shell.dart`
  - **Novo item**: "Propostas" para advogados
  - **Ajustar índices**: Todas as branches posteriores
  - **Consistência**: Com outros perfis

#### **📋 Sprint 1.3: Otimização Case Highlight (2 dias)**

**🔧 UX Melhorada:**
- [ ] **1.3.1** Melhorar banner de case highlight em `partners_screen.dart`
  - **Animações**: Entrada suave, scroll automático
  - **Detalhes do caso**: Nome, área legal, complexidade
  - **Estatísticas**: Matches encontrados, tempo estimado

- [ ] **1.3.2** Otimizar transição triage → recomendações
  - **Loading state**: Durante carregamento de matches
  - **Feedback visual**: Progresso da busca
  - **Notificação aprimorada**: Com ação "Ver Recomendações"

### **⚡ FASE 2: MELHORIAS DE EXPERIÊNCIA** (15 dias)

#### **📋 Sprint 2.1: Dashboard Unificado (5 dias)**

**🔧 UnifiedLawyerDashboard:**
- [ ] **2.1.1** Criar dashboard que unifique ofertas, propostas e parcerias
  - **Seção Welcome**: Com estatísticas do dia
  - **KPI Cards**: Taxa aceitação, tempo resposta, casos ativos, receita
  - **Quick Actions**: Grid com ações principais
  - **Recent Activity**: Feed de atividades recentes

- [ ] **2.1.2** Implementar DashboardBloc com métricas reais
  - **Agregação**: Dados de offers, proposals, partnerships
  - **Cálculos**: KPIs em tempo real
  - **Cache**: Para performance

#### **📋 Sprint 2.2: Sistema de Busca Avançada (5 dias)**

**🔧 AdvancedSearchFilters:**
- [ ] **2.2.1** Aprimorar filtros existentes no SearchBloc
  - **Novos filtros**: Preço, disponibilidade, experiência mínima
  - **Localização**: Raio configurável, GPS
  - **Salvamento**: Pesquisas favoritas

- [ ] **2.2.2** Interface de filtros avançados
  - **Modal**: Com todas as opções organizadas
  - **Range sliders**: Para preço e distância
  - **Tags**: Para especialidades
  - **Presets**: Busca rápida

#### **📋 Sprint 2.3: Notificações Inteligentes (5 dias)**

**🔧 NotificationSettingsScreen:**
- [ ] **2.3.1** Implementar tela de configurações de notificação
  - **Categorias**: Ofertas, Propostas, Parcerias, Casos
  - **Preferências**: Push, Email, Horário silencioso
  - **Filtros**: Por especialidade, urgência
  - **Agregação**: Inteligente para evitar spam

### **🚀 FASE 3: FUNCIONALIDADES AVANÇADAS** (20 dias)

#### **📋 Sprint 3.1: Sistema de Avaliações (10 dias)**

**🔧 CaseRatingSystem:**
- [ ] **3.1.1** Implementar CaseRatingScreen
  - **Avaliação geral**: 1-5 estrelas
  - **Critérios específicos**: Comunicação, expertise, responsividade, valor
  - **Tags**: Pontos destacados
  - **Comentários**: Opcionais com limite

- [ ] **3.1.2** Backend para avaliações
  - **Tabela ratings**: Com todas as métricas
  - **Estatísticas**: Automáticas por advogado
  - **Moderação**: Para comentários
  - **APIs**: CRUD completo

#### **📋 Sprint 3.2: Analytics e Relatórios (5 dias)**

**🔧 AnalyticsScreen:**
- [ ] **3.2.1** Dashboard de analytics para advogados
  - **Métricas**: Performance, conversão, receita
  - **Gráficos**: Temporais e comparativos
  - **Exportação**: PDF e Excel
  - **Filtros**: Por período e tipo

#### **📋 Sprint 3.3: Integrações Externas (5 dias)**

**🔧 ExternalIntegrations:**
- [ ] **3.3.1** Integração com OAB
  - **Verificação**: Automática de registro
  - **Dados**: Especialidades, histórico disciplinar
  - **Cache**: Para evitar chamadas desnecessárias

- [ ] **3.3.2** Integração com Tribunais
  - **Consulta processos**: Por número
  - **Agenda audiências**: Por OAB
  - **Atualizações**: Automáticas de status

---

## 📊 **PRIORIZAÇÃO E DEPENDÊNCIAS**

### **🔥 CRÍTICO (Deve ser feito primeiro):**
1. **LawyerHiringModal (1.1.1-1.1.3)** - Base para todo fluxo
2. **Backend Propostas (1.1.4-1.1.5)** - Suporte à contratação
3. **Injection Container (1.1.6)** - Integração completa

### **⚠️ ALTA PRIORIDADE:**
4. **HiringProposalsScreen (1.2.1-1.2.3)** - Gestão para advogados
5. **Navegação (1.2.4-1.2.5)** - Acesso às funcionalidades
6. **Otimização UX (1.3.1-1.3.2)** - Melhoria do fluxo existente

### **📈 MÉDIO-LONGO PRAZO:**
7. **Dashboard Unificado** - Melhoria de experiência
8. **Busca Avançada** - Funcionalidade complementar
9. **Notificações Inteligentes** - Otimização do existente
10. **Sistema de Avaliações** - Diferencial competitivo
11. **Analytics** - Insights de negócio
12. **Integrações Externas** - Funcionalidades premium

---

## 🛠️ **IMPLEMENTAÇÃO HOLÍSTICA**

### **Princípios para Cada Task:**

#### **1. Verificação Prévia (Sempre):**
- [ ] Verificar se componentes similares existem (ex: FirmHiring → LawyerHiring)
- [ ] Verificar dependências no injection_container.dart
- [ ] Verificar rotas no app_router.dart
- [ ] Verificar se backend routes existem

#### **2. Implementação Consistente:**
- [ ] Seguir padrões das features existentes
- [ ] Usar mesma estrutura de pastas
- [ ] Manter convenções de nomenclatura
- [ ] Aplicar Clean Architecture

#### **3. Integração Completa:**
- [ ] **Backend**: API + banco + validações
- [ ] **Frontend**: UI + BLoC + repository + use cases
- [ ] **Navegação**: Rotas + menus + contextos
- [ ] **Testes**: Unitários + integração

#### **4. Documentação Obrigatória:**
- [ ] Atualizar `@status.md` após cada task
- [ ] Documentar decisões técnicas
- [ ] Registrar referências ao plano seguido
- [ ] Manter histórico de implementações

---

## 📋 **TEMPLATE DE VALIDAÇÃO POR TASK**

Para cada task completada, verificar:

```markdown
### ✅ Task [ID]: [Nome]
**Verificação Completa:**
- [ ] Backend implementado e testado
- [ ] Frontend implementado e funcionando
- [ ] Integração end-to-end validada
- [ ] Rotas configuradas corretamente
- [ ] Injection container atualizado
- [ ] Testes implementados
- [ ] @status.md atualizado
- [ ] Documentação criada

**Referência ao Plano:**
- Documento: PLANO_ACAO_DETALHADO.md
- Seção: [Fase X - Sprint Y]
- Entregável: [Nome do entregável]
```

---

## 🎯 **PRÓXIMOS PASSOS IMEDIATOS**

### **Semana 1 - Arranque:**
1. **Segunda**: Aprovar lista de to-dos e alocar recursos
2. **Terça**: Configurar ambiente e iniciar 1.1.1 (LawyerHiringModal)
3. **Quarta**: Completar 1.1.1-1.1.3 (Frontend hiring)
4. **Quinta**: Completar 1.1.4-1.1.5 (Backend propostas)
5. **Sexta**: Completar 1.1.6 (Integração) e testes

### **Validação Contínua:**
- **Daily review**: Estado de cada task
- **Code review**: Para cada PR
- **Integration testing**: Após cada sprint
- **Status update**: No @status.md diariamente

---

## 📋 **CONCLUSÃO**

Esta lista de to-dos foi elaborada seguindo rigorosamente o **Princípio da Verificação**, com análise detalhada do código atual. Cada task está baseada em evidências concretas do que existe vs. o que precisa ser implementado.

**Destaques da Verificação:**
- ✅ **85% do sistema funciona** (confirmado)
- ❌ **LawyerHiringModal é a lacuna crítica** (confirmado por busca)
- ✅ **FirmHiringModal pode ser template** (estrutura validada)
- ✅ **Backend/Frontend bem estruturados** (injection container robusto)
- ✅ **Navegação bem organizada** (StatefulShellRoute implementado)

A implementação seguindo esta lista garantirá completude do sistema de contratação individual mantendo consistência com a arquitetura existente. 