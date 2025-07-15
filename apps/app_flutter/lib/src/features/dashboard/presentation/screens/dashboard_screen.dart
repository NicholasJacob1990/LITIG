import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/features/dashboard/presentation/widgets/client_dashboard.dart';
import 'package:meu_app/src/features/dashboard/presentation/widgets/lawyer_dashboard.dart';
import 'package:meu_app/src/core/utils/logger.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Função helper para verificar se é advogado (múltiplos valores possíveis)
  bool _isLawyer(String? userRole) {
    if (userRole == null) return false;
    return userRole == 'lawyer' || 
           userRole == 'LAWYER' || 
           userRole == 'advogado' ||
           userRole == 'Lawyer';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, auth_states.AuthState>(
      builder: (context, state) {
        if (state is auth_states.Authenticated) {
          final user = state.user;
          
          // Debug: imprimir o role para verificar o valor
          AppLogger.debug('Dashboard: User role = ${user.role}');
          
          if (_isLawyer(user.role)) {
            return LawyerDashboard(userName: user.fullName ?? 'Advogado');
          } else {
            return ClientDashboard(userName: user.fullName ?? 'Cliente');
          }
        }
        // Exibe um loader enquanto o estado de autenticação é resolvido
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
} 