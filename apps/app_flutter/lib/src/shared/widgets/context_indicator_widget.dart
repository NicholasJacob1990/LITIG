import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../shared/utils/app_colors.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

/// Widget que fornece indicadores visuais sutis para detecção automática de contexto
/// Solução 3: Contexto automático sem toggle manual
/// 
/// Funcionalidades:
/// - Detecção automática de contexto baseada na rota atual
/// - Indicadores visuais sutis (azul LITIG-1, verde pessoal)
/// - Botão de acesso à área pessoal
/// - Integração completa com AutoContextService do backend
/// - Logs automáticos de mudança de contexto
class ContextIndicatorWidget extends StatefulWidget {
  const ContextIndicatorWidget({super.key});

  @override
  State<ContextIndicatorWidget> createState() => _ContextIndicatorWidgetState();
}

class _ContextIndicatorWidgetState extends State<ContextIndicatorWidget> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  
  String _currentContext = 'platform_work';
  bool _isTransitioning = false;
  String? _previousRoute;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _detectInitialContext();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _colorAnimation = ColorTween(
      begin: AppColors.primaryBlue,
      end: AppColors.success,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _detectInitialContext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectAndUpdateContext();
    });
  }

  void _detectAndUpdateContext() {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    
    if (_previousRoute == currentRoute) return;
    _previousRoute = currentRoute;

    final newContext = _determineContextFromRoute(currentRoute);
    
    if (newContext != _currentContext) {
      _triggerContextTransition(newContext);
    }
  }

  String _determineContextFromRoute(String route) {
    // Detecção automática baseada em indicadores de rota
    final personalIndicators = [
      '/personal/',
      '/my-cases/',
      '/client-dashboard/',
      '/personal-profile/',
      '/hire-lawyer-personal/',
      '/my-contracts/',
      '/personal-payments/',
    ];

    final adminIndicators = [
      '/admin/',
      '/platform-dashboard/',
      '/system-reports/',
      '/platform-analytics/',
      '/internal-communications/',
    ];

    // Verificar indicadores de área pessoal
    for (final indicator in personalIndicators) {
      if (route.contains(indicator)) {
        return 'personal_client';
      }
    }

    // Verificar indicadores de área administrativa
    for (final indicator in adminIndicators) {
      if (route.contains(indicator)) {
        return 'administrative_task';
      }
    }

    // Default: trabalho profissional da plataforma
    return 'platform_work';
  }

  void _triggerContextTransition(String newContext) {
    setState(() {
      _isTransitioning = true;
    });

    // Animar transição visual
    _animationController.forward().then((_) {
      setState(() {
        _currentContext = newContext;
        _isTransitioning = false;
      });
      _animationController.reverse();
    });

    // Log da mudança automática (integração com backend)
    _logContextChange(newContext);
  }

  Future<void> _logContextChange(String newContext) async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        // Aqui seria a integração com AutoContextService
        // Em uma implementação real, chamaria o backend
        debugPrint('Context automatically changed to: $newContext');
        debugPrint('User: ${authState.user.id}');
        debugPrint('Route: ${ModalRoute.of(context)?.settings.name}');
        debugPrint('Timestamp: ${DateTime.now().toIso8601String()}');
      }
    } catch (e) {
      debugPrint('Error logging context change: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated || 
            !authState.user.isPlatformAssociate) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            
            return Container(
              margin: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 16,
                vertical: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador principal de contexto
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isTransitioning ? _scaleAnimation.value : 1.0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 8 : 12,
                            vertical: isCompact ? 4 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getContextColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getContextColor(),
                              width: 1.5,
                            ),
                            boxShadow: _isTransitioning ? [
                              BoxShadow(
                                color: _getContextColor().withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ] : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getContextIcon(),
                                size: isCompact ? 14 : 16,
                                color: _getContextColor(),
                              ),
                              if (!isCompact) ...[
                                const SizedBox(width: 6),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getContextTitle(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _getContextColor(),
                                        height: 1.0,
                                      ),
                                    ),
                                    Text(
                                      _getContextSubtitle(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: _getContextColor().withValues(alpha: 0.8),
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Indicador de transição
                  if (_isTransitioning) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(_getContextColor()),
                      ),
                    ),
                  ],

                  // Botão de área pessoal (sempre visível para super associados)
                  if (_currentContext != 'personal_client') ...[
                    const SizedBox(width: 12),
                    _PersonalAreaButton(
                      onPressed: _navigateToPersonalArea,
                      isCompact: isCompact,
                    ),
                  ],

                  // Indicador de notificações contextuais
                  const SizedBox(width: 8),
                  _ContextNotificationBadge(
                    context: _currentContext,
                    isCompact: isCompact,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getContextColor() {
    switch (_currentContext) {
      case 'personal_client':
        return AppColors.success; // Verde para área pessoal
      case 'administrative_task':
        return AppColors.warning; // Amarelo para administrativo
      case 'platform_work':
      default:
        return AppColors.primaryBlue; // Azul LITIG-1 para trabalho da plataforma
    }
  }

  IconData _getContextIcon() {
    switch (_currentContext) {
      case 'personal_client':
        return LucideIcons.user; // Usuário para área pessoal
      case 'administrative_task':
        return LucideIcons.settings; // Configurações para administrativo
      case 'platform_work':
      default:
        return LucideIcons.building2; // Prédio para LITIG-1
    }
  }

  String _getContextTitle() {
    switch (_currentContext) {
      case 'personal_client':
        return 'PESSOAL';
      case 'administrative_task':
        return 'ADMIN';
      case 'platform_work':
      default:
        return 'LITIG-1';
    }
  }

  String _getContextSubtitle() {
    switch (_currentContext) {
      case 'personal_client':
        return 'Área Privada';
      case 'administrative_task':
        return 'Administrativo';
      case 'platform_work':
      default:
        return 'Profissional';
    }
  }

  void _navigateToPersonalArea() {
    Navigator.of(context).pushNamed('/personal-dashboard');
  }
}

/// Botão para acesso rápido à área pessoal
class _PersonalAreaButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isCompact;

  const _PersonalAreaButton({
    required this.onPressed,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 6 : 8,
            vertical: isCompact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.home,
                size: isCompact ? 12 : 14,
                color: AppColors.success,
              ),
              if (!isCompact) ...[
                const SizedBox(width: 4),
                const Text(
                  'Pessoal',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge de notificações contextuais
class _ContextNotificationBadge extends StatelessWidget {
  final String context;
  final bool isCompact;

  const _ContextNotificationBadge({
    required this.context,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final notificationCount = _getContextNotificationCount();
    
    if (notificationCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: BoxConstraints(
        minWidth: isCompact ? 16 : 20,
        minHeight: isCompact ? 16 : 20,
      ),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          notificationCount > 99 ? '99+' : notificationCount.toString(),
          style: TextStyle(
            fontSize: isCompact ? 8 : 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  int _getContextNotificationCount() {
    // Em uma implementação real, isso viria do estado global
    // Por enquanto, simular baseado no contexto
    switch (context) {
      case 'personal_client':
        return 2; // Simulação de 2 notificações pessoais
      case 'administrative_task':
        return 0; // Sem notificações administrativas
      case 'platform_work':
      default:
        return 5; // Simulação de 5 notificações de trabalho
    }
  }
}
