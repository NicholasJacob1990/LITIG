import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/partnership_recommendation.dart';
import '../../../partnerships/domain/repositories/partnership_repository.dart';

// Events
abstract class HybridRecommendationsEvent extends Equatable {
  const HybridRecommendationsEvent();

  @override
  List<Object?> get props => [];
}

class FetchHybridRecommendations extends HybridRecommendationsEvent {
  final String lawyerId;
  final bool expandSearch;
  final int limit;
  final double minConfidence;

  const FetchHybridRecommendations({
    required this.lawyerId,
    this.expandSearch = false,
    this.limit = 10,
    this.minConfidence = 0.6,
  });

  @override
  List<Object?> get props => [lawyerId, expandSearch, limit, minConfidence];
}

class RefreshHybridRecommendations extends HybridRecommendationsEvent {
  final String lawyerId;
  final bool expandSearch;

  const RefreshHybridRecommendations({
    required this.lawyerId,
    this.expandSearch = false,
  });

  @override
  List<Object?> get props => [lawyerId, expandSearch];
}

class ToggleExpandSearch extends HybridRecommendationsEvent {
  final String lawyerId;

  const ToggleExpandSearch({required this.lawyerId});

  @override
  List<Object?> get props => [lawyerId];
}

class InviteExternalProfile extends HybridRecommendationsEvent {
  final String recommendationId;
  final PartnershipRecommendation recommendation;

  const InviteExternalProfile({
    required this.recommendationId,
    required this.recommendation,
  });

  @override
  List<Object?> get props => [recommendationId, recommendation];
}

// States
abstract class HybridRecommendationsState extends Equatable {
  const HybridRecommendationsState();

  @override
  List<Object?> get props => [];
}

class HybridRecommendationsInitial extends HybridRecommendationsState {}

class HybridRecommendationsLoading extends HybridRecommendationsState {}

class HybridRecommendationsLoaded extends HybridRecommendationsState {
  final List<PartnershipRecommendation> recommendations;
  final bool expandSearchEnabled;
  final int totalRecommendations;
  final Map<String, dynamic> hybridStats;
  final Map<String, dynamic> algorithmInfo;

  const HybridRecommendationsLoaded({
    required this.recommendations,
    required this.expandSearchEnabled,
    required this.totalRecommendations,
    required this.hybridStats,
    required this.algorithmInfo,
  });

  @override
  List<Object?> get props => [
        recommendations,
        expandSearchEnabled,
        totalRecommendations,
        hybridStats,
        algorithmInfo,
      ];

  HybridRecommendationsLoaded copyWith({
    List<PartnershipRecommendation>? recommendations,
    bool? expandSearchEnabled,
    int? totalRecommendations,
    Map<String, dynamic>? hybridStats,
    Map<String, dynamic>? algorithmInfo,
  }) {
    return HybridRecommendationsLoaded(
      recommendations: recommendations ?? this.recommendations,
      expandSearchEnabled: expandSearchEnabled ?? this.expandSearchEnabled,
      totalRecommendations: totalRecommendations ?? this.totalRecommendations,
      hybridStats: hybridStats ?? this.hybridStats,
      algorithmInfo: algorithmInfo ?? this.algorithmInfo,
    );
  }

  // Getters convenientes
  List<PartnershipRecommendation> get verifiedRecommendations =>
      recommendations.where((r) => r.isVerifiedMember).toList();

  List<PartnershipRecommendation> get externalRecommendations =>
      recommendations.where((r) => r.isPublicProfile).toList();

  List<PartnershipRecommendation> get invitedRecommendations =>
      recommendations.where((r) => r.isInvited).toList();

  int get internalCount => hybridStats['internal_profiles'] ?? 0;
  int get externalCount => hybridStats['external_profiles'] ?? 0;
  double get hybridRatio => hybridStats['hybrid_ratio']?.toDouble() ?? 0.0;
  bool get llmEnabled => algorithmInfo['llm_enabled'] ?? false;
}

class HybridRecommendationsError extends HybridRecommendationsState {
  final String message;

  const HybridRecommendationsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class InvitationSent extends HybridRecommendationsState {
  final String recommendationId;
  final String invitationId;
  final String message;

  const InvitationSent({
    required this.recommendationId,
    required this.invitationId,
    required this.message,
  });

  @override
  List<Object?> get props => [recommendationId, invitationId, message];
}

// BLoC
class HybridRecommendationsBloc
    extends Bloc<HybridRecommendationsEvent, HybridRecommendationsState> {
  final PartnershipRepository repository;

  HybridRecommendationsBloc({required this.repository})
      : super(HybridRecommendationsInitial()) {
    on<FetchHybridRecommendations>(_onFetchHybridRecommendations);
    on<RefreshHybridRecommendations>(_onRefreshHybridRecommendations);
    on<ToggleExpandSearch>(_onToggleExpandSearch);
    on<InviteExternalProfile>(_onInviteExternalProfile);
  }

  Future<void> _onFetchHybridRecommendations(
    FetchHybridRecommendations event,
    Emitter<HybridRecommendationsState> emit,
  ) async {
    emit(HybridRecommendationsLoading());

    try {
      final result = await repository.getEnhancedPartnershipRecommendations(
        lawyerId: event.lawyerId,
        expandSearch: event.expandSearch,
        limit: event.limit,
        minConfidence: event.minConfidence,
      );

      final recommendations = result['recommendations'] as List<dynamic>;
      final algorithmInfo = result['algorithm_info'] as Map<String, dynamic>;
      final metadata = result['metadata'] as Map<String, dynamic>;

      final partnershipRecs = recommendations
          .map((json) => PartnershipRecommendation.fromJson(json))
          .toList();

      emit(HybridRecommendationsLoaded(
        recommendations: partnershipRecs,
        expandSearchEnabled: event.expandSearch,
        totalRecommendations: result['total_recommendations'] ?? 0,
        hybridStats: metadata['hybrid_stats'] ?? {},
        algorithmInfo: algorithmInfo,
      ));
    } catch (e) {
      emit(HybridRecommendationsError(
        message: 'Erro ao carregar recomendações: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRefreshHybridRecommendations(
    RefreshHybridRecommendations event,
    Emitter<HybridRecommendationsState> emit,
  ) async {
    add(FetchHybridRecommendations(
      lawyerId: event.lawyerId,
      expandSearch: event.expandSearch,
    ));
  }

  Future<void> _onToggleExpandSearch(
    ToggleExpandSearch event,
    Emitter<HybridRecommendationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is HybridRecommendationsLoaded) {
      final newExpandSearch = !currentState.expandSearchEnabled;
      
      add(FetchHybridRecommendations(
        lawyerId: event.lawyerId,
        expandSearch: newExpandSearch,
      ));
    }
  }

  Future<void> _onInviteExternalProfile(
    InviteExternalProfile event,
    Emitter<HybridRecommendationsState> emit,
  ) async {
    try {
      final invitationResult = await repository.createPartnershipInvitation(
        externalProfile: event.recommendation.profileData!.toMap(),
        partnershipContext: {
          'area_expertise': event.recommendation.lawyerSpecialty ?? '',
          'compatibility_score': '${(event.recommendation.compatibilityScore * 100).toInt()}%',
          'partnership_reason': event.recommendation.partnershipReason,
        },
      );

      if (invitationResult['status'] == 'created') {
        emit(InvitationSent(
          recommendationId: event.recommendationId,
          invitationId: invitationResult['invitation_id'],
          message: 'Convite enviado com sucesso!',
        ));

        // Atualizar a recomendação para status "invited"
        final currentState = state;
        if (currentState is HybridRecommendationsLoaded) {
          final updatedRecommendations = currentState.recommendations.map((rec) {
            if (rec.recommendedLawyerId == event.recommendation.recommendedLawyerId) {
              return rec.copyWith(
                status: RecommendationStatus.invited,
                invitationId: invitationResult['invitation_id'],
              );
            }
            return rec;
          }).toList();

          emit(currentState.copyWith(recommendations: updatedRecommendations));
        }
      } else {
        emit(HybridRecommendationsError(
          message: invitationResult['message'] ?? 'Erro ao enviar convite',
        ));
      }
    } catch (e) {
      emit(HybridRecommendationsError(
        message: 'Erro ao enviar convite: ${e.toString()}',
      ));
    }
  }
} 