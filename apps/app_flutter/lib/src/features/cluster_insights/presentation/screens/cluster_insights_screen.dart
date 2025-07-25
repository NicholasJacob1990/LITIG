import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/cluster_insights_modal.dart';
import '../bloc/trending_clusters_bloc.dart';
import '../bloc/partnership_recommendations_bloc.dart';
import '../../../../injection_container.dart';

class ClusterInsightsScreen extends StatelessWidget {
  const ClusterInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<TrendingClustersBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<PartnershipRecommendationsBloc>(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Insights de Mercado'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const ClusterInsightsModal(),
      ),
    );
  }
} 