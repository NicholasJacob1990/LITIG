import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/hire_firm.dart';
import '../../../../core/error/failures.dart';

// Events
abstract class FirmHiringEvent extends Equatable {
  const FirmHiringEvent();

  @override
  List<Object?> get props => [];
}

class StartFirmHiring extends FirmHiringEvent {
  final String firmId;
  final String firmName;
  final String caseId;

  const StartFirmHiring({
    required this.firmId,
    required this.firmName,
    required this.caseId,
  });

  @override
  List<Object?> get props => [firmId, firmName, caseId];
}

class ConfirmFirmHiring extends FirmHiringEvent {
  final HireFirmParams params;

  const ConfirmFirmHiring({required this.params});

  @override
  List<Object?> get props => [params];
}

class CancelFirmHiring extends FirmHiringEvent {}

// States
abstract class FirmHiringState extends Equatable {
  const FirmHiringState();

  @override
  List<Object?> get props => [];
}

class FirmHiringInitial extends FirmHiringState {}

class FirmHiringConfirmation extends FirmHiringState {
  final String firmId;
  final String firmName;
  final String caseId;

  const FirmHiringConfirmation({
    required this.firmId,
    required this.firmName,
    required this.caseId,
  });

  @override
  List<Object?> get props => [firmId, firmName, caseId];
}

class FirmHiringLoading extends FirmHiringState {}

class FirmHiringSuccess extends FirmHiringState {
  final HireFirmResult result;

  const FirmHiringSuccess({required this.result});

  @override
  List<Object?> get props => [result];
}

class FirmHiringError extends FirmHiringState {
  final String message;

  const FirmHiringError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class FirmHiringBloc extends Bloc<FirmHiringEvent, FirmHiringState> {
  final HireFirm hireFirm;

  FirmHiringBloc({
    required this.hireFirm,
  }) : super(FirmHiringInitial()) {
    on<StartFirmHiring>(_onStartFirmHiring);
    on<ConfirmFirmHiring>(_onConfirmFirmHiring);
    on<CancelFirmHiring>(_onCancelFirmHiring);
  }

  Future<void> _onStartFirmHiring(
    StartFirmHiring event,
    Emitter<FirmHiringState> emit,
  ) async {
    emit(FirmHiringConfirmation(
      firmId: event.firmId,
      firmName: event.firmName,
      caseId: event.caseId,
    ));
  }

  Future<void> _onConfirmFirmHiring(
    ConfirmFirmHiring event,
    Emitter<FirmHiringState> emit,
  ) async {
    emit(FirmHiringLoading());

    try {
      final result = await hireFirm(event.params);
      
      if (result.isSuccess) {
        emit(FirmHiringSuccess(result: result.value));
      } else {
        emit(FirmHiringError(message: result.failure.message));
      }
    } catch (e) {
      emit(FirmHiringError(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  Future<void> _onCancelFirmHiring(
    CancelFirmHiring event,
    Emitter<FirmHiringState> emit,
  ) async {
    emit(FirmHiringInitial());
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Erro no servidor. Tente novamente.';
      case ConnectionFailure:
        return 'Erro de conexão. Verifique sua internet.';
      case ValidationFailure:
        return failure.message;
      default:
        return 'Erro inesperado. Tente novamente.';
    }
  }
} 