import 'package:daily_flutter/daily_flutter.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallService {
  static final VideoCallService _instance = VideoCallService._internal();
  factory VideoCallService() => _instance;
  VideoCallService._internal();

  Daily? _daily;
  bool _isInitialized = false;

  // Configuração inicial do Daily.co
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _daily = Daily();
      
      // Solicitar permissões necessárias
      await _requestPermissions();
      
      _isInitialized = true;
      debugPrint('✅ Daily.co inicializado com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar Daily.co: $e');
      rethrow;
    }
  }

  // Solicitar permissões de câmera e microfone
  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    return statuses[Permission.camera] == PermissionStatus.granted &&
           statuses[Permission.microphone] == PermissionStatus.granted;
  }

  // Criar sala de videochamada
  Future<String> createRoom({
    required String roomName,
    bool enableRecording = false,
    int maxParticipants = 2,
  }) async {
    if (!_isInitialized) {
      throw Exception('VideoCallService não foi inicializado');
    }

    try {
      // Em produção, isso seria feito no backend
      // Por ora, vamos criar um room URL mock
      final roomUrl = 'https://litig.daily.co/$roomName';
      
      debugPrint('🎥 Sala criada: $roomUrl');
      return roomUrl;
    } catch (e) {
      debugPrint('❌ Erro ao criar sala: $e');
      rethrow;
    }
  }

  // Entrar em uma sala
  Future<void> joinRoom(String roomUrl) async {
    if (!_isInitialized) {
      throw Exception('VideoCallService não foi inicializado');
    }

    try {
      await _daily?.join(roomUrl);
      debugPrint('🎥 Conectado à sala: $roomUrl');
    } catch (e) {
      debugPrint('❌ Erro ao entrar na sala: $e');
      rethrow;
    }
  }

  // Sair da sala
  Future<void> leaveRoom() async {
    try {
      await _daily?.leave();
      debugPrint('🎥 Saiu da sala');
    } catch (e) {
      debugPrint('❌ Erro ao sair da sala: $e');
    }
  }

  // Alternar câmera
  Future<void> toggleCamera() async {
    try {
      await _daily?.setLocalVideo(!(_daily?.localVideo ?? false));
    } catch (e) {
      debugPrint('❌ Erro ao alternar câmera: $e');
    }
  }

  // Alternar microfone
  Future<void> toggleMicrophone() async {
    try {
      await _daily?.setLocalAudio(!(_daily?.localAudio ?? false));
    } catch (e) {
      debugPrint('❌ Erro ao alternar microfone: $e');
    }
  }

  // Obter estado atual
  bool get isConnected => _daily?.isConnected ?? false;
  bool get isCameraEnabled => _daily?.localVideo ?? false;
  bool get isMicrophoneEnabled => _daily?.localAudio ?? false;

  // Cleanup
  Future<void> dispose() async {
    await leaveRoom();
    await _daily?.destroy();
    _isInitialized = false;
    debugPrint('🎥 VideoCallService finalizado');
  }
}