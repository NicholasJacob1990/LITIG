import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/hiring_proposal.dart';

part 'hiring_proposal_model.g.dart';

@JsonSerializable()
class HiringProposalModel extends HiringProposal {
  const HiringProposalModel({
    required super.id,
    required super.lawyerId,
    required super.clientId,
    required super.caseId,
    required super.contractType,
    required super.budget,
    super.notes,
    required super.status,
    required super.createdAt,
    super.respondedAt,
    super.responseMessage,
    required super.expiresAt,
  });

  factory HiringProposalModel.fromJson(Map<String, dynamic> json) =>
      _$HiringProposalModelFromJson(json);

  Map<String, dynamic> toJson() => _$HiringProposalModelToJson(this);

  factory HiringProposalModel.fromEntity(HiringProposal entity) {
    return HiringProposalModel(
      id: entity.id,
      lawyerId: entity.lawyerId,
      clientId: entity.clientId,
      caseId: entity.caseId,
      contractType: entity.contractType,
      budget: entity.budget,
      notes: entity.notes,
      status: entity.status,
      createdAt: entity.createdAt,
      respondedAt: entity.respondedAt,
      responseMessage: entity.responseMessage,
      expiresAt: entity.expiresAt,
    );
  }

  HiringProposal toEntity() {
    return HiringProposal(
      id: id,
      lawyerId: lawyerId,
      clientId: clientId,
      caseId: caseId,
      contractType: contractType,
      budget: budget,
      notes: notes,
      status: status,
      createdAt: createdAt,
      respondedAt: respondedAt,
      responseMessage: responseMessage,
      expiresAt: expiresAt,
    );
  }
}