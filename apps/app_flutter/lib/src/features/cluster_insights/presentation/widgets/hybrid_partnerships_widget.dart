import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/hybrid_recommendations_bloc.dart';
import '../../domain/entities/partnership_recommendation.dart';
import '../../../partnerships/domain/repositories/partnership_repository.dart';
import 'unclaimed_profile_card.dart';
import 'verified_profile_card.dart';
import 'invitation_modal.dart';

/// Widget principal para exibir recomendações híbridas de parcerias
class HybridPartnershipsWidget extends StatelessWidget {
  final String currentLawyerId;
  final bool showExpandOption;

  const HybridPartnershipsWidget({
    super.key,
    required this.currentLawyerId,
    this.showExpandOption = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HybridRecommendationsBloc(
        repository: GetIt.instance<PartnershipRepository>(),
      )..add(FetchHybridRecommendations(lawyerId: currentLawyerId)),
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com controles
              _buildHeader(context),
              const SizedBox(height: 16),
              
              // Lista de recomendações
              BlocBuilder<HybridRecommendationsBloc, HybridRecommendationsState>(
                builder: (context, state) {
                  return _buildContent(context, state);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocBuilder<HybridRecommendationsBloc, HybridRecommendationsState>(
      builder: (context, state) {
        return Column(
          children: [
            Row(
              children: [
                const Icon(Icons.handshake, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Parcerias Estratégicas',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // Toggle de busca expandida
                if (showExpandOption && state is HybridRecommendationsLoaded)
                  _buildExpandToggle(context, state),
                
                // Botão de atualização
                IconButton(
                  onPressed: () {
                    final currentState = state;
                    final expandSearch = currentState is HybridRecommendationsLoaded
                        ? currentState.expandSearchEnabled
                        : false;
                    
                    context.read<HybridRecommendationsBloc>().add(
                      RefreshHybridRecommendations(
                        lawyerId: currentLawyerId,
                        expandSearch: expandSearch,
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Atualizar recomendações',
                ),
              ],
            ),
            
            // Estatísticas híbridas
            if (state is HybridRecommendationsLoaded)
              _buildHybridStats(context, state),
          ],
        );
      },
    );
  }

  Widget _buildExpandToggle(BuildContext context, HybridRecommendationsLoaded state) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: state.expandSearchEnabled 
            ? Colors.purple.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: state.expandSearchEnabled 
              ? Colors.purple.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            state.expandSearchEnabled ? Icons.public : Icons.search,
            size: 16,
            color: state.expandSearchEnabled ? Colors.purple : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            state.expandSearchEnabled ? 'Busca Externa' : 'Interno',
            style: theme.textTheme.bodySmall?.copyWith(
              color: state.expandSearchEnabled ? Colors.purple : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch(
            value: state.expandSearchEnabled,
            onChanged: (_) {
              context.read<HybridRecommendationsBloc>().add(
                ToggleExpandSearch(lawyerId: currentLawyerId),
              );
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildHybridStats(BuildContext context, HybridRecommendationsLoaded state) {
    final theme = Theme.of(context);
    
    if (!state.expandSearchEnabled || state.externalCount == 0) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Text(
            '${state.internalCount} verificados + ${state.externalCount} públicos',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (state.llmEnabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'IA',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, HybridRecommendationsState state) {
    if (state is HybridRecommendationsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (state is HybridRecommendationsError) {
      return _buildErrorState(context, state);
    }
    
    if (state is InvitationSent) {
      // Mostrar feedback de convite enviado e voltar para as recomendações
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ver Convites',
              onPressed: () {
                // TODO: Navegar para tela de convites
              },
            ),
          ),
        );
        
        // Recarregar recomendações
        context.read<HybridRecommendationsBloc>().add(
          RefreshHybridRecommendations(
            lawyerId: currentLawyerId,
          ),
        );
      });
      
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (state is HybridRecommendationsLoaded) {
      return _buildRecommendationsList(context, state);
    }
    
    return _buildEmptyState(context);
  }

  Widget _buildErrorState(BuildContext context, HybridRecommendationsError state) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar recomendações',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<HybridRecommendationsBloc>().add(
                  FetchHybridRecommendations(lawyerId: currentLawyerId),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.handshake_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma recomendação encontrada',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente ativar a busca externa para encontrar mais advogados',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList(BuildContext context, HybridRecommendationsLoaded state) {
    if (state.recommendations.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return Column(
      children: [
        // Seção de membros verificados
        if (state.verifiedRecommendations.isNotEmpty) ...[
          _buildSectionHeader(context, 'Membros Verificados', Icons.verified),
          ...state.verifiedRecommendations.map((rec) => VerifiedProfileCard(
            recommendation: rec,
            onContact: () => _handleContactVerified(context, rec),
          )),
        ],
        
        // Seção de perfis externos
        if (state.externalRecommendations.isNotEmpty) ...[
          if (state.verifiedRecommendations.isNotEmpty)
            const SizedBox(height: 24),
          _buildSectionHeader(context, 'Perfis Públicos Sugeridos', Icons.public),
          ...state.externalRecommendations.map((rec) => UnclaimedProfileCard(
            recommendation: rec,
            onInvite: () => _handleInviteExternal(context, rec),
          )),
        ],
        
        // Seção de convites enviados
        if (state.invitedRecommendations.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Convites Enviados', Icons.mail_outline),
          ...state.invitedRecommendations.map((rec) => UnclaimedProfileCard(
            recommendation: rec,
            showInviteButton: false,
          )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleContactVerified(BuildContext context, PartnershipRecommendation rec) {
    // TODO: Implementar contato com membro verificado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contactando ${rec.lawyerName}...'),
      ),
    );
  }

  void _handleInviteExternal(BuildContext context, PartnershipRecommendation rec) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InvitationModal(
        recommendation: rec,
        onSendInvite: (message) {
          context.read<HybridRecommendationsBloc>().add(
            InviteExternalProfile(
              recommendationId: rec.recommendedLawyerId,
              recommendation: rec,
            ),
          );
        },
      ),
    );
  }
} 