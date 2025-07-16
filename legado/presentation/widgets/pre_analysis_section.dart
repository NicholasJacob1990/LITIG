import 'package:flutter/material.dart';
import '../../../../shared/utils/app_colors.dart';

class PreAnalysisSection extends StatelessWidget {
  const PreAnalysisSection({super.key});

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // badge HIGH -----------------------------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: AppColors.orange, borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.access_time, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('HIGH',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 12),

            // título ---------------------------------------------
            Text('Direito Trabalhista',
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
              child: Text('Análise Preliminar por IA\n'
                  'Sujeita a conferência humana',
                  style: t.bodyMedium!.copyWith(color: Colors.white),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),

            // prazo + urgência -----------------------------------
            infoRow(Icons.schedule, 'Prazo Estimado', '15 dias úteis'),
            const SizedBox(height: 8),
            Text('Nível de Urgência',
                style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Stack(children: [
              // fundo cinza
              Container(
                  height: 6,
                  decoration: BoxDecoration(
                      color: AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(3))),
              // 8/10 preenchido
              FractionallySizedBox(
                widthFactor: .8,
                child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(3))),
              ),
            ]),
            const SizedBox(height: 24),

            // Análise preliminar ---------------------------------
            Text('Análise Preliminar',
                style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Com base nas informações fornecidas, identifica-se uma possível '
              'demissão sem justa causa com irregularidades no pagamento das '
              'verbas rescisórias…',
              style: t.bodySmall,
            ),
            const SizedBox(height: 20),

            // Documentos necessários -----------------------------
            Text('Documentos Necessários',
                style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...[
              'Contrato de trabalho',
              'Carta de demissão',
              'Comprovantes de pagamento'
            ]
                .map((d) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        const Icon(Icons.description,
                            size: 16, color: AppColors.green),
                        const SizedBox(width: 6),
                        Text(d),
                      ]),
                    ))
                ,
            const SizedBox(height: 2),
            Text('+2  documentos adicionais',
                style:
                    t.bodySmall!.copyWith(color: AppColors.lightText2)),
            const SizedBox(height: 24),

            // Estimativa de custos -------------------------------
            Text('Estimativa de Custos',
                style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              _costCard(context, 'Consulta', 'R\$ 350,00'),
              const SizedBox(width: 12),
              _costCard(context, 'Representação', 'R\$ 2.500,00'),
            ]),
            const SizedBox(height: 24),

            // Avaliação de risco --------------------------------
            Text('Avaliação de Risco',
                style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Risco baixo. Documentação sólida e jurisprudência favorável. '
              'Recomenda-se prosseguir com a consulta especializada.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Ver Análise Completa'),
            )
          ],
        ),
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