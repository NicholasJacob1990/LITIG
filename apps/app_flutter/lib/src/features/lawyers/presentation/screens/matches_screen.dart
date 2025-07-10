import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/lawyers/data/datasources/lawyers_remote_data_source.dart';
import 'package:meu_app/src/features/lawyers/data/repositories/lawyers_repository_impl.dart';
import 'package:meu_app/src/features/lawyers/domain/usecases/find_matches_usecase.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/matches_bloc.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/lawyer_match_card.dart';

class MatchesScreen extends StatelessWidget {
  final String caseId;

  const MatchesScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        // TODO: Mover para injeção de dependência (GetIt)
        final dio = Dio(); 
        final dataSource = LawyersRemoteDataSourceImpl(dio: dio);
        final repository = LawyersRepositoryImpl(remoteDataSource: dataSource);
        final useCase = FindMatchesUseCase(repository);
        return MatchesBloc(findMatchesUseCase: useCase)..add(FetchMatches(caseId: caseId));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Advogados Recomendados'),
        ),
        body: BlocBuilder<MatchesBloc, MatchesState>(
          builder: (context, state) {
            if (state is MatchesLoading || state is MatchesInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MatchesError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Erro ao carregar advogados: ${state.message}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (state is MatchesLoaded) {
              if (state.lawyers.isEmpty) {
                return const Center(
                  child: Text('Nenhum advogado encontrado para este caso.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                itemCount: state.lawyers.length,
                itemBuilder: (context, index) {
                  final lawyer = state.lawyers[index];
                  return LawyerMatchCard(
                    lawyer: lawyer,
                    onSelect: () {},
                    onExplain: () {},
                  );
                },
              );
            }

            return const Center(child: Text('Estado não previsto.'));
          },
        ),
      ),
    );
  }
} 