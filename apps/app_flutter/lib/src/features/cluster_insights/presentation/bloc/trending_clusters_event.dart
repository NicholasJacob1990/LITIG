import 'package:equatable/equatable.dart';

abstract class TrendingClustersEvent extends Equatable {
  const TrendingClustersEvent();

  @override
  List<Object?> get props => [];
}

class FetchTrendingClusters extends TrendingClustersEvent {
  final String clusterType;
  final int limit;

  const FetchTrendingClusters({
    this.clusterType = 'case',
    this.limit = 3,
  });

  @override
  List<Object?> get props => [clusterType, limit];
}

class RefreshTrendingClusters extends TrendingClustersEvent {
  const RefreshTrendingClusters();
} 