import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../features/vip/presentation/bloc/vip_status_bloc.dart';
import 'vip_client_badge.dart';

/// Widget VIP Badge com BlocBuilder granular para performance otimizada
///
/// ⚡ OTIMIZAÇÕES IMPLEMENTADAS:
/// - Rebuilds seletivos apenas quando dados VIP relevantes mudam
/// - buildWhen inteligente para filtrar mudanças irrelevantes
/// - Cache de props para evitar comparações desnecessárias
/// - Hooks para memoização avançada
class GranularVipBadge extends HookWidget {
  final String userId;
  final String? viewerRole;
  final VoidCallback? onTap;
  final bool showTooltip;
  final bool enableHapticFeedback;

  const GranularVipBadge({
    super.key,
    required this.userId,
    required this.viewerRole,
    this.onTap,
    this.showTooltip = true,
    this.enableHapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    // Memoiza props para evitar comparações desnecessárias
    final memoizedProps = useMemoized(
      () => _VipBadgeProps(
        userId: userId,
        viewerRole: viewerRole,
        onTap: onTap,
        showTooltip: showTooltip,
        enableHapticFeedback: enableHapticFeedback,
      ),
      [userId, viewerRole, onTap, showTooltip, enableHapticFeedback],
    );

    return BlocBuilder<VipStatusBloc, VipStatusState>(
      // 🎯 GRANULARIDADE: Só rebuilda quando dados VIP relevantes mudam
      buildWhen: (previous, current) {
        return _shouldRebuild(previous, current, memoizedProps.userId);
      },
      builder: (context, state) {
        return _buildVipBadgeFromState(state, memoizedProps);
      },
    );
  }

  /// Lógica inteligente para determinar quando rebuildar
  bool _shouldRebuild(
    VipStatusState previous, 
    VipStatusState current, 
    String userId
  ) {
    // Sempre rebuilda se mudou de tipo de state
    if (previous.runtimeType != current.runtimeType) {
      return true;
    }

    // Para VipStatusLoaded, verifica mudanças específicas
    if (previous is VipStatusLoaded && current is VipStatusLoaded) {
      // Só rebuild se for o mesmo usuário E dados VIP mudaram
      if (previous.userId == userId && current.userId == userId) {
        return previous.currentPlan != current.currentPlan ||
               previous.isVip != current.isVip ||
               previous.benefits.length != current.benefits.length;
      }
      // Se userId diferente, não precisa rebuild
      return false;
    }

    // Para outros estados, sempre rebuilda (loading, error)
    return true;
  }

  Widget _buildVipBadgeFromState(VipStatusState state, _VipBadgeProps props) {
    switch (state.runtimeType) {
      case VipStatusLoaded:
        final loadedState = state as VipStatusLoaded;
        if (loadedState.userId == props.userId) {
          return VipClientBadge(
            clientPlan: loadedState.currentPlan,
            viewerRole: props.viewerRole,
            onTap: props.onTap,
            showTooltip: props.showTooltip,
            enableHapticFeedback: props.enableHapticFeedback,
          );
        }
        break;
        
      case VipStatusLoading:
        return _buildLoadingBadge();
        
      case VipStatusError:
        return _buildErrorBadge();
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingBadge() {
    return Container(
      width: 60,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.error_outline,
        size: 16,
        color: Colors.red.shade600,
      ),
    );
  }
}

/// Classe interna para memoização de props
class _VipBadgeProps {
  final String userId;
  final String? viewerRole;
  final VoidCallback? onTap;
  final bool showTooltip;
  final bool enableHapticFeedback;

  const _VipBadgeProps({
    required this.userId,
    required this.viewerRole,
    this.onTap,
    required this.showTooltip,
    required this.enableHapticFeedback,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _VipBadgeProps &&
           other.userId == userId &&
           other.viewerRole == viewerRole &&
           other.onTap == onTap &&
           other.showTooltip == showTooltip &&
           other.enableHapticFeedback == enableHapticFeedback;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      viewerRole,
      onTap,
      showTooltip,
      enableHapticFeedback,
    );
  }
}
