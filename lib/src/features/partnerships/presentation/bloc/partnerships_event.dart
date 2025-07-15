import '../../domain/entities/partnership.dart';

abstract class PartnershipsEvent {
  const PartnershipsEvent();
}

class FetchPartnerships extends PartnershipsEvent {
  const FetchPartnerships();
}

class CreatePartnership extends PartnershipsEvent {
  final String partnerId;
  final String? caseId;
  final PartnershipType type;
  final String honorarios;
  final String? proposalMessage;

  const CreatePartnership({
    required this.partnerId,
    this.caseId,
    required this.type,
    required this.honorarios,
    this.proposalMessage,
  });
}

class AcceptPartnership extends PartnershipsEvent {
  final String partnershipId;

  const AcceptPartnership(this.partnershipId);
}

class RejectPartnership extends PartnershipsEvent {
  final String partnershipId;

  const RejectPartnership(this.partnershipId);
}

class AcceptContract extends PartnershipsEvent {
  final String partnershipId;

  const AcceptContract(this.partnershipId);
}

class GenerateContract extends PartnershipsEvent {
  final String partnershipId;

  const GenerateContract(this.partnershipId);
} 