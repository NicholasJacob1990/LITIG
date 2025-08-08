import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../bloc/firm_profile_bloc.dart';
import '../bloc/firm_profile_event.dart';
import '../bloc/firm_profile_state.dart';
import '../widgets/firm_team_view.dart';
import '../widgets/firm_data_transparency_view.dart';

class FirmProfileScreen extends StatefulWidget {
  final String firmId;

  const FirmProfileScreen({super.key, required this.firmId});

  @override
  State<FirmProfileScreen> createState() => _FirmProfileScreenState();
}

class _FirmProfileScreenState extends State<FirmProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FirmProfileBloc>().add(LoadFirmProfile(widget.firmId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<FirmProfileBloc, FirmProfileState>(
        builder: (context, state) {
          if (state is FirmProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FirmProfileError) {
            return _buildErrorState(context, state);
          }
          if (state is FirmProfileLoaded) {
            return _buildLoadedContent(context, state);
          }
          return const Center(child: Text("Estado inicial"));
        },
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildErrorState(BuildContext context, FirmProfileError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertTriangle,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar perfil',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<FirmProfileBloc>().add(LoadFirmProfile(widget.firmId));
              },
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, FirmProfileLoaded state) {
    final firm = state.enrichedFirm;
    return CustomScrollView(
      slivers: [
        _buildAppBar(context, firm.name),
        SliverToBoxAdapter(
          child: DefaultTabController(
            length: 6,
            child: Column(
              children: [
                _buildProfileHeader(state),
                _buildTabBar(),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: TabBarView(
                    children: [
                      _buildOverviewTab(state),
                      _buildTeamTab(state),
                      _buildCasesTab(state),
                      _buildPartnershipsTab(state),
                      _buildFinancialsTab(state),
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

  Widget _buildAppBar(BuildContext context, String firmName) {
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
          onPressed: () => _shareFirmProfile(context),
        ),
        IconButton(
          icon: const Icon(LucideIcons.bookmark),
          onPressed: () => _saveToFavorites(context),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag_outlined),
                  SizedBox(width: 8),
                  Text('Reportar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'contact',
              child: Row(
                children: [
                  Icon(Icons.contact_mail),
                  SizedBox(width: 8),
                  Text('Contato Direto'),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          firmName,
          style: const TextStyle(fontSize: 16),
        ),
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

  Widget _buildProfileHeader(FirmProfileLoaded state) {
    final firm = state.enrichedFirm;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildFirmLogo(firm),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFirmInfo(firm),
              ),
              _buildQualityIndicator(firm.overallQualityScore),
            ],
          ),
          const SizedBox(height: 16),
          _buildFirmMetrics(firm),
        ],
      ),
    );
  }

  Widget _buildFirmLogo(firm) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: (firm.logoUrl != null && firm.logoUrl!.isNotEmpty)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                firm.logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultLogo(),
              ),
            )
          : _buildDefaultLogo(),
    );
  }

  Widget _buildDefaultLogo() {
    return Icon(
      LucideIcons.building2,
      size: 40,
      color: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildFirmInfo(firm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          firm.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${firm.totalLawyers} advogados • ${firm.specializations.length} especializações',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        if (firm.location != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(LucideIcons.mapPin, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${firm.location!.city}, ${firm.location!.state}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildQualityIndicator(double qualityScore) {
    final percentage = (qualityScore * 100).toInt();
    final color = _getQualityColor(qualityScore);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.checkCircle,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirmMetrics(firm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetricItem(
          'Taxa de Sucesso',
          '${(firm.stats.successRate * 100).toInt()}%',
          LucideIcons.trendingUp,
          Colors.green,
        ),
        _buildMetricItem(
          'Casos Ativos',
          '${firm.stats.activeCases}',
          LucideIcons.briefcase,
          Colors.blue,
        ),
        _buildMetricItem(
          'Avaliação',
          '${firm.stats.averageRating.toStringAsFixed(1)}',
          LucideIcons.star,
          Colors.amber,
        ),
        _buildMetricItem(
          'Anos de Mercado',
          firm.financialInfo?.foundedYear != null 
            ? '${DateTime.now().year - firm.financialInfo!.foundedYear!}' 
            : 'N/A',
          LucideIcons.calendar,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: const TabBar(
        isScrollable: true,
        tabs: [
          Tab(icon: Icon(LucideIcons.building), text: 'Visão Geral'),
          Tab(icon: Icon(LucideIcons.users), text: 'Equipe'),
          Tab(icon: Icon(LucideIcons.briefcase), text: 'Casos'),
          Tab(icon: Icon(LucideIcons.users), text: 'Parcerias'),
          Tab(icon: Icon(LucideIcons.dollarSign), text: 'Financeiro'),
          Tab(icon: Icon(LucideIcons.shield), text: 'Transparência'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(FirmProfileLoaded state) {
    return _buildPlaceholderTab('Visão Geral do Escritório');
  }

  Widget _buildTeamTab(FirmProfileLoaded state) {
    return FirmTeamView(
      firmId: widget.firmId,
      enrichedFirm: state.enrichedFirm,
    );
  }

  Widget _buildCasesTab(FirmProfileLoaded state) {
    return _buildPlaceholderTab('Histórico de Casos');
  }

  Widget _buildPartnershipsTab(FirmProfileLoaded state) {
    return _buildPlaceholderTab('Parcerias do Escritório');
  }

  Widget _buildFinancialsTab(FirmProfileLoaded state) {
    return _buildPlaceholderTab('Informações Financeiras');
  }

  Widget _buildTransparencyTab(FirmProfileLoaded state) {
    return FirmDataTransparencyView(
      dataSources: state.enrichedFirm.dataSources,
      qualityScore: state.enrichedFirm.overallQualityScore,
      lastUpdated: state.enrichedFirm.lastConsolidated,
      firmId: widget.firmId,
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.construction,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Esta seção será implementada em breve.',
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

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showHiringOptions(context),
      icon: const Icon(LucideIcons.users),
      label: const Text('Contratar Escritório'),
    );
  }

  Color _getQualityColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  void _shareFirmProfile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil compartilhado com sucesso!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveToFavorites(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Escritório salvo nos favoritos!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'report':
        _reportFirm(context);
        break;
      case 'contact':
        _contactFirm(context);
        break;
    }
  }

  void _reportFirm(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reportar escritório - funcionalidade em desenvolvimento'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _contactFirm(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contato direto - funcionalidade em desenvolvimento'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showHiringOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Opções de Contratação',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(LucideIcons.building),
              title: const Text('Contratar Escritório'),
              subtitle: const Text('Contratar o escritório completo'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar contratação do escritório
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.user),
              title: const Text('Contratar Advogado Específico'),
              subtitle: const Text('Escolher um advogado da equipe'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Mostrar lista de advogados do escritório
              },
            ),
          ],
        ),
      ),
    );
  }
} 