import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/core/theme/app_colors.dart';
import 'package:meu_app/src/features/messaging/presentation/bloc/unified_messaging_bloc.dart';
import 'package:meu_app/src/features/messaging/presentation/widgets/rich_inmail_composer_widget.dart';
import 'package:meu_app/src/shared/widgets/voice_recorder_widget.dart';

/// Widget com ações específicas do LinkedIn seguindo melhores práticas de UI
/// Inclui InMail, convites, voice notes e interações com posts
class LinkedInActionsWidget extends StatelessWidget {
  final String accountId;

  const LinkedInActionsWidget({
    super.key,
    required this.accountId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildQuickActions(context),
          const SizedBox(height: 16),
          _buildNetworkingActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0077B5).withOpacity(0.1), // LinkedIn blue
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            LucideIcons.linkedin,
            color: Color(0xFF0077B5),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ações LinkedIn',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Networking profissional e comunicação',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context: context,
                icon: LucideIcons.mail,
                title: 'InMail',
                subtitle: 'Mensagem direta',
                color: const Color(0xFF0077B5),
                onTap: () => _showInMailDialog(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context: context,
                icon: LucideIcons.userPlus,
                title: 'Convite',
                subtitle: 'Conectar-se',
                color: Colors.green,
                onTap: () => _showInvitationDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNetworkingActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Networking Avançado',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildNetworkingChip(
              context: context,
              icon: LucideIcons.mic,
              label: 'Nota de Voz',
              onPressed: () => _showVoiceNoteDialog(context),
            ),
            _buildNetworkingChip(
              context: context,
              icon: LucideIcons.messageCircle,
              label: 'Comentar Post',
              onPressed: () => _showCommentDialog(context),
            ),
            _buildNetworkingChip(
              context: context,
              icon: LucideIcons.users,
              label: 'Ver Conexões',
              onPressed: () => _viewConnections(context),
            ),
            _buildNetworkingChip(
              context: context,
              icon: LucideIcons.building,
              label: 'Empresa',
              onPressed: () => _viewCompanyProfile(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkingChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ActionChip(
      onPressed: onPressed,
      avatar: Icon(
        icon,
        size: 16,
        color: const Color(0xFF0077B5),
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0077B5),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: const Color(0xFF0077B5).withOpacity(0.1),
      side: const BorderSide(
        color: Color(0xFF0077B5),
        width: 0.5,
      ),
    );
  }

  void _showInMailDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RichInMailComposerWidget(
        accountId: accountId,
        onSent: (result) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'InMail enviado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showInvitationDialog(BuildContext context) {
    final userIdController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.userPlus,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Enviar Convite',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: userIdController,
                decoration: const InputDecoration(
                  labelText: 'ID do usuário',
                  hintText: 'Ex: john-doe-123456',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.user),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Mensagem personalizada (opcional)',
                  hintText: 'Olá! Gostaria de me conectar...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      if (userIdController.text.isNotEmpty) {
                        Navigator.pop(context);
                        context.read<UnifiedMessagingBloc>().add(
                              SendLinkedInInvitation(
                                accountId: accountId,
                                userId: userIdController.text,
                                message: messageController.text.isEmpty 
                                    ? null 
                                    : messageController.text,
                              ),
                            );
                      }
                    },
                    icon: const Icon(LucideIcons.send, size: 16),
                    label: const Text('Enviar Convite'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVoiceNoteDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
        ),
        child: VoiceRecorderWidget(
          primaryColor: const Color(0xFF0077B5),
          onRecordingComplete: (filePath, duration) {
            Navigator.pop(context);
            _sendVoiceNote(context, filePath, duration);
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _sendVoiceNote(BuildContext context, String filePath, Duration duration) {
    // TODO: Implementar envio de voice note via LinkedIn
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.mic, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Nota de voz gravada (${_formatDuration(duration)}) - Envio em desenvolvimento'),
          ],
        ),
        backgroundColor: const Color(0xFF0077B5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showCommentDialog(BuildContext context) {
    final postIdController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comentar em Post'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: postIdController,
                decoration: const InputDecoration(
                  labelText: 'ID do post',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Comentário',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (postIdController.text.isNotEmpty && 
                  commentController.text.isNotEmpty) {
                Navigator.pop(context);
                // TODO: Implementar comentário em post
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
                );
              }
            },
            child: const Text('Comentar'),
          ),
        ],
      ),
    );
  }

  void _viewConnections(BuildContext context) {
    // TODO: Navegar para tela de conexões
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
    );
  }

  void _viewCompanyProfile(BuildContext context) {
    // TODO: Navegar para perfil da empresa
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
    );
  }
}