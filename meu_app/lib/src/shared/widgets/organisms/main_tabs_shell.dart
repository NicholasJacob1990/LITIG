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
    // Usamos um BlocBuilder para reagir a mudanças de estado, como logout.
    return BlocBuilder<AuthBloc, auth_states.AuthState>(
      builder: (context, state) {
        if (state is auth_states.Authenticated) {
          final userRole = state.user.role ?? 'client'; // Default to client if role is null

          return Scaffold(
            body: child,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _calculateSelectedIndex(context),
              onTap: (index) => _onItemTapped(index, context, userRole),
              items: _getNavItems(userRole),
              type: BottomNavigationBarType.fixed, // Garante que todos os itens apareçam
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Colors.grey,
            ),
          );
        }
        // Se não estiver autenticado, não mostra o shell (GoRouter cuidará do redirect)
        return Scaffold(body: child);
      },
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final GoRouter route = GoRouter.of(context);
    final String location = route.routerDelegate.currentConfiguration.uri.toString();
    if (location.startsWith('/dashboard')) {
      return 0;
    }
    if (location.startsWith('/cases')) {
      return 1;
    }
    if (location.startsWith('/triage') || location.startsWith('/schedule')) { // Agenda do advogado
      return 2;
    }
    if (location.startsWith('/lawyers') || location.startsWith('/messages')) { // Mensagens do advogado
      return 3;
    }
    if (location.startsWith('/profile')) {
      return 4;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, String userRole) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/cases');
        break;
      case 2:
        final route = (userRole == 'client') ? '/triage' : '/schedule'; // Rota para /schedule precisa ser criada
        context.go(route);
        break;
      case 3:
        final route = (userRole == 'client') ? '/lawyers' : '/messages'; // Rota para /messages precisa ser criada
        context.go(route);
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  List<BottomNavigationBarItem> _getNavItems(String userRole) {
    if (userRole == 'lawyer') {
      return const [
        BottomNavigationBarItem(icon: Icon(LucideIcons.gauge), label: 'Painel'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.briefcase), label: 'Casos'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.calendar), label: 'Agenda'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.messageCircle), label: 'Mensagens'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Perfil'),
      ];
    }
    // Default para cliente
    return const [
      BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Início'),
      BottomNavigationBarItem(icon: Icon(LucideIcons.clipboardList), label: 'Meus Casos'),
      BottomNavigationBarItem(icon: Icon(LucideIcons.bot), label: 'Triagem'),
      BottomNavigationBarItem(icon: Icon(LucideIcons.users), label: 'Advogados'),
      BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Perfil'),
    ];
  }
} 