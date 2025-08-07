import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

  /// Nova lógica baseada em permissões
  List<NavigationTab> _getNavItemsForPermissions(List<String> userPermissions, String userRole) {
    // Usar sistema baseado em permissões com ordem por perfil
    final tabs = getVisibleTabsForUser(userPermissions: userPermissions, userRole: userRole);
    if (tabs.isNotEmpty) return tabs;
    // Fallback em último caso
    print('DEBUG - Permissions returned empty. Falling back to role defaults for $userRole');
    return _getFallbackTabsForRole(userRole);
  }
  
    /// Fallback com abas padrão por perfil quando o sistema de permissões falha
  /// Baseado no código legado comentado (linhas 204-242)
  List<NavigationTab> _getFallbackTabsForRole(String userRole) {
    print('DEBUG - Usando fallback para userRole: $userRole');
    
    switch (userRole) {
      case 'lawyer_firm_member':  // Atualizado de lawyer_associated
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
      case 'firm':
      case 'super_associate':
        return [
          const NavigationTab(
            label: 'Início',
            icon: LucideIcons.home,
            branchIndex: 6,
            requiredPermission: 'nav.view.home',
            route: '/home',
          ),
          const NavigationTab(
            label: 'Meus Casos',
            icon: LucideIcons.folder,
            branchIndex: 7,
            requiredPermission: 'nav.view.cases',
            route: '/contractor-cases',
          ),
          const NavigationTab(
            label: 'Ofertas',
            icon: LucideIcons.inbox,
            branchIndex: 8,
            requiredPermission: 'nav.view.offers',
            route: '/contractor-offers',
          ),
          const NavigationTab(
            label: 'Parceiros',
            icon: LucideIcons.search,
            branchIndex: 9,
            requiredPermission: 'nav.view.partners',
            route: '/partners',
          ),
          const NavigationTab(
            label: 'Parcerias',
            icon: LucideIcons.users,
            branchIndex: 10,
            requiredPermission: 'nav.view.partnerships',
            route: '/partnerships',
          ),
          const NavigationTab(
            label: 'Mensagens',
            icon: LucideIcons.messageSquare,
            branchIndex: 11,
            requiredPermission: 'nav.view.messages',
            route: '/contractor-messages',
          ),
          const NavigationTab(
            label: 'Perfil',
            icon: LucideIcons.user,
            branchIndex: 12,
            requiredPermission: 'nav.view.profile',
            route: '/contractor-profile',
          ),
        ];
        
      case 'client_pf': // Cliente Pessoa Física
      case 'PF': // LEGACY: Fallback para compatibilidade
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
            route: '/find-lawyers',
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
}