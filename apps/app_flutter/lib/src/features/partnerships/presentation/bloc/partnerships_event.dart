import 'package:equatable/equatable.dart';

abstract class PartnershipsEvent extends Equatable {
  const PartnershipsEvent();

  @override
  List<Object> get props => [];
}

class FetchPartnerships extends PartnershipsEvent {}

class LoadPartnerships extends PartnershipsEvent {}

class AcceptPartnership extends PartnershipsEvent {
  final String partnershipId;

  const AcceptPartnership({required this.partnershipId});

  @override
  List<Object> get props => [partnershipId];
}

class RejectPartnership extends PartnershipsEvent {
  final String partnershipId;
  final String reason;

  const RejectPartnership({required this.partnershipId, required this.reason});

  @override
  List<Object> get props => [partnershipId, reason];
} 