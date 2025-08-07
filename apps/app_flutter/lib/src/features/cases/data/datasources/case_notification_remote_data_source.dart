import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:meu_app/src/core/utils/app_logger.dart';

class CaseNotificationRemoteDataSource {
  final http.Client httpClient;
  final String baseUrl;

  CaseNotificationRemoteDataSource({
    required this.httpClient,
    required this.baseUrl,
  });

  /// Envia notificação de caso para o backend processar e enviar por email
  Future<bool> sendCaseNotificationEmail({
    required String notificationType,
    required String userEmail,
    required String userName,
    required Map<String, dynamic> caseData,
    required Map<String, dynamic> notificationData,
    bool sendEmail = true,
  }) async {
    try {
      AppLogger.info('Enviando notificação de caso para backend - Tipo: $notificationType');
      
      final requestBody = {
        'notification_type': notificationType,
        'user_email': userEmail,
        'user_name': userName,
        'case_data': caseData,
        'notification_data': notificationData,
        'send_email': sendEmail,
      };
      
      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/v1/case-notifications/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final success = responseData['success'] as bool;
        final emailSent = responseData['email_sent'] as bool? ?? false;
        
        AppLogger.info('Notificação processada - Sucesso: $success, Email enviado: $emailSent');
        return success;
      } else {
        AppLogger.error('Erro HTTP ao enviar notificação - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      AppLogger.error('Erro ao enviar notificação de caso: $e');
      return false;
    }
  }

  /// Testa o sistema de notificações (apenas para desenvolvimento)
  Future<bool> testCaseNotification() async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/v1/case-notifications/test'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final success = responseData['success'] as bool;
        AppLogger.info('Teste de notificação - Resultado: $success');
        return success;
      } else {
        AppLogger.error('Erro no teste de notificação - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      AppLogger.error('Erro no teste de notificação: $e');
      return false;
    }
  }
}