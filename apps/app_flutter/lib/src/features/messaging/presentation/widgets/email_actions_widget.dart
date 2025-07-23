import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/core/theme/app_colors.dart';
import 'package:meu_app/src/core/services/unipile_service.dart';
import 'package:meu_app/src/features/messaging/presentation/bloc/unified_messaging_bloc.dart';
import 'package:meu_app/src/features/messaging/presentation/widgets/rich_email_composer_widget.dart';

/// Widget com ações para gerenciar emails seguindo melhores práticas de UI
/// Inclui reply, reply all, forward, delete, archive, mark as unread
class EmailActionsWidget extends StatelessWidget {
  final UnipileEmail email;
  final String accountId;
  final VoidCallback? onEmailUpdated;

  const EmailActionsWidget({
    super.key,
    required this.email,
    required this.accountId,
    this.onEmailUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: AppColors.outline.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          const SizedBox(height: 16),
          _buildEmailInfo(context),
          const SizedBox(height: 20),
          _buildPrimaryActions(context),
          const SizedBox(height: 12),
          _buildSecondaryActions(context),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.outline.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildEmailInfo(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(
            email.isRead ? LucideIcons.mailOpen : LucideIcons.mail,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                email.subject.isNotEmpty ? email.subject : 'Sem assunto',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'De: ${email.from}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: LucideIcons.reply,
            label: 'Responder',
            onPressed: () => _showReplyDialog(context, false),
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: LucideIcons.replyAll,
            label: 'Resp. Todos',
            onPressed: () => _showReplyDialog(context, true),
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: LucideIcons.forward,
            label: 'Encaminhar',
            onPressed: () => _showForwardDialog(context),
            isPrimary: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionChip(
          context: context,
          icon: LucideIcons.archive,
          label: 'Arquivar',
          onPressed: () => _archiveEmail(context),
        ),
        _buildActionChip(
          context: context,
          icon: LucideIcons.trash2,
          label: 'Excluir',
          onPressed: () => _showDeleteDialog(context),
          isDestructive: true,
        ),
        if (email.isRead)
          _buildActionChip(
            context: context,
            icon: LucideIcons.mailX,
            label: 'Marcar como não lida',
            onPressed: () => _markAsUnread(context),
          ),
        _buildActionChip(
          context: context,
          icon: LucideIcons.folder,
          label: 'Mover',
          onPressed: () => _showMoveDialog(context),
        ),
        _buildActionChip(
          context: context,
          icon: LucideIcons.edit,
          label: 'Criar rascunho',
          onPressed: () => _createFromTemplate(context),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return isPrimary
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          );
  }

  Widget _buildActionChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return ActionChip(
      onPressed: onPressed,
      avatar: Icon(
        icon,
        size: 16,
        color: isDestructive ? AppColors.error : AppColors.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.primary,
          fontSize: 12,
        ),
      ),
      backgroundColor: isDestructive
          ? AppColors.error.withOpacity(0.1)
          : AppColors.primary.withOpacity(0.1),
      side: BorderSide(
        color: isDestructive
            ? AppColors.error.withOpacity(0.3)
            : AppColors.primary.withOpacity(0.3),
      ),
    );
  }

  void _showReplyDialog(BuildContext context, bool replyAll) {
    Navigator.pop(context); // Fechar o bottom sheet atual
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RichEmailComposerWidget(
        initialTo: email.from,
        initialSubject: 'Re: ${email.subject}',
        initialBody: _generateReplyQuote(),
        replyToEmailId: email.id,
        isReply: true,
        isReplyAll: replyAll,
        onSent: (result) {
          Navigator.pop(context);
          onEmailUpdated?.call();
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  String _generateReplyQuote() {
    final date = email.receivedAt?.toString() ?? 'Data desconhecida';
    return '''
<br><br>
<div style="border-left: 2px solid #ccc; padding-left: 10px; margin: 10px 0;">
  <p><strong>Em ${date.split(' ')[0]}, ${email.from} escreveu:</strong></p>
  <p>${email.body}</p>
</div>
''';
  }

  void _showForwardDialog(BuildContext context) {
    final toController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encaminhar Email'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: toController,
                decoration: const InputDecoration(
                  labelText: 'Para',
                  hintText: 'destinatario@email.com',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Mensagem adicional (opcional)',
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
              if (toController.text.isNotEmpty) {
                Navigator.pop(context);
                // TODO: Implementar forward
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
                );
              }
            },
            child: const Text('Encaminhar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Email'),
        content: const Text('Deseja mover este email para a lixeira ou excluí-lo permanentemente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<UnifiedMessagingBloc>().add(
                    DeleteEmail(
                      emailId: email.id,
                      accountId: accountId,
                      permanent: false,
                    ),
                  );
              onEmailUpdated?.call();
            },
            child: const Text('Lixeira'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<UnifiedMessagingBloc>().add(
                    DeleteEmail(
                      emailId: email.id,
                      accountId: accountId,
                      permanent: true,
                    ),
                  );
              onEmailUpdated?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _archiveEmail(BuildContext context) {
    context.read<UnifiedMessagingBloc>().add(
          ArchiveEmail(
            emailId: email.id,
            accountId: accountId,
          ),
        );
    onEmailUpdated?.call();
    Navigator.pop(context);
  }

  void _markAsUnread(BuildContext context) {
    // TODO: Implementar marcar como não lida
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
    );
  }

  void _showMoveDialog(BuildContext context) {
    // TODO: Implementar dialog para mover entre pastas
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mover Email'),
        content: const Text('Selecione a pasta de destino:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _createFromTemplate(BuildContext context) {
    context.read<UnifiedMessagingBloc>().add(
          CreateEmailDraft(
            accountId: accountId,
            to: email.from,
            subject: 'Re: ${email.subject}',
            body: '\n\n--- Email original ---\n${email.body}',
          ),
        );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rascunho criado com base no email original'),
        backgroundColor: Colors.green,
      ),
    );
  }
}