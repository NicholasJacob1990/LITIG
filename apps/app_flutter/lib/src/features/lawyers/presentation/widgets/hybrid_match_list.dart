import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/matched_lawyer.dart';
import '../../../firms/domain/entities/law_firm.dart';
import '../../../firms/presentation/widgets/firm_card.dart';
import '../../../recommendations/presentation/widgets/lawyer_match_card.dart';

/// Widget para exibir lista híbrida de advogados e escritórios
/// 
/// Este widget renderiza uma lista unificada contendo tanto advogados
/// individuais quanto escritórios, com cabeçalhos de seção opcionais
/// e tratamento adequado para diferentes tipos de entidades.
/// 
/// ## Navegação
/// 
/// O widget oferece duas opções de navegação para escritórios:
/// 
/// ### Navegação Interna (Padrão)
/// - **Tap simples**: Abre FirmDetailScreen dentro da aba atual
/// - **Rota**: `/firm/:firmId`
/// - **Comportamento**: Mantém as abas de navegação visíveis
/// 
/// ### Navegação Externa/Modal
/// - **Long press**: Abre menu com opções de navegação
/// - **Rota**: `/firm-modal/:firmId`
/// - **Comportamento**: Sobrepõe as abas (tela cheia)
/// 
/// ### Menu Contextual (Long Press)
/// - **Ver Detalhes**: Navegação interna
/// - **Abrir em Tela Cheia**: Navegação modal
/// - **Ver Advogados**: Lista de advogados do escritório
/// 
/// ## Renderização
/// 
/// - **Seções separadas** (padrão): Escritórios e advogados em seções distintas
/// - **Resultados mistos**: Lista unificada com prioridade para escritórios
class HybridMatchList extends StatelessWidget {
  final List<MatchedLawyer> lawyers;
  final List<LawFirm> firms;
  final bool showSectionHeaders;
  final String emptyMessage;
  final VoidCallback? onRefresh;
  final bool isLoading;
  final bool showMixedResults;

  const HybridMatchList({
    super.key,
    required this.lawyers,
    required this.firms,
    this.showSectionHeaders = true,
    this.emptyMessage = 'Nenhum resultado encontrado.',
    this.onRefresh,
    this.isLoading = false,
    this.showMixedResults = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasLawyers = lawyers.isNotEmpty;
    final hasFirms = firms.isNotEmpty;

    if (!hasLawyers && !hasFirms) {
      return _buildEmptyState(context);
    }

    // Se showMixedResults for true, renderiza uma lista mista unificada
    if (showMixedResults) {
      return _buildMixedResultsList(context);
    }

    // Renderização por seções (comportamento padrão)
    return _buildSectionedList(context, hasLawyers, hasFirms);
  }

  Widget _buildMixedResultsList(BuildContext context) {
    // Combinar e ordenar resultados mistos
    final mixedResults = <dynamic>[];
    
    // Adicionar escritórios com prioridade (aparecem primeiro)
    mixedResults.addAll(firms);
    
    // Adicionar advogados
    mixedResults.addAll(lawyers);

    return RefreshIndicator(
      onRefresh: onRefresh != null ? () async => onRefresh!() : () async {},
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: mixedResults.length,
        itemBuilder: (context, index) {
          final item = mixedResults[index];
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildMixedResultCard(context, item),
          );
        },
      ),
    );
  }

  Widget _buildMixedResultCard(BuildContext context, dynamic item) {
    if (item is LawFirm) {
      return FirmCard(
        firm: item,
        showKpis: true,
        isCompact: false,
        onTap: () => _navigateToFirmDetail(context, item.id),
        onLongPress: () => _showFirmNavigationOptions(context, item),
      );
    } else if (item is MatchedLawyer) {
      return LawyerMatchCard(
        lawyer: item,
        onSelect: () => _navigateToLawyerDetail(context, item.id),
        onExplain: () => _showExplanation(context, item.id),
      );
    }
    
    // Fallback para tipos não reconhecidos
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text('Tipo de resultado não reconhecido: ${item.runtimeType}'),
    );
  }

  Widget _buildSectionedList(BuildContext context, bool hasLawyers, bool hasFirms) {
    return RefreshIndicator(
      onRefresh: onRefresh != null ? () async => onRefresh!() : () async {},
      child: CustomScrollView(
        slivers: [
          // Seção de Escritórios
          if (hasFirms) ...[
            if (showSectionHeaders) _buildSectionHeader(context, 'Escritórios', firms.length),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final firm = firms[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: FirmCard(
                      firm: firm,
                      showKpis: true,
                      isCompact: false,
                      onTap: () => _navigateToFirmDetail(context, firm.id),
                      onLongPress: () => _showFirmNavigationOptions(context, firm),
                    ),
                  );
                },
                childCount: firms.length,
              ),
            ),
          ],

          // Seção de Advogados
          if (hasLawyers) ...[
            if (showSectionHeaders) _buildSectionHeader(context, 'Advogados', lawyers.length),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final lawyer = lawyers[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: LawyerMatchCard(
                      lawyer: lawyer,
                      onSelect: () => _navigateToLawyerDetail(context, lawyer.id),
                      onExplain: () => _showExplanation(context, lawyer.id),
                    ),
                  );
                },
                childCount: lawyers.length,
              ),
            ),
          ],

          // Espaçamento final
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              title == 'Escritórios' ? LucideIcons.building : LucideIcons.user,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.search,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum resultado encontrado',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            emptyMessage,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (onRefresh != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToFirmDetail(BuildContext context, String firmId) {
    // Usar context.push para navegação interna (dentro da aba)
    _navigateToFirmDetailInternal(context, firmId);
  }

  void _navigateToFirmDetailInternal(BuildContext context, String firmId) {
    // Navegação interna - mantém as abas visíveis
    context.push('/firm/$firmId');
  }

  void _navigateToFirmDetailModal(BuildContext context, String firmId) {
    // Navegação modal - sobrepõe as abas
    context.push('/firm-modal/$firmId');
  }

  void _showFirmNavigationOptions(BuildContext context, LawFirm firm) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opções para ${firm.name}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(LucideIcons.eye),
              title: const Text('Ver Detalhes'),
              subtitle: const Text('Abrir dentro da aba atual'),
              onTap: () {
                Navigator.pop(context);
                _navigateToFirmDetailInternal(context, firm.id);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.externalLink),
              title: const Text('Abrir em Tela Cheia'),
              subtitle: const Text('Abrir cobrindo toda a tela'),
              onTap: () {
                Navigator.pop(context);
                _navigateToFirmDetailModal(context, firm.id);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.users),
              title: const Text('Ver Advogados'),
              subtitle: const Text('Listar advogados do escritório'),
              onTap: () {
                Navigator.pop(context);
                context.push('/firm/${firm.id}/lawyers');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLawyerDetail(BuildContext context, String lawyerId) {
    // TODO: Implementar navegação para detalhes do advogado
    // Navigator.of(context).pushNamed('/lawyer/$lawyerId');
  }

  void _showExplanation(BuildContext context, String lawyerId) {
    // TODO: Implementar modal de explicação
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Explicação para advogado $lawyerId')),
    );
  }
}

/// Widget para exibir estatísticas da busca híbrida
class HybridMatchStats extends StatelessWidget {
  final int lawyersCount;
  final int firmsCount;
  final String searchQuery;

  const HybridMatchStats({
    super.key,
    required this.lawyersCount,
    required this.firmsCount,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final totalResults = lawyersCount + firmsCount;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            LucideIcons.search,
            size: 16,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              totalResults == 0
                  ? 'Nenhum resultado para "$searchQuery"'
                  : '$totalResults resultado${totalResults == 1 ? '' : 's'} para "$searchQuery"',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (totalResults > 0) ...[
            _buildStatChip(context, 'Escritórios', firmsCount, LucideIcons.building),
            const SizedBox(width: 8),
            _buildStatChip(context, 'Advogados', lawyersCount, LucideIcons.user),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String label, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 