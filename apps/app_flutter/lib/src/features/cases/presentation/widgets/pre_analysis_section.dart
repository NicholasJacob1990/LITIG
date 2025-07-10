import 'package:flutter/material.dart';
import 'package:meu_app/src/features/cases/domain/entities/case_detail_models.dart';

class PreAnalysisSection extends StatelessWidget {
  final PreAnalysis pre;
  const PreAnalysisSection({super.key, required this.pre});

  @override
  Widget build(BuildContext context) {
    final urgencyPct = pre.urgency / 10.0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Chip(
              label: Text(pre.priority, style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.redAccent,
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
          ]),
          const SizedBox(height: 8),
          Chip(
            label: Text(pre.tag,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            backgroundColor: pre.tagColor,
          ),
          const SizedBox(height: 12),
          Text('Prazo Estimado: ${pre.estimatedTime}'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              flex: 8,
              child: LinearProgressIndicator(value: urgencyPct, minHeight: 6, backgroundColor: Colors.grey[300]),
            ),
            const SizedBox(width: 8),
            Text('${pre.urgency}/10'),
          ]),
          const SizedBox(height: 16),
          const Text('Análise Preliminar', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(pre.summary),
          const SizedBox(height: 12),
          const Text('Documentos Necessários', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...pre.requiredDocs.map((d) => Text('• $d')),
          const SizedBox(height: 12),
          const Text('Estimativa de Custos', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
              children: pre.costs
                  .map((c) => Expanded(
                        child: Card(
                          color: Colors.grey[100],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(children: [
                              Text(c.label, style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(c.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ))
                  .toList()),
          const SizedBox(height: 12),
          const Text('Avaliação de Risco', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(pre.risk),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(onPressed: () {}, child: const Text('Ver Análise Completa')),
          ),
        ]),
      ),
    );
  }
} 