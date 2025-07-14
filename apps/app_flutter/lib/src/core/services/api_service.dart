import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static String get _baseUrl {
    // Debug logs para verificar a detecção de plataforma
    print('🔍 DEBUG ApiService: kIsWeb = $kIsWeb');
    
    // Detecção mais robusta de plataforma
    if (kIsWeb) {
      print('🌐 DEBUG ApiService: Detectado Flutter Web - usando localhost:8080');
      return 'http://localhost:8080/api';
    }
    
    // Para plataformas nativas, verificar o Platform
    try {
      if (Platform.isAndroid) {
        print('🤖 DEBUG ApiService: Detectado Android - usando 10.0.2.2:8080');
        return 'http://10.0.2.2:8080/api'; // Emulador Android
      } else if (Platform.isIOS) {
        print('🍎 DEBUG ApiService: Detectado iOS - usando 127.0.0.1:8080');
        return 'http://127.0.0.1:8080/api'; // Simulador iOS
      } else {
        print('🖥️ DEBUG ApiService: Detectado Desktop - usando localhost:8080');
        return 'http://localhost:8080/api'; // Desktop
      }
    } catch (e) {
      // Se Platform não estiver disponível (ex: Web), usar localhost
      print('⚠️ DEBUG ApiService: Platform não disponível, fallback para localhost:8080');
      return 'http://localhost:8080/api';
    }
  }

  static String get _baseUrlV2 {
    // Debug logs para verificar a detecção de plataforma
    print('🔍 DEBUG ApiService V2: kIsWeb = $kIsWeb');
    
    // Detecção mais robusta de plataforma
    if (kIsWeb) {
      print('🌐 DEBUG ApiService V2: Detectado Flutter Web - usando localhost:8080');
      return 'http://localhost:8080/api/v2';
    }
    
    // Para plataformas nativas, verificar o Platform
    try {
      if (Platform.isAndroid) {
        print('🤖 DEBUG ApiService V2: Detectado Android - usando 10.0.2.2:8080');
        return 'http://10.0.2.2:8080/api/v2'; // Emulador Android
      } else if (Platform.isIOS) {
        print('🍎 DEBUG ApiService V2: Detectado iOS - usando 127.0.0.1:8080');
        return 'http://127.0.0.1:8080/api/v2'; // Simulador iOS
      } else {
        print('🖥️ DEBUG ApiService V2: Detectado Desktop - usando localhost:8080');
        return 'http://localhost:8080/api/v2'; // Desktop
      }
    } catch (e) {
      // Se Platform não estiver disponível (ex: Web), usar localhost
      print('⚠️ DEBUG ApiService V2: Platform não disponível, fallback para localhost:8080');
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
      
      print('DEBUG: Tentando acessar URL: $url');
      print('DEBUG: Headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('DEBUG: Status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao buscar casos: Status ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG: Erro capturado: $e');
      print('DEBUG: Tipo do erro: ${e.runtimeType}');
      throw Exception('Erro ao buscar casos: $e');
    }
  }

  static Future<Map<String, dynamic>> getCaseDetail(String caseId) async {
    try {
      final headers = await _getHeaders();
      final url = '$_baseUrl/cases/$caseId';
      
      print('DEBUG: Tentando acessar URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('DEBUG: Status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao buscar detalhes do caso: Status ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG: Erro capturado: $e');
      throw Exception('Erro ao buscar detalhes do caso: $e');
    }
  }

  // ===== TRIAGEM =====
  static Future<Map<String, dynamic>> startTriageConversation() async {
    try {
      final headers = await _getHeaders();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final body = jsonEncode({'user_id': user.id});
      final url = '$_baseUrlV2/triage/start';
      
      print('DEBUG: Tentando acessar URL: $url');
      print('DEBUG: Headers: $headers');
      print('DEBUG: Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      
      print('DEBUG: Status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao iniciar a conversa de triagem: Status ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG: Erro capturado: $e');
      print('DEBUG: Tipo do erro: ${e.runtimeType}');
      throw Exception('Erro ao iniciar conversa: $e');
    }
  }

  static Future<Map<String, dynamic>> continueTriageConversation(String caseId, String message) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({'case_id': caseId, 'message': message});
      final url = '$_baseUrlV2/triage/continue';

      print('DEBUG: Tentando acessar URL (continue): $url');
      print('DEBUG: Headers (continue): $headers');
      print('DEBUG: Body (continue): $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('DEBUG: Status code (continue): ${response.statusCode}');
      print('DEBUG: Response body (continue): ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Erro ${response.statusCode}: ${errorData['detail'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      print('DEBUG: Erro capturado em continueTriageConversation: $e');
      print('DEBUG: Tipo do erro: ${e.runtimeType}');
      // Retransmite a exceção para ser tratada na UI
      rethrow;
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
      body['custom_coords'] = {
        'latitude': customLatitude,
        'longitude': customLongitude,
      };
    }
    
    // Adicionar raio se fornecido
    if (radiusKm != null) {
      body['radius_km'] = radiusKm.toInt();
    }
    
    final url = '$_baseUrl/match';

    print('DEBUG: Enviando requisição de match com preset: $preset');
    print('DEBUG: Coordenadas customizadas: ${customLatitude != null ? '[$customLatitude, $customLongitude]' : 'Não fornecidas'}');
    print('DEBUG: Raio: ${radiusKm ?? 'Padrão'}km');

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data; // Retorna o objeto completo da resposta
    } else {
      throw Exception('Falha ao buscar recomendações: Status ${response.statusCode} - ${response.body}');
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
} 