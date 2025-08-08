import '../../domain/entities/enriched_firm.dart';

/// Modelos alinhados com a entidade de domínio atual

class EnrichedFirmModel extends EnrichedFirm {
  EnrichedFirmModel({
    required String id,
    required String name,
    required String description,
    required List<String> specializations,
    FirmLocation? location,
    required int foundedYear,
    required FirmSize size,
    required double rating,
    required double caseSuccessRate,
    required Duration averageResponseTime,
    required PriceRange priceRange,
    required List<String> languages,
    required List<FirmCertification> certifications,
    required FirmContactInfo contactInfo,
    required FirmTeamData teamData,
    required FirmTransparencyReport transparencyReport,
    required FirmFinancialSummary financialSummary,
    required DateTime lastUpdated,
  }) : super(
          id: id,
          name: name,
          description: description,
          specializations: specializations,
          location: location,
          foundedYear: foundedYear,
          size: size,
          rating: rating,
          caseSuccessRate: caseSuccessRate,
          averageResponseTime: averageResponseTime,
          priceRange: priceRange,
          languages: languages,
          certifications: certifications,
          contactInfo: contactInfo,
          teamData: teamData,
          transparencyReport: transparencyReport,
          financialSummary: financialSummary,
          lastUpdated: lastUpdated,
        );

  factory EnrichedFirmModel.fromJson(Map<String, dynamic> json) {
    return EnrichedFirmModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      specializations: List<String>.from(json['specializations'] ?? []),
      location: json['location'] != null
          ? FirmLocationModel.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      foundedYear: json['founded_year'] as int? ?? 0,
      size: _parseFirmSize(json['size'] as String?),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      caseSuccessRate: (json['case_success_rate'] as num?)?.toDouble() ?? 0.0,
      averageResponseTime: Duration(hours: json['average_response_time_hours'] as int? ?? 0),
      priceRange: _parsePriceRange(json['price_range'] as String?),
      languages: List<String>.from(json['languages'] ?? []),
      certifications: (json['certifications'] as List<dynamic>? ?? [])
          .map((c) => FirmCertificationModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      contactInfo: FirmContactInfoModel.fromJson(
          json['contact_info'] as Map<String, dynamic>? ?? {}),
      teamData: FirmTeamDataModel.fromJson(
          json['team_data'] as Map<String, dynamic>? ?? {}),
      transparencyReport: FirmTransparencyReportModel.fromJson(
          json['transparency_report'] as Map<String, dynamic>? ?? {}),
      financialSummary: FirmFinancialSummaryModel.fromJson(
          json['financial_summary'] as Map<String, dynamic>? ?? {}),
      lastUpdated: DateTime.parse(
          json['last_updated'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  static FirmSize _parseFirmSize(String? size) {
    switch (size?.toLowerCase()) {
      case 'small':
        return FirmSize.small;
      case 'medium':
        return FirmSize.medium;
      case 'large':
        return FirmSize.large;
      default:
        return FirmSize.medium;
    }
  }

  static PriceRange _parsePriceRange(String? range) {
    switch (range?.toLowerCase()) {
      case 'economic':
        return PriceRange.economic;
      case 'standard':
        return PriceRange.standard;
      case 'premium':
        return PriceRange.premium;
      case 'luxury':
        return PriceRange.luxury;
      default:
        return PriceRange.standard;
    }
  }
}

class FirmLocationModel extends FirmLocation {
  const FirmLocationModel({
    required super.address,
    required super.city,
    required super.state,
    required super.country,
    required super.postalCode,
  });

  factory FirmLocationModel.fromJson(Map<String, dynamic> json) {
    return FirmLocationModel(
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? '',
      postalCode: json['postal_code'] as String? ?? '',
    );
  }
}

class FirmCertificationModel extends FirmCertification {
  const FirmCertificationModel({
    required super.name,
    required super.authority,
    required super.year,
  });

  factory FirmCertificationModel.fromJson(Map<String, dynamic> json) {
    return FirmCertificationModel(
      name: json['name'] as String? ?? '',
      authority: json['authority'] as String? ?? '',
      year: json['year'] as int? ?? 0,
    );
  }
}

class FirmContactInfoModel extends FirmContactInfo {
  const FirmContactInfoModel({
    required super.email,
    required super.phone,
    required super.website,
    required super.address,
  });

  factory FirmContactInfoModel.fromJson(Map<String, dynamic> json) {
    return FirmContactInfoModel(
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      website: json['website'] as String? ?? '',
      address: FirmLocationModel.fromJson(
          json['address'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class FirmTeamDataModel extends FirmTeamData {
  const FirmTeamDataModel({
    required super.totalLawyers,
    required super.partnersCount,
    required super.associatesCount,
    required super.specialistsCount,
    required super.stats,
    required super.overallQualityScore,
    required super.completenessScore,
    required super.dataSources,
    required super.lastConsolidated,
  });

  factory FirmTeamDataModel.fromJson(Map<String, dynamic> json) {
    return FirmTeamDataModel(
      totalLawyers: json['total_lawyers'] as int? ?? 0,
      partnersCount: json['partners'] as int? ?? 0,
      associatesCount: json['associates'] as int? ?? 0,
      specialistsCount: json['juniors'] as int? ?? 0,
      stats: Map<String, int>.from(json['specialists_by_area'] ?? {}),
      overallQualityScore: (json['average_experience'] as num?)?.toDouble() ?? 0.0,
      completenessScore: 0,
      dataSources: const [],
      lastConsolidated: DateTime.now(),
    );
  }
}

class FirmFinancialSummaryModel extends FirmFinancialSummary {
  const FirmFinancialSummaryModel({
    required super.annualRevenue,
    required super.profitMargin,
    required super.ebitda,
    required super.averageTicket,
    required super.revenueGrowth,
    required super.clientRetentionRate,
    required super.revenueByArea,
    required super.yearOverYearMetrics,
  });

  factory FirmFinancialSummaryModel.fromJson(Map<String, dynamic> json) {
    return FirmFinancialSummaryModel(
      annualRevenue: json['annual_revenue'] as int? ?? 0,
      profitMargin: (json['profit_margin'] as num?)?.toDouble() ?? 0.0,
      ebitda: json['ebitda'] as int? ?? 0,
      averageTicket: json['average_ticket'] as int? ?? 0,
      revenueGrowth: (json['revenue_growth'] as num?)?.toDouble() ?? 0.0,
      clientRetentionRate: (json['client_retention_rate'] as num?)?.toDouble() ?? 0.0,
      revenueByArea: Map<String, int>.from(json['revenue_by_area'] ?? {}),
      yearOverYearMetrics: Map<String, int>.from(json['year_over_year_metrics'] ?? {}),
    );
  }
}

class FirmTransparencyReportModel extends FirmTransparencyReport {
  const FirmTransparencyReportModel({
    required super.dataSources,
    required super.dataQualityScore,
    required super.lastConsolidated,
    required super.privacyPolicy,
  });

  factory FirmTransparencyReportModel.fromJson(Map<String, dynamic> json) {
    final sources = (json['data_sources'] as List<dynamic>? ?? [])
        .map((source) => DataSourceInfo(
              sourceName: source['source_name'] as String? ?? '',
              lastUpdated: source['last_updated'] as String? ?? '',
              qualityScore: (source['quality_score'] as num?)?.toDouble() ?? 0.0,
              dataPoints: source['data_points'] as int? ?? 0,
              errors: List<String>.from(source['errors'] ?? []),
            ))
        .toList();
    return FirmTransparencyReportModel(
      dataSources: sources,
      dataQualityScore: (json['data_quality_score'] as num?)?.toDouble() ?? 0.0,
      lastConsolidated: json['last_consolidated'] as String? ?? '',
      privacyPolicy: json['privacy_policy'] as String? ?? '',
    );
  }
}