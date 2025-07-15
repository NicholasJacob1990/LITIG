import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/lawyer.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';

class PartnerSearchResultList extends StatelessWidget {
  final List<Lawyer> lawyers;
  final List<LawFirm> firms;
  final String emptyMessage;
  final VoidCallback? onRefresh;
  final bool showSourceBadges; // Mostrar badges de fonte (semântico vs diretório)

  const PartnerSearchResultList({
    super.key,
    required this.lawyers,
    required this.firms,
    this.emptyMessage = 'Nenhum resultado encontrado.',
    this.onRefresh,
    this.showSourceBadges = true,
  });

  @override
  Widget build(BuildContext context) {
    final combinedList = [...lawyers, ...firms];

    if (combinedList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.searchX,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final list = RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      child: ListView.builder(
        itemCount: combinedList.length,
        itemBuilder: (context, index) {
          final item = combinedList[index];
          
          if (item is Lawyer) {
            return _buildLawyerCard(context, item);
          }
          if (item is LawFirm) {
            return _buildFirmCard(context, item);
          }
          return const SizedBox.shrink();
        },
      ),
    );

    return list;
  }

  Widget _buildLawyerCard(BuildContext context, Lawyer lawyer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com avatar e info básica
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(lawyer.avatarUrl),
                  onBackgroundImageError: (_, __) {},
                  child: lawyer.avatarUrl.isEmpty 
                    ? const Icon(LucideIcons.user) 
                    : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lawyer.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (showSourceBadges) _buildSourceBadge(context, 'semantic'),
                        ],
                      ),
                      Text(
                        'OAB: ${lawyer.oab}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Info adicional
            Row(
              children: [
                Icon(
                  LucideIcons.gavel,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Advogado(a) Individual',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirmCard(BuildContext context, LawFirm firm) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com ícone e info básica
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    LucideIcons.building2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              firm.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (showSourceBadges) _buildSourceBadge(context, 'directory'),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '${firm.teamSize} advogados',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          // Badge de escritório de grande porte
                          if (firm.isLargeFirm) ...[
                            const SizedBox(width: 8),
                            _buildBoutiqueBadge(context),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Info adicional do escritório
            Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Fundado em ${firm.foundedYear}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (firm.hasLocation) ...[
                  const SizedBox(width: 16),
                  Icon(
                    LucideIcons.mapPin,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Localização definida',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBadge(BuildContext context, String source) {
    final isDirectorySource = source == 'directory';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDirectorySource 
          ? Colors.blue.withValues(alpha: 0.1)
          : Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDirectorySource ? Colors.blue : Colors.purple,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDirectorySource ? LucideIcons.database : LucideIcons.brain,
            size: 12,
            color: isDirectorySource ? Colors.blue : Colors.purple,
          ),
          const SizedBox(width: 4),
          Text(
            isDirectorySource ? 'Diretório' : 'Semântico',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDirectorySource ? Colors.blue : Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoutiqueBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.gem,
            size: 10,
            color: Colors.orange,
          ),
          const SizedBox(width: 2),
          Text(
            'Boutique',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }


} 
 