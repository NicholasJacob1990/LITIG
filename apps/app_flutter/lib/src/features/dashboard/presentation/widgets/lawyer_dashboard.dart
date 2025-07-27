import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:meu_app/src/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:meu_app/src/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:meu_app/src/features/dashboard/domain/usecases/get_lawyer_stats_usecase.dart';
import 'package:meu_app/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:meu_app/src/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:meu_app/src/features/dashboard/presentation/widgets/lawyer_firm_info_card.dart';
import 'package:meu_app/src/features/dashboard/presentation/bloc/lawyer_firm_bloc.dart';
import 'package:meu_app/src/features/cluster_insights/presentation/widgets/hybrid_partnerships_widget.dart';
import 'package:meu_app/injection_container.dart';

class LawyerDashboard extends StatelessWidget {
  final String userName;

  const LawyerDashboard({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            // TODO: Mover para GetIt
            final dataSource = DashboardRemoteDataSourceImpl();
            final repository = DashboardRepositoryImpl(remoteDataSource: dataSource);
            final useCase = GetLawyerStatsUseCase(repository);
            return DashboardBloc(getLawyerStatsUseCase: useCase)..add(FetchLawyerStats());
          },
        ),
        BlocProvider(
          create: (context) => LawyerFirmBloc(
            firmsRepository: getIt(),
          )..add(const LoadLawyerFirmInfo()),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text('Bem-vindo, $userName'),
          actions: [
            IconButton(
              icon: const Icon(lucide.LucideIcons.logOut),
              onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsSection(),
              const SizedBox(height: 24),
              _buildFirmInfoSection(context),
              const SizedBox(height: 24),
              // Widget de Parcerias Híbridas
              const HybridPartnershipsWidget(
                currentLawyerId: 'demo_lawyer_001', // TODO: Obter do contexto de autenticação
                showExpandOption: true,
              ),
              const SizedBox(height: 24),
              Text('Ações Rápidas', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildActionsGrid(context),
              const SizedBox(height: 24),
              Text('Acesso Rápido', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildQuickAccessList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DashboardError) {
          return Center(child: Text(state.message));
        }
        if (state is DashboardLoaded) {
          final stats = state.stats;
          final theme = Theme.of(context);
          return Row(
            children: [
              Expanded(child: StatCard(title: 'Casos Ativos', value: '${stats.activeCases}', icon: lucide.LucideIcons.briefcase, color: theme.colorScheme.primary)),
              const SizedBox(width: 16),
              Expanded(child: StatCard(title: 'Novos Leads', value: '${stats.newLeads}', icon: lucide.LucideIcons.userPlus, color: Colors.green.shade400)),
              const SizedBox(width: 16),
              Expanded(child: StatCard(title: 'Alertas', value: '${stats.alerts}', icon: lucide.LucideIcons.bell, color: Colors.amber.shade400)),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFirmInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              lucide.LucideIcons.building,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Meu Escritório',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 16),
        BlocBuilder<LawyerFirmBloc, LawyerFirmState>(
          builder: (context, state) {
            if (state is LawyerFirmLoading) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            
            if (state is LawyerFirmError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        lucide.LucideIcons.alertTriangle,
                        size: 32,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Erro ao carregar informações do escritório',
                        style: TextStyle(color: Colors.red[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                         onPressed: () => _retryLoadFirmInfo(context),
                         child: const Text('Tentar Novamente'),
                       ),
                    ],
                  ),
                ),
              );
            }
            
            if (state is LawyerFirmLoaded) {
              return LawyerFirmInfoCard(
                firm: state.firm,
                hasActiveCases: state.hasActiveCases,
                totalCases: state.totalCases,
              );
            }
            
            // Estado não vinculado a escritório
            return _buildIndependentLawyerCard(context);
          },
        ),
      ],
    );
  }

  Widget _buildActionsGrid(BuildContext context) {
    final actions = [
      {'title': 'Meus Casos', 'icon': lucide.LucideIcons.briefcase, 'route': '/cases'},
      {'title': 'Mensagens', 'icon': lucide.LucideIcons.messageCircle, 'route': '/messages'},
      {'title': 'Agenda', 'icon': lucide.LucideIcons.calendar, 'route': '/schedule'},
      {'title': 'Parcerias', 'icon': lucide.LucideIcons.users, 'route': '/partnerships'},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 180).floor().clamp(2, 4);
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(
              context,
              action['title'] as String,
              action['icon'] as IconData,
              action['route'] as String,
            );
          },
        );
      },
    );
  }
  
  Widget _buildQuickAccessList(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(lucide.LucideIcons.edit),
          title: const Text('Editar Perfil Público'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/profile/edit'),
        ),
        ListTile(
          leading: const Icon(lucide.LucideIcons.settings),
          title: const Text('Configurações'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/profile/settings'),
        ),
        BlocBuilder<LawyerFirmBloc, LawyerFirmState>(
          builder: (context, state) {
            if (state is LawyerFirmLoaded) {
              return ListTile(
                leading: const Icon(lucide.LucideIcons.building),
                title: const Text('Perfil do Escritório'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/firms/${state.firm.id}'),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, String route) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildIndependentLawyerCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              lucide.LucideIcons.building2,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Advogado Independente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Você não está vinculado a nenhum escritório.\nTrabalhando de forma independente.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    context.go('/partnerships');
                  },
                  icon: const Icon(lucide.LucideIcons.users),
                  label: const Text('Buscar Parcerias'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implementar criação de escritório
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Criação de escritório em desenvolvimento'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  icon: const Icon(lucide.LucideIcons.plus),
                  label: const Text('Criar Escritório'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _retryLoadFirmInfo(BuildContext context) {
    BlocProvider.of<LawyerFirmBloc>(context).add(const LoadLawyerFirmInfo());
  }
} 