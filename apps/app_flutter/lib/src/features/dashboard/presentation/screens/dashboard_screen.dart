import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/features/dashboard/presentation/widgets/client_dashboard.dart';
import 'package:meu_app/src/features/dashboard/presentation/widgets/lawyer_dashboard.dart';
import 'package:meu_app/src/features/dashboard/presentation/widgets/firm_dashboard.dart';
import 'package:meu_app/src/features/dashboard/presentation/widgets/contractor_dashboard.dart';
import 'package:meu_app/src/core/utils/logger.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, auth_states.AuthState>(
      builder: (context, state) {
        if (state is auth_states.Authenticated) {
          final user = state.user;
          
          // Debug: imprimir o role para verificar o valor
          AppLogger.debug('Dashboard: User role = ${user.role}');
          
          // Determinar o dashboard baseado no tipo específico de usuário
          switch (user.role) {
            case 'lawyer_office':
              // Sócios de escritório recebem dashboard específico da firma
              return FirmDashboard(userName: user.fullName ?? 'Sócio');
            case 'lawyer_individual':
            case 'lawyer_platform_associate':
              // Advogados contratantes recebem dashboard de captação
              return ContractorDashboard(
                userName: user.fullName ?? 'Advogado',
                userRole: user.role ?? 'lawyer_individual',
              );
            case 'lawyer_associated':
            case 'lawyer':
            case 'LAWYER':
            case 'advogado':
            case 'Lawyer':
              // Advogados associados recebem dashboard pessoal
              return LawyerDashboard(userName: user.fullName ?? 'Advogado');
            case 'client':
            case 'PF':
            default:
              // Clientes recebem dashboard azul de triagem
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