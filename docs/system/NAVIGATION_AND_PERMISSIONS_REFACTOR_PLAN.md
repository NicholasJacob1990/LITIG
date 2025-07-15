# 🎯 Plano de Refatoração: Fábrica de Navegação e Sistema de Permissões

**Versão:** 1.0  
**Status:** Planejado

## 1. 🚀 Objetivo

Este documento detalha o plano técnico para refatorar duas partes críticas do sistema:
1.  **Sistema de Autorização**: Migrar de uma verificação baseada em `Roles` (Perfis) para um sistema granular baseado em `Permissions` (Capacidades).
2.  **Construção da UI de Navegação**: Substituir a lógica de `switch/case` por uma "Fábrica de Navegação" (Navigation Factory) dinâmica e sem repetição de código.

**Benefícios Esperados:**
-   **Flexibilidade:** Adicionar ou modificar perfis de usuário sem alterar o código do frontend.
-   **Manutenibilidade:** Reduzir drasticamente a repetição de código e a complexidade da lógica de UI.
-   **Clareza:** Tornar a lógica de acesso e de construção de UI mais semântica e legível.

---

## 2. 🪜 Plano de Implementação Faseado

A implementação será dividida em duas fases principais, com uma feature flag para garantir um rollout seguro.

**Feature Flag:** `USE_NEW_NAVIGATION_SYSTEM` (a ser criada no sistema de configuração, ex: Firebase Remote Config ou tabela no Supabase).

### ✅ Fase 1: Implementação do Sistema de Permissões (Backend)

O objetivo desta fase é enriquecer o objeto do usuário com uma lista de permissões.

#### Tarefa 1.1: Criar Schema do Banco de Dados

Criar as tabelas `permissions` e `profile_permissions` para gerenciar as capacidades de cada perfil.

```sql
-- Tabela para armazenar todas as permissões possíveis no sistema
CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT NOT NULL UNIQUE, -- Ex: 'nav.view.offers', 'cases.can.create'
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Tabela de junção para associar permissões a perfis de usuário
-- (considerando que os perfis já existem em uma tabela 'profiles' ou similar)
CREATE TABLE profile_permissions (
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (profile_id, permission_id)
);
```

#### Tarefa 1.2: Popular as Permissões Iniciais

Criar um script de seed para popular a tabela `permissions` com todas as chaves de navegação e ações necessárias.

**Exemplo de Permissões de Navegação:**
- `nav.view.dashboard`
- `nav.view.cases`
- `nav.view.agenda`
- `nav.view.offers`
- `nav.view.partners`
- `nav.view.partnerships`

#### Tarefa 1.3: Atualizar a API de Autenticação/Usuário

Modificar o endpoint que retorna os dados do usuário logado (ex: `/api/me`) para incluir a lista de `permissions` do seu perfil.

**Exemplo de Payload de Resposta do Usuário:**
```json
{
  "id": "user-uuid",
  "full_name": "Nicholas Jacob",
  "email": "nicholas@example.com",
  "role": "lawyer_office", // O role ainda pode ser útil para lógicas legadas ou display
  "permissions": [ // NOVA PROPRIEDADE
    "nav.view.home",
    "nav.view.offers",
    "nav.view.partners",
    "nav.view.partnerships",
    "nav.view.messages",
    "nav.view.profile"
  ]
}
```

---

### ✅ Fase 2: Implementação da Fábrica de Navegação (Frontend Flutter)

O objetivo é refatorar `main_tabs_shell.dart` para usar a nova lógica.

#### Tarefa 2.1: Criar o Mapa de Abas (Tabs Map)

Definir um mapa central com **todas as abas possíveis** no sistema, cada uma com sua `requiredPermission`.

**Arquivo:** `lib/src/shared/config/navigation_config.dart`
```dart
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/shared/widgets/atoms/nav_item.dart';

class NavigationTab {
  final NavItem navItem;
  final String requiredPermission;

  const NavigationTab({required this.navItem, required this.requiredPermission});
}

final Map<String, NavigationTab> allPossibleTabs = {
  // Abas do Associado
  'dashboard': NavigationTab(navItem: NavItem(label: 'Painel', icon: LucideIcons.layoutDashboard, branchIndex: 0), requiredPermission: 'nav.view.dashboard'),
  'cases': NavigationTab(navItem: NavItem(label: 'Casos', icon: LucideIcons.folder, branchIndex: 1), requiredPermission: 'nav.view.cases'),
  'agenda': NavigationTab(navItem: NavItem(label: 'Agenda', icon: LucideIcons.calendar, branchIndex: 2), requiredPermission: 'nav.view.agenda'),
  
  // Abas de Captação
  'home': NavigationTab(navItem: NavItem(label: 'Início', icon: LucideIcons.home, branchIndex: 6), requiredPermission: 'nav.view.home'),
  'offers': NavigationTab(navItem: NavItem(label: 'Ofertas', icon: LucideIcons.inbox, branchIndex: 7), requiredPermission: 'nav.view.offers'),
  'partners': NavigationTab(navItem: NavItem(label: 'Parceiros', icon: LucideIcons.search, branchIndex: 8), requiredPermission: 'nav.view.partners'),
  'partnerships': NavigationTab(navItem: NavItem(label: 'Parcerias', icon: LucideIcons.users, branchIndex: 9), requiredPermission: 'nav.view.partnerships'),

  // Abas Comuns
  'messages': NavigationTab(navItem: NavItem(label: 'Mensagens', icon: LucideIcons.messageSquare, branchIndex: 4), requiredPermission: 'nav.view.messages'),
  'profile': NavigationTab(navItem: NavItem(label: 'Perfil', icon: LucideIcons.user, branchIndex: 5), requiredPermission: 'nav.view.profile'),
};

```

#### Tarefa 2.2: Refatorar `main_tabs_shell.dart`

Substituir o `switch (userRole)` pela nova lógica baseada em permissões.

**ANTES:**
```dart
// ... em main_tabs_shell.dart
List<NavItem> _getNavItemsForRole(String userRole) {
  switch (userRole) {
    case 'lawyer_associated':
      return [
        NavItem(label: 'Painel', icon: LucideIcons.layoutDashboard, branchIndex: 0),
        // ... mais itens repetidos
      ];
    case 'lawyer_individual':
    case 'lawyer_office':
      return [
        NavItem(label: 'Início', icon: LucideIcons.home, branchIndex: 6),
        // ... mais itens repetidos
      ];
    // ...
  }
}
```

**DEPOIS (Implementação Final):**
```dart
// ... em main_tabs_shell.dart
import 'package:meu_app/src/shared/config/navigation_config.dart';

// ...
List<NavItem> _getNavItemsForUser(Authenticated state) {
  // Supondo que `state.user.permissions` é um `List<String>`
  final userPermissions = state.user.permissions;

  // Lista ordenada de chaves para manter a ordem do menu
  const orderedTabs = ['dashboard', 'home', 'cases', 'agenda', 'offers', 'partners', 'partnerships', 'messages', 'profile'];

  final List<NavItem> visibleItems = [];
  for (final tabKey in orderedTabs) {
    final tabConfig = allPossibleTabs[tabKey];
    if (tabConfig != null && userPermissions.contains(tabConfig.requiredPermission)) {
      visibleItems.add(tabConfig.navItem);
    }
  }
  return visibleItems;
}
```

---

---

## 3. 📊 Matriz de Permissões por Perfil

Esta tabela define quais permissões cada perfil de usuário deve ter, baseada na matriz de navegação do documento de arquitetura.

| Permissão | 👤 Cliente | ⚖️ Adv. Associado | 🤝 Adv. Contratante | 🌟 Super Associado |
|-----------|:----------:|:------------------:|:-------------------:|:------------------:|
| `nav.view.client_home` | ✅ | | | |
| `nav.view.client_cases` | ✅ | | | |
| `nav.view.find_lawyers` | ✅ | | | |
| `nav.view.client_messages` | ✅ | | | |
| `nav.view.client_services` | ✅ | | | |
| `nav.view.client_profile` | ✅ | | | |
| `nav.view.dashboard` | | ✅ | | |
| `nav.view.cases` | | ✅ | ✅ | ✅ |
| `nav.view.agenda` | | ✅ | | |
| `nav.view.offers` | | ✅ | | ✅ |
| `nav.view.messages` | | ✅ | | ✅ |
| `nav.view.profile` | | ✅ | | ✅ |
| `nav.view.home` | | | ✅ | ✅ |
| `nav.view.contractor_offers` | | | ✅ | |
| `nav.view.partners` | | | ✅ | |
| `nav.view.partnerships` | | | ✅ | |
| `nav.view.contractor_messages` | | | ✅ | |
| `nav.view.contractor_profile` | | | ✅ | |

---

## 4. 🔧 Implementação Detalhada

### 4.1. Script de Seed das Permissões

**Arquivo:** `packages/backend/scripts/seed_permissions.py`

```python
import asyncio
from supabase import create_client, Client

PERMISSIONS_SEED = [
    # Cliente
    {"key": "nav.view.client_home", "description": "Visualizar página inicial do cliente"},
    {"key": "nav.view.client_cases", "description": "Visualizar casos do cliente"},
    {"key": "nav.view.find_lawyers", "description": "Buscar advogados/escritórios"},
    {"key": "nav.view.client_messages", "description": "Mensagens do cliente"},
    {"key": "nav.view.client_services", "description": "Serviços disponíveis"},
    {"key": "nav.view.client_profile", "description": "Perfil do cliente"},
    
    # Advogado Associado
    {"key": "nav.view.dashboard", "description": "Painel de performance"},
    {"key": "nav.view.cases", "description": "Visualizar casos (advogado)"},
    {"key": "nav.view.agenda", "description": "Agenda e prazos"},
    {"key": "nav.view.offers", "description": "Ofertas recebidas"},
    {"key": "nav.view.messages", "description": "Mensagens (advogado)"},
    {"key": "nav.view.profile", "description": "Perfil (advogado)"},
    
    # Advogado Contratante
    {"key": "nav.view.home", "description": "Início do contratante"},
    {"key": "nav.view.contractor_offers", "description": "Ofertas em casos"},
    {"key": "nav.view.partners", "description": "Buscar parceiros"},
    {"key": "nav.view.partnerships", "description": "Parcerias"},
    {"key": "nav.view.contractor_messages", "description": "Mensagens de parceria"},
    {"key": "nav.view.contractor_profile", "description": "Perfil do contratante"},
]

PROFILE_PERMISSIONS = {
    "client": [
        "nav.view.client_home", "nav.view.client_cases", "nav.view.find_lawyers", 
        "nav.view.client_messages", "nav.view.client_services", "nav.view.client_profile"
    ],
    "lawyer_associated": [
        "nav.view.dashboard", "nav.view.cases", "nav.view.agenda", 
        "nav.view.offers", "nav.view.messages", "nav.view.profile"
    ],
    "lawyer_individual": [
        "nav.view.home", "nav.view.cases", "nav.view.contractor_offers", "nav.view.partners", 
        "nav.view.partnerships", "nav.view.contractor_messages", "nav.view.contractor_profile"
    ],
    "lawyer_office": [
        "nav.view.home", "nav.view.cases", "nav.view.contractor_offers", "nav.view.partners", 
        "nav.view.partnerships", "nav.view.contractor_messages", "nav.view.contractor_profile"
    ],
    "lawyer_platform_associate": [
        "nav.view.home", "nav.view.cases", "nav.view.offers", 
        "nav.view.messages", "nav.view.profile"
    ]
}

async def seed_permissions():
    # Implementar lógica de seed
    pass

if __name__ == "__main__":
    asyncio.run(seed_permissions())
```

### 4.2. Atualização do Modelo de Usuário (Flutter)

**Arquivo:** `lib/src/features/auth/domain/entities/user.dart`

```dart
class User {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final List<String> permissions; // NOVA PROPRIEDADE
  
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.permissions, // OBRIGATÓRIO
  });
  
  // Método de conveniência para verificar permissões
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
}
```

### 4.3. Mapa de Navegação Completo

**Arquivo:** `lib/src/shared/config/navigation_config.dart`

```dart
final Map<String, NavigationTab> allPossibleTabs = {
  // Cliente
  'client_home': NavigationTab(
    navItem: NavItem(label: 'Início', icon: LucideIcons.home, branchIndex: 12),
    requiredPermission: 'nav.view.client_home'
  ),
  'client_cases': NavigationTab(
    navItem: NavItem(label: 'Meus Casos', icon: LucideIcons.clipboardList, branchIndex: 13),
    requiredPermission: 'nav.view.client_cases'
  ),
  'find_lawyers': NavigationTab(
    navItem: NavItem(label: 'Advogados', icon: LucideIcons.search, branchIndex: 14),
    requiredPermission: 'nav.view.find_lawyers'
  ),
  'client_messages': NavigationTab(
    navItem: NavItem(label: 'Mensagens', icon: LucideIcons.messageCircle, branchIndex: 15),
    requiredPermission: 'nav.view.client_messages'
  ),
  'client_services': NavigationTab(
    navItem: NavItem(label: 'Serviços', icon: LucideIcons.layoutGrid, branchIndex: 16),
    requiredPermission: 'nav.view.client_services'
  ),
  'client_profile': NavigationTab(
    navItem: NavItem(label: 'Perfil', icon: LucideIcons.user, branchIndex: 17),
    requiredPermission: 'nav.view.client_profile'
  ),
  
  // Advogado Associado
  'dashboard': NavigationTab(
    navItem: NavItem(label: 'Painel', icon: LucideIcons.layoutDashboard, branchIndex: 0),
    requiredPermission: 'nav.view.dashboard'
  ),
  'cases': NavigationTab(
    navItem: NavItem(label: 'Casos', icon: LucideIcons.folder, branchIndex: 1),
    requiredPermission: 'nav.view.cases'
  ),
  'agenda': NavigationTab(
    navItem: NavItem(label: 'Agenda', icon: LucideIcons.calendar, branchIndex: 2),
    requiredPermission: 'nav.view.agenda'
  ),
  'offers': NavigationTab(
    navItem: NavItem(label: 'Ofertas', icon: LucideIcons.inbox, branchIndex: 3),
    requiredPermission: 'nav.view.offers'
  ),
  'messages': NavigationTab(
    navItem: NavItem(label: 'Mensagens', icon: LucideIcons.messageSquare, branchIndex: 4),
    requiredPermission: 'nav.view.messages'
  ),
  'profile': NavigationTab(
    navItem: NavItem(label: 'Perfil', icon: LucideIcons.user, branchIndex: 5),
    requiredPermission: 'nav.view.profile'
  ),
  
  // Advogado Contratante
  'home': NavigationTab(
    navItem: NavItem(label: 'Início', icon: LucideIcons.home, branchIndex: 6),
    requiredPermission: 'nav.view.home'
  ),
  'contractor_offers': NavigationTab(
    navItem: NavItem(label: 'Ofertas', icon: LucideIcons.inbox, branchIndex: 7),
    requiredPermission: 'nav.view.contractor_offers'
  ),
  'partners': NavigationTab(
    navItem: NavItem(label: 'Parceiros', icon: LucideIcons.search, branchIndex: 8),
    requiredPermission: 'nav.view.partners'
  ),
  'partnerships': NavigationTab(
    navItem: NavItem(label: 'Parcerias', icon: LucideIcons.users, branchIndex: 9),
    requiredPermission: 'nav.view.partnerships'
  ),
  'contractor_messages': NavigationTab(
    navItem: NavItem(label: 'Mensagens', icon: LucideIcons.messageSquare, branchIndex: 10),
    requiredPermission: 'nav.view.contractor_messages'
  ),
  'contractor_profile': NavigationTab(
    navItem: NavItem(label: 'Perfil', icon: LucideIcons.user, branchIndex: 11),
    requiredPermission: 'nav.view.contractor_profile'
  ),
};
```

---

## 5. 🧪 Estratégia de Testes

### 5.1. Testes Unitários

**Arquivo:** `test/shared/config/navigation_config_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/src/shared/config/navigation_config.dart';

void main() {
  group('NavigationConfig Tests', () {
    test('should return correct tabs for lawyer_associated permissions', () {
      final permissions = ['nav.view.dashboard', 'nav.view.cases', 'nav.view.agenda'];
      final tabs = getVisibleTabsForPermissions(permissions);
      
      expect(tabs.length, 3);
      expect(tabs[0].label, 'Painel');
      expect(tabs[1].label, 'Casos');
      expect(tabs[2].label, 'Agenda');
    });
    
    test('should handle empty permissions gracefully', () {
      final tabs = getVisibleTabsForPermissions([]);
      expect(tabs.isEmpty, true);
    });
  });
}
```

### 5.2. Testes de Integração

**Arquivo:** `integration_test/navigation_permissions_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meu_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Navigation Permissions Integration Tests', () {
    testWidgets('client should see only client navigation tabs', (tester) async {
      // Mock user with client permissions
      // Test navigation visibility
    });
    
    testWidgets('lawyer_associated should see lawyer navigation tabs', (tester) async {
      // Mock user with lawyer permissions
      // Test navigation visibility
    });
  });
}
```

---

## 6. 📋 Rollout e Implementação

### 6.1. Cronograma de Implementação

| Fase | Duração | Tarefas | Responsável |
|------|---------|---------|-------------|
| **Fase 1** | 1 semana | Schema DB + Seed + API | Backend Dev |
| **Fase 2** | 1 semana | Navigation Config + Refactor | Frontend Dev |
| **Fase 3** | 3 dias | Testes + Feature Flag | QA + DevOps |
| **Fase 4** | 1 semana | Rollout + Monitoramento | Toda equipe |

### 6.2. Critérios de Aceitação

- [ ] Todas as permissões estão corretamente associadas aos perfis
- [ ] A navegação funciona identicamente ao sistema atual
- [ ] Não há regressões de performance
- [ ] Testes unitários e de integração passam
- [ ] Feature flag permite rollback instantâneo

### 6.3. Plano de Rollback

Em caso de problemas críticos:
1. Desativar feature flag `USE_NEW_NAVIGATION_SYSTEM`
2. Sistema volta automaticamente para lógica de `switch/case`
3. Investigar e corrigir problemas
4. Reativar feature flag após correções

---

## 7. 🔮 Benefícios Futuros

### 7.1. Facilidade de Manutenção
- Adicionar nova aba: apenas inserir no banco de dados
- Novo perfil: apenas configurar permissões
- Alterar navegação: sem mudanças no código

### 7.2. Escalabilidade
- Permissões granulares para funcionalidades específicas
- Sistema de roles hierárquicos
- Permissões temporárias ou condicionais

### 7.3. Auditoria e Compliance
- Log de todas as verificações de permissão
- Histórico de mudanças de acesso
- Relatórios de usage por funcionalidade 