import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/offers/domain/entities/case_offer.dart';
import 'package:meu_app/src/features/offers/presentation/bloc/offers_bloc.dart';
import 'package:meu_app/src/features/offers/presentation/bloc/offers_event.dart';
import 'package:meu_app/src/features/offers/presentation/bloc/offers_state.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/lawyer_hiring_bloc.dart';
import 'package:meu_app/src/features/lawyers/presentation/screens/hiring_proposals_screen.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_bloc.dart';
import 'package:meu_app/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:meu_app/injection_container.dart';
import '../widgets/case_offer_card.dart';
import '../widgets/offer_dialogs.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<OffersBloc>()..add(LoadOffersData()),
        ),
        BlocProvider(
          create: (_) => getIt<LawyerHiringBloc>(),
        ),
        BlocProvider(
          create: (_) => getIt<PartnershipsBloc>(),
        ),
        BlocProvider(
          create: (_) => getIt<DashboardBloc>()..add(FetchLawyerStats()),
        ),
      ],
      child: const _UnifiedLawyerWorkspace(),
    );
  }
}

class _UnifiedLawyerWorkspace extends StatefulWidget {
  const _UnifiedLawyerWorkspace();

  @override
  State<_UnifiedLawyerWorkspace> createState() => _UnifiedLawyerWorkspaceState();
}

class _UnifiedLawyerWorkspaceState extends State<_UnifiedLawyerWorkspace> with TickerProviderStateMixin {
  late final TabController _mainTabController;
  late final TabController _offersTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 4, vsync: this); // Expandido para 4 abas
    _offersTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _offersTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Trabalho'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        bottom: TabBar(
          controller: _mainTabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: [
            BlocBuilder<OffersBloc, OffersState>(
              buildWhen: (previous, current) =>
                  previous is OffersLoading || current is OffersLoaded,
              builder: (context, state) {
                final count = state is OffersLoaded ? state.pendingOffers.length : 0;
                return Tab(
                  icon: const Icon(Icons.inbox),
                  text: 'Ofertas ($count)',
                );
              },
            ),
            BlocBuilder<LawyerHiringBloc, LawyerHiringState>(
              builder: (context, state) {
                // TODO: Implementar contagem de propostas pendentes
                return const Tab(
                  icon: Icon(Icons.file_present),
                  text: 'Propostas',
                );
              },
            ),
            BlocBuilder<PartnershipsBloc, PartnershipsState>(
              builder: (context, state) {
                // TODO: Implementar contagem de parcerias ativas
                return const Tab(
                  icon: Icon(Icons.people),
                  text: 'Parcerias',
                );
              },
            ),
            const Tab(
              icon: Icon(Icons.analytics),
              text: 'Controle',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildPlatformOffersView(),
          _buildClientProposalsView(),
          _buildPartnershipsView(),
          _buildDashboardView(),
        ],
      ),
    );
  }

  Widget _buildPlatformOffersView() {
    return BlocConsumer<OffersBloc, OffersState>(
      listener: (context, state) {
        if (state is OfferActionSuccess) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
        }
        if (state is OfferActionFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.error), backgroundColor: Colors.red));
        }
      },
      builder: (context, state) {
        if (state is OffersLoading || state is OffersInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is OffersError) {
          return Center(child: Text('Erro: ${state.message}'));
        }
        if (state is OffersLoaded) {
           return Column(
             children: [
               TabBar(
                 controller: _offersTabController,
                 tabs: [
                   Tab(text: 'Pendentes (${state.pendingOffers.length})'),
                   const Tab(text: 'Histórico'),
                   const Tab(text: 'Estatísticas'),
                 ],
               ),
               Expanded(
                 child: TabBarView(
                   controller: _offersTabController,
                   children: [
                     _PendingOffersTab(offers: state.pendingOffers),
                     const Center(child: Text('Histórico')),
                     _StatsTab(stats: state.stats),
                   ],
                 ),
               ),
             ],
           );
        }
        return const Center(child: Text('Estado não tratado.'));
      },
    );
  }

  Widget _buildClientProposalsView() {
    return const HiringProposalsScreenContent();
  }

  Widget _buildPartnershipsView() {
    return BlocBuilder<PartnershipsBloc, PartnershipsState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Parcerias Ativas',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      context.read<PartnershipsBloc>().add(const LoadPartnerships());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state is PartnershipsLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is PartnershipsLoaded)
                Expanded(
                  child: state.partnerships.isEmpty
                      ? _buildEmptyPartnershipsState()
                      : ListView.builder(
                          itemCount: state.partnerships.length,
                          itemBuilder: (context, index) {
                            final partnership = state.partnerships[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(partnership.partnerName[0].toUpperCase()),
                                ),
                                title: Text(partnership.partnerName),
                                subtitle: Text('Status: ${partnership.status}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () {
                                    // TODO: Implementar menu de ações da parceria
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                )
              else if (state is PartnershipsError)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<PartnershipsBloc>().add(const LoadPartnerships());
                          },
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Expanded(
                  child: Center(child: Text('Carregue suas parcerias')),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyPartnershipsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Nenhuma parceria ativa',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Suas parcerias profissionais aparecerão aqui',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Buscar Parceiros'),
            onPressed: () {
              // TODO: Navegar para tela de busca de parceiros
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Centro de Controle',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildKPICards(state),
              const SizedBox(height: 24),
              _buildQuickActionsGrid(),
              const SizedBox(height: 24),
              _buildRecentActivity(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKPICards(DashboardState state) {
    if (state is DashboardLoaded) {
      final stats = state.stats;
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildKPICard(
            'Casos Ativos',
            '${stats.activeCases}',
            Icons.folder_open,
            Colors.blue,
          ),
          _buildKPICard(
            'Novos Leads',
            '${stats.newLeads}',
            Icons.trending_up,
            Colors.green,
          ),
          _buildKPICard(
            'Alertas',
            '${stats.alerts}',
            Icons.notification_important,
            stats.alerts > 0 ? Colors.orange : Colors.grey,
          ),
          _buildKPICard(
            'Taxa Aceitação',
            '85%', // TODO: Implementar cálculo real
            Icons.check_circle,
            Colors.purple,
          ),
        ],
      );
    } else if (state is DashboardLoading) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return _buildKPICardsPlaceholder();
    }
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Icon(
                  Icons.trending_up,
                  color: Colors.green,
                  size: 16,
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICardsPlaceholder() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildKPICard('Casos Ativos', '--', Icons.folder_open, Colors.grey),
        _buildKPICard('Novos Leads', '--', Icons.trending_up, Colors.grey),
        _buildKPICard('Alertas', '--', Icons.notification_important, Colors.grey),
        _buildKPICard('Taxa Aceitação', '--', Icons.check_circle, Colors.grey),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildQuickActionCard(
              'Ver Casos',
              Icons.folder,
              Colors.blue,
              () {
                // TODO: Navegar para casos
              },
            ),
            _buildQuickActionCard(
              'Buscar Parceiros',
              Icons.search,
              Colors.green,
              () {
                // TODO: Navegar para busca de parceiros
              },
            ),
            _buildQuickActionCard(
              'Mensagens',
              Icons.message,
              Colors.orange,
              () {
                // TODO: Navegar para mensagens
              },
            ),
            _buildQuickActionCard(
              'Configurações',
              Icons.settings,
              Colors.purple,
              () {
                // TODO: Navegar para configurações
              },
            ),
            _buildQuickActionCard(
              'Relatórios',
              Icons.analytics,
              Colors.teal,
              () {
                // TODO: Navegar para relatórios
              },
            ),
            _buildQuickActionCard(
              'Ajuda',
              Icons.help,
              Colors.grey,
              () {
                // TODO: Navegar para ajuda
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atividade Recente',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildActivityItem(
                  'Nova oferta recebida',
                  'Caso de Direito Civil - Cliente João',
                  '2 min atrás',
                  Icons.inbox,
                  Colors.blue,
                ),
                const Divider(),
                _buildActivityItem(
                  'Proposta aceita',
                  'Maria Silva aceitou sua proposta',
                  '1 hora atrás',
                  Icons.check_circle,
                  Colors.green,
                ),
                const Divider(),
                _buildActivityItem(
                  'Nova parceria',
                  'Convite de Dr. Carlos aceito',
                  '3 horas atrás',
                  Icons.people,
                  Colors.purple,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingOffersTab extends StatelessWidget {
  final List<CaseOffer> offers;
  const _PendingOffersTab({required this.offers});

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return const _EmptyState(
        icon: Icons.inbox_outlined,
        title: 'Nenhuma oferta pendente',
        subtitle: 'Quando novos clientes escolherem você, as ofertas aparecerão aqui.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<OffersBloc>().add(LoadOffersData());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          return CaseOfferCard(
            offer: offer,
            onAccept: () => _acceptOffer(context, offer),
            onReject: () => _rejectOffer(context, offer),
          );
        },
      ),
    );
  }

  Future<void> _acceptOffer(BuildContext context, CaseOffer offer) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AcceptOfferDialog(offer: offer),
    );

    if (result == true && context.mounted) {
      context.read<OffersBloc>().add(AcceptOffer(offerId: offer.id));
    }
  }

  Future<void> _rejectOffer(BuildContext context, CaseOffer offer) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => RejectOfferDialog(offer: offer),
    );

    if (reason != null && context.mounted) {
      context.read<OffersBloc>().add(RejectOffer(offerId: offer.id, reason: reason));
    }
  }
}

class _PendingPartnershipsTab extends StatelessWidget {
  final List<Partnership> partnerships;
  const _PendingPartnershipsTab({required this.partnerships});

  @override
  Widget build(BuildContext context) {
    if (partnerships.isEmpty) {
      return const _EmptyState(
        icon: Icons.people_outline,
        title: 'Nenhuma proposta de parceria pendente',
        subtitle: 'Quando novos parceiros se interessarem por você, as propostas aparecerão aqui.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PartnershipsBloc>().add(LoadPartnershipsData());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: partnerships.length,
        itemBuilder: (context, index) {
          final partnership = partnerships[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partnership.clientName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    partnership.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _acceptPartnership(context, partnership),
                        child: const Text('Aceitar'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => _rejectPartnership(context, partnership),
                        child: const Text('Rejeitar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _acceptPartnership(BuildContext context, Partnership partnership) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AcceptPartnershipDialog(partnership: partnership),
    );

    if (result == true && context.mounted) {
      context.read<PartnershipsBloc>().add(AcceptPartnership(partnershipId: partnership.id));
    }
  }

  Future<void> _rejectPartnership(BuildContext context, Partnership partnership) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => RejectPartnershipDialog(partnership: partnership),
    );

    if (reason != null && context.mounted) {
      context.read<PartnershipsBloc>().add(RejectPartnership(partnershipId: partnership.id, reason: reason));
    }
  }
}

class _StatsTab extends StatelessWidget {
  final OfferStats? stats;
  const _StatsTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const _EmptyState(
        icon: Icons.query_stats,
        title: 'Sem estatísticas',
        subtitle: 'Processe algumas ofertas para ver suas estatísticas.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _StatCard(
            icon: Icons.pie_chart,
            label: 'Taxa de Aceitação',
            value: '${(stats!.acceptanceRate * 100).toStringAsFixed(1)}%',
            color: Colors.green,
          ),
          _StatCard(
            icon: Icons.speed,
            label: 'Tempo Médio de Resposta',
            value: '${stats!.avgResponseTimeHours.toStringAsFixed(1)} horas',
            color: Colors.blue,
          ),
          const Divider(height: 32),
          _StatRow(label: 'Total de Ofertas Recebidas', value: stats!.totalOffers.toString()),
          _StatRow(label: 'Ofertas Aceitas', value: stats!.accepted.toString()),
          _StatRow(label: 'Ofertas Rejeitadas', value: stats!.rejected.toString()),
          _StatRow(label: 'Ofertas Expiradas', value: stats!.expired.toString()),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
} 