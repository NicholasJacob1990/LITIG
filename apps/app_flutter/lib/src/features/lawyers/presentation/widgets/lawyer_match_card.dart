import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';

class LawyerMatchCard extends StatefulWidget {
  final MatchedLawyer lawyer;
  final VoidCallback? onSelect;
  final VoidCallback? onExplain;

  const LawyerMatchCard({
    super.key,
    required this.lawyer,
    this.onSelect,
    this.onExplain,
  });

  @override
  State<LawyerMatchCard> createState() => _LawyerMatchCardState();
}

class _LawyerMatchCardState extends State<LawyerMatchCard> {
  bool _isExpanded = false;

  Color _getMatchColor(double score) {
    if (score >= 0.8) return Colors.green.shade400;
    if (score >= 0.6) return Colors.amber.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchColor = _getMatchColor(widget.lawyer.fair);
    final isAutoridade = widget.lawyer.features.successRate > 0.8; // Exemplo de lógica

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- HEADER ---
            Row(
              children: [
                _buildAvatar(theme),
                const SizedBox(width: 16),
                _buildBasicInfo(theme),
                _buildScoreCircle(matchColor, theme),
              ],
            ),
            const SizedBox(height: 12),
            
            // --- EXPERIÊNCIA E PRÊMIOS ---
            _buildExperienceAndAwards(theme),
            
            // --- BADGE DE AUTORIDADE ---
            if (isAutoridade) _buildAuthorityBadge(theme),
            
            const SizedBox(height: 16),

            // --- MÉTRICAS ---
            _buildMetricsRow(),

            const SizedBox(height: 16),

            // --- ANÁLISE EXPANSÍVEL ---
            _buildExpansionPanel(theme),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // --- BOTÕES DE AÇÃO ---
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundImage: CachedNetworkImageProvider(widget.lawyer.avatarUrl),
          backgroundColor: theme.colorScheme.surface,
        ),
        if (widget.lawyer.isAvailable)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: theme.cardColor, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBasicInfo(ThemeData theme) {
     return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.lawyer.nome, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(LucideIcons.mapPin, size: 14, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              Text('${widget.lawyer.distanceKm.toStringAsFixed(1)} km', style: theme.textTheme.bodyMedium),
            ],
          ),
           const SizedBox(height: 2),
          Row(
            children: [
              Icon(LucideIcons.award, size: 14, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              Text(widget.lawyer.primaryArea, style: theme.textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCircle(Color matchColor, ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: matchColor.withOpacity(0.1),
            border: Border.all(color: matchColor, width: 2),
          ),
          child: Center(
            child: Text(
              '${(widget.lawyer.fair * 100).toInt()}',
              style: theme.textTheme.headlineSmall?.copyWith(color: matchColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('Compatibilidade', style: theme.textTheme.bodySmall)
      ],
    );
  }

  Widget _buildAuthorityBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.shieldCheck, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text('⚖️ Autoridade no Assunto', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildExperienceAndAwards(ThemeData theme) {
    if (widget.lawyer.experienceYears == null && widget.lawyer.awards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          children: [
            // Experiência
            if (widget.lawyer.experienceYears != null) ...[
              Icon(LucideIcons.briefcase, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '${widget.lawyer.experienceYears} anos de experiência',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
            ],
            
            // Botão Currículo
            if (widget.lawyer.professionalSummary != null && widget.lawyer.professionalSummary!.isNotEmpty) ...[
              TextButton.icon(
                onPressed: () => _showCurriculumModal(context),
                icon: const Icon(LucideIcons.fileText, size: 16),
                label: const Text('Ver Currículo'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
            ],
          ],
        ),
        
        // Prêmios/Selos
        if (widget.lawyer.awards.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.award, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: widget.lawyer.awards
                      .take(3) // Limitar a 3 prêmios
                      .map((award) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Text(
                              award,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  void _showCurriculumModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Currículo - ${widget.lawyer.nome}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.lawyer.experienceYears != null) ...[
                            Text(
                              'Experiência: ${widget.lawyer.experienceYears} anos',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          if (widget.lawyer.awards.isNotEmpty) ...[
                            Text(
                              'Prêmios e Reconhecimentos:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...widget.lawyer.awards.map((award) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• $award', style: Theme.of(context).textTheme.bodyMedium),
                            )).toList(),
                            const SizedBox(height: 16),
                          ],
                          
                          Text(
                            'Resumo Profissional:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.lawyer.professionalSummary ?? 'Não disponível',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetric(icon: LucideIcons.star, value: widget.lawyer.rating?.toStringAsFixed(1) ?? 'N/A', label: 'Avaliação'),
        _buildMetric(icon: LucideIcons.checkCircle, value: '${(widget.lawyer.features.successRate * 100).toInt()}%', label: 'Êxito'),
        _buildMetric(icon: LucideIcons.clock, value: '${widget.lawyer.features.responseTime}h', label: 'Resposta'),
        _buildMetric(icon: LucideIcons.brainCircuit, value: '${(widget.lawyer.features.softSkills * 100).toInt()}', label: 'Soft Skills'),
        _buildMetric(icon: LucideIcons.users, value: widget.lawyer.reviewCount.toString(), label: 'Casos'),
      ],
    );
  }

  Widget _buildMetric({required IconData icon, required String value, required String label}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.8)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildExpansionPanel(ThemeData theme) {
    return Column(
      children: [
        const Divider(height: 1),
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.sparkles, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  _isExpanded ? 'Ocultar Análise' : 'Analisar Compatibilidade',
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                ),
                Icon(
                  _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Análise de compatibilidade baseada em experiência, localização, taxa de sucesso e perfil do caso.', // Placeholder
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () { /* TODO: Implementar contratação */ },
            icon: const Icon(LucideIcons.fileSignature),
            label: const Text('Contratar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () { /* TODO: Implementar chat */ },
          icon: const Icon(LucideIcons.messageSquare),
          tooltip: 'Chat',
        ),
        IconButton(
          onPressed: () { /* TODO: Implementar vídeo */ },
          icon: const Icon(LucideIcons.video),
          tooltip: 'Vídeo Chamada',
        ),
      ],
    );
  }
} 