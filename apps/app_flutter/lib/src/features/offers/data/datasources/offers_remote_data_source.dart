import '../../domain/entities/case_offer.dart';

abstract class OffersRemoteDataSource {
  Future<List<CaseOffer>> getPendingOffers();
  
  Future<List<CaseOffer>> getOfferHistory({String? status});

  Future<OfferStats> getOfferStats();

  Future<void> acceptOffer(String offerId, {String? notes});

  Future<void> rejectOffer(String offerId, String reason);
} 