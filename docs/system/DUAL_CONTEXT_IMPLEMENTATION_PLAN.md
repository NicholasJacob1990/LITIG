# Plano de Implementação: Funcionalidade de Contexto Duplo

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
- ✅ Consistência nos `branchIndex`
- ✅ Reutilização de `CasesScreen` (DRY principle)
- ✅ Integração com `go_router` estabelecida

---

## 📝 **Plano de Implementação Detalhado**

### **Fase 1: Atualização da Navegação**

#### **1.1. Modificar Rotas no `app_router.dart`**

**Arquivo**: `apps/app_flutter/lib/src/router/app_router.dart`

**Alteração**: Inserir nova rota `/contractor-cases` no grupo de abas do "Advogado Contratante"

```dart
// Advogado Contratante (índices 6-12 AGORA)
StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())]),
// ⬇️ ADICIONAR NOVA ROTA AQUI ⬇️
StatefulShellBranch(routes: [GoRoute(path: '/contractor-cases', builder: (context, state) => const CasesScreen())]),
StatefulShellBranch(routes: [GoRoute(path: '/contractor-offers', builder: (context, state) => const CaseOffersScreen())]),
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
- **Mitigação**: Verificação tripla do mapeamento de índices

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

### **Melhoria 1: Contexto Inteligente no CasesBloc**

```dart
class FetchCases extends CasesEvent {
  final bool asCreator; // true quando advogado vê "seus casos criados"
  const FetchCases({this.asCreator = false});
}
```

### **Melhoria 2: FAB Condicional**

```dart
floatingActionButton: _shouldShowCreateButton(userRole) 
  ? FloatingActionButton.extended(...)
  : null,

bool _shouldShowCreateButton(String userRole) {
  return ['client', 'lawyer_individual', 'lawyer_office', 'lawyer_platform_associate']
    .contains(userRole);
}
```

### **Melhoria 3: Título Dinâmico**

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

## ✅ **Relatório de Implementação (15/07/2025)**

### **Status: CONCLUÍDO**

A funcionalidade de Contexto Duplo foi implementada e validada com sucesso, seguindo e adaptando o plano original.

### **Resumo das Ações Executadas:**

1.  **Análise e Verificação:**
    *   Confirmou-se que a `CasesScreen` já possuía o `FloatingActionButton` para criar novos casos.
    *   Identificou-se que a navegação para esta tela estava ausente para os perfis de advogado.

2.  **Implementação da Navegação (Frontend):**
    *   A rota `/contractor-cases` foi adicionada ao `app_router.dart`, conectando a `CasesScreen` ao fluxo do advogado.
    *   A navegação foi atualizada no `navigation_config.dart`, que substituiu a lógica legada do `main_tabs_shell.dart`.
    *   A aba "Meus Casos" foi habilitada para os perfis `lawyer_individual`, `lawyer_office` e `lawyer_platform_associate`.
    *   Os `branchIndex` de todo o sistema foram corrigidos para garantir consistência.

3.  **Validação do Fluxo de Triagem:**
    *   A análise do `ChatTriageBloc` confirmou que o fluxo é agnóstico ao perfil do usuário, utilizando o token de autenticação para identificar o criador do caso. Nenhuma alteração foi necessária.

4.  **Implementação da Lógica de Exclusão (Backend):**
    *   Foi verificado que o endpoint principal de match (`/api/match`) não excluía o usuário criador dos resultados.
    *   O arquivo `packages/backend/api/main.py` foi modificado para filtrar a lista de advogados **antes** de passá-la ao algoritmo de ranking, garantindo que o advogado que cria o caso nunca apareça como uma sugestão para si mesmo.
    *   A análise posterior do `algoritmo_match.py` confirmou que ele possui um parâmetro `exclude_ids`, validando a robustez da solução implementada.

### **Resultado Final:**

A plataforma agora permite que advogados e escritórios criem casos como se fossem clientes, utilizando o mesmo funil de triagem por IA, e recebam uma lista de parceiros e especialistas recomendados, fortalecendo o ecossistema B2B da LITGO. O plano foi executado com sucesso e a funcionalidade está totalmente operacional.

---

## 📚 **Referências Técnicas**

### **Documentos Relacionados**
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
- [ ] Adicionar rota `/contractor-cases` no `app_router.dart`
- [ ] Adicionar item "Meus Casos" no `main_tabs_shell.dart`
- [ ] Ajustar todos os `branchIndex` subsequentes
- [ ] Verificar mapeamento de índices

### **CasesScreen**
- [ ] Importar `go_router`
- [ ] Adicionar `FloatingActionButton.extended`
- [ ] Remover botão duplicado do `_buildEmptyState`
- [ ] Testar navegação para `/triage`

### **Testes**
- [ ] Criar testes de integração para nova navegação
- [ ] Testar fluxo completo de criação de casos
- [ ] Verificar comportamento para diferentes perfis
- [ ] Testes de regressão

### **Documentação**
- [ ] Atualizar `ATUALIZAÇÃO_STATUS.md`
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