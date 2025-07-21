import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meu_app/src/core/utils/logger.dart';

/// Serviço simplificado de API para compatibilidade com data sources
class SimpleApiService {
  final http.Client _client;
  
  SimpleApiService(this._client);

  String get baseUrl => _baseUrl;

  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }
    
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080/api';
      } else if (Platform.isIOS) {
        return 'http://127.0.0.1:8080/api';
      } else {
        return 'http://localhost:8080/api';
      }
    } catch (e) {
      return 'http://localhost:8080/api';
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final session = Supabase.instance.client.auth.currentSession;
    final headers = {
      'Content-Type': 'application/json',
    };
    
    final accessToken = session?.accessToken;
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    
    return headers;
  }

  /// Método GET
  Future<ApiResponse> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final url = '$_baseUrl$endpoint';
      
      AppLogger.debug('GET $url');
      
      final response = await _client.get(
        Uri.parse(url),
        headers: headers,
      );
      
      AppLogger.debug('Response ${response.statusCode}');
      
      return ApiResponse(
        statusCode: response.statusCode,
        data: jsonDecode(response.body),
      );
    } catch (e) {
      AppLogger.error('GET $endpoint failed', error: e);
      rethrow;
    }
  }

  /// Método POST
  Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final headers = await _getHeaders();
      final url = '$_baseUrl$endpoint';
      
      AppLogger.debug('POST $url');
      
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: data != null ? jsonEncode(data) : null,
      );
      
      AppLogger.debug('Response ${response.statusCode}');
      
      return ApiResponse(
        statusCode: response.statusCode,
        data: jsonDecode(response.body),
      );
    } catch (e) {
      AppLogger.error('POST $endpoint failed', error: e);
      rethrow;
    }
  }

  /// Método PUT
  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final headers = await _getHeaders();
      final url = '$_baseUrl$endpoint';
      
      AppLogger.debug('PUT $url');
      
      final response = await _client.put(
        Uri.parse(url),
        headers: headers,
        body: data != null ? jsonEncode(data) : null,
      );
      
      AppLogger.debug('Response ${response.statusCode}');
      
      return ApiResponse(
        statusCode: response.statusCode,
        data: jsonDecode(response.body),
      );
    } catch (e) {
      AppLogger.error('PUT $endpoint failed', error: e);
      rethrow;
    }
  }

  /// Método PATCH
  Future<ApiResponse> patch(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final headers = await _getHeaders();
      final url = '$_baseUrl$endpoint';
      
      AppLogger.debug('PATCH $url');
      
      final response = await _client.patch(
        Uri.parse(url),
        headers: headers,
        body: data != null ? jsonEncode(data) : null,
      );
      
      AppLogger.debug('Response ${response.statusCode}');
      
      return ApiResponse(
        statusCode: response.statusCode,
        data: response.body.isNotEmpty ? jsonDecode(response.body) : {},
      );
    } catch (e) {
      AppLogger.error('PATCH $endpoint failed', error: e);
      rethrow;
    }
  }

  /// Método DELETE
  Future<ApiResponse> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final url = '$_baseUrl$endpoint';
      
      AppLogger.debug('DELETE $url');
      
      final response = await _client.delete(
        Uri.parse(url),
        headers: headers,
      );
      
      AppLogger.debug('Response ${response.statusCode}');
      
      return ApiResponse(
        statusCode: response.statusCode,
        data: response.body.isNotEmpty ? jsonDecode(response.body) : {},
      );
    } catch (e) {
      AppLogger.error('DELETE $endpoint failed', error: e);
      rethrow;
    }
  }
}

/// Classe de resposta da API
class ApiResponse {
  final int statusCode;
  final dynamic data;

  ApiResponse({
    required this.statusCode,
    required this.data,
  });
} 