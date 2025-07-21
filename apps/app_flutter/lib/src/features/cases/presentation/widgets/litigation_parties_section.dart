import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import '../../domain/entities/litigation_party.dart';

/// Widget para exibir as partes processuais em casos contenciosos
class LitigationPartiesSection extends StatelessWidget {
  const LitigationPartiesSection({
    super.key,
    required this.parties,
    this.title = 'Partes Processuais',
    this.showDetails = true,
  });

  final List<LitigationParty> parties;
  final String title;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (parties.isEmpty) {
      return const SizedBox.shrink();
    }

    // Separar partes por tipo
    final plaintiffs = parties.where((party) => party.isPlaintiff).toList();
    final defendants = parties.where((party) => party.isDefendant).toList();
    final others = parties.where((party) => !party.isPlaintiff && !party.isDefendant).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header da seção
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.users,
                      size: 20,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Seção Autores
              if (plaintiffs.isNotEmpty) ...[
                _buildPartyTypeSection(
                  context,
                  'Autor(es)',
                  plaintiffs,
                  LucideIcons.user,
                  AppColors.primaryBlue,
                ),
                if (defendants.isNotEmpty || others.isNotEmpty)
                  const SizedBox(height: 16),
              ],

              // Seção Réus
              if (defendants.isNotEmpty) ...[
                _buildPartyTypeSection(
                  context,
                  'Réu(s)',
                  defendants,
                  LucideIcons.userX,
                  AppColors.error,
                ),
                if (others.isNotEmpty)
                  const SizedBox(height: 16),
              ],

              // Seção Outros (Terceiros, Intervenientes)
              if (others.isNotEmpty) ...[
                _buildPartyTypeSection(
                  context,
                  'Outras Partes',
                  others,
                  LucideIcons.userPlus,
                  AppColors.warning,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartyTypeSection(
    BuildContext context,
    String sectionTitle,
    List<LitigationParty> sectionParties,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da subseção
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              sectionTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Lista de partes
        ...sectionParties.map((party) => _buildPartyItem(context, party, color)),
      ],
    );
  }

  Widget _buildPartyItem(BuildContext context, LitigationParty party, Color accentColor) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome da parte
          Row(
            children: [
              Expanded(
                child: Text(
                  party.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (party.type != PartyType.plaintiff && party.type != PartyType.defendant)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    party.type.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: accentColor,
                    ),
                  ),
                ),
            ],
          ),

          if (showDetails) ...[
            // Documento (CPF/CNPJ)
            if (party.documentNumber != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.credit_card, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text(
                    party.documentNumber!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],

            // Representação legal
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  party.isRepresentedBySelf ? LucideIcons.userCheck : LucideIcons.briefcase,
                  size: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    party.isRepresentedBySelf
                        ? 'Própria pessoa'
                        : party.lawyer ?? 'Sem representação',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontStyle: party.lawyer == null && !party.isRepresentedBySelf
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
              ],
            ),

            // Endereço (se disponível)
            if (party.address != null) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.mapPin, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      party.address!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Notas (se disponível)
            if (party.notes != null && party.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.stickyNote, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        party.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
} 