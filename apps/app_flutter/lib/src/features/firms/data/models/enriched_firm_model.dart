import '../../domain/entities/enriched_firm.dart';
import '../../../lawyers/data/models/enriched_lawyer_model.dart';
import '../../../lawyers/data/models/data_source_info_model.dart';

class EnrichedFirmModel extends EnrichedFirm {
  const EnrichedFirmModel({
    required super.id,
    required super.name,
    required super.description,
    super.logoUrl,
    super.specializations,
    super.partners,
    super.associates,
    required super.totalLawyers,
    required super.partnersCount,
    required super.associatesCount,
    required super.specialistsCount,
    super.specialistsByArea,
    super.certifications,
    super.awards,
    super.location,
    super.contactInfo,
    required super.dataSources,
    required super.overallQualityScore,
    required super.completenessScore,
    required super.lastConsolidated,
    super.financialInfo,
    super.partnerships,
    required super.stats,
  });

  factory EnrichedFirmModel.fromJson(Map<String, dynamic> json) {
    return EnrichedFirmModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      logoUrl: json['logo_url'],
      specializations: List<String>.from(json['specializations'] ?? []),
      partners: (json['partners'] as List<dynamic>?)
              ?.map((p) => EnrichedLawyerModel.fromJson(p))
              .toList() ??
          [],
      associates: (json['associates'] as List<dynamic>?)
              ?.map((a) => EnrichedLawyerModel.fromJson(a))
              .toList() ??
          [],
      totalLawyers: json['total_lawyers'] ?? 0,
      partnersCount: json['partners_count'] ?? 0,
      associatesCount: json['associates_count'] ?? 0,
      specialistsCount: json['specialists_count'] ?? 0,
      specialistsByArea: Map<String, int>.from(json['specialists_by_area'] ?? {}),
      certifications: (json['certifications'] as List<dynamic>?)
              ?.map((c) => FirmCertificationModel.fromJson(c))
              .toList() ??
          [],
      awards: (json['awards'] as List<dynamic>?)
              ?.map((a) => FirmAwardModel.fromJson(a))
              .toList() ??
          [],
      location: json['location'] != null 
          ? FirmLocationModel.fromJson(json['location']) 
          : null,
      contactInfo: json['contact_info'] != null 
          ? FirmContactInfoModel.fromJson(json['contact_info']) 
          : null,
      dataSources: (json['data_sources'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, DataSourceInfoModel.fromJson(value)))
              ?? {},
      overallQualityScore: (json['overall_quality_score'] ?? 0.0).toDouble(),
      completenessScore: (json['completeness_score'] ?? 0.0).toDouble(),
      lastConsolidated: DateTime.parse(json['last_consolidated'] ?? DateTime.now().toIso8601String()),
      financialInfo: json['financial_info'] != null 
          ? FirmFinancialInfoModel.fromJson(json['financial_info']) 
          : null,
      partnerships: (json['partnerships'] as List<dynamic>?)
              ?.map((p) => FirmPartnershipModel.fromJson(p))
              .toList() ??
          [],
      stats: FirmStatsModel.fromJson(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'specializations': specializations,
      'partners': partners.map((p) => (p as EnrichedLawyerModel).toJson()).toList(),
      'associates': associates.map((a) => (a as EnrichedLawyerModel).toJson()).toList(),
      'total_lawyers': totalLawyers,
      'partners_count': partnersCount,
      'associates_count': associatesCount,
      'specialists_count': specialistsCount,
      'specialists_by_area': specialistsByArea,
      'certifications': certifications.map((c) => (c as FirmCertificationModel).toJson()).toList(),
      'awards': awards.map((a) => (a as FirmAwardModel).toJson()).toList(),
      'location': (location as FirmLocationModel?)?.toJson(),
      'contact_info': (contactInfo as FirmContactInfoModel?)?.toJson(),
      'data_sources': dataSources.map((key, value) => MapEntry(key, (value as DataSourceInfoModel).toJson())),
      'overall_quality_score': overallQualityScore,
      'completeness_score': completenessScore,
      'last_consolidated': lastConsolidated.toIso8601String(),
      'financial_info': (financialInfo as FirmFinancialInfoModel?)?.toJson(),
      'partnerships': partnerships.map((p) => (p as FirmPartnershipModel).toJson()).toList(),
      'stats': (stats as FirmStatsModel).toJson(),
    };
  }
}

class FirmCertificationModel extends FirmCertification {
  const FirmCertificationModel({
    required super.name,
    required super.issuer,
    super.validUntil,
    super.certificateUrl,
    super.isActive,
  });

  factory FirmCertificationModel.fromJson(Map<String, dynamic> json) {
    return FirmCertificationModel(
      name: json['name'] ?? '',
      issuer: json['issuer'] ?? '',
      validUntil: json['valid_until'] != null ? DateTime.parse(json['valid_until']) : null,
      certificateUrl: json['certificate_url'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuer': issuer,
      'valid_until': validUntil?.toIso8601String(),
      'certificate_url': certificateUrl,
      'is_active': isActive,
    };
  }
}

class FirmAwardModel extends FirmAward {
  const FirmAwardModel({
    required super.name,
    required super.category,
    required super.dateReceived,
    super.issuer,
    super.description,
  });

  factory FirmAwardModel.fromJson(Map<String, dynamic> json) {
    return FirmAwardModel(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      dateReceived: DateTime.parse(json['date_received'] ?? DateTime.now().toIso8601String()),
      issuer: json['issuer'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'date_received': dateReceived.toIso8601String(),
      'issuer': issuer,
      'description': description,
    };
  }
}

class FirmLocationModel extends FirmLocation {
  const FirmLocationModel({
    required super.address,
    required super.city,
    required super.state,
    super.zipCode,
    required super.country,
    super.latitude,
    super.longitude,
    super.isMainOffice,
    super.nearbyLandmarks,
  });

  factory FirmLocationModel.fromJson(Map<String, dynamic> json) {
    return FirmLocationModel(
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zip_code'],
      country: json['country'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isMainOffice: json['is_main_office'] ?? true,
      nearbyLandmarks: List<String>.from(json['nearby_landmarks'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'is_main_office': isMainOffice,
      'nearby_landmarks': nearbyLandmarks,
    };
  }
}

class FirmContactInfoModel extends FirmContactInfo {
  const FirmContactInfoModel({
    super.phone,
    super.email,
    super.website,
    super.linkedinUrl,
    super.socialMediaUrls,
    super.whatsapp,
  });

  factory FirmContactInfoModel.fromJson(Map<String, dynamic> json) {
    return FirmContactInfoModel(
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      linkedinUrl: json['linkedin_url'],
      socialMediaUrls: List<String>.from(json['social_media_urls'] ?? []),
      whatsapp: json['whatsapp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
      'website': website,
      'linkedin_url': linkedinUrl,
      'social_media_urls': socialMediaUrls,
      'whatsapp': whatsapp,
    };
  }
}

class FirmFinancialInfoModel extends FirmFinancialInfo {
  const FirmFinancialInfoModel({
    super.revenueRange,
    super.foundedYear,
    super.legalStructure,
    super.isPubliclyTraded,
    super.stockSymbol,
    super.employeeCount,
    super.officeLocations,
  });

  factory FirmFinancialInfoModel.fromJson(Map<String, dynamic> json) {
    return FirmFinancialInfoModel(
      revenueRange: json['revenue_range'],
      foundedYear: json['founded_year'],
      legalStructure: json['legal_structure'],
      isPubliclyTraded: json['is_publicly_traded'] ?? false,
      stockSymbol: json['stock_symbol'],
      employeeCount: json['employee_count'],
      officeLocations: List<String>.from(json['office_locations'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'revenue_range': revenueRange,
      'founded_year': foundedYear,
      'legal_structure': legalStructure,
      'is_publicly_traded': isPubliclyTraded,
      'stock_symbol': stockSymbol,
      'employee_count': employeeCount,
      'office_locations': officeLocations,
    };
  }
}

class FirmPartnershipModel extends FirmPartnership {
  const FirmPartnershipModel({
    required super.partnerFirmId,
    required super.partnerFirmName,
    required super.partnershipType,
    super.startDate,
    super.endDate,
    super.isActive,
    super.description,
    super.collaborationAreas,
  });

  factory FirmPartnershipModel.fromJson(Map<String, dynamic> json) {
    return FirmPartnershipModel(
      partnerFirmId: json['partner_firm_id'] ?? '',
      partnerFirmName: json['partner_firm_name'] ?? '',
      partnershipType: json['partnership_type'] ?? '',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
      description: json['description'],
      collaborationAreas: List<String>.from(json['collaboration_areas'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partner_firm_id': partnerFirmId,
      'partner_firm_name': partnerFirmName,
      'partnership_type': partnershipType,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'description': description,
      'collaboration_areas': collaborationAreas,
    };
  }
}

class FirmStatsModel extends FirmStats {
  const FirmStatsModel({
    required super.totalCases,
    required super.activeCases,
    required super.wonCases,
    required super.successRate,
    required super.averageRating,
    required super.totalReviews,
    required super.averageResponseTime,
    required super.casesThisYear,
  });

  factory FirmStatsModel.fromJson(Map<String, dynamic> json) {
    return FirmStatsModel(
      totalCases: json['total_cases'] ?? 0,
      activeCases: json['active_cases'] ?? 0,
      wonCases: json['won_cases'] ?? 0,
      successRate: (json['success_rate'] ?? 0.0).toDouble(),
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      averageResponseTime: (json['average_response_time'] ?? 0.0).toDouble(),
      casesThisYear: json['cases_this_year'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_cases': totalCases,
      'active_cases': activeCases,
      'won_cases': wonCases,
      'success_rate': successRate,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'average_response_time': averageResponseTime,
      'cases_this_year': casesThisYear,
    };
  }
} 
import '../../../lawyers/data/models/enriched_lawyer_model.dart';
import '../../../lawyers/data/models/data_source_info_model.dart';

class EnrichedFirmModel extends EnrichedFirm {
  const EnrichedFirmModel({
    required super.id,
    required super.name,
    required super.description,
    super.logoUrl,
    super.specializations,
    super.partners,
    super.associates,
    required super.totalLawyers,
    required super.partnersCount,
    required super.associatesCount,
    required super.specialistsCount,
    super.specialistsByArea,
    super.certifications,
    super.awards,
    super.location,
    super.contactInfo,
    required super.dataSources,
    required super.overallQualityScore,
    required super.completenessScore,
    required super.lastConsolidated,
    super.financialInfo,
    super.partnerships,
    required super.stats,
  });

  factory EnrichedFirmModel.fromJson(Map<String, dynamic> json) {
    return EnrichedFirmModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      logoUrl: json['logo_url'],
      specializations: List<String>.from(json['specializations'] ?? []),
      partners: (json['partners'] as List<dynamic>?)
              ?.map((p) => EnrichedLawyerModel.fromJson(p))
              .toList() ??
          [],
      associates: (json['associates'] as List<dynamic>?)
              ?.map((a) => EnrichedLawyerModel.fromJson(a))
              .toList() ??
          [],
      totalLawyers: json['total_lawyers'] ?? 0,
      partnersCount: json['partners_count'] ?? 0,
      associatesCount: json['associates_count'] ?? 0,
      specialistsCount: json['specialists_count'] ?? 0,
      specialistsByArea: Map<String, int>.from(json['specialists_by_area'] ?? {}),
      certifications: (json['certifications'] as List<dynamic>?)
              ?.map((c) => FirmCertificationModel.fromJson(c))
              .toList() ??
          [],
      awards: (json['awards'] as List<dynamic>?)
              ?.map((a) => FirmAwardModel.fromJson(a))
              .toList() ??
          [],
      location: json['location'] != null 
          ? FirmLocationModel.fromJson(json['location']) 
          : null,
      contactInfo: json['contact_info'] != null 
          ? FirmContactInfoModel.fromJson(json['contact_info']) 
          : null,
      dataSources: (json['data_sources'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, DataSourceInfoModel.fromJson(value)))
              ?? {},
      overallQualityScore: (json['overall_quality_score'] ?? 0.0).toDouble(),
      completenessScore: (json['completeness_score'] ?? 0.0).toDouble(),
      lastConsolidated: DateTime.parse(json['last_consolidated'] ?? DateTime.now().toIso8601String()),
      financialInfo: json['financial_info'] != null 
          ? FirmFinancialInfoModel.fromJson(json['financial_info']) 
          : null,
      partnerships: (json['partnerships'] as List<dynamic>?)
              ?.map((p) => FirmPartnershipModel.fromJson(p))
              .toList() ??
          [],
      stats: FirmStatsModel.fromJson(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'specializations': specializations,
      'partners': partners.map((p) => (p as EnrichedLawyerModel).toJson()).toList(),
      'associates': associates.map((a) => (a as EnrichedLawyerModel).toJson()).toList(),
      'total_lawyers': totalLawyers,
      'partners_count': partnersCount,
      'associates_count': associatesCount,
      'specialists_count': specialistsCount,
      'specialists_by_area': specialistsByArea,
      'certifications': certifications.map((c) => (c as FirmCertificationModel).toJson()).toList(),
      'awards': awards.map((a) => (a as FirmAwardModel).toJson()).toList(),
      'location': (location as FirmLocationModel?)?.toJson(),
      'contact_info': (contactInfo as FirmContactInfoModel?)?.toJson(),
      'data_sources': dataSources.map((key, value) => MapEntry(key, (value as DataSourceInfoModel).toJson())),
      'overall_quality_score': overallQualityScore,
      'completeness_score': completenessScore,
      'last_consolidated': lastConsolidated.toIso8601String(),
      'financial_info': (financialInfo as FirmFinancialInfoModel?)?.toJson(),
      'partnerships': partnerships.map((p) => (p as FirmPartnershipModel).toJson()).toList(),
      'stats': (stats as FirmStatsModel).toJson(),
    };
  }
}

class FirmCertificationModel extends FirmCertification {
  const FirmCertificationModel({
    required super.name,
    required super.issuer,
    super.validUntil,
    super.certificateUrl,
    super.isActive,
  });

  factory FirmCertificationModel.fromJson(Map<String, dynamic> json) {
    return FirmCertificationModel(
      name: json['name'] ?? '',
      issuer: json['issuer'] ?? '',
      validUntil: json['valid_until'] != null ? DateTime.parse(json['valid_until']) : null,
      certificateUrl: json['certificate_url'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuer': issuer,
      'valid_until': validUntil?.toIso8601String(),
      'certificate_url': certificateUrl,
      'is_active': isActive,
    };
  }
}

class FirmAwardModel extends FirmAward {
  const FirmAwardModel({
    required super.name,
    required super.category,
    required super.dateReceived,
    super.issuer,
    super.description,
  });

  factory FirmAwardModel.fromJson(Map<String, dynamic> json) {
    return FirmAwardModel(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      dateReceived: DateTime.parse(json['date_received'] ?? DateTime.now().toIso8601String()),
      issuer: json['issuer'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'date_received': dateReceived.toIso8601String(),
      'issuer': issuer,
      'description': description,
    };
  }
}

class FirmLocationModel extends FirmLocation {
  const FirmLocationModel({
    required super.address,
    required super.city,
    required super.state,
    super.zipCode,
    required super.country,
    super.latitude,
    super.longitude,
    super.isMainOffice,
    super.nearbyLandmarks,
  });

  factory FirmLocationModel.fromJson(Map<String, dynamic> json) {
    return FirmLocationModel(
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zip_code'],
      country: json['country'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isMainOffice: json['is_main_office'] ?? true,
      nearbyLandmarks: List<String>.from(json['nearby_landmarks'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'is_main_office': isMainOffice,
      'nearby_landmarks': nearbyLandmarks,
    };
  }
}

class FirmContactInfoModel extends FirmContactInfo {
  const FirmContactInfoModel({
    super.phone,
    super.email,
    super.website,
    super.linkedinUrl,
    super.socialMediaUrls,
    super.whatsapp,
  });

  factory FirmContactInfoModel.fromJson(Map<String, dynamic> json) {
    return FirmContactInfoModel(
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      linkedinUrl: json['linkedin_url'],
      socialMediaUrls: List<String>.from(json['social_media_urls'] ?? []),
      whatsapp: json['whatsapp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
      'website': website,
      'linkedin_url': linkedinUrl,
      'social_media_urls': socialMediaUrls,
      'whatsapp': whatsapp,
    };
  }
}

class FirmFinancialInfoModel extends FirmFinancialInfo {
  const FirmFinancialInfoModel({
    super.revenueRange,
    super.foundedYear,
    super.legalStructure,
    super.isPubliclyTraded,
    super.stockSymbol,
    super.employeeCount,
    super.officeLocations,
  });

  factory FirmFinancialInfoModel.fromJson(Map<String, dynamic> json) {
    return FirmFinancialInfoModel(
      revenueRange: json['revenue_range'],
      foundedYear: json['founded_year'],
      legalStructure: json['legal_structure'],
      isPubliclyTraded: json['is_publicly_traded'] ?? false,
      stockSymbol: json['stock_symbol'],
      employeeCount: json['employee_count'],
      officeLocations: List<String>.from(json['office_locations'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'revenue_range': revenueRange,
      'founded_year': foundedYear,
      'legal_structure': legalStructure,
      'is_publicly_traded': isPubliclyTraded,
      'stock_symbol': stockSymbol,
      'employee_count': employeeCount,
      'office_locations': officeLocations,
    };
  }
}

class FirmPartnershipModel extends FirmPartnership {
  const FirmPartnershipModel({
    required super.partnerFirmId,
    required super.partnerFirmName,
    required super.partnershipType,
    super.startDate,
    super.endDate,
    super.isActive,
    super.description,
    super.collaborationAreas,
  });

  factory FirmPartnershipModel.fromJson(Map<String, dynamic> json) {
    return FirmPartnershipModel(
      partnerFirmId: json['partner_firm_id'] ?? '',
      partnerFirmName: json['partner_firm_name'] ?? '',
      partnershipType: json['partnership_type'] ?? '',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
      description: json['description'],
      collaborationAreas: List<String>.from(json['collaboration_areas'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partner_firm_id': partnerFirmId,
      'partner_firm_name': partnerFirmName,
      'partnership_type': partnershipType,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'description': description,
      'collaboration_areas': collaborationAreas,
    };
  }
}

class FirmStatsModel extends FirmStats {
  const FirmStatsModel({
    required super.totalCases,
    required super.activeCases,
    required super.wonCases,
    required super.successRate,
    required super.averageRating,
    required super.totalReviews,
    required super.averageResponseTime,
    required super.casesThisYear,
  });

  factory FirmStatsModel.fromJson(Map<String, dynamic> json) {
    return FirmStatsModel(
      totalCases: json['total_cases'] ?? 0,
      activeCases: json['active_cases'] ?? 0,
      wonCases: json['won_cases'] ?? 0,
      successRate: (json['success_rate'] ?? 0.0).toDouble(),
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      averageResponseTime: (json['average_response_time'] ?? 0.0).toDouble(),
      casesThisYear: json['cases_this_year'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_cases': totalCases,
      'active_cases': activeCases,
      'won_cases': wonCases,
      'success_rate': successRate,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'average_response_time': averageResponseTime,
      'cases_this_year': casesThisYear,
    };
  }
} 