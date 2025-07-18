import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../utils/app_colors.dart';

/// Indicador discreto apenas com ícones genéricos
/// 
/// Para uso no AppBar - SEM referências à marca LITIG-1
/// Apenas cores e ícones sutis para indicar contexto
class DiscreteContextIndicator extends StatelessWidget {
  const DiscreteContextIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated || 
            !authState.user.isPlatformAssociate) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ponto colorido discreto
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: _getContextColor(context).withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Ícone área pessoal discreto (sem texto)
            if (_isPlatformWork(context))
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/personal'),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey.shade600.withOpacity(0.6),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Color _getContextColor(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '';
    
    if (route.contains('/personal/')) {
      return AppColors.success; // Verde para pessoal
    } else if (route.contains('/admin/')) {
      return AppColors.warning; // Amarelo para admin
    } else {
      return AppColors.primaryBlue; // Azul para trabalho
    }
  }

  bool _isPlatformWork(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '';
    return !route.contains('/personal/');
  }
}

/// Versão ainda mais minimalista - apenas um ponto
class MinimalContextDot extends StatelessWidget {
  const MinimalContextDot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated || 
            !authState.user.isPlatformAssociate) {
          return const SizedBox.shrink();
        }

        return Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: _getContextColor(context).withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Color _getContextColor(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '';
    
    if (route.contains('/personal/')) {
      return AppColors.success;
    } else if (route.contains('/admin/')) {
      return AppColors.warning;
    } else {
      return AppColors.primaryBlue;
    }
  }
} 