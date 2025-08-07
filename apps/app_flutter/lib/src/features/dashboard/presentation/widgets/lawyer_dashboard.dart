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
                      lucide.LucideIcons.user,
                      size: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LAWYER DASHBOARD',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Painel Pessoal do Advogado Associado',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              _buildPersonalDashboard(context),
              const SizedBox(height: 24),
              _buildAgendaAndTasks(context),
              const SizedBox(height: 24),
              _buildPerformanceSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalDashboard(BuildContext context) {
    return _buildDashboardSection(
      context,
      title: 'Dashboard Pessoal',
      icon: lucide.LucideIcons.user,
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardError) {
            return Center(child: Text(state.message));
          }
          if (state is DashboardLoaded) {
            final stats = state.stats;
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: StatCard(title: 'Casos Ativos', value: '${stats.activeCases}', icon: lucide.LucideIcons.briefcase, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(width: 16),
                    Expanded(child: StatCard(title: 'Produtividade', value: '92%', icon: lucide.LucideIcons.trendingUp, color: Colors.green.shade400)),
                  ],
                ),
                const SizedBox(height: 16),
                StatCard(title: 'Metas do Mês', value: '75%', icon: lucide.LucideIcons.target, color: Colors.orange.shade400),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAgendaAndTasks(BuildContext context) {
    return _buildDashboardSection(
      context,
      title: 'Agenda e Tarefas',
      icon: lucide.LucideIcons.calendar,
      child: Column(
        children: [
          _buildInfoCard(context, 'Próximas Audiências', '2', 'Ver agenda completa', '/schedule'),
          const SizedBox(height: 16),
          _buildInfoCard(context, 'Prazos', '5', 'Ver todos os prazos', '/deadlines'),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(BuildContext context) {
    return _buildDashboardSection(
      context,
      title: 'Performance',
      icon: lucide.LucideIcons.barChart,
      child: Column(
        children: [
          _buildInfoCard(context, 'Estatísticas', 'Visualizar', 'Analisar performance', '/statistics'),
          const SizedBox(height: 16),
          _buildInfoCard(context, 'Relatórios', 'Gerar', 'Exportar relatórios', '/reports'),
          const SizedBox(height: 16),
          _buildInfoCard(context, 'Financeiro', 'Abrir', 'Ver indicadores financeiros', '/financial'),
        ],
      ),
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

  Widget _buildInfoCard(BuildContext context, String title, String value, String buttonText, String route) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).primaryColor)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => context.go(route),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
} 