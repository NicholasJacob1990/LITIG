import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/law_firm.dart';
import '../../domain/usecases/get_firms.dart';
import '../../../../core/error/failures.dart';

// Events
abstract class FirmEvent extends Equatable {
  const FirmEvent();

  @override
  List<Object?> get props => [];
}

class GetFirmsEvent extends FirmEvent {
  final GetFirmsParams params;

  const GetFirmsEvent({required this.params});

  @override
  List<Object?> get props => [params];
}

class RefreshFirmsEvent extends FirmEvent {
  final GetFirmsParams params;

  const RefreshFirmsEvent({required this.params});

  @override
  List<Object?> get props => [params];
}

class FetchMoreFirmsEvent extends FirmEvent {}

class GetFirmDetailsEvent extends FirmEvent {
  final String firmId;

  const GetFirmDetailsEvent({required this.firmId});

  @override
  List<Object?> get props => [firmId];
}

// States
abstract class FirmState extends Equatable {
  const FirmState();

  @override
  List<Object?> get props => [];
}

class FirmInitial extends FirmState {}

class FirmLoading extends FirmState {}

class FirmLoaded extends FirmState {
  final List<LawFirm> firms;
  final bool hasReachedMax;
  final LawFirm? firm; // Para detalhes de uma firm específica

  const FirmLoaded({
    required this.firms,
    this.hasReachedMax = false,
    this.firm,
  });

  @override
  List<Object?> get props => [firms, hasReachedMax, firm];

  FirmLoaded copyWith({
    List<LawFirm>? firms,
    bool? hasReachedMax,
    LawFirm? firm,
  }) {
    return FirmLoaded(
      firms: firms ?? this.firms,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      firm: firm ?? this.firm,
    );
  }
}

class FirmError extends FirmState {
  final String message;

  const FirmError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class FirmBloc extends Bloc<FirmEvent, FirmState> {
  final GetFirms getFirms;
  GetFirmsParams _lastParams = const GetFirmsParams();

  FirmBloc({
    required this.getFirms,
  }) : super(FirmInitial()) {
    on<GetFirmsEvent>(_onGetFirms);
    on<RefreshFirmsEvent>(_onRefreshFirms);
    on<FetchMoreFirmsEvent>(_onFetchMoreFirms, transformer: droppable());
    on<GetFirmDetailsEvent>(_onGetFirmDetails);
  }

  Future<void> _onGetFirms(
    GetFirmsEvent event,
    Emitter<FirmState> emit,
  ) async {
    emit(FirmLoading());
    _lastParams = event.params.copyWith(offset: 0);
    
    final result = await getFirms(_lastParams);

    result.fold(
      (failure) => emit(FirmError(message: _mapFailureToMessage(failure))),
      (firms) => emit(FirmLoaded(
        firms: firms,
        hasReachedMax: firms.length < _lastParams.limit,
      )),
    );
  }

  Future<void> _onFetchMoreFirms(
    FetchMoreFirmsEvent event,
    Emitter<FirmState> emit,
  ) async {
    if (state is FirmLoaded) {
      final currentState = state as FirmLoaded;
      if (currentState.hasReachedMax) return;

      _lastParams = _lastParams.copyWith(offset: currentState.firms.length);

      final result = await getFirms(_lastParams);

      result.fold(
        (failure) => emit(FirmError(message: _mapFailureToMessage(failure))), // Pode-se optar por não emitir erro aqui para uma UX mais suave
        (newFirms) {
          emit(FirmLoaded(
            firms: currentState.firms + newFirms,
            hasReachedMax: newFirms.length < _lastParams.limit,
          ));
        },
      );
    }
  }

  Future<void> _onRefreshFirms(
    RefreshFirmsEvent event,
    Emitter<FirmState> emit,
  ) async {
    _lastParams = event.params.copyWith(offset: 0);
    final result = await getFirms(_lastParams);

    result.fold(
      (failure) => emit(FirmError(message: _mapFailureToMessage(failure))),
      (firms) => emit(FirmLoaded(
        firms: firms,
        hasReachedMax: firms.length < _lastParams.limit,
      )),
    );
  }

  Future<void> _onGetFirmDetails(
    GetFirmDetailsEvent event,
    Emitter<FirmState> emit,
  ) async {
    emit(FirmLoading());
    
    // TODO: Implementar GetFirmDetailsUseCase quando estiver disponível
    // Por enquanto, simular um resultado para evitar erro de compilação
    try {
      // Buscar a firm específica da lista atual se disponível
      if (state is FirmLoaded) {
        final currentState = state as FirmLoaded;
        final firm = currentState.firms.firstWhere(
          (f) => f.id == event.firmId,
          orElse: () => throw Exception('Firm not found'),
        );
        emit(FirmLoaded(firms: currentState.firms, firm: firm));
      } else {
        emit(const FirmError(message: 'Detalhes da firma não disponíveis'));
      }
    } catch (e) {
      emit(FirmError(message: 'Erro ao buscar detalhes da firma: $e'));
    }
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