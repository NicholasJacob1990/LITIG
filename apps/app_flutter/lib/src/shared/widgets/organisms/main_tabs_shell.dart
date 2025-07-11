import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;

class MainTabsShell extends StatelessWidget {
  final Widget child;

  const MainTabsShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, auth_states.AuthState>(
      builder: (context, state) {
        if (state is auth_states.Authenticated) {
          final userRole = state.user.role ?? 'client';
          return Scaffold(
            body: child,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _calculateSelectedIndex(context, userRole),
              onTap: (index) => _onItemTapped(index, context, userRole),
              items: _getNavItems(userRole),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Colors.grey,
            ),
          );
        }
        return Scaffold(body: child);
      },
    );
  }

  int _calculateSelectedIndex(BuildContext context, String userRole) {
    final String location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    
    if (_isLawyer(userRole)) {
      if (location.startsWith('/dashboard')) return 0;
      if (location.startsWith('/cases')) return 1;
      if (location.startsWith('/schedule')) return 2;
      if (location.startsWith('/messages')) return 3;
      if (location.startsWith('/profile')) return 4;
    } else { // Cliente
      if (location.startsWith('/dashboard')) return 0;
      if (location.startsWith('/cases')) return 1;
      if (location.startsWith('/lawyers')) return 2;
      if (location.startsWith('/client-messages')) return 3;
      if (location.startsWith('/services')) return 4;
      if (location.startsWith('/profile')) return 5;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, String userRole) {
    if (_isLawyer(userRole)) {
      switch (index) {
        case 0: context.go('/dashboard'); break;
        case 1: context.go('/cases'); break;
        case 2: context.go('/schedule'); break;
        case 3: context.go('/messages'); break;
        case 4: context.go('/profile'); break;
      }
    } else { // Cliente
      switch (index) {
        case 0: context.go('/dashboard'); break;
        case 1: context.go('/cases'); break;
        case 2: context.go('/lawyers'); break;
        case 3: context.go('/client-messages'); break;
        case 4: context.go('/services'); break;
        case 5: context.go('/profile'); break;
      }
    }
  }

  bool _isLawyer(String? userRole) {
    if (userRole == null) return false;
    final role = userRole.toLowerCase();
    return role == 'lawyer' || role == 'advogado';
  }

  List<BottomNavigationBarItem> _getNavItems(String userRole) {
    if (_isLawyer(userRole)) {
      return const [
        BottomNavigationBarItem(icon: Icon(LucideIcons.gauge), label: 'Painel'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.briefcase), label: 'Casos'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.calendar), label: 'Agenda'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.messageCircle), label: 'Mensagens'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Perfil'),
      ];
    }
    // Cliente
    return const [
      BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Início'),
      BottomNavigationBarItem(icon: Icon(LucideIcons.clipboardList), label: 'Meus Casos'),
      BottomNavigationBarItem(icon: Icon(LucideIcons.search), label: 'Advogados'),
      BottomNavigationBarItem(icon: Icon(LucideIcons.messageCircle), label: 'Mensagens'),
      BottomNavigationBarItem(icon: Icon(LucideIcons.layoutGrid), label: 'Serviços'),
      BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Perfil'),
    ];
  }
} 