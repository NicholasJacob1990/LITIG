import 'package:flutter/material.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import '../../domain/entities/lawyer_rating_stats.dart';

/// Widget para exibir estatísticas de avaliação de um advogado
class LawyerRatingStatsWidget extends StatelessWidget {
  final LawyerRatingStats stats;
  final bool showDetailedBreakdown;
  final bool isCompact;

  const LawyerRatingStatsWidget({
    super.key,
    required this.stats,
    this.showDetailedBreakdown = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactView(context);
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildOverallStats(context),
            if (showDetailedBreakdown) ...[
              const SizedBox(height: 24),
              _buildDetailedRatings(context),
              const SizedBox(height: 24),
              _buildStarDistribution(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          _buildRatingCircle(context),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.totalRatings} avaliações',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < stats.overallRating ? Icons.star : Icons.star_border,
                        size: 16,
                        color: index < stats.overallRating ? Colors.amber : Colors.grey[400],
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      stats.overallRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.analytics_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Estatísticas de Avaliação',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        if (stats.isRecommended) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.thumb_up,
                  size: 14,
                  color: AppColors.success,
                ),
                SizedBox(width: 4),
                Text(
                  'Recomendado',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOverallStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Avaliação Geral',
            stats.overallRating.toStringAsFixed(1),
            Icons.star,
            _getRatingColor(stats.overallRating),
            subtitle: 'de 5 estrelas',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            'Total de Avaliações',
            stats.totalRatings.toString(),
            Icons.reviews,
            Theme.of(context).colorScheme.primary,
            subtitle: stats.totalRatings == 1 ? 'avaliação' : 'avaliações',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedRatings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avaliações Detalhadas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailedRatingRow(
          context,
          'Comunicação',
          Icons.chat_bubble_outline,
          stats.communicationAvg,
        ),
        const SizedBox(height: 12),
        _buildDetailedRatingRow(
          context,
          'Expertise',
          Icons.psychology_outlined,
          stats.expertiseAvg,
        ),
        const SizedBox(height: 12),
        _buildDetailedRatingRow(
          context,
          'Responsividade',
          Icons.schedule_outlined,
          stats.responsivenessAvg,
        ),
        const SizedBox(height: 12),
        _buildDetailedRatingRow(
          context,
          'Custo-Benefício',
          Icons.attach_money_outlined,
          stats.valueAvg,
        ),
      ],
    );
  }

  Widget _buildDetailedRatingRow(
    BuildContext context,
    String label,
    IconData icon,
    double value,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < value ? Icons.star : Icons.star_border,
                        size: 16,
                        color: index < value ? Colors.amber : Colors.grey[400],
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      value.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getRatingColor(value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildProgressBar(context, value),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, double value) {
    return Container(
      width: 60,
      height: 8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value / 5,
        child: Container(
          decoration: BoxDecoration(
            color: _getRatingColor(value),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildStarDistribution(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribuição de Estrelas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(5, (index) {
          final starCount = 5 - index;
          final count = stats.starDistribution[starCount.toString()] ?? 0;
          final percentage = stats.totalRatings > 0 ? count / stats.totalRatings : 0.0;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    '$starCount',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.amber,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getStarColor(starCount),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(percentage * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  child: Text(
                    '$count',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRatingCircle(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _getRatingColor(stats.overallRating).withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: _getRatingColor(stats.overallRating),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stats.overallRating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getRatingColor(stats.overallRating),
            ),
          ),
          Icon(
            Icons.star,
            size: 16,
            color: _getRatingColor(stats.overallRating),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return AppColors.success;
    if (rating >= 3.5) return Colors.green;
    if (rating >= 2.5) return AppColors.warning;
    if (rating >= 1.5) return Colors.orange;
    return AppColors.error;
  }

  Color _getStarColor(int stars) {
    switch (stars) {
      case 5:
        return AppColors.success;
      case 4:
        return Colors.green;
      case 3:
        return AppColors.warning;
      case 2:
        return Colors.orange;
      case 1:
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }
} 