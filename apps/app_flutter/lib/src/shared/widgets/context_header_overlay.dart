import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../utils/app_colors.dart';

/// Header discreto para indicação automática de contexto
/// 
/// Solução 3 - Versão ultra discreta:
/// - Apenas um ponto colorido sutil no canto
/// - Texto microscópico quando necessário
/// - Animações suaves e imperceptíveis
/// - Botão pessoal quase invisível
class ContextHeaderOverlay extends StatefulWidget {
  final Widget child;

  const ContextHeaderOverlay({
    super.key,
    required this.child,
  });

  @override
  State<ContextHeaderOverlay> createState() => _ContextHeaderOverlayState();
}

class _ContextHeaderOverlayState extends State<ContextHeaderOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final String _currentContext = 'platform_work';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated || 
            !authState.user.isPlatformAssociate) {
          return widget.child;
        }

        return Stack(
          children: [
            widget.child,
            
            // Indicador discreto no topo direito
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildDiscreteIndicator(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDiscreteIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ponto colorido sutil
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: _getContextColor().withValues(alpha: 0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getContextColor().withValues(alpha: 0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Botão área pessoal - quase invisível
        if (_currentContext == 'platform_work')
          GestureDetector(
            onTap: _navigateToPersonalArea,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Icon(
                Icons.person_outline,
                size: 14,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }

  Color _getContextColor() {
    switch (_currentContext) {
      case 'personal_client':
        return AppColors.success; // Verde sutil
      case 'administrative_task':
        return AppColors.warning; // Amarelo sutil
      case 'platform_work':
      default:
        return AppColors.primaryBlue; // Azul sutil
    }
  }

  void _navigateToPersonalArea() {
    // Navegação para área pessoal
    Navigator.of(context).pushNamed('/personal');
  }
}

/// Versão ainda mais discreta - apenas para status bar
class MinimalContextIndicator extends StatelessWidget {
  const MinimalContextIndicator({super.key});

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
            color: _getContextColor(context).withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Color _getContextColor(BuildContext context) {
    // Detecção baseada na rota atual
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

/// Widget para integração no AppBar existente
class DiscreteContextAppBarAction extends StatelessWidget {
  const DiscreteContextAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated || 
            !authState.user.isPlatformAssociate) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador minimalista
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _getContextColor(context).withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Botão área pessoal discreto
              if (_isPlatformWork(context))
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/personal'),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey.shade600.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
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

  bool _isPlatformWork(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '';
    return !route.contains('/personal/');
  }
} 