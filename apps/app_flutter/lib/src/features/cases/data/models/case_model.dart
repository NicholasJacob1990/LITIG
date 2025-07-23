import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/features/cases/domain/entities/lawyer_info.dart';

class CaseModel extends Case {
  const CaseModel({
    required super.id,
    required super.title,
    required super.status,
    super.lawyerName,
    super.lawyerId,
    required super.createdAt,
    super.lawyer,
    super.recommendedFirm,
    super.firmMatchScore,
    super.caseType,
    super.allocationType,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Caso sem título',
      status: json['status'] as String? ?? 'unknown',
      lawyerName: json['lawyer_name'] as String?,
      lawyerId: json['lawyer_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      lawyer: json['lawyer'] != null ? LawyerInfo.fromJson(json['lawyer']) : null,
      recommendedFirm: null, // TODO: Implementar fromJson na LawFirm quando necessário
      firmMatchScore: json['firm_match_score']?.toDouble(),
      caseType: json['case_type'] as String?,
      allocationType: json['allocation_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'lawyer_name': lawyerName,
      'lawyer_id': lawyerId,
      'created_at': createdAt.toIso8601String(),
    };
  }
} 