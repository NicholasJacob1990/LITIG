import 'package:equatable/equatable.dart';

/// Entidade que representa uma avaliação de caso
class CaseRating extends Equatable {
  final String? id;
  final String caseId;
  final String lawyerId;
  final String clientId;
  final String raterType; // 'client' ou 'lawyer'
  final double overallRating;
  final double communicationRating;
  final double expertiseRating;
  final double responsivenessRating;
  final double valueRating;
  final String? comment;
  final List<String> tags;
  final DateTime? createdAt;
  final bool isVerified;
  final bool isPublic;
  final int helpfulVotes;

  const CaseRating({
    this.id,
    required this.caseId,
    required this.lawyerId,
    required this.clientId,
    required this.raterType,
    required this.overallRating,
    required this.communicationRating,
    required this.expertiseRating,
    required this.responsivenessRating,
    required this.valueRating,
    this.comment,
    this.tags = const [],
    this.createdAt,
    this.isVerified = true,
    this.isPublic = true,
    this.helpfulVotes = 0,
  });

  /// Cria uma cópia da avaliação com campos modificados
  CaseRating copyWith({
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
    return CaseRating(
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

  /// Converte de JSON para entidade
  factory CaseRating.fromJson(Map<String, dynamic> json) {
    return CaseRating(
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

  /// Converte entidade para JSON
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

  /// Calcula a média de todas as avaliações detalhadas
  double get averageDetailedRating {
    return (communicationRating + expertiseRating + responsivenessRating + valueRating) / 4;
  }

  /// Retorna true se a avaliação foi feita por um cliente
  bool get isClientRating => raterType == 'client';

  /// Retorna true se a avaliação foi feita por um advogado
  bool get isLawyerRating => raterType == 'lawyer';

  /// Formata a data de criação para exibição
  String get formattedDate {
    if (createdAt == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(createdAt!);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ano${difference.inDays > 730 ? 's' : ''} atrás';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} mês${difference.inDays > 60 ? 'es' : ''} atrás';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} dia${difference.inDays > 1 ? 's' : ''} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''} atrás';
    } else {
      return 'Agora mesmo';
    }
  }

  @override
  List<Object?> get props => [
        id,
        caseId,
        lawyerId,
        clientId,
        raterType,
        overallRating,
        communicationRating,
        expertiseRating,
        responsivenessRating,
        valueRating,
        comment,
        tags,
        createdAt,
        isVerified,
        isPublic,
        helpfulVotes,
      ];

  @override
  String toString() {
    return 'CaseRating{id: $id, caseId: $caseId, raterType: $raterType, overallRating: $overallRating}';
  }
} 