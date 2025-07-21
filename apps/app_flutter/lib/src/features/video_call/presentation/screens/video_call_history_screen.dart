import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/video_call_bloc.dart';
import 'package:meu_app/injection_container.dart';

class VideoCallHistoryScreen extends StatefulWidget {
  const VideoCallHistoryScreen({super.key});

  @override
  State<VideoCallHistoryScreen> createState() => _VideoCallHistoryScreenState();
}

class _VideoCallHistoryScreenState extends State<VideoCallHistoryScreen> {
  late VideoCallBloc _videoCallBloc;

  @override
  void initState() {
    super.initState();
    _videoCallBloc = getIt<VideoCallBloc>();
    // TODO: Carregar histórico de videochamadas
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _videoCallBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Histórico de Videochamadas'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        body: BlocBuilder<VideoCallBloc, VideoCallState>(
          builder: (context, state) {
            if (state is VideoCallLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is VideoCallError) {
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
                      'Erro ao carregar histórico',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Recarregar histórico
                      },
                      icon: const Icon(LucideIcons.refreshCw),
                      label: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              );
            }
            
            // TODO: Implementar estado com lista de videochamadas
            return _buildEmptyState();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.video,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma videochamada encontrada',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suas videochamadas aparecerão aqui',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}