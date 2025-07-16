import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/case.dart';
import '../../../firms/domain/entities/law_firm.dart';
import '../../data/services/case_firm_recommendation_service.dart';

// Events
abstract class CaseFirmRecommendationEvent extends Equatable {
  const CaseFirmRecommendationEvent();
}

class FetchFirmRecommendation extends CaseFirmRecommendationEvent {
  final Case caseData;

  const FetchFirmRecommendation({required this.caseData});

  @override
  List<Object?> get props => [caseData];
}

class RefreshFirmRecommendation extends CaseFirmRecommendationEvent {
  final Case caseData;

  const RefreshFirmRecommendation({required this.caseData});

  @override
  List<Object?> get props => [caseData];
}

// States
abstract class CaseFirmRecommendationState extends Equatable {
  const CaseFirmRecommendationState();
}

class CaseFirmRecommendationInitial extends CaseFirmRecommendationState {
  @override
  List<Object> get props => [];
}

class CaseFirmRecommendationLoading extends CaseFirmRecommendationState {
  @override
  List<Object> get props => [];
}

class CaseFirmRecommendationLoaded extends CaseFirmRecommendationState {
  final Case updatedCase;
  final LawFirm recommendedFirm;
  final double matchScore;

  const CaseFirmRecommendationLoaded({
    required this.updatedCase,
    required this.recommendedFirm,
    required this.matchScore,
  });

  @override
  List<Object> get props => [updatedCase, recommendedFirm, matchScore];
}

class CaseFirmRecommendationEmpty extends CaseFirmRecommendationState {
  final String reason;

  const CaseFirmRecommendationEmpty({
    required this.reason,
  });

  @override
  List<Object> get props => [reason];
}

class CaseFirmRecommendationError extends CaseFirmRecommendationState {
  final String message;

  const CaseFirmRecommendationError({required this.message});

  @override
  List<Object> get props => [message];
}

// BLoC
class CaseFirmRecommendationBloc extends Bloc<CaseFirmRecommendationEvent, CaseFirmRecommendationState> {
  final CaseFirmRecommendationService _recommendationService;

  CaseFirmRecommendationBloc({
    required CaseFirmRecommendationService recommendationService,
  }) : _recommendationService = recommendationService,
       super(CaseFirmRecommendationInitial()) {
    on<FetchFirmRecommendation>(_onFetchFirmRecommendation);
    on<RefreshFirmRecommendation>(_onRefreshFirmRecommendation);
  }

  Future<void> _onFetchFirmRecommendation(
    FetchFirmRecommendation event,
    Emitter<CaseFirmRecommendationState> emit,
  ) async {
    emit(CaseFirmRecommendationLoading());
    
    try {
      final recommendedFirm = await _recommendationService.getRecommendedFirm(event.caseData);
      
      if (recommendedFirm == null) {
        emit(const CaseFirmRecommendationEmpty(
          reason: 'Caso não elegível para recomendação de escritório'
        ));
        return;
      }
      
      final matchScore = await _recommendationService.calculateMatchScore(
        event.caseData,
        recommendedFirm,
      );
      
      final updatedCase = Case.withRecommendedFirm(
        originalCase: event.caseData,
        recommendedFirm: recommendedFirm,
        matchScore: matchScore,
      );
      
      emit(CaseFirmRecommendationLoaded(
        updatedCase: updatedCase,
        recommendedFirm: recommendedFirm,
        matchScore: matchScore,
      ));
    } catch (e) {
      emit(CaseFirmRecommendationError(
        message: 'Erro ao buscar recomendação: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRefreshFirmRecommendation(
    RefreshFirmRecommendation event,
    Emitter<CaseFirmRecommendationState> emit,
  ) async {
    // Reutilizar a lógica de fetch
    add(FetchFirmRecommendation(caseData: event.caseData));
  }
} 
 
 