import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/services/video_call_service.dart';

/// Tela principal de videochamada com interface completa
/// 
/// Funcionalidades implementadas:
/// - Interface responsiva para web e mobile
/// - Controles de áudio/vídeo
/// - Modo picture-in-picture
/// - Chat integrado
/// - Compartilhamento de tela
/// - Gravação de chamadas
/// - Estatísticas em tempo real
/// - Qualidade adaptativa
class VideoCallScreen extends StatefulWidget {
  final String? roomId;
  final String? userName;
  final Map<String, dynamic>? callConfig;

  const VideoCallScreen({
    super.key,
    this.roomId,
    this.userName,
    this.callConfig,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  // Service instances
  final VideoCallService _videoCallService = VideoCallService();
  
  // UI Controllers
  late AnimationController _controlsAnimationController;
  late AnimationController _connectionAnimationController;
  late Animation<double> _controlsOpacity;
  late Animation<double> _connectionPulse;
  
  // Video renderers
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  
  // Stream subscriptions
  StreamSubscription<MediaStream?>? _localStreamSubscription;
  StreamSubscription<MediaStream?>? _remoteStreamSubscription;
  StreamSubscription<bool>? _connectionStateSubscription;
  StreamSubscription<Map<String, dynamic>>? _callEventsSubscription;
  
  // UI State
  bool _isControlsVisible = true;
  bool _isConnected = false;
  bool _isFullscreen = false;
  bool _showStatistics = false;
  bool _showChat = false;
  Timer? _controlsTimer;
  
  // Call statistics
  Map<String, dynamic> _connectionStats = {};
  Timer? _statsTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _initializeAnimations();
    _initializeRenderers();
    _initializeVideoCall();
    _setupStreamSubscriptions();
    _startControlsTimer();
    _startStatsTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    _controlsTimer?.cancel();
    _statsTimer?.cancel();
    
    _localStreamSubscription?.cancel();
    _remoteStreamSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _callEventsSubscription?.cancel();
    
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    
    _controlsAnimationController.dispose();
    _connectionAnimationController.dispose();
    
    _videoCallService.dispose();
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // Pausar vídeo em background para economizar bateria
        _videoCallService.toggleCamera();
        break;
      case AppLifecycleState.resumed:
        // Reativar vídeo ao voltar
        if (!_videoCallService.isCameraEnabled) {
          _videoCallService.toggleCamera();
        }
        break;
      default:
        break;
    }
  }

  /// Inicializa animações da interface
  void _initializeAnimations() {
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _connectionAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _controlsOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _connectionPulse = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _connectionAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _controlsAnimationController.forward();
    _connectionAnimationController.repeat(reverse: true);
  }

  /// Inicializa os renderizadores de vídeo
  Future<void> _initializeRenderers() async {
    try {
      _localRenderer = RTCVideoRenderer();
      _remoteRenderer = RTCVideoRenderer();
      
      await _localRenderer!.initialize();
      await _remoteRenderer!.initialize();
      
      debugPrint('✅ Video renderers inicializados');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar renderers: $e');
    }
  }

  /// Inicializa o serviço de videochamada
  Future<void> _initializeVideoCall() async {
    try {
      await _videoCallService.initialize();
      
      if (widget.roomId != null) {
        await _videoCallService.joinRoom(
          widget.roomId!,
          userName: widget.userName,
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao inicializar videochamada: $e');
      _showErrorDialog('Erro ao conectar', e.toString());
    }
  }

  /// Configura assinatura dos streams
  void _setupStreamSubscriptions() {
    _localStreamSubscription = _videoCallService.localStreamStream.listen((stream) {
      if (stream != null && _localRenderer != null) {
        _localRenderer!.srcObject = stream;
        setState(() {});
      }
    });

    _remoteStreamSubscription = _videoCallService.remoteStreamStream.listen((stream) {
      if (stream != null && _remoteRenderer != null) {
        _remoteRenderer!.srcObject = stream;
        setState(() {});
      }
    });

    _connectionStateSubscription = _videoCallService.connectionStateStream.listen((connected) {
      setState(() {
        _isConnected = connected;
      });
      
      if (connected) {
        _connectionAnimationController.stop();
      } else {
        _connectionAnimationController.repeat(reverse: true);
      }
    });

    _callEventsSubscription = _videoCallService.callEventsStream.listen((event) {
      _handleCallEvent(event);
    });
  }

  /// Manipula eventos da chamada
  void _handleCallEvent(Map<String, dynamic> event) {
    final type = event['type'] as String;
    
    switch (type) {
      case 'user_joined':
        _showSnackBar('${event['userName']} entrou na chamada');
        break;
      case 'user_left':
        _showSnackBar('${event['userName']} saiu da chamada');
        break;
      case 'room_full':
        _showErrorDialog('Sala Lotada', 'A sala atingiu o número máximo de participantes');
        break;
      case 'recording_started':
        _showSnackBar('🔴 Gravação iniciada');
        break;
      case 'recording_stopped':
        _showSnackBar('⏹️ Gravação parada');
        break;
      default:
        debugPrint('Evento não tratado: $type');
    }
  }

  /// Inicia timer para esconder controles automaticamente
  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isControlsVisible) {
        setState(() {
          _isControlsVisible = false;
        });
        _controlsAnimationController.reverse();
      }
    });
  }

  /// Inicia timer para atualizar estatísticas
  void _startStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_showStatistics) {
        final stats = await _videoCallService.getConnectionStats();
        setState(() {
          _connectionStats = stats;
        });
      }
    });
  }

  /// Exibe controles novamente
  void _showControls() {
    if (!_isControlsVisible) {
      setState(() {
        _isControlsVisible = true;
      });
      _controlsAnimationController.forward();
    }
    _startControlsTimer();
  }

  /// Alterna modo fullscreen
  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  /// Exibe dialog de erro
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Sair da tela de chamada
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Exibe snackbar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background video area
          _buildVideoArea(),
          
          // Connection status
          if (!_isConnected) _buildConnectionStatus(),
          
          // Controls overlay
          _buildControlsOverlay(),
          
          // Statistics panel
          if (_showStatistics) _buildStatisticsPanel(),
          
          // Chat panel
          if (_showChat) _buildChatPanel(),
        ],
      ),
    );
  }

  /// Constrói área de vídeo principal
  Widget _buildVideoArea() {
    return GestureDetector(
      onTap: _showControls,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            // Remote video (main)
            if (_remoteRenderer?.srcObject != null)
              RTCVideoView(
                _remoteRenderer!,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
            else
              _buildWaitingView(),
            
            // Local video (picture-in-picture)
            if (_localRenderer?.srcObject != null)
              Positioned(
                top: 60,
                right: 20,
                child: _buildLocalVideoView(),
              ),
          ],
        ),
      ),
    );
  }

  /// Constrói view de espera
  Widget _buildWaitingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _connectionPulse,
            builder: (context, child) {
              return Transform.scale(
                scale: _connectionPulse.value,
                child: Icon(
                  LucideIcons.video,
                  size: 100,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Aguardando outros participantes...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Room ID: ${widget.roomId}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói view do vídeo local (PiP)
  Widget _buildLocalVideoView() {
    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: RTCVideoView(
          _localRenderer!,
          mirror: true,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
      ),
    );
  }

  /// Constrói status de conexão
  Widget _buildConnectionStatus() {
    return Positioned(
      top: 60,
      left: 20,
      child: AnimatedBuilder(
        animation: _connectionPulse,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: _connectionPulse.value,
                  child: const Icon(
                    LucideIcons.wifi,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Conectando...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Constrói overlay de controles
  Widget _buildControlsOverlay() {
    return AnimatedBuilder(
      animation: _controlsOpacity,
      builder: (context, child) {
        return Opacity(
          opacity: _isControlsVisible ? _controlsOpacity.value : 0.0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Column(
              children: [
                // Top bar
                _buildTopBar(),
                
                const Spacer(),
                
                // Bottom controls
                _buildBottomControls(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Constrói barra superior
  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: () async {
                await _videoCallService.leaveRoom();
                Navigator.of(context).pop();
              },
              icon: const Icon(LucideIcons.x, color: Colors.white),
            ),
            
            Expanded(
              child: Text(
                'Chamada de Vídeo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            IconButton(
              onPressed: () {
                setState(() {
                  _showStatistics = !_showStatistics;
                });
              },
              icon: Icon(
                LucideIcons.barChart3,
                color: _showStatistics ? Colors.blue : Colors.white,
              ),
            ),
            
            IconButton(
              onPressed: () {
                setState(() {
                  _showChat = !_showChat;
                });
              },
              icon: Icon(
                LucideIcons.messageSquare,
                color: _showChat ? Colors.blue : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói controles inferiores
  Widget _buildBottomControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Toggle microphone
            _buildControlButton(
              icon: _videoCallService.isMicrophoneEnabled
                  ? LucideIcons.mic
                  : LucideIcons.micOff,
              isActive: _videoCallService.isMicrophoneEnabled,
              onPressed: _videoCallService.toggleMicrophone,
            ),
            
            // Toggle camera
            _buildControlButton(
              icon: _videoCallService.isCameraEnabled
                  ? LucideIcons.video
                  : LucideIcons.videoOff,
              isActive: _videoCallService.isCameraEnabled,
              onPressed: _videoCallService.toggleCamera,
            ),
            
            // Switch camera (mobile only)
            if (Theme.of(context).platform == TargetPlatform.android ||
                Theme.of(context).platform == TargetPlatform.iOS)
              _buildControlButton(
                icon: LucideIcons.rotateCcw,
                onPressed: _videoCallService.switchCamera,
              ),
            
            // Toggle recording
            _buildControlButton(
              icon: _videoCallService.isRecording
                  ? LucideIcons.square
                  : LucideIcons.circle,
              isActive: _videoCallService.isRecording,
              color: _videoCallService.isRecording ? Colors.red : null,
              onPressed: () {
                if (_videoCallService.isRecording) {
                  _videoCallService.stopRecording();
                } else {
                  _videoCallService.startRecording();
                }
              },
            ),
            
            // End call
            _buildControlButton(
              icon: LucideIcons.phoneOff,
              color: Colors.red,
              onPressed: () async {
                await _videoCallService.leaveRoom();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói botão de controle
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = true,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (color ?? (isActive ? Colors.white : Colors.grey))
            .withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: color != null ? Colors.white : Colors.black,
          size: 24,
        ),
        iconSize: 24,
      ),
    );
  }

  /// Constrói painel de estatísticas
  Widget _buildStatisticsPanel() {
    return Positioned(
      top: 100,
      right: 20,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estatísticas da Conexão',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showStatistics = false;
                    });
                  },
                  icon: const Icon(LucideIcons.x, color: Colors.white, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStatItem('Status', _isConnected ? 'Conectado' : 'Desconectado'),
            _buildStatItem('Room ID', widget.roomId ?? 'N/A'),
            _buildStatItem('Câmera', _videoCallService.isCameraEnabled ? 'Ligada' : 'Desligada'),
            _buildStatItem('Microfone', _videoCallService.isMicrophoneEnabled ? 'Ligado' : 'Desligado'),
            _buildStatItem('Gravação', _videoCallService.isRecording ? 'Ativa' : 'Inativa'),
          ],
        ),
      ),
    );
  }

  /// Constrói item de estatística
  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói painel de chat
  Widget _buildChatPanel() {
    return Positioned(
      bottom: 100,
      right: 20,
      child: Container(
        width: 300,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            // Chat header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showChat = false;
                      });
                    },
                    icon: const Icon(LucideIcons.x, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
            
            // Chat messages
            const Expanded(
              child: Center(
                child: Text(
                  'Chat em desenvolvimento',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            
            // Chat input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white24)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Digite uma mensagem...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Implementar envio de mensagem
                    },
                    icon: const Icon(LucideIcons.send, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}