import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/cases/domain/entities/lawyer_info.dart';
import 'package:meu_app/src/shared/widgets/atoms/initials_avatar.dart';

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
    return Card(
      elevation: 4,
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
              _buildLawyerHeader(),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildProgressSection(),
              const SizedBox(height: 12),
              _buildNextStepSection(),
              const Divider(height: 24),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLawyerHeader() {
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
              Text(lawyer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(lawyer.specialty, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
        Chip(
          label: Text(status),
          backgroundColor: _getStatusColor(status).withOpacity(0.1),
          labelStyle: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
          side: BorderSide.none,
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Progresso', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(status)),
        ),
      ],
    );
  }

  Widget _buildNextStepSection() {
    return Row(
      children: [
        const Icon(LucideIcons.flag, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        const Text('Próxima etapa: ', style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(nextStep, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Em Andamento':
        return Colors.orange.shade700;
      case 'Concluído':
        return Colors.green.shade700;
      case 'Aguardando':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
} 