import 'package:meu_app/src/core/utils/result.dart';
import 'package:meu_app/src/features/offers/domain/entities/case_offer.dart';
import 'package:meu_app/src/features/offers/domain/repositories/offers_repository.dart';

// --- GetPendingOffersUseCase ---
class GetPendingOffersUseCase {
  final OffersRepository _repository;

  GetPendingOffersUseCase(this._repository);

  Future<Result<List<CaseOffer>>> call() {
    return _repository.getPendingOffers();
  }
}

// --- GetOfferHistoryUseCase ---
class GetOfferHistoryUseCase {
  final OffersRepository _repository;

  GetOfferHistoryUseCase(this._repository);

  Future<Result<List<CaseOffer>>> call(GetOfferHistoryParams params) {
    return _repository.getOfferHistory(status: params.status);
  }
}

class GetOfferHistoryParams {
  final String? status;
  GetOfferHistoryParams({this.status});
}

// --- GetOfferStatsUseCase ---
class GetOfferStatsUseCase {
  final OffersRepository _repository;

  GetOfferStatsUseCase(this._repository);

  Future<Result<OfferStats>> call() {
    return _repository.getOfferStats();
  }
}

// --- AcceptOfferUseCase ---
class AcceptOfferUseCase {
  final OffersRepository _repository;

  AcceptOfferUseCase(this._repository);

  Future<Result<void>> call(AcceptOfferParams params) {
    return _repository.acceptOffer(params.offerId, notes: params.notes);
  }
}

class AcceptOfferParams {
  final String offerId;
  final String? notes;
  AcceptOfferParams({required this.offerId, this.notes});
}

// --- RejectOfferUseCase ---
class RejectOfferUseCase {
  final OffersRepository _repository;

  RejectOfferUseCase(this._repository);

  Future<Result<void>> call(RejectOfferParams params) {
    return _repository.rejectOffer(params.offerId, params.reason);
  }
}

class RejectOfferParams {
  final String offerId;
  final String reason;
  RejectOfferParams({required this.offerId, required this.reason});
} 