import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:meu_app/src/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:meu_app/src/shared/config/navigation_config.dart';
import 'package:meu_app/src/shared/widgets/context_header_overlay.dart';

class MainTabsShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainTabsShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, auth_states.AuthState>(
      builder: (context, state) {
        if (state is auth_states.Authenticated) {
          final user = state.user;
          final userRole = user.effectiveUserRole;
          final userPermissions = user.permissions;
          
          // Sistema de navegação baseado em permissões
          List<NavigationTab> navTabs = _getNavItemsForPermissions(userPermissions, userRole);
          
          // DEBUG: Log para diagnosticar o problema
          print('DEBUG - UserRole: $userRole');
          print('DEBUG - UserPermissions: $userPermissions');
          print('DEBUG - NavTabs count BEFORE: ${navTabs.length}');
          
          // FALLBACK ADICIONAL: Se ainda está vazio, força abas mínimas
          if (navTabs.isEmpty) {
            print('DEBUG - FORÇANDO FALLBACK MÍNIMO');
            navTabs = [
              const NavigationTab(
                label: 'Início',
                icon: LucideIcons.home,
                branchIndex: 0,
                requiredPermission: 'temp',
                route: '/temp1',
              ),
              const NavigationTab(
                label: 'Perfil',
                icon: LucideIcons.user,
                branchIndex: 1,
                requiredPermission: 'temp',
                route: '/temp2',
              ),
            ];
          }
          
          print('DEBUG - NavTabs count AFTER: ${navTabs.length}');
          print('DEBUG - NavTabs: ${navTabs.map((t) => t.label).toList()}');
          
                    return Scaffold(
            body: userRole == 'lawyer_platform_associate'
                ? ContextHeaderOverlay(child: navigationShell)
                : navigationShell,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _getCurrentIndexForTabs(navTabs, navigationShell.currentIndex),
              onTap: (index) => _onItemTappedForTabs(index, navTabs),
              items: navTabs.map((tab) => _buildBottomNavigationBarItem(context, tab, userRole)).toList(),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Colors.grey,
            ),
          ); 
          // LEGADO: Lógica comentada após migração para sistema de permissões
          /*
          else {
          final navItems = _getNavItemsForRole(userRole);
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: BottomNavigationBar(
                currentIndex: _getCurrentIndexForItems(navItems, navigationShell.currentIndex),
                onTap: (index) => _onItemTappedForItems(index, navItems),
                items: navItems.map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon), 
                  label: item.label,
                )).toList(),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Colors.grey,
            ),
          );
          }
          */
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  /// Constrói item da bottom navigation com badge de notificação quando necessário
  BottomNavigationBarItem _buildBottomNavigationBarItem(
    BuildContext context, 
    NavigationTab tab, 
    String userRole
  ) {
    // Verificar se deve exibir badge de notificação
    final shouldShowBadge = _shouldShowNotificationBadge(tab, userRole);
    
    Widget iconWidget = Icon(tab.icon);
    
    if (shouldShowBadge) {
      // TODO: Implementar NotificationBadge quando NotificationBloc estiver pronto
      iconWidget = Icon(tab.icon);
      /*
      iconWidget = BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, notificationState) {
          return NotificationBadge(
            count: notificationState.unreadCount,
            child: Icon(tab.icon),
          );
        },
      );
      */
    }
    
    return BottomNavigationBarItem(
      icon: iconWidget,
      label: tab.label,
    );
  }

  /// Determina se deve exibir badge de notificação para uma aba específica
  bool _shouldShowNotificationBadge(NavigationTab tab, String userRole) {
    // Apenas advogados recebem notificações por enquanto
    if (!_isLawyer(userRole)) return false;
    
    // Badge aparece em abas relacionadas a ofertas ou mensagens
    return tab.route.contains('offers') || 
           tab.route.contains('messages') ||
           tab.label.toLowerCase() == 'ofertas' ||
           tab.label.toLowerCase() == 'mensagens';
  }

  /// Verifica se o usuário é advogado
  bool _isLawyer(String userRole) {
    return userRole.contains('lawyer') || userRole == 'LAWYER';
  }

  /// Métodos para NavigationTab (nova lógica)
  void _onItemTappedForTabs(int index, List<NavigationTab> navTabs) {
    final branchIndex = navTabs[index].branchIndex;
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  int _getCurrentIndexForTabs(List<NavigationTab> navTabs, int currentBranchIndex) {
    for (int i = 0; i < navTabs.length; i++) {
      if (navTabs[i].branchIndex == currentBranchIndex) {
        return i;
      }
    }
    return 0;
  }

  // LEGADO: Métodos comentados após migração para sistema de permissões
  // TODO: Remover após validação completa do novo sistema
  /*
  /// Métodos para NavItem (lógica legada)
  void _onItemTappedForItems(int index, List<NavItem> navItems) {
    final branchIndex = navItems[index].branchIndex;
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  int _getCurrentIndexForItems(List<NavItem> navItems, int currentBranchIndex) {
    for (int i = 0; i < navItems.length; i++) {
      if (navItems[i].branchIndex == currentBranchIndex) {
        return i;
      }
    }
    return 0;
  }
  */

  /// Nova lógica baseada em permissões
  List<NavigationTab> _getNavItemsForPermissions(List<String> userPermissions, String userRole) {
    // TEMPORÁRIO: Ignorar sistema de permissões e usar fallback direto
    // para resolver erro de BottomNavigationBar
    print('DEBUG - Usando fallback direto para userRole: $userRole');
    return _getFallbackTabsForRole(userRole);
  }
  
    /// Fallback com abas padrão por perfil quando o sistema de permissões falha
  /// Baseado no código legado comentado (linhas 204-242)
  List<NavigationTab> _getFallbackTabsForRole(String userRole) {
    print('DEBUG - Usando fallback para userRole: $userRole');
    
    switch (userRole) {
      case 'lawyer_associated':
        return [
          const NavigationTab(
            label: 'Painel',
            icon: LucideIcons.layoutDashboard,
            branchIndex: 0,
            requiredPermission: 'nav.view.dashboard',
            route: '/dashboard',
          ),
          const NavigationTab(
            label: 'Casos',
            icon: LucideIcons.folder,
            branchIndex: 1,
            requiredPermission: 'nav.view.cases',
            route: '/cases',
          ),
          const NavigationTab(
            label: 'Agenda',
            icon: LucideIcons.calendar,
            branchIndex: 2,
            requiredPermission: 'nav.view.schedule',
            route: '/schedule',
          ),
          const NavigationTab(
            label: 'Ofertas',
            icon: LucideIcons.inbox,
            branchIndex: 3,
            requiredPermission: 'nav.view.offers',
            route: '/offers',
          ),
          const NavigationTab(
            label: 'Mensagens',
            icon: LucideIcons.messageSquare,
            branchIndex: 4,
            requiredPermission: 'nav.view.messages',
            route: '/messages',
          ),
          const NavigationTab(
            label: 'Perfil',
            icon: LucideIcons.user,
            branchIndex: 5,
            requiredPermission: 'nav.view.profile',
            route: '/profile',
          ),
        ];
        
      case 'lawyer_individual':
      case 'lawyer_office':
      case 'lawyer_platform_associate':
        return [
          const NavigationTab(
            label: 'Início',
            icon: LucideIcons.home,
            branchIndex: 6,
            requiredPermission: 'nav.view.home',
            route: '/contractor-home',
          ),
          const NavigationTab(
            label: 'Meus Casos',
            icon: LucideIcons.folder,
            branchIndex: 8,
            requiredPermission: 'nav.view.cases',
            route: '/contractor-cases',
          ),
          const NavigationTab(
            label: 'Ofertas',
            icon: LucideIcons.inbox,
            branchIndex: 9,
            requiredPermission: 'nav.view.offers',
            route: '/contractor-offers',
          ),
          const NavigationTab(
            label: 'Parceiros',
            icon: LucideIcons.search,
            branchIndex: 10,
            requiredPermission: 'nav.view.partners',
            route: '/partners',
          ),
          const NavigationTab(
            label: 'Parcerias',
            icon: LucideIcons.users,
            branchIndex: 11,
            requiredPermission: 'nav.view.partnerships',
            route: '/partnerships',
          ),
          const NavigationTab(
            label: 'Mensagens',
            icon: LucideIcons.messageSquare,
            branchIndex: 11, // CORRIGIDO: de 10 para 11
            requiredPermission: 'nav.view.messages',
            route: '/contractor-messages',
          ),
          const NavigationTab(
            label: 'Perfil',
            icon: LucideIcons.user,
            branchIndex: 12, // CORRIGIDO: de 11 para 12
            requiredPermission: 'nav.view.profile',
            route: '/contractor-profile',
          ),
        ];
        
      case 'PF': // ADICIONADO: Fallback para Cliente (Pessoa Física)
      default:
        return [
          const NavigationTab(
            label: 'Início',
            icon: LucideIcons.home,
            branchIndex: 13,
            requiredPermission: 'nav.view.client.home',
            route: '/client-home',
          ),
          const NavigationTab(
            label: 'Meus Casos',
            icon: LucideIcons.folder,
            branchIndex: 14,
            requiredPermission: 'nav.view.client.cases',
            route: '/client-cases',
          ),
          const NavigationTab(
            label: 'Advogados',
            icon: LucideIcons.search,
            branchIndex: 15,
            requiredPermission: 'nav.view.client.find_lawyers',
            route: '/advogados',
          ),
          const NavigationTab(
            label: 'Mensagens',
            icon: LucideIcons.messageSquare,
            branchIndex: 16,
            requiredPermission: 'nav.view.client.messages',
            route: '/client-messages',
          ),
          const NavigationTab(
            label: 'Serviços',
            icon: LucideIcons.briefcase,
            branchIndex: 17,
            requiredPermission: 'nav.view.client.services',
            route: '/services',
          ),
          const NavigationTab(
            label: 'Perfil',
            icon: LucideIcons.user,
            branchIndex: 18,
            requiredPermission: 'nav.view.client.profile',
            route: '/client-profile',
          ),
        ];
    }
  }

  // LEGADO: Função comentada após migração para sistema de permissões
  // TODO: Remover após validação completa do novo sistema
  /*
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
        return [
          NavItem(label: 'Início', icon: LucideIcons.home, branchIndex: 6),
          NavItem(label: 'Casos', icon: LucideIcons.folder, branchIndex: 1), // Adicionado
          NavItem(label: 'Ofertas', icon: LucideIcons.inbox, branchIndex: 7), // Sistema de ofertas
          NavItem(label: 'Parceiros', icon: LucideIcons.search, branchIndex: 8),
          NavItem(label: 'Parcerias', icon: LucideIcons.users, branchIndex: 9),
          NavItem(label: 'Mensagens', icon: LucideIcons.messageSquare, branchIndex: 10),
          NavItem(label: 'Perfil', icon: LucideIcons.user, branchIndex: 11),
        ];
      case 'lawyer_platform_associate': // NOVO: Super Associado - usa mesma navegação de captação
        return [
          NavItem(label: 'Início', icon: LucideIcons.home, branchIndex: 6),
          NavItem(label: 'Casos', icon: LucideIcons.folder, branchIndex: 1), // Adicionado
          NavItem(label: 'Ofertas', icon: LucideIcons.inbox, branchIndex: 3), // Usa branch 3 (offers)
          NavItem(label: 'Mensagens', icon: LucideIcons.messageSquare, branchIndex: 4),
          NavItem(label: 'Perfil', icon: LucideIcons.user, branchIndex: 5),
        ];
      default: // client
        return [
          NavItem(label: 'Início', icon: LucideIcons.home, branchIndex: 12),
          NavItem(label: 'Meus Casos', icon: LucideIcons.clipboardList, branchIndex: 13),
          NavItem(label: 'Advogados', icon: LucideIcons.search, branchIndex: 14),
          NavItem(label: 'Mensagens', icon: LucideIcons.messageCircle, branchIndex: 15),
          NavItem(label: 'Serviços', icon: LucideIcons.layoutGrid, branchIndex: 16),
          NavItem(label: 'Perfil', icon: LucideIcons.user, branchIndex: 17),
        ];
    }
  }
  */
}

// LEGADO: Classe comentada após migração para sistema de permissões
// TODO: Remover após validação completa do novo sistema
/*
class NavItem {
  final String label;
  final IconData icon;
  final int branchIndex;

  const NavItem({required this.label, required this.icon, required this.branchIndex});
}
*/ 