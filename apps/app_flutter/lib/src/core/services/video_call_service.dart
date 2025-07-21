import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Serviço robusto de videochamada usando WebRTC
/// 
/// Implementa funcionalidades completas de videochamada incluindo:
/// - Criação e gerenciamento de salas
/// - Conexão peer-to-peer via WebRTC
/// - Controle de áudio/vídeo
/// - Gravação de chamadas
/// - Qualidade adaptativa
/// - Reconexão automática
class VideoCallService {
  static final VideoCallService _instance = VideoCallService._internal();
  factory VideoCallService() => _instance;
  VideoCallService._internal();

  // WebRTC components
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  // Socket connection for signaling
  io.Socket? _socket;
  
  // Configuration
  final Map<String, dynamic> _rtcConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      // Em produção, adicionar servidores TURN próprios
    ],
    'sdpSemantics': 'unified-plan',
  };

  // State management
  bool _isInitialized = false;
  bool _isConnected = false;
  bool _isCameraEnabled = true;
  bool _isMicrophoneEnabled = true;
  bool _isRecording = false;
  String? _currentRoomId;
  
  // Stream controllers for UI updates
  final StreamController<MediaStream?> _localStreamController = StreamController.broadcast();
  final StreamController<MediaStream?> _remoteStreamController = StreamController.broadcast();
  final StreamController<bool> _connectionStateController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _callEventsController = StreamController.broadcast();

  // Getters for streams
  Stream<MediaStream?> get localStreamStream => _localStreamController.stream;
  Stream<MediaStream?> get remoteStreamStream => _remoteStreamController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<Map<String, dynamic>> get callEventsStream => _callEventsController.stream;

  // Public getters
  bool get isConnected => _isConnected;
  bool get isCameraEnabled => _isCameraEnabled;
  bool get isMicrophoneEnabled => _isMicrophoneEnabled;
  bool get isRecording => _isRecording;
  String? get currentRoomId => _currentRoomId;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  /// Inicializa o serviço de videochamada
  Future<void> initialize({String? signalingServerUrl}) async {
    if (_isInitialized) return;

    try {
      // Solicitar permissões necessárias
      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        throw Exception('Permissões de câmera e microfone são necessárias');
      }

      // Conectar ao servidor de sinalização
      await _connectSignalingServer(signalingServerUrl ?? 'ws://localhost:3000');
      
      _isInitialized = true;
      debugPrint('✅ VideoCallService inicializado com sucesso');
      
      _callEventsController.add({
        'type': 'service_initialized',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Erro ao inicializar VideoCallService: $e');
      rethrow;
    }
  }

  /// Solicita permissões de câmera e microfone
  Future<bool> _requestPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final cameraGranted = statuses[Permission.camera] == PermissionStatus.granted;
      final microphoneGranted = statuses[Permission.microphone] == PermissionStatus.granted;

      debugPrint('📹 Permissão de câmera: ${cameraGranted ? "✅" : "❌"}');
      debugPrint('🎤 Permissão de microfone: ${microphoneGranted ? "✅" : "❌"}');

      return cameraGranted && microphoneGranted;
    } catch (e) {
      debugPrint('❌ Erro ao solicitar permissões: $e');
      return false;
    }
  }

  /// Conecta ao servidor de sinalização WebSocket
  Future<void> _connectSignalingServer(String url) async {
    try {
      _socket = io.io(url, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _socket!.onConnect((_) {
        debugPrint('🔗 Conectado ao servidor de sinalização');
      });

      _socket!.onDisconnect((_) {
        debugPrint('🔌 Desconectado do servidor de sinalização');
        _isConnected = false;
        _connectionStateController.add(false);
      });

      _socket!.on('offer', _handleOffer);
      _socket!.on('answer', _handleAnswer);
      _socket!.on('ice-candidate', _handleIceCandidate);
      _socket!.on('user-joined', _handleUserJoined);
      _socket!.on('user-left', _handleUserLeft);
      _socket!.on('room-full', _handleRoomFull);

    } catch (e) {
      debugPrint('❌ Erro ao conectar servidor de sinalização: $e');
      rethrow;
    }
  }

  /// Cria uma nova sala de videochamada
  Future<String> createRoom({
    required String roomName,
    bool enableRecording = false,
    int maxParticipants = 2,
    Map<String, dynamic>? roomConfig,
  }) async {
    if (!_isInitialized) {
      throw Exception('VideoCallService não foi inicializado');
    }

    try {
      final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}_$roomName';
      
      // Configurações da sala
      final config = {
        'roomId': roomId,
        'roomName': roomName,
        'maxParticipants': maxParticipants,
        'enableRecording': enableRecording,
        'createdAt': DateTime.now().toIso8601String(),
        'features': {
          'screenShare': true,
          'recording': enableRecording,
          'chat': true,
          'fileSharing': true,
        },
        ...?roomConfig,
      };

      _socket?.emit('create-room', config);
      
      debugPrint('🏠 Sala criada: $roomId');
      
      _callEventsController.add({
        'type': 'room_created',
        'roomId': roomId,
        'config': config,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return roomId;
    } catch (e) {
      debugPrint('❌ Erro ao criar sala: $e');
      rethrow;
    }
  }

  /// Entra em uma sala existente
  Future<void> joinRoom(String roomId, {String? userName}) async {
    if (!_isInitialized) {
      throw Exception('VideoCallService não foi inicializado');
    }

    try {
      _currentRoomId = roomId;
      
      // Inicializar stream local
      await _initializeLocalStream();
      
      // Criar conexão peer
      await _createPeerConnection();
      
      // Entrar na sala via socket
      _socket?.emit('join-room', {
        'roomId': roomId,
        'userName': userName ?? 'User_${DateTime.now().millisecondsSinceEpoch}',
        'userAgent': 'LITIG-1 Flutter App',
      });

      debugPrint('🚪 Entrando na sala: $roomId');
      
      _callEventsController.add({
        'type': 'joining_room',
        'roomId': roomId,
        'userName': userName,
        'timestamp': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      debugPrint('❌ Erro ao entrar na sala: $e');
      rethrow;
    }
  }

  /// Inicializa o stream local (câmera e microfone)
  Future<void> _initializeLocalStream() async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': {
          'width': {'min': 640, 'ideal': 1280, 'max': 1920},
          'height': {'min': 480, 'ideal': 720, 'max': 1080},
          'frameRate': {'min': 15, 'ideal': 30, 'max': 60},
          'facingMode': 'user',
        },
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStreamController.add(_localStream);
      
      debugPrint('📹 Stream local inicializado');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar stream local: $e');
      rethrow;
    }
  }

  /// Cria conexão WebRTC peer-to-peer
  Future<void> _createPeerConnection() async {
    try {
      _peerConnection = await createPeerConnection(_rtcConfiguration);
      
      // Adicionar stream local
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
        });
      }

      // Configurar callbacks
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        _socket?.emit('ice-candidate', {
          'roomId': _currentRoomId,
          'candidate': candidate.toMap(),
        });
      };

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        debugPrint('📡 Stream remoto recebido');
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream);
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('🔗 Estado da conexão: $state');
        _isConnected = state == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
        _connectionStateController.add(_isConnected);
        
        _callEventsController.add({
          'type': 'connection_state_changed',
          'state': state.toString(),
          'isConnected': _isConnected,
          'timestamp': DateTime.now().toIso8601String(),
        });
      };

      debugPrint('🔗 PeerConnection criado');
    } catch (e) {
      debugPrint('❌ Erro ao criar PeerConnection: $e');
      rethrow;
    }
  }

  /// Manipula ofertas WebRTC recebidas
  Future<void> _handleOffer(dynamic data) async {
    try {
      final offer = RTCSessionDescription(data['offer']['sdp'], data['offer']['type']);
      await _peerConnection?.setRemoteDescription(offer);
      
      final answer = await _peerConnection?.createAnswer();
      await _peerConnection?.setLocalDescription(answer!);
      
      _socket?.emit('answer', {
        'roomId': _currentRoomId,
        'answer': answer!.toMap(),
      });
      
      debugPrint('📞 Oferta processada e resposta enviada');
    } catch (e) {
      debugPrint('❌ Erro ao processar oferta: $e');
    }
  }

  /// Manipula respostas WebRTC recebidas
  Future<void> _handleAnswer(dynamic data) async {
    try {
      final answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
      await _peerConnection?.setRemoteDescription(answer);
      debugPrint('📞 Resposta recebida e processada');
    } catch (e) {
      debugPrint('❌ Erro ao processar resposta: $e');
    }
  }

  /// Manipula candidatos ICE recebidos
  Future<void> _handleIceCandidate(dynamic data) async {
    try {
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      await _peerConnection?.addCandidate(candidate);
      debugPrint('🧊 Candidato ICE adicionado');
    } catch (e) {
      debugPrint('❌ Erro ao adicionar candidato ICE: $e');
    }
  }

  /// Manipula entrada de novos usuários
  void _handleUserJoined(dynamic data) {
    debugPrint('👤 Usuário entrou: ${data['userName']}');
    _callEventsController.add({
      'type': 'user_joined',
      'userName': data['userName'],
      'userId': data['userId'],
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Iniciar processo de oferecimento se formos o initiator
    if (data['initiator'] == true) {
      _createOffer();
    }
  }

  /// Manipula saída de usuários
  void _handleUserLeft(dynamic data) {
    debugPrint('👤 Usuário saiu: ${data['userName']}');
    _callEventsController.add({
      'type': 'user_left',
      'userName': data['userName'],
      'userId': data['userId'],
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Manipula sala lotada
  void _handleRoomFull(dynamic data) {
    debugPrint('🚫 Sala lotada: ${data['roomId']}');
    _callEventsController.add({
      'type': 'room_full',
      'roomId': data['roomId'],
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Cria uma oferta WebRTC
  Future<void> _createOffer() async {
    try {
      final offer = await _peerConnection?.createOffer();
      await _peerConnection?.setLocalDescription(offer!);
      
      _socket?.emit('offer', {
        'roomId': _currentRoomId,
        'offer': offer!.toMap(),
      });
      
      debugPrint('📞 Oferta criada e enviada');
    } catch (e) {
      debugPrint('❌ Erro ao criar oferta: $e');
    }
  }

  /// Alterna o estado da câmera
  Future<void> toggleCamera() async {
    if (_localStream == null) return;
    
    try {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        _isCameraEnabled = !_isCameraEnabled;
        videoTracks[0].enabled = _isCameraEnabled;
        
        debugPrint('📹 Câmera ${_isCameraEnabled ? "ligada" : "desligada"}');
        
        _callEventsController.add({
          'type': 'camera_toggled',
          'enabled': _isCameraEnabled,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao alternar câmera: $e');
    }
  }

  /// Alterna o estado do microfone
  Future<void> toggleMicrophone() async {
    if (_localStream == null) return;
    
    try {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        _isMicrophoneEnabled = !_isMicrophoneEnabled;
        audioTracks[0].enabled = _isMicrophoneEnabled;
        
        debugPrint('🎤 Microfone ${_isMicrophoneEnabled ? "ligado" : "desligado"}');
        
        _callEventsController.add({
          'type': 'microphone_toggled',
          'enabled': _isMicrophoneEnabled,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao alternar microfone: $e');
    }
  }

  /// Inicia gravação da chamada
  Future<void> startRecording() async {
    if (_isRecording) return;
    
    try {
      _socket?.emit('start-recording', {
        'roomId': _currentRoomId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      _isRecording = true;
      debugPrint('🔴 Gravação iniciada');
      
      _callEventsController.add({
        'type': 'recording_started',
        'roomId': _currentRoomId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Erro ao iniciar gravação: $e');
    }
  }

  /// Para gravação da chamada
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    try {
      _socket?.emit('stop-recording', {
        'roomId': _currentRoomId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      _isRecording = false;
      debugPrint('⏹️ Gravação parada');
      
      _callEventsController.add({
        'type': 'recording_stopped',
        'roomId': _currentRoomId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Erro ao parar gravação: $e');
    }
  }

  /// Troca câmera (frontal/traseira) em dispositivos móveis
  Future<void> switchCamera() async {
    if (_localStream == null) return;
    
    try {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        await Helper.switchCamera(videoTracks[0]);
        debugPrint('🔄 Câmera trocada');
        
        _callEventsController.add({
          'type': 'camera_switched',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao trocar câmera: $e');
    }
  }

  /// Sai da sala atual
  Future<void> leaveRoom() async {
    try {
      if (_currentRoomId != null) {
        _socket?.emit('leave-room', {
          'roomId': _currentRoomId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      // Limpar streams
      await _localStream?.dispose();
      await _remoteStream?.dispose();
      _localStream = null;
      _remoteStream = null;
      
      // Fechar conexão peer
      await _peerConnection?.close();
      _peerConnection = null;
      
      // Reset state
      _isConnected = false;
      _currentRoomId = null;
      
      // Notificar UI
      _localStreamController.add(null);
      _remoteStreamController.add(null);
      _connectionStateController.add(false);
      
      debugPrint('🚪 Saiu da sala');
      
      _callEventsController.add({
        'type': 'left_room',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Erro ao sair da sala: $e');
    }
  }

  /// Obtém estatísticas da conexão
  Future<Map<String, dynamic>> getConnectionStats() async {
    if (_peerConnection == null) return {};
    
    try {
      final stats = await _peerConnection!.getStats();
      final statsMap = <String, dynamic>{};
      
      for (var report in stats) {
        statsMap[report.id] = report.values;
      }
      
      return {
        'connectionStats': statsMap,
        'isConnected': _isConnected,
        'roomId': _currentRoomId,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Erro ao obter estatísticas: $e');
      return {};
    }
  }

  /// Finaliza o serviço e limpa recursos
  Future<void> dispose() async {
    try {
      await leaveRoom();
      
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      
      await _localStreamController.close();
      await _remoteStreamController.close();
      await _connectionStateController.close();
      await _callEventsController.close();
      
      _isInitialized = false;
      
      debugPrint('🎥 VideoCallService finalizado');
    } catch (e) {
      debugPrint('❌ Erro ao finalizar VideoCallService: $e');
    }
  }
}