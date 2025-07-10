import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/shared/widgets/atoms/initials_avatar.dart';

class LawyerMatchCard extends StatelessWidget {
  final MatchedLawyer lawyer;
  final VoidCallback onSelect;
  final VoidCallback onExplain;

  const LawyerMatchCard({
    super.key,
    required this.lawyer,
    required this.onSelect,
    required this.onExplain,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildInfoRow(),
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Hero(
          tag: 'lawyer-avatar-${lawyer.id}',
          child: CachedNetworkImage(
            imageUrl: lawyer.avatarUrl,
            imageBuilder: (context, imageProvider) => CircleAvatar(backgroundImage: imageProvider, radius: 24),
            placeholder: (context, url) => const CircleAvatar(radius: 24, child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => InitialsAvatar(text: lawyer.name, radius: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lawyer.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(lawyer.primaryArea, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getMatchColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${(lawyer.fairScore * 100).toInt()}% Match',
            style: TextStyle(color: _getMatchColor(), fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoChip(LucideIcons.star, '${lawyer.rating}', Colors.amber),
        _buildInfoChip(LucideIcons.mapPin, '${lawyer.distanceKm.toStringAsFixed(1)} km', Colors.blue),
        _buildInfoChip(LucideIcons.briefcase, '${lawyer.casesCount} casos', Colors.purple),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Chip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onExplain,
            icon: const Icon(LucideIcons.helpCircle, size: 16),
            label: const Text('Por que este advogado?'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onSelect,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            child: const Text('Selecionar'),
          ),
        ),
      ],
    );
  }

  Color _getMatchColor() {
    if (lawyer.fairScore >= 0.8) return Colors.green;
    if (lawyer.fairScore >= 0.6) return Colors.orange;
    return Colors.red;
  }
} 