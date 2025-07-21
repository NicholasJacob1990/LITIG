import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../widgets/stat_card.dart';

/// Dashboard específico para advogados contratantes
/// 
/// Para lawyer_individual, lawyer_platform_associate
/// Foco em captação de clientes, gestão de parcerias e negócios
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
            // Métricas de captação
            _buildCaptationMetrics(context),
            const SizedBox(height: 24),
            
            // Oportunidades de negócio
            _buildBusinessOpportunities(context),
            const SizedBox(height: 24),
            
            // Parcerias ativas
            _buildActivePartnerships(context),
            const SizedBox(height: 24),
            
            // Pipeline de clientes
            _buildClientPipeline(context),
            const SizedBox(height: 24),
            
            // Ações rápidas de captação
            Text('Captação & Negócios', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildCaptationActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptationMetrics(BuildContext context) {
    // TODO: Implementar chamada real da API baseada no tipo de advogado
    final metrics = _getMetricsForRole(userRole);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Suas Métricas de Captação', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
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
                title: 'Novos Leads',
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
                title: 'Faturamento',
                value: 'R\$ ${_formatCurrency(metrics['monthlyRevenue']!)}',
                icon: LucideIcons.dollarSign,
                color: Colors.orange.shade400,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Taxa Conversão',
                value: '${metrics['conversionRate']}%',
                icon: LucideIcons.trendingUp,
                color: Colors.purple.shade400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBusinessOpportunities(BuildContext context) {
    // TODO: Implementar chamada real da API
    final opportunities = [
      {
        'id': 'opp-1',
        'client': 'Empresa ABC Ltda',
        'type': 'Direito Empresarial',
        'value': 45000.0,
        'probability': 85,
        'stage': 'Proposta Enviada',
        'daysInStage': 3
      },
      {
        'id': 'opp-2',
        'client': 'João da Silva',
        'type': 'Direito Civil',
        'value': 12000.0,
        'probability': 60,
        'stage': 'Negociação',
        'daysInStage': 7
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Oportunidades de Negócio', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => context.go('/opportunities'),
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...opportunities.map((opp) => _buildOpportunityCard(context, opp)),
      ],
    );
  }

  Widget _buildOpportunityCard(BuildContext context, Map<String, dynamic> opportunity) {
    Color probabilityColor = opportunity['probability'] >= 80 
        ? Colors.green 
        : opportunity['probability'] >= 60 
            ? Colors.orange 
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/opportunity/${opportunity['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      opportunity['client'],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: probabilityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: probabilityColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${opportunity['probability']}%',
                      style: TextStyle(
                        color: probabilityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.briefcase, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    opportunity['type'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(LucideIcons.dollarSign, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'R\$ ${_formatCurrency(opportunity['value'])}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.clock, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${opportunity['stage']} • ${opportunity['daysInStage']} dias',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePartnerships(BuildContext context) {
    // TODO: Implementar chamada real da API
    final partnerships = [
      {
        'id': 'partner-1',
        'name': 'Dr. Carlos Silva',
        'specialization': 'Direito Trabalhista',
        'activeCases': 3,
        'monthlyRevenue': 15000.0,
        'rating': 4.8,
        'status': 'active'
      },
      {
        'id': 'partner-2',
        'name': 'Silva & Associados',
        'specialization': 'Direito Tributário',
        'activeCases': 2,
        'monthlyRevenue': 22000.0,
        'rating': 4.9,
        'status': 'active'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Parcerias Ativas', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => context.go('/partnerships'),
              child: const Text('Gerenciar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...partnerships.map((partner) => _buildPartnershipCard(context, partner)),
      ],
    );
  }

  Widget _buildPartnershipCard(BuildContext context, Map<String, dynamic> partner) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/partnership/${partner['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Text(
                  partner['name'].toString().substring(0, 2).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner['name'],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      partner['specialization'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(LucideIcons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${partner['rating']}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${partner['activeCases']} casos',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${_formatCurrency(partner['monthlyRevenue'])}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'este mês',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientPipeline(BuildContext context) {
    // TODO: Implementar chamada real da API
    final pipelineData = {
      'prospects': 12,
      'qualified': 8,
      'proposal': 5,
      'negotiation': 3,
      'closed': 2
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pipeline de Clientes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
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
        ),
      ],
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
    final actions = userRole == 'lawyer_platform_associate' 
        ? _getSuperAssociateActions() 
        : _getIndividualLawyerActions();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: actions.map((action) => _buildActionCard(
        context,
        action['title']!,
        action['icon'] as IconData,
        action['route']!,
        action['color'] as Color,
      )).toList(),
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
      case 'lawyer_platform_associate':
        return {
          'activeClients': 15,
          'newLeads': 8,
          'monthlyRevenue': 45000.0,
          'conversionRate': 35,
        };
      case 'lawyer_individual':
      default:
        return {
          'activeClients': 8,
          'newLeads': 5,
          'monthlyRevenue': 25000.0,
          'conversionRate': 28,
        };
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'lawyer_platform_associate':
        return 'Super Associado';
      case 'lawyer_individual':
        return 'Advogado Autônomo';
      default:
        return 'Advogado';
    }
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
} 