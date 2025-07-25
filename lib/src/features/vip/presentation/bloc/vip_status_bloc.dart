import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

// Events
@immutable
abstract class VipStatusEvent extends Equatable {
  const VipStatusEvent();

  @override
  List<Object?> get props => [];
}

class CheckVipStatus extends VipStatusEvent {
  final String userId;
  final String userType;

  const CheckVipStatus({
    required this.userId,
    required this.userType,
  });

  @override
  List<Object?> get props => [userId, userType];
}

class UpdateVipPlan extends VipStatusEvent {
  final String userId;
  final String newPlan;

  const UpdateVipPlan({
    required this.userId,
    required this.newPlan,
  });

  @override
  List<Object?> get props => [userId, newPlan];
}

class RefreshVipBenefits extends VipStatusEvent {
  final String userId;

  const RefreshVipBenefits({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// States
@immutable
abstract class VipStatusState extends Equatable {
  const VipStatusState();

  @override
  List<Object?> get props => [];
}

class VipStatusInitial extends VipStatusState {}

class VipStatusLoading extends VipStatusState {}

class VipStatusLoaded extends VipStatusState {
  final String userId;
  final String currentPlan;
  final bool isVip;
  final List<String> benefits;
  final DateTime lastUpdated;
  final Map<String, dynamic> metadata;

  const VipStatusLoaded({
    required this.userId,
    required this.currentPlan,
    required this.isVip,
    required this.benefits,
    required this.lastUpdated,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [
    userId,
    currentPlan,
    isVip,
    benefits,
    lastUpdated,
    metadata,
  ];

  VipStatusLoaded copyWith({
    String? userId,
    String? currentPlan,
    bool? isVip,
    List<String>? benefits,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return VipStatusLoaded(
      userId: userId ?? this.userId,
      currentPlan: currentPlan ?? this.currentPlan,
      isVip: isVip ?? this.isVip,
      benefits: benefits ?? this.benefits,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }
}

class VipStatusError extends VipStatusState {
  final String message;
  final String? userId;

  const VipStatusError({
    required this.message,
    this.userId,
  });

  @override
  List<Object?> get props => [message, userId];
}

// BLoC
class VipStatusBloc extends Bloc<VipStatusEvent, VipStatusState> {
  final Map<String, VipStatusLoaded> _cache = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);

  VipStatusBloc() : super(VipStatusInitial()) {
    on<CheckVipStatus>(_onCheckVipStatus);
    on<UpdateVipPlan>(_onUpdateVipPlan);
    on<RefreshVipBenefits>(_onRefreshVipBenefits);
  }

  Future<void> _onCheckVipStatus(
    CheckVipStatus event,
    Emitter<VipStatusState> emit,
  ) async {
    try {
      final cached = _cache[event.userId];
      if (cached != null && 
          DateTime.now().difference(cached.lastUpdated) < _cacheExpiration) {
        emit(cached);
        return;
      }

      emit(VipStatusLoading());

      final vipData = await _fetchVipStatus(event.userId, event.userType);
      
      final result = VipStatusLoaded(
        userId: event.userId,
        currentPlan: vipData['plan'] ?? 'FREE',
        isVip: _isVipPlan(vipData['plan']),
        benefits: _getBenefitsForPlan(vipData['plan']),
        lastUpdated: DateTime.now(),
        metadata: vipData['metadata'] ?? {},
      );

      _cache[event.userId] = result;
      emit(result);
    } catch (e) {
      emit(VipStatusError(
        message: 'Erro ao verificar status VIP: ${e.toString()}',
        userId: event.userId,
      ));
    }
  }

  Future<void> _onUpdateVipPlan(
    UpdateVipPlan event,
    Emitter<VipStatusState> emit,
  ) async {
    try {
      emit(VipStatusLoading());
      await _updateUserPlan(event.userId, event.newPlan);
      _cache.remove(event.userId);
      add(CheckVipStatus(userId: event.userId, userType: 'client'));
    } catch (e) {
      emit(VipStatusError(
        message: 'Erro ao atualizar plano VIP: ${e.toString()}',
        userId: event.userId,
      ));
    }
  }

  Future<void> _onRefreshVipBenefits(
    RefreshVipBenefits event,
    Emitter<VipStatusState> emit,
  ) async {
    _cache.remove(event.userId);
    add(CheckVipStatus(userId: event.userId, userType: 'client'));
  }

  Future<Map<String, dynamic>> _fetchVipStatus(String userId, String userType) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return {
      'plan': 'VIP',
      'metadata': {
        'upgraded_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'expires_at': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      },
    };
  }

  Future<void> _updateUserPlan(String userId, String newPlan) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  bool _isVipPlan(String? plan) {
    return ['VIP', 'ENTERPRISE', 'PREMIUM'].contains(plan?.toUpperCase());
  }

  List<String> _getBenefitsForPlan(String? plan) {
    switch (plan?.toUpperCase()) {
      case 'VIP':
        return [
          'Atendimento prioritário',
          'Acesso a advogados premium',
          'Suporte 24/7',
          'Consultas ilimitadas',
        ];
      case 'ENTERPRISE':
        return [
          'Soluções corporativas',
          'Equipe jurídica dedicada',
          'SLA garantido',
          'Relatórios customizados',
          'Integração API',
        ];
      case 'PREMIUM':
        return [
          'Benefícios especiais',
          'Atendimento diferenciado',
          'Consultas preferenciais',
        ];
      default:
        return [];
    }
  }

  @override
  Future<void> close() {
    _cache.clear();
    return super.close();
  }
} 