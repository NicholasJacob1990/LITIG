import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/shared/services/remote_config_service.dart';

/// Configuração de navegação baseada em permissões
/// Substitui o sistema de switch/case por uma abordagem dinâmica
class NavigationTab {
  final String label;
  final IconData icon;
  final int branchIndex;
  final String requiredPermission;
  final String route;

  const NavigationTab({
    required this.label,
    required this.icon,
    required this.branchIndex,
    required this.requiredPermission,
    required this.route,
  });
}

/// Mapa centralizado de todas as abas possíveis no sistema
/// Cada aba é associada a uma permissão específica
/// CORRIGIDO: Índices sequenciais e labels conforme documentação
final Map<String, NavigationTab> allPossibleTabs = {
  // === CLIENTE (CORRETO conforme documentação) ===
  'client_home': const NavigationTab(
    label: 'Início',
    icon: LucideIcons.home,
    branchIndex: 0,
    requiredPermission: 'nav.view.client_home',
    route: '/client-home',
  ),
  'client_cases': const NavigationTab(
    label: 'Meus Casos',
    icon: LucideIcons.clipboardList,
    branchIndex: 1,
    requiredPermission: 'nav.view.client_cases',
    route: '/client-cases',
  ),
  'find_lawyers': const NavigationTab(
    label: 'Advogados',
    icon: LucideIcons.search,
    branchIndex: 2,
    requiredPermission: 'nav.view.find_lawyers',
    route: '/find-lawyers',
  ),
  'client_messages': const NavigationTab(
    label: 'Mensagens',
    icon: LucideIcons.messageCircle,
    branchIndex: 3,
    requiredPermission: 'nav.view.client_messages',
    route: '/client-messages',
  ),
  'services': const NavigationTab(
    label: 'Serviços',
    icon: LucideIcons.briefcase,
    branchIndex: 4,
    requiredPermission: 'nav.view.services',
    route: '/services',
  ),
  'client_profile': const NavigationTab(
    label: 'Perfil',
    icon: LucideIcons.user,
    branchIndex: 5,
    requiredPermission: 'nav.view.client_profile',
    route: '/client-profile',
  ),

  // === ADVOGADO ASSOCIADO ===
  'dashboard': const NavigationTab(
    label: 'Painel',
    icon: LucideIcons.layoutDashboard,
    branchIndex: 0,
    requiredPermission: 'nav.view.dashboard',
    route: '/dashboard',
  ),
  'cases': const NavigationTab(
    label: 'Casos',
    icon: LucideIcons.folder,
    branchIndex: 1,
    requiredPermission: 'nav.view.cases',
    route: '/cases',
  ),
  'agenda': const NavigationTab(
    label: 'Agenda',
    icon: LucideIcons.calendar,
    branchIndex: 2,
    requiredPermission: 'nav.view.agenda',
    route: '/agenda',
  ),
  'offers': const NavigationTab(
    label: 'Ofertas',
    icon: LucideIcons.inbox,
    branchIndex: 3,
    requiredPermission: 'nav.view.offers',
    route: '/offers',
  ),
  'messages': const NavigationTab(
    label: 'Mensagens',
    icon: LucideIcons.messageSquare,
    branchIndex: 4,
    requiredPermission: 'nav.view.messages',
    route: '/messages',
  ),
  'profile': const NavigationTab(
    label: 'Perfil',
    icon: LucideIcons.user,
    branchIndex: 5,
    requiredPermission: 'nav.view.profile',
    route: '/profile',
  ),

  // === ADVOGADO CONTRATANTE ===
  'home': const NavigationTab(
    label: 'Início',
    icon: LucideIcons.home,
    branchIndex: 8,
    requiredPermission: 'nav.view.home',
    route: '/home',
  ),
  'contractor_cases': const NavigationTab(
    label: 'Meus Casos',
    icon: LucideIcons.clipboardList,
    branchIndex: 9,
    requiredPermission: 'nav.view.contractor_cases',
    route: '/contractor-cases',
  ),
  'contractor_offers': const NavigationTab(
    label: 'Ofertas',
    icon: LucideIcons.inbox,
    branchIndex: 10,
    requiredPermission: 'nav.view.contractor_offers',
    route: '/contractor-offers',
  ),
  'partners': const NavigationTab(
    label: 'Parceiros',
    icon: LucideIcons.search,
    branchIndex: 11,
    requiredPermission: 'nav.view.partners',
    route: '/partners',
  ),
  'partnerships': const NavigationTab(
    label: 'Parcerias',
    icon: LucideIcons.users,
    branchIndex: 12,
    requiredPermission: 'nav.view.partnerships',
    route: '/partnerships',
  ),
  'contractor_messages': const NavigationTab(
    label: 'Mensagens',
    icon: LucideIcons.messageSquare,
    branchIndex: 13,
    requiredPermission: 'nav.view.contractor_messages',
    route: '/contractor-messages',
  ),
  'contractor_profile': const NavigationTab(
    label: 'Perfil',
    icon: LucideIcons.user,
    branchIndex: 14,
    requiredPermission: 'nav.view.contractor_profile',
    route: '/contractor-profile',
  ),
};

/// Ordem de exibição das abas no menu
/// Organizada por perfil de usuário
const Map<String, List<String>> tabOrderByProfile = {
  'client': [
    'client_home',
    'client_cases',
    'find_lawyers',
    'client_messages',
    'services',
    'client_profile',
  ],
  'lawyer_associated': [
    'dashboard',
    'cases',
    'agenda',
    'offers',
    'messages',
    'profile',
  ],
  'lawyer_individual': [
    'home',
    'contractor_offers',
    'partners',
    'partnerships',
    'contractor_cases',
    'contractor_messages',
    'contractor_profile',
  ],
  'lawyer_office': [
    'home',
    'contractor_offers',
    'partners',
    'partnerships',
    'contractor_cases',
    'contractor_messages',
    'contractor_profile',
  ],
  'lawyer_platform_associate': [
    'home',
    'contractor_offers',
    'partners',
    'partnerships',
    'contractor_cases',
    'contractor_messages',
    'contractor_profile',
  ],
};

/// Função para obter abas visíveis baseado nas permissões do usuário
List<NavigationTab> getVisibleTabsForUser({
  required List<String> userPermissions,
  required String userRole,
}) {
  final List<NavigationTab> visibleTabs = [];
  
  // Obter ordem das abas para o perfil do usuário
  final tabOrder = tabOrderByProfile[userRole] ?? tabOrderByProfile['client']!;
  
  // Filtrar abas baseado nas permissões
  for (final tabKey in tabOrder) {
    final tab = allPossibleTabs[tabKey];
    if (tab != null && userPermissions.contains(tab.requiredPermission)) {
      // Filtro para não exibir rotas desativadas
      if (tab.branchIndex != 99) {
        visibleTabs.add(tab);
      }
    }
  }
  
  // FALLBACK: Garantir pelo menos 2 abas para evitar erro no BottomNavigationBar
  if (visibleTabs.length < 2) {
    // Para clientes: adicionar abas essenciais por padrão
    if (userRole == 'client' || userRole == 'CLIENT') {
      final defaultClientTabs = [
        allPossibleTabs['client_home']!,
        allPossibleTabs['find_lawyers']!,
      ];
      visibleTabs.clear();
      visibleTabs.addAll(defaultClientTabs);
    } else {
      // Para outros perfis: adicionar pelo menos as primeiras 2 abas do tabOrder
      for (final tabKey in tabOrder.take(2)) {
        final tab = allPossibleTabs[tabKey];
        if (tab != null && tab.branchIndex != 99) {
          visibleTabs.add(tab);
        }
      }
    }
  }
  
  return visibleTabs;
}

/// Feature flag para controlar o uso do novo sistema
/// Utiliza Firebase Remote Config para controle dinâmico
bool get useNewNavigationSystem => RemoteConfigService.instance.useNewNavigationSystem;

/// Função para obter rota inicial baseada no perfil do usuário
String getInitialRouteForUser(String userRole) {
  switch (userRole) {
    case 'lawyer_associated':
      return '/dashboard';
    case 'lawyer_individual':
    case 'lawyer_office':
    case 'lawyer_platform_associate':
      return '/home';
    default: // cliente
      return '/client-home';
  }
}

/// Função para verificar se o usuário tem uma permissão específica
bool userHasPermission(List<String> userPermissions, String permission) {
  return userPermissions.contains(permission);
}

/// Função para encontrar aba por rota
NavigationTab? findTabByRoute(String route) {
  return allPossibleTabs.values.where((tab) => tab.route == route).firstOrNull;
}

/// Função para encontrar índice da aba no branch de navegação
int findBranchIndexByRoute(String route) {
  final tab = findTabByRoute(route);
  return tab?.branchIndex ?? 0;
} 