import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/offers/domain/entities/case_offer.dart';

abstract class OffersState extends Equatable {
  const OffersState();

  @override
  List<Object> get props => [];
}

class OffersInitial extends OffersState {}

class OffersLoading extends OffersState {}

class OffersLoaded extends OffersState {
  final List<CaseOffer> pendingOffers;
  final List<CaseOffer> historyOffers;
  final OfferStats? stats;

  const OffersLoaded({
    this.pendingOffers = const [],
    this.historyOffers = const [],
    this.stats,
  });

  @override
  List<Object> get props => [pendingOffers, historyOffers, stats ?? ''];
}

class OfferActionSuccess extends OffersState {
  final String message;
  const OfferActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class OfferActionFailure extends OffersState {
    final String error;
  const OfferActionFailure(this.error);

  @override
  List<Object> get props => [error];
}

class OffersError extends OffersState {
  final String message;

  const OffersError(this.message);

  @override
  List<Object> get props => [message];
} 