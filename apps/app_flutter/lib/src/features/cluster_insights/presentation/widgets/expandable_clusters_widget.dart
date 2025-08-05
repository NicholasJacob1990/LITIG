import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/trending_clusters_bloc.dart';
import '../bloc/trending_clusters_state.dart';
import '../bloc/trending_clusters_event.dart';
import '../../domain/entities/trending_cluster.dart';
import 'cluster_insights_modal.dart';
import '../../../../shared/widgets/error_display_widget.dart';
import '../../../../../injection_container.dart';

class ExpandableClustersWidget extends StatelessWidget {
  const ExpandableClustersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TrendingClustersBloc>()..add(const FetchTrendingClusters()),
      child: Card(
        key: const Key('expandable_clusters_card'),
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com CTA "Ver Completo"
              Row(
                children: [
                  const Icon(Icons.analytics, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Insights de Mercado',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    key: const Key('expandable_clusters_ver_completo_button'),
                    onPressed: () => _showFullInsightsModal(context),
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Ver Completo'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Preview compacto dos 3 top clusters
              const SizedBox(height: 16),
              BlocBuilder<TrendingClustersBloc, TrendingClustersState>(
                builder: (context, state) {
                  if (state is TrendingClustersLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  if (state is TrendingClustersError) {
                    return ErrorDisplayWidget(
                      message: state.message,
                      onRetry: () {
                        context.read<TrendingClustersBloc>().add(const FetchTrendingClusters());
                      },
                    );
                  }
                  
                  if (state is TrendingClustersLoaded) {
                    return _buildTrendingList(context, state.clusters);
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
              
              const SizedBox(height: 12),
              
              // CTA para parceiros estratégicos
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.handshake, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Descubra parceiros estratégicos para seu escritório',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showFullInsightsModal(context, initialTab: 'partnerships'),
                      child: const Text('Ver Agora'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingList(BuildContext context, List<TrendingCluster> clusters) {
    if (clusters.isEmpty) {
      return const Text(
        'Nenhuma tendência identificada no momento.',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }

    return Column(
      key: const Key('trending_clusters_list'),
      children: clusters.asMap().entries.map((entry) {
        final index = entry.key;
        final cluster = entry.value;
        
        return _ClusterTrendCard(
          key: Key('cluster_trend_card_${cluster.clusterId}'),
          cluster: cluster,
          rank: index + 1,
          onTap: () => _navigateToClusterDetail(context, cluster.clusterId),
        );
      }).toList(),
    );
  }

  void _showFullInsightsModal(BuildContext context, {String? initialTab}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClusterInsightsModal(initialTab: initialTab),
    );
  }

  void _navigateToClusterDetail(BuildContext context, String clusterId) {
    Navigator.pushNamed(
      context, 
      '/cluster-detail',
      arguments: {'clusterId': clusterId},
    );
  }
}

class _ClusterTrendCard extends StatelessWidget {
  final TrendingCluster cluster;
  final int rank;
  final VoidCallback onTap;

  const _ClusterTrendCard({
    super.key,
    required this.cluster,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRankColor(),
          child: Text(
            '#$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          cluster.clusterLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${cluster.totalCases} casos • Momentum: ${(cluster.momentumScore * 100).toStringAsFixed(0)}%'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cluster.isEmergent) 
              const Icon(Icons.new_releases, color: Colors.orange, size: 20),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getRankColor() {
    switch (rank) {
      case 1: return Colors.amber;
      case 2: return Colors.grey[600]!;
      case 3: return Colors.brown;
      default: return Colors.blue;
    }
  }
} 