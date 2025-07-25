import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/cluster_repository.dart';
import '../../domain/entities/partnership_recommendation.dart';

// Events
abstract class PartnershipRecommendationsEvent extends Equatable {
  const PartnershipRecommendationsEvent();

  @override
  List<Object?> get props => [];
}

class FetchPartnershipRecommendations extends PartnershipRecommendationsEvent {
  final String lawyerId;
  final int limit;
  final double minCompatibility;

  const FetchPartnershipRecommendations({
    required this.lawyerId,
    this.limit = 10,
    this.minCompatibility = 0.6,
  });

  @override
  List<Object?> get props => [lawyerId, limit, minCompatibility];
}

class ProvidePartnershipFeedback extends PartnershipRecommendationsEvent {
  final String lawyerId;
  final String feedbackType;
  final double feedbackScore;
  final int? interactionTimeSeconds;
  final String? feedbackNotes;

  const ProvidePartnershipFeedback({
    required this.lawyerId,
    required this.feedbackType,
    required this.feedbackScore,
    this.interactionTimeSeconds,
    this.feedbackNotes,
  });

  @override
  List<Object?> get props => [
        lawyerId,
        feedbackType,
        feedbackScore,
        interactionTimeSeconds,
        feedbackNotes,
      ];
}

class RefreshPartnershipRecommendations extends PartnershipRecommendationsEvent {
  final String lawyerId;

  const RefreshPartnershipRecommendations({required this.lawyerId});

  @override
  List<Object?> get props => [lawyerId];
}

// States
abstract class PartnershipRecommendationsState extends Equatable {
  const PartnershipRecommendationsState();

  @override
  List<Object?> get props => [];
}

class PartnershipRecommendationsInitial extends PartnershipRecommendationsState {}

class PartnershipRecommendationsLoading extends PartnershipRecommendationsState {}

class PartnershipRecommendationsLoaded extends PartnershipRecommendationsState {
  final List<PartnershipRecommendation> recommendations;
  final DateTime lastUpdated;

  const PartnershipRecommendationsLoaded({
    required this.recommendations,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [recommendations, lastUpdated];

  PartnershipRecommendationsLoaded copyWith({
    List<PartnershipRecommendation>? recommendations,
    DateTime? lastUpdated,
  }) {
    return PartnershipRecommendationsLoaded(
      recommendations: recommendations ?? this.recommendations,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class PartnershipRecommendationsError extends PartnershipRecommendationsState {
  final String message;
  final String? errorCode;

  const PartnershipRecommendationsError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

class PartnershipFeedbackSuccess extends PartnershipRecommendationsState {
  final String message;
  final String feedbackType;

  const PartnershipFeedbackSuccess({
    required this.message,
    required this.feedbackType,
  });

  @override
  List<Object?> get props => [message, feedbackType];
}

class PartnershipFeedbackError extends PartnershipRecommendationsState {
  final String message;
  final String feedbackType;

  const PartnershipFeedbackError({
    required this.message,
    required this.feedbackType,
  });

  @override
  List<Object?> get props => [message, feedbackType];
}

// BLoC
class PartnershipRecommendationsBloc extends Bloc<PartnershipRecommendationsEvent, PartnershipRecommendationsState> {
  final ClusterRepository repository;

  PartnershipRecommendationsBloc({required this.repository}) : super(PartnershipRecommendationsInitial()) {
    on<FetchPartnershipRecommendations>(_onFetchPartnershipRecommendations);
    on<ProvidePartnershipFeedback>(_onProvidePartnershipFeedback);
    on<RefreshPartnershipRecommendations>(_onRefreshPartnershipRecommendations);
  }

  Future<void> _onFetchPartnershipRecommendations(
    FetchPartnershipRecommendations event,
    Emitter<PartnershipRecommendationsState> emit,
  ) async {
    emit(PartnershipRecommendationsLoading());

    try {
      final recommendations = await repository.getPartnershipRecommendations(
        lawyerId: event.lawyerId,
        limit: event.limit,
        minCompatibility: event.minCompatibility,
      );

      emit(PartnershipRecommendationsLoaded(
        recommendations: recommendations,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(PartnershipRecommendationsError(
        message: 'Erro ao carregar recomendações: ${e.toString()}',
        errorCode: 'FETCH_ERROR',
      ));
    }
  }

  Future<void> _onProvidePartnershipFeedback(
    ProvidePartnershipFeedback event,
    Emitter<PartnershipRecommendationsState> emit,
  ) async {
    try {
      await repository.providePartnershipFeedback(
        lawyerId: event.lawyerId,
        feedbackType: event.feedbackType,
        feedbackScore: event.feedbackScore,
        interactionTimeSeconds: event.interactionTimeSeconds,
        feedbackNotes: event.feedbackNotes,
      );

      emit(PartnershipFeedbackSuccess(
        message: 'Feedback enviado com sucesso!',
        feedbackType: event.feedbackType,
      ));

      // Voltar ao estado carregado após feedback bem-sucedido
      if (state is PartnershipRecommendationsLoaded) {
        emit(state as PartnershipRecommendationsLoaded);
      }
    } catch (e) {
      emit(PartnershipFeedbackError(
        message: 'Erro ao enviar feedback: ${e.toString()}',
        feedbackType: event.feedbackType,
      ));

      // Voltar ao estado carregado após erro
      if (state is PartnershipRecommendationsLoaded) {
        emit(state as PartnershipRecommendationsLoaded);
      }
    }
  }

  Future<void> _onRefreshPartnershipRecommendations(
    RefreshPartnershipRecommendations event,
    Emitter<PartnershipRecommendationsState> emit,
  ) async {
    // Manter dados existentes enquanto carrega novos
    final currentState = state;
    if (currentState is PartnershipRecommendationsLoaded) {
      emit(currentState.copyWith(lastUpdated: DateTime.now()));
    }

    try {
      final recommendations = await repository.getPartnershipRecommendations(
        lawyerId: event.lawyerId,
      );

      emit(PartnershipRecommendationsLoaded(
        recommendations: recommendations,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      // Se já havia dados carregados, manter eles e só mostrar erro
      if (currentState is PartnershipRecommendationsLoaded) {
        emit(currentState);
        emit(PartnershipRecommendationsError(
          message: 'Erro ao atualizar recomendações: ${e.toString()}',
          errorCode: 'REFRESH_ERROR',
        ));
        emit(currentState);
      } else {
        emit(PartnershipRecommendationsError(
          message: 'Erro ao carregar recomendações: ${e.toString()}',
          errorCode: 'REFRESH_ERROR',
        ));
      }
    }
  }
} 