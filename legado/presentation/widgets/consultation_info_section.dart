import 'package:flutter/material.dart';
import '../../../../shared/utils/app_colors.dart';

class ConsultationInfoSection extends StatelessWidget {
  const ConsultationInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informações da Consulta',
                style: t.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _infoRow(Icons.calendar_month, 'Data da Consulta', '16/01/2024'),
            _infoRow(Icons.timer_outlined, 'Duração', '45 minutos'),
            _infoRow(Icons.videocam, 'Modalidade', 'Vídeo'),
            _infoRow(Icons.receipt_long, 'Plano', 'Plano por Ato'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.lightText2),
            const SizedBox(width: 8),
            Text('$label: ',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(value),
          ],
        ),
      );
} 