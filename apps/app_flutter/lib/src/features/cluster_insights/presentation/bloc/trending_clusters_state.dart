import 'package:equatable/equatable.dart';
import '../../domain/entities/trending_cluster.dart';

abstract class TrendingClustersState extends Equatable {
  const TrendingClustersState();

  @override
  List<Object?> get props => [];
}

class TrendingClustersInitial extends TrendingClustersState {}

class TrendingClustersLoading extends TrendingClustersState {}

class TrendingClustersLoaded extends TrendingClustersState {
  final List<TrendingCluster> clusters;

  const TrendingClustersLoaded(this.clusters);

  @override
  List<Object?> get props => [clusters];
}

class TrendingClustersError extends TrendingClustersState {
  final String message;

  const TrendingClustersError(this.message);

  @override
  List<Object?> get props => [message];
} 