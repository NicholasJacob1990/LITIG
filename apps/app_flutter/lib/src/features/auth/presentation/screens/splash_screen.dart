import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/core/utils/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    AppLogger.info('SplashScreen iniciado');
    // Removendo o timer para evitar conflitos - o BlocListener irá gerenciar a navegação
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Construindo SplashScreen...');
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: BlocListener<AuthBloc, auth_states.AuthState>(
        listener: (context, state) {
          AppLogger.debug('AuthState mudou no SplashScreen: ${state.runtimeType}');
          
          // Aguarda um mínimo de 2 segundos para uma experiência melhor
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              if (state is auth_states.Authenticated) {
                AppLogger.success('Navegando para dashboard (listener)');
                context.go('/dashboard');
              } else if (state is auth_states.Unauthenticated) {
                AppLogger.info('Navegando para login (listener)');
                context.go('/login');
              }
            }
          });
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo do app
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.gavel,
                  size: 60,
                  color: Color(0xFF0066FF),
                ),
              ),
              const SizedBox(height: 32),
              // Nome do app
              Text(
                'LITGO',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Conectando você ao advogado ideal',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              // Debug info
              BlocBuilder<AuthBloc, auth_states.AuthState>(
                builder: (context, state) {
                  return Text(
                    'Estado: ${state.runtimeType}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
