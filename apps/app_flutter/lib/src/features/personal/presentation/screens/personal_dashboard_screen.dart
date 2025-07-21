import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/utils/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Tela principal da Área Pessoal para Super Associados
/// 
/// Implementa o conceito da Solução 3:
/// - Área completamente separada da navegação principal
/// - Super associado atua como pessoa física contratando serviços
/// - Interface verde para diferenciação visual
/// - 4 abas específicas: Painel, Buscar, Casos, Mensagens
class PersonalDashboardScreen extends StatefulWidget {
  const PersonalDashboardScreen({super.key});

  @override
  State<PersonalDashboardScreen> createState() => _PersonalDashboardScreenState();
}

class _PersonalDashboardScreenState extends State<PersonalDashboardScreen> 
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated || !authState.user.isPlatformAssociate) {
          return const Scaffold(
            body: Center(
              child: Text('Acesso negado. Área exclusiva para Super Associados.'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: _buildPersonalAppBar(context, authState.user.fullName ?? 'Usuário'),
          body: TabBarView(
            controller: _tabController,
            children: [
              _PersonalDashboardTab(userName: authState.user.fullName ?? 'Usuário'),
              const _FindLawyersTab(),
              const _PersonalCasesTab(),
              const _PersonalMessagesTab(),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildPersonalAppBar(BuildContext context, String userName) {
    return AppBar(
      backgroundColor: AppColors.success,
      foregroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Voltar ao Centro de Trabalho',
      ),
      title: Row(
        children: [
          const Icon(LucideIcons.user, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Área Pessoal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Pessoa Física',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.helpCircle),
          onPressed: () => _showPersonalAreaHelp(context),
          tooltip: 'Ajuda da Área Pessoal',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        tabs: const [
          Tab(
            icon: Icon(LucideIcons.home, size: 20),
            text: 'Painel',
          ),
          Tab(
            icon: Icon(LucideIcons.search, size: 20),
            text: 'Buscar',
          ),
          Tab(
            icon: Icon(LucideIcons.folder, size: 20),
            text: 'Casos',
          ),
          Tab(
            icon: Icon(LucideIcons.messageCircle, size: 20),
            text: 'Mensagens',
          ),
        ],
      ),
    );
  }

  void _showPersonalAreaHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.info, color: AppColors.success),
            SizedBox(width: 8),
            Text('Área Pessoal'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta é sua área privada onde você atua como pessoa física contratando advogados para seus casos pessoais.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '🔹 Completamente separada do trabalho LITIG-1\n'
              '🔹 Seus dados pessoais ficam privados\n'
              '🔹 Contrate advogados para casos próprios\n'
              '🔹 Gerencie contratos e pagamentos pessoais',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}

/// Tab principal do painel pessoal
class _PersonalDashboardTab extends StatelessWidget {
  final String userName;

  const _PersonalDashboardTab({required this.userName});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          _buildPersonalStatsSection(),
          const SizedBox(height: 24),
          _buildQuickActionsSection(context),
          const SizedBox(height: 24),
          _buildRecentActivitySection(),
          const SizedBox(height: 24),
          _buildFinancialSummarySection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success,
            AppColors.success.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.user,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $userName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Sua área pessoal como pessoa física',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.shield, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seus dados pessoais são completamente privados e separados do trabalho LITIG-1',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meus Casos Pessoais',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: LucideIcons.folder,
                title: 'Casos Ativos',
                value: '2',
                color: AppColors.success,
                subtitle: 'Em andamento',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: LucideIcons.clock,
                title: 'Aguardando',
                value: '1',
                color: AppColors.warning,
                subtitle: 'Resposta do advogado',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: LucideIcons.checkCircle,
                title: 'Finalizados',
                value: '3',
                color: AppColors.primaryBlue,
                subtitle: 'Último ano',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ações Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: LucideIcons.plus,
                title: 'Novo Caso',
                subtitle: 'Criar caso pessoal',
                color: AppColors.success,
                onTap: () => _createPersonalCase(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: LucideIcons.search,
                title: 'Buscar Advogado',
                subtitle: 'Para meus casos',
                color: AppColors.primaryBlue,
                onTap: () => _searchLawyers(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: LucideIcons.fileText,
                title: 'Contratos',
                subtitle: 'Ver contratos',
                color: AppColors.warning,
                onTap: () => _viewContracts(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Atividade Recente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Ver tudo'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          icon: LucideIcons.messageSquare,
          title: 'Nova mensagem do Dr. Silva',
          subtitle: 'Caso: Revisão de aposentadoria',
          time: '2h atrás',
          color: AppColors.primaryBlue,
        ),
        const SizedBox(height: 8),
        _buildActivityItem(
          icon: LucideIcons.fileText,
          title: 'Documento anexado',
          subtitle: 'Petição inicial - Caso trabalhista',
          time: '1 dia atrás',
          color: AppColors.success,
        ),
        const SizedBox(height: 8),
        _buildActivityItem(
          icon: LucideIcons.dollarSign,
          title: 'Pagamento processado',
          subtitle: 'Honorários Dr. Santos - R\$ 2.500',
          time: '3 dias atrás',
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummarySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.dollarSign, color: AppColors.success),
              SizedBox(width: 8),
              Text(
                'Resumo Financeiro',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFinancialMetric(
                  title: 'Valores em Disputa',
                  value: 'R\$ 45.000',
                  subtitle: '3 casos ativos',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFinancialMetric(
                  title: 'Honorários Pagos',
                  value: 'R\$ 12.000',
                  subtitle: 'Último ano',
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetric({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  void _createPersonalCase(BuildContext context) {
    // Navegar para criação de caso pessoal
    Navigator.of(context).pushNamed('/personal/create-case');
  }

  void _searchLawyers(BuildContext context) {
    // Navegar para busca de advogados na área pessoal
    Navigator.of(context).pushNamed('/personal/search-lawyers');
  }

  void _viewContracts(BuildContext context) {
    // Navegar para contratos pessoais
    Navigator.of(context).pushNamed('/personal/contracts');
  }
}

/// Tab de busca de advogados na área pessoal
class _FindLawyersTab extends StatelessWidget {
  const _FindLawyersTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.search, size: 64, color: AppColors.success),
          SizedBox(height: 16),
          Text(
            'Buscar Advogados',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Encontre advogados para seus casos pessoais',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Tab de casos pessoais
class _PersonalCasesTab extends StatelessWidget {
  const _PersonalCasesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.folder, size: 64, color: AppColors.success),
          SizedBox(height: 16),
          Text(
            'Meus Casos Pessoais',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Onde você é o cliente contratando advogados',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Tab de mensagens pessoais
class _PersonalMessagesTab extends StatelessWidget {
  const _PersonalMessagesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.messageCircle, size: 64, color: AppColors.success),
          SizedBox(height: 16),
          Text(
            'Mensagens Pessoais',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Conversas com advogados dos seus casos pessoais',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
} 