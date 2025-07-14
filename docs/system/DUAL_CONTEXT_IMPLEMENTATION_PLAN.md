# Plano de Implementação: Funcionalidade de Contexto Duplo

> **📄 Documento Relacionado**: Este plano complementa o `PLANO_CONTEXTO_DUPLO_ADVOGADOS.md` fornecendo uma visão mais detalhada e estratégica da mesma implementação. Para uma abordagem mais concisa e focada na implementação, consulte o documento relacionado.

## 📋 **Visão Geral**

Este documento detalha o plano de implementação da funcionalidade de "contexto duplo" para a plataforma LITGO, permitindo que advogados contratantes (`lawyer_individual`, `lawyer_office`, `lawyer_platform_associate`) possam criar e gerenciar casos como se fossem clientes.

### **Contexto Estratégico**

A implementação complementa perfeitamente o sistema de busca avançada recém-implementado:
- **Sistema de Busca**: Advogados procurando outros advogados (correspondentes, especialistas)
- **Contexto Duplo**: Advogados criando casos como clientes

### **Problema Identificado**

Conforme documentado em `ANALISE_NAVEGACAO_FLUTTER.md`:
- ✅ Advogados contratantes **podem** criar casos (via aba "Início" → `HomeScreen` → `/triage`)
- ❌ Mas **não têm** uma forma intuitiva de **gerenciar** os casos que criaram
- ❌ Precisam navegar por um fluxo indireto para criar novos casos

### **Solução Proposta**

Adicionar aba "Meus Casos" com FloatingActionButton para criação direta de casos, proporcionando UX otimizada para advogados contratantes.

---

## 🎯 **Objetivos**

### **Objetivos Primários**
1. **Melhorar UX**: Proporcionar fluxo intuitivo para advogados contratantes gerenciarem casos criados
2. **Completar Funcionalidade**: Implementar contexto duplo completo na plataforma
3. **Manter Consistência**: Seguir padrões arquiteturais estabelecidos

### **Objetivos Secundários**
1. **Reduzir Fricção**: Eliminar navegação indireta para criação de casos
2. **Aumentar Engajamento**: Facilitar uso da plataforma por advogados contratantes
3. **Preparar B2B**: Estabelecer base para funcionalidades B2B avançadas

---

## 🏗️ **Arquitetura Técnica**

### **Componentes Afetados**
1. **Navegação**: `app_router.dart`, `main_tabs_shell.dart`
2. **Telas**: `CasesScreen`
3. **Lógica**: `CasesBloc` (potencial ajuste)

### **Padrões Seguidos**
- ✅ `StatefulShellBranch` para nova rota
- ✅ Consistência nos `branchIndex` com comentários descritivos
- ✅ Reutilização de `CasesScreen` (DRY principle)
- ✅ Integração com `go_router` estabelecida
- ✅ Simplicidade sobre complexidade (evitar over-engineering)

---

## 📝 **Plano de Implementação Detalhado**

### **Fase 1: Atualização da Navegação**

#### **1.1. Modificar Rotas no `app_router.dart`**

**Arquivo**: `apps/app_flutter/lib/src/router/app_router.dart`

**Alteração**: Inserir nova rota `/contractor-cases` no grupo de abas do "Advogado Contratante"

```dart
// --- Advogado Contratante (índices 6-12 APÓS ALTERAÇÃO) ---
StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())]),                    // 6: Início
// ⬇️ ADICIONAR NOVA ROTA AQUI ⬇️
StatefulShellBranch(routes: [GoRoute(path: '/contractor-cases', builder: (context, state) => const CasesScreen())]),      // 7: Meus Casos (NOVA)
StatefulShellBranch(routes: [GoRoute(path: '/contractor-offers', builder: (context, state) => const CaseOffersScreen())]), // 8: Ofertas (antes era 7)
StatefulShellBranch(routes: [GoRoute(path: '/partners', builder: (context, state) => const LawyerSearchScreen())]),       // 9: Parceiros (antes era 8)
StatefulShellBranch(routes: [GoRoute(path: '/partnerships', builder: (context, state) => const PartnershipsScreen())]),   // 10: Parcerias (antes era 9)
StatefulShellBranch(routes: [GoRoute(path: '/contractor-messages', builder: (context, state) => const MessagesScreen())]), // 11: Mensagens (antes era 10)
StatefulShellBranch(routes: [GoRoute(path: '/contractor-profile', builder: (context, state) => const ProfileScreen())]),  // 12: Perfil (antes era 11)

// --- Cliente (índices 13-18 APÓS ALTERAÇÃO) ---
StatefulShellBranch(routes: [GoRoute(path: '/client-home', builder: (context, state) => const HomeScreen())]),       // 13: Início (antes era 12)
StatefulShellBranch(routes: [GoRoute(path: '/client-cases', builder: (context, state) => const CasesScreen())]),     // 14: Meus Casos (antes era 13)
// ... demais rotas com índices ajustados
```

#### **1.2. Atualizar Navegação em `main_tabs_shell.dart`**

**Arquivo**: `apps/app_flutter/lib/src/shared/widgets/organisms/main_tabs_shell.dart`

**Alteração**: Adicionar item "Meus Casos" e ajustar `branchIndex` das abas subsequentes

```dart
case 'lawyer_individual':
case 'lawyer_office':
case 'lawyer_platform_associate':
  return [
    NavItem(label: 'Início', icon: LucideIcons.home, branchIndex: 6),
    // ⬇️ ADICIONAR NOVA ABA AQUI ⬇️
    NavItem(label: 'Meus Casos', icon: LucideIcons.clipboardList, branchIndex: 7), 
    // ⬇️ ATUALIZAR ÍNDICES DAS ABAS SEGUINTES ⬇️
    NavItem(label: 'Ofertas', icon: LucideIcons.inbox, branchIndex: 8), 
    NavItem(label: 'Parceiros', icon: LucideIcons.search, branchIndex: 9),
    NavItem(label: 'Parcerias', icon: LucideIcons.users, branchIndex: 10),
    NavItem(label: 'Mensagens', icon: LucideIcons.messageSquare, branchIndex: 11),
    NavItem(label: 'Perfil', icon: LucideIcons.user, branchIndex: 12),
  ];
```

### **Fase 2: Atualização da CasesScreen**

#### **2.1. Adicionar FloatingActionButton**

**Arquivo**: `apps/app_flutter/lib/src/features/cases/presentation/screens/cases_screen.dart`

**Alterações**:
1. Importar `go_router`
2. Adicionar `FloatingActionButton.extended`
3. Remover botão duplicado do `_buildEmptyState`

```dart
import 'package:go_router/go_router.dart'; // 👈 IMPORTAR GO_ROUTER

class CasesScreen extends StatelessWidget {
  const CasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CasesBloc>()..add(FetchCases()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meus Casos'),
          centerTitle: true,
        ),
        // ⬇️ ADICIONAR BOTÃO FLUTUANTE AQUI ⬇️
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/triage'), // Inicia o fluxo de triagem
          label: const Text('Criar Novo Caso'),
          icon: const Icon(LucideIcons.plus),
        ),
        body: Column(
          // ... existing code ...
        ),
      ),
    );
  }
}
```

---

## ⚠️ **Pontos Críticos de Atenção**

### **1. Risco dos Índices (`branchIndex`)**
- **Criticidade**: ALTA
- **Descrição**: Erro nos `branchIndex` fará abas apontarem para telas erradas
- **Mitigação**: Usar comentários descritivos inline (melhor prática) em vez de abstrações complexas como enums
- **Boas Práticas**: Comentários claros no código são preferíveis a over-engineering

### **2. Comportamento do CasesBloc**
- **Criticidade**: MÉDIA
- **Descrição**: `CasesBloc` deve buscar casos criados pelo advogado, não atribuídos a ele
- **Mitigação**: Verificar se lógica atual funciona ou implementar contexto

### **3. Navegação Consistente**
- **Criticidade**: BAIXA
- **Descrição**: Garantir que `/triage` funciona corretamente para todos os perfis
- **Mitigação**: Testes de integração

---

## 🚀 **Melhorias Recomendadas**

> **💡 Princípio**: Manter simplicidade e evitar over-engineering. Comentários descritivos são preferíveis a abstrações complexas.

### **Melhoria 1: Comentários Descritivos nas Branches**

```dart
branches: [
  // --- Advogado Associado (índices 0-5) ---
  StatefulShellBranch(routes: [GoRoute(path: '/dashboard', ...)]), // 0: Dashboard
  StatefulShellBranch(routes: [GoRoute(path: '/cases', ...)]),    // 1: Casos
  
  // --- Advogado Contratante (índices 6-12) ---
  StatefulShellBranch(routes: [GoRoute(path: '/home', ...)]),     // 6: Início
  StatefulShellBranch(routes: [GoRoute(path: '/contractor-cases', ...)]), // 7: Meus Casos (NOVA)
  // ...
],
```

### **Melhoria 2: Contexto Inteligente no CasesBloc**

```dart
class FetchCases extends CasesEvent {
  final bool asCreator; // true quando advogado vê "seus casos criados"
  const FetchCases({this.asCreator = false});
}
```

### **Melhoria 3: FAB Condicional**

```dart
floatingActionButton: _shouldShowCreateButton(userRole) 
  ? FloatingActionButton.extended(...)
  : null,

bool _shouldShowCreateButton(String userRole) {
  return ['client', 'lawyer_individual', 'lawyer_office', 'lawyer_platform_associate']
    .contains(userRole);
}
```

### **Melhoria 4: Título Dinâmico**

```dart
appBar: AppBar(
  title: Text(_getScreenTitle(userRole)),
),

String _getScreenTitle(String userRole) {
  if (['lawyer_individual', 'lawyer_office', 'lawyer_platform_associate'].contains(userRole)) {
    return 'Casos Criados'; // Mais específico para advogados
  }
  return 'Meus Casos'; // Para clientes
}
```

---

## 📊 **Plano de Testes**

### **Testes de Integração**
1. **Navegação**: Verificar se nova aba aparece corretamente para perfis corretos
2. **Criação de Casos**: Testar fluxo `/triage` a partir do FAB
3. **Listagem**: Verificar se casos criados aparecem corretamente
4. **Regressão**: Garantir que outras funcionalidades não foram afetadas

### **Testes de Unidade**
1. **CasesBloc**: Verificar comportamento com diferentes contextos
2. **Navegação**: Testar mapeamento de `branchIndex`

---

## 📈 **Métricas de Sucesso**

### **Métricas Quantitativas**
- **Uso da Nova Aba**: % de advogados contratantes que acessam "Meus Casos"
- **Criação de Casos**: Aumento na criação de casos por advogados contratantes
- **Tempo de Navegação**: Redução no tempo para criar novo caso

### **Métricas Qualitativas**
- **Feedback UX**: Avaliação da experiência pelos usuários
- **Suporte**: Redução em tickets relacionados à navegação
- **Adoção**: Aumento no engajamento de advogados contratantes

---

## 🗓️ **Cronograma de Implementação**

### **Semana 1: Desenvolvimento**
- **Dia 1-2**: Fase 1 - Atualização da navegação
- **Dia 3-4**: Fase 2 - Atualização da CasesScreen
- **Dia 5**: Testes e ajustes

### **Semana 2: Validação**
- **Dia 1-2**: Testes de integração
- **Dia 3-4**: Testes com usuários
- **Dia 5**: Correções e deploy

---

## 🔍 **Considerações de Segurança**

### **Autorização**
- Verificar se advogados só veem casos que criaram
- Implementar filtros adequados no backend se necessário

### **Auditoria**
- Logs de criação de casos por advogados contratantes
- Rastreamento de uso da nova funcionalidade

---

## 📚 **Referências Técnicas**

### **Documentos Relacionados**
- `PLANO_CONTEXTO_DUPLO_ADVOGADOS.md` - Versão concisa deste plano (foco na implementação)
- `ANALISE_NAVEGACAO_FLUTTER.md` - Análise da navegação atual
- `FLUTTER_MIGRATION_MASTER_PLAN.md` - Plano mestre de migração
- `ATUALIZAÇÃO_STATUS.md` - Status atual do projeto

### **Código Relacionado**
- `app_router.dart` - Configuração de rotas
- `main_tabs_shell.dart` - Navegação principal
- `cases_screen.dart` - Tela de casos
- `cases_bloc.dart` - Lógica de negócio

---

## ✅ **Checklist de Implementação**

### **Navegação**
- [x] Adicionar rota `/contractor-cases` no `app_router.dart`
- [x] Adicionar item "Meus Casos" no `main_tabs_shell.dart`
- [x] Ajustar todos os `branchIndex` subsequentes
- [x] Verificar mapeamento de índices

### **CasesScreen**
- [x] Importar `go_router`
- [x] Adicionar `FloatingActionButton.extended`
- [x] Remover botão duplicado do `_buildEmptyState`
- [x] Testar navegação para `/triage`

### **Testes**
- [x] Criar testes de integração para nova navegação
- [x] Testar fluxo completo de criação de casos
- [x] Verificar comportamento para diferentes perfis
- [x] Testar regressão

### **Documentação**
- [x] Atualizar `ATUALIZAÇÃO_STATUS.md`
- [ ] Documentar mudanças na navegação
- [ ] Atualizar guias de usuário

---

## 🎯 **Conclusão**

A implementação da funcionalidade de contexto duplo é **estrategicamente necessária** e **tecnicamente sólida**. Ela:

1. **Completa a experiência B2B** da plataforma
2. **Melhora drasticamente a UX** para advogados contratantes
3. **Segue padrões estabelecidos** na arquitetura
4. **Complementa perfeitamente** o sistema de busca avançada

Com implementação cuidadosa dos pontos críticos identificados, esta funcionalidade elevará significativamente a utilidade e adoção da plataforma pelos perfis de advogados contratantes.

**Status**: Pronto para implementação imediata
**Prioridade**: Alta
**Risco**: Baixo (com atenção aos pontos críticos)
**Impacto**: Alto (melhoria significativa na UX) 