import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../bloc/lawyer_detail_bloc.dart';
import '../bloc/lawyer_detail_event.dart';
import '../bloc/lawyer_detail_state.dart';

// Widgets especializados
import '../widgets/linkedin_profile_view.dart';
import '../widgets/academic_profile_view.dart';
import '../widgets/curriculum_view.dart';
import '../widgets/data_transparency_view.dart';

class LawyerDetailScreen extends StatefulWidget {
  final String lawyerId;

  const LawyerDetailScreen({super.key, required this.lawyerId});

  @override
  State<LawyerDetailScreen> createState() => _LawyerDetailScreenState();
}

class _LawyerDetailScreenState extends State<LawyerDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Dispara o evento para carregar os detalhes do advogado ao iniciar a tela
    context.read<LawyerDetailBloc>().add(LoadLawyerDetail(widget.lawyerId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<LawyerDetailBloc, LawyerDetailState>(
        builder: (context, state) {
          if (state is LawyerDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is LawyerDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro ao carregar: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<LawyerDetailBloc>()
                          .add(LoadLawyerDetail(widget.lawyerId));
                    },
                    child: const Text('Tentar Novamente'),
                  )
                ],
              ),
            );
          }
          if (state is LawyerDetailLoaded) {
            return _buildLoadedContent(context, state);
          }
          return const Center(child: Text("Estado inicial ou não esperado."));
        },
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, LawyerDetailLoaded state) {
    final lawyer = state.enrichedLawyer;
    return CustomScrollView(
      slivers: [
        _buildAppBar(context, lawyer.nome),
        SliverToBoxAdapter(
          child: DefaultTabController(
            length: 5,
            child: Column(
              children: [
                // _buildProfileHeader(lawyer), // Será implementado depois
                _buildTabBar(),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200, // Altura ajustável
                                      child: TabBarView(
                      children: [
                        _buildOverviewTab(state),
                        _buildLinkedInTab(state),
                        _buildAcademicTab(state),
                        _buildCurriculumTab(),
                        _buildTransparencyTab(state),
                      ],
                    ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, String lawyerName) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.share),
          onPressed: () { /* TODO: Implementar compartilhamento */ },
        ),
        IconButton(
          icon: const Icon(LucideIcons.bookmark),
          onPressed: () { /* TODO: Implementar salvar nos favoritos */ },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(lawyerName, style: const TextStyle(fontSize: 16)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return const TabBar(
      isScrollable: true,
      tabs: [
        Tab(icon: Icon(LucideIcons.user), text: 'Visão Geral'),
        Tab(icon: Icon(LucideIcons.linkedin), text: 'LinkedIn'),
        Tab(icon: Icon(LucideIcons.graduationCap), text: 'Acadêmico'),
        Tab(icon: Icon(LucideIcons.fileText), text: 'Currículo'),
        Tab(icon: Icon(LucideIcons.shield), text: 'Transparência'),
      ],
    );
  }

  Widget _buildOverviewTab(LawyerDetailLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo do Perfil',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.enrichedLawyer.bio ?? 'Informações detalhadas sobre o perfil profissional do advogado.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Especialidades',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.enrichedLawyer.especialidades.map((spec) => 
                      Chip(label: Text(spec))
                    ).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qualidade dos Dados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: state.enrichedLawyer.overallQualityScore,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.enrichedLawyer.overallQualityScore >= 0.8 
                          ? Colors.green 
                          : state.enrichedLawyer.overallQualityScore >= 0.6 
                              ? Colors.orange 
                              : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(state.enrichedLawyer.overallQualityScore * 100).toInt()}% de completude',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedInTab(LawyerDetailLoaded state) {
    if (state.enrichedLawyer.linkedinProfile != null) {
      return LinkedInProfileView(profile: state.enrichedLawyer.linkedinProfile!);
    }
    return _buildNoDataView('LinkedIn não conectado');
  }

  Widget _buildAcademicTab(LawyerDetailLoaded state) {
    if (state.enrichedLawyer.academicProfile != null) {
      return AcademicProfileView(profile: state.enrichedLawyer.academicProfile!);
    }
    return _buildNoDataView('Dados acadêmicos não disponíveis');
  }

  Widget _buildCurriculumTab() {
    return CurriculumView(lawyerId: widget.lawyerId);
  }

  Widget _buildTransparencyTab(LawyerDetailLoaded state) {
    return DataTransparencyView(
      dataSources: state.enrichedLawyer.dataSources,
      qualityScore: state.enrichedLawyer.overallQualityScore,
      lastUpdated: state.enrichedLawyer.lastConsolidated,
    );
  }

  Widget _buildNoDataView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.database,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Estes dados serão disponibilizados assim que a integração for concluída.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../bloc/lawyer_detail_bloc.dart';
import '../bloc/lawyer_detail_event.dart';
import '../bloc/lawyer_detail_state.dart';

// Widgets especializados
import '../widgets/linkedin_profile_view.dart';
import '../widgets/academic_profile_view.dart';
import '../widgets/curriculum_view.dart';
import '../widgets/data_transparency_view.dart';

class LawyerDetailScreen extends StatefulWidget {
  final String lawyerId;

  const LawyerDetailScreen({super.key, required this.lawyerId});

  @override
  State<LawyerDetailScreen> createState() => _LawyerDetailScreenState();
}

class _LawyerDetailScreenState extends State<LawyerDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Dispara o evento para carregar os detalhes do advogado ao iniciar a tela
    context.read<LawyerDetailBloc>().add(LoadLawyerDetail(widget.lawyerId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<LawyerDetailBloc, LawyerDetailState>(
        builder: (context, state) {
          if (state is LawyerDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is LawyerDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro ao carregar: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<LawyerDetailBloc>()
                          .add(LoadLawyerDetail(widget.lawyerId));
                    },
                    child: const Text('Tentar Novamente'),
                  )
                ],
              ),
            );
          }
          if (state is LawyerDetailLoaded) {
            return _buildLoadedContent(context, state);
          }
          return const Center(child: Text("Estado inicial ou não esperado."));
        },
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, LawyerDetailLoaded state) {
    final lawyer = state.enrichedLawyer;
    return CustomScrollView(
      slivers: [
        _buildAppBar(context, lawyer.nome),
        SliverToBoxAdapter(
          child: DefaultTabController(
            length: 5,
            child: Column(
              children: [
                // _buildProfileHeader(lawyer), // Será implementado depois
                _buildTabBar(),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200, // Altura ajustável
                                      child: TabBarView(
                      children: [
                        _buildOverviewTab(state),
                        _buildLinkedInTab(state),
                        _buildAcademicTab(state),
                        _buildCurriculumTab(),
                        _buildTransparencyTab(state),
                      ],
                    ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, String lawyerName) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.share),
          onPressed: () { /* TODO: Implementar compartilhamento */ },
        ),
        IconButton(
          icon: const Icon(LucideIcons.bookmark),
          onPressed: () { /* TODO: Implementar salvar nos favoritos */ },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(lawyerName, style: const TextStyle(fontSize: 16)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return const TabBar(
      isScrollable: true,
      tabs: [
        Tab(icon: Icon(LucideIcons.user), text: 'Visão Geral'),
        Tab(icon: Icon(LucideIcons.linkedin), text: 'LinkedIn'),
        Tab(icon: Icon(LucideIcons.graduationCap), text: 'Acadêmico'),
        Tab(icon: Icon(LucideIcons.fileText), text: 'Currículo'),
        Tab(icon: Icon(LucideIcons.shield), text: 'Transparência'),
      ],
    );
  }

  Widget _buildOverviewTab(LawyerDetailLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo do Perfil',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.enrichedLawyer.bio ?? 'Informações detalhadas sobre o perfil profissional do advogado.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Especialidades',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.enrichedLawyer.especialidades.map((spec) => 
                      Chip(label: Text(spec))
                    ).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qualidade dos Dados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: state.enrichedLawyer.overallQualityScore,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.enrichedLawyer.overallQualityScore >= 0.8 
                          ? Colors.green 
                          : state.enrichedLawyer.overallQualityScore >= 0.6 
                              ? Colors.orange 
                              : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(state.enrichedLawyer.overallQualityScore * 100).toInt()}% de completude',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedInTab(LawyerDetailLoaded state) {
    if (state.enrichedLawyer.linkedinProfile != null) {
      return LinkedInProfileView(profile: state.enrichedLawyer.linkedinProfile!);
    }
    return _buildNoDataView('LinkedIn não conectado');
  }

  Widget _buildAcademicTab(LawyerDetailLoaded state) {
    if (state.enrichedLawyer.academicProfile != null) {
      return AcademicProfileView(profile: state.enrichedLawyer.academicProfile!);
    }
    return _buildNoDataView('Dados acadêmicos não disponíveis');
  }

  Widget _buildCurriculumTab() {
    return CurriculumView(lawyerId: widget.lawyerId);
  }

  Widget _buildTransparencyTab(LawyerDetailLoaded state) {
    return DataTransparencyView(
      dataSources: state.enrichedLawyer.dataSources,
      qualityScore: state.enrichedLawyer.overallQualityScore,
      lastUpdated: state.enrichedLawyer.lastConsolidated,
    );
  }

  Widget _buildNoDataView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.database,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Estes dados serão disponibilizados assim que a integração for concluída.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 