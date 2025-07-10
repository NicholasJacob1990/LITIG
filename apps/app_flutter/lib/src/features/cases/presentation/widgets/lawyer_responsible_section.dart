import 'package:flutter/material.dart';
import 'package:meu_app/src/features/cases/domain/entities/case_detail_models.dart';

class LawyerResponsibleSection extends StatelessWidget {
  final Lawyer lawyer;
  const LawyerResponsibleSection({super.key, required this.lawyer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 24, backgroundImage: NetworkImage(lawyer.avatarUrl)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lawyer.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(lawyer.specialty, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('${lawyer.rating.toStringAsFixed(1)} • ${lawyer.experienceYears} anos',
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(onPressed: () {/* chat */}, icon: const Icon(Icons.chat_bubble, color: Colors.blue)),
                IconButton(onPressed: () {/* vídeo */}, icon: const Icon(Icons.videocam, color: Colors.green)),
              ],
            )
          ],
        ),
      ),
    );
  }
} 