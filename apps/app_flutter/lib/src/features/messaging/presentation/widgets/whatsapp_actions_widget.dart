import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/core/theme/app_colors.dart';
import 'package:meu_app/src/features/messaging/presentation/bloc/unified_messaging_bloc.dart';
import 'package:meu_app/src/shared/widgets/voice_recorder_widget.dart';

/// Widget com ações específicas do WhatsApp Business seguindo melhores práticas de UI
/// Inclui mensagens rápidas, status, catálogo e ações de negócio
class WhatsAppActionsWidget extends StatelessWidget {
  final String accountId;

  const WhatsAppActionsWidget({
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
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildQuickActions(context),
          const SizedBox(height: 16),
          _buildBusinessActions(context),
          const SizedBox(height: 16),
          _buildClientActions(context),
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
            color: const Color(0xFF25D366).withValues(alpha: 0.1), // WhatsApp green
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            LucideIcons.messageCircle,
            color: Color(0xFF25D366),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ações WhatsApp',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Comunicação direta e negócios',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.6),
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
            color: AppColors.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context: context,
                icon: LucideIcons.messageCircle,
                title: 'Mensagem',
                subtitle: 'Enviar texto',
                color: const Color(0xFF25D366),
                onTap: () => _showQuickMessageDialog(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context: context,
                icon: LucideIcons.mic,
                title: 'Áudio',
                subtitle: 'Gravar voz',
                color: Colors.blue,
                onTap: () => _showVoiceMessageDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBusinessActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Negócios',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildBusinessChip(
              context: context,
              icon: LucideIcons.package,
              label: 'Catálogo',
              onPressed: () => _showCatalogDialog(context),
            ),
            _buildBusinessChip(
              context: context,
              icon: LucideIcons.shoppingCart,
              label: 'Pedido',
              onPressed: () => _showOrderDialog(context),
            ),
            _buildBusinessChip(
              context: context,
              icon: LucideIcons.calendar,
              label: 'Agendar',
              onPressed: () => _showScheduleDialog(context),
            ),
            _buildBusinessChip(
              context: context,
              icon: LucideIcons.creditCard,
              label: 'Pagamento',
              onPressed: () => _showPaymentDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClientActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Serviços',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildServiceChip(
              context: context,
              icon: LucideIcons.fileText,
              label: 'Consultoria',
              onPressed: () => _showConsultationDialog(context),
            ),
            _buildServiceChip(
              context: context,
              icon: LucideIcons.users,
              label: 'Reunião',
              onPressed: () => _showMeetingDialog(context),
            ),
            _buildServiceChip(
              context: context,
              icon: LucideIcons.fileCheck,
              label: 'Documentos',
              onPressed: () => _showDocumentsDialog(context),
            ),
            _buildServiceChip(
              context: context,
              icon: LucideIcons.helpCircle,
              label: 'Suporte',
              onPressed: () => _showSupportDialog(context),
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
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
                color: AppColors.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessChip({
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
        color: const Color(0xFF25D366),
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF25D366),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.1),
      side: const BorderSide(
        color: Color(0xFF25D366),
        width: 0.5,
      ),
    );
  }

  Widget _buildServiceChip({
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
        color: Colors.blue,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.blue.withValues(alpha: 0.1),
      side: const BorderSide(
        color: Colors.blue,
        width: 0.5,
      ),
    );
  }

  // ===== DIALOGS E AÇÕES =====

  void _showQuickMessageDialog(BuildContext context) {
    final messageController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar Mensagem WhatsApp'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Número do WhatsApp',
                  hintText: '+55 11 99999-9999',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Mensagem',
                  hintText: 'Digite sua mensagem...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (phoneController.text.isNotEmpty && messageController.text.isNotEmpty) {
                Navigator.pop(context);
                _sendWhatsAppMessage(context, phoneController.text, messageController.text);
              }
            },
            icon: const Icon(LucideIcons.send, size: 16),
            label: const Text('Enviar'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
            ),
          ),
        ],
      ),
    );
  }

  void _showVoiceMessageDialog(BuildContext context) {
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
          primaryColor: const Color(0xFF25D366),
          onRecordingComplete: (filePath, duration) {
            Navigator.pop(context);
            _sendVoiceMessage(context, filePath, duration);
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _sendWhatsAppMessage(BuildContext context, String phone, String message) {
    context.read<UnifiedMessagingBloc>().add(
      SendWhatsAppMessage(
        accountId: accountId,
        phone: phone,
        message: message,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.messageCircle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Mensagem enviada para $phone'),
          ],
        ),
        backgroundColor: const Color(0xFF25D366),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendVoiceMessage(BuildContext context, String filePath, Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.mic, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Áudio gravado (${_formatDuration(duration)}) - Envio em desenvolvimento'),
          ],
        ),
        backgroundColor: const Color(0xFF25D366),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ===== DIALOGS DE NEGÓCIO =====

  void _showCatalogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Catálogo de Serviços'),
        content: const Text('Funcionalidade de catálogo será implementada em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Pedido'),
        content: const Text('Funcionalidade de pedidos será implementada em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agendar Consulta'),
        content: const Text('Funcionalidade de agendamento será implementada em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pagamento'),
        content: const Text('Funcionalidade de pagamento será implementada em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ===== DIALOGS DE SERVIÇOS =====

  void _showConsultationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Consultoria'),
        content: const Text('Funcionalidade de consultoria será implementada em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMeetingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agendar Reunião'),
        content: const Text('Funcionalidade de reunião será implementada em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDocumentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar Documentos'),
        content: const Text('Funcionalidade de documentos será implementada em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suporte'),
        content: const Text('Funcionalidade de suporte será implementada em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}


