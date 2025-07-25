import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/core/theme/app_colors.dart';
import 'package:meu_app/src/core/services/audio_service.dart';

/// Widget para reprodução de voice messages
/// Inclui controles de play/pause, progresso, velocidade e waveform
class VoiceMessagePlayerWidget extends StatefulWidget {
  final String filePath;
  final Duration? duration;
  final bool isSentByMe;
  final Color? primaryColor;
  final VoidCallback? onPlaybackComplete;
  final bool showTimestamp;
  final DateTime? timestamp;

  const VoiceMessagePlayerWidget({
    super.key,
    required this.filePath,
    this.duration,
    this.isSentByMe = false,
    this.primaryColor,
    this.onPlaybackComplete,
    this.showTimestamp = true,
    this.timestamp,
  });

  @override
  State<VoiceMessagePlayerWidget> createState() => _VoiceMessagePlayerWidgetState();
}

class _VoiceMessagePlayerWidgetState extends State<VoiceMessagePlayerWidget>
    with TickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  
  late AnimationController _waveAnimationController;
  late Animation<double> _waveAnimation;
  
  PlaybackState _playbackState = const PlaybackState(
    isPlaying: false,
    position: Duration.zero,
    duration: Duration.zero,
    speed: 1.0,
  );
  
  Duration? _audioDuration;
  bool _isCurrentlyPlaying = false;

  @override
  void initState() {
    super.initState();
    
    // Configurar animação de waveform
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _waveAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _waveAnimationController, curve: Curves.easeInOut),
    );
    
    // Inicializar serviço de áudio
    _audioService.initialize();
    
    // Obter duração do arquivo
    _loadAudioDuration();
    
    // Escutar mudanças no estado de reprodução
    _audioService.playbackStateStream.listen((state) {
      setState(() {
        _playbackState = state;
        _isCurrentlyPlaying = state.isPlaying;
      });
      
      if (state.isPlaying) {
        _waveAnimationController.repeat(reverse: true);
      } else {
        _waveAnimationController.stop();
        _waveAnimationController.reset();
        
        // Verificar se reprodução foi completada
        if (state.position >= state.duration && state.duration > Duration.zero) {
          widget.onPlaybackComplete?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadAudioDuration() async {
    if (widget.duration != null) {
      _audioDuration = widget.duration;
      return;
    }
    
    final duration = await _audioService.getAudioDuration(widget.filePath);
    if (mounted) {
      setState(() {
        _audioDuration = duration;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? 
        (widget.isSentByMe ? AppColors.primaryBlue : Colors.grey[600]!);
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: widget.isSentByMe 
            ? AppColors.primaryBlue.withValues(alpha: 0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isSentByMe 
              ? AppColors.primaryBlue.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPlayButton(primaryColor),
              const SizedBox(width: 12),
              Expanded(child: _buildWaveformAndProgress(primaryColor)),
              const SizedBox(width: 8),
              _buildDurationText(primaryColor),
            ],
          ),
          if (widget.showTimestamp && widget.timestamp != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildTimestamp(),
            ),
          if (_isCurrentlyPlaying)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildPlaybackControls(primaryColor),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(Color primaryColor) {
    return GestureDetector(
      onTap: _togglePlayback,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _isCurrentlyPlaying ? primaryColor : primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: primaryColor,
            width: _isCurrentlyPlaying ? 0 : 1.5,
          ),
        ),
        child: Icon(
          _isCurrentlyPlaying ? LucideIcons.pause : LucideIcons.play,
          color: _isCurrentlyPlaying ? Colors.white : primaryColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildWaveformAndProgress(Color primaryColor) {
    return Column(
      children: [
        // Waveform animado
        SizedBox(
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(20, (index) {
              final progress = _audioDuration != null && _audioDuration! > Duration.zero
                  ? _playbackState.position.inMilliseconds / _audioDuration!.inMilliseconds
                  : 0.0;
              
              final isActive = (index / 20) <= progress;
              
              return AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  final baseHeight = 4.0 + (index % 3) * 8.0;
                  final animatedHeight = _isCurrentlyPlaying && isActive
                      ? baseHeight * _waveAnimation.value
                      : baseHeight * 0.3;
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 2,
                    height: animatedHeight.clamp(2.0, 24.0),
                    decoration: BoxDecoration(
                      color: isActive 
                          ? primaryColor
                          : primaryColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                },
              );
            }),
          ),
        ),
        // Barra de progresso fina
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: _audioDuration != null && _audioDuration! > Duration.zero
              ? _playbackState.position.inMilliseconds / _audioDuration!.inMilliseconds
              : 0.0,
          backgroundColor: primaryColor.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          minHeight: 2,
        ),
      ],
    );
  }

  Widget _buildDurationText(Color primaryColor) {
    final displayDuration = _isCurrentlyPlaying 
        ? _playbackState.position
        : (_audioDuration ?? Duration.zero);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatDuration(displayDuration),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: primaryColor,
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (_audioDuration != null && _isCurrentlyPlaying)
          Text(
            '/ ${_formatDuration(_audioDuration!)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: primaryColor.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
      ],
    );
  }

  Widget _buildTimestamp() {
    final timestamp = widget.timestamp!;
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    String timeText;
    if (difference.inDays > 0) {
      timeText = '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      timeText = '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      timeText = '${difference.inMinutes}min atrás';
    } else {
      timeText = 'Agora';
    }
    
    return Text(
      timeText,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Colors.grey[600],
        fontSize: 11,
      ),
    );
  }

  Widget _buildPlaybackControls(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Controle de velocidade
        GestureDetector(
          onTap: _cyclePlaybackSpeed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${_playbackState.speed}x',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        // Controle de posição (seek)
        Expanded(
          child: Slider(
            value: _audioDuration != null && _audioDuration! > Duration.zero
                ? _playbackState.position.inMilliseconds / _audioDuration!.inMilliseconds
                : 0.0,
            onChanged: _onSeekChanged,
            activeColor: primaryColor,
            inactiveColor: primaryColor.withValues(alpha: 0.3),
            thumbColor: primaryColor,
          ),
        ),
        
        // Botão de parar
        GestureDetector(
          onTap: _stopPlayback,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              LucideIcons.square,
              color: Colors.red,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _togglePlayback() async {
    if (!File(widget.filePath).existsSync()) {
      _showError('Arquivo de áudio não encontrado');
      return;
    }
    
    if (_isCurrentlyPlaying) {
      await _audioService.pausePlayback();
    } else {
      await _audioService.playAudio(widget.filePath);
    }
  }

  Future<void> _stopPlayback() async {
    await _audioService.stopPlayback();
  }

  Future<void> _cyclePlaybackSpeed() async {
    double newSpeed;
    switch (_playbackState.speed) {
      case 1.0:
        newSpeed = 1.25;
        break;
      case 1.25:
        newSpeed = 1.5;
        break;
      case 1.5:
        newSpeed = 2.0;
        break;
      case 2.0:
        newSpeed = 0.75;
        break;
      case 0.75:
        newSpeed = 0.5;
        break;
      default:
        newSpeed = 1.0;
    }
    
    await _audioService.setPlaybackSpeed(newSpeed);
  }

  void _onSeekChanged(double value) {
    if (_audioDuration != null) {
      final newPosition = Duration(
        milliseconds: (value * _audioDuration!.inMilliseconds).round(),
      );
      _audioService.seekTo(newPosition);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}