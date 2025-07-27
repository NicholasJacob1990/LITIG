import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/cluster_insights/domain/entities/cluster_detail.dart';
import 'package:meu_app/src/features/cluster_insights/domain/repositories/cluster_repository.dart';

// Events
abstract class AllClustersEvent extends Equatable {
  const AllClustersEvent();
  @override
  List<Object> get props => [];
}

class FetchAllClusters extends AllClustersEvent {}

// States
abstract class AllClustersState extends Equatable {
  const AllClustersState();
  @override
  List<Object> get props => [];
}

class AllClustersInitial extends AllClustersState {}

class AllClustersLoading extends AllClustersState {}

class AllClustersLoaded extends AllClustersState {
  final List<ClusterDetail> clusters;
  const AllClustersLoaded(this.clusters);
  @override
  List<Object> get props => [clusters];
}

class AllClustersError extends AllClustersState {
  final String message;
  const AllClustersError(this.message);
  @override
  List<Object> get props => [message];
}

// BLoC
class AllClustersBloc extends Bloc<AllClustersEvent, AllClustersState> {
  final ClusterRepository repository;

  AllClustersBloc({required this.repository}) : super(AllClustersInitial()) {
    on<FetchAllClusters>((event, emit) async {
      emit(AllClustersLoading());
      try {
        // NOTA: O repositório precisa de um método `getAllClusters`.
        // Vamos assumir que ele existe e retorna List<ClusterDetail>.
        final clusters = await repository.getAllClusters(); 
        emit(AllClustersLoaded(clusters));
      } catch (e) {
        emit(AllClustersError('Falha ao buscar todos os clusters: $e'));
      }
    });
  }
} 
 