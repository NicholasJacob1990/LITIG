import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/trending_clusters_bloc.dart';
import '../bloc/trending_clusters_state.dart';
import '../bloc/trending_clusters_event.dart';
import '../../domain/entities/trending_cluster.dart';
import '../../../../../injection_container.dart';

class ClusterDetailScreen extends StatelessWidget {
  final String clusterId;

  const ClusterDetailScreen({super.key, required this.clusterId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TrendingClustersBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes do Cluster'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<TrendingClustersBloc, TrendingClustersState>(
          builder: (context, state) {
            if (state is TrendingClustersLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is TrendingClustersError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar detalhes',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<TrendingClustersBloc>()
                          .add(const FetchTrendingClusters()),
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              );
            }
            
            if (state is TrendingClustersLoaded) {
              final cluster = state.clusters.firstWhere(
                (c) => c.clusterId == clusterId,
                orElse: () => state.clusters.first,
              );
              
              return _buildClusterDetails(context, cluster);
            }
            
            return const Center(child: Text('Carregando...'));
          },
        ),
      ),
    );
  }

  Widget _buildClusterDetails(BuildContext context, TrendingCluster cluster) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do cluster
          Card(
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
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (cluster.isEmergent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'EMERGENTE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Métricas principais
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          'Total de Casos',
                          cluster.totalCases.toString(),
                          Icons.gavel,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          'Momentum',
                          '${(cluster.momentumScore * 100).toStringAsFixed(1)}%',
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Barra de progresso do momentum
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nível de Crescimento',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: cluster.momentumScore,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          cluster.momentumScore > 0.7 ? Colors.green : Colors.orange,
                        ),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMomentumDescription(cluster.momentumScore),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Informações adicionais
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informações Adicionais',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('ID do Cluster', cluster.clusterId),
                  _buildInfoRow(
                    'Confiança do Rótulo', 
                    '${(cluster.labelConfidence * 100).toStringAsFixed(1)}%',
                  ),
                  if (cluster.emergentSince != null)
                    _buildInfoRow(
                      'Emergente desde', 
                      _formatDate(cluster.emergentSince!),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Ações
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showPartnershipRecommendations(context),
              icon: const Icon(Icons.handshake),
              label: const Text('Ver Parcerias Recomendadas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getMomentumDescription(double momentum) {
    if (momentum > 0.8) return 'Crescimento acelerado';
    if (momentum > 0.6) return 'Crescimento moderado';
    if (momentum > 0.4) return 'Crescimento lento';
    return 'Estável';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showPartnershipRecommendations(BuildContext context) {
    // TODO: Navegar para tab de parcerias no modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade será implementada em breve'),
      ),
    );
  }
} 