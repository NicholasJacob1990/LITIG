import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:meu_app/src/features/cluster_insights/domain/repositories/cluster_repository.dart';
import 'package:meu_app/src/features/cluster_insights/presentation/bloc/trending_clusters_bloc.dart';
import 'package:meu_app/src/features/cluster_insights/domain/entities/trending_cluster.dart';

import 'trending_clusters_bloc_test.mocks.dart';

@GenerateMocks([ClusterRepository])
void main() {
  late MockClusterRepository mockClusterRepository;
  late TrendingClustersBloc trendingClustersBloc;

  setUp(() {
    mockClusterRepository = MockClusterRepository();
    trendingClustersBloc = TrendingClustersBloc(repository: mockClusterRepository);
  });

  tearDown(() {
    trendingClustersBloc.close();
  });

  final tTrendingClusters = [
    const TrendingCluster(
      clusterId: 'cluster_1',
      clusterLabel: 'Direito Digital',
      momentumScore: 0.85,
      totalCases: 50,
      isEmergent: true,
      labelConfidence: 0.9,
    ),
    const TrendingCluster(
      clusterId: 'cluster_2',
      clusterLabel: 'Contratos de SaaS',
      momentumScore: 0.75,
      totalCases: 30,
      isEmergent: false,
      labelConfidence: 0.8,
    ),
  ];

  group('TrendingClustersBloc', () {
    test('o estado inicial deve ser TrendingClustersInitial', () {
      expect(trendingClustersBloc.state, equals(TrendingClustersInitial()));
    });

    blocTest<TrendingClustersBloc, TrendingClustersState>(
      'deve emitir [Loading, Loaded] quando os dados são obtidos com sucesso',
      build: () {
        when(mockClusterRepository.getTrendingClusters(clusterType: anyNamed('clusterType'), limit: anyNamed('limit')))
            .thenAnswer((_) async => tTrendingClusters.map((e) => e.toJson()).toList());
        return trendingClustersBloc;
      },
      act: (bloc) => bloc.add(const FetchTrendingClusters()),
      expect: () => [
        TrendingClustersLoading(),
        isA<TrendingClustersLoaded>().having(
          (state) => state.clusters.length,
          'clusters length',
          tTrendingClusters.length,
        ),
      ],
      verify: (_) {
        verify(mockClusterRepository.getTrendingClusters(clusterType: 'case', limit: 3));
      },
    );

    blocTest<TrendingClustersBloc, TrendingClustersState>(
      'deve emitir [Loading, Error] quando a obtenção de dados falha',
      build: () {
        when(mockClusterRepository.getTrendingClusters(clusterType: anyNamed('clusterType'), limit: anyNamed('limit')))
            .thenThrow(Exception('Falha ao buscar dados'));
        return trendingClustersBloc;
      },
      act: (bloc) => bloc.add(const FetchTrendingClusters()),
      expect: () => [
        TrendingClustersLoading(),
        isA<TrendingClustersError>().having(
          (state) => state.message,
          'error message',
          contains('Falha ao buscar dados'),
        ),
      ],
    );

    blocTest<TrendingClustersBloc, TrendingClustersState>(
      'deve emitir [Loaded] com isRefreshing=true, depois [Loaded] com isRefreshing=false ao recarregar',
      build: () {
        when(mockClusterRepository.getTrendingClusters(clusterType: anyNamed('clusterType'), limit: anyNamed('limit')))
            .thenAnswer((_) async => tTrendingClusters.map((e) => e.toJson()).toList());
        return trendingClustersBloc;
      },
      act: (bloc) => bloc.add(const RefreshTrendingClusters()),
      // O estado inicial é o mesmo, então a primeira emissão é o carregado com `isRefreshing: true`
      // seguido pelo estado carregado normal.
      // O skip(1) é para pular o estado initial que é emitido na criação do BLoC
      expect: () => [
        isA<TrendingClustersLoaded>()
            .having((state) => state.isRefreshing, 'isRefreshing', true)
            .having((state) => state.clusters, 'clusters', isEmpty), // Assume que o estado anterior estava vazio
        isA<TrendingClustersLoaded>()
            .having((state) => state.isRefreshing, 'isRefreshing', false)
            .having((state) => state.clusters.length, 'clusters length', tTrendingClusters.length),
      ],
    );
  });
} 