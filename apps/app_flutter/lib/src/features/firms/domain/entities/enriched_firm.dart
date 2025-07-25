import 'package:equatable/equatable.dart';
import '../../../lawyers/domain/entities/enriched_lawyer.dart';
import '../../../lawyers/domain/entities/data_source_info.dart';

class EnrichedFirm extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final List<String> specializations;
  final List<EnrichedLawyer> partners;
  final List<EnrichedLawyer> associates;
  final int totalLawyers;
  final int partnersCount;
  final int associatesCount;
  final int specialistsCount;
  final Map<String, int> specialistsByArea;
  final List<FirmCertification> certifications;
  final List<FirmAward> awards;
  final FirmLocation? location;
  final FirmContactInfo? contactInfo;
  final Map<String, DataSourceInfo> dataSources;
  final double overallQualityScore;
  final double completenessScore;
  final DateTime lastConsolidated;
  final FirmFinancialInfo? financialInfo;
  final List<FirmPartnership> partnerships;
  final FirmStats stats;

  const EnrichedFirm({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    this.specializations = const [],
    this.partners = const [],
    this.associates = const [],
    required this.totalLawyers,
    required this.partnersCount,
    required this.associatesCount,
    required this.specialistsCount,
    this.specialistsByArea = const {},
    this.certifications = const [],
    this.awards = const [],
    this.location,
    this.contactInfo,
    required this.dataSources,
    required this.overallQualityScore,
    required this.completenessScore,
    required this.lastConsolidated,
    this.financialInfo,
    this.partnerships = const [],
    required this.stats,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        logoUrl,
        specializations,
        partners,
        associates,
        totalLawyers,
        partnersCount,
        associatesCount,
        specialistsCount,
        specialistsByArea,
        certifications,
        awards,
        location,
        contactInfo,
        dataSources,
        overallQualityScore,
        completenessScore,
        lastConsolidated,
        financialInfo,
        partnerships,
        stats,
      ];
}

class FirmCertification extends Equatable {
  final String name;
  final String issuer;
  final DateTime? validUntil;
  final String? certificateUrl;
  final bool isActive;

  const FirmCertification({
    required this.name,
    required this.issuer,
    this.validUntil,
    this.certificateUrl,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [name, issuer, validUntil, certificateUrl, isActive];
}

class FirmAward extends Equatable {
  final String name;
  final String category;
  final DateTime dateReceived;
  final String? issuer;
  final String? description;

  const FirmAward({
    required this.name,
    required this.category,
    required this.dateReceived,
    this.issuer,
    this.description,
  });

  @override
  List<Object?> get props => [name, category, dateReceived, issuer, description];
}

class FirmLocation extends Equatable {
  final String address;
  final String city;
  final String state;
  final String? zipCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final bool isMainOffice;
  final List<String> nearbyLandmarks;

  const FirmLocation({
    required this.address,
    required this.city,
    required this.state,
    this.zipCode,
    required this.country,
    this.latitude,
    this.longitude,
    this.isMainOffice = true,
    this.nearbyLandmarks = const [],
  });

  @override
  List<Object?> get props => [
        address,
        city,
        state,
        zipCode,
        country,
        latitude,
        longitude,
        isMainOffice,
        nearbyLandmarks,
      ];
}

class FirmContactInfo extends Equatable {
  final String? phone;
  final String? email;
  final String? website;
  final String? linkedinUrl;
  final List<String> socialMediaUrls;
  final String? whatsapp;

  const FirmContactInfo({
    this.phone,
    this.email,
    this.website,
    this.linkedinUrl,
    this.socialMediaUrls = const [],
    this.whatsapp,
  });

  @override
  List<Object?> get props => [
        phone,
        email,
        website,
        linkedinUrl,
        socialMediaUrls,
        whatsapp,
      ];
}

class FirmFinancialInfo extends Equatable {
  final String? revenueRange;
  final int? foundedYear;
  final String? legalStructure;
  final bool isPubliclyTraded;
  final String? stockSymbol;
  final int? employeeCount;
  final List<String> officeLocations;

  const FirmFinancialInfo({
    this.revenueRange,
    this.foundedYear,
    this.legalStructure,
    this.isPubliclyTraded = false,
    this.stockSymbol,
    this.employeeCount,
    this.officeLocations = const [],
  });

  @override
  List<Object?> get props => [
        revenueRange,
        foundedYear,
        legalStructure,
        isPubliclyTraded,
        stockSymbol,
        employeeCount,
        officeLocations,
      ];
}

class FirmPartnership extends Equatable {
  final String partnerFirmId;
  final String partnerFirmName;
  final String partnershipType;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? description;
  final List<String> collaborationAreas;

  const FirmPartnership({
    required this.partnerFirmId,
    required this.partnerFirmName,
    required this.partnershipType,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.description,
    this.collaborationAreas = const [],
  });

  @override
  List<Object?> get props => [
        partnerFirmId,
        partnerFirmName,
        partnershipType,
        startDate,
        endDate,
        isActive,
        description,
        collaborationAreas,
      ];
}

class FirmStats extends Equatable {
  final int totalCases;
  final int activeCases;
  final int wonCases;
  final double successRate;
  final double averageRating;
  final int totalReviews;
  final double averageResponseTime;
  final int casesThisYear;

  const FirmStats({
    required this.totalCases,
    required this.activeCases,
    required this.wonCases,
    required this.successRate,
    required this.averageRating,
    required this.totalReviews,
    required this.averageResponseTime,
    required this.casesThisYear,
  });

  @override
  List<Object?> get props => [
        totalCases,
        activeCases,
        wonCases,
        successRate,
        averageRating,
        totalReviews,
        averageResponseTime,
        casesThisYear,
      ];
} 
import '../../../lawyers/domain/entities/enriched_lawyer.dart';
import '../../../lawyers/domain/entities/data_source_info.dart';

class EnrichedFirm extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final List<String> specializations;
  final List<EnrichedLawyer> partners;
  final List<EnrichedLawyer> associates;
  final int totalLawyers;
  final int partnersCount;
  final int associatesCount;
  final int specialistsCount;
  final Map<String, int> specialistsByArea;
  final List<FirmCertification> certifications;
  final List<FirmAward> awards;
  final FirmLocation? location;
  final FirmContactInfo? contactInfo;
  final Map<String, DataSourceInfo> dataSources;
  final double overallQualityScore;
  final double completenessScore;
  final DateTime lastConsolidated;
  final FirmFinancialInfo? financialInfo;
  final List<FirmPartnership> partnerships;
  final FirmStats stats;

  const EnrichedFirm({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    this.specializations = const [],
    this.partners = const [],
    this.associates = const [],
    required this.totalLawyers,
    required this.partnersCount,
    required this.associatesCount,
    required this.specialistsCount,
    this.specialistsByArea = const {},
    this.certifications = const [],
    this.awards = const [],
    this.location,
    this.contactInfo,
    required this.dataSources,
    required this.overallQualityScore,
    required this.completenessScore,
    required this.lastConsolidated,
    this.financialInfo,
    this.partnerships = const [],
    required this.stats,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        logoUrl,
        specializations,
        partners,
        associates,
        totalLawyers,
        partnersCount,
        associatesCount,
        specialistsCount,
        specialistsByArea,
        certifications,
        awards,
        location,
        contactInfo,
        dataSources,
        overallQualityScore,
        completenessScore,
        lastConsolidated,
        financialInfo,
        partnerships,
        stats,
      ];
}

class FirmCertification extends Equatable {
  final String name;
  final String issuer;
  final DateTime? validUntil;
  final String? certificateUrl;
  final bool isActive;

  const FirmCertification({
    required this.name,
    required this.issuer,
    this.validUntil,
    this.certificateUrl,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [name, issuer, validUntil, certificateUrl, isActive];
}

class FirmAward extends Equatable {
  final String name;
  final String category;
  final DateTime dateReceived;
  final String? issuer;
  final String? description;

  const FirmAward({
    required this.name,
    required this.category,
    required this.dateReceived,
    this.issuer,
    this.description,
  });

  @override
  List<Object?> get props => [name, category, dateReceived, issuer, description];
}

class FirmLocation extends Equatable {
  final String address;
  final String city;
  final String state;
  final String? zipCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final bool isMainOffice;
  final List<String> nearbyLandmarks;

  const FirmLocation({
    required this.address,
    required this.city,
    required this.state,
    this.zipCode,
    required this.country,
    this.latitude,
    this.longitude,
    this.isMainOffice = true,
    this.nearbyLandmarks = const [],
  });

  @override
  List<Object?> get props => [
        address,
        city,
        state,
        zipCode,
        country,
        latitude,
        longitude,
        isMainOffice,
        nearbyLandmarks,
      ];
}

class FirmContactInfo extends Equatable {
  final String? phone;
  final String? email;
  final String? website;
  final String? linkedinUrl;
  final List<String> socialMediaUrls;
  final String? whatsapp;

  const FirmContactInfo({
    this.phone,
    this.email,
    this.website,
    this.linkedinUrl,
    this.socialMediaUrls = const [],
    this.whatsapp,
  });

  @override
  List<Object?> get props => [
        phone,
        email,
        website,
        linkedinUrl,
        socialMediaUrls,
        whatsapp,
      ];
}

class FirmFinancialInfo extends Equatable {
  final String? revenueRange;
  final int? foundedYear;
  final String? legalStructure;
  final bool isPubliclyTraded;
  final String? stockSymbol;
  final int? employeeCount;
  final List<String> officeLocations;

  const FirmFinancialInfo({
    this.revenueRange,
    this.foundedYear,
    this.legalStructure,
    this.isPubliclyTraded = false,
    this.stockSymbol,
    this.employeeCount,
    this.officeLocations = const [],
  });

  @override
  List<Object?> get props => [
        revenueRange,
        foundedYear,
        legalStructure,
        isPubliclyTraded,
        stockSymbol,
        employeeCount,
        officeLocations,
      ];
}

class FirmPartnership extends Equatable {
  final String partnerFirmId;
  final String partnerFirmName;
  final String partnershipType;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? description;
  final List<String> collaborationAreas;

  const FirmPartnership({
    required this.partnerFirmId,
    required this.partnerFirmName,
    required this.partnershipType,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.description,
    this.collaborationAreas = const [],
  });

  @override
  List<Object?> get props => [
        partnerFirmId,
        partnerFirmName,
        partnershipType,
        startDate,
        endDate,
        isActive,
        description,
        collaborationAreas,
      ];
}

class FirmStats extends Equatable {
  final int totalCases;
  final int activeCases;
  final int wonCases;
  final double successRate;
  final double averageRating;
  final int totalReviews;
  final double averageResponseTime;
  final int casesThisYear;

  const FirmStats({
    required this.totalCases,
    required this.activeCases,
    required this.wonCases,
    required this.successRate,
    required this.averageRating,
    required this.totalReviews,
    required this.averageResponseTime,
    required this.casesThisYear,
  });

  @override
  List<Object?> get props => [
        totalCases,
        activeCases,
        wonCases,
        successRate,
        averageRating,
        totalReviews,
        averageResponseTime,
        casesThisYear,
      ];
} 