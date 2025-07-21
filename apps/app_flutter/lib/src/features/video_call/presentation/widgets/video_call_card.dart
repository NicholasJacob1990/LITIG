import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/video_call_room.dart';

class VideoCallCard extends StatelessWidget {
  final VideoCallRoom room;
  final VoidCallback? onJoin;
  final VoidCallback? onEnd;

  const VideoCallCard({
    super.key,
    required this.room,
    this.onJoin,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(room.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(room.status),
                    color: _getStatusColor(room.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Videochamada',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        room.roomName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(room.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(room.status),
                    style: TextStyle(
                      color: _getStatusColor(room.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Room details
            _buildDetailRow(
              icon: LucideIcons.users,
              label: 'Participantes',
              value: '${room.participants.length} pessoa(s)',
            ),
            
            _buildDetailRow(
              icon: LucideIcons.clock,
              label: 'Criada em',
              value: _formatDateTime(room.createdAt),
            ),
            
            if (room.joinedAt != null)
              _buildDetailRow(
                icon: LucideIcons.play,
                label: 'Iniciada em',
                value: _formatDateTime(room.joinedAt!),
              ),
            
            if (room.endedAt != null)
              _buildDetailRow(
                icon: LucideIcons.stopCircle,
                label: 'Encerrada em',
                value: _formatDateTime(room.endedAt!),
              ),
            
            if (room.durationMinutes > 0)
              _buildDetailRow(
                icon: LucideIcons.timer,
                label: 'Duração',
                value: '${room.durationMinutes} minutos',
              ),
            
            if (!room.isEnded && !room.isExpired)
              _buildDetailRow(
                icon: LucideIcons.calendar,
                label: 'Expira em',
                value: _formatDateTime(room.expiresAt),
              ),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                if (room.canJoin) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _joinCall(context),
                      icon: const Icon(LucideIcons.video),
                      label: const Text('Entrar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                if (room.isActive) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onEnd,
                      icon: const Icon(LucideIcons.phoneOff),
                      label: const Text('Encerrar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                OutlinedButton.icon(
                  onPressed: () => _showRoomDetails(context),
                  icon: const Icon(LucideIcons.info),
                  label: const Text('Detalhes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'created':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'ended':
        return Colors.grey;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'created':
        return LucideIcons.clock;
      case 'active':
        return LucideIcons.video;
      case 'ended':
        return LucideIcons.checkCircle;
      case 'expired':
        return LucideIcons.alertTriangle;
      default:
        return LucideIcons.helpCircle;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'created':
        return 'Aguardando';
      case 'active':
        return 'Ativa';
      case 'ended':
        return 'Encerrada';
      case 'expired':
        return 'Expirada';
      default:
        return 'Desconhecido';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _joinCall(BuildContext context) {
    context.push('/video-call/${room.roomName}', extra: {
      'roomUrl': room.roomUrl,
      'userId': 'current_user', // TODO: Usar ID do usuário atual
      'otherPartyName': 'Outro participante',
    });
  }

  void _showRoomDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes da Videochamada'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                icon: LucideIcons.hash,
                label: 'ID',
                value: room.id,
              ),
              _buildDetailRow(
                icon: LucideIcons.tag,
                label: 'Nome da Sala',
                value: room.roomName,
              ),
              _buildDetailRow(
                icon: LucideIcons.link,
                label: 'URL',
                value: room.roomUrl,
              ),
              _buildDetailRow(
                icon: LucideIcons.briefcase,
                label: 'Caso',
                value: room.caseId,
              ),
              _buildDetailRow(
                icon: LucideIcons.users,
                label: 'Cliente',
                value: room.clientId,
              ),
              _buildDetailRow(
                icon: LucideIcons.user,
                label: 'Advogado',
                value: room.lawyerId,
              ),
              if (room.recordingUrl != null)
                _buildDetailRow(
                  icon: LucideIcons.video,
                  label: 'Gravação',
                  value: 'Disponível',
                ),
            ],
          ),
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