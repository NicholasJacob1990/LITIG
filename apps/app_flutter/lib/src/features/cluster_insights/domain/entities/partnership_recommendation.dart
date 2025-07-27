import 'package:equatable/equatable.dart';

/// Status de uma recomendação de parceria (para modelo híbrido)
enum RecommendationStatus {
  /// Membro verificado da plataforma LITIG (padrão para compatibilidade)
  verifiedMember,
  /// Perfil público encontrado via busca externa  
  publicProfile,
  /// Convite enviado, aguardando aceite
  invited,
}

/// Dados do perfil externo (para perfis públicos)
class ExternalProfileData extends Equatable {
  /// URL do perfil principal (LinkedIn, etc.)
  final String? profileUrl;
  /// Nome completo verificado
  final String? fullName;
  /// Título profissional
  final String? headline;
  /// Resumo da experiência
  final String? summary;
  /// URL da foto de perfil
  final String? photoUrl;
  /// Cidade de atuação
  final String? city;
  /// Score de confiança (0.0 a 1.0)
  final double? confidenceScore;

  const ExternalProfileData({
    this.profileUrl,
    this.fullName,
    this.headline,
    this.summary,
    this.photoUrl,
    this.city,
    this.confidenceScore,
  });

  @override
  List<Object?> get props => [
    profileUrl, fullName, headline, summary, photoUrl, city, confidenceScore,
  ];

  Map<String, dynamic> toMap() {
    return {
      'profile_url': profileUrl,
      'full_name': fullName,
      'headline': headline,
      'summary': summary,
      'photo_url': photoUrl,
      'city': city,
      'confidence_score': confidenceScore,
    };
  }

  factory ExternalProfileData.fromMap(Map<String, dynamic> map) {
    return ExternalProfileData(
      profileUrl: map['profile_url'],
      fullName: map['full_name'],
      headline: map['headline'],
      summary: map['summary'],
      photoUrl: map['photo_url'],
      city: map['city'],
      confidenceScore: map['confidence_score']?.toDouble(),
    );
  }
}

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

  // 🆕 Novos campos para modelo híbrido (opcionais para compatibilidade)
  /// Status da recomendação (padrão: verifiedMember para compatibilidade)
  final RecommendationStatus status;
  /// ID do convite (se aplicável)
  final String? invitationId;
  /// Dados do perfil externo (apenas para status publicProfile)
  final ExternalProfileData? profileData;

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
    // 🆕 Novos campos opcionais (padrão para compatibilidade)
    this.status = RecommendationStatus.verifiedMember,
    this.invitationId,
    this.profileData,
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
      // 🆕 Novos campos híbridos
      status: _parseStatus(json['status']),
      invitationId: json['invitation_id'],
      profileData: json['profile_data'] != null
          ? ExternalProfileData.fromMap(json['profile_data'])
          : null,
    );
  }

  /// Parse do status a partir de string
  static RecommendationStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'verified':
        return RecommendationStatus.verifiedMember;
      case 'invited':
        return RecommendationStatus.invited;
      case 'public_profile':
        return RecommendationStatus.publicProfile;
      default:
        return RecommendationStatus.verifiedMember; // Padrão para compatibilidade
    }
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
      // 🆕 Novos campos híbridos
      'status': _statusToString(status),
      'invitation_id': invitationId,
      'profile_data': profileData?.toMap(),
    };
  }

  /// Converte status para string
  static String _statusToString(RecommendationStatus status) {
    switch (status) {
      case RecommendationStatus.verifiedMember:
        return 'verified';
      case RecommendationStatus.invited:
        return 'invited';
      case RecommendationStatus.publicProfile:
        return 'public_profile';
    }
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
    // 🆕 Novos campos híbridos
    RecommendationStatus? status,
    String? invitationId,
    ExternalProfileData? profileData,
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
      // 🆕 Novos campos híbridos
      status: status ?? this.status,
      invitationId: invitationId ?? this.invitationId,
      profileData: profileData ?? this.profileData,
    );
  }

  // 🆕 Getters convenientes para modelo híbrido
  /// Se é um membro verificado da plataforma
  bool get isVerifiedMember => status == RecommendationStatus.verifiedMember;
  
  /// Se é um perfil público externo
  bool get isPublicProfile => status == RecommendationStatus.publicProfile;
  
  /// Se já foi convidado
  bool get isInvited => status == RecommendationStatus.invited;

  /// URL do avatar (prioriza perfil externo se disponível)
  String get avatarUrl {
    if (profileData?.photoUrl != null) {
      return profileData!.photoUrl!;
    }
    // Fallback para placeholder
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(lawyerName)}&background=0D8ABC&color=fff';
  }

  /// Título/headline do advogado (prioriza perfil externo)
  String get displayHeadline {
    if (profileData?.headline != null) {
      return profileData!.headline!;
    }
    return lawyerSpecialty ?? 'Advogado';
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
        // 🆕 Novos campos híbridos
        status,
        invitationId,
        profileData,
      ];
} 