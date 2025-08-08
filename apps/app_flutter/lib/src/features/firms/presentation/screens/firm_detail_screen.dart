import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lawyer.dart';
import '../bloc/firm_detail_bloc.dart';
import '../widgets/firm_card.dart';
import '../widgets/firm_card_helpers.dart';
import '../../domain/entities/law_firm.dart';
import '../../domain/entities/firm_kpi.dart';
import '../../domain/usecases/get_firm_lawyers.dart';
import '../../../lawyers/presentation/widgets/lawyer_social_links.dart';

/// Tela para exibir detalhes completos de um escritório de advocacia
/// 
/// Esta tela apresenta informações detalhadas sobre um escritório,
/// incluindo seus KPIs, advogados associados e outras métricas relevantes.
class FirmDetailScreen extends StatefulWidget {
  final String firmId;

  const FirmDetailScreen({
    super.key,
    required this.firmId,
  });

  @override
  State<FirmDetailScreen> createState() => _FirmDetailScreenState();
}

class _FirmDetailScreenState extends State<FirmDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Carregar dados do escritório
    context.read<FirmDetailBloc>().add(
      GetFirmDetailEvent(firmId: widget.firmId),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<FirmDetailBloc, FirmDetailState>(
        builder: (context, state) {
          if (state is FirmDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FirmDetailError) {
            return _buildErrorState(state.message);
          }

          if (state is FirmDetailLoaded) {
            return _buildLoadedState(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar escritório',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<FirmDetailBloc>().add(
                RefreshFirmDetailEvent(firmId: widget.firmId),
              );
            },
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(FirmDetailLoaded state) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          _buildAppBar(state.firm),
          _buildFirmHeader(state.firm, state.kpis),
        ];
      },
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(state),
                _buildLawyersTab(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(LawFirm firm) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          firm.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<FirmDetailBloc>().add(
              RefreshFirmDetailEvent(firmId: widget.firmId),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFirmHeader(LawFirm firm, FirmKPI? kpis) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: FirmCard(
          firm: firm,
          // kpis: kpis, // Removido, pois FirmCard agora usa firm.kpis
          showKpis: true,
          isCompact: false,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.info_outline),
            text: 'Visão Geral',
          ),
          Tab(
            icon: Icon(Icons.people),
            text: 'Advogados',
          ),
        ],
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
        indicatorColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildOverviewTab(FirmDetailLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(state.firm),
          const SizedBox(height: 24),
          if (state.kpis != null) ...[
            _buildKpisSection(state.kpis!),
            const SizedBox(height: 24),
          ],
          _buildActionsSection(state.firm),
        ],
      ),
    );
  }

  Widget _buildInfoSection(LawFirm firm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Gerais',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('ID', firm.id),
            _buildInfoRow('Tamanho da Equipe', '${firm.teamSize} advogados'),
            if (firm.hasLocation) ...[
              _buildInfoRow(
                  'Localização',
                  'Lat: ${firm.mainLat!.toStringAsFixed(6)}, Lon: ${firm.mainLon!.toStringAsFixed(6)}'),
            ],
            if (firm.createdAt != null)
              _buildInfoRow('Criado em', formatDateTime(firm.createdAt!)),
            if (firm.updatedAt != null)
              _buildInfoRow('Atualizado em', formatDateTime(firm.updatedAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpisSection(FirmKPI kpis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indicadores de Performance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    'Taxa de Sucesso',
                    '${(kpis.successRate * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    'NPS',
                    kpis.nps.toStringAsFixed(0),
                    Icons.star,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    'Reputação',
                    '${(kpis.reputationScore * 100).toStringAsFixed(0)}%',
                    Icons.thumb_up,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    'Diversidade',
                    '${(kpis.diversityIndex * 100).toStringAsFixed(0)}%',
                    Icons.diversity_3,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: _buildKpiCard(
                'Casos Ativos',
                kpis.activeCases.toString(),
                Icons.folder,
                Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(LawFirm firm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ações',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Implementar contato com escritório
                    },
                    icon: const Icon(Icons.contact_phone),
                    label: const Text('Entrar em Contato'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Implementar favoritar escritório
                    },
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('Favoritar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLawyersTab(FirmDetailLoaded state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Advogados do Escritório',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<FirmDetailBloc>().add(
                    GetFirmLawyersEvent(
                      firmId: widget.firmId,
                      params: GetFirmLawyersParams(firmId: widget.firmId),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Carregar'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildLawyersList(state),
        ),
      ],
    );
  }

  Widget _buildLawyersList(FirmDetailLoaded state) {
    if (state.isLoadingLawyers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.lawyers == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum advogado carregado',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Toque em "Carregar" para ver os advogados',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final lawyers = state.lawyers!;

    if (lawyers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum advogado encontrado',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: lawyers.length,
      itemBuilder: (context, index) {
        final lawyer = lawyers[index];
        return _buildLawyerCard(lawyer);
      },
    );
  }

  Widget _buildLawyerCard(Lawyer lawyer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: (lawyer.avatarUrl != null && lawyer.avatarUrl!.isNotEmpty)
              ? NetworkImage(lawyer.avatarUrl!)
              : null,
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: (lawyer.avatarUrl == null || lawyer.avatarUrl!.isEmpty)
              ? Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                )
              : null,
        ),
        title: Text(
          lawyer.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lawyer.email != null) Text(lawyer.email!),
            if (lawyer.specialization != null)
              Row(
                children: [
                  Text(
                    lawyer.specialization!,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  // Ícones das redes sociais
                  LawyerSocialLinks(
                    linkedinUrl: 'https://linkedin.com/in/${lawyer.name.toLowerCase().replaceAll(' ', '-')}',
                    instagramUrl: 'https://instagram.com/${lawyer.name.toLowerCase().replaceAll(' ', '')}',
                    facebookUrl: 'https://facebook.com/${lawyer.name.toLowerCase().replaceAll(' ', '.')}',
                  ),
                ],
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () {
            // Implementar navegação para perfil do advogado
          },
        ),
      ),
    );
  }
} 
