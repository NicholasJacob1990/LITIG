import 'package:flutter/material.dart';
import 'package:meu_app/src/features/cases/domain/entities/case_detail_models.dart';

class NextStepsSection extends StatelessWidget {
  final List<NextStep> steps;
  const NextStepsSection({super.key, required this.steps});

  Color _priorityColor(String p) {
    switch (p) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Próximos Passos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...steps.map((step) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Chip(
                        label: Text(step.priority, style: const TextStyle(color: Colors.white)),
                        backgroundColor: _priorityColor(step.priority)),
                    const SizedBox(width: 8),
                    Chip(label: Text(step.status, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.orange),
                  ]),
                  const SizedBox(height: 8),
                  Text(step.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(step.description, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Prazo: ${step.dueDate}'),
                  ]),
                ]),
              ),
            )),
      ]),
    );
  }
} 