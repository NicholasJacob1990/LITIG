import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8000/api'; // Corrigido de 8080 para 8000

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

  static Future<Map<String, dynamic>> startTriageConversation() async {
    try {
      final headers = await _getHeaders();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final body = jsonEncode({'user_id': user.id});
      const url = '$_baseUrl/v2/triage/start';
      
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
      const url = '$_baseUrl/v2/triage/continue';

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

  static Future<String> submitTriageTranscript(String transcript) async {
    final headers = await _getHeaders();
    final body = jsonEncode({'texto_cliente': transcript});
    const url = '$_baseUrl/triage/full-flow';

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

  static Future<List<dynamic>> getMatches(String caseId) async {
    final headers = await _getHeaders();
    final body = jsonEncode({
      'case_id': caseId,
      'k': 5,
      'preset': 'balanced',
    });
    const url = '$_baseUrl/match';

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['matches'] ?? [];
    } else {
      throw Exception('Falha ao buscar recomendações');
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
} 