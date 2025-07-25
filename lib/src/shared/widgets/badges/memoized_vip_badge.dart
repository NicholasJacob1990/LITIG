import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'vip_client_badge.dart';

/// Widget VIP Badge memoizado para otimização de performance
/// 
/// ⚡ MELHORIAS DE PERFORMANCE:
/// - Memoização para evitar rebuilds desnecessários
/// - Cache de computações baseado em dependências
/// - Rebuild apenas quando clientPlan ou viewerRole mudam
class MemoizedVipBadge extends HookWidget {
  final String? clientPlan;
  final String? viewerRole;
  final VoidCallback? onTap;
  final bool showTooltip;
  final bool enableHapticFeedback;

  const MemoizedVipBadge({
    super.key,
    required this.clientPlan,
    required this.viewerRole,
    this.onTap,
    this.showTooltip = true,
    this.enableHapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    // Memoizar o badge baseado nas dependências críticas
    final memoizedBadge = useMemoized(
      () => VipClientBadge(
        clientPlan: clientPlan,
        viewerRole: viewerRole,
        onTap: onTap,
        showTooltip: showTooltip,
        enableHapticFeedback: enableHapticFeedback,
      ),
      [clientPlan, viewerRole, onTap, showTooltip, enableHapticFeedback],
    );

    return memoizedBadge;
  }
}

/// Extension para facilitar a migração de VipClientBadge para MemoizedVipBadge
extension VipBadgeMemoization on VipClientBadge {
  /// Converte um VipClientBadge para versão memoizada
  static Widget memoized({
    required String? clientPlan,
    required String? viewerRole,
    VoidCallback? onTap,
    bool showTooltip = true,
    bool enableHapticFeedback = true,
  }) {
    return MemoizedVipBadge(
      clientPlan: clientPlan,
      viewerRole: viewerRole,
      onTap: onTap,
      showTooltip: showTooltip,
      enableHapticFeedback: enableHapticFeedback,
    );
  }
} 