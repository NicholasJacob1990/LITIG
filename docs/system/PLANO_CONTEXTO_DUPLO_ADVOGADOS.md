# Plano de Ação: Implementação do Contexto Duplo para Advogados

> **📄 Documento Relacionado**: Este plano complementa o `DUAL_CONTEXT_IMPLEMENTATION_PLAN.md` fornecendo uma abordagem mais concisa e focada na implementação. Para uma visão mais detalhada e estratégica, consulte o documento relacionado.

**Data:** $(date)
**Autor:** Sistema de Desenvolvimento IA
**Status:** Planejado
**Prioridade:** Alta

---

## 1. Objetivo Principal

Implementar a funcionalidade de "contexto duplo" para os perfis de **Advogado Contratante** (autônomo, escritório, super associado), permitindo que eles criem e visualizem seus próprios casos (atuando como clientes) através de uma nova aba "Meus Casos" na barra de navegação principal.

## 2. Contexto e Justificativa

### Problema Identificado
A arquitetura atual do sistema permite que advogados contratantes iniciem o fluxo de criação de casos através da aba "Início" (que leva à `HomeScreen`), mas não fornece uma forma clara de visualizar e gerenciar os casos que eles próprios criaram como clientes.

### Solução Proposta
Adicionar uma nova aba "Meus Casos" à barra de navegação dos perfis de Advogado Contratante, reutilizando a `CasesScreen` existente e adicionando um `FloatingActionButton` para criação de novos casos.

## 3. Princípios Técnicos

- **Simplicidade e Clareza:** A implementação será direta, modificando os índices da `StatefulShellRoute` manualmente, sem adicionar camadas de abstração desnecessárias (evitar over-engineering).
- **Fonte Única da Verdade:** A ordem das rotas na lista de `branches` do arquivo `app_router.dart` será a única fonte de verdade para os índices.
- **Código Auto-Documentado:** Serão adicionados comentários descritivos inline no código para garantir que a lógica de indexação seja óbvia e a manutenção futura seja segura.
- **Reutilização de Componentes:** A `CasesScreen` existente será reutilizada, mantendo a consistência da interface.
- **Melhores Práticas Flutter:** Seguir as práticas recomendadas pela comunidade Flutter para `StatefulShellRoute`, priorizando comentários claros sobre abstrações complexas.

## 4. Plano de Implementação Passo a Passo

### Passo 1: Adicionar a Rota de "Casos do Contratante" no Roteador

**Objetivo:** Registrar a nova rota na estrutura principal de navegação.

**Arquivo:** `apps/app_flutter/lib/src/router/app_router.dart`

**Ação:** Inserir uma nova `StatefulShellBranch` para a tela de casos no grupo de rotas do Advogado Contratante.

```dart
        branches: [
          // --- Advogado Associado (índices 0-5) ---
          StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen())]), // 0: Dashboard
          StatefulShellBranch(routes: [GoRoute(path: '/cases', builder: (context, state) => const CasesScreen())]),       // 1: Casos
          StatefulShellBranch(routes: [GoRoute(path: '/agenda', builder: (context, state) => const AgendaScreen())]),      // 2: Agenda
          StatefulShellBranch(routes: [GoRoute(path: '/offers', builder: (context, state) => const OffersScreen())]),      // 3: Ofertas
          StatefulShellBranch(routes: [GoRoute(path: '/messages', builder: (context, state) => const MessagesScreen())]),  // 4: Mensagens
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())]),    // 5: Perfil
          
          // --- Advogado Contratante (índices 6-12 APÓS ALTERAÇÃO) ---
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())]),                    // 6: Início
          // ⬇️ NOVA ROTA ADICIONADA ⬇️
          StatefulShellBranch(routes: [GoRoute(path: '/contractor-cases', builder: (context, state) => const CasesScreen())]),      // 7: Meus Casos (Contratante)
          StatefulShellBranch(routes: [GoRoute(path: '/contractor-offers', builder: (context, state) => const CaseOffersScreen())]), // 8: Ofertas (antes era 7)
          StatefulShellBranch(routes: [GoRoute(path: '/partners', builder: (context, state) => const LawyerSearchScreen())]),       // 9: Parceiros (antes era 8)
          StatefulShellBranch(routes: [GoRoute(path: '/partnerships', builder: (context, state) => const PartnershipsScreen())]),   // 10: Parcerias (antes era 9)
          StatefulShellBranch(routes: [GoRoute(path: '/contractor-messages', builder: (context, state) => const MessagesScreen())]), // 11: Mensagens (antes era 10)
          StatefulShellBranch(routes: [GoRoute(path: '/contractor-profile', builder: (context, state) => const ProfileScreen())]),  // 12: Perfil (antes era 11)

          // --- Cliente (índices 13-18 APÓS ALTERAÇÃO - antes eram 12-17) ---
          StatefulShellBranch(routes: [GoRoute(path: '/client-home', builder: (context, state) => const HomeScreen())]),       // 13: Início (antes era 12)
          StatefulShellBranch(routes: [GoRoute(path: '/client-cases', builder: (context, state) => const CasesScreen())]),     // 14: Meus Casos (antes era 13)
          StatefulShellBranch(routes: [GoRoute(path: '/find-lawyers', builder: (context, state) => const LawyersScreen())]),  // 15: Advogados (antes era 14)
          StatefulShellBranch(routes: [GoRoute(path: '/client-messages', builder: (context, state) => const MessagesScreen())]), // 16: Mensagens (antes era 15)
          StatefulShellBranch(routes: [GoRoute(path: '/services', builder: (context, state) => const ServicesScreen())]),     // 17: Serviços (antes era 16)
          StatefulShellBranch(routes: [GoRoute(path: '/client-profile', builder: (context, state) => const ProfileScreen())]), // 18: Perfil (antes era 17)
        ],
```

### Passo 2: Adicionar o Item na Barra de Navegação

**Objetivo:** Exibir a nova aba na interface do usuário e reajustar os índices das abas seguintes.

**Arquivo:** `apps/app_flutter/lib/src/shared/widgets/organisms/main_tabs_shell.dart`

**Ação:** Adicionar um novo `NavItem` na lista de itens do perfil de Advogado Contratante e atualizar os `branchIndex` subsequentes.

```dart
  List<NavItem> _getNavItemsForRole(String userRole) {
    switch (userRole) {
      case 'lawyer_associated':
        return [
          NavItem(label: 'Painel', icon: LucideIcons.layoutDashboard, branchIndex: 0),
          NavItem(label: 'Casos', icon: LucideIcons.folder, branchIndex: 1),
          NavItem(label: 'Agenda', icon: LucideIcons.calendar, branchIndex: 2),
          NavItem(label: 'Ofertas', icon: LucideIcons.inbox, branchIndex: 3),
          NavItem(label: 'Mensagens', icon: LucideIcons.messageSquare, branchIndex: 4),
          NavItem(label: 'Perfil', icon: LucideIcons.user, branchIndex: 5),
        ];
      case 'lawyer_individual':
      case 'lawyer_office':
      case 'lawyer_platform_associate':
        return [
          NavItem(label: 'Início', icon: LucideIcons.home, branchIndex: 6),
          // ⬇️ NOVA ABA ADICIONADA ⬇️
          NavItem(label: 'Meus Casos', icon: LucideIcons.clipboardList, branchIndex: 7),
          // ⬇️ ÍNDICES DAS ABAS SEGUINTES ATUALIZADOS ⬇️
          NavItem(label: 'Ofertas', icon: LucideIcons.inbox, branchIndex: 8),        // antes era 7
          NavItem(label: 'Parceiros', icon: LucideIcons.search, branchIndex: 9),     // antes era 8
          NavItem(label: 'Parcerias', icon: LucideIcons.users, branchIndex: 10),     // antes era 9
          NavItem(label: 'Mensagens', icon: LucideIcons.messageSquare, branchIndex: 11), // antes era 10
          NavItem(label: 'Perfil', icon: LucideIcons.user, branchIndex: 12),         // antes era 11
        ];
      default: // client
        return [
          NavItem(label: 'Início', icon: LucideIcons.home, branchIndex: 13),         // antes era 12
          NavItem(label: 'Meus Casos', icon: LucideIcons.clipboardList, branchIndex: 14), // antes era 13
          NavItem(label: 'Advogados', icon: LucideIcons.search, branchIndex: 15),    // antes era 14
          NavItem(label: 'Mensagens', icon: LucideIcons.messageCircle, branchIndex: 16), // antes era 15
          NavItem(label: 'Serviços', icon: LucideIcons.layoutGrid, branchIndex: 17), // antes era 16
          NavItem(label: 'Perfil', icon: LucideIcons.user, branchIndex: 18),         // antes era 17
        ];
    }
  }
```

### Passo 3: Habilitar a Criação de Casos na `CasesScreen`

**Objetivo:** Adicionar o botão que permite a criação de um novo caso.

**Arquivo:** `apps/app_flutter/lib/src/features/cases/presentation/screens/cases_screen.dart`

**Ação:** Adicionar um `FloatingActionButton` à tela `CasesScreen` para iniciar o fluxo de triagem e remover o botão antigo que só aparecia no estado vazio.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // 👈 ADICIONAR IMPORT
import 'package:meu_app/src/features/cases/presentation/bloc/cases_bloc.dart';
import 'package:meu_app/src/features/cases/presentation/widgets/case_card.dart';
import 'package:meu_app/injection_container.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
        // ⬇️ ADICIONAR FLOATING ACTION BUTTON ⬇️
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/triage'), // Inicia o fluxo de triagem
          label: const Text('Criar Novo Caso'),
          icon: const Icon(LucideIcons.plus),
        ),
        body: Column(
          children: [
            _buildFilterSection(),
            Expanded(
              child: BlocBuilder<CasesBloc, CasesState>(
                builder: (context, state) {
                  // ... existing code ...
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... existing code ...

  Widget _buildEmptyState(String activeFilter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.folderX, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Não há casos com status "$activeFilter"',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          // ⬇️ BOTÃO ANTIGO REMOVIDO ⬇️
          // const SizedBox(height: 16),
          // ElevatedButton.icon(
          //   onPressed: () {
          //     // TODO: Navegar para tela de nova triagem
          //   },
          //   icon: const Icon(LucideIcons.plus),
          //   label: const Text('Iniciar Nova Consulta'),
          // ),
        ],
      ),
    );
  }
}
```

## 5. Impacto e Considerações

### Perfis Afetados
- **✅ Advogado Contratante:** Ganha acesso à nova funcionalidade
- **🔄 Cliente:** Índices das abas atualizados (sem impacto visual)
- **➖ Advogado Associado:** Sem alterações

### Reutilização de Componentes
- **`CasesScreen`:** Reutilizada sem modificações na lógica de negócio
- **`CasesBloc`:** Funciona normalmente, filtrando casos por usuário autenticado
- **Navegação:** Aproveita a estrutura existente do `StatefulShellRoute`

### Benefícios
1. **Contexto Duplo Completo:** Advogados contratantes podem criar e gerenciar casos como clientes
2. **UX Consistente:** Interface familiar para todos os tipos de usuário
3. **Manutenibilidade:** Reutilização de código existente
4. **Escalabilidade:** Estrutura preparada para futuras expansões

## 6. Verificação e Testes

### Critérios de Sucesso
1. **Login como Advogado Contratante:**
   - Fazer login como usuário do tipo `lawyer_office` ou `lawyer_individual`
   - Confirmar que a nova aba "Meus Casos" aparece entre "Início" e "Ofertas"

2. **Funcionalidade da Nova Aba:**
   - Acessar a tela "Meus Casos"
   - Verificar que o `FloatingActionButton` "Criar Novo Caso" está visível
   - Confirmar que a lista de casos (se houver) é exibida corretamente

3. **Criação de Casos:**
   - Clicar no botão "Criar Novo Caso"
   - Confirmar que a navegação para o fluxo de triagem (`/triage`) ocorre corretamente
   - Completar um caso e verificar que ele aparece na lista

4. **Regressão:**
   - Fazer login como Cliente e verificar que a interface não foi alterada
   - Fazer login como Advogado Associado e verificar que a interface não foi alterada
   - Testar a navegação entre todas as abas de todos os perfis

### Checklist de Implementação
- [ ] Passo 1: Rota adicionada no `app_router.dart`
- [ ] Passo 2: Aba adicionada no `main_tabs_shell.dart`
- [ ] Passo 3: FloatingActionButton adicionado na `CasesScreen`
- [ ] Teste: Login como Advogado Contratante
- [ ] Teste: Navegação para nova aba funciona
- [ ] Teste: FloatingActionButton visível e funcional
- [ ] Teste: Criação de caso funciona
- [ ] Teste: Regressão nos outros perfis
- [ ] Documentação: Atualizar documentação de navegação

## 7. Considerações Futuras

### Melhorias Possíveis
1. **Comentários Descritivos:** Manter comentários inline claros nas branches (melhor prática vs. enums)
2. **Diferenciação Visual:** Adicionar indicadores visuais para distinguir casos criados como cliente vs. casos recebidos como advogado
3. **Filtros Avançados:** Implementar filtros específicos para casos próprios vs. casos de terceiros
4. **Notificações:** Sistema de notificações para casos criados pelo próprio usuário

### Manutenção
- **Documentação:** Manter a documentação de navegação atualizada
- **Testes:** Incluir testes automatizados para a nova funcionalidade
- **Monitoramento:** Acompanhar o uso da nova funcionalidade através de métricas

---

**Próximos Passos:** Implementar o plano seguindo a ordem dos passos descritos e executar os testes de verificação.

**Responsável pela Implementação:** [A definir]
**Prazo Estimado:** [A definir]
**Status:** Aguardando aprovação para implementação 