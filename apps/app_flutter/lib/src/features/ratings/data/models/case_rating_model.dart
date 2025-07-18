import '../../domain/entities/case_rating.dart';

/// Modelo de dados para avaliação de caso
class CaseRatingModel extends CaseRating {
  const CaseRatingModel({
    super.id,
    required super.caseId,
    required super.lawyerId,
    required super.clientId,
    required super.raterType,
    required super.overallRating,
    required super.communicationRating,
    required super.expertiseRating,
    required super.responsivenessRating,
    required super.valueRating,
    super.comment,
    super.tags = const [],
    super.createdAt,
    super.isVerified = true,
    super.isPublic = true,
    super.helpfulVotes = 0,
  });

  /// Converte de JSON para modelo
  factory CaseRatingModel.fromJson(Map<String, dynamic> json) {
    return CaseRatingModel(
      id: json['id'],
      caseId: json['case_id'],
      lawyerId: json['lawyer_id'],
      clientId: json['client_id'],
      raterType: json['rater_type'],
      overallRating: (json['overall_rating'] as num).toDouble(),
      communicationRating: (json['communication_rating'] as num).toDouble(),
      expertiseRating: (json['expertise_rating'] as num).toDouble(),
      responsivenessRating: (json['responsiveness_rating'] as num).toDouble(),
      valueRating: (json['value_rating'] as num).toDouble(),
      comment: json['comment'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      isVerified: json['is_verified'] ?? true,
      isPublic: json['is_public'] ?? true,
      helpfulVotes: json['helpful_votes'] ?? 0,
    );
  }

  /// Converte modelo para JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_id': caseId,
      'lawyer_id': lawyerId,
      'client_id': clientId,
      'rater_type': raterType,
      'overall_rating': overallRating,
      'communication_rating': communicationRating,
      'expertise_rating': expertiseRating,
      'responsiveness_rating': responsivenessRating,
      'value_rating': valueRating,
      'comment': comment,
      'tags': tags,
      'created_at': createdAt?.toIso8601String(),
      'is_verified': isVerified,
      'is_public': isPublic,
      'helpful_votes': helpfulVotes,
    };
  }

  /// Converte de entidade para modelo
  factory CaseRatingModel.fromEntity(CaseRating entity) {
    return CaseRatingModel(
      id: entity.id,
      caseId: entity.caseId,
      lawyerId: entity.lawyerId,
      clientId: entity.clientId,
      raterType: entity.raterType,
      overallRating: entity.overallRating,
      communicationRating: entity.communicationRating,
      expertiseRating: entity.expertiseRating,
      responsivenessRating: entity.responsivenessRating,
      valueRating: entity.valueRating,
      comment: entity.comment,
      tags: entity.tags,
      createdAt: entity.createdAt,
      isVerified: entity.isVerified,
      isPublic: entity.isPublic,
      helpfulVotes: entity.helpfulVotes,
    );
  }

  /// Converte modelo para entidade
  CaseRating toEntity() {
    return CaseRating(
      id: id,
      caseId: caseId,
      lawyerId: lawyerId,
      clientId: clientId,
      raterType: raterType,
      overallRating: overallRating,
      communicationRating: communicationRating,
      expertiseRating: expertiseRating,
      responsivenessRating: responsivenessRating,
      valueRating: valueRating,
      comment: comment,
      tags: tags,
      createdAt: createdAt,
      isVerified: isVerified,
      isPublic: isPublic,
      helpfulVotes: helpfulVotes,
    );
  }

  /// Cria uma cópia do modelo com campos modificados
  CaseRatingModel copyWith({
    String? id,
    String? caseId,
    String? lawyerId,
    String? clientId,
    String? raterType,
    double? overallRating,
    double? communicationRating,
    double? expertiseRating,
    double? responsivenessRating,
    double? valueRating,
    String? comment,
    List<String>? tags,
    DateTime? createdAt,
    bool? isVerified,
    bool? isPublic,
    int? helpfulVotes,
  }) {
    return CaseRatingModel(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      lawyerId: lawyerId ?? this.lawyerId,
      clientId: clientId ?? this.clientId,
      raterType: raterType ?? this.raterType,
      overallRating: overallRating ?? this.overallRating,
      communicationRating: communicationRating ?? this.communicationRating,
      expertiseRating: expertiseRating ?? this.expertiseRating,
      responsivenessRating: responsivenessRating ?? this.responsivenessRating,
      valueRating: valueRating ?? this.valueRating,
      comment: comment ?? this.comment,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      isPublic: isPublic ?? this.isPublic,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
    );
  }
} 