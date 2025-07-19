import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import 'compact_search_card.dart' as search_card; // Import for Badge classes
import '../../../lawyers/presentation/widgets/lawyer_social_links.dart';

/// Cartão compacto para escritórios na aba "Buscar" (140-160px)
/// 
/// Implementa paridade completa com cartões de advogados,
/// otimizado para descoberta e exploração inicial.
class CompactFirmCard extends StatefulWidget {
  final LawFirm firm;
  final VoidCallback? onSelect;
  final VoidCallback? onViewFirm;

  const CompactFirmCard({
    super.key,
    required this.firm,
    this.onSelect,
    this.onViewFirm,
  });

  @override
  State<CompactFirmCard> createState() => _CompactFirmCardState();
}

class _CompactFirmCardState extends State<CompactFirmCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      elevation: 2,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 140,
          maxHeight: 160,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Logo + Nome + Áreas Principais
            Row(
              children: [
                _buildLogo(theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.firm.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.building,
                            size: 12,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _getMainLegalAreas(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Ícones das redes sociais
                          LawyerSocialLinks(
                            linkedinUrl: 'https://linkedin.com/company/${widget.firm.name.toLowerCase()}',
                            instagramUrl: 'https://instagram.com/${widget.firm.name.toLowerCase()}',
                            facebookUrl: 'https://facebook.com/${widget.firm.name.toLowerCase()}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Badges Dinâmicos Institucionais
            _buildInstitutionalBadges(),
            
            const SizedBox(height: 8),
            
            // Link Expansível "Por que este escritório?"
            _buildExpandableLink(theme),
            
            const Spacer(),
            
            // Botões de Ação
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    // Escritórios geralmente não têm logo individual,
    // então usamos um container estilizado
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: const Icon(
        LucideIcons.building2,
        size: 20,
        color: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildInstitutionalBadges() {
    final badges = _getInstitutionalBadges();
    
    if (badges.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: badges.take(3).map((badge) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getBadgeColor(badge.source).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBadgeColor(badge.source).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          badge.title,
          style: TextStyle(
            color: _getBadgeColor(badge.source),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildExpandableLink(ThemeData theme) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Row(
        children: [
          Icon(
            LucideIcons.helpCircle,
            size: 14,
            color: AppColors.primaryBlue.withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Por que este escritório?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primaryBlue.withOpacity(0.8),
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          Icon(
            _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            size: 14,
            color: AppColors.primaryBlue.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: ElevatedButton(
            onPressed: widget.onSelect,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Selecionar',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
                      child: TextButton(
              onPressed: () => _navigateToTeamView(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'Ver Equipe',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ),
        ),
      ],
    );
  }

  // Helper Methods
  
  String _getMainLegalAreas() {
    // Implementar baseado nas áreas do escritório
    // Por enquanto, retorna um placeholder
    if (widget.firm.specializations.isNotEmpty) {
      // Pegar as 2-3 principais áreas
      final areas = widget.firm.specializations.take(2).join(' • ');
      return areas;
    }
    return 'Direito Empresarial • Tributário';
  }

  List<search_card.Badge> _getInstitutionalBadges() {
    final badges = <search_card.Badge>[];
    
    // Badges baseados em KPIs e certificações institucionais
    if (widget.firm.kpis?.nps != null && widget.firm.kpis!.nps > 8.0) {
      badges.add(const search_card.Badge(title: 'Alto NPS', source: search_card.BadgeSource.platform));
    }
    
    if (widget.firm.kpis?.successRate != null && widget.firm.kpis!.successRate > 0.85) {
      badges.add(const search_card.Badge(title: '85%+ Êxito', source: search_card.BadgeSource.api));
    }
    
    // Certificações/Selos institucionais (placeholder)
    badges.add(const search_card.Badge(title: 'Selo OAB-SP', source: search_card.BadgeSource.certified));
    
    if (widget.firm.foundedYear != null) {
      final yearsOperation = DateTime.now().year - widget.firm.foundedYear!;
      if (yearsOperation > 10) {
        badges.add(search_card.Badge(title: '$yearsOperation anos', source: search_card.BadgeSource.platform));
      }
    }
    
    return badges;
  }

  Color _getBadgeColor(search_card.BadgeSource source) {
    switch (source) {
      case search_card.BadgeSource.api:
        return AppColors.warning; // APIs externas - dourado
      case search_card.BadgeSource.platform:
        return AppColors.primaryBlue; // Sistema interno - azul
      case search_card.BadgeSource.certified:
        return AppColors.success; // Certificado - verde
      case search_card.BadgeSource.declared:
        return AppColors.lightTextSecondary; // Auto-declarado - cinza
    }
  }

  void _navigateToTeamView(BuildContext context) {
    context.push('/firm/${widget.firm.id}/lawyers');
  }
} 