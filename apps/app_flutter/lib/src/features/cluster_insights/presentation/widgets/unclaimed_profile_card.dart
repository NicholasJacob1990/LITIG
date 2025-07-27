import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/partnership_recommendation.dart';

/// Widget para exibir perfis externos (não cadastrados) com diferenciação visual
class UnclaimedProfileCard extends StatelessWidget {
  final PartnershipRecommendation recommendation;
  final VoidCallback? onInvite;
  final bool showInviteButton;

  const UnclaimedProfileCard({
    super.key,
    required this.recommendation,
    this.onInvite,
    this.showInviteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(recommendation.status),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com status badge
            Row(
              children: [
                _buildStatusBadge(context),
                const Spacer(),
                if (recommendation.isPublicProfile)
                  _buildCuriosityGapChip(context),
              ],
            ),
            const SizedBox(height: 12),
            
            // Perfil principal
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(recommendation.avatarUrl),
                  onBackgroundImageError: (_, __) => {},
                  child: recommendation.avatarUrl.contains('ui-avatars.com')
                      ? null
                      : const Icon(Icons.person, size: 30),
                ),
                const SizedBox(width: 16),
                
                // Informações básicas
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.lawyerName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommendation.displayHeadline,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (recommendation.profileData?.city != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              recommendation.profileData!.city!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Score de compatibilidade (limitado para perfis externos)
            if (recommendation.isPublicProfile)
              _buildLimitedCompatibilityScore(context)
            else
              _buildFullCompatibilityScore(context),
            
            const SizedBox(height: 16),
            
            // Ações
            Row(
              children: [
                // Botão LinkedIn (sempre disponível)
                if (recommendation.profileData?.profileUrl != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openLinkedInProfile(
                        recommendation.profileData!.profileUrl!,
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Ver no LinkedIn'),
                    ),
                  ),
                
                if (recommendation.profileData?.profileUrl != null && showInviteButton)
                  const SizedBox(width: 12),
                
                // Botão de convite (apenas para perfis externos)
                if (showInviteButton && recommendation.isPublicProfile)
                  Expanded(
                    child: _buildInviteButton(context),
                  ),
                
                // Status de convite (se já foi convidado)
                if (recommendation.isInvited)
                  Expanded(
                    child: _buildInvitedStatus(context),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final theme = Theme.of(context);
    
    String label;
    IconData icon;
    Color color;
    
    switch (recommendation.status) {
      case RecommendationStatus.verifiedMember:
        label = 'Verificado';
        icon = Icons.verified;
        color = Colors.green;
        break;
      case RecommendationStatus.publicProfile:
        label = 'Perfil Público';
        icon = Icons.public;
        color = Colors.orange;
        break;
      case RecommendationStatus.invited:
        label = 'Convidado';
        icon = Icons.mail_outline;
        color = Colors.blue;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuriosityGapChip(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 14, color: Colors.purple),
          const SizedBox(width: 4),
          Text(
            'Análise Limitada',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.purple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitedCompatibilityScore(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.insights, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sinergia de ${(recommendation.compatibilityScore * 100).toInt()}% detectada',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Convide para desbloquear a análise completa',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, color: Colors.amber.shade700, size: 20),
        ],
      ),
    );
  }

  Widget _buildFullCompatibilityScore(BuildContext context) {
    final theme = Theme.of(context);
    final scorePercent = (recommendation.compatibilityScore * 100).toInt();
    
    Color scoreColor;
    if (scorePercent >= 80) {
      scoreColor = Colors.green;
    } else if (scorePercent >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: scoreColor),
              const SizedBox(width: 8),
              Text(
                'Compatibilidade: $scorePercent%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scoreColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.partnershipReason,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (recommendation.potentialSynergies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: recommendation.potentialSynergies.take(3).map((synergy) {
                return Chip(
                  label: Text(
                    synergy,
                    style: theme.textTheme.bodySmall,
                  ),
                  backgroundColor: scoreColor.withOpacity(0.1),
                  side: BorderSide(color: scoreColor.withOpacity(0.3)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInviteButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onInvite,
      icon: const Icon(Icons.mail_outline),
      label: const Text('Convidar'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildInvitedStatus(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Text(
            'Convite Enviado',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(RecommendationStatus status) {
    switch (status) {
      case RecommendationStatus.verifiedMember:
        return Colors.green;
      case RecommendationStatus.publicProfile:
        return Colors.orange;
      case RecommendationStatus.invited:
        return Colors.blue;
    }
  }

  Future<void> _openLinkedInProfile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
} 