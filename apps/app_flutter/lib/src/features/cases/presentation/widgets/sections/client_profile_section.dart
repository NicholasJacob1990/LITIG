import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/client_info.dart';
import '../../../../../shared/utils/app_colors.dart';
import '../../../../../shared/widgets/atoms/initials_avatar.dart';

/// Seção de perfil do cliente na visão do advogado
/// Contraparte exata da LawyerResponsibleSection
/// Garante simetria de informações: se cliente vê dados ricos do advogado, 
/// advogado deve ver dados ricos do cliente
class ClientProfileSection extends StatelessWidget {
  final ClientInfo clientInfo;
  final String? matchContext;
  final VoidCallback? onContactClient;
  final VoidCallback? onViewClientHistory;

  const ClientProfileSection({
    super.key,
    required this.clientInfo,
    this.matchContext,
    this.onContactClient,
    this.onViewClientHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(theme),
            const SizedBox(height: 16),
            _buildClientHeader(theme),
            const SizedBox(height: 16),
            _buildClientMetrics(theme),
            const SizedBox(height: 16),
            _buildClientDetails(theme),
            if (matchContext != null) ...[
              const SizedBox(height: 16),
              _buildMatchContext(theme),
            ],
            const SizedBox(height: 20),
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            clientInfo.isCorporate ? LucideIcons.building2 : LucideIcons.user,
            color: AppColors.primaryBlue,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perfil do Cliente',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                clientInfo.isCorporate ? 'Pessoa Jurídica' : 'Pessoa Física',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(theme),
      ],
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    Color statusColor;
    String statusText;

    switch (clientInfo.status) {
      case ClientStatus.vip:
        statusColor = Colors.purple;
        statusText = 'VIP';
        break;
      case ClientStatus.active:
        statusColor = Colors.green;
        statusText = 'Ativo';
        break;
      case ClientStatus.potential:
        statusColor = Colors.blue;
        statusText = 'Potencial';
        break;
      case ClientStatus.problematic:
        statusColor = Colors.orange;
        statusText = 'Atenção';
        break;
      case ClientStatus.returning:
        statusColor = Colors.teal;
        statusText = 'Recorrente';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildClientHeader(ThemeData theme) {
    return Row(
      children: [
        // Avatar do cliente (equivalente ao do advogado)
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
            child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
              child: clientInfo.avatarUrl != null && clientInfo.avatarUrl!.isNotEmpty
                  ? CachedNetworkImage(
                    imageUrl: clientInfo.avatarUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => InitialsAvatar(
                      text: clientInfo.name,
                      radius: 30,
                    ),
                  )
                : InitialsAvatar(
                    text: clientInfo.name,
                    radius: 30,
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clientInfo.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (clientInfo.company != null) ...[
                Text(
                  clientInfo.company!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  Icon(
                    LucideIcons.mail,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      clientInfo.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    LucideIcons.phone,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    clientInfo.phone,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClientMetrics(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildMetricItem(
                theme,
                icon: LucideIcons.star,
                label: 'Rating',
                value: clientInfo.averageRating.toStringAsFixed(1),
                color: Colors.amber,
              ),
              _buildMetricItem(
                theme,
                icon: LucideIcons.briefcase,
                label: 'Casos',
                value: clientInfo.previousCases.toString(),
                color: AppColors.primaryBlue,
              ),
              _buildMetricItem(
                theme,
                icon: LucideIcons.shieldCheck,
                label: 'Risco',
                value: clientInfo.riskLevel,
                color: _getRiskColor(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricItem(
                theme,
                icon: LucideIcons.creditCard,
                label: 'Pagamento',
                value: '${clientInfo.paymentReliability.toInt()}%',
                color: Colors.green,
              ),
              _buildMetricItem(
                theme,
                icon: LucideIcons.clock,
                label: 'Resposta',
                value: clientInfo.responseTimeFormatted,
                color: Colors.blue,
              ),
              _buildMetricItem(
                theme,
                icon: LucideIcons.trendingUp,
                label: 'Potencial',
                value: '${clientInfo.expansionPotential.toInt()}%',
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Orçamento e comunicação
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                theme,
                icon: LucideIcons.dollarSign,
                label: 'Orçamento',
                value: clientInfo.budgetRangeFormatted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailItem(
                theme,
                icon: LucideIcons.messageCircle,
                label: 'Comunicação',
                value: _getPreferredCommunicationLabel(),
              ),
            ),
          ],
        ),

        // Necessidades especiais e interesses
        if (clientInfo.specialNeeds.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDetailItem(
            theme,
            icon: LucideIcons.alertCircle,
            label: 'Necessidades Especiais',
            value: clientInfo.specialNeeds.join(', '),
          ),
        ],

        if (clientInfo.interests.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDetailItem(
            theme,
            icon: LucideIcons.target,
            label: 'Interesses',
            value: clientInfo.interests.take(3).join(', '),
          ),
        ],

        // Contexto empresarial (para PJ)
        if (clientInfo.isCorporate) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (clientInfo.industry != null)
                Expanded(
                  child: _buildDetailItem(
                    theme,
                    icon: LucideIcons.building,
                    label: 'Setor',
                    value: clientInfo.industry!,
                  ),
                ),
              if (clientInfo.companySize != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailItem(
                    theme,
                    icon: LucideIcons.users,
                    label: 'Funcionários',
                    value: '${clientInfo.companySize}',
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDetailItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchContext(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.zap,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contexto do Match',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  matchContext!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onContactClient ?? () => _contactClient(),
            icon: Icon(
              _getContactIcon(),
              size: 18,
            ),
            label: const Text('Contatar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onViewClientHistory ?? () => _viewClientHistory(),
            icon: const Icon(LucideIcons.history, size: 18),
            label: const Text('Histórico'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getRiskColor() {
    if (clientInfo.riskScore <= 30) return Colors.green;
    if (clientInfo.riskScore <= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getContactIcon() {
    switch (clientInfo.preferredCommunication) {
      case 'whatsapp':
        return LucideIcons.messageCircle;
      case 'phone':
        return LucideIcons.phone;
      case 'teams':
        return LucideIcons.video;
      default:
        return LucideIcons.mail;
    }
  }

  String _getPreferredCommunicationLabel() {
    switch (clientInfo.preferredCommunication) {
      case 'whatsapp':
        return 'WhatsApp';
      case 'phone':
        return 'Telefone';
      case 'teams':
        return 'Teams';
      case 'email':
        return 'E-mail';
      default:
        return 'E-mail';
    }
  }

  void _contactClient() {
    // Implementar lógica de contato baseada na preferência
    switch (clientInfo.preferredCommunication) {
      case 'whatsapp':
        _launchWhatsApp();
        break;
      case 'phone':
        _launchPhone();
        break;
      case 'email':
        _launchEmail();
        break;
      default:
        _launchEmail();
    }
  }

  void _viewClientHistory() {
    // TODO: Implementar navegação para histórico do cliente
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(
    //     content: Text('Funcionalidade em desenvolvimento'),
    //   ),
    // );
  }

  void _launchWhatsApp() async {
    final phone = clientInfo.phone.replaceAll(RegExp(r'[^\d]'), '');
    final url = Uri.parse('https://wa.me/55$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _launchPhone() async {
    final url = Uri.parse('tel:${clientInfo.phone}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _launchEmail() async {
    final url = Uri.parse('mailto:${clientInfo.email}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
} 