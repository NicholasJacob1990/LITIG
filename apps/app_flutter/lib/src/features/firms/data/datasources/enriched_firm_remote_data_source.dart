import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/enriched_firm.dart';
import '../../domain/entities/case_info.dart';
import '../../domain/entities/partnership_info.dart';

abstract class EnrichedFirmRemoteDataSource {
  Future<EnrichedFirm> getEnrichedFirm(String firmId);
  Future<EnrichedFirm> refreshEnrichedFirm(String firmId);
  Future<FirmTeamData> getTeamData(String firmId);
  Future<FirmFinancialSummary> getFinancialData(String firmId);
  Future<List<CaseInfo>> getFirmCases(String firmId, {Map<String, dynamic>? filters});
  Future<List<PartnershipInfo>> getFirmPartnerships(String firmId, {Map<String, dynamic>? filters});
}

class EnrichedFirmRemoteDataSourceImpl implements EnrichedFirmRemoteDataSource {
  final http.Client client;
  final NetworkInfo networkInfo;
  final String baseUrl;

  EnrichedFirmRemoteDataSourceImpl({
    required this.client,
    required this.networkInfo,
    required this.baseUrl,
  });

  @override
  Future<EnrichedFirm> getEnrichedFirm(String firmId) async {
    if (!await networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/enriched-firms/firm/$firmId/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // TODO: Adicionar token de autenticação
          // 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return _parseEnrichedFirmFromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Escritório não encontrado');
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Acesso não autorizado');
      } else if (response.statusCode == 403) {
        throw AuthorizationException('Permissão negada');
      } else {
        throw ServerException('Erro no servidor: ${response.statusCode}');
      }
    } on http.ClientException {
      throw NetworkException('Erro de conexão');
    } on FormatException {
      throw ParsingException('Erro ao processar resposta do servidor');
    } catch (e) {
      if (e is ServerException || e is NetworkException || e is ParsingException) {
        rethrow;
      }
      throw ServerException('Erro inesperado: $e');
    }
  }

  @override
  Future<EnrichedFirm> refreshEnrichedFirm(String firmId) async {
    if (!await networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/enriched-firms/firm/$firmId/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // TODO: Adicionar token de autenticação
        },
      ).timeout(const Duration(seconds: 60)); // Refresh pode demorar mais

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return _parseEnrichedFirmFromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Escritório não encontrado');
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Acesso não autorizado');
      } else {
        throw ServerException('Erro ao atualizar dados: ${response.statusCode}');
      }
    } on http.ClientException {
      throw NetworkException('Erro de conexão');
    } on FormatException {
      throw ParsingException('Erro ao processar resposta do servidor');
    } catch (e) {
      if (e is ServerException || e is NetworkException || e is ParsingException) {
        rethrow;
      }
      throw ServerException('Erro inesperado: $e');
    }
  }

  @override
  Future<FirmTeamData> getTeamData(String firmId) async {
    if (!await networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/enriched-firms/firm/$firmId/team'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return _parseTeamDataFromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Dados da equipe não encontrados');
      } else {
        throw ServerException('Erro ao buscar dados da equipe: ${response.statusCode}');
      }
    } on http.ClientException {
      throw NetworkException('Erro de conexão');
    } on FormatException {
      throw ParsingException('Erro ao processar dados da equipe');
    } catch (e) {
      if (e is ServerException || e is NetworkException || e is ParsingException) {
        rethrow;
      }
      throw ServerException('Erro inesperado: $e');
    }
  }

  @override
  Future<FirmFinancialSummary> getFinancialData(String firmId) async {
    if (!await networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/enriched-firms/firm/$firmId/financial'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return _parseFinancialDataFromJson(jsonData);
      } else if (response.statusCode == 403) {
        throw AuthorizationException('Acesso negado aos dados financeiros');
      } else if (response.statusCode == 404) {
        throw NotFoundException('Dados financeiros não encontrados');
      } else {
        throw ServerException('Erro ao buscar dados financeiros: ${response.statusCode}');
      }
    } on http.ClientException {
      throw NetworkException('Erro de conexão');
    } on FormatException {
      throw ParsingException('Erro ao processar dados financeiros');
    } catch (e) {
      if (e is ServerException || e is NetworkException || e is ParsingException) {
        rethrow;
      }
      throw ServerException('Erro inesperado: $e');
    }
  }

  @override
  Future<List<CaseInfo>> getFirmCases(String firmId, {Map<String, dynamic>? filters}) async {
    if (!await networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    try {
      final queryParams = <String, String>{};
      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) queryParams[key] = value.toString();
        });
      }

      final uri = Uri.parse('$baseUrl/api/enriched-firms/firm/$firmId/cases')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return _parseCasesFromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Casos não encontrados');
      } else {
        throw ServerException('Erro ao buscar casos: ${response.statusCode}');
      }
    } on http.ClientException {
      throw NetworkException('Erro de conexão');
    } on FormatException {
      throw ParsingException('Erro ao processar dados dos casos');
    } catch (e) {
      if (e is ServerException || e is NetworkException || e is ParsingException) {
        rethrow;
      }
      throw ServerException('Erro inesperado: $e');
    }
  }

  @override
  Future<List<PartnershipInfo>> getFirmPartnerships(String firmId, {Map<String, dynamic>? filters}) async {
    if (!await networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    try {
      final queryParams = <String, String>{};
      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) queryParams[key] = value.toString();
        });
      }

      final uri = Uri.parse('$baseUrl/api/enriched-firms/firm/$firmId/partnerships')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return _parsePartnershipsFromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Parcerias não encontradas');
      } else {
        throw ServerException('Erro ao buscar parcerias: ${response.statusCode}');
      }
    } on http.ClientException {
      throw NetworkException('Erro de conexão');
    } on FormatException {
      throw ParsingException('Erro ao processar dados das parcerias');
    } catch (e) {
      if (e is ServerException || e is NetworkException || e is ParsingException) {
        rethrow;
      }
      throw ServerException('Erro inesperado: $e');
    }
  }

  // Métodos de parsing privados
  EnrichedFirm _parseEnrichedFirmFromJson(Map<String, dynamic> json) {
    try {
      return EnrichedFirm(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        specializations: List<String>.from(json['specializations'] ?? []),
        location: json['location'] as String? ?? '',
        foundedYear: json['founded_year'] as int? ?? 0,
        size: _parseFirmSize(json['size'] as String?),
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        caseSuccessRate: (json['case_success_rate'] as num?)?.toDouble() ?? 0.0,
        averageResponseTime: Duration(hours: json['average_response_time_hours'] as int? ?? 0),
        priceRange: _parsePriceRange(json['price_range'] as String?),
        languages: List<String>.from(json['languages'] ?? []),
        certifications: List<String>.from(json['certifications'] ?? []),
        contactInfo: _parseContactInfo(json['contact_info'] as Map<String, dynamic>?),
        teamData: _parseTeamDataFromJson(json['team_data'] as Map<String, dynamic>? ?? {}),
        transparencyReport: _parseTransparencyReport(json['transparency_report'] as Map<String, dynamic>?),
        financialSummary: _parseFinancialDataFromJson(json['financial_summary'] as Map<String, dynamic>? ?? {}),
        lastUpdated: DateTime.parse(json['last_updated'] as String? ?? DateTime.now().toIso8601String()),
      );
    } catch (e) {
      throw ParsingException('Erro ao processar dados do escritório: $e');
    }
  }

  FirmTeamData _parseTeamDataFromJson(Map<String, dynamic> json) {
    try {
      return FirmTeamData(
        totalLawyers: json['total_lawyers'] as int? ?? 0,
        partners: json['partners'] as int? ?? 0,
        associates: json['associates'] as int? ?? 0,
        juniors: json['juniors'] as int? ?? 0,
        specialistsByArea: Map<String, int>.from(json['specialists_by_area'] ?? {}),
        averageExperience: (json['average_experience'] as num?)?.toDouble() ?? 0.0,
        barAssociations: List<String>.from(json['bar_associations'] ?? []),
        certifications: List<String>.from(json['certifications'] ?? []),
      );
    } catch (e) {
      throw ParsingException('Erro ao processar dados da equipe: $e');
    }
  }

  FirmFinancialSummary _parseFinancialDataFromJson(Map<String, dynamic> json) {
    try {
      return FirmFinancialSummary(
        annualRevenue: json['annual_revenue'] as int? ?? 0,
        profitMargin: (json['profit_margin'] as num?)?.toDouble() ?? 0.0,
        ebitda: json['ebitda'] as int? ?? 0,
        averageTicket: json['average_ticket'] as int? ?? 0,
        revenueGrowth: (json['revenue_growth'] as num?)?.toDouble() ?? 0.0,
        clientRetentionRate: (json['client_retention_rate'] as num?)?.toDouble() ?? 0.0,
        revenueByArea: Map<String, int>.from(json['revenue_by_area'] ?? {}),
        yearOverYearMetrics: Map<String, int>.from(json['year_over_year_metrics'] ?? {}),
      );
    } catch (e) {
      throw ParsingException('Erro ao processar dados financeiros: $e');
    }
  }

  List<CaseInfo> _parseCasesFromJson(Map<String, dynamic> json) {
    try {
      final casesList = json['cases'] as List<dynamic>? ?? [];
      return casesList.map((caseJson) {
        return CaseInfo(
          id: caseJson['id'] as String,
          caseNumber: caseJson['case_number'] as String,
          title: caseJson['title'] as String,
          area: _parseCaseArea(caseJson['area'] as String?),
          status: _parseCaseStatus(caseJson['status'] as String?),
          startDate: DateTime.parse(caseJson['start_date'] as String),
          endDate: caseJson['end_date'] != null 
              ? DateTime.parse(caseJson['end_date'] as String) 
              : null,
          summary: caseJson['summary'] as String? ?? '',
          successProbability: (caseJson['success_probability'] as num?)?.toDouble() ?? 0.0,
          clientName: caseJson['client_name'] as String? ?? '',
          caseValue: (caseJson['case_value'] as num?)?.toDouble() ?? 0.0,
          tags: List<String>.from(caseJson['tags'] ?? []),
        );
      }).toList();
    } catch (e) {
      throw ParsingException('Erro ao processar dados dos casos: $e');
    }
  }

  List<PartnershipInfo> _parsePartnershipsFromJson(Map<String, dynamic> json) {
    try {
      final partnershipsList = json['partnerships'] as List<dynamic>? ?? [];
      return partnershipsList.map((partnershipJson) {
        return PartnershipInfo(
          id: partnershipJson['id'] as String,
          partnerName: partnershipJson['partner_name'] as String,
          partnerLogo: partnershipJson['partner_logo'] as String? ?? '',
          type: _parsePartnershipType(partnershipJson['type'] as String?),
          status: _parsePartnershipStatus(partnershipJson['status'] as String?),
          startDate: DateTime.parse(partnershipJson['start_date'] as String),
          endDate: partnershipJson['end_date'] != null 
              ? DateTime.parse(partnershipJson['end_date'] as String) 
              : null,
          description: partnershipJson['description'] as String? ?? '',
          benefits: List<String>.from(partnershipJson['benefits'] ?? []),
          sharedAreas: List<String>.from(partnershipJson['shared_areas'] ?? []),
          contactPerson: partnershipJson['contact_person'] as String? ?? '',
          contactEmail: partnershipJson['contact_email'] as String? ?? '',
          collaborationScore: (partnershipJson['collaboration_score'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (e) {
      throw ParsingException('Erro ao processar dados das parcerias: $e');
    }
  }

  // Métodos auxiliares de parsing
  FirmSize _parseFirmSize(String? size) {
    switch (size?.toLowerCase()) {
      case 'small': return FirmSize.small;
      case 'medium': return FirmSize.medium;
      case 'large': return FirmSize.large;
      default: return FirmSize.medium;
    }
  }

  PriceRange _parsePriceRange(String? range) {
    switch (range?.toLowerCase()) {
      case 'economic': return PriceRange.economic;
      case 'standard': return PriceRange.standard;
      case 'premium': return PriceRange.premium;
      case 'luxury': return PriceRange.luxury;
      default: return PriceRange.standard;
    }
  }

  CaseArea _parseCaseArea(String? area) {
    switch (area?.toLowerCase()) {
      case 'civil': return CaseArea.civil;
      case 'criminal': return CaseArea.criminal;
      case 'corporate': return CaseArea.corporate;
      case 'labor': return CaseArea.labor;
      case 'tax': return CaseArea.tax;
      case 'family': return CaseArea.family;
      case 'intellectual': return CaseArea.intellectual;
      case 'environmental': return CaseArea.environmental;
      case 'constitutional': return CaseArea.constitutional;
      case 'administrative': return CaseArea.administrative;
      default: return CaseArea.civil;
    }
  }

  CaseStatus _parseCaseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active': return CaseStatus.active;
      case 'closed': return CaseStatus.closed;
      case 'pending': return CaseStatus.pending;
      case 'won': return CaseStatus.won;
      case 'lost': return CaseStatus.lost;
      default: return CaseStatus.active;
    }
  }

  PartnershipType _parsePartnershipType(String? type) {
    switch (type?.toLowerCase()) {
      case 'strategic': return PartnershipType.strategic;
      case 'commercial': return PartnershipType.commercial;
      case 'referral': return PartnershipType.referral;
      case 'international': return PartnershipType.international;
      case 'technology': return PartnershipType.technology;
      case 'academic': return PartnershipType.academic;
      default: return PartnershipType.commercial;
    }
  }

  PartnershipStatus _parsePartnershipStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active': return PartnershipStatus.active;
      case 'inactive': return PartnershipStatus.inactive;
      case 'pending': return PartnershipStatus.pending;
      case 'suspended': return PartnershipStatus.suspended;
      default: return PartnershipStatus.active;
    }
  }

  FirmContactInfo _parseContactInfo(Map<String, dynamic>? json) {
    if (json == null) {
      return const FirmContactInfo(
        email: '',
        phone: '',
        website: '',
        address: '',
      );
    }

    return FirmContactInfo(
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      website: json['website'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }

  FirmTransparencyReport _parseTransparencyReport(Map<String, dynamic>? json) {
    if (json == null) {
      return const FirmTransparencyReport(
        dataSources: [],
        dataQualityScore: 0.0,
        lastConsolidated: '',
        privacyPolicy: '',
      );
    }

    return FirmTransparencyReport(
      dataSources: (json['data_sources'] as List<dynamic>? ?? []).map((source) {
        return DataSourceInfo(
          sourceName: source['source_name'] as String? ?? '',
          lastUpdated: source['last_updated'] as String? ?? '',
          qualityScore: (source['quality_score'] as num?)?.toDouble() ?? 0.0,
          dataPoints: source['data_points'] as int? ?? 0,
          errors: List<String>.from(source['errors'] ?? []),
        );
      }).toList(),
      dataQualityScore: (json['data_quality_score'] as num?)?.toDouble() ?? 0.0,
      lastConsolidated: json['last_consolidated'] as String? ?? '',
      privacyPolicy: json['privacy_policy'] as String? ?? '',
    );
  }
} 