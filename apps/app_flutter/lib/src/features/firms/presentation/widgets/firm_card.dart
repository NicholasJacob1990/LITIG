import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/law_firm.dart';
import '../../domain/entities/firm_kpi.dart';
import 'firm_card_helpers.dart';
import 'firm_match_explanation_dialog.dart';
import 'package:meu_app/src/shared/widgets/instrumented_widgets.dart';

/// Widget reutilizável para exibir informações de um escritório de advocacia
/// 
/// Este widget apresenta as informações básicas de um escritório de forma
/// consistente em listas e grids, incluindo nome, tamanho da equipe,
/// localização e indicadores de performance quando disponíveis.
class FirmCard extends StatelessWidget {
  final LawFirm firm;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onHire;
  final bool showKpis;
  final bool isCompact;
  final bool showHireButton;
  // Novos parâmetros para instrumentação
  final String? sourceContext;
  final String? searchQuery;
  final double? searchRank;
  final Map<String, dynamic>? searchFilters;
  final String? caseContext;

  const FirmCard({
    super.key,
    required this.firm,
    this.onTap,
    this.onLongPress,
    this.onHire,
    this.showKpis = true,
    this.isCompact = false,
    this.showHireButton = false,
    this.sourceContext,
    this.searchQuery,
    this.searchRank,
    this.searchFilters,
    this.caseContext,
  });

  @override
  Widget build(BuildContext context) {
    // Acesso seguro aos KPIs a partir da entidade firm
    final kpis = firm.kpis;

    return InstrumentedProfileCard(
      profileId: firm.id,
      profileType: 'firm',
      sourceContext: sourceContext ?? 'firm_list',
      searchQuery: searchQuery,
      searchRank: searchRank,
      searchFilters: searchFilters,
      caseContext: caseContext,
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.symmetric(
          horizontal: isCompact ? 8.0 : 16.0,
          vertical: isCompact ? 4.0 : 8.0,
        ),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, kpis),
                if (!isCompact) ...[
                  const SizedBox(height: 12),
                  _buildDetails(context),
                ],
                if (showKpis && kpis != null && !isCompact) ...[
                  const SizedBox(height: 12),
                  _buildKpis(context, kpis),
                ],
                if (showHireButton && !isCompact) ...[
                  const SizedBox(height: 16),
                  _buildActionButtons(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FirmKPI? kpis) {
    return Row(
      children: [
        // Ícone do escritório
        Container(
          width: isCompact ? 40 : 48,
          height: isCompact ? 40 : 48,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.business,
            color: Theme.of(context).primaryColor,
            size: isCompact ? 20 : 24,
          ),
        ),
        const SizedBox(width: 12),
        // Nome e informações básicas
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firm.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 14 : 16,
                ),
                maxLines: isCompact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: isCompact ? 14 : 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${firm.teamSize} ${firm.teamSize == 1 ? 'advogado' : 'advogados'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: isCompact ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Indicador de qualidade (se disponível)
        if (kpis != null && showKpis)
          _buildQualityIndicator(context, kpis),
      ],
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Localização (se disponível)
        if (firm.hasLocation) ...[
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Lat: ${firm.mainLat!.toStringAsFixed(3)}, Lon: ${firm.mainLon!.toStringAsFixed(3)}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        // Data de criação
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 4),
            Text(
              firm.createdAt != null 
                ? 'Criado em ${formatDate(firm.createdAt!)}'
                : 'Data de criação não disponível',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpis(BuildContext context, FirmKPI kpis) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildKpiItem(
            context,
            'Taxa de Sucesso',
            '${(kpis.successRate * 100).toStringAsFixed(0)}%',
            Icons.trending_up,
            getSuccessRateColor(kpis.successRate),
          ),
          _buildKpiItem(
            context,
            'NPS',
            kpis.nps.toStringAsFixed(0),
            Icons.star,
            getNpsColor(kpis.nps),
          ),
          _buildKpiItem(
            context,
            'Casos Ativos',
            kpis.activeCases.toString(),
            Icons.folder,
            Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQualityIndicator(BuildContext context, FirmKPI kpis) {
    // Usa o reputationScore diretamente, que já é pré-calculado
    final score = kpis.reputationScore;
    final color = getReputationScoreColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            // O score agora é de 0-100, formatamos para uma casa decimal
            (score / 10).toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Primeira linha: Ver Perfil (destaque) - Instrumentado
        SizedBox(
          width: double.infinity,
          child: InstrumentedButton(
            elementId: 'view_firm_profile_${firm.id}',
            context: 'firm_card',
            onPressed: () => _navigateToFirmProfile(context),
            additionalData: {
              'firm_id': firm.id,
              'firm_name': firm.name,
              'source_context': sourceContext,
              'search_rank': searchRank,
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.building, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Ver Perfil do Escritório', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Segunda linha: Ações rápidas - Instrumentadas
        Row(
          children: [
            Expanded(
              child: InstrumentedButton(
                elementId: 'firm_details_${firm.id}',
                context: 'firm_card',
                onPressed: onTap,
                additionalData: {
                  'firm_id': firm.id,
                  'action_type': 'view_details',
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility, size: 16),
                    SizedBox(width: 4),
                    Text('Detalhes'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InstrumentedButton(
              elementId: 'firm_explanation_${firm.id}',
              context: 'firm_card',
              onPressed: () => _showFirmMatchExplanation(context),
              additionalData: {
                'firm_id': firm.id,
                'action_type': 'explanation_request',
              },
              child: Icon(
                LucideIcons.helpCircle,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InstrumentedInviteButton(
                invitationType: 'firm_hire',
                recipientId: firm.id,
                context: 'firm_card',
                caseId: caseContext,
                recipientType: 'firm',
                onPressed: onHire ?? () {},
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.handshake, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Contratar', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToFirmProfile(BuildContext context) {
    context.push('/firm/${firm.id}/profile');
  }

  void _showFirmMatchExplanation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FirmMatchExplanationDialog(
        firm: firm,
        onViewFullProfile: () {
          Navigator.of(context).pop();
          _navigateToFirmProfile(context);
        },
      ),
    );
  }
} 