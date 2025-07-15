import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/shared/config/navigation_config.dart';

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
          final navTabs = _getNavItemsForPermissions(userPermissions, userRole);
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _getCurrentIndexForTabs(navTabs, navigationShell.currentIndex),
              onTap: (index) => _onItemTappedForTabs(index, navTabs),
              items: navTabs.map((tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon), 
                label: tab.label,
              )).toList(),
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
    return getVisibleTabsForUser(
      userPermissions: userPermissions,
      userRole: userRole,
    );
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