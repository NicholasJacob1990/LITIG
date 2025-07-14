import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/features/auth/domain/entities/user.dart';

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
          final userRole = state.user.role ?? 'client';
          final navItems = _getNavItemsForRole(userRole);
          
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _getCurrentIndex(userRole, navigationShell.currentIndex),
              onTap: (index) => _onItemTapped(index, navItems),
              items: navItems.map((item) => BottomNavigationBarItem(icon: Icon(item.icon), label: item.label)).toList(),
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

  void _onItemTapped(int index, List<NavItem> navItems) {
    final branchIndex = navItems[index].branchIndex;
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  int _getCurrentIndex(String userRole, int currentBranchIndex) {
    final navItems = _getNavItemsForRole(userRole);
    for (int i = 0; i < navItems.length; i++) {
      if (navItems[i].branchIndex == currentBranchIndex) {
        return i;
      }
    }
    return 0;
  }

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
      case 'lawyer_platform_associate': // NOVO: Super Associado - usa mesma navegação de captação
        return [
          NavItem(label: 'Início', icon: LucideIcons.home, branchIndex: 6),
          NavItem(label: 'Meus Casos', icon: LucideIcons.clipboardList, branchIndex: 7), // NOVA ABA
          NavItem(label: 'Ofertas', icon: LucideIcons.inbox, branchIndex: 8), // Sistema de ofertas (antes era 7)
          NavItem(label: 'Parceiros', icon: LucideIcons.search, branchIndex: 9), // antes era 8
          NavItem(label: 'Parcerias', icon: LucideIcons.users, branchIndex: 10), // antes era 9
          NavItem(label: 'Mensagens', icon: LucideIcons.messageSquare, branchIndex: 11), // antes era 10
          NavItem(label: 'Perfil', icon: LucideIcons.user, branchIndex: 12), // antes era 11
        ];
      default: // client
        return [
          NavItem(label: 'Início', icon: LucideIcons.home, branchIndex: 13), // antes era 12
          NavItem(label: 'Meus Casos', icon: LucideIcons.clipboardList, branchIndex: 14), // antes era 13
          NavItem(label: 'Advogados', icon: LucideIcons.search, branchIndex: 15), // antes era 14
          NavItem(label: 'Mensagens', icon: LucideIcons.messageCircle, branchIndex: 16), // antes era 15
          NavItem(label: 'Serviços', icon: LucideIcons.layoutGrid, branchIndex: 17), // antes era 16
          NavItem(label: 'Perfil', icon: LucideIcons.user, branchIndex: 18), // antes era 17
        ];
    }
  }
}

class NavItem {
  final String label;
  final IconData icon;
  final int branchIndex;

  const NavItem({required this.label, required this.icon, required this.branchIndex});
} 