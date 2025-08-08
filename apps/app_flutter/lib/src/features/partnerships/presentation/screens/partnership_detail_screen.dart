import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/partnerships/domain/entities/partnership.dart';

class PartnershipDetailScreen extends StatelessWidget {
  final String partnershipId;
  final Partnership? initialData;

  const PartnershipDetailScreen({
    super.key,
    required this.partnershipId,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = initialData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Parceria'),
        actions: [
          IconButton(
            tooltip: 'Ir para conversa',
            icon: const Icon(Icons.chat_outlined),
            onPressed: () {
              if (data != null && data.partnerType == PartnerEntityType.lawyer && data.partnerAsLawyer != null) {
                final partner = data.partnerAsLawyer!;
                context.go('/internal-chat/${partner.id}?recipientName=${Uri.encodeComponent(partner.name)}');
              }
            },
          )
        ],
      ),
      body: data == null
          ? _buildLoadingPlaceholder(theme)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, data),
                  const SizedBox(height: 16),
                  _buildOverviewCards(context, data),
                  const SizedBox(height: 16),
                  _buildLinkedCaseContext(context, data),
                  const SizedBox(height: 16),
                  _buildScopeSection(context, data),
                  const SizedBox(height: 16),
                  _buildContractSection(context, data),
                  const SizedBox(height: 16),
                  _buildFinanceSection(context, data),
                  const SizedBox(height: 16),
                  _buildSlaTimelineSection(context, data),
                  const SizedBox(height: 16),
                  _buildComplianceSection(context, data),
                  const SizedBox(height: 16),
                  _buildActions(context, data),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingPlaceholder(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 24, width: 160, color: theme.colorScheme.surfaceVariant),
          const SizedBox(height: 12),
          Container(height: 16, width: 220, color: theme.colorScheme.surfaceVariant),
          const SizedBox(height: 24),
          Container(height: 120, color: theme.colorScheme.surfaceVariant),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Partnership partnership) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(partnership.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(partnership.type.toString().split('.').last)),
                const SizedBox(width: 8),
                Chip(label: Text(partnership.status.toString().split('.').last)),
                const SizedBox(width: 8),
                if (partnership.linkedCaseId != null && partnership.linkedCaseId!.isNotEmpty)
                  ActionChip(
                    label: Text(
                      partnership.linkedCaseTitle?.isNotEmpty == true
                          ? partnership.linkedCaseTitle!
                          : 'Abrir Caso ${partnership.linkedCaseId}',
                    ),
                    avatar: const Icon(Icons.folder_open, size: 16),
                    onPressed: () => context.go('/case-detail/${partnership.linkedCaseId}'),
                  )
                else
                  const Chip(label: Text('Parceria Externa')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    partnership.partnerName,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, Partnership partnership) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Honorários', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 6),
                  Text(partnership.honorarios ?? 'A definir', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data de Início', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 6),
                  Text('${partnership.createdAt.day}/${partnership.createdAt.month}/${partnership.createdAt.year}', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, Partnership partnership) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: partnership.contractUrl != null && partnership.contractUrl!.isNotEmpty
                ? () => context.go('/partnerships/${partnership.id}')
                : null,
            icon: const Icon(Icons.description_outlined),
            label: const Text('Ver Contrato'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/chat/${partnership.id}?otherPartyName=${Uri.encodeComponent(partnership.partnerName)}'),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Abrir Chat'),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedCaseContext(BuildContext context, Partnership p) {
    if (p.linkedCaseId == null || p.linkedCaseId!.isEmpty) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.folder_open),
        title: Text(p.linkedCaseTitle?.isNotEmpty == true ? p.linkedCaseTitle! : 'Caso ${p.linkedCaseId}'),
        subtitle: Text('Tipo: ${p.linkedCaseType ?? '-'} • Status: ${p.linkedCaseStatus ?? '-'}'),
        trailing: TextButton.icon(
          onPressed: () => context.go('/case-detail/${p.linkedCaseId}'),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Abrir Caso'),
        ),
      ),
    );
  }

  Widget _buildScopeSection(BuildContext context, Partnership p) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Escopo & Responsabilidades', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(p.proposalMessage ?? 'Escopo a definir', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildContractSection(BuildContext context, Partnership p) {
    final theme = Theme.of(context);
    final hasContract = p.contractUrl != null && p.contractUrl!.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contrato', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.description_outlined, size: 16),
                  label: Text(hasContract ? 'Gerado' : 'Pendente'),
                ),
                const SizedBox(width: 8),
                if (p.contractAcceptedAt != null)
                  Chip(
                    avatar: const Icon(Icons.verified, size: 16),
                    label: Text('Assinado em ${p.contractAcceptedAt!.day}/${p.contractAcceptedAt!.month}/${p.contractAcceptedAt!.year}'),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: hasContract ? () => context.go('/partnerships/${p.id}') : null,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceSection(BuildContext context, Partnership p) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financeiro', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(avatar: const Icon(Icons.payments, size: 16), label: Text('Honorários: ${p.honorarios ?? '-'}')),
                Chip(avatar: const Icon(Icons.account_tree, size: 16), label: Text('Modelo: ${p.feeModel ?? '-'}')),
                Chip(avatar: const Icon(Icons.percent, size: 16), label: Text('Split: ${p.feeSplitPercent?.toStringAsFixed(0) ?? '-'}%')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlaTimelineSection(BuildContext context, Partnership p) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SLA & Timeline', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (p.slaDueAt != null)
                  Chip(avatar: const Icon(Icons.timer, size: 16), label: Text('SLA: ${p.slaDueAt!.day}/${p.slaDueAt!.month}/${p.slaDueAt!.year}')),
                if (p.lastActivityAt != null)
                  Chip(avatar: const Icon(Icons.update, size: 16), label: Text('Última atividade: ${p.lastActivityAt!.day}/${p.lastActivityAt!.month}/${p.lastActivityAt!.year}')),
                if (p.unreadCount != null && (p.unreadCount ?? 0) > 0)
                  Chip(avatar: const Icon(Icons.mark_chat_unread, size: 16), label: Text('${p.unreadCount} mensagens não lidas')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceSection(BuildContext context, Partnership p) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compliance & Jurisdição', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(avatar: const Icon(Icons.privacy_tip_outlined, size: 16), label: Text('NDA: ${p.ndaStatus ?? '-'}')),
                Chip(avatar: const Icon(Icons.gavel_outlined, size: 16), label: Text('Jurisdição: ${p.jurisdiction ?? '-'}')),
                if (p.externalCaseNumber != null)
                  Chip(avatar: const Icon(Icons.confirmation_number_outlined, size: 16), label: Text('Proc. Externo: ${p.externalCaseNumber}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


