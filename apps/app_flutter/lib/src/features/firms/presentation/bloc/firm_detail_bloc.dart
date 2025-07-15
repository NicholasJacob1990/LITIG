import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/law_firm.dart';
import '../../domain/entities/firm_kpi.dart';
import '../../domain/entities/lawyer.dart';
import '../../domain/usecases/get_firm_by_id.dart';
import '../../domain/usecases/get_firm_kpis.dart';
import '../../domain/usecases/get_firm_lawyers.dart';
import '../../../../core/error/failures.dart';

// Events
abstract class FirmDetailEvent extends Equatable {
  const FirmDetailEvent();

  @override
  List<Object?> get props => [];
}

class GetFirmDetailEvent extends FirmDetailEvent {
  final String firmId;

  const GetFirmDetailEvent({required this.firmId});

  @override
  List<Object?> get props => [firmId];
}

class GetFirmKpisEvent extends FirmDetailEvent {
  final String firmId;

  const GetFirmKpisEvent({required this.firmId});

  @override
  List<Object?> get props => [firmId];
}

class GetFirmLawyersEvent extends FirmDetailEvent {
  final String firmId;
  final GetFirmLawyersParams params;

  const GetFirmLawyersEvent({
    required this.firmId,
    required this.params,
  });

  @override
  List<Object?> get props => [firmId, params];
}

class RefreshFirmDetailEvent extends FirmDetailEvent {
  final String firmId;

  const RefreshFirmDetailEvent({required this.firmId});

  @override
  List<Object?> get props => [firmId];
}

// States
abstract class FirmDetailState extends Equatable {
  const FirmDetailState();

  @override
  List<Object?> get props => [];
}

class FirmDetailInitial extends FirmDetailState {}

class FirmDetailLoading extends FirmDetailState {}

class FirmDetailLoaded extends FirmDetailState {
  final LawFirm firm;
  final FirmKPI? kpis;
  final List<Lawyer>? lawyers; // API returns paginated data with metadata
  final bool isLoadingKpis;
  final bool isLoadingLawyers;

  const FirmDetailLoaded({
    required this.firm,
    this.kpis,
    this.lawyers,
    this.isLoadingKpis = false,
    this.isLoadingLawyers = false,
  });

  @override
  List<Object?> get props => [
        firm,
        kpis,
        lawyers,
        isLoadingKpis,
        isLoadingLawyers,
      ];

  FirmDetailLoaded copyWith({
    FirmKPI? kpis,
    List<Lawyer>? lawyers,
    bool? isLoadingKpis,
    bool? isLoadingLawyers,
  }) {
    return FirmDetailLoaded(
      firm: firm, // firm is required and cannot be changed
      kpis: kpis ?? this.kpis,
      lawyers: lawyers ?? this.lawyers,
      isLoadingKpis: isLoadingKpis ?? this.isLoadingKpis,
      isLoadingLawyers: isLoadingLawyers ?? this.isLoadingLawyers,
    );
  }
}

class FirmDetailError extends FirmDetailState {
  final String message;

  const FirmDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class FirmDetailBloc extends Bloc<FirmDetailEvent, FirmDetailState> {
  final GetFirmById getFirmById;
  final GetFirmKpis getFirmKpis;
  final GetFirmLawyers getFirmLawyers;

  FirmDetailBloc({
    required this.getFirmById,
    required this.getFirmKpis,
    required this.getFirmLawyers,
  }) : super(FirmDetailInitial()) {
    on<GetFirmDetailEvent>(_onGetFirmDetail);
    on<GetFirmKpisEvent>(_onGetFirmKpis, transformer: sequential());
    on<GetFirmLawyersEvent>(_onGetFirmLawyers, transformer: sequential());
    on<RefreshFirmDetailEvent>(_onRefreshFirmDetail);
  }

  Future<void> _onGetFirmDetail(
    GetFirmDetailEvent event,
    Emitter<FirmDetailState> emit,
  ) async {
    emit(FirmDetailLoading());

    final result = await getFirmById(GetFirmByIdParams(firmId: event.firmId));

    result.fold(
      (failure) => emit(FirmDetailError(message: _mapFailureToMessage(failure))),
      (firm) {
        if (firm != null) {
          emit(FirmDetailLoaded(firm: firm));
        } else {
          emit(const FirmDetailError(message: 'Escritório não encontrado'));
        }
      },
    );
  }

  Future<void> _onGetFirmKpis(
    GetFirmKpisEvent event,
    Emitter<FirmDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is FirmDetailLoaded) {
      emit(currentState.copyWith(isLoadingKpis: true));

      final result = await getFirmKpis(GetFirmKpisParams(firmId: event.firmId));

      result.fold(
        (failure) => emit(FirmDetailError(message: _mapFailureToMessage(failure))),
        (kpis) => emit(currentState.copyWith(
          kpis: kpis,
          isLoadingKpis: false,
        )),
      );
    }
  }

  Future<void> _onGetFirmLawyers(
    GetFirmLawyersEvent event,
    Emitter<FirmDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is FirmDetailLoaded) {
      emit(currentState.copyWith(isLoadingLawyers: true));

      final result = await getFirmLawyers(event.params);

      result.fold(
        (failure) {
          // Em caso de falha, podemos manter a lista antiga ou limpá-la.
          // Por enquanto, vamos manter a antiga para não perder a UI se já houver dados.
          emit(currentState.copyWith(isLoadingLawyers: false));
          // Poderíamos emitir um evento de "snackbar" de erro aqui.
        },
        (lawyers) => emit(currentState.copyWith(
          lawyers: lawyers,
          isLoadingLawyers: false,
        )),
      );
    }
  }

  Future<void> _onRefreshFirmDetail(
    RefreshFirmDetailEvent event,
    Emitter<FirmDetailState> emit,
  ) async {
    final result = await getFirmById(GetFirmByIdParams(firmId: event.firmId));

    result.fold(
      (failure) => emit(FirmDetailError(message: _mapFailureToMessage(failure))),
      (firm) {
        if (firm != null) {
          emit(FirmDetailLoaded(firm: firm));
        } else {
          emit(const FirmDetailError(message: 'Escritório não encontrado'));
        }
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Erro no servidor. Tente novamente.';
      case ConnectionFailure:
        return 'Erro de conexão. Verifique sua internet.';
      case ValidationFailure:
        return 'Dados inválidos. Verifique os parâmetros.';
      default:
        return 'Erro inesperado. Tente novamente.';
    }
  }
} 