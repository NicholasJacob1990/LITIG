import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/offers/domain/entities/case_offer.dart';
import 'package:meu_app/src/features/offers/presentation/bloc/offers_bloc.dart';
import 'package:meu_app/src/features/offers/presentation/bloc/offers_event.dart';
import 'package:meu_app/src/features/offers/presentation/bloc/offers_state.dart';
import 'package:meu_app/injection_container.dart';
import '../widgets/case_offer_card.dart';
import '../widgets/offer_dialogs.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OffersBloc>()..add(LoadOffersData()),
      child: const _OffersView(),
    );
  }
}

class _OffersView extends StatefulWidget {
  const _OffersView();

  @override
  State<_OffersView> createState() => _OffersViewState();
}

class _OffersViewState extends State<_OffersView> with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas de Casos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<OffersBloc>().add(LoadOffersData());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            BlocBuilder<OffersBloc, OffersState>(
              buildWhen: (previous, current) =>
                  previous is OffersLoading || current is OffersLoaded,
              builder: (context, state) {
                final count = state is OffersLoaded ? state.pendingOffers.length : 0;
                return Tab(text: 'Pendentes ($count)');
              },
            ),
            const Tab(text: 'Histórico'),
            const Tab(text: 'Estatísticas'),
          ],
        ),
      ),
      body: BlocConsumer<OffersBloc, OffersState>(
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
             return TabBarView(
              controller: _tabController,
              children: [
                _PendingOffersTab(offers: state.pendingOffers),
                // TODO: Build History Tab
                const Center(child: Text('Histórico')),
                // TODO: Build Stats Tab
                _StatsTab(stats: state.stats),
              ],
            );
          }
          return const Center(child: Text('Estado não tratado.'));
        },
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