import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/lawyers_bloc.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/explanation_modal.dart';
import 'package:meu_app/src/features/recommendations/presentation/widgets/lawyer_match_card.dart';

class LawyersScreen extends StatelessWidget {
  const LawyersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LawyersBloc(),
      child: const LawyersView(),
    );
  }
}

class LawyersView extends StatefulWidget {
  const LawyersView({super.key});

  @override
  State<LawyersView> createState() => _LawyersViewState();
}

class _LawyersViewState extends State<LawyersView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Advogados',
          style: TextStyle(
            fontFamily: 'Sans-serif',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.slidersHorizontal),
            onPressed: () {
              // TODO: Implementar modal de filtros avançados
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Recomendações'),
            Tab(text: 'Buscar Advogado'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          RecommendationsTabView(),
          SearchTabView(),
        ],
      ),
    );
  }
}

class RecommendationsTabView extends StatefulWidget {
  const RecommendationsTabView({super.key});

  @override
  State<RecommendationsTabView> createState() => _RecommendationsTabViewState();
}

class _RecommendationsTabViewState extends State<RecommendationsTabView> {
  @override
  void initState() {
    super.initState();
    // Supondo que o caseId viria dos argumentos da rota
    const caseId = 'case-123';
    context.read<LawyersBloc>().add(const FetchLawyers(caseId: caseId));
  }

  void _showExplanationModal(BuildContext context, String explanation, Map<String, dynamic> lawyer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExplanationModal(explanation: explanation, lawyer: lawyer),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LawyersBloc, LawyersState>(
      listener: (context, state) {
        if (state is ExplanationLoaded) {
          _showExplanationModal(context, state.explanation, state.lawyer);
        }
      },
      child: BlocBuilder<LawyersBloc, LawyersState>(
        builder: (context, state) {
          if (state is LawyersLoading || state is LawyersInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is LawyersError) {
            return Center(child: Text(state.message));
          }
          if (state is LawyersLoaded) {
            return ListView.builder(
              itemCount: state.lawyers.length,
              itemBuilder: (context, index) {
                final lawyer = state.lawyers[index];
                return LawyerMatchCard(
                  lawyer: lawyer,
                  onSelect: () {
                    // Lógica para selecionar advogado
                  },
                  onExplain: () {
                    context.read<LawyersBloc>().add(
                          ExplainMatch(caseId: 'case-123', lawyerId: lawyer['lawyer_id']),
                        );
                  },
                );
              },
            );
          }
          return const Center(child: Text('Nenhum advogado encontrado.'));
        },
      ),
    );
  }
}

class SearchTabView extends StatelessWidget {
  const SearchTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Busca Manual de Advogados'),
    );
  }
} 