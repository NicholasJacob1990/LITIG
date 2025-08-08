import 'package:equatable/equatable.dart';

// Enums based on parsing methods in the data source
enum FirmSize { small, medium, large }
enum PriceRange { economic, standard, premium, luxury }

class EnrichedFirm extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<String> specializations;
  final FirmLocation? location;
  final int foundedYear;
  final FirmSize size;
  final double rating;
  final double caseSuccessRate;
  final Duration averageResponseTime;
  final PriceRange priceRange;
  final List<String> languages;
  final List<FirmCertification> certifications;
  final FirmContactInfo contactInfo;
  final FirmTeamData teamData;
  final FirmTransparencyReport transparencyReport;
  final FirmFinancialSummary financialSummary;
  final DateTime lastUpdated;

  const EnrichedFirm({
    required this.id,
    required this.name,
    required this.description,
    required this.specializations,
    this.location,
    required this.foundedYear,
    required this.size,
    required this.rating,
    required this.caseSuccessRate,
    required this.averageResponseTime,
    required this.priceRange,
    required this.languages,
    required this.certifications,
    required this.contactInfo,
    required this.teamData,
    required this.transparencyReport,
    required this.financialSummary,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        specializations,
        location,
        foundedYear,
        size,
        rating,
        caseSuccessRate,
        averageResponseTime,
        priceRange,
        languages,
        certifications,
        contactInfo,
        teamData,
        transparencyReport,
        financialSummary,
        lastUpdated,
      ];
}

class FirmLocation extends Equatable {
    final String address;
    final String city;
    final String state;
    final String country;
    final String postalCode;

    const FirmLocation({
        required this.address,
        required this.city,
        required this.state,
        required this.country,
        required this.postalCode,
    });

    @override
    List<Object?> get props => [address, city, state, country, postalCode];
}

class FirmCertification extends Equatable {
    final String name;
    final String authority;
    final int year;

    const FirmCertification({
        required this.name,
        required this.authority,
        required this.year,
    });

    @override
    List<Object?> get props => [name, authority, year];
}

class FirmContactInfo extends Equatable {
  final String email;
  final String phone;
  final String website;
  final FirmLocation address;

  const FirmContactInfo({
    required this.email,
    required this.phone,
    required this.website,
    required this.address,
  });

  @override
  List<Object?> get props => [email, phone, website, address];
}

class FirmTeamData extends Equatable {
  final int totalLawyers;
  final int partnersCount;
  final int associatesCount;
  final int specialistsCount;
  final Map<String, int> stats;
  final double overallQualityScore;
  final double completenessScore;
  final List<DataSourceInfo> dataSources;
  final DateTime lastConsolidated;

  const FirmTeamData({
    required this.totalLawyers,
    required this.partnersCount,
    required this.associatesCount,
    required this.specialistsCount,
    required this.stats,
    required this.overallQualityScore,
    required this.completenessScore,
    required this.dataSources,
    required this.lastConsolidated,
  });

  @override
  List<Object?> get props => [
        totalLawyers,
        partnersCount,
        associatesCount,
        specialistsCount,
        stats,
        overallQualityScore,
        completenessScore,
        dataSources,
        lastConsolidated,
      ];
}

class FirmFinancialSummary extends Equatable {
  final int annualRevenue;
  final double profitMargin;
  final int ebitda;
  final int averageTicket;
  final double revenueGrowth;
  final double clientRetentionRate;
  final Map<String, int> revenueByArea;
  final Map<String, int> yearOverYearMetrics;

  const FirmFinancialSummary({
    required this.annualRevenue,
    required this.profitMargin,
    required this.ebitda,
    required this.averageTicket,
    required this.revenueGrowth,
    required this.clientRetentionRate,
    required this.revenueByArea,
    required this.yearOverYearMetrics,
  });

  @override
  List<Object?> get props => [
        annualRevenue,
        profitMargin,
        ebitda,
        averageTicket,
        revenueGrowth,
        clientRetentionRate,
        revenueByArea,
        yearOverYearMetrics,
      ];
}

class FirmTransparencyReport extends Equatable {
  final List<DataSourceInfo> dataSources;
  final double dataQualityScore;
  final String lastConsolidated;
  final String privacyPolicy;

  const FirmTransparencyReport({
    required this.dataSources,
    required this.dataQualityScore,
    required this.lastConsolidated,
    required this.privacyPolicy,
  });

  @override
  List<Object?> get props => [
        dataSources,
        dataQualityScore,
        lastConsolidated,
        privacyPolicy,
      ];
}

class DataSourceInfo extends Equatable {
  final String sourceName;
  final String lastUpdated;
  final double qualityScore;
  final int dataPoints;
  final List<String> errors;

  const DataSourceInfo({
    required this.sourceName,
    required this.lastUpdated,
    required this.qualityScore,
    required this.dataPoints,
    required this.errors,
  });

  @override
  List<Object?> get props => [
        sourceName,
        lastUpdated,
        qualityScore,
        dataPoints,
        errors,
      ];
}