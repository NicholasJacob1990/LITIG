import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
              currentIndex: navigationShell.currentIndex,
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

  List<NavItem> _getNavItemsForRole(String userRole) {
    switch (userRole) {
      case 'lawyer_associated':
        return [
          NavItem(label: 'Painel', icon: Icons.dashboard, branchIndex: 0),
          NavItem(label: 'Casos', icon: Icons.folder, branchIndex: 1),
          NavItem(label: 'Agenda', icon: Icons.event_note, branchIndex: 2),
          NavItem(label: 'Ofertas', icon: Icons.inbox, branchIndex: 3),
          NavItem(label: 'Mensagens', icon: Icons.chat, branchIndex: 4),
          NavItem(label: 'Perfil', icon: Icons.person, branchIndex: 13),
        ];
      case 'lawyer_individual':
      case 'lawyer_office':
        return [
          NavItem(label: 'Início', icon: Icons.home, branchIndex: 5),
          NavItem(label: 'Parceiros', icon: Icons.search, branchIndex: 6),
          NavItem(label: 'Parcerias', icon: Icons.handshake, branchIndex: 7),
          NavItem(label: 'Mensagens', icon: Icons.chat, branchIndex: 4),
          NavItem(label: 'Perfil', icon: Icons.person, branchIndex: 13),
        ];
      default: // client
        return [
          NavItem(label: 'Início', icon: Icons.home, branchIndex: 9),
          NavItem(label: 'Meus Casos', icon: Icons.cases, branchIndex: 10),
          NavItem(label: 'Advogados', icon: Icons.search, branchIndex: 11),
          NavItem(label: 'Mensagens', icon: Icons.message, branchIndex: 12),
          NavItem(label: 'Serviços', icon: Icons.grid_view, branchIndex: 13),
          NavItem(label: 'Perfil', icon: Icons.person, branchIndex: 14),
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