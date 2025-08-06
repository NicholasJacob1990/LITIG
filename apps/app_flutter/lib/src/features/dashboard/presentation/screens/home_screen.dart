import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocBuilder<AuthBloc, auth_states.AuthState>(
      builder: (context, state) {
        String userName = 'Cliente';
        if (state is auth_states.Authenticated) {
          userName = state.user.fullName ?? 'Cliente';
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Olá, $userName'),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.logOut),
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                },
              ),
            ],
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.bot, size: 64, color: Color(0xFF1E40AF)),
                  const SizedBox(height: 24),
                  Text(
                    'Seu Problema Jurídico, Resolvido com Inteligência',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Use nossa IA para uma pré-análise gratuita e seja conectado ao advogado certo para o seu caso.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    icon: const Icon(LucideIcons.playCircle),
                    label: const Text('Iniciar Consulta com IA'),
                    onPressed: () => context.go('/triage'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
