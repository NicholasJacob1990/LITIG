import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/lawyer.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';

/// Cartão compacto para aba "Buscar" (140-160px)
/// 
/// Otimizado para performance e escaneabilidade, com foco em
/// descoberta e exploração inicial de advogados/escritórios.
class CompactSearchCard extends StatefulWidget {
  final dynamic item; // Pode ser Lawyer, MatchedLawyer ou LawFirm
  final VoidCallback? onSelect;
  final VoidCallback? onViewProfile;

  const CompactSearchCard({
    super.key,
    required this.item,
    this.onSelect,
    this.onViewProfile,
  });

  @override
  State<CompactSearchCard> createState() => _CompactSearchCardState();
}

class _CompactSearchCardState extends State<CompactSearchCard> {
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
          color: theme.dividerColor.withValues(alpha: 0.2),
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
            // Header: Avatar + Nome + Área
            Row(
              children: [
                _buildAvatar(theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getName(),
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
                            LucideIcons.briefcase,
                            size: 12,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _getPrimaryArea(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Badges Dinâmicos
            _buildDynamicBadges(),
            
            const SizedBox(height: 8),
            
            // Link Expansível "Por que este advogado/escritório?"
            _buildExpandableLink(theme),
            
            const Spacer(),
            
            // Botões de Ação
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    final avatarUrl = _getAvatarUrl();
    
    if (avatarUrl != null) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: CachedNetworkImageProvider(avatarUrl),
        backgroundColor: theme.colorScheme.surface,
      );
    }
    
    // Fallback para escritórios ou advogados sem foto
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Icon(
        _isLawFirm() ? LucideIcons.building : LucideIcons.user,
        size: 20,
        color: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildDynamicBadges() {
    final badges = _getBadges();
    
    if (badges.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: badges.take(3).map((badge) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getBadgeColor(badge.source).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBadgeColor(badge.source).withValues(alpha: 0.3),
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
            color: AppColors.primaryBlue.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _isLawFirm() 
                ? 'Por que este escritório?' 
                : 'Por que este advogado?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primaryBlue.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          Icon(
            _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            size: 14,
            color: AppColors.primaryBlue.withValues(alpha: 0.8),
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
            onPressed: widget.onViewProfile,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: const Text(
              'Ver Perfil',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  // Helper Methods
  
  String _getName() {
    if (widget.item is MatchedLawyer) {
      return (widget.item as MatchedLawyer).nome;
    } else if (widget.item is Lawyer) {
      return (widget.item as Lawyer).name;
    } else {
      // LawFirm
      return widget.item.name ?? 'Escritório';
    }
  }

  String _getPrimaryArea() {
    if (widget.item is MatchedLawyer) {
      return (widget.item as MatchedLawyer).primaryArea;
    } else if (widget.item is Lawyer) {
      final areas = (widget.item as Lawyer).expertiseAreas;
      return areas.isNotEmpty ? areas.first : 'Direito Geral';
    } else {
      // LawFirm - return main areas
      return 'Direito Empresarial'; // Placeholder
    }
  }

  String? _getAvatarUrl() {
    if (widget.item is MatchedLawyer) {
      return (widget.item as MatchedLawyer).avatarUrl;
    } else if (widget.item is Lawyer) {
      return (widget.item as Lawyer).avatarUrl;
    }
    return null; // LawFirm typically doesn't have avatar
  }

  bool _isLawFirm() {
    return widget.item.runtimeType.toString().contains('LawFirm');
  }

  List<Badge> _getBadges() {
    // Mock badges implementation - will be enhanced with real data
    if (widget.item is MatchedLawyer) {
      final lawyer = widget.item as MatchedLawyer;
      return [
        if (lawyer.awards.isNotEmpty) 
          Badge(title: lawyer.awards.first, source: BadgeSource.certified),
        const Badge(title: 'Plataforma', source: BadgeSource.platform),
        if (lawyer.rating != null && lawyer.rating! > 4.5)
          const Badge(title: 'Top Rated', source: BadgeSource.api),
      ];
    }
    
    return [
      const Badge(title: 'Verificado', source: BadgeSource.platform),
      const Badge(title: 'Certificado', source: BadgeSource.certified),
    ];
  }

  Color _getBadgeColor(BadgeSource source) {
    switch (source) {
      case BadgeSource.api:
        return AppColors.warning; // APIs externas - dourado
      case BadgeSource.platform:
        return AppColors.primaryBlue; // Sistema interno - azul
      case BadgeSource.certified:
        return AppColors.success; // Certificado - verde
      case BadgeSource.declared:
        return AppColors.lightTextSecondary; // Auto-declarado - cinza
    }
  }
}

/// Estrutura para badges dinâmicos
class Badge {
  final String title;
  final BadgeSource source;

  const Badge({
    required this.title,
    required this.source,
  });
}

/// Fonte dos badges para determinar cores e credibilidade
enum BadgeSource {
  api,        // APIs externas (máxima credibilidade)
  platform,   // Sistema interno (métricas da plataforma)
  certified,  // Certificados verificados
  declared,   // Auto-declarados (menor credibilidade)
} 