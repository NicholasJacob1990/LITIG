import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:daily_flutter/daily_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/video_call_bloc.dart';
import '../widgets/video_call_controls.dart';
import '../widgets/video_call_waiting_room.dart';
import '../../../../injection_container.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomName;
  final String roomUrl;
  final String userId;
  final String? otherPartyName;

  const VideoCallScreen({
    super.key,
    required this.roomName,
    required this.roomUrl,
    required this.userId,
    this.otherPartyName,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late VideoCallBloc _videoCallBloc;

  @override
  void initState() {
    super.initState();
    _videoCallBloc = getIt<VideoCallBloc>();
    
    // Entrar na sala automaticamente
    _videoCallBloc.add(JoinVideoCallRoomEvent(
      roomName: widget.roomName,
      roomUrl: widget.roomUrl,
      userId: widget.userId,
    ));
  }

  @override
  void dispose() {
    _videoCallBloc.add(const EndVideoCallEvent());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _videoCallBloc,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.otherPartyName ?? 'Videochamada'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () {
                _showCallInfo(context);
              },
              icon: const Icon(LucideIcons.info),
            ),
          ],
        ),
        body: BlocConsumer<VideoCallBloc, VideoCallState>(
          listener: (context, state) {
            if (state is VideoCallError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is VideoCallEnded) {
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            if (state is VideoCallLoading) {
              return const VideoCallWaitingRoom();
            }
            
            if (state is VideoCallError) {
              return _buildErrorView(state.message);
            }
            
            if (state is VideoCallJoined) {
              return _buildVideoCallView(state);
            }
            
            return const VideoCallWaitingRoom();
          },
        ),
      ),
    );
  }

  Widget _buildVideoCallView(VideoCallJoined state) {
    return Stack(
      children: [
        // Vídeo principal
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: const Center(
              child: Text(
                'Daily.co Video Widget\n(Implementar DailyCallWidget)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        
        // Controles da videochamada
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoCallControls(
            onEndCall: () {
              _videoCallBloc.add(const EndVideoCallEvent());
            },
            onToggleCamera: () {
              _videoCallBloc.add(const ToggleCameraEvent());
            },
            onToggleMicrophone: () {
              _videoCallBloc.add(const ToggleMicrophoneEvent());
            },
          ),
        ),
        
        // Vídeo próprio (picture-in-picture)
        Positioned(
          top: 80,
          right: 16,
          child: Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.user,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro na videochamada',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[300],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(LucideIcons.arrowLeft),
            label: const Text('Voltar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showCallInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações da Chamada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sala: ${widget.roomName}'),
            const SizedBox(height: 8),
            Text('URL: ${widget.roomUrl}'),
            const SizedBox(height: 8),
            Text('Usuário: ${widget.userId}'),
            if (widget.otherPartyName != null) ...[
              const SizedBox(height: 8),
              Text('Conversa com: ${widget.otherPartyName}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}