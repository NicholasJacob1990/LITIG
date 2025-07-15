import 'package:equatable/equatable.dart';

abstract class OffersEvent extends Equatable {
  const OffersEvent();

  @override
  List<Object> get props => [];
}

class LoadOffersData extends OffersEvent {}

class AcceptOffer extends OffersEvent {
  final String offerId;
  final String? notes;

  const AcceptOffer({required this.offerId, this.notes});

  @override
  List<Object> get props => [offerId, notes ?? ''];
}

class RejectOffer extends OffersEvent {
  final String offerId;
  final String reason;

  const RejectOffer({required this.offerId, required this.reason});

    @override
  List<Object> get props => [offerId, reason];
} 