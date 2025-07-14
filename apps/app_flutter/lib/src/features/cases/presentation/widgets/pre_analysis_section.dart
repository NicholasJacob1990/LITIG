import 'package:flutter/material.dart';
import '../../domain/entities/case_detail.dart';
import '../../../../shared/utils/app_colors.dart';

class PreAnalysisSection extends StatelessWidget {
  final PreAnalysis? preAnalysis;
  
  const PreAnalysisSection({
    super.key,
    this.preAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    Widget infoRow(IconData icn, String l, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icn, size: 16, color: AppColors.lightText2),
              const SizedBox(width: 8),
              Text('$l: ', style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(v),
            ],
          ),
        );

    if (preAnalysis == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pré-análise',
                  style: t.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.analytics_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Análise em processamento',
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
            // badge de urgência -----------------------------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: _getUrgencyColor(preAnalysis!.urgencyLevel), 
                  borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.access_time, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(_getUrgencyLabel(preAnalysis!.urgencyLevel),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 12),

            // título ---------------------------------------------
            Text(preAnalysis!.legalArea,
                style: t.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            // banner roxo ----------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.accentPurpleStart,
                    AppColors.accentPurpleEnd
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text('Análise Preliminar por IA',
                      style: t.bodyMedium!.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                  Text('Sujeita a conferência humana',
                      style: t.bodySmall!.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Analisado em: ${_formatDate(preAnalysis!.analyzedAt)}',
                      style: t.bodySmall!.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Análise preliminar ---------------------------------
            Text('Resumo da Análise',
                style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              preAnalysis!.summary,
              style: t.bodySmall,
            ),
            const SizedBox(height: 16),

            // Pontos-chave ---------------------------------------
            Text('Pontos-chave Identificados',
                style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...preAnalysis!.keyPoints
                .map((point) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right,
                              size: 16, color: AppColors.green),
                          const SizedBox(width: 6),
                          Expanded(child: Text(point)),
                        ],
                      ),
                    ))
                .toList(),
            const SizedBox(height: 20),

            // Documentos necessários (NOVO) ---------------------
            if (preAnalysis!.requiredDocuments.isNotEmpty) ...[
              Text('Documentos Necessários',
                  style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ...preAnalysis!.requiredDocuments
                  .map((doc) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.description_outlined,
                                size: 16, color: AppColors.lightText2),
                            const SizedBox(width: 6),
                            Expanded(child: Text(doc, style: t.bodySmall)),
                          ],
                        ),
                      ))
                  .toList(),
              const SizedBox(height: 20),
            ],

            // Estimativa de Custos -------------------------------
            Text('Estimativa de Custos',
                style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              _costCard(context, 'Consulta', 'R\$ ${preAnalysis!.estimatedCosts['Consulta']?.toStringAsFixed(2) ?? 'N/A'}'),
              const SizedBox(width: 12),
              _costCard(context, 'Representação', 'R\$ ${preAnalysis!.estimatedCosts['Representação']?.toStringAsFixed(2) ?? 'N/A'}'),
            ]),
            const SizedBox(height: 24),
            
            // Avaliação de Risco ---------------------------------
            Text('Avaliação de Risco',
                style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              preAnalysis!.riskAssessment,
              style: t.bodySmall,
            ),
            const SizedBox(height: 20),

            // Recomendação ---------------------------------------
            Text('Recomendação',
                style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                preAnalysis!.recommendation,
                style: t.bodySmall!.copyWith(color: Colors.blue[800]),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _showFullAnalysis(context),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Ver Análise Completa'),
            )
          ],
                  ),
        ),
      );
  }

  Color _getUrgencyColor(String urgencyLevel) {
    switch (urgencyLevel.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baixa':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getUrgencyLabel(String urgencyLevel) {
    switch (urgencyLevel.toLowerCase()) {
      case 'alta':
        return 'ALTA';
      case 'media':
        return 'MÉDIA';
      case 'baixa':
        return 'BAIXA';
      default:
        return urgencyLevel.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showFullAnalysis(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Análise Completa'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Área: ${preAnalysis!.legalArea}'),
              const SizedBox(height: 8),
              Text('Urgência: ${_getUrgencyLabel(preAnalysis!.urgencyLevel)}'),
              const SizedBox(height: 8),
              Text('Resumo:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(preAnalysis!.summary),
              const SizedBox(height: 8),
              Text('Recomendação:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(preAnalysis!.recommendation),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _costCard(BuildContext context, String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor)),
          child: Column(
            children: [
              const Icon(Icons.attach_money, color: AppColors.green),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyMedium?.color)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
            ],
          ),
        ),
      );
} 