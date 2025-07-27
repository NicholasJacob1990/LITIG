import 'package:flutter/material.dart';
import '../../domain/entities/partnership_recommendation.dart';

/// Widget para exibir perfis de membros verificados da plataforma
class VerifiedProfileCard extends StatelessWidget {
  final PartnershipRecommendation recommendation;
  final VoidCallback? onContact;

  const VerifiedProfileCard({
    super.key,
    required this.recommendation,
    this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com badge verificado
            Row(
              children: [
                _buildVerifiedBadge(context),
                const Spacer(),
                _buildEngagementIndicator(context),
              ],
            ),
            const SizedBox(height: 12),
            
            // Perfil principal
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(recommendation.avatarUrl),
                  onBackgroundImageError: (_, __) => {},
                  child: recommendation.avatarUrl.contains('ui-avatars.com')
                      ? null
                      : const Icon(Icons.person, size: 28),
                ),
                const SizedBox(width: 16),
                
                // Informações básicas
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.lawyerName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (recommendation.firmName != null) ...[
                        Text(
                          recommendation.firmName!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        recommendation.displayHeadline,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Score de compatibilidade completo
            _buildFullCompatibilityScore(context),
            
            const SizedBox(height: 16),
            
            // Ações
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onContact,
                    icon: const Icon(Icons.chat),
                    label: const Text('Contatar via Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _viewProfile(context),
                  icon: const Icon(Icons.person),
                  label: const Text('Ver Perfil'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedBadge(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 16, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            'Membro Verificado',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementIndicator(BuildContext context) {
    final theme = Theme.of(context);
    
    // Simular indicador de engajamento baseado no score
    final engagementLevel = recommendation.compatibilityScore;
    Color indicatorColor;
    String indicatorLabel;
    
    if (engagementLevel >= 0.8) {
      indicatorColor = Colors.green;
      indicatorLabel = 'Ativo';
    } else if (engagementLevel >= 0.6) {
      indicatorColor = Colors.orange;
      indicatorLabel = 'Moderado';
    } else {
      indicatorColor = Colors.grey;
      indicatorLabel = 'Baixo';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: indicatorColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            indicatorLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: indicatorColor,
              fontWeight: FontWeight.w500,
            ),
          ),
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
          // Score principal
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
              const Spacer(),
              _buildScoreBar(context, recommendation.compatibilityScore, scoreColor),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Razão da parceria
          Text(
            recommendation.partnershipReason,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          
          // Sinergias
          if (recommendation.potentialSynergies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Áreas de Sinergia:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: recommendation.potentialSynergies.map((synergy) {
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
          
          // Informações de contato (se disponível)
          if (recommendation.contactEmail != null || recommendation.contactPhone != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                if (recommendation.contactEmail != null) ...[
                  Icon(Icons.email, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Email disponível',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (recommendation.contactPhone != null) ...[
                  if (recommendation.contactEmail != null) ...[
                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: 12,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Icon(Icons.phone, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Telefone disponível',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreBar(BuildContext context, double score, Color color) {
    return Container(
      width: 60,
      height: 6,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: score,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  void _viewProfile(BuildContext context) {
    // TODO: Implementar navegação para perfil completo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visualizando perfil de ${recommendation.lawyerName}'),
      ),
    );
  }
} 