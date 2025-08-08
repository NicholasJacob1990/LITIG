import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../widgets/stat_card.dart';
import 'package:meu_app/src/features/cluster_insights/presentation/widgets/expandable_clusters_widget.dart';

/// Dashboard para CONTRATANTES (advogados que contratam outros)
/// Para lawyer_individual, super_associate
class ContractorDashboard extends StatelessWidget {
  final String userName;
  final String userRole;

  const ContractorDashboard({
    super.key, 
    required this.userName,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bem-vindo, $userName'),
            Text(
              _getRoleDisplayName(userRole),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título do Dashboard
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.briefcase,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'CONTRACTOR DASHBOARD',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Painel de Captação de Clientes e Gestão de Oportunidades',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Métricas de captação
            _buildCaptationMetrics(context),
            const SizedBox(height: 24),
            
            _buildBusinessOpportunities(context),
            const SizedBox(height: 24),
            
            _buildClusterInsights(context),
            const SizedBox(height: 24),
            
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptationMetrics(BuildContext context) {
    final metrics = _getMetricsForRole(userRole);

    return _buildDashboardSection(
      context,
      title: 'Métricas de Captação',
      icon: LucideIcons.trendingUp,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Clientes Ativos',
                  value: '${metrics['activeClients']}',
                  icon: LucideIcons.users,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Oportunidades',
                  value: '${metrics['newLeads']}',
                  icon: LucideIcons.userPlus,
                  color: Colors.green.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Parcerias Ativas',
                  value: '${metrics['activePartnerships']}',
                  icon: LucideIcons.briefcase,
                  color: Colors.orange.shade400,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Conversão',
                  value: '${metrics['conversionRate']}%',
                  icon: LucideIcons.target,
                  color: Colors.purple.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessOpportunities(BuildContext context) {
    return _buildDashboardSection(
      context,
      title: 'Oportunidades de Negócio',
      icon: LucideIcons.dollarSign,
      child: Column(
        children: [
          _buildClientPipeline(context),
          const SizedBox(height: 16),
          _buildCaptationActions(context),
        ],
      ),
    );
  }

  Widget _buildClusterInsights(BuildContext context) {
    return _buildDashboardSection(
      context,
      title: 'Insights de Cluster',
      icon: LucideIcons.brainCircuit,
      child: const ExpandableClustersWidget(),
    );
  }

  Widget _buildDashboardSection(BuildContext context, {required String title, required IconData icon, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildClientPipeline(BuildContext context) {
    final pipelineData = _getPipelineForRole(userRole);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pipeline de Clientes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _buildPipelineStage(context, 'Prospects', pipelineData['prospects']!, Colors.blue),
          const SizedBox(height: 8),
          _buildPipelineStage(context, 'Qualificados', pipelineData['qualified']!, Colors.cyan),
          const SizedBox(height: 8),
          _buildPipelineStage(context, 'Proposta', pipelineData['proposal']!, Colors.orange),
          const SizedBox(height: 8),
          _buildPipelineStage(context, 'Negociação', pipelineData['negotiation']!, Colors.purple),
          const SizedBox(height: 8),
          _buildPipelineStage(context, 'Fechados', pipelineData['closed']!, Colors.green),
        ],
      ),
    );
  }

  Widget _buildPipelineStage(BuildContext context, String stage, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            stage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCaptationActions(BuildContext context) {
    return _buildActionCard(
      context,
      'Ações de Captação',
      LucideIcons.users,
      '/opportunities',
      Colors.blue,
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = userRole == 'super_associate' 
        ? _getSuperAssociateActions() 
        : _getIndividualLawyerActions();

    return _buildDashboardSection(
      context,
      title: 'Ações Rápidas',
      icon: LucideIcons.zap,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
        ),
        itemCount: actions.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _buildActionCard(
            context,
            action['title']!,
            action['icon'] as IconData,
            action['route']!,
            action['color'] as Color,
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getSuperAssociateActions() {
    return [
      {
        'title': 'Buscar Parceiros',
        'icon': LucideIcons.search,
        'route': '/partners',
        'color': Colors.blue,
      },
      {
        'title': 'Minhas Ofertas',
        'icon': LucideIcons.inbox,
        'route': '/contractor-offers',
        'color': Colors.green,
      },
      {
        'title': 'Financeiro',
        'icon': LucideIcons.wallet,
        'route': '/financial',
        'color': Colors.teal,
      },
      {
        'title': 'Relatórios',
        'icon': LucideIcons.barChart3,
        'route': '/reports',
        'color': Colors.orange,
      },
      {
        'title': 'Configurações',
        'icon': LucideIcons.settings,
        'route': '/profile/settings',
        'color': Colors.purple,
      },
    ];
  }

  List<Map<String, dynamic>> _getIndividualLawyerActions() {
    return [
      {
        'title': 'Buscar Parceiros',
        'icon': LucideIcons.search,
        'route': '/partners',
        'color': Colors.blue,
      },
      {
        'title': 'Parcerias',
        'icon': LucideIcons.users,
        'route': '/partnerships',
        'color': Colors.green,
      },
      {
        'title': 'Meus Casos',
        'icon': LucideIcons.briefcase,
        'route': '/contractor-cases',
        'color': Colors.orange,
      },
      {
        'title': 'Financeiro',
        'icon': LucideIcons.wallet,
        'route': '/financial',
        'color': Colors.teal,
      },
      {
        'title': 'Mensagens',
        'icon': LucideIcons.messageSquare,
        'route': '/contractor-messages',
        'color': Colors.purple,
      },
    ];
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    Color color,
  ) {
    return Card(
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getMetricsForRole(String role) {
    switch (role) {
      case 'super_associate':
        return {
          'activeClients': 15,
          'newLeads': 8,
          'monthlyRevenue': 45000.0,
          'conversionRate': 35,
          'activePartnerships': 5,
        };
      case 'lawyer_individual':
      default:
        return {
          'activeClients': 8,
          'newLeads': 5,
          'monthlyRevenue': 25000.0,
          'conversionRate': 28,
          'activePartnerships': 2,
        };
    }
  }

  Map<String, int> _getPipelineForRole(String role) {
    switch (role) {
      case 'super_associate':
        return {
          'prospects': 18,
          'qualified': 12,
          'proposal': 7,
          'negotiation': 4,
          'closed': 3,
        };
      case 'lawyer_individual':
      default:
        return {
          'prospects': 12,
          'qualified': 8,
          'proposal': 5,
          'negotiation': 3,
          'closed': 2,
        };
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'super_associate':
        return 'Super Associado';
      case 'lawyer_individual':
        return 'Advogado Autônomo';
      default:
        return 'Advogado';
    }
  }

  // Removed unused _formatCurrency
} 