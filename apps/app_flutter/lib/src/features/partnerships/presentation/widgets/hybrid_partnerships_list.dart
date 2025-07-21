import 'package:flutter/material.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';
import 'package:meu_app/src/features/partnerships/domain/entities/partnership.dart';
import 'package:meu_app/src/features/partnerships/presentation/widgets/partnership_card.dart';

enum HybridPartnershipsListType {
  active,
  sent,
  received,
}

class HybridPartnershipsList extends StatelessWidget {
  final List<Partnership> lawyerPartnerships;
  final List<LawFirm> firmPartnerships;
  final HybridPartnershipsListType listType;
  final Future<void> Function() onRefresh;

  const HybridPartnershipsList({
    super.key,
    required this.lawyerPartnerships,
    required this.firmPartnerships,
    required this.listType,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = lawyerPartnerships.length + firmPartnerships.length;

    if (totalItems == 0) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: totalItems + 1, // +1 para o header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader(context);
          }

          final adjustedIndex = index - 1;
          
          // Primeiro mostrar parcerias com advogados
          if (adjustedIndex < lawyerPartnerships.length) {
            return _buildLawyerPartnershipCard(
              context,
              lawyerPartnerships[adjustedIndex],
            );
          }
          
          // Depois mostrar parcerias com escritórios
          final firmIndex = adjustedIndex - lawyerPartnerships.length;
          if (firmIndex < firmPartnerships.length) {
            return _buildFirmPartnershipCard(
              context,
              firmPartnerships[firmIndex],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    String title;
    String subtitle;
    IconData icon;
    Color color;

    switch (listType) {
      case HybridPartnershipsListType.active:
        title = 'Parcerias Ativas';
        subtitle = '${lawyerPartnerships.length} advogados, ${firmPartnerships.length} escritórios';
        icon = Icons.handshake;
        color = Colors.green;
        break;
      case HybridPartnershipsListType.sent:
        title = 'Propostas Enviadas';
        subtitle = '${lawyerPartnerships.length} propostas aguardando resposta';
        icon = Icons.send;
        color = Colors.blue;
        break;
      case HybridPartnershipsListType.received:
        title = 'Propostas Recebidas';
        subtitle = '${lawyerPartnerships.length} propostas para avaliar';
        icon = Icons.inbox;
        color = Colors.orange;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLawyerPartnershipCard(BuildContext context, Partnership partnership) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          // TODO: Implementar navegação para detalhes da parceria
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Parceria com ${partnership.partnerName}'),
              backgroundColor: Colors.blue,
            ),
          );
        },
        child: PartnershipCard(
          partnership: partnership,
        ),
      ),
    );
  }

  Widget _buildFirmPartnershipCard(BuildContext context, LawFirm firm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        child: Column(
          children: [
            // Header indicando que é uma parceria com escritório
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    size: 16,
                    color: Colors.green[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Parceria com Escritório',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(HybridPartnershipsListType.active),
                ],
              ),
            ),
            // FirmCard com informações completas B2B
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  // TODO: Implementar navegação para detalhes da parceria com escritório
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Parceria B2B com ${firm.name}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            firm.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (firm.isLargeFirm)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'GRANDE PORTE',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${firm.teamSize} advogados • Fundado em ${firm.foundedYear}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (firm.hasLocation) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${firm.mainLat!.toStringAsFixed(2)}, ${firm.mainLon!.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (firm.kpis != null) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildKpiChip('Taxa de Sucesso', '${firm.kpis!.successRatePercentage.toStringAsFixed(0)}%', Colors.green),
                          _buildKpiChip('NPS', '${firm.kpis!.npsPercentage.toStringAsFixed(0)}%', Colors.blue),
                          _buildKpiChip('${firm.kpis!.activeCases}', 'Casos Ativos', Colors.orange),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(HybridPartnershipsListType type) {
    Color color;
    String label;

    switch (type) {
      case HybridPartnershipsListType.active:
        color = Colors.green;
        label = 'Ativa';
        break;
      case HybridPartnershipsListType.sent:
        color = Colors.blue;
        label = 'Enviada';
        break;
      case HybridPartnershipsListType.received:
        color = Colors.orange;
        label = 'Recebida';
        break;
    }

    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    String message;
    IconData icon;

    switch (listType) {
      case HybridPartnershipsListType.active:
        message = 'Nenhuma parceria ativa.\nBusque novos parceiros para começar.';
        icon = Icons.handshake_outlined;
        break;
      case HybridPartnershipsListType.sent:
        message = 'Nenhuma proposta enviada.\nEnvie propostas para advogados ou escritórios.';
        icon = Icons.send_outlined;
        break;
      case HybridPartnershipsListType.received:
        message = 'Nenhuma proposta recebida.\nAguarde propostas de outros parceiros.';
        icon = Icons.inbox_outlined;
        break;
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navegar para busca de parceiros
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar Parceiros'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.6),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
} 