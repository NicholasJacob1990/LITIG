import 'package:flutter/material.dart';

/// Widget para exibir estrelas de avaliação de forma consistente
class RatingStarsDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool showRating;
  final bool showTotal;
  final int totalRatings;
  final EdgeInsetsGeometry? padding;
  final MainAxisAlignment alignment;

  const RatingStarsDisplay({
    super.key,
    required this.rating,
    this.size = 16,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.showRating = true,
    this.showTotal = false,
    this.totalRatings = 0,
    this.padding,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: Row(
        mainAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(5, (index) {
            return Icon(
              _getStarIcon(index),
              size: size,
              color: _getStarColor(index),
            );
          }),
          if (showRating || showTotal) ...[
            const SizedBox(width: 8),
            if (showRating)
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: size * 0.8,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            if (showTotal && totalRatings > 0) ...[
              if (showRating) const SizedBox(width: 4),
              Text(
                '($totalRatings)',
                style: TextStyle(
                  fontSize: size * 0.7,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  IconData _getStarIcon(int index) {
    final difference = rating - index;
    if (difference >= 1) {
      return Icons.star;
    } else if (difference >= 0.5) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }

  Color _getStarColor(int index) {
    final difference = rating - index;
    if (difference >= 0.5) {
      return activeColor;
    } else {
      return inactiveColor;
    }
  }
}

/// Widget para exibir rating com barra de progresso
class RatingProgressBar extends StatelessWidget {
  final String label;
  final double rating;
  final int count;
  final int totalCount;
  final Color color;

  const RatingProgressBar({
    super.key,
    required this.label,
    required this.rating,
    required this.count,
    required this.totalCount,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalCount > 0 ? count / totalCount : 0.0;
    
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            count.toString(),
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

/// Widget para exibir distribuição de ratings em estrelas
class RatingDistribution extends StatelessWidget {
  final Map<int, int> distribution;
  final int totalRatings;

  const RatingDistribution({
    super.key,
    required this.distribution,
    required this.totalRatings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribuição de Avaliações',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(5, (index) {
          final stars = 5 - index;
          final count = distribution[stars] ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: RatingProgressBar(
              label: '$stars ★',
              rating: stars.toDouble(),
              count: count,
              totalCount: totalRatings,
              color: _getColorForRating(stars),
            ),
          );
        }),
      ],
    );
  }

  Color _getColorForRating(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 