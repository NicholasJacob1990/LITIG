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

  const VipStatusLoaded({
    required this.userId,
    required this.currentPlan,
    required this.isVip,
    required this.benefits,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [userId, currentPlan, isVip, benefits, lastUpdated];
}

class VipStatusError extends VipStatusState {
  final String message;

  const VipStatusError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class VipStatusBloc extends Bloc<VipStatusEvent, VipStatusState> {
  VipStatusBloc() : super(VipStatusInitial()) {
    on<CheckVipStatus>(_onCheckVipStatus);
    on<UpdateVipPlan>(_onUpdateVipPlan);
  }

  Future<void> _onCheckVipStatus(
    CheckVipStatus event,
    Emitter<VipStatusState> emit,
  ) async {
    try {
      emit(VipStatusLoading());
      
      // Simulação de verificação VIP
      await Future.delayed(const Duration(milliseconds: 500));
      
      emit(VipStatusLoaded(
        userId: event.userId,
        currentPlan: 'VIP',
        isVip: true,
        benefits: ['Atendimento prioritário', 'Suporte 24/7'],
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(VipStatusError(message: 'Erro ao verificar status VIP'));
    }
  }

  Future<void> _onUpdateVipPlan(
    UpdateVipPlan event,
    Emitter<VipStatusState> emit,
  ) async {
    try {
      emit(VipStatusLoading());
      await Future.delayed(const Duration(milliseconds: 300));
      add(CheckVipStatus(userId: event.userId, userType: 'client'));
    } catch (e) {
      emit(VipStatusError(message: 'Erro ao atualizar plano VIP'));
    }
  }
}
