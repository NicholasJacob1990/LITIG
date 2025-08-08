import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../widgets/stat_card.dart';

/// Dashboard expandido para clientes com métricas pessoais completas
/// 
/// Inclui:
/// - Status dos casos em andamento
/// - Advogados contratados
/// - Próximas audiências
/// - Documentos pendentes
/// - Mensagens não lidas
class EnhancedClientDashboard extends StatelessWidget {
  final String userName;

  const EnhancedClientDashboard({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, $userName'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Métricas principais
            _buildClientMetrics(context),
            const SizedBox(height: 24),
            
            // Casos em andamento
            _buildActiveCasesSection(context),
            const SizedBox(height: 24),
            
            // Advogados contratados
            _buildContractedLawyersSection(context),
            const SizedBox(height: 24),
            
            // Próximas audiências
            _buildUpcomingHearingsSection(context),
            const SizedBox(height: 24),
            
            // Ações rápidas
            Text('Ações Rápidas', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildClientMetrics(BuildContext context) {
    // TODO: Implementar chamada real da API
    final metrics = {
      'activeCases': 3,
      'contractedLawyers': 2,
      'upcomingHearings': 1,
      'unreadMessages': 5
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seus Casos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Casos Ativos',
                value: '${metrics['activeCases']}',
                icon: LucideIcons.briefcase,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Advogados',
                value: '${metrics['contractedLawyers']}',
                icon: LucideIcons.userCheck,
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
                title: 'Audiências',
                value: '${metrics['upcomingHearings']}',
                icon: LucideIcons.calendar,
                color: Colors.orange.shade400,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Mensagens',
                value: '${metrics['unreadMessages']}',
                icon: LucideIcons.messageCircle,
                color: Colors.blue.shade400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveCasesSection(BuildContext context) {
    // TODO: Implementar chamada real da API
    final activeCases = [
      {
        'id': 'case-1',
        'title': 'Ação Trabalhista - Rescisão',
        'lawyer': 'Dr. João Silva',
        'status': 'Em andamento',
        'nextStep': 'Aguardando documentos',
        'priority': 'high'
      },
      {
        'id': 'case-2', 
        'title': 'Revisão Contratual',
        'lawyer': 'Dra. Maria Santos',
        'status': 'Análise inicial',
        'nextStep': 'Reunião agendada',
        'priority': 'medium'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Casos em Andamento', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => context.go('/client-cases'),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...activeCases.map((caseData) => _buildCaseCard(context, caseData)),
      ],
    );
  }

  Widget _buildCaseCard(BuildContext context, Map<String, dynamic> caseData) {
    Color priorityColor = caseData['priority'] == 'high' 
        ? Colors.red 
        : caseData['priority'] == 'medium' 
            ? Colors.orange 
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/case-detail/${caseData['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      caseData['title'],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      caseData['status'],
                      style: TextStyle(
                        color: priorityColor,
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
                  const Icon(LucideIcons.user, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    caseData['lawyer'],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(LucideIcons.clock, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    caseData['nextStep'],
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

  Widget _buildContractedLawyersSection(BuildContext context) {
    // TODO: Implementar chamada real da API
    final lawyers = [
      {
        'id': 'lawyer-1',
        'name': 'Dr. João Silva',
        'specialization': 'Direito Trabalhista',
        'rating': 4.8,
        'activeCases': 2,
        'responseTime': '2h'
      },
      {
        'id': 'lawyer-2',
        'name': 'Dra. Maria Santos',
        'specialization': 'Direito Civil',
        'rating': 4.9,
        'activeCases': 1,
        'responseTime': '1h'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Seus Advogados', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
      onPressed: () => context.go('/find-lawyers'),
              child: const Text('Buscar mais'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...lawyers.map((lawyer) => _buildLawyerCard(context, lawyer)),
      ],
    );
  }

  Widget _buildLawyerCard(BuildContext context, Map<String, dynamic> lawyer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/chat/lawyer/${lawyer['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Text(
                  lawyer['name'].toString().substring(0, 2).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lawyer['name'],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      lawyer['specialization'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(LucideIcons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${lawyer['rating']}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${lawyer['activeCases']} casos',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () => context.go('/chat/lawyer/${lawyer['id']}'),
                    icon: const Icon(LucideIcons.messageCircle),
                    tooltip: 'Enviar mensagem',
                  ),
                  Text(
                    'Resp: ${lawyer['responseTime']}',
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

  Widget _buildUpcomingHearingsSection(BuildContext context) {
    // TODO: Implementar chamada real da API
    final hearings = [
      {
        'id': 'hearing-1',
        'caseTitle': 'Ação Trabalhista - Rescisão',
        'date': '25/01/2025',
        'time': '14:30',
        'type': 'Audiência de Conciliação',
        'location': 'Tribunal do Trabalho - 2ª Vara',
        'lawyer': 'Dr. João Silva'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Próximas Audiências', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (hearings.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.calendar,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Nenhuma audiência agendada',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...hearings.map((hearing) => _buildHearingCard(context, hearing)),
      ],
    );
  }

  Widget _buildHearingCard(BuildContext context, Map<String, dynamic> hearing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${hearing['date']} às ${hearing['time']}',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hearing['type'],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hearing['caseTitle'],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hearing['location'],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.user, size: 16),
                const SizedBox(width: 4),
                Text(
                  hearing['lawyer'],
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
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
          'Nova Consulta',
          LucideIcons.bot,
          '/triage',
          Colors.blue,
        ),
        _buildActionCard(
          context,
          'Buscar Advogados',
          LucideIcons.search,
  '/find-lawyers',
          Colors.green,
        ),
        _buildActionCard(
          context,
          'Meus Casos',
          LucideIcons.briefcase,
          '/client-cases',
          Colors.orange,
        ),
        _buildActionCard(
          context,
          'Mensagens',
          LucideIcons.messageCircle,
          '/client-messages',
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
} 