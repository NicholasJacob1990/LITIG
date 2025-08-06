import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/cluster_repository.dart';
import '../../domain/entities/trending_cluster.dart';
import 'trending_clusters_event.dart';
import 'trending_clusters_state.dart';

class TrendingClustersBloc 
    extends Bloc<TrendingClustersEvent, TrendingClustersState> {
  final ClusterRepository repository;

  TrendingClustersBloc({required this.repository})
      : super(TrendingClustersInitial()) {
    on<FetchTrendingClusters>(_onFetchTrendingClusters);
    on<RefreshTrendingClusters>(_onRefreshTrendingClusters);
  }

  Future<void> _onFetchTrendingClusters(
    FetchTrendingClusters event,
    Emitter<TrendingClustersState> emit,
  ) async {
    emit(TrendingClustersLoading());

    try {
      final clustersData = await repository.getTrendingClusters(
        clusterType: event.clusterType,
        limit: event.limit,
      );

      final clusters = clustersData.map((json) => 
        TrendingCluster.fromJson(json)
      ).toList();

      emit(TrendingClustersLoaded(clusters));
    } catch (e) {
      emit(TrendingClustersError('Erro ao carregar clusters: $e'));
    }
  }

  Future<void> _onRefreshTrendingClusters(
    RefreshTrendingClusters event,
    Emitter<TrendingClustersState> emit,
  ) async {
    add(const FetchTrendingClusters());
  }
} 