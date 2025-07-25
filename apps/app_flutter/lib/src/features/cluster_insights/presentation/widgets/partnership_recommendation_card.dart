import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/partnership_recommendation.dart';
import '../bloc/partnership_recommendations_bloc.dart';

class PartnershipRecommendationCard extends StatefulWidget {
  final PartnershipRecommendation recommendation;
  final VoidCallback? onContact;
  final VoidCallback? onViewProfile;

  const PartnershipRecommendationCard({
    super.key,
    required this.recommendation,
    this.onContact,
    this.onViewProfile,
  });

  @override
  State<PartnershipRecommendationCard> createState() => _PartnershipRecommendationCardState();
}

class _PartnershipRecommendationCardState extends State<PartnershipRecommendationCard> {
  bool _isExpanded = false;
  bool _hasProvidedFeedback = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com informações principais
            _buildHeader(theme),
            const SizedBox(height: 12),
            
            // Score de compatibilidade
            _buildCompatibilityScore(theme),
            const SizedBox(height: 12),
            
            // Sinergias potenciais
            _buildPotentialSynergies(theme),
            const SizedBox(height: 12),
            
            // Razão da recomendação
            _buildRecommendationReason(theme),
            
            // Botões de ação principais
            const SizedBox(height: 16),
            _buildMainActionButtons(theme),
            
            // Seção de feedback ML (expandível)
            if (!_hasProvidedFeedback) ...[
              const SizedBox(height: 12),
              _buildFeedbackSection(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            widget.recommendation.lawyerName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.recommendation.lawyerName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.recommendation.firmName != null)
                Text(
                  widget.recommendation.firmName!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          icon: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCompatibilityScore(ThemeData theme) {
    final score = widget.recommendation.compatibilityScore;
    final scoreColor = _getScoreColor(score);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.psychology,
            color: scoreColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Compatibilidade: ${(score * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scoreColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPotentialSynergies(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sinergias Potenciais:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        ...widget.recommendation.potentialSynergies.take(3).map((synergy) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    synergy,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationReason(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Por que esta recomendação?',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.recommendation.partnershipReason,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onViewProfile,
            icon: const Icon(Icons.person_outline),
            label: const Text('Ver Perfil'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[700],
              side: BorderSide(color: Colors.blue[300]!),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onContact,
            icon: const Icon(Icons.message_outlined),
            label: const Text('Contatar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.feedback_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Como foi esta recomendação?',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: _FeedbackButton(
                  label: 'Aceitar',
                  icon: Icons.thumb_up_outlined,
                  color: Colors.green,
                  onPressed: () => _provideFeedback('accepted', 0.9),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _FeedbackButton(
                  label: 'Contatar',
                  icon: Icons.message_outlined,
                  color: Colors.blue,
                  onPressed: () => _provideFeedback('contacted', 0.8),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _FeedbackButton(
                  label: 'Rejeitar',
                  icon: Icons.thumb_down_outlined,
                  color: Colors.red,
                  onPressed: () => _provideFeedback('rejected', 0.2),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _FeedbackButton(
                  label: 'Dispensar',
                  icon: Icons.close_outlined,
                  color: Colors.grey,
                  onPressed: () => _provideFeedback('dismissed', 0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _provideFeedback(String feedbackType, double score) {
    // Enviar feedback para o backend ML
    context.read<PartnershipRecommendationsBloc>().add(
      ProvidePartnershipFeedback(
        lawyerId: widget.recommendation.recommendedLawyerId,
        feedbackType: feedbackType,
        feedbackScore: score,
        interactionTimeSeconds: 30, // Placeholder - implementar timer real
      ),
    );

    // Mostrar confirmação
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getFeedbackMessage(feedbackType)),
        backgroundColor: _getFeedbackColor(feedbackType),
        duration: const Duration(seconds: 2),
      ),
    );

    // Marcar como feedback fornecido
    setState(() {
      _hasProvidedFeedback = true;
    });
  }

  String _getFeedbackMessage(String feedbackType) {
    switch (feedbackType) {
      case 'accepted':
        return 'Obrigado! Vamos melhorar as próximas recomendações.';
      case 'contacted':
        return 'Ótimo! Seu feedback ajuda a refinar o algoritmo.';
      case 'rejected':
        return 'Entendido. Vamos ajustar as recomendações.';
      case 'dismissed':
        return 'Feedback registrado. Obrigado!';
      default:
        return 'Feedback enviado com sucesso!';
    }
  }

  Color _getFeedbackColor(String feedbackType) {
    switch (feedbackType) {
      case 'accepted':
        return Colors.green;
      case 'contacted':
        return Colors.blue;
      case 'rejected':
        return Colors.orange;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

class _FeedbackButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _FeedbackButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
} 