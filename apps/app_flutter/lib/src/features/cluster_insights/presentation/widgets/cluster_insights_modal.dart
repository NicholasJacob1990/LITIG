import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/trending_clusters_bloc.dart';
import '../bloc/trending_clusters_state.dart';
import '../bloc/all_clusters_bloc.dart';
import '../bloc/partnership_recommendations_bloc.dart';
import '../../domain/entities/trending_cluster.dart';
import '../../domain/entities/partnership_recommendation.dart';
import 'partnership_recommendation_card.dart';
import '../../../../../injection_container.dart';

class ClusterInsightsModal extends StatefulWidget {
  final String? initialTab;
  
  const ClusterInsightsModal({super.key, this.initialTab});

  @override
  State<ClusterInsightsModal> createState() => _ClusterInsightsModalState();
}

class _ClusterInsightsModalState extends State<ClusterInsightsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab == 'partnerships' ? 2 : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Insights de Mercado',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(icon: Icon(Icons.trending_up), text: 'Tendências'),
              Tab(icon: Icon(Icons.category), text: 'Todos Clusters'),
              Tab(icon: Icon(Icons.handshake), text: 'Parcerias'),
            ],
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TrendingClustersTab(),
                BlocProvider(
                  create: (context) => getIt<AllClustersBloc>()..add(FetchAllClusters()),
                  child: _AllClustersTab(),
                ),
                BlocProvider(
                  create: (context) => getIt<PartnershipRecommendationsBloc>(),
                  child: _PartnershipRecommendationsTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Tab 1: Tendências Detalhadas
class _TrendingClustersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nichos Emergentes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          BlocBuilder<TrendingClustersBloc, TrendingClustersState>(
            builder: (context, state) {
              if (state is TrendingClustersLoaded) {
                return Column(
                  children: state.clusters.map((cluster) => 
                    _DetailedClusterCard(cluster: cluster)
                  ).toList(),
                );
              }
              return const CircularProgressIndicator();
            },
          ),
        ],
      ),
    );
  }
}

// Tab 2: Todos os Clusters
class _AllClustersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Todos os Clusters Identificados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Lista completa com filtros
          BlocBuilder<AllClustersBloc, AllClustersState>(
            builder: (context, state) {
              if (state is AllClustersLoaded) {
                return Column(
                  children: state.clusters.map((cluster) => 
                    _ClusterOverviewCard(cluster: cluster)
                  ).toList(),
                );
              }
              return const CircularProgressIndicator();
            },
          ),
        ],
      ),
    );
  }
}

// Tab 3: Recomendações de Parceria
class _PartnershipRecommendationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parceiros Estratégicos Recomendados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Baseado em análise de complementaridade de clusters',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          
          BlocBuilder<PartnershipRecommendationsBloc, PartnershipRecommendationsState>(
            builder: (context, state) {
              if (state is PartnershipRecommendationsLoaded) {
                return Column(
                  children: state.recommendations.map((rec) => 
                    PartnershipRecommendationCard(
                      recommendation: rec,
                      onContact: () => _contactPartner(context, rec),
                      onViewProfile: () => _viewProfile(context, rec),
                    )
                  ).toList(),
                );
              }
              return const CircularProgressIndicator();
            },
          ),
        ],
      ),
    );
  }

  void _contactPartner(BuildContext context, PartnershipRecommendation rec) {
    // TODO: Implementar navegação para chat/contato
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contatando ${rec.lawyerName}...')),
    );
  }

  void _viewProfile(BuildContext context, PartnershipRecommendation rec) {
    // TODO: Implementar navegação para perfil do advogado
    Navigator.pushNamed(
      context,
      '/lawyer-detail',
      arguments: {'lawyerId': rec.recommendedLawyerId},
    );
  }
}

// Card detalhado para cluster
class _DetailedClusterCard extends StatelessWidget {
  final TrendingCluster cluster;

  const _DetailedClusterCard({required this.cluster});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    cluster.clusterLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (cluster.isEmergent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'EMERGENTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${cluster.totalCases} casos identificados'),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.trending_up, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text('Momentum: ${(cluster.momentumScore * 100).toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: cluster.momentumScore,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                cluster.momentumScore > 0.7 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Card overview para cluster
class _ClusterOverviewCard extends StatelessWidget {
  final TrendingCluster cluster;

  const _ClusterOverviewCard({required this.cluster});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cluster.isEmergent ? Colors.orange : Colors.blue,
        child: Text(
          cluster.totalCases.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      title: Text(cluster.clusterLabel),
      subtitle: Text('Momentum: ${(cluster.momentumScore * 100).toStringAsFixed(0)}%'),
      trailing: cluster.isEmergent 
          ? const Icon(Icons.new_releases, color: Colors.orange)
          : const Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/cluster-detail',
          arguments: {'clusterId': cluster.clusterId},
        );
      },
    );
  }
} 