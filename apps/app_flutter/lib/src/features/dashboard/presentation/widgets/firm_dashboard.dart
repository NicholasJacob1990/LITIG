import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../widgets/stat_card.dart';

/// Dashboard específico para sócios de escritórios
/// 
/// Exibe métricas da equipe, performance coletiva, 
/// faturamento consolidado e gestão dos advogados
class FirmDashboard extends StatelessWidget {
  final String userName;

  const FirmDashboard({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$userName - Sócio'),
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
            // Métricas do escritório
            _buildFirmMetrics(context),
            const SizedBox(height: 24),
            
            // Performance da equipe
            _buildTeamPerformance(context),
            const SizedBox(height: 24),
            
            // Advogados da equipe
            _buildTeamMembers(context),
            const SizedBox(height: 24),
            
            // Faturamento consolidado
            _buildRevenueDashboard(context),
            const SizedBox(height: 24),
            
            // Ações rápidas para sócios
            Text('Gestão do Escritório', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildManagementActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFirmMetrics(BuildContext context) {
    // TODO: Implementar chamada real da API
    final firmMetrics = {
      'teamSize': 8,
      'activeCases': 24,
      'monthlyRevenue': 145000.0,
      'clientSatisfaction': 4.7
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Visão Geral do Escritório', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Advogados',
                value: '${firmMetrics['teamSize']}',
                icon: LucideIcons.users,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Casos Ativos',
                value: '${firmMetrics['activeCases']}',
                icon: LucideIcons.briefcase,
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
                                 value: 'R\$ ${_formatCurrency(firmMetrics['monthlyRevenue']! as double)}',
                icon: LucideIcons.dollarSign,
                color: Colors.orange.shade400,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Satisfação',
                value: '${firmMetrics['clientSatisfaction']}⭐',
                icon: LucideIcons.star,
                color: Colors.amber.shade400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamPerformance(BuildContext context) {
    // TODO: Implementar chamada real da API
    final teamPerformance = {
      'averageProductivity': 0.85,
      'onTimeDelivery': 0.92,
      'clientRetention': 0.88,
      'averageRating': 4.6
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Performance da Equipe', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildPerformanceMetric(
                context,
                'Produtividade Média',
                '${(teamPerformance['averageProductivity']! * 100).toInt()}%',
                LucideIcons.trendingUp,
                _getPerformanceColor(teamPerformance['averageProductivity']!),
              ),
              const SizedBox(height: 12),
              _buildPerformanceMetric(
                context,
                'Entregas no Prazo',
                '${(teamPerformance['onTimeDelivery']! * 100).toInt()}%',
                LucideIcons.clock,
                _getPerformanceColor(teamPerformance['onTimeDelivery']!),
              ),
              const SizedBox(height: 12),
              _buildPerformanceMetric(
                context,
                'Retenção de Clientes',
                '${(teamPerformance['clientRetention']! * 100).toInt()}%',
                LucideIcons.userCheck,
                _getPerformanceColor(teamPerformance['clientRetention']!),
              ),
              const SizedBox(height: 12),
              _buildPerformanceMetric(
                context,
                'Avaliação Média',
                '${teamPerformance['averageRating']}⭐',
                LucideIcons.star,
                Colors.amber,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamMembers(BuildContext context) {
    // TODO: Implementar chamada real da API  
    final teamMembers = [
      {
        'id': 'lawyer-1',
        'name': 'Dr. Carlos Silva',
        'level': 'Sênior',
        'specialization': 'Direito Trabalhista',
        'activeCases': 8,
        'productivity': 0.92,
        'rating': 4.8,
        'status': 'available'
      },
      {
        'id': 'lawyer-2',
        'name': 'Dra. Ana Santos',
        'level': 'Pleno',
        'specialization': 'Direito Civil',
        'activeCases': 6,
        'productivity': 0.87,
        'rating': 4.6,
        'status': 'busy'
      },
      {
        'id': 'lawyer-3',
        'name': 'Dr. Paulo Costa',
        'level': 'Júnior',
        'specialization': 'Direito Tributário',
        'activeCases': 4,
        'productivity': 0.78,
        'rating': 4.3,
        'status': 'available'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Equipe do Escritório', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => context.go('/firm/team-management'),
              child: const Text('Gerenciar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...teamMembers.map((member) => _buildTeamMemberCard(context, member)),
      ],
    );
  }

  Widget _buildTeamMemberCard(BuildContext context, Map<String, dynamic> member) {
    Color statusColor = member['status'] == 'available' ? Colors.green : Colors.orange;
    String statusText = member['status'] == 'available' ? 'Disponível' : 'Ocupado';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/lawyer-performance/${member['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    child: Text(
                      member['name'].toString().substring(0, 2).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              member['name'],
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${member['level']} • ${member['specialization']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMemberMetric('Casos', '${member['activeCases']}'),
                  const SizedBox(width: 24),
                  _buildMemberMetric(
                    'Produtividade', 
                    '${(member['productivity'] * 100).toInt()}%'
                  ),
                  const SizedBox(width: 24),
                  _buildMemberMetric('Avaliação', '${member['rating']}⭐'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueDashboard(BuildContext context) {
    // TODO: Implementar chamada real da API
    final revenueData = {
      'thisMonth': 145000.0,
      'lastMonth': 132000.0,
      'growth': 0.098,
      'billableHours': 384,
      'averageHourlyRate': 377.6
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Faturamento', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.green.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Este Mês',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                                                 'R\$ ${_formatCurrency(revenueData['thisMonth']! as double)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${(revenueData['growth']! * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildRevenueMetric(
                      context,
                      'Horas Faturáveis',
                      '${revenueData['billableHours']}h',
                      LucideIcons.clock,
                    ),
                  ),
                  Expanded(
                    child: _buildRevenueMetric(
                      context,
                      'Valor/Hora Médio',
                      'R\$ ${revenueData['averageHourlyRate']!.toStringAsFixed(0)}',
                      LucideIcons.dollarSign,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.green.shade700),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.green.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildManagementActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          context,
          'Gerenciar Equipe',
          LucideIcons.users,
          '/firm/team-management',
          Colors.blue,
        ),
        _buildActionCard(
          context,
          'Relatórios',
          LucideIcons.barChart3,
          '/firm/reports',
          Colors.green,
        ),
        _buildActionCard(
          context,
          'Configurações SLA',
          LucideIcons.clock,
          '/sla-settings',
          Colors.orange,
        ),
        _buildActionCard(
          context,
          'Clientes',
          LucideIcons.briefcase,
          '/firm/clients',
          Colors.purple,
        ),
      ],
    );
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

  Color _getPerformanceColor(double value) {
    if (value >= 0.85) return Colors.green;
    if (value >= 0.70) return Colors.orange;
    return Colors.red;
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