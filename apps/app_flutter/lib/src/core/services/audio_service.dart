import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:meu_app/src/core/utils/logger.dart';

/// Serviço de áudio para gravação e reprodução de voice messages
/// Suporta gravação, reprodução, pausar, controle de velocidade
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  // Estado da gravação
  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentRecordingPath;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  
  // Estado da reprodução
  bool _isPlaying = false;
  String? _currentPlayingPath;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  
  // Streams para observar mudanças
  final StreamController<RecordingState> _recordingStateController = 
      StreamController<RecordingState>.broadcast();
  final StreamController<PlaybackState> _playbackStateController = 
      StreamController<PlaybackState>.broadcast();
  final StreamController<Duration> _recordingDurationController = 
      StreamController<Duration>.broadcast();

  // Getters para streams
  Stream<RecordingState> get recordingStateStream => _recordingStateController.stream;
  Stream<PlaybackState> get playbackStateStream => _playbackStateController.stream;
  Stream<Duration> get recordingDurationStream => _recordingDurationController.stream;

  // Getters para estado atual
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  Duration get recordingDuration => _recordingDuration;
  Duration get playbackPosition => _playbackPosition;
  Duration get playbackDuration => _playbackDuration;
  double get playbackSpeed => _playbackSpeed;

  /// Inicializa o serviço de áudio
  Future<void> initialize() async {
    try {
      // Configurar listeners do player
      _player.positionStream.listen((position) {
        _playbackPosition = position;
        _playbackStateController.add(PlaybackState(
          isPlaying: _isPlaying,
          position: position,
          duration: _playbackDuration,
          speed: _playbackSpeed,
        ));
      });

      _player.durationStream.listen((duration) {
        if (duration != null) {
          _playbackDuration = duration;
        }
      });

      _player.playerStateStream.listen((state) {
        _isPlaying = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _playbackPosition = Duration.zero;
        }
        _playbackStateController.add(PlaybackState(
          isPlaying: _isPlaying,
          position: _playbackPosition,
          duration: _playbackDuration,
          speed: _playbackSpeed,
        ));
      });

      AppLogger.success('AudioService inicializado com sucesso');
    } catch (e) {
      AppLogger.error('Erro ao inicializar AudioService', error: e);
    }
  }

  /// Solicita permissões de microfone
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      
      if (status == PermissionStatus.granted) {
        AppLogger.info('Permissão de microfone concedida');
        return true;
      } else if (status == PermissionStatus.permanentlyDenied) {
        AppLogger.warning('Permissão de microfone negada permanentemente');
        return false;
      } else {
        AppLogger.warning('Permissão de microfone negada');
        return false;
      }
    } catch (e) {
      AppLogger.error('Erro ao solicitar permissão de microfone', error: e);
      return false;
    }
  }

  /// Inicia gravação de áudio
  Future<bool> startRecording({String? customPath}) async {
    try {
      // Verificar permissões
      if (!await requestMicrophonePermission()) {
        throw Exception('Permissão de microfone necessária');
      }

      // Gerar caminho do arquivo
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customPath ?? 'voice_message_$timestamp.m4a';
      final filePath = '${directory.path}/$fileName';

      // Configurar gravação
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc, // Compatível com iOS e Android
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1, // Mono para economizar espaço
      );

      // Iniciar gravação
      await _recorder.start(config, path: filePath);
      
      _isRecording = true;
      _isPaused = false;
      _currentRecordingPath = filePath;
      _recordingDuration = Duration.zero;
      
      // Iniciar timer para duração
      _startRecordingTimer();
      
      // Notificar listeners
      _recordingStateController.add(RecordingState(
        isRecording: true,
        isPaused: false,
        duration: _recordingDuration,
        filePath: filePath,
      ));

      AppLogger.info('Gravação iniciada: $filePath');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao iniciar gravação', error: e);
      return false;
    }
  }

  /// Pausa gravação de áudio
  Future<bool> pauseRecording() async {
    try {
      if (!_isRecording || _isPaused) return false;

      await _recorder.pause();
      _isPaused = true;
      _recordingTimer?.cancel();
      
      _recordingStateController.add(RecordingState(
        isRecording: true,
        isPaused: true,
        duration: _recordingDuration,
        filePath: _currentRecordingPath,
      ));

      AppLogger.info('Gravação pausada');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao pausar gravação', error: e);
      return false;
    }
  }

  /// Resume gravação de áudio
  Future<bool> resumeRecording() async {
    try {
      if (!_isRecording || !_isPaused) return false;

      await _recorder.resume();
      _isPaused = false;
      _startRecordingTimer();
      
      _recordingStateController.add(RecordingState(
        isRecording: true,
        isPaused: false,
        duration: _recordingDuration,
        filePath: _currentRecordingPath,
      ));

      AppLogger.info('Gravação retomada');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao retomar gravação', error: e);
      return false;
    }
  }

  /// Para gravação e retorna o caminho do arquivo
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final filePath = await _recorder.stop();
      
      _isRecording = false;
      _isPaused = false;
      _recordingTimer?.cancel();
      
      _recordingStateController.add(RecordingState(
        isRecording: false,
        isPaused: false,
        duration: _recordingDuration,
        filePath: filePath,
      ));

      AppLogger.info('Gravação finalizada: $filePath');
      return filePath;
    } catch (e) {
      AppLogger.error('Erro ao finalizar gravação', error: e);
      return null;
    }
  }

  /// Cancela gravação e deleta arquivo
  Future<bool> cancelRecording() async {
    try {
      if (!_isRecording) return false;

      await _recorder.stop();
      
      // Tentar deletar arquivo
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      _isRecording = false;
      _isPaused = false;
      _recordingTimer?.cancel();
      _recordingDuration = Duration.zero;
      
      _recordingStateController.add(RecordingState(
        isRecording: false,
        isPaused: false,
        duration: Duration.zero,
        filePath: null,
      ));

      AppLogger.info('Gravação cancelada');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao cancelar gravação', error: e);
      return false;
    }
  }

  /// Reproduce áudio do caminho especificado
  Future<bool> playAudio(String filePath) async {
    try {
      // Parar reprodução atual se existir
      if (_isPlaying) {
        await stopPlayback();
      }

      // Configurar e iniciar reprodução
      await _player.setFilePath(filePath);
      await _player.play();
      
      _currentPlayingPath = filePath;
      _isPlaying = true;
      
      AppLogger.info('Reprodução iniciada: $filePath');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao reproduzir áudio', error: e);
      return false;
    }
  }

  /// Pausa reprodução
  Future<bool> pausePlayback() async {
    try {
      if (!_isPlaying) return false;

      await _player.pause();
      AppLogger.info('Reprodução pausada');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao pausar reprodução', error: e);
      return false;
    }
  }

  /// Resume reprodução
  Future<bool> resumePlayback() async {
    try {
      if (_isPlaying) return false;

      await _player.play();
      AppLogger.info('Reprodução retomada');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao retomar reprodução', error: e);
      return false;
    }
  }

  /// Para reprodução
  Future<bool> stopPlayback() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _playbackPosition = Duration.zero;
      _currentPlayingPath = null;
      
      AppLogger.info('Reprodução interrompida');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao parar reprodução', error: e);
      return false;
    }
  }

  /// Define velocidade de reprodução
  Future<bool> setPlaybackSpeed(double speed) async {
    try {
      if (speed < 0.5 || speed > 2.0) {
        throw ArgumentError('Velocidade deve estar entre 0.5 e 2.0');
      }

      await _player.setSpeed(speed);
      _playbackSpeed = speed;
      
      _playbackStateController.add(PlaybackState(
        isPlaying: _isPlaying,
        position: _playbackPosition,
        duration: _playbackDuration,
        speed: speed,
      ));

      AppLogger.info('Velocidade de reprodução alterada para ${speed}x');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao alterar velocidade', error: e);
      return false;
    }
  }

  /// Busca posição específica na reprodução
  Future<bool> seekTo(Duration position) async {
    try {
      await _player.seek(position);
      AppLogger.info('Posição alterada para ${position.inSeconds}s');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao buscar posição', error: e);
      return false;
    }
  }

  /// Inicia timer para contar duração da gravação
  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording && !_isPaused) {
        _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        _recordingDurationController.add(_recordingDuration);
        
        _recordingStateController.add(RecordingState(
          isRecording: true,
          isPaused: false,
          duration: _recordingDuration,
          filePath: _currentRecordingPath,
        ));
      }
    });
  }

  /// Obtém duração de um arquivo de áudio
  Future<Duration?> getAudioDuration(String filePath) async {
    try {
      final tempPlayer = AudioPlayer();
      await tempPlayer.setFilePath(filePath);
      final duration = tempPlayer.duration;
      await tempPlayer.dispose();
      return duration;
    } catch (e) {
      AppLogger.error('Erro ao obter duração do áudio', error: e);
      return null;
    }
  }

  /// Libera recursos
  Future<void> dispose() async {
    try {
      _recordingTimer?.cancel();
      await _recorder.dispose();
      await _player.dispose();
      await _recordingStateController.close();
      await _playbackStateController.close();
      await _recordingDurationController.close();
      
      AppLogger.info('AudioService resources disposed');
    } catch (e) {
      AppLogger.error('Erro ao liberar recursos do AudioService', error: e);
    }
  }
}

/// Estado da gravação
class RecordingState {
  final bool isRecording;
  final bool isPaused;
  final Duration duration;
  final String? filePath;

  const RecordingState({
    required this.isRecording,
    required this.isPaused,
    required this.duration,
    this.filePath,
  });

  @override
  String toString() {
    return 'RecordingState(isRecording: $isRecording, isPaused: $isPaused, duration: $duration, filePath: $filePath)';
  }
}

/// Estado da reprodução
class PlaybackState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double speed;

  const PlaybackState({
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.speed,
  });

  @override
  String toString() {
    return 'PlaybackState(isPlaying: $isPlaying, position: $position, duration: $duration, speed: $speed)';
  }
}