import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/partnerships/presentation/widgets/hybrid_partnerships_list.dart' show HybridPartnershipsListType;
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
  /// Contexto da lista (Ativas, Enviadas, Recebidas) para CTA contextual
  final HybridPartnershipsListType? listContext;
  /// Callbacks para ações rápidas (usado principalmente em Recebidas)
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  /// ID do usuário atual (para determinar direção: enviada/recebida)
  final String? currentUserId;

  /// {@macro partnership_card}
  const PartnershipCard({
    super.key,
    required this.partnership,
    this.listContext,
    this.onAccept,
    this.onReject,
    this.currentUserId,
  });

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
            context.go('/partnerships/${partnership.id}', extra: {'partnership': partnership});
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
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                'Iniciada ${timeago.format(partnership.createdAt, locale: 'pt_BR')}',
                                style: textTheme.bodySmall,
                              ),
                              if (partnership.linkedCaseId != null && partnership.linkedCaseId!.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 4),
                                    const Icon(Icons.link, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      partnership.linkedCaseTitle != null && partnership.linkedCaseTitle!.isNotEmpty
                                          ? partnership.linkedCaseTitle!
                                          : 'Caso ${partnership.linkedCaseId}',
                                      style: textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 4),
                                    const Icon(Icons.public, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Externa',
                                      style: textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                            ],
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
                    const SizedBox(width: 6),
                    _buildDirectionBadge(context),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/partnerships/${partnership.id}', extra: {'partnership': partnership}),
                      child: const Text('Ver Detalhes'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (partnership.honorarios != null || partnership.proposalMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        if (partnership.honorarios != null)
                          Chip(
                            avatar: const Icon(Icons.payments_outlined, size: 16),
                            label: Text(partnership.honorarios!),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        const SizedBox(width: 8),
                        if (partnership.proposalMessage != null)
                          Expanded(
                            child: Text(
                              partnership.proposalMessage!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                            ),
                          ),
                      ],
                    ),
                  ),
                _buildActivityBadges(),
                const SizedBox(height: 8),
                _buildContextualActions(context, colorScheme),
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
    final avatar = partnership.partnerAvatarUrl;
    if (avatar.isEmpty) {
      return CircleAvatar(
        radius: 20,
        child: Icon(
          Icons.person,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      );
    }
    return CircleAvatar(
      radius: 20,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatar,
          fit: BoxFit.cover,
          width: 40,
          height: 40,
          placeholder: (context, url) => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) => Icon(
            Icons.person,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
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
        backgroundColor = colorScheme.secondaryContainer;
        textColor = colorScheme.onSecondaryContainer;
        break;
    }

    return Chip(
      label: Text(text),
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildDirectionBadge(BuildContext context) {
    if (currentUserId == null || currentUserId!.isEmpty) {
      return const SizedBox.shrink();
    }
    final direction = partnership.directionForUser(currentUserId!);
    if (direction == null) return const SizedBox.shrink();

    final isSent = direction == 'sent';
    final color = isSent ? Colors.blue : Colors.orange;
    final icon = isSent ? Icons.north_east : Icons.south_west;
    final label = isSent ? 'Enviada' : 'Recebida';

    return Chip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildActivityBadges() {
    if (partnership.unreadCount == null && partnership.lastActivityAt == null && partnership.slaDueAt == null) {
      return const SizedBox.shrink();
    }
    final items = <Widget>[];
    if (partnership.unreadCount != null && (partnership.unreadCount ?? 0) > 0) {
      items.add(Chip(
        avatar: const Icon(Icons.mark_chat_unread, size: 14),
        label: Text('${partnership.unreadCount} não lidos'),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ));
    }
    if (partnership.lastActivityAt != null) {
      items.add(Chip(
        avatar: const Icon(Icons.update, size: 14),
        label: Text('Atividade: ${timeago.format(partnership.lastActivityAt!, locale: 'pt_BR')}'),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ));
    }
    if (partnership.slaDueAt != null) {
      items.add(Chip(
        avatar: const Icon(Icons.timer, size: 14),
        label: Text('SLA: ${timeago.format(partnership.slaDueAt!, locale: 'pt_BR')}'),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ));
    }
    return Wrap(spacing: 6, runSpacing: 4, children: items);
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
        icon = Icons.workspaces_outline;
        break;
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

  // Ações contextuais por aba
  Widget _buildContextualActions(BuildContext context, ColorScheme colorScheme) {
    switch (listContext) {
      case HybridPartnershipsListType.active:
        return Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () {
              if (partnership.partnerType == PartnerEntityType.lawyer && partnership.partnerAsLawyer != null) {
                final partner = partnership.partnerAsLawyer!;
                context.go('/internal-chat/${partner.id}?recipientName=${Uri.encodeComponent(partner.name)}');
              } else if (partnership.partnerType == PartnerEntityType.firm && partnership.partnerAsFirm != null) {
                final firm = partnership.partnerAsFirm!;
                context.go('/firm/${firm.id}/profile');
              }
            },
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Conversar'),
          ),
        );
      case HybridPartnershipsListType.sent:
        return Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                label: const Text('Proposta Enviada'),
                backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.35),
                labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/partnerships/${partnership.id}', extra: {'partnership': partnership}),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Revisar'),
              ),
            ],
          ),
        );
      case HybridPartnershipsListType.received:
        return Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onReject ?? () => context.go('/partnerships/${partnership.id}', extra: {'partnership': partnership}),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Rejeitar'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
              ElevatedButton.icon(
                onPressed: onAccept ?? () => context.go('/partnerships/${partnership.id}', extra: {'partnership': partnership}),
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Aceitar'),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
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
      return 'Divisão de Caso';
  }
}