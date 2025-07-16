import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/cases/domain/entities/lawyer_info.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import 'package:meu_app/src/shared/widgets/atoms/initials_avatar.dart';
import 'package:meu_app/src/core/theme/app_theme.dart';

class DetailedCaseCard extends StatelessWidget {
  final String caseId;
  final String title;
  final String status;
  final double progress;
  final String nextStep;
  final LawyerInfo lawyer;

  const DetailedCaseCard({
    super.key,
    required this.caseId,
    required this.title,
    required this.status,
    required this.progress,
    required this.nextStep,
    required this.lawyer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.go('/cases/$caseId'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLawyerHeader(context),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 12),
              _buildProgressSection(context),
              const SizedBox(height: 12),
              _buildNextStepSection(context),
              const Divider(height: 24),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLawyerHeader(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = theme.extension<AppStatusColors>()!;
    return Row(
      children: [
        CachedNetworkImage(
          imageUrl: lawyer.avatarUrl,
          imageBuilder: (context, imageProvider) => CircleAvatar(
            backgroundImage: imageProvider,
            radius: 20,
          ),
          placeholder: (context, url) => const CircleAvatar(radius: 20, child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => InitialsAvatar(text: lawyer.name, radius: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lawyer.name, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              Text(lawyer.specialty, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
            ],
          ),
        ),
        Chip(
          label: Text(status),
          backgroundColor: _getStatusColor(status, statusColors).withOpacity(0.1),
          labelStyle: TextStyle(color: _getStatusColor(status, statusColors), fontWeight: FontWeight.bold, fontSize: 12),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = theme.extension<AppStatusColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progresso', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(status, statusColors)),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildNextStepSection(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(LucideIcons.flag, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text('Próxima etapa: ', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        Expanded(child: Text(nextStep, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)))),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _actionButton(context, icon: LucideIcons.bot, label: 'Resumo IA', onPressed: () {}),
        _actionButton(context, icon: LucideIcons.messageCircle, label: 'Chat', onPressed: () {}),
        _actionButton(context, icon: LucideIcons.folder, label: 'Documentos', onPressed: () {}),
      ],
    );
  }

  Widget _actionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Color _getStatusColor(String status, AppStatusColors statusColors) {
    switch (status) {
      case 'Em Andamento':
        return statusColors.statusOrange!;
      case 'Concluído':
        return statusColors.statusGreen!;
      case 'Aguardando':
        return statusColors.statusBlue!;
      default:
        return statusColors.statusBlue!; // Fallback
    }
  }
} 