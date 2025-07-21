import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meu_app/src/core/utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:meu_app/src/features/search/domain/entities/search_params.dart';
import 'package:meu_app/src/features/lawyers/data/models/lawyer_model.dart';
import '../error/exceptions.dart';

class ApiService {
  static final Dio _dio = Dio();
  // TODO: Implement Supabase integration
  // static final SupabaseClient _supabase = Supabase.instance.client;

  static String get _baseUrl {
    // Debug logs para verificar a detecção de plataforma
    AppLogger.debug('ApiService: kIsWeb = $kIsWeb');
    
    // Detecção mais robusta de plataforma
    if (kIsWeb) {
      AppLogger.debug('ApiService: Detectado Flutter Web - usando localhost:8080');
      return 'http://localhost:8080/api';
    }
    
    // Para plataformas nativas, verificar o Platform
    try {
      if (Platform.isAndroid) {
        AppLogger.debug('ApiService: Detectado Android - usando 10.0.2.2:8080');
        return 'http://10.0.2.2:8080/api'; // Emulador Android
      } else if (Platform.isIOS) {
        AppLogger.debug('ApiService: Detectado iOS - usando 127.0.0.1:8080');
        return 'http://127.0.0.1:8080/api'; // Simulador iOS
      } else {
        AppLogger.debug('ApiService: Detectado Desktop - usando localhost:8080');
        return 'http://localhost:8080/api'; // Desktop
      }
    } catch (e) {
      // Se Platform não estiver disponível (ex: Web), usar localhost
      AppLogger.warning('ApiService: Platform não disponível, fallback para localhost:8080');
      return 'http://localhost:8080/api';
    }
  }

  static String get _baseUrlV2 {
    // Debug logs para verificar a detecção de plataforma
    AppLogger.debug('ApiService V2: kIsWeb = $kIsWeb');
    
    // Detecção mais robusta de plataforma
    if (kIsWeb) {
      AppLogger.debug('ApiService V2: Detectado Flutter Web - usando localhost:8080');
      return 'http://localhost:8080/api/v2';
    }
    
    // Para plataformas nativas, verificar o Platform
    try {
      if (Platform.isAndroid) {
        AppLogger.debug('ApiService V2: Detectado Android - usando 10.0.2.2:8080');
        return 'http://10.0.2.2:8080/api/v2'; // Emulador Android
      } else if (Platform.isIOS) {
        AppLogger.debug('ApiService V2: Detectado iOS - usando 127.0.0.1:8080');
        return 'http://127.0.0.1:8080/api/v2'; // Simulador iOS
      } else {
        AppLogger.debug('ApiService V2: Detectado Desktop - usando localhost:8080');
        return 'http://localhost:8080/api/v2'; // Desktop
      }
    } catch (e) {
      // Se Platform não estiver disponível (ex: Web), usar localhost
      AppLogger.warning('ApiService V2: Platform não disponível, fallback para localhost:8080');
      return 'http://localhost:8080/api/v2';
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    final session = Supabase.instance.client.auth.currentSession;
    final headers = {
      'Content-Type': 'application/json',
    };
    // Corrige a verificação de nulidade antes de acessar o token
    final accessToken = session?.accessToken;
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  // ===== CASOS =====
  static Future<Map<String, dynamic>> getMyCases() async {
    try {
      final headers = await _getHeaders();
      final url = '$_baseUrl/cases/my-cases';
      
      AppLogger.debug(' Tentando acessar URL: $url');
      AppLogger.debug(' Headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      AppLogger.debug(' Status code: ${response.statusCode}');
      AppLogger.debug(' Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao buscar casos: Status ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.debug(' Erro capturado: $e');
      AppLogger.debug(' Tipo do erro: ${e.runtimeType}');
      throw Exception('Erro ao buscar casos: $e');
    }
  }

  static Future<Map<String, dynamic>> getCaseDetail(String caseId) async {
    try {
      final headers = await _getHeaders();
      final url = '$_baseUrl/cases/$caseId';
      
      AppLogger.debug(' Tentando acessar URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      AppLogger.debug(' Status code: ${response.statusCode}');
      AppLogger.debug(' Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao buscar detalhes do caso: Status ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.debug(' Erro capturado: $e');
      throw Exception('Erro ao buscar detalhes do caso: $e');
    }
  }

  // ===== TRIAGEM =====
  static Future<Map<String, dynamic>> startTriageConversation() async {
    try {
      final response = await _dio.post('/triage/start');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Falha ao iniciar a conversa de triagem: Status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Falha ao iniciar a conversa de triagem: $e');
    }
  }

  static Future<Map<String, dynamic>> continueTriageConversation(String caseId, String message) async {
    try {
      final response = await _dio.post(
        '/triage/continue',
        data: {'case_id': caseId, 'message': message},
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Falha ao continuar a conversa de triagem: Status ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.debug(' Erro capturado em continueTriageConversation: $e');
      throw Exception('Falha ao continuar a conversa de triagem: $e');
    }
  }

  static Future<Map<String, dynamic>> startTriage(String description) async {
    final headers = await _getHeaders();
    // TODO: Adicionar coordenadas do GPS
    final body = jsonEncode({'texto_cliente': description, 'coords': [-23.5505, -46.6333]});
    final url = '$_baseUrl/triage';

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 202) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao iniciar a triagem: Status ${response.statusCode} - ${response.body}');
    }
  }

  static Future<String> submitTriageTranscript(String transcript) async {
    final headers = await _getHeaders();
    final body = jsonEncode({'texto_cliente': transcript});
    final url = '$_baseUrl/triage/full-flow';

    // Endpoint corrigido
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 202) {
       final data = jsonDecode(response.body);
       // A API pode retornar um task_id para polling, mas a doc sugere que o match é disparado.
       // Vamos assumir que o importante é o case_id que virá em algum momento ou será
       // parte da resposta do status da task. Por simplicidade, vamos retornar o corpo.
       // No fluxo real, isso precisaria de polling no status da task.
       return data['case_id'] ?? data['task_id'];
    } else {
      throw Exception('Falha ao iniciar a triagem');
    }
  }

  // ===== MATCHES =====
  static Future<Map<String, dynamic>> getMatches(
    String caseId, {
    String preset = 'balanced',
    int topN = 5,
    double? customLatitude,
    double? customLongitude,
    double? radiusKm,
  }) async {
    final headers = await _getHeaders();
    
    // Buscar dados do caso primeiro
    final caseData = await getCaseDetail(caseId);
    
    // Corpo da requisição seguindo o MatchRequestSchema
    final body = <String, dynamic>{
      'case': {
        'title': caseData['title'] ?? 'Caso sem título',
        'description': caseData['description'] ?? caseData['texto_cliente'] ?? 'Descrição não disponível',
        'area': caseData['area'] ?? 'Civil',
        'subarea': caseData['subarea'] ?? 'Geral',
        'urgency_hours': caseData['urgency_h'] ?? 48,
        'coordinates': {
          'latitude': caseData['coords']?[0] ?? -23.5505,
          'longitude': caseData['coords']?[1] ?? -46.6333,
        },
        'complexity': caseData['complexity'] ?? 'MEDIUM',
        'estimated_value': caseData['estimated_value'],
      },
      'top_n': topN,
      'preset': preset,
    };
    
    // Adicionar coordenadas customizadas se fornecidas
    if (customLatitude != null && customLongitude != null) {
      body['case']['coordinates'] = {
        'latitude': customLatitude,
        'longitude': customLongitude,
      };
    }
    
    // Adicionar raio se fornecido
    if (radiusKm != null) {
      body['radius_km'] = radiusKm;
    }

    final url = '$_baseUrl/match';
    
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao buscar matches: Status ${response.statusCode} - ${response.body}');
    }
  }

  // Novo método: buscar matches direto por case_id (mais eficiente)
  static Future<Map<String, dynamic>> getMatchesByCase(
    String caseId, {
    String preset = 'balanced',
    int topN = 5,
  }) async {
    final headers = await _getHeaders();
    
    final url = '$_baseUrl/cases/$caseId/matches';
    final queryParams = {
      'preset': preset,
      'top_n': topN.toString(),
    };
    
    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao buscar matches do caso: Status ${response.statusCode} - ${response.body}');
    }
  }

  // ===== MATCHES - MÉTODOS ESPECÍFICOS PARA BUSCA AVANÇADA =====
  
  /// Busca por correspondente em localização específica
  static Future<Map<String, dynamic>> findCorrespondent(
    String caseId, {
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
    int topN = 5,
  }) async {
    return getMatches(
      caseId,
      preset: 'correspondent',
      topN: topN,
      customLatitude: latitude,
      customLongitude: longitude,
      radiusKm: radiusKm,
    );
  }

  /// Busca por especialista em área específica
  static Future<Map<String, dynamic>> findExpert(
    String caseId, {
    int topN = 5,
  }) async {
    return getMatches(
      caseId,
      preset: 'expert',
      topN: topN,
    );
  }

  /// Busca por parecerista/opinião especializada
  static Future<Map<String, dynamic>> findExpertOpinion(
    String caseId, {
    int topN = 3,
  }) async {
    return getMatches(
      caseId,
      preset: 'expert_opinion',
      topN: topN,
    );
  }

  /// Busca econômica (melhor custo-benefício)
  static Future<Map<String, dynamic>> findEconomic(
    String caseId, {
    int topN = 5,
  }) async {
    return getMatches(
      caseId,
      preset: 'economic',
      topN: topN,
    );
  }

  /// Busca B2B (escritório para escritório)
  static Future<Map<String, dynamic>> findB2B(
    String caseId, {
    int topN = 5,
  }) async {
    return getMatches(
      caseId,
      preset: 'b2b',
      topN: topN,
    );
  }

  /// Escolhe um advogado para um caso específico (implementação do PLANO_ACAO_CONTRATACAO.md)
  static Future<Map<String, dynamic>> chooseLawyerForCase({
    required String caseId,
    required String lawyerId,
    int choiceOrder = 1,
  }) async {
    try {
      AppLogger.info('Choosing lawyer for case - caseId: $caseId, lawyerId: $lawyerId');
      
      final headers = await _getHeaders();
      final url = '$_baseUrl/cases/$caseId/choose-lawyer';
      final body = jsonEncode({
        'case_id': caseId,
        'chosen_lawyer_id': lawyerId,
        'choice_order': choiceOrder,
      });

      AppLogger.debug('POST $url');
      AppLogger.debug('Request body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      AppLogger.debug('Response status: ${response.statusCode}');
      AppLogger.debug('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        AppLogger.success('Lawyer choice successful: $result');
        return result;
      } else {
        AppLogger.error('Failed to choose lawyer: Status ${response.statusCode}');
        AppLogger.error('Error response: ${response.body}');
        throw ServerException(message: 'Falha ao enviar proposta para o advogado.');
      }
    } catch (e) {
      AppLogger.error('Exception in chooseLawyerForCase: $e');
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(message: 'Erro de conexão ao enviar proposta.');
    }
  }

  static Future<Map<String, dynamic>> checkTriageStatus(String taskId) async {
    final headers = await _getHeaders();
    final url = '$_baseUrl/triage/status/$taskId';
    
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao verificar o status da triagem');
    }
  }

  static Future<Map<String, dynamic>> startIntelligentTriage() async {
    final headers = await _getHeaders();
    final url = '$_baseUrlV2/triage/start';

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao iniciar a conversa de triagem: Status ${response.statusCode} - ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> continueIntelligentTriage({
    required String caseId,
    required String message,
  }) async {
    final headers = await _getHeaders();
    final url = '$_baseUrlV2/triage/continue';
    final body = jsonEncode({
      'case_id': caseId,
      'message': message,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao continuar a conversa de triagem: Status ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<dynamic>> directorySearch(SearchParams params) async {
    try {
      final response = await _dio.get(
        '/lawyers/directory-search',
        queryParameters: params.toQuery(),
      );
      if (response.statusCode == 200) {
        final lawyers = (response.data as List)
            .map((data) => LawyerModel.fromJson(data))
            .toList();
        // Aqui também poderíamos tratar LawFirmModel se o endpoint retornar
        return lawyers;
      } else {
        throw ServerException(message: 'Erro na busca por diretório');
      }
    } on DioException catch (e) {
      throw ServerException.fromDioError(e);
    }
  }

  // ========== OCR E DOCUMENTOS ==========
  
  /// Processa documento via OCR no backend
  static Future<Response> processDocumentOCR({
    required String imageBase64,
    String? caseId,
    String? documentTypeHint,
    required String userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      return await _dio.post('/documents/process-ocr', data: {
        'image_base64': imageBase64,
        'case_id': caseId,
        'document_type_hint': documentTypeHint,
        'user_id': userId,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      AppLogger.error('Erro no processamento OCR', error: e);
      rethrow;
    }
  }

  /// Salva documento processado
  static Future<Response> saveProcessedDocument({
    required String caseId,
    required String documentName,
    required String documentType,
    required Map<String, dynamic> extractedData,
    required Map<String, dynamic> ocrResult,
    required double confidenceScore,
    String? imageBase64,
  }) async {
    try {
      return await _dio.post('/documents/save-processed', data: {
        'case_id': caseId,
        'document_name': documentName,
        'document_type': documentType,
        'extracted_data': extractedData,
        'ocr_result': ocrResult,
        'confidence_score': confidenceScore,
        'image_base64': imageBase64,
      });
    } catch (e) {
      AppLogger.error('Erro ao salvar documento processado', error: e);
      rethrow;
    }
  }

  /// Valida dados extraídos
  static Future<Response> validateDocumentData({
    required Map<String, dynamic> extractedData,
  }) async {
    try {
      return await _dio.post('/documents/validate-data', data: {
        'extracted_data': extractedData,
      });
    } catch (e) {
      AppLogger.error('Erro na validação de dados', error: e);
      rethrow;
    }
  }

  /// Lista documentos OCR de um caso
  static Future<Response> getCaseOCRDocuments(String caseId) async {
    try {
      return await _dio.get('/documents/case/$caseId/ocr-documents');
    } catch (e) {
      AppLogger.error('Erro ao buscar documentos OCR', error: e);
      rethrow;
    }
  }

  /// Obtém detalhes de um documento
  static Future<Response> getDocumentDetails(String documentId) async {
    try {
      return await _dio.get('/documents/document/$documentId/details');
    } catch (e) {
      AppLogger.error('Erro ao buscar detalhes do documento', error: e);
      rethrow;
    }
  }

  /// Reprocessa documento existente
  static Future<Response> reprocessDocument(String documentId) async {
    try {
      return await _dio.post('/documents/reprocess/$documentId');
    } catch (e) {
      AppLogger.error('Erro no reprocessamento do documento', error: e);
      rethrow;
    }
  }

  /// Verifica saúde do serviço OCR
  static Future<Response> checkOCRHealth() async {
    try {
      return await _dio.get('/documents/ocr/health');
    } catch (e) {
      AppLogger.error('Erro ao verificar saúde do OCR', error: e);
      rethrow;
    }
  }
} 