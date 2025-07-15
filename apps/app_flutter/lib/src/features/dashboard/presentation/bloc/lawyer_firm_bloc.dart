import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';
import 'package:meu_app/src/features/firms/domain/repositories/firm_repository.dart';

// Events
abstract class LawyerFirmEvent extends Equatable {
  const LawyerFirmEvent();

  @override
  List<Object?> get props => [];
}

class LoadLawyerFirmInfo extends LawyerFirmEvent {
  const LoadLawyerFirmInfo();
}

class RefreshLawyerFirmInfo extends LawyerFirmEvent {
  const RefreshLawyerFirmInfo();
}

// States
abstract class LawyerFirmState extends Equatable {
  const LawyerFirmState();

  @override
  List<Object?> get props => [];
}

class LawyerFirmInitial extends LawyerFirmState {
  const LawyerFirmInitial();
}

class LawyerFirmLoading extends LawyerFirmState {
  const LawyerFirmLoading();
}

class LawyerFirmLoaded extends LawyerFirmState {
  final LawFirm firm;
  final bool hasActiveCases;
  final int totalCases;

  const LawyerFirmLoaded({
    required this.firm,
    this.hasActiveCases = false,
    this.totalCases = 0,
  });

  @override
  List<Object?> get props => [firm, hasActiveCases, totalCases];
}

class LawyerFirmError extends LawyerFirmState {
  final String message;

  const LawyerFirmError({required this.message});

  @override
  List<Object?> get props => [message];
}

class LawyerFirmNotAssociated extends LawyerFirmState {
  const LawyerFirmNotAssociated();
}

// BLoC
class LawyerFirmBloc extends Bloc<LawyerFirmEvent, LawyerFirmState> {
  final FirmRepository _firmRepository;

  LawyerFirmBloc({
    required FirmRepository firmsRepository,
  }) : _firmRepository = firmsRepository, super(const LawyerFirmInitial()) {
    on<LoadLawyerFirmInfo>(_onLoadLawyerFirmInfo);
    on<RefreshLawyerFirmInfo>(_onRefreshLawyerFirmInfo);
  }

  Future<void> _onLoadLawyerFirmInfo(
    LoadLawyerFirmInfo event,
    Emitter<LawyerFirmState> emit,
  ) async {
    emit(const LawyerFirmLoading());
    await _loadFirmInfo(emit);
  }

  Future<void> _onRefreshLawyerFirmInfo(
    RefreshLawyerFirmInfo event,
    Emitter<LawyerFirmState> emit,
  ) async {
    await _loadFirmInfo(emit);
  }

  Future<void> _loadFirmInfo(Emitter<LawyerFirmState> emit) async {
    try {
      // TODO: Implementar lógica para obter firmId do advogado logado
      // Por enquanto, vamos simular com um ID fixo para teste
      const mockFirmId = 'firm_123';
      
      final result = await _firmRepository.getFirmById(mockFirmId);
      
      result.fold(
        (failure) {
          if (failure.message.contains('not found') || failure.message.contains('404')) {
            emit(const LawyerFirmNotAssociated());
          } else {
            emit(LawyerFirmError(message: failure.message));
          }
        },
        (firm) {
          if (firm != null) {
            // Simular dados adicionais que viriam da API
            const hasActiveCases = true;
            const totalCases = 15;
            
            emit(LawyerFirmLoaded(
              firm: firm,
              hasActiveCases: hasActiveCases,
              totalCases: totalCases,
            ));
          } else {
            emit(const LawyerFirmNotAssociated());
          }
        },
      );
    } catch (e) {
      emit(LawyerFirmError(message: 'Erro inesperado: $e'));
    }
  }
} 