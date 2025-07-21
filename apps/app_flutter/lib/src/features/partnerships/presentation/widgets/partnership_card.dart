import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:meu_app/src/features/partnerships/domain/entities/partnership.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Um widget de card para exibir um resumo de uma [Partnership].
///
/// Mostra os detalhes do parceiro (advogado ou escritório), o status,
/// o tipo e o título da parceria. Fornecer um rótulo semântico abrangente
/// para uma melhor acessibilidade.
class PartnershipCard extends StatelessWidget {
  /// A parceria a ser exibida.
  final Partnership partnership;

  /// {@macro partnership_card}
  const PartnershipCard({super.key, required this.partnership});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Define o rótulo semântico para leitores de tela.
    final semanticLabel =
        'Parceria com ${partnership.partnerName} sobre "${partnership.title}". '
        'Tipo: ${_getPartnershipTypeLabel(partnership.type)}. '
        'Status: ${_getPartnershipStatusLabel(partnership.status)}. '
        'Iniciada ${timeago.format(partnership.createdAt, locale: 'pt_BR')}.';

    return Semantics(
      label: semanticLabel,
      container: true,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // TODO: Implementar navegação para detalhes da parceria
            // Ex: context.go('/partnerships/${partnership.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildPartnerAvatar(context),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partnership.partnerName,
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Parceria iniciada ${timeago.format(partnership.createdAt, locale: 'pt_BR')}',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(partnership.status, colorScheme),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  partnership.title,
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTypeChip(partnership.type, colorScheme),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // TODO: Implementar navegação para detalhes da parceria
                        // Ex: context.go('/partnerships/${partnership.id}');
                      },
                      child: const Text('Ver Detalhes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (partnership.partnerType == PartnerEntityType.firm) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: colorScheme.secondaryContainer,
        child: Icon(
          Icons.business,
          color: colorScheme.onSecondaryContainer,
          size: 22,
        ),
      );
    }
    
    // Padrão para advogado
    return CircleAvatar(
      radius: 20,
      backgroundImage: CachedNetworkImageProvider(partnership.partnerAvatarUrl),
      // Fallback em caso de erro ao carregar a imagem
      onBackgroundImageError: (_, __) {},
      child: CachedNetworkImage(
        imageUrl: partnership.partnerAvatarUrl,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
        ),
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(
          Icons.person,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildStatusChip(PartnershipStatus status, ColorScheme colorScheme) {
    final String text = _getPartnershipStatusLabel(status);
    final Color backgroundColor;
    final Color textColor;

    switch (status) {
      case PartnershipStatus.active:
        backgroundColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        break;
      case PartnershipStatus.negotiation:
        backgroundColor = colorScheme.tertiaryContainer;
        textColor = colorScheme.onTertiaryContainer;
        break;
      case PartnershipStatus.closed:
      case PartnershipStatus.rejected:
        backgroundColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
        break;
      case PartnershipStatus.pending:
      default: // Garante robustez contra novos status
        backgroundColor = colorScheme.secondaryContainer;
        textColor = colorScheme.onSecondaryContainer;
    }

    return Chip(
      label: Text(text),
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildTypeChip(PartnershipType type, ColorScheme colorScheme) {
    final String text = _getPartnershipTypeLabel(type);
    final IconData icon;

    switch (type) {
      case PartnershipType.correspondent:
        icon = Icons.location_on_outlined;
        break;
      case PartnershipType.expertOpinion:
        icon = Icons.school_outlined;
        break;
      case PartnershipType.caseSharing:
      default: // Garante robustez contra novos tipos
        icon = Icons.workspaces_outline;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: colorScheme.secondary),
      label: Text(text),
      backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.3),
      labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// Funções auxiliares para obter os rótulos, facilitando a reutilização e a internacionalização no futuro.
String _getPartnershipStatusLabel(PartnershipStatus status) {
  switch (status) {
    case PartnershipStatus.active:
      return 'Ativa';
    case PartnershipStatus.negotiation:
      return 'Em Negociação';
    case PartnershipStatus.closed:
      return 'Fechada';
    case PartnershipStatus.rejected:
      return 'Rejeitada';
    case PartnershipStatus.pending:
    default:
      return 'Pendente';
  }
}

String _getPartnershipTypeLabel(PartnershipType type) {
  switch (type) {
    case PartnershipType.correspondent:
      return 'Correspondente';
    case PartnershipType.expertOpinion:
      return 'Parecerista';
    case PartnershipType.caseSharing:
    default:
      return 'Divisão de Caso';
  }
}