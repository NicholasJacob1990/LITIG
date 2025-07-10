import 'package:flutter/material.dart';
import 'package:meu_app/src/features/cases/domain/entities/case_detail_models.dart';

class ConsultationInfoSection extends StatelessWidget {
  final ConsultationInfo info;
  const ConsultationInfoSection({super.key, required this.info});

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Informações da Consulta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          _row(Icons.calendar_today, 'Data da Consulta:', info.date),
          _row(Icons.access_time, 'Duração:', info.duration),
          _row(Icons.videocam, 'Modalidade:', info.mode),
          _row(Icons.description, 'Plano:', info.plan),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
} 