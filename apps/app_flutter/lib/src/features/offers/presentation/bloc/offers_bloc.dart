import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/core/utils/result.dart';
import 'package:meu_app/src/features/offers/domain/entities/case_offer.dart';
import 'package:meu_app/src/features/offers/domain/usecases/offers_usecases.dart';
import 'offers_event.dart';
import 'offers_state.dart';

class OffersBloc extends Bloc<OffersEvent, OffersState> {
  final GetPendingOffersUseCase _getPendingOffersUseCase;
  final GetOfferHistoryUseCase _getOfferHistoryUseCase;
  final GetOfferStatsUseCase _getOfferStatsUseCase;
  final AcceptOfferUseCase _acceptOfferUseCase;
  final RejectOfferUseCase _rejectOfferUseCase;

  OffersBloc({
    required GetPendingOffersUseCase getPendingOffersUseCase,
    required GetOfferHistoryUseCase getOfferHistoryUseCase,
    required GetOfferStatsUseCase getOfferStatsUseCase,
    required AcceptOfferUseCase acceptOfferUseCase,
    required RejectOfferUseCase rejectOfferUseCase,
  })  : _getPendingOffersUseCase = getPendingOffersUseCase,
        _getOfferHistoryUseCase = getOfferHistoryUseCase,
        _getOfferStatsUseCase = getOfferStatsUseCase,
        _acceptOfferUseCase = acceptOfferUseCase,
        _rejectOfferUseCase = rejectOfferUseCase,
        super(OffersInitial()) {
    on<LoadOffersData>(_onLoadOffersData);
    on<AcceptOffer>(_onAcceptOffer);
    on<RejectOffer>(_onRejectOffer);
  }

  Future<void> _onLoadOffersData(
    LoadOffersData event,
    Emitter<OffersState> emit,
  ) async {
    emit(OffersLoading());
    try {
      // Use Future.wait for concurrent execution
      final results = await Future.wait([
        _getPendingOffersUseCase.call(),
        _getOfferHistoryUseCase.call(GetOfferHistoryParams(status: null)),
        _getOfferStatsUseCase.call(),
      ]);

      // Cast the results from Future.wait
      final pendingResult = results[0] as Result<List<CaseOffer>>;
      final historyResult = results[1] as Result<List<CaseOffer>>;
      final statsResult = results[2] as Result<OfferStats>;

      if (pendingResult.isSuccess && historyResult.isSuccess && statsResult.isSuccess) {
        emit(OffersLoaded(
          pendingOffers: pendingResult.value,
          historyOffers: historyResult.value,
          stats: statsResult.value,
        ));
      } else {
        // TODO: Handle individual failures better, e.g., show partial data
        emit(const OffersError('Falha ao carregar os dados das ofertas.'));
      }
    } catch (e) {
      emit(OffersError(e.toString()));
    }
  }

  Future<void> _onAcceptOffer(
    AcceptOffer event,
    Emitter<OffersState> emit,
  ) async {
    final result = await _acceptOfferUseCase.call(
      AcceptOfferParams(offerId: event.offerId, notes: event.notes),
    );

    result.fold(
      (failure) => emit(OfferActionFailure(failure.message)),
      (_) {
        emit(const OfferActionSuccess('Oferta aceita com sucesso!'));
        add(LoadOffersData());
      },
    );
  }

  Future<void> _onRejectOffer(
    RejectOffer event,
    Emitter<OffersState> emit,
  ) async {
    final result = await _rejectOfferUseCase.call(
      RejectOfferParams(offerId: event.offerId, reason: event.reason),
    );

    result.fold(
      (failure) => emit(OfferActionFailure(failure.message)),
      (_) {
        emit(const OfferActionSuccess('Oferta rejeitada.'));
        add(LoadOffersData());
      },
    );
  }
} 