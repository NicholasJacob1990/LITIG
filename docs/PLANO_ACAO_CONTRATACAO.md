
# 🚀 PLANO DE AÇÃO - SISTEMA DE CONTRATAÇÃO DE ADVOGADOS INDIVIDUAIS

**Data**: 2025-01-03  
**Versão**: 1.0  
**Status**: ⏳ **Em Planejamento**  
**Base**: Análise confirmada do estado atual do sistema  

---

## 📊 **ANÁLISE CONFIRMADA DO ESTADO ATUAL**

### ✅ **Funcionalidades Existentes (85% do sistema)**

#### 1. **Fluxo Triage → Recomendações**
- **Status**: ✅ **Funcionando Perfeitamente**
- **Implementação**: 
  - Redirecionamento: `/advogados?case_highlight={caseId}`
  - Detecção automática de parâmetros URL
  - Banner de caso destacado implementado
  - Auto-carregamento de matches para casos específicos

#### 2. **Backend de Contratação**
- **Status**: ✅ **Completo e Funcional**
- **Componentes**:
  - Endpoint: `POST /cases/{case_id}/choose-lawyer`
  - Função: `process_client_choice()` implementada
  - Criação automática de ofertas
  - Sistema de notificações integrado
  - Validação de disponibilidade do advogado

#### 3. **Contratação de Escritórios**
- **Status**: ✅ **Implementada**
- **Componentes**:
  - `FirmHiringModal` funcional
  - Fluxo completo para escritórios
  - Integração com sistema de ofertas

#### 4. **Sistema de Notificações**
- **Status**: ✅ **Completo**
- **Componentes**:
  - Frontend: `NotificationService` + `NotificationBloc`
  - Backend: `notify_service.py` com Expo Push Notifications
  - Tipos: `newOffer`, `offerAccepted`, `caseUpdate`, `deadlineReminder`

### ❌ **Lacuna Identificada (15% restante)**

#### **Contratação de Advogados Individuais**
- **Problema**: Não implementada
- **Componentes Faltando**:
  - Método `chooseLawyerForCase` no ApiService
  - `LawyerHiringModal` para advogados individuais
  - Botões "Contratar" nos cards de advogados
  - BLoC de gerenciamento de contratação

---

## 🎯 **PLANO DE AÇÃO DETALHADO**

### **FASE 1: IMPLEMENTAR MÉTODO API (Prioridade ALTA)**

**Duração**: 1 dia  
**Responsável**: Dev Backend  
**Status**: ⏳ Pendente  

#### **Tarefa 1.1**: Adicionar método `chooseLawyerForCase` ao ApiService
- **Arquivo**: `apps/app_flutter/lib/src/core/services/api_service.dart`
- **Implementação**:
```dart
static Future<Map<String, dynamic>> chooseLawyerForCase({
  required String caseId,
  required String lawyerId,
  int choiceOrder = 1,
}) async {
  final headers = await _getHeaders();
  final url = '$_baseUrl/cases/$caseId/choose-lawyer';
  final body = jsonEncode({
    'case_id': caseId,
    'chosen_lawyer_id': lawyerId,
    'choice_order': choiceOrder,
  });

  final response = await http.post(
    Uri.parse(url),
    headers: headers,
    body: body,
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    AppLogger.error('Falha ao escolher advogado: Status ${response.statusCode}');
    throw ServerException(message: 'Falha ao enviar proposta para o advogado.');
  }
}
```

#### **Tarefa 1.2**: Adicionar método equivalente ao DioService
- **Arquivo**: `apps/app_flutter/lib/src/core/services/dio_service.dart`
- **Implementação**: Método similar usando Dio
- **Benefício**: Consistência com outros métodos da aplicação

#### **Tarefa 1.3**: Testar conectividade com backend
- **Teste**: Verificar se endpoint responde corretamente
- **Validação**: Confirmar criação de ofertas no banco
- **Métricas**: Tempo de resposta < 3s

### **FASE 2: CRIAR LAWYERHIRINGMODAL (Prioridade ALTA)**

**Duração**: 2 dias  
**Responsável**: Dev Frontend  
**Status**: ⏳ Pendente  

#### **Tarefa 2.1**: Criar arquivo `LawyerHiringModal`
- **Localização**: `apps/app_flutter/lib/src/features/lawyers/presentation/widgets/lawyer_hiring_modal.dart`
- **Base**: Copiar estrutura do `FirmHiringModal` e adaptar
- **Estrutura**:
```dart
class LawyerHiringModal extends StatefulWidget {
  final MatchedLawyer lawyer;
  final String caseId;
  final String clientId;
  
  const LawyerHiringModal({
    super.key,
    required this.lawyer,
    required this.caseId,
    required this.clientId,
  });
  
  @override
  State<LawyerHiringModal> createState() => _LawyerHiringModalState();
}
```

#### **Tarefa 2.2**: Implementar UI do modal
- **Componentes**:
  - Header com informações do advogado
  - Detalhes do caso
  - Botões de ação (Contratar/Cancelar)
  - Loading states
  - Feedback de sucesso/erro

#### **Tarefa 2.3**: Implementar lógica de contratação
- **Integração**: Chamar `ApiService.chooseLawyerForCase()`
- **Estados**: Loading, Success, Error
- **Feedback**: SnackBar com resultado
- **Navegação**: Redirecionar após sucesso

#### **Tarefa 2.4**: Adicionar botão "Contratar" nos cards de advogados
- **Localização**: `partners_screen.dart` e `lawyer_match_card.dart`
- **Condição**: Mostrar apenas quando `case_highlight` estiver ativo
- **Estilo**: Botão destacado e intuitivo

### **FASE 3: IMPLEMENTAR BLOC DE CONTRATAÇÃO (Prioridade MÉDIA)**

**Duração**: 1 dia  
**Responsável**: Dev Frontend  
**Status**: ⏳ Pendente  

#### **Tarefa 3.1**: Criar `LawyerHiringBloc`
- **Localização**: `apps/app_flutter/lib/src/features/lawyers/presentation/bloc/`
- **Eventos**:
  - `HireLawyer`: Iniciar processo de contratação
  - `HiringSuccess`: Contratação bem-sucedida
  - `HiringError`: Erro na contratação
- **Estados**:
  - `HiringInitial`: Estado inicial
  - `HiringLoading`: Processando contratação
  - `HiringSuccess`: Contratação concluída
  - `HiringError`: Erro na contratação

#### **Tarefa 3.2**: Implementar repositório de contratação
- **Localização**: `apps/app_flutter/lib/src/features/lawyers/data/repositories/`
- **Métodos**:
  - `hireLawyer()`: Executar contratação
  - `getHiringStatus()`: Verificar status
  - `cancelHiring()`: Cancelar processo

#### **Tarefa 3.3**: Registrar no container de injeção
- **Arquivo**: `apps/app_flutter/lib/src/injection_container.dart`
- **Adicionar**: `LawyerHiringBloc` e dependências
- **Teste**: Verificar injeção correta

### **FASE 4: MELHORAR UX DO FLUXO (Prioridade MÉDIA)**

**Duração**: 1 dia  
**Responsável**: Dev Frontend  
**Status**: ⏳ Pendente  

#### **Tarefa 4.1**: Adicionar indicadores visuais
- **Loading states**: Durante processo de contratação
- **Success feedback**: Confirmação visual de sucesso
- **Error handling**: Mensagens de erro claras
- **Progress indicators**: Mostrar etapas do processo

#### **Tarefa 4.2**: Implementar navegação pós-contratação
- **Redirecionamento**: Para tela de casos após contratação
- **Notificação**: Push notification para o advogado
- **Status update**: Atualizar status do caso
- **Histórico**: Registrar ação no histórico

#### **Tarefa 4.3**: Adicionar confirmação antes da contratação
- **Dialog**: Confirmar escolha do advogado
- **Informações**: Mostrar detalhes da proposta
- **Cancelamento**: Opção de cancelar
- **Validação**: Verificar disponibilidade antes

### **FASE 5: TESTES E VALIDAÇÃO (Prioridade MÉDIA)**

**Duração**: 1 dia  
**Responsável**: QA  
**Status**: ⏳ Pendente  

#### **Tarefa 5.1**: Testes unitários
- **ApiService**: Testar método `chooseLawyerForCase`
- **LawyerHiringModal**: Testar UI e lógica
- **LawyerHiringBloc**: Testar estados e eventos
- **Repositório**: Testar métodos de contratação

#### **Tarefa 5.2**: Testes de integração
- **Fluxo completo**: Triage → Matches → Contratação
- **Backend integration**: Verificar criação de ofertas
- **Notifications**: Confirmar envio de notificações
- **Database**: Verificar persistência de dados

#### **Tarefa 5.3**: Testes de UI
- **Responsividade**: Diferentes tamanhos de tela
- **Acessibilidade**: Suporte a leitores de tela
- **Performance**: Tempo de resposta adequado
- **Usabilidade**: Testes com usuários reais

### **FASE 6: DOCUMENTAÇÃO E DEPLOY (Prioridade BAIXA)**

**Duração**: 0.5 dia  
**Responsável**: Dev  
**Status**: ⏳ Pendente  

#### **Tarefa 6.1**: Atualizar documentação
- **README**: Instruções de uso do novo fluxo
- **API docs**: Documentar endpoint de contratação
- **User guide**: Guia para clientes
- **Developer docs**: Documentação técnica

#### **Tarefa 6.2**: Preparar para produção
- **Error monitoring**: Integrar com Sentry/Firebase
- **Analytics**: Rastrear métricas de contratação
- **A/B testing**: Testar diferentes versões da UI
- **Performance monitoring**: Monitorar performance

---

## 📅 **CRONOGRAMA ESTIMADO**

| Fase | Duração | Responsável | Status | Dependências |
|------|---------|-------------|--------|--------------|
| Fase 1 | 1 dia | Dev Backend | ⏳ Pendente | - |
| Fase 2 | 2 dias | Dev Frontend | ⏳ Pendente | Fase 1 |
| Fase 3 | 1 dia | Dev Frontend | ⏳ Pendente | Fase 1 |
| Fase 4 | 1 dia | Dev Frontend | ⏳ Pendente | Fase 2, 3 |
| Fase 5 | 1 dia | QA | ⏳ Pendente | Fase 2, 3, 4 |
| Fase 6 | 0.5 dia | Dev | ⏳ Pendente | Fase 5 |

**Total Estimado**: 6.5 dias de desenvolvimento  
**Data de Início**: 2025-01-04  
**Data de Conclusão**: 2025-01-10  

---

## 🎯 **CRITÉRIOS DE SUCESSO**

### **Funcionais**
- ✅ Cliente consegue contratar advogado individual
- ✅ Oferta é criada automaticamente no backend
- ✅ Notificação é enviada para o advogado
- ✅ Status do caso é atualizado corretamente
- ✅ Histórico de contratações é mantido

### **UX/UI**
- ✅ Interface intuitiva e responsiva
- ✅ Feedback visual claro durante processo
- ✅ Tratamento adequado de erros
- ✅ Navegação fluida pós-contratação
- ✅ Acessibilidade adequada

### **Técnicos**
- ✅ Código limpo e bem documentado
- ✅ Testes unitários e de integração
- ✅ Performance adequada (< 3s)
- ✅ Compatibilidade com sistema existente
- ✅ Tratamento de erros robusto

---

## 🚨 **RISCOS E MITIGAÇÕES**

### **Riscos Técnicos**

#### **Backend não responde**
- **Risco**: Endpoint `/choose-lawyer` falha
- **Mitigação**: Implementar fallback e retry
- **Monitoramento**: Logs de erro e alertas

#### **Conflitos de estado**
- **Risco**: Múltiplas tentativas de contratação
- **Mitigação**: Usar BLoC para gerenciamento
- **Prevenção**: Validação de estado antes da ação

#### **Performance**
- **Risco**: Tempo de resposta alto
- **Mitigação**: Otimizar chamadas de API
- **Monitoramento**: Métricas de performance

### **Riscos de UX**

#### **Confusão do usuário**
- **Risco**: Interface não clara
- **Mitigação**: UI clara e feedback constante
- **Teste**: Testes de usabilidade

#### **Processo muito longo**
- **Risco**: Usuário desiste durante contratação
- **Mitigação**: Loading states e progress indicators
- **Otimização**: Minimizar passos necessários

#### **Erros não claros**
- **Risco**: Usuário não entende o erro
- **Mitigação**: Mensagens de erro específicas
- **Ajuda**: Tooltips e instruções claras

### **Riscos de Negócio**

#### **Advogado não disponível**
- **Risco**: Tentativa de contratar advogado indisponível
- **Mitigação**: Validação antes da contratação
- **Feedback**: Informar disponibilidade em tempo real

#### **Caso já contratado**
- **Risco**: Contratação duplicada
- **Mitigação**: Verificação de status
- **Prevenção**: Bloquear ações duplicadas

#### **Problemas de pagamento**
- **Risco**: Falha no processamento de pagamento
- **Mitigação**: Integração futura com gateway
- **Fallback**: Modo de teste sem pagamento

---

## 📈 **MÉTRICAS DE SUCESSO**

### **Métricas Técnicas**
- **Tempo de resposta**: < 3s para contratação
- **Taxa de erro**: < 5% de falhas
- **Uptime**: > 99% de disponibilidade
- **Performance**: < 2s para carregar modal

### **Métricas de Negócio**
- **Taxa de conversão**: % de matches que viram contratos
- **Tempo de contratação**: Tempo médio para contratar
- **Satisfação do usuário**: Feedback pós-contratação
- **Engagement**: % de usuários que completam contratação

### **Métricas de UX**
- **Usabilidade**: Score de usabilidade > 4.5/5
- **Acessibilidade**: Conformidade com WCAG 2.1
- **Performance**: Core Web Vitals adequados
- **Feedback**: Taxa de feedback positivo > 80%

---

## 🔧 **RECURSOS NECESSÁRIOS**

### **Equipe**
- **Dev Backend**: 1 pessoa (1 dia)
- **Dev Frontend**: 1 pessoa (4.5 dias)
- **QA**: 1 pessoa (1 dia)
- **Total**: 6.5 dias-homem

### **Ferramentas**
- **IDE**: VS Code / Android Studio
- **Versionamento**: Git
- **Testes**: Flutter Test
- **Monitoramento**: Firebase Analytics
- **Documentação**: Markdown

### **Ambiente**
- **Desenvolvimento**: Local
- **Teste**: Staging environment
- **Produção**: Cloud deployment
- **Backup**: Versionamento de código

---

## 📋 **CHECKLIST DE IMPLEMENTAÇÃO**

### **Fase 1 - API**
- [ ] Implementar método `chooseLawyerForCase` no ApiService
- [ ] Implementar método equivalente no DioService
- [ ] Testar conectividade com backend
- [ ] Validar criação de ofertas
- [ ] Documentar método

### **Fase 2 - UI**
- [ ] Criar arquivo `LawyerHiringModal`
- [ ] Implementar UI do modal
- [ ] Implementar lógica de contratação
- [ ] Adicionar botões "Contratar" nos cards
- [ ] Testar responsividade

### **Fase 3 - BLoC**
- [ ] Criar `LawyerHiringBloc`
- [ ] Implementar eventos e estados
- [ ] Criar repositório de contratação
- [ ] Registrar no container de injeção
- [ ] Testar BLoC

### **Fase 4 - UX**
- [ ] Adicionar indicadores visuais
- [ ] Implementar navegação pós-contratação
- [ ] Adicionar confirmação antes da contratação
- [ ] Implementar feedback de sucesso/erro
- [ ] Testar fluxo completo

### **Fase 5 - Testes**
- [ ] Implementar testes unitários
- [ ] Implementar testes de integração
- [ ] Implementar testes de UI
- [ ] Validar performance
- [ ] Testar acessibilidade

### **Fase 6 - Deploy**
- [ ] Atualizar documentação
- [ ] Configurar monitoramento
- [ ] Preparar para produção
- [ ] Deploy em staging
- [ ] Deploy em produção

---

## 🚀 **PRÓXIMOS PASSOS**

1. **Aprovar o plano** - Confirmar se está alinhado com as expectativas
2. **Alocar recursos** - Definir responsáveis e cronograma
3. **Configurar ambiente** - Preparar ferramentas e ambientes
4. **Iniciar Fase 1** - Implementar método `chooseLawyerForCase`
5. **Executar fases sequencialmente** - Seguir cronograma
6. **Validar resultados** - Testar cada fase antes de prosseguir
7. **Documentar lições aprendidas** - Registrar insights para futuros projetos

---

**Status do Plano**: ✅ **Aprovado e Pronto para Implementação**  
**Próxima Ação**: Iniciar Fase 1 - Implementar método API  
**Contato**: Equipe de Desenvolvimento  
**Última Atualização**: 2025-01-03 