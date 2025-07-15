import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:meu_app/src/core/error/exceptions.dart';
import '../models/law_firm_model.dart';
import '../models/firm_kpi_model.dart';
import '../models/firm_stats_model.dart';

/// Interface para definir os métodos de acesso remoto aos dados de escritórios
abstract class FirmRemoteDataSource {
  /// Busca uma lista de escritórios com filtros opcionais
  Future<List<LawFirmModel>> getFirms({
    int limit = 50,
    int offset = 0,
    bool includeKpis = true,
    bool includeLawyersCount = true,
    double? minSuccessRate,
    int? minTeamSize,
  });

  /// Busca um escritório específico por ID
  Future<LawFirmModel?> getFirmById(
    String firmId, {
    bool includeKpis = true,
    bool includeLawyersCount = true,
  });

  /// Busca estatísticas agregadas dos escritórios
  Future<FirmStatsModel> getFirmStats();

  /// Busca KPIs específicos de um escritório
  Future<FirmKPIModel?> getFirmKpis(String firmId);

  /// Busca advogados de um escritório específico
  Future<Map<String, dynamic>> getFirmLawyers(
    String firmId, {
    int limit = 50,
    int offset = 0,
  });

  /// Cria um novo escritório (admin only)
  Future<LawFirmModel> createFirm(Map<String, dynamic> firmData);

  /// Atualiza dados de um escritório
  Future<LawFirmModel> updateFirm(String firmId, Map<String, dynamic> firmData);

  /// Atualiza ou cria KPIs de um escritório
  Future<FirmKPIModel> updateFirmKpis(String firmId, Map<String, dynamic> kpiData);

  /// Deleta um escritório (admin only)
  Future<bool> deleteFirm(String firmId);
}

/// Implementação concreta do FirmRemoteDataSource usando HTTP
class FirmRemoteDataSourceImpl implements FirmRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  FirmRemoteDataSourceImpl({
    required this.client,
    required this.baseUrl,
  });

  /// Headers padrão para requisições HTTP
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Headers com autenticação (será injetado via interceptor)
  Map<String, String> _headersWithAuth(String? token) => {
        ..._headers,
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// Helper para processar a resposta HTTP e tratar erros comuns
  dynamic _processResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return json.decode(response.body);
      case 204:
        return null;
      case 400:
        throw ServerException(message: 'Requisição inválida (400): ${response.body}');
      case 401:
        throw AuthenticationException();
      case 403:
        throw PermissionException();
      case 404:
        throw NotFoundException(resource: response.request?.url.path ?? 'desconhecido');
      case 500:
      default:
        throw ServerException(message: 'Erro do servidor (${response.statusCode}): ${response.body}');
    }
  }

  Future<http.Response> _makeRequest(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw ConnectionException(message: 'Tempo de requisição excedido. Verifique sua conexão.');
    } on http.ClientException {
      throw ConnectionException();
    }
  }

  @override
  Future<List<LawFirmModel>> getFirms({
    int limit = 50,
    int offset = 0,
    bool includeKpis = true,
    bool includeLawyersCount = true,
    double? minSuccessRate,
    int? minTeamSize,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      'include_kpis': includeKpis.toString(),
      'include_lawyers_count': includeLawyersCount.toString(),
      if (minSuccessRate != null) 'min_success_rate': minSuccessRate.toString(),
      if (minTeamSize != null) 'min_team_size': minTeamSize.toString(),
    };

    final uri = Uri.parse('$baseUrl/firms').replace(queryParameters: queryParams);
    
    final response = await _makeRequest(() => client.get(uri, headers: _headers));
    
    final jsonList = _processResponse(response) as List<dynamic>;
    return jsonList.map((json) => LawFirmModel.fromJson(json)).toList();
  }

  @override
  Future<LawFirmModel?> getFirmById(
    String firmId, {
    bool includeKpis = true,
    bool includeLawyersCount = true,
  }) async {
    final queryParams = <String, String>{
      'include_kpis': includeKpis.toString(),
      'include_lawyers_count': includeLawyersCount.toString(),
    };

    final uri = Uri.parse('$baseUrl/firms/$firmId').replace(queryParameters: queryParams);
    
    try {
      final response = await _makeRequest(() => client.get(uri, headers: _headers));
      final jsonData = _processResponse(response);
      return LawFirmModel.fromJson(jsonData);
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<FirmStatsModel> getFirmStats() async {
    final uri = Uri.parse('$baseUrl/firms/stats');
    final response = await _makeRequest(() => client.get(uri, headers: _headers));
    final jsonData = _processResponse(response);
    return FirmStatsModel.fromJson(jsonData);
  }

  @override
  Future<FirmKPIModel?> getFirmKpis(String firmId) async {
    final uri = Uri.parse('$baseUrl/firms/$firmId/kpis');
    
    try {
      final response = await _makeRequest(() => client.get(uri, headers: _headers));
      final jsonData = _processResponse(response);
      if (jsonData == null) return null;
      return FirmKPIModel.fromJson(jsonData);
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> getFirmLawyers(
    String firmId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    final uri = Uri.parse('$baseUrl/firms/$firmId/lawyers').replace(queryParameters: queryParams);
    final response = await _makeRequest(() => client.get(uri, headers: _headers));
    return _processResponse(response) as Map<String, dynamic>;
  }

  @override
  Future<LawFirmModel> createFirm(Map<String, dynamic> firmData) async {
    final uri = Uri.parse('$baseUrl/firms');
    final response = await _makeRequest(() => client.post(
      uri,
      headers: _headers,
      body: json.encode(firmData),
    ));
    final jsonData = _processResponse(response);
    return LawFirmModel.fromJson(jsonData);
  }

  @override
  Future<LawFirmModel> updateFirm(String firmId, Map<String, dynamic> firmData) async {
    final uri = Uri.parse('$baseUrl/firms/$firmId');
    final response = await _makeRequest(() => client.put(
      uri,
      headers: _headers,
      body: json.encode(firmData),
    ));
    final jsonData = _processResponse(response);
    return LawFirmModel.fromJson(jsonData);
  }

  @override
  Future<FirmKPIModel> updateFirmKpis(String firmId, Map<String, dynamic> kpiData) async {
    final uri = Uri.parse('$baseUrl/firms/$firmId/kpis');
    final response = await _makeRequest(() => client.put(
      uri,
      headers: _headers,
      body: json.encode(kpiData),
    ));
    final jsonData = _processResponse(response);
    return FirmKPIModel.fromJson(jsonData);
  }

  @override
  Future<bool> deleteFirm(String firmId) async {
    final uri = Uri.parse('$baseUrl/firms/$firmId');
    try {
      await _makeRequest(() => client.delete(uri, headers: _headers));
      return true;
    } on NotFoundException {
      return false;
    }
  }
} 