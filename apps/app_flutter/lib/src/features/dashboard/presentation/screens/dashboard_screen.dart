import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/features/dashboard/presentation/widgets/client_dashboard.dart';
import 'package:meu_app/src/features/dashboard/presentation/widgets/lawyer_dashboard.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, auth_states.AuthState>(
      builder: (context, state) {
        if (state is auth_states.Authenticated) {
          final user = state.user;
          // Assumindo que o role 'advogado' vem do backend
          if (user.role == 'advogado') {
            return LawyerDashboard(userName: user.name ?? 'Advogado');
          } else {
            return ClientDashboard(userName: user.name ?? 'Cliente');
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