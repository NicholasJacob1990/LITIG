import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'vip_client_badge.dart';

/// Badge VIP com micro-animações para UX premium
///
/// 🎨 ANIMAÇÕES IMPLEMENTADAS:
/// - Animação de entrada suave com elastic effect
/// - Brilho sutil para badges VIP (breathing effect)
/// - Shake animation quando tapped
/// - Scale animation no hover/focus
/// - Particle effects para planos ENTERPRISE
class AnimatedVipBadge extends StatefulWidget {
  final String? clientPlan;
  final String? viewerRole;
  final VoidCallback? onTap;
  final bool showTooltip;
  final bool enableHapticFeedback;
  final bool enableGlowEffect;
  final bool enableParticles;

  const AnimatedVipBadge({
    super.key,
    required this.clientPlan,
    required this.viewerRole,
    this.onTap,
    this.showTooltip = true,
    this.enableHapticFeedback = true,
    this.enableGlowEffect = true,
    this.enableParticles = false,
  });

  @override
  State<AnimatedVipBadge> createState() => _AnimatedVipBadgeState();
}

class _AnimatedVipBadgeState extends State<AnimatedVipBadge>
    with TickerProviderStateMixin {
  // Controladores de animação
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _shakeController;
  late AnimationController _particleController;

  // Animações
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _particleAnimation;

  // Estados
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialAnimations();
  }

  void _initializeAnimations() {
    // 🚀 Animação de entrada (scale up)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // ✨ Animação de brilho (breathing)
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // 📳 Animação de shake no tap
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 🎆 Animação de partículas (enterprise)
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Configurar curvas das animações
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    ));
  }

  void _startInitialAnimations() {
    // Inicia animação de entrada
    _scaleController.forward();

    // Inicia glow apenas para badges VIP
    if (_isVipPlan() && widget.enableGlowEffect) {
      _glowController.repeat(reverse: true);
    }

    // Inicia partículas para ENTERPRISE
    if (_isEnterprisePlan() && widget.enableParticles) {
      _particleController.repeat();
    }
  }

  bool _isVipPlan() {
    return ['VIP'].contains(widget.clientPlan?.toUpperCase());
  }

  bool _isEnterprisePlan() {
    return ['ENTERPRISE'].contains(widget.clientPlan?.toUpperCase());
  }

  bool _isPremiumPlan() {
    return ['PREMIUM'].contains(widget.clientPlan?.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverStart(),
      onExit: (_) => _onHoverEnd(),
      child: GestureDetector(
        onTapDown: (_) => _onTapDown(),
        onTapUp: (_) => _onTapUp(),
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimation,
            _glowAnimation,
            _shakeAnimation,
            _particleAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value * _getHoverScale(),
              child: Transform.translate(
                offset: _getShakeOffset(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 🎆 Partículas de fundo (Enterprise)
                    if (_isEnterprisePlan() && widget.enableParticles)
                      _buildParticleEffect(),

                    // ✨ Container com glow effect
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _buildGlowEffects(),
                      ),
                      child: VipClientBadge(
                        clientPlan: widget.clientPlan,
                        viewerRole: widget.viewerRole,
                        onTap: null, // Gerenciado aqui
                        showTooltip: widget.showTooltip,
                        enableHapticFeedback: false, // Gerenciado aqui
                      ),
                    ),

                    // 🌟 Highlight effect no hover
                    if (_isHovered)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getAccentColor().withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<BoxShadow> _buildGlowEffects() {
    final shadows = <BoxShadow>[];

    // Glow básico para todos os badges
    shadows.add(BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ));

    // Glow especial para VIP
    if (_isVipPlan() && widget.enableGlowEffect) {
      shadows.add(BoxShadow(
        color: _getAccentColor().withValues(alpha: _glowAnimation.value * 0.6),
        offset: const Offset(0, 0),
        blurRadius: 12 * _glowAnimation.value,
        spreadRadius: 2 * _glowAnimation.value,
      ));
    }

    // Glow intenso para Enterprise
    if (_isEnterprisePlan()) {
      shadows.add(BoxShadow(
        color: Colors.blue.withValues(alpha: 0.4),
        offset: const Offset(0, 0),
        blurRadius: 8,
        spreadRadius: 1,
      ));
    }

    // Glow dourado para Premium
    if (_isPremiumPlan()) {
      shadows.add(BoxShadow(
        color: Colors.amber.withValues(alpha: 0.4),
        offset: const Offset(0, 0),
        blurRadius: 6,
        spreadRadius: 1,
      ));
    }

    return shadows;
  }

  Widget _buildParticleEffect() {
    return Positioned.fill(
      child: CustomPaint(
        painter: ParticlePainter(
          animationValue: _particleAnimation.value,
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Color _getAccentColor() {
    switch (widget.clientPlan?.toUpperCase()) {
      case 'VIP':
        return const Color(0xFF6B46C1); // Roxo
      case 'ENTERPRISE':
        return const Color(0xFF4338CA); // Azul
      case 'PREMIUM':
        return const Color(0xFFB45309); // Dourado
      default:
        return Colors.grey;
    }
  }

  double _getHoverScale() {
    if (_isPressed) return 0.95;
    if (_isHovered) return 1.05;
    return 1.0;
  }

  Offset _getShakeOffset() {
    if (_shakeController.isAnimating) {
      final shakeValue = _shakeAnimation.value;
      final shakeMagnitude = 2.0;
      return Offset(
        shakeMagnitude * (0.5 - (shakeValue * 4) % 1).abs() * 
        (shakeValue > 0.5 ? -1 : 1),
        0,
      );
    }
    return Offset.zero;
  }

  void _onHoverStart() {
    if (mounted) {
      setState(() => _isHovered = true);
    }
  }

  void _onHoverEnd() {
    if (mounted) {
      setState(() => _isHovered = false);
    }
  }

  void _onTapDown() {
    if (mounted) {
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp() {
    if (mounted) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTap() {
    // 📳 Feedback háptico
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    // 🎯 Animação de shake
    _shakeController.reset();
    _shakeController.forward();

    // 🎉 Callback do usuário
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _shakeController.dispose();
    _particleController.dispose();
    super.dispose();
  }
}

/// Painter customizado para efeito de partículas
class ParticlePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final List<Particle> particles;

  ParticlePainter({
    required this.animationValue,
    required this.color,
  }) : particles = _generateParticles();

  static List<Particle> _generateParticles() {
    return List.generate(8, (index) => Particle(
      x: (index * 45.0) % 360, // Distribuição circular
      y: 20 + (index * 5.0),
      size: 2.0 + (index % 3),
      speed: 0.5 + (index * 0.1),
    ));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final progress = (animationValue + particle.speed) % 1.0;
      final radius = 30 * progress;
      final angle = particle.x * (3.14159 / 180) + animationValue * 2 * 3.14159;
      
      final x = center.dx + radius * (angle.cos());
      final y = center.dy + radius * (angle.sin());
      
      final opacity = (1.0 - progress) * 0.6;
      paint.color = color.withValues(alpha: opacity);
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size * (1.0 - progress * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Classe para representar uma partícula
class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;

  const Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

/// Extension para facilitar conversões matemáticas
extension DoubleExtensions on double {
  double cos() => math.cos(this);
  double sin() => math.sin(this);
}

// Import necessário para funções matemáticas já adicionado no topo 