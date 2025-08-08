import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:meu_app/src/core/utils/app_logger.dart';

class CommunicationsServiceException implements Exception {
  final String message;
  CommunicationsServiceException(this.message);
  @override
  String toString() => 'CommunicationsServiceException: $message';
}

class CommunicationsService {
  static final CommunicationsService _instance = CommunicationsService._internal();
  factory CommunicationsService() => _instance;
  CommunicationsService._internal();

  String _baseUrl = _resolveDefaultBaseUrl();
  final http.Client _client = http.Client();
  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void setBaseUrl(String baseUrl) {
    if (baseUrl.isNotEmpty) {
      _baseUrl = baseUrl;
    }
  }

  static String _resolveDefaultBaseUrl() {
    try {
      if (kIsWeb) return 'http://localhost:8080/api/v2/communications';
      if (Platform.isAndroid) return 'http://10.0.2.2:8080/api/v2/communications';
      return 'http://localhost:8080/api/v2/communications';
    } catch (_) {
      return 'http://localhost:8080/api/v2/communications';
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) headers['Authorization'] = 'Bearer $_authToken';
    return headers;
  }

  Future<Map<String, dynamic>> _makeRequest(String method, String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final headers = await _getHeaders();
      final url = '$_baseUrl$endpoint';
      AppLogger.debug('Communications API: $method $url');
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(Uri.parse(url), headers: headers);
          break;
        case 'POST':
          response = await _client.post(Uri.parse(url), headers: headers, body: data != null ? jsonEncode(data) : null);
          break;
        default:
          throw Exception('HTTP method not supported: $method');
      }
      AppLogger.debug('Communications Response: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isNotEmpty ? jsonDecode(response.body) : {};
      }
      throw CommunicationsServiceException('Erro: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('Erro na requisição Communications', {'error': e.toString()});
      rethrow;
    }
  }

  // ===== WhatsApp Business =====
  Future<bool> sendWhatsAppText({required String toPhoneE164, required String message}) async {
    final resp = await _makeRequest('POST', '/whatsapp/send-text', data: {
      'to': toPhoneE164,
      'message': message,
    });
    return resp['success'] == true;
  }

  Future<bool> sendWhatsAppAudio({required String toPhoneE164, required String audioUrl}) async {
    final resp = await _makeRequest('POST', '/whatsapp/send-audio', data: {
      'to': toPhoneE164,
      'audio_url': audioUrl,
    });
    return resp['success'] == true;
  }

  // ===== Microsoft Graph (app-only) =====
  Future<Map<String, dynamic>> graphListMessages({required String userUpn, int top = 25}) async {
    return _makeRequest('GET', '/graph/$userUpn/messages?top=$top');
  }

  Future<bool> graphSendMail({required String userUpn, required List<String> to, required String subject, required String bodyHtml}) async {
    final resp = await _makeRequest('POST', '/graph/$userUpn/sendMail', data: {
      'to': to,
      'subject': subject,
      'body_html': bodyHtml,
    });
    return resp['success'] == true;
  }

  Future<Map<String, dynamic>> graphListEvents({required String userUpn, int top = 50}) async {
    return _makeRequest('GET', '/graph/$userUpn/events?top=$top');
  }

  Future<Map<String, dynamic>> graphCreateEvent({
    required String userUpn,
    required String subject,
    required DateTime start,
    required DateTime end,
    String? location,
    List<String>? attendees,
    String bodyHtml = '',
  }) async {
    return _makeRequest('POST', '/graph/$userUpn/events', data: {
      'subject': subject,
      'start_iso': start.toUtc().toIso8601String(),
      'end_iso': end.toUtc().toIso8601String(),
      'location': location,
      'attendees': attendees,
      'body_html': bodyHtml,
    });
  }

  // ===== Gmail (delegated token provided by backend/session) =====
  Future<Map<String, dynamic>> gmailListMessages({required String accessToken, int maxResults = 25}) async {
    return _makeRequest('GET', '/gmail/messages?access_token=$accessToken&max_results=$maxResults');
  }

  Future<bool> gmailSendRaw({required String accessToken, required String rawBase64}) async {
    final resp = await _makeRequest('POST', '/gmail/send', data: {
      'access_token': accessToken,
      'raw_base64': rawBase64,
    });
    return resp['success'] == true;
  }

  void dispose() {
    _client.close();
  }
}


