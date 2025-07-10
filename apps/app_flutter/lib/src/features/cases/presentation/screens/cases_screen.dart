import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/cases/data/datasources/cases_remote_data_source.dart';
import 'package:meu_app/src/features/cases/data/repositories/cases_repository_impl.dart';
import 'package:meu_app/src/features/cases/domain/usecases/get_my_cases_usecase.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/cases_bloc.dart';
import 'package:meu_app/src/features/cases/presentation/widgets/case_card.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CasesScreen extends StatelessWidget {
  const CasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        // TODO: Mover para GetIt
        final dio = Dio();
        final dataSource = CasesRemoteDataSourceImpl(dio: dio);
        final repository = CasesRepositoryImpl(remoteDataSource: dataSource);
        final useCase = GetMyCasesUseCase(repository);
        return CasesBloc(getMyCasesUseCase: useCase)..add(FetchCases());
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meus Casos'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildFilterSection(),
            Expanded(
              child: BlocBuilder<CasesBloc, CasesState>(
                builder: (context, state) {
                  if (state is CasesLoading || state is CasesInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CasesError) {
                    return Center(child: Text('Erro: ${state.message}'));
                  }
                  if (state is CasesLoaded) {
                    if (state.filteredCases.isEmpty) {
                      return _buildEmptyState(state.activeFilter);
                    }
                    return ListView.builder(
                      itemCount: state.filteredCases.length,
                      itemBuilder: (context, index) {
                        final caseData = state.filteredCases[index];
                        return CaseCard(
                          caseId: caseData.id,
                          title: caseData.title,
                          subtitle: 'Status: ${caseData.status}', // Exemplo
                          clientType: 'PF', // Exemplo
                          status: caseData.status,
                          preAnalysisDate: caseData.createdAt.toIso8601String(),
                          lawyer: caseData.lawyer,
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterSection() {
    const filters = ['Todos', 'Em Andamento', 'Concluído', 'Aguardando'];
    return BlocBuilder<CasesBloc, CasesState>(
      builder: (context, state) {
        if (state is! CasesLoaded) return const SizedBox(height: 60);

        return SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final filter = filters[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: state.activeFilter == filter,
                  onSelected: (_) => context.read<CasesBloc>().add(FilterCases(filter)),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String activeFilter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.folderX, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Não há casos com status "$activeFilter"',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
} 