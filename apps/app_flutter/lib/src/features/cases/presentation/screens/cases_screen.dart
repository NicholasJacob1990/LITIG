import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/cases_bloc.dart';
import 'package:meu_app/src/features/cases/presentation/widgets/case_card.dart';
import 'package:meu_app/injection_container.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CasesScreen extends StatelessWidget {
  const CasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CasesBloc>()..add(FetchCases()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meus Casos'),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/triage'),
          icon: const Icon(LucideIcons.plus),
          label: const Text('Criar Novo Caso'),
          tooltip: 'Iniciar nova consulta de caso',
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.alertCircle, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Erro: ${state.message}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.read<CasesBloc>().add(FetchCases()),
                            child: const Text('Tentar Novamente'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is CasesLoaded) {
                    if (state.filteredCases.isEmpty) {
                      return _buildEmptyState(context, state.activeFilter);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Padding para o FAB
                      itemCount: state.filteredCases.length,
                      itemBuilder: (context, index) {
                        final caseData = state.filteredCases[index];
                        return CaseCard(
                          caseId: caseData.id,
                          title: caseData.title,
                          subtitle: 'Status: ${caseData.status}',
                          clientType: 'PF', // TODO: Obter do caso
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

  Widget _buildEmptyState(BuildContext context, String activeFilter) {
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
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/triage'),
            icon: const Icon(LucideIcons.plus),
            label: const Text('Iniciar Nova Consulta'),
          ),
        ],
      ),
    );
  }
} 