import 'package:flutter/material.dart';
import '../../domain/entities/case_detail.dart';
import '../../../../shared/utils/app_colors.dart';

class ConsultationInfoSection extends StatelessWidget {
  final ConsultationInfo? consultation;
  
  const ConsultationInfoSection({
    super.key,
    this.consultation,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    
    if (consultation == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Informações da Consulta',
                  style: t.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Consulta não agendada',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informações da Consulta',
                style: t.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _infoRow(
              Icons.calendar_month, 
              'Data da Consulta', 
              _formatDate(consultation!.date)
            ),
            _infoRow(
              Icons.timer_outlined, 
              'Duração', 
              '${consultation!.durationMinutes} minutos'
            ),
            _infoRow(
              _getModalityIcon(consultation!.modality), 
              'Modalidade', 
              _getModalityLabel(consultation!.modality)
            ),
            _infoRow(
              Icons.receipt_long, 
              'Plano', 
              _getPlanLabel(consultation!.plan)
            ),
            if (consultation!.notes != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _infoRow(
                Icons.note_outlined, 
                'Observações', 
                consultation!.notes!
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.lightText2),
            const SizedBox(width: 8),
            Text('$label: ',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Expanded(
              child: Text(
                value,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      );
      
  IconData _getModalityIcon(String modality) {
    switch (modality.toLowerCase()) {
      case 'video':
        return Icons.videocam;
      case 'presencial':
        return Icons.location_on;
      case 'telefone':
        return Icons.phone;
      default:
        return Icons.help_outline;
    }
  }
  
  String _getModalityLabel(String modality) {
    switch (modality.toLowerCase()) {
      case 'video':
        return 'Videochamada';
      case 'presencial':
        return 'Presencial';
      case 'telefone':
        return 'Telefone';
      default:
        return modality;
    }
  }
  
  String _getPlanLabel(String plan) {
    switch (plan.toLowerCase()) {
      case 'por_ato':
        return 'Plano por Ato';
      case 'mensal':
        return 'Plano Mensal';
      case 'anual':
        return 'Plano Anual';
      default:
        return plan;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
} 