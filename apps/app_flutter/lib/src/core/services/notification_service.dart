import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:meu_app/src/core/services/storage_service.dart';
import 'package:meu_app/src/core/utils/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FirebaseMessaging _messaging;
  late FlutterLocalNotificationsPlugin _localNotifications;
  final Dio _dio = Dio();
  final StorageService _storage = StorageService();
  
  // Callback para quando uma notificação é recebida
  Function(Map<String, dynamic>)? onNotificationReceived;
  Function(Map<String, dynamic>)? onNotificationTapped;

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    _messaging = FirebaseMessaging.instance;
    _localNotifications = FlutterLocalNotificationsPlugin();

    // Configurar notificações locais
    await _setupLocalNotifications();
    
    // Solicitar permissões
    await _requestPermissions();
    
    // Configurar handlers de mensagens
    await _setupMessageHandlers();
    
    // Obter token FCM
    await _getAndSaveFCMToken();
  }

  /// Configura notificações locais
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          onNotificationTapped?.call(data);
        }
      },
    );
  }

  /// Solicita permissões de notificação
  Future<bool> _requestPermissions() async {
    // Permissões Firebase
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Permissões do sistema (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Configura handlers de mensagens
  Future<void> _setupMessageHandlers() async {
    // Mensagem recebida quando app está em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
      _handleNotificationData(message.data);
    });

    // Mensagem que abriu o app (background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onNotificationTapped?.call(message.data);
    });

    // Verificar se app foi aberto por notificação
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      onNotificationTapped?.call(initialMessage.data);
    }
  }

  /// Obtém e salva token FCM
  Future<String?> _getAndSaveFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _sendTokenToBackend(token);
        
        // Listener para atualizações do token
        _messaging.onTokenRefresh.listen(_sendTokenToBackend);
      }
      return token;
    } catch (e) {
      debugPrint('Erro ao obter FCM token: $e');
      return null;
    }
  }

  /// Envia token para o backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final userId = await _storage.getString('user_id');
      if (userId == null) {
        AppLogger.warning('User ID não encontrado, token não será salvo');
        return;
      }

      await _dio.post(
        'http://127.0.0.1:8000/notifications/fcm-token',
        data: {
          'user_id': userId,
          'fcm_token': token,
          'platform': defaultTargetPlatform.name,
          'app_version': '1.0.0',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await _storage.getString('access_token')}',
          },
        ),
      );
      
      AppLogger.success('FCM Token enviado com sucesso: ${token.substring(0, 20)}...');
    } catch (e) {
      AppLogger.error('Erro ao enviar token para backend', error: e);
    }
  }

  /// Mostra notificação local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'offers_channel',
      'Ofertas de Casos',
      channelDescription: 'Notificações sobre novas ofertas de casos',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Nova Oferta',
      message.notification?.body ?? 'Você recebeu uma nova oferta de caso',
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// Processa dados da notificação
  void _handleNotificationData(Map<String, dynamic> data) {
    onNotificationReceived?.call(data);
  }

  /// Limpa todas as notificações
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Define callback para notificação recebida
  void setOnNotificationReceived(Function(Map<String, dynamic>) callback) {
    onNotificationReceived = callback;
  }

  /// Define callback para notificação tocada
  void setOnNotificationTapped(Function(Map<String, dynamic>) callback) {
    onNotificationTapped = callback;
  }

  /// Mostra notificação local (método público para background handler)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? channelId,
    String? channelName,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'default_channel',
      channelName ?? 'Notificações Gerais',
      channelDescription: 'Notificações gerais do aplicativo',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Obtém o token FCM atual
  Future<String?> getCurrentToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      AppLogger.error('Erro ao obter token FCM', error: e);
      return null;
    }
  }

  /// Subscreve a um tópico
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      AppLogger.info('Subscrito ao tópico: $topic');
    } catch (e) {
      AppLogger.error('Erro ao subscrever ao tópico $topic', error: e);
    }
  }

  /// Dessubscreve de um tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      AppLogger.info('Dessubscrito do tópico: $topic');
    } catch (e) {
      AppLogger.error('Erro ao dessubscrever do tópico $topic', error: e);
    }
  }
} 
