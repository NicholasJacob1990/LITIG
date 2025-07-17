import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/hiring_result.dart';

part 'hiring_result_model.g.dart';

@JsonSerializable()
class HiringResultModel extends HiringResult {
  const HiringResultModel({
    required super.proposalId,
    required super.contractId,
    required super.message,
    required super.createdAt,
  });

  factory HiringResultModel.fromJson(Map<String, dynamic> json) =>
      _$HiringResultModelFromJson(json);

  Map<String, dynamic> toJson() => _$HiringResultModelToJson(this);

  factory HiringResultModel.fromEntity(HiringResult entity) {
    return HiringResultModel(
      proposalId: entity.proposalId,
      contractId: entity.contractId,
      message: entity.message,
      createdAt: entity.createdAt,
    );
  }

  HiringResult toEntity() {
    return HiringResult(
      proposalId: proposalId,
      contractId: contractId,
      message: message,
      createdAt: createdAt,
    );
  }
}