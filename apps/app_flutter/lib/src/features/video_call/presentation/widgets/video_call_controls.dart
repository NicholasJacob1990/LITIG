import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class VideoCallControls extends StatefulWidget {
  final VoidCallback onEndCall;
  final VoidCallback onToggleCamera;
  final VoidCallback onToggleMicrophone;
  final bool isCameraEnabled;
  final bool isMicrophoneEnabled;

  const VideoCallControls({
    super.key,
    required this.onEndCall,
    required this.onToggleCamera,
    required this.onToggleMicrophone,
    this.isCameraEnabled = true,
    this.isMicrophoneEnabled = true,
  });

  @override
  State<VideoCallControls> createState() => _VideoCallControlsState();
}

class _VideoCallControlsState extends State<VideoCallControls> {
  bool _isCameraEnabled = true;
  bool _isMicrophoneEnabled = true;

  @override
  void initState() {
    super.initState();
    _isCameraEnabled = widget.isCameraEnabled;
    _isMicrophoneEnabled = widget.isMicrophoneEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Botão do microfone
            _buildControlButton(
              icon: _isMicrophoneEnabled ? LucideIcons.mic : LucideIcons.micOff,
              isEnabled: _isMicrophoneEnabled,
              onPressed: () {
                setState(() {
                  _isMicrophoneEnabled = !_isMicrophoneEnabled;
                });
                widget.onToggleMicrophone();
              },
              tooltip: _isMicrophoneEnabled ? 'Silenciar' : 'Ativar microfone',
            ),
            
            // Botão da câmera
            _buildControlButton(
              icon: _isCameraEnabled ? LucideIcons.video : LucideIcons.videoOff,
              isEnabled: _isCameraEnabled,
              onPressed: () {
                setState(() {
                  _isCameraEnabled = !_isCameraEnabled;
                });
                widget.onToggleCamera();
              },
              tooltip: _isCameraEnabled ? 'Desligar câmera' : 'Ligar câmera',
            ),
            
            // Botão de chat
            _buildControlButton(
              icon: LucideIcons.messageCircle,
              isEnabled: true,
              onPressed: () {
                _showChatDialog(context);
              },
              tooltip: 'Chat',
            ),
            
            // Botão de compartilhar tela
            _buildControlButton(
              icon: LucideIcons.monitor,
              isEnabled: true,
              onPressed: () {
                _showFeatureNotAvailable(context, 'Compartilhamento de tela');
              },
              tooltip: 'Compartilhar tela',
            ),
            
            // Botão de encerrar chamada
            _buildControlButton(
              icon: LucideIcons.phoneOff,
              isEnabled: true,
              onPressed: widget.onEndCall,
              tooltip: 'Encerrar chamada',
              backgroundColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onPressed,
    required String tooltip,
    Color? backgroundColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor ?? 
                 (isEnabled ? Colors.white.withOpacity(0.2) : Colors.red.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _showChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat'),
        content: const Text('Funcionalidade de chat em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showFeatureNotAvailable(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature estará disponível em breve'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}