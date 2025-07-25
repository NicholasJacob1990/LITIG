import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/core/theme/app_colors.dart';
import 'package:meu_app/src/core/services/audio_service.dart';

/// Widget para gravação de voice messages com interface animada
/// Inclui visualização de waveform, controles de gravação e preview
class VoiceRecorderWidget extends StatefulWidget {
  final Function(String filePath, Duration duration)? onRecordingComplete;
  final VoidCallback? onCancel;
  final Color? primaryColor;
  final double? maxHeight;
  final bool showWaveform;

  const VoiceRecorderWidget({
    super.key,
    this.onRecordingComplete,
    this.onCancel,
    this.primaryColor,
    this.maxHeight = 200,
    this.showWaveform = true,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with TickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  RecordingState _recordingState = const RecordingState(
    isRecording: false,
    isPaused: false,
    duration: Duration.zero,
  );
  
  final List<double> _waveformData = [];
  final int _maxWaveformBars = 50;

  @override
  void initState() {
    super.initState();
    
    // Configurar animações
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    // Inicializar serviço de áudio
    _audioService.initialize();
    
    // Escutar mudanças no estado de gravação
    _audioService.recordingStateStream.listen((state) {
      setState(() {
        _recordingState = state;
      });
      
      if (state.isRecording && !state.isPaused) {
        _pulseController.repeat(reverse: true);
        _simulateWaveform();
      } else {
        _pulseController.stop();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? AppColors.primaryBlue;
    
    return Container(
      height: widget.maxHeight,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(primaryColor),
          const SizedBox(height: 20),
          if (widget.showWaveform) _buildWaveform(primaryColor),
          const Spacer(),
          _buildDurationDisplay(primaryColor),
          const SizedBox(height: 20),
          _buildControls(primaryColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Row(
      children: [
        Icon(
          LucideIcons.mic,
          color: primaryColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _recordingState.isRecording
                    ? (_recordingState.isPaused ? 'Gravação Pausada' : 'Gravando...')
                    : 'Gravar Mensagem de Voz',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              Text(
                _recordingState.isRecording
                    ? 'Toque para pausar ou finalizar'
                    : 'Toque no microfone para começar',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (_recordingState.isRecording)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'REC',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWaveform(Color primaryColor) {
    return Container(
      height: 60,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_maxWaveformBars, (index) {
          final height = _waveformData.length > index 
              ? _waveformData[index] * 50 
              : 2.0;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 2,
            height: height.clamp(2.0, 50.0),
            decoration: BoxDecoration(
              color: _recordingState.isRecording && !_recordingState.isPaused
                  ? primaryColor
                  : primaryColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDurationDisplay(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatDuration(_recordingState.duration),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: primaryColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildControls(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Botão Cancelar
        if (_recordingState.isRecording)
          _buildControlButton(
            icon: LucideIcons.x,
            color: Colors.red,
            onPressed: _cancelRecording,
            tooltip: 'Cancelar',
          )
        else
          const SizedBox(width: 50),
        
        // Botão principal (Gravar/Pausar/Retomar)
        GestureDetector(
          onTapDown: (_) => _scaleController.forward(),
          onTapUp: (_) => _scaleController.reverse(),
          onTapCancel: () => _scaleController.reverse(),
          onTap: _handleMainAction,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value * 
                       (_recordingState.isRecording && !_recordingState.isPaused 
                        ? _pulseAnimation.value 
                        : 1.0),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _recordingState.isRecording && !_recordingState.isPaused
                        ? Colors.red
                        : primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_recordingState.isRecording && !_recordingState.isPaused
                            ? Colors.red
                            : primaryColor).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getMainActionIcon(),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              );
            },
          ),
        ),
        
        // Botão Finalizar
        if (_recordingState.isRecording)
          _buildControlButton(
            icon: LucideIcons.check,
            color: Colors.green,
            onPressed: _stopRecording,
            tooltip: 'Finalizar',
          )
        else
          const SizedBox(width: 50),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }

  IconData _getMainActionIcon() {
    if (!_recordingState.isRecording) {
      return LucideIcons.mic;
    } else if (_recordingState.isPaused) {
      return LucideIcons.play;
    } else {
      return LucideIcons.pause;
    }
  }

  void _handleMainAction() {
    if (!_recordingState.isRecording) {
      _startRecording();
    } else if (_recordingState.isPaused) {
      _resumeRecording();
    } else {
      _pauseRecording();
    }
  }

  Future<void> _startRecording() async {
    final success = await _audioService.startRecording();
    if (!success) {
      _showError('Erro ao iniciar gravação');
    }
  }

  Future<void> _pauseRecording() async {
    final success = await _audioService.pauseRecording();
    if (!success) {
      _showError('Erro ao pausar gravação');
    }
  }

  Future<void> _resumeRecording() async {
    final success = await _audioService.resumeRecording();
    if (!success) {
      _showError('Erro ao retomar gravação');
    }
  }

  Future<void> _stopRecording() async {
    final filePath = await _audioService.stopRecording();
    if (filePath != null) {
      widget.onRecordingComplete?.call(filePath, _recordingState.duration);
    } else {
      _showError('Erro ao finalizar gravação');
    }
  }

  Future<void> _cancelRecording() async {
    final success = await _audioService.cancelRecording();
    if (success) {
      widget.onCancel?.call();
    } else {
      _showError('Erro ao cancelar gravação');
    }
  }

  void _simulateWaveform() {
    // Simular dados de waveform (em uma implementação real, seria obtido do microfone)
    if (_recordingState.isRecording && !_recordingState.isPaused) {
      setState(() {
        final random = Random();
        final newValue = 0.1 + random.nextDouble() * 0.9;
        
        if (_waveformData.length >= _maxWaveformBars) {
          _waveformData.removeAt(0);
        }
        _waveformData.add(newValue);
      });
      
      // Agendar próxima atualização
      Future.delayed(const Duration(milliseconds: 100), _simulateWaveform);
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