import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/core/error/failures.dart';
import '../../domain/usecases/submit_rating_usecase.dart';
import '../../domain/usecases/get_lawyer_ratings_usecase.dart';
import '../../domain/usecases/check_can_rate_usecase.dart';
import '../../domain/repositories/rating_repository.dart';
import 'rating_event.dart';
import 'rating_state.dart';

/// BLoC responsável pelo gerenciamento do estado das avaliações
class RatingBloc extends Bloc<RatingEvent, RatingState> {
  final SubmitRatingUseCase submitRatingUseCase;
  final GetLawyerRatingsUseCase getLawyerRatingsUseCase;
  final CheckCanRateUseCase checkCanRateUseCase;
  final RatingRepository repository;

  // Cache para paginação
  int _currentPage = 1;
  String? _currentLawyerId;
  bool _hasMoreRatings = true;

  RatingBloc({
    required this.submitRatingUseCase,
    required this.getLawyerRatingsUseCase,
    required this.checkCanRateUseCase,
    required this.repository,
  }) : super(const RatingInitial()) {
    // Registrar handlers dos eventos
    on<SubmitRating>(_onSubmitRating);
    on<LoadLawyerRatings>(_onLoadLawyerRatings);
    on<LoadLawyerStats>(_onLoadLawyerStats);
    on<CheckCanRate>(_onCheckCanRate);
    on<LoadCaseRatings>(_onLoadCaseRatings);
    on<VoteHelpful>(_onVoteHelpful);
    on<UpdateRating>(_onUpdateRating);
    on<DeleteRating>(_onDeleteRating);
    on<ClearRatingState>(_onClearRatingState);
    on<LoadMoreRatings>(_onLoadMoreRatings);
  }

  /// Handler para submeter avaliação
  Future<void> _onSubmitRating(
    SubmitRating event,
    Emitter<RatingState> emit,
  ) async {
    emit(const RatingSubmitting());

    final result = await submitRatingUseCase(event.rating);

    result.fold(
      (failure) => emit(RatingError(message: _mapFailureToMessage(failure))),
      (ratingId) => emit(RatingSubmitted(ratingId: ratingId)),
    );
  }

  /// Handler para carregar avaliações de advogado
  Future<void> _onLoadLawyerRatings(
    LoadLawyerRatings event,
    Emitter<RatingState> emit,
  ) async {
    // Reset paginação se for novo advogado
    if (_currentLawyerId != event.lawyerId) {
      _currentPage = 1;
      _currentLawyerId = event.lawyerId;
      _hasMoreRatings = true;
    }

    emit(const RatingLoading());

    // Carregar avaliações e estatísticas em paralelo
    final ratingsResult = await getLawyerRatingsUseCase(
      event.lawyerId,
      page: event.page,
      limit: event.limit,
    );

    final statsResult = await repository.getLawyerStats(event.lawyerId);

    ratingsResult.fold(
      (failure) => emit(RatingError(message: _mapFailureToMessage(failure))),
      (ratings) {
        // Verificar se há mais páginas
        _hasMoreRatings = ratings.length >= event.limit;
        _currentPage = event.page;

        statsResult.fold(
          (failure) => emit(LawyerRatingsLoaded(
            ratings: ratings,
            currentPage: _currentPage,
            hasMore: _hasMoreRatings,
          )),
          (stats) => emit(LawyerRatingsLoaded(
            ratings: ratings,
            stats: stats,
            currentPage: _currentPage,
            hasMore: _hasMoreRatings,
          )),
        );
      },
    );
  }

  /// Handler para carregar estatísticas do advogado
  Future<void> _onLoadLawyerStats(
    LoadLawyerStats event,
    Emitter<RatingState> emit,
  ) async {
    emit(const RatingLoading());

    final result = await repository.getLawyerStats(event.lawyerId);

    result.fold(
      (failure) => emit(RatingError(message: _mapFailureToMessage(failure))),
      (stats) => emit(LawyerStatsLoaded(stats)),
    );
  }

  /// Handler para verificar se pode avaliar
  Future<void> _onCheckCanRate(
    CheckCanRate event,
    Emitter<RatingState> emit,
  ) async {
    emit(const RatingLoading());

    final result = await checkCanRateUseCase(event.caseId);

    result.fold(
      (failure) => emit(RatingError(message: _mapFailureToMessage(failure))),
      (canRateData) => emit(CanRateLoaded(
        canRate: canRateData['can_rate'] ?? false,
        reason: canRateData['reason'],
        raterType: canRateData['rater_type'],
        caseInfo: canRateData['case_info'],
        existingRatingId: canRateData['existing_rating_id'],
      )),
    );
  }

  /// Handler para carregar avaliações de caso
  Future<void> _onLoadCaseRatings(
    LoadCaseRatings event,
    Emitter<RatingState> emit,
  ) async {
    emit(const RatingLoading());

    final result = await repository.getCaseRatings(event.caseId);

    result.fold(
      (failure) => emit(RatingError(message: _mapFailureToMessage(failure))),
      (ratings) => emit(CaseRatingsLoaded(ratings)),
    );
  }

  /// Handler para votar como útil
  Future<void> _onVoteHelpful(
    VoteHelpful event,
    Emitter<RatingState> emit,
  ) async {
    // Não mudar o estado principal, apenas mostrar feedback
    final result = await repository.voteHelpful(event.ratingId);

    result.fold(
      (failure) => emit(RatingError(message: _mapFailureToMessage(failure))),
      (_) => emit(VoteRegistered(ratingId: event.ratingId)),
    );
  }

  /// Handler para atualizar avaliação
  Future<void> _onUpdateRating(
    UpdateRating event,
    Emitter<RatingState> emit,
  ) async {
    emit(const RatingLoading());

    final result = await repository.updateRating(event.rating);

    result.fold(
      (failure) => emit(RatingError(message: _mapFailureToMessage(failure))),
      (_) => emit(RatingUpdated(rating: event.rating)),
    );
  }

  /// Handler para deletar avaliação
  Future<void> _onDeleteRating(
    DeleteRating event,
    Emitter<RatingState> emit,
  ) async {
    emit(const RatingLoading());

    final result = await repository.deleteRating(event.ratingId);

    result.fold(
      (failure) => emit(RatingError(message: _mapFailureToMessage(failure))),
      (_) => emit(RatingDeleted(ratingId: event.ratingId)),
    );
  }

  /// Handler para limpar estado
  Future<void> _onClearRatingState(
    ClearRatingState event,
    Emitter<RatingState> emit,
  ) async {
    _currentPage = 1;
    _currentLawyerId = null;
    _hasMoreRatings = true;
    emit(const RatingInitial());
  }

  /// Handler para carregar mais avaliações (paginação)
  Future<void> _onLoadMoreRatings(
    LoadMoreRatings event,
    Emitter<RatingState> emit,
  ) async {
    if (!_hasMoreRatings || _currentLawyerId != event.lawyerId) return;

    // Manter estado atual e adicionar loading
    if (state is LawyerRatingsLoaded) {
      final currentState = state as LawyerRatingsLoaded;
      emit(currentState.copyWith(isLoadingMore: true));

      final result = await getLawyerRatingsUseCase(
        event.lawyerId,
        page: _currentPage + 1,
        limit: 10,
      );

      result.fold(
        (failure) => emit(currentState.copyWith(
          isLoadingMore: false,
        )),
        (newRatings) {
          _hasMoreRatings = newRatings.length >= 10;
          _currentPage++;

          final allRatings = [...currentState.ratings, ...newRatings];

          emit(currentState.copyWith(
            ratings: allRatings,
            currentPage: _currentPage,
            hasMore: _hasMoreRatings,
            isLoadingMore: false,
          ));
        },
      );
    }
  }

  /// Mapeia falhas para mensagens de erro amigáveis
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ValidationFailure:
        return failure.message;
      case ConnectionFailure:
        return 'Verifique sua conexão com a internet';
      case ServerFailure:
        return 'Erro no servidor. Tente novamente mais tarde';
      case AuthenticationFailure:
        return 'Você precisa estar logado para esta operação';
      case AuthorizationFailure:
        return 'Você não tem permissão para esta operação';
      case TimeoutFailure:
        return 'A operação demorou muito para ser concluída';
      default:
        return failure.message.isNotEmpty
            ? failure.message
            : 'Erro inesperado. Tente novamente';
    }
  }

  /// Retorna true se existem dados carregados
  bool get hasData {
    return state is LawyerRatingsLoaded ||
           state is LawyerStatsLoaded ||
           state is CanRateLoaded ||
           state is CaseRatingsLoaded;
  }

  /// Retorna true se está carregando
  bool get isLoading {
    return state is RatingLoading || state is RatingSubmitting;
  }

  /// Retorna true se há erro
  bool get hasError {
    return state is RatingError ||
           state is RatingValidationError ||
           state is RatingNetworkError;
  }

  /// Retorna mensagem de erro se houver
  String? get errorMessage {
    if (state is RatingError) {
      return (state as RatingError).message;
    }
    if (state is RatingValidationError) {
      return (state as RatingValidationError).message;
    }
    if (state is RatingNetworkError) {
      return (state as RatingNetworkError).message;
    }
    return null;
  }
} 