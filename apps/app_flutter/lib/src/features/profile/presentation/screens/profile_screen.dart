import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:meu_app/src/features/dashboard/presentation/bloc/lawyer_firm_bloc.dart';
import '../../../../../injection_container.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<LawyerFirmBloc>()..add(const LoadLawyerFirmInfo()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Perfil'),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.settings),
              onPressed: () {
                context.go('/profile/settings');
              },
            ),
          ],
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) {
              final user = state.user;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Área do perfil centralizada
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            child: user.fullName != null && user.fullName!.isNotEmpty
                                ? Text(user.fullName!.substring(0, 2).toUpperCase(), style: const TextStyle(fontSize: 40))
                                : const Icon(LucideIcons.user, size: 40),
                          ),
                          const SizedBox(height: 20),
                          Text(user.fullName ?? 'Usuário', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text(user.email ?? 'E-mail não informado', style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: 8),
                          if (user.role != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _getRoleDisplayName(user.role!),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Dashboard Contextual Completo (baseado no tipo de usuário)
                    _buildContextualDashboard(context, user),
                    const SizedBox(height: 24),
                    
                    // Seção de Escritório (apenas para advogados)
                    if (user.role == 'lawyer' || user.role == 'associate_lawyer')
                      const _LawyerFirmSection(),
                    
                    const SizedBox(height: 32),
                    
                    // Botão de editar perfil
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.go('/profile/edit');
                        },
                        icon: const Icon(LucideIcons.edit),
                        label: const Text('Editar Perfil'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildContextualDashboard(BuildContext context, dynamic user) {
    return Column(
      children: [
        // Métricas resumidas
        _buildPersonalMetricsSection(context, user),
        const SizedBox(height: 16),
        
        // Dashboard contextual expandido baseado no tipo de usuário
        _buildExpandedDashboardByUserType(context, user.role),
      ],
    );
  }

  Widget _buildPersonalMetricsSection(BuildContext context, dynamic user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.barChart3, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Suas Métricas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricsForUserType(context, user.role),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedDashboardByUserType(BuildContext context, String? role) {
    // Dashboard contextual completo baseado no tipo de usuário
    switch (role) {
      case 'lawyer_individual':
        return _buildIndividualLawyerDashboard(context);
      case 'lawyer_platform_associate':
        return _buildSuperAssociateDashboard(context);
      case 'lawyer_office':
        return _buildFirmOwnerDashboard(context);
      case 'lawyer_associated':
        return _buildAssociatedLawyerDashboard(context);
      case 'client':
      case 'PF':
        return _buildClientDashboard(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIndividualLawyerDashboard(BuildContext context) {
    // Dashboard para advogados autônomos - foco em captação
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.briefcase, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Seu Negócio Jurídico',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Oportunidades em andamento
            _buildSectionItem(
              context,
              'Oportunidades Ativas',
              '5 em negociação',
              LucideIcons.target,
              Colors.orange,
            ),
            _buildSectionItem(
              context,
              'Parcerias',
              '3 advogados parceiros',
              LucideIcons.users,
              Colors.blue,
            ),
            _buildSectionItem(
              context,
              'Pipeline Mensal',
              'R\$ 45.000 em propostas',
              LucideIcons.dollarSign,
              Colors.green,
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/contractor-home'),
                icon: const Icon(LucideIcons.externalLink),
                label: const Text('Ver Dashboard Completo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuperAssociateDashboard(BuildContext context) {
    // Dashboard para super associados - foco em captação e parcerias
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.crown, size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Super Associado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSectionItem(
              context,
              'Captação Mensal',
              '12 novos leads qualificados',
              LucideIcons.userPlus,
              Colors.green,
            ),
            _buildSectionItem(
              context,
              'Parcerias Ativas',
              '8 escritórios parceiros',
              LucideIcons.building,
              Colors.blue,
            ),
            _buildSectionItem(
              context,
              'Comissões',
              'R\$ 28.500 este mês',
              LucideIcons.piggyBank,
              Colors.purple,
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/contractor-home'),
                icon: const Icon(LucideIcons.externalLink),
                label: const Text('Dashboard de Captação'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirmOwnerDashboard(BuildContext context) {
    // Dashboard para sócios de escritório - foco na gestão da equipe
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.building2, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Gestão do Escritório',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSectionItem(
              context,
              'Equipe',
              '8 advogados • 92% produtividade',
              LucideIcons.users,
              Colors.blue,
            ),
            _buildSectionItem(
              context,
              'Faturamento',
              'R\$ 145.000 este mês (+9.8%)',
              LucideIcons.trendingUp,
              Colors.green,
            ),
            _buildSectionItem(
              context,
              'Casos Ativos',
              '24 casos em andamento',
              LucideIcons.briefcase,
              Colors.orange,
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/firm-dashboard'),
                icon: const Icon(LucideIcons.externalLink),
                label: const Text('Dashboard da Firma'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssociatedLawyerDashboard(BuildContext context) {
    // Dashboard para advogados associados - foco na produtividade
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.userCheck, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Sua Produtividade',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSectionItem(
              context,
              'Casos Delegados',
              '5 casos ativos • 3 pendentes',
              LucideIcons.briefcase,
              Colors.blue,
            ),
            _buildSectionItem(
              context,
              'Eficiência',
              '92% taxa de entrega no prazo',
              LucideIcons.clock,
              Colors.green,
            ),
            _buildSectionItem(
              context,
              'Horas Trabalhadas',
              '156h este mês • Meta: 160h',
              LucideIcons.timer,
              Colors.orange,
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/dashboard'),
                icon: const Icon(LucideIcons.externalLink),
                label: const Text('Dashboard Completo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientDashboard(BuildContext context) {
    // Dashboard para clientes - foco nos casos e advogados
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.user, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Seus Casos Jurídicos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSectionItem(
              context,
              'Casos em Andamento',
              '3 casos ativos • 1 audiência próxima',
              LucideIcons.briefcase,
              Colors.blue,
            ),
            _buildSectionItem(
              context,
              'Advogados Contratados',
              '2 advogados • ⭐ 4.7 média',
              LucideIcons.userCheck,
              Colors.green,
            ),
            _buildSectionItem(
              context,
              'Mensagens',
              '5 mensagens não lidas',
              LucideIcons.messageCircle,
              Colors.orange,
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/client-home'),
                icon: const Icon(LucideIcons.externalLink),
                label: const Text('Dashboard Completo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsForUserType(BuildContext context, String? role) {
    // TODO: Implementar chamadas reais da API baseadas no tipo de usuário
    switch (role) {
      case 'lawyer':
      case 'lawyer_individual':
      case 'lawyer_office':
      case 'lawyer_platform_associate':
        return _buildLawyerMetrics(context);
      case 'lawyer_associated':
        return _buildAssociatedLawyerMetrics(context);
      case 'client':
      case 'PF':
        return _buildClientMetrics(context);
      default:
        return _buildDefaultMetrics(context);
    }
  }

  Widget _buildLawyerMetrics(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricItem(context, 'Casos Ativos', '8', LucideIcons.briefcase)),
            Expanded(child: _buildMetricItem(context, 'Taxa Sucesso', '87%', LucideIcons.trendingUp)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricItem(context, 'Avaliação', '4.7⭐', LucideIcons.star)),
            Expanded(child: _buildMetricItem(context, 'Este Mês', 'R\$ 25K', LucideIcons.dollarSign)),
          ],
        ),
      ],
    );
  }

  Widget _buildAssociatedLawyerMetrics(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricItem(context, 'Casos Ativos', '5', LucideIcons.briefcase)),
            Expanded(child: _buildMetricItem(context, 'Produtividade', '92%', LucideIcons.trendingUp)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricItem(context, 'Horas Mês', '156h', LucideIcons.clock)),
            Expanded(child: _buildMetricItem(context, 'Avaliação', '4.5⭐', LucideIcons.star)),
          ],
        ),
      ],
    );
  }

  Widget _buildClientMetrics(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricItem(context, 'Casos Ativos', '3', LucideIcons.briefcase)),
            Expanded(child: _buildMetricItem(context, 'Advogados', '2', LucideIcons.userCheck)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricItem(context, 'Audiências', '1', LucideIcons.calendar)),
            Expanded(child: _buildMetricItem(context, 'Mensagens', '5', LucideIcons.messageCircle)),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultMetrics(BuildContext context) {
    return Text(
      'Métricas não disponíveis para este tipo de usuário',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'lawyer':
        return 'Advogado de Captação';
      case 'associate_lawyer':
        return 'Advogado Associado';
      case 'client':
        return 'Cliente';
      default:
        return role;
    }
  }
}

class _LawyerFirmSection extends StatelessWidget {
  const _LawyerFirmSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LawyerFirmBloc, LawyerFirmState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.building2, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Escritório',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (state is LawyerFirmLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state is LawyerFirmLoaded)
                  _buildFirmInfo(context, state)
                else if (state is LawyerFirmNotAssociated)
                  _buildNotLinkedInfo(context)
                else if (state is LawyerFirmError)
                  _buildErrorInfo(context, state.message)
                else
                  _buildInitialInfo(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFirmInfo(BuildContext context, LawyerFirmLoaded state) {
    final firm = state.firm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          firm.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            const Icon(LucideIcons.userCheck, size: 16),
            const SizedBox(width: 4),
            Text(
              'Função: Advogado Associado',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        Row(
          children: [
            const Icon(LucideIcons.users, size: 16),
            const SizedBox(width: 4),
            Text(
              'Equipe: ${firm.teamSize} advogados',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        
        if (firm.kpis != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.trendingUp, size: 16),
              const SizedBox(width: 4),
              Text(
                'Taxa de Sucesso: ${(firm.kpis!.successRate * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
        
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.push('/firm/${firm.id}');
            },
            icon: const Icon(LucideIcons.eye),
            label: const Text('Ver Detalhes do Escritório'),
          ),
        ),
      ],
    );
  }

  Widget _buildNotLinkedInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advogado Independente',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Você não está vinculado a nenhum escritório.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navegar para busca de parcerias
                  // context.go('/partnerships');
                },
                icon: const Icon(LucideIcons.users),
                label: const Text('Buscar Parcerias'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navegar para criação de escritório
                  // context.go('/firm/create');
                },
                icon: const Icon(LucideIcons.plus),
                label: const Text('Criar Escritório'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorInfo(BuildContext context, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.alertCircle,
              color: Theme.of(context).colorScheme.error,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Erro ao carregar informações',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<LawyerFirmBloc>().add(const RefreshLawyerFirmInfo());
            },
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Tentar Novamente'),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Carregando informações...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<LawyerFirmBloc>().add(const LoadLawyerFirmInfo());
            },
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Carregar Informações'),
          ),
        ),
      ],
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'partner':
        return 'Sócio';
      case 'associate':
        return 'Associado';
      case 'junior':
        return 'Júnior';
      case 'senior':
        return 'Sênior';
      default:
        return role;
    }
  }
} 