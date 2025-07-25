import 'package:equatable/equatable.dart';

class PartnershipRecommendation extends Equatable {
  final String recommendedLawyerId;
  final String lawyerName;
  final String? firmName;
  final String? firmId;
  final double compatibilityScore;
  final List<String> potentialSynergies;
  final String partnershipReason;
  final String? lawyerSpecialty;
  final String? contactEmail;
  final String? contactPhone;
  final Map<String, dynamic>? additionalData;
  final DateTime createdAt;

  const PartnershipRecommendation({
    required this.recommendedLawyerId,
    required this.lawyerName,
    this.firmName,
    this.firmId,
    required this.compatibilityScore,
    required this.potentialSynergies,
    required this.partnershipReason,
    this.lawyerSpecialty,
    this.contactEmail,
    this.contactPhone,
    this.additionalData,
    required this.createdAt,
  });

  factory PartnershipRecommendation.fromJson(Map<String, dynamic> json) {
    return PartnershipRecommendation(
      recommendedLawyerId: json['lawyer_id'] ?? json['recommended_lawyer_id'] ?? '',
      lawyerName: json['name'] ?? json['lawyer_name'] ?? '',
      firmName: json['firm_name'],
      firmId: json['firm_id'],
      compatibilityScore: (json['compatibility_score'] ?? json['confidence_score'] ?? 0.0).toDouble(),
      potentialSynergies: List<String>.from(json['potential_synergies'] ?? []),
      partnershipReason: json['partnership_reason'] ?? '',
      lawyerSpecialty: json['lawyer_specialty'] ?? json['cluster_expertise'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      additionalData: json['additional_data'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommended_lawyer_id': recommendedLawyerId,
      'lawyer_name': lawyerName,
      'firm_name': firmName,
      'firm_id': firmId,
      'compatibility_score': compatibilityScore,
      'potential_synergies': potentialSynergies,
      'partnership_reason': partnershipReason,
      'lawyer_specialty': lawyerSpecialty,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'additional_data': additionalData,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PartnershipRecommendation copyWith({
    String? recommendedLawyerId,
    String? lawyerName,
    String? firmName,
    String? firmId,
    double? compatibilityScore,
    List<String>? potentialSynergies,
    String? partnershipReason,
    String? lawyerSpecialty,
    String? contactEmail,
    String? contactPhone,
    Map<String, dynamic>? additionalData,
    DateTime? createdAt,
  }) {
    return PartnershipRecommendation(
      recommendedLawyerId: recommendedLawyerId ?? this.recommendedLawyerId,
      lawyerName: lawyerName ?? this.lawyerName,
      firmName: firmName ?? this.firmName,
      firmId: firmId ?? this.firmId,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      potentialSynergies: potentialSynergies ?? this.potentialSynergies,
      partnershipReason: partnershipReason ?? this.partnershipReason,
      lawyerSpecialty: lawyerSpecialty ?? this.lawyerSpecialty,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      additionalData: additionalData ?? this.additionalData,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        recommendedLawyerId,
        lawyerName,
        firmName,
        firmId,
        compatibilityScore,
        potentialSynergies,
        partnershipReason,
        lawyerSpecialty,
        contactEmail,
        contactPhone,
        additionalData,
        createdAt,
      ];
} 