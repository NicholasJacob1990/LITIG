import 'package:meu_app/src/core/utils/result.dart';
import '../../domain/entities/case_offer.dart';

abstract class OffersRepository {
  Future<Result<List<CaseOffer>>> getPendingOffers();
  Future<Result<List<CaseOffer>>> getOfferHistory({String? status});
  Future<Result<OfferStats>> getOfferStats();
  Future<Result<void>> acceptOffer(String offerId, {String? notes});
  Future<Result<void>> rejectOffer(String offerId, String reason);
}