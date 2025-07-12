import 'package:flutter/material.dart';
import '../../../../shared/utils/app_colors.dart';

class NextStepsSection extends StatelessWidget {
  const NextStepsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Próximos Passos',
            style: t.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _stepCard(
          title: 'Enviar documentos',
          desc: 'Contrato de trabalho, carta de demissão e comprovantes',
          deadline: '24/01/2024',
          priority: _Priority.high,
        ),
        _stepCard(
          title: 'Análise dos documentos',
          desc: 'Advogado analisará a documentação enviada',
          deadline: '27/01/2024',
          priority: _Priority.medium,
        ),
        _stepCard(
          title: 'Elaboração de petição',
          desc: 'Preparação da ação trabalhista',
          deadline: '04/02/2024',
          priority: _Priority.medium,
        ),
      ],
    );
  }

  Widget _stepCard(
      {required String title,
      required String desc,
      required String deadline,
      required _Priority priority}) {
    final badgeColor = {
      _Priority.high: AppColors.red,
      _Priority.medium: AppColors.yellow
    }[priority]!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
            _badge(priority.name.toUpperCase(), badgeColor),
          ]),
          const SizedBox(height: 4),
          Text(desc),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.calendar_today, size: 14, color: AppColors.lightText2),
            const SizedBox(width: 4),
            Text('Prazo: $deadline', style: const TextStyle(color: AppColors.lightText2)),
            const Spacer(),
            _badge('PENDING', badgeColor),
          ]),
        ]),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
      );
}

enum _Priority { high, medium } 