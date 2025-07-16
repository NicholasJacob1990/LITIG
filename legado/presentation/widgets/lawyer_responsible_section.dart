import 'package:flutter/material.dart';

class LawyerResponsibleSection extends StatelessWidget {
  const LawyerResponsibleSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final chipBg = Theme.of(context).chipTheme.backgroundColor;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. Carlos Mendes',
                      style: t.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Direito Trabalhista', style: t.bodySmall),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text('4.8  •  12 anos'),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _ActionChip(icon: Icons.chat_bubble_outline, label: 'Chat', bg: chipBg!),
                const SizedBox(height: 8),
                _ActionChip(icon: Icons.videocam, label: 'Vídeo', bg: chipBg),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.bg});
  final IconData icon;
  final String label;
  final Color bg;
  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        backgroundColor: bg,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      );
} 