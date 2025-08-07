import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/lawyer_hiring_modal.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/lawyer_social_links.dart';
import 'package:meu_app/src/shared/widgets/atoms/initials_avatar.dart';
import 'package:meu_app/src/shared/widgets/badges/universal_badge.dart';
import 'package:meu_app/src/shared/utils/badge_visibility_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/shared/widgets/instrumented_widgets.dart';

class LawyerMatchCard extends StatefulWidget {
  final MatchedLawyer lawyer;
  final VoidCallback? onSelect;
  final VoidCallback? onExplain;
  final String? caseId;
  final String? clientId;
  // Novos parâmetros para instrumentação
  final String? sourceContext;
  final String? searchQuery;
  final double? searchRank;
  final Map<String, dynamic>? searchFilters;

  const LawyerMatchCard({
    super.key,
    required this.lawyer,
    this.onSelect,
    this.onExplain,
    this.caseId,
    this.clientId,
    this.sourceContext,
    this.searchQuery,
    this.searchRank,
    this.searchFilters,
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

    return InstrumentedProfileCard(
      profileId: widget.lawyer.id,
      profileType: 'lawyer',
      sourceContext: widget.sourceContext ?? 'match_list',
      searchQuery: widget.searchQuery,
      searchRank: widget.searchRank,
      searchFilters: widget.searchFilters,
      caseContext: widget.caseId,
      onTap: () => _navigateToLawyerProfile(context),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
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

              const SizedBox(height: 12),

              // --- DADOS SOCIAIS ---
              _buildSocialSection(),

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
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return Stack(
      children: [
        InitialsAvatar(
          text: widget.lawyer.nome,
          radius: 32,
          avatarUrl: widget.lawyer.avatarUrl.isNotEmpty ? widget.lawyer.avatarUrl : null,
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
          Row(
            children: [
              Expanded(
                child: Text(widget.lawyer.nome, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              // NOVO: Badge PRO universal para recomendações
              BlocBuilder<AuthBloc, auth_states.AuthState>(
                builder: (context, authState) {
                  if (authState is auth_states.Authenticated) {
                    final badgeContext = BadgeVisibilityHelper.getProLawyerContext(
                      authState.user.role,
                      widget.lawyer.plan,
                      false, // Recomendações não têm contexto de caso premium específico
                    );
                    
                    return UniversalBadge(
                      context: badgeContext,
                      fontSize: 10,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
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
            color: matchColor.withValues(alpha: 0.1),
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
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
              const Icon(LucideIcons.award, size: 16, color: Colors.amber),
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
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
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
                            )),
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
    // Otimização: usar cor constante ao invés de theme.colorScheme.onSurface.withValues(alpha: 0.8)
    const iconColor = Colors.grey; // Cor constante para evitar recálculo desnecessário
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor),
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
    return Column(
      children: [
        // Primeira linha: Ver Perfil (destaque) - Instrumentado
        SizedBox(
          width: double.infinity,
          child: InstrumentedButton(
            elementId: 'view_lawyer_profile_${widget.lawyer.id}',
            context: 'lawyer_match_card',
            onPressed: () => _navigateToLawyerProfile(context),
            additionalData: {
              'lawyer_id': widget.lawyer.id,
              'match_score': widget.lawyer.fair,
              'source_context': widget.sourceContext,
              'search_rank': widget.searchRank,
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.user, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Ver Perfil Completo', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Segunda linha: Ações rápidas - Instrumentadas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: InstrumentedInviteButton(
                invitationType: 'lawyer_hire',
                recipientId: widget.lawyer.id,
                context: 'lawyer_match_card',
                caseId: widget.caseId,
                matchScore: widget.lawyer.fair,
                recipientType: 'lawyer',
                onPressed: _handleHireLawyer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.fileSignature, color: Theme.of(context).colorScheme.onPrimary),
                    const SizedBox(width: 8),
                    Text('Contratar', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InstrumentedButton(
              elementId: 'match_explanation_${widget.lawyer.id}',
              context: 'lawyer_match_card',
              onPressed: () => _showMatchExplanation(context),
              additionalData: {
                'lawyer_id': widget.lawyer.id,
                'match_score': widget.lawyer.fair,
                'action_type': 'explanation_request',
              },
              child: Icon(
                LucideIcons.helpCircle,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            InstrumentedButton(
              elementId: 'start_chat_${widget.lawyer.id}',
              context: 'lawyer_match_card',
              onPressed: () => _handleStartChat(context),
              additionalData: {
                'lawyer_id': widget.lawyer.id,
                'action_type': 'start_chat',
                'case_id': widget.caseId,
              },
              child: const Icon(LucideIcons.messageSquare),
            ),
            InstrumentedButton(
              elementId: 'video_call_${widget.lawyer.id}',
              context: 'lawyer_match_card',
              onPressed: () => _handleVideoCall(context),
              additionalData: {
                'lawyer_id': widget.lawyer.id,
                'action_type': 'video_call',
                'case_id': widget.caseId,
              },
              child: const Icon(LucideIcons.video),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToLawyerProfile(BuildContext context) {
    context.push('/lawyer/${widget.lawyer.id}/profile');
  }

  void _handleStartChat(BuildContext context) {
    // TODO: Implementar navegação para chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de chat em desenvolvimento'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showMatchExplanation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _buildMatchExplanationDialog(context),
    );
  }

  Widget _buildMatchExplanationDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHeader(context),
            const SizedBox(height: 20),
            _buildCompatibilityScore(),
            const SizedBox(height: 20),
            _buildExplanationFactors(),
            const SizedBox(height: 24),
            _buildDialogActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: widget.lawyer.avatarUrl.isNotEmpty ? NetworkImage(widget.lawyer.avatarUrl) : null,
          child: widget.lawyer.avatarUrl.isEmpty ? const Icon(LucideIcons.user) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Por que ${widget.lawyer.nome} foi recomendado?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Análise detalhada da compatibilidade',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.x),
        ),
      ],
    );
  }

  Widget _buildCompatibilityScore() {
    final percentage = (widget.lawyer.fair * 100).toInt();
    final scoreColor = _getScoreColor(widget.lawyer.fair);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: 0.1),
            scoreColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: scoreColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compatibilidade',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  _getCompatibilityText(widget.lawyer.fair),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationFactors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fatores de Compatibilidade',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _buildFactor(
          'Taxa de Sucesso',
          widget.lawyer.features.successRate,
          LucideIcons.trendingUp,
          'Histórico de vitórias em casos similares',
        ),
        _buildFactor(
          'Tempo de Resposta',
          _normalizeResponseTime(widget.lawyer.features.responseTime),
          LucideIcons.clock,
          'Velocidade para responder demandas',
        ),
        _buildFactor(
          'Soft Skills',
          widget.lawyer.features.softSkills,
          LucideIcons.users,
          'Habilidades de comunicação e relacionamento',
        ),
      ],
    );
  }

  Widget _buildFactor(String title, double score, IconData icon, String description) {
    final scoreColor = _getScoreColor(score);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: scoreColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('${(score * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToLawyerProfile(context);
            },
            icon: const Icon(LucideIcons.user),
            label: const Text('Ver Perfil Completo'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _handleHireLawyer();
            },
            icon: const Icon(LucideIcons.fileSignature),
            label: const Text('Contratar'),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getCompatibilityText(double score) {
    if (score >= 0.8) return 'Altamente compatível com seu caso';
    if (score >= 0.6) return 'Boa compatibilidade com seu caso';
    return 'Compatibilidade moderada';
  }

  double _normalizeResponseTime(int responseTimeHours) {
    // Normaliza o tempo de resposta para uma escala de 0-1
    // Menor tempo = melhor score
    if (responseTimeHours <= 2) return 1.0;
    if (responseTimeHours <= 6) return 0.8;
    if (responseTimeHours <= 12) return 0.6;
    if (responseTimeHours <= 24) return 0.4;
    return 0.2;
  }

  void _handleHireLawyer() {
    // Verifica se caseId e clientId foram fornecidos
    if (widget.caseId == null || widget.clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Dados do caso não disponíveis. Por favor, selecione um caso primeiro.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Abre o LawyerHiringModal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LawyerHiringModal(
        lawyer: widget.lawyer,
        caseId: widget.caseId!,
        clientId: widget.clientId!,
      ),
    );
  }

  Widget _buildSocialSection() {
    // TODO: Implementar campos de redes sociais no modelo MatchedLawyer
    return const LawyerSocialLinks(
      linkedinUrl: 'https://linkedin.com/in/advogado',
      instagramUrl: 'https://instagram.com/advogado',
      facebookUrl: 'https://facebook.com/advogado',
    );
  }


  void _handleVideoCall(BuildContext context) {
    // Verificar se caseId e clientId foram fornecidos
    if (widget.caseId == null || widget.clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Dados do caso não disponíveis para videochamada.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Gerar nome único para a sala
    final roomName = 'call_${widget.caseId}_${widget.lawyer.id}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Navegar para a tela de videochamada
    context.push('/video-call/$roomName', extra: {
      'roomUrl': 'https://litig.daily.co/$roomName',
      'userId': widget.clientId,
      'otherPartyName': widget.lawyer.nome,
    });
  }

} 