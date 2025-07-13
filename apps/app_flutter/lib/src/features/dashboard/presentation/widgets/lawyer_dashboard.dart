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
    return BlocProvider(
      create: (context) {
        // TODO: Mover para GetIt
        final dataSource = DashboardRemoteDataSourceImpl();
        final repository = DashboardRepositoryImpl(remoteDataSource: dataSource);
        final useCase = GetLawyerStatsUseCase(repository);
        return DashboardBloc(getLawyerStatsUseCase: useCase)..add(FetchLawyerStats());
      },
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

  Widget _buildActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(context, 'Meus Casos', lucide.LucideIcons.briefcase, '/cases'),
        _buildActionCard(context, 'Mensagens', lucide.LucideIcons.messageCircle, '/messages'),
        _buildActionCard(context, 'Agenda', lucide.LucideIcons.calendar, '/schedule'),
        _buildActionCard(context, 'Notificações', lucide.LucideIcons.bell, '/notifications'),
      ],
    );
  }
  
  Widget _buildQuickAccessList(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(lucide.LucideIcons.edit),
          title: const Text('Editar Perfil Público'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/profile/edit'),
        ),
        ListTile(
          leading: Icon(lucide.LucideIcons.settings),
          title: const Text('Configurações'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/profile/settings'),
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
} 