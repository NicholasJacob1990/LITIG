import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:meu_app/src/features/dashboard/presentation/bloc/lawyer_firm_bloc.dart';
import 'package:meu_app/injection_container.dart';
import 'package:meu_app/src/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:meu_app/src/features/profile/presentation/bloc/profile_state.dart';
import 'package:meu_app/src/features/profile/presentation/bloc/profile_event.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<LawyerFirmBloc>()..add(const LoadLawyerFirmInfo()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Perfil'),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.settings),
              onPressed: () {
                // Detecta o contexto atual e navega adequadamente
                final currentLocation = GoRouterState.of(context).uri.toString();
                if (currentLocation.contains('/contractor-profile')) {
                  context.go('/contractor-profile/settings');
                } else if (currentLocation.contains('/client-profile')) {
                  context.go('/client-profile/settings');
                } else if (currentLocation.contains('/profile')) {
                  context.go('/profile/settings');
                } else {
                  // Fallback para rota independente
                  context.go('/profile-details/settings');
                }
              },
            ),
          ],
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is Authenticated) {
              final user = authState.user;
              return BlocProvider(
                create: (context) => getIt<ProfileBloc>()..add(LoadProfile(user.id)),
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, profileState) {
                    if (profileState is ProfileLoaded) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Área do perfil centralizada
                            _buildProfileHeader(context, user, profileState.socialProfiles),
                            const SizedBox(height: 32),
                            
                            // Menu Completo do Perfil
                            _buildProfileMenu(context, user),
                            
                            const SizedBox(height: 24),
                            
                            // Dashboard Contextual Resumido
                            if (user.role == 'lawyer' || user.role == 'lawyer_associated' || user.role == 'lawyer_office')
                              _buildContextualDashboard(context, user),
                            
                            // Seção de Escritório
                            if (user.role == 'lawyer' || user.role == 'associate_lawyer') ...[
                              const SizedBox(height: 24),
                              const _LawyerFirmSection(),
                            ],
                            
                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user, Map<String, dynamic>? socialProfiles) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            child: user.fullName != null && user.fullName!.isNotEmpty
                ? Text(user.fullName!.substring(0, 2).toUpperCase(), style: const TextStyle(fontSize: 40))
                : const Icon(LucideIcons.user, size: 40),
          ),
          const SizedBox(height: 20),
          Text(user.fullName ?? 'Usuário', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(user.email ?? 'E-mail não informado', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          if (socialProfiles != null && socialProfiles.isNotEmpty)
            _buildSocialBadges(context, socialProfiles),
          const SizedBox(height: 8),
          if (user.role != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getRoleDisplayName(user.role!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialBadges(BuildContext context, Map<String, dynamic> socialProfiles) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: socialProfiles.entries.map((entry) {
        final provider = entry.key;
        final data = entry.value;
        IconData icon;
        Color color;

        switch (provider) {
          case 'instagram':
            icon = LucideIcons.instagram;
            color = const Color(0xFFE4405F);
            break;
          case 'linkedin':
            icon = LucideIcons.linkedin;
            color = const Color(0xFF0077B5);
            break;
          default:
            icon = LucideIcons.share2;
            color = Colors.grey;
        }

        return Chip(
          avatar: Icon(icon, color: color, size: 16),
          label: Text(
            '${data['followers'] ?? 0} seguidores',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          backgroundColor: color.withValues(alpha: 0.1),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        );
      }).toList(),
    );
  }

  Widget _buildContextualDashboard(BuildContext context, dynamic user) {
    return Column(
      children: [
        // Métricas resumidas
        _buildPersonalMetricsSection(context, user),
        const SizedBox(height: 16),
        
        // Dashboard contextual expandido baseado no tipo de usuário
        _buildExpandedDashboardByUserType(context, user.role),
      ],
    );
  }

  /// **Menu Completo do Perfil - Baseado no PLANO_ACAO_PERFIL_CLIENTE.md**
  Widget _buildProfileMenu(BuildContext context, dynamic user) {
    final isClient = user.role == 'client' || user.role == 'PF';
    final isLawyer = user.role?.contains('lawyer') == true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header do Menu
        Row(
          children: [
            const Icon(LucideIcons.user, size: 20),
            const SizedBox(width: 8),
            Text(
              isClient ? 'Perfil do Cliente' : 'Perfil Profissional',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Dashboard Pessoal
        _buildProfileMenuCard(
          context,
          icon: LucideIcons.barChart3,
          title: 'Dashboard',
          subtitle: 'Métricas e indicadores pessoais',
          color: Colors.blue,
          onTap: () => _showComingSoon(context, 'Dashboard Pessoal'),
        ),
        
        // Dados Pessoais
        _buildProfileMenuCard(
          context,
          icon: LucideIcons.fileText,
          title: 'Dados Pessoais',
          subtitle: isClient ? 'Informações básicas e documentos' : 'Informações profissionais',
          color: Colors.green,
          onTap: () => context.push('/profile/personal-data'),
        ),
        
        // Documentos
        _buildProfileMenuCard(
          context,
          icon: LucideIcons.folder,
          title: 'Documentos',
          subtitle: isClient ? 'Upload e gestão de documentos' : 'Certificações e comprovantes',
          color: Colors.orange,
          onTap: () => context.push('/profile/documents'),
        ),
        
        // Comunicação
        _buildProfileMenuCard(
          context,
          icon: LucideIcons.messageCircle,
          title: 'Comunicação',
          subtitle: 'Preferências de contato e notificações',
          color: Colors.purple,
          onTap: () => context.push('/profile-details/communication-preferences'),
        ),
        
        // Conexões Sociais (ITEM ADICIONADO)
        _buildProfileMenuCard(
          context,
          icon: LucideIcons.share2,
          title: 'Conexões Sociais',
          subtitle: 'Conecte seu LinkedIn, Instagram e mais',
          color: Colors.cyan,
          onTap: () => context.push('/profile-details/social-connections'),
        ),
        
        // Planos e Assinaturas (NOVO)
        _buildProfileMenuCard(
          context,
          icon: LucideIcons.crown,
          title: _getPlanMenuTitle(user.role),
          subtitle: _getPlanMenuSubtitle(user.role),
          color: _getPlanMenuColor(user.role),
          onTap: () => context.push('/billing/plans'),
        ),
        
        // Financeiro (principalmente para clientes, mas útil para advogados também)
        if (isClient || isLawyer)
          _buildProfileMenuCard(
            context,
            icon: LucideIcons.dollarSign,
            title: isClient ? 'Dashboard Financeiro' : 'Controle Financeiro',
            subtitle: isClient ? 'Contratos e pagamentos' : 'Faturamento e recebimentos',
            color: Colors.teal,
            onTap: () => context.push('/financial'),
          ),
        
        // Contratos (principalmente para clientes)
        if (isClient)
          _buildProfileMenuCard(
            context,
            icon: LucideIcons.fileCheck,
            title: 'Contratos e Serviços',
            subtitle: 'Contratos vigentes e histórico',
            color: Colors.indigo,
            onTap: () => context.push('/contracts'),
          ),
        
        // Privacidade e Segurança
        _buildProfileMenuCard(
          context,
          icon: LucideIcons.shield,
          title: 'Privacidade e Segurança',
          subtitle: 'Configurações LGPD e controle de acesso',
          color: Colors.red,
          onTap: () => context.push('/profile/privacy-settings'),
        ),
        
        // Configurações Gerais
        _buildProfileMenuCard(
          context,
          icon: LucideIcons.settings,
          title: 'Configurações',
          subtitle: 'Aparência, idioma e preferências gerais',
          color: Colors.grey,
          onTap: () => context.push('/profile/settings'),
        ),
        
        // Editar Perfil (ação rápida)
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(LucideIcons.edit),
            label: const Text('Editar Perfil Básico'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildProfileMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: onTap,
      ),
    );
  }
  
  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Em breve!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildPersonalMetricsSection(BuildContext context, dynamic user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.barChart3, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Suas Métricas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricsForUserType(context, user.role),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedDashboardByUserType(BuildContext context, String? role) {
    // Dashboard contextual completo baseado no tipo de usuário
    switch (role) {
      case 'lawyer_individual':
        return _buildIndividualLawyerDashboard(context);
      case 'lawyer_platform_associate':
        return _buildSuperAssociateDashboard(context);
      case 'lawyer_office':
        return _buildFirmOwnerDashboard(context);
      case 'lawyer_associated':
        return _buildAssociatedLawyerDashboard(context);
      case 'client':
      case 'PF':
        return _buildClientDashboard(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIndividualLawyerDashboard(BuildContext context) {
    // Dashboard para advogados autônomos - foco em captação
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.briefcase, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Seu Negócio Jurídico',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Oportunidades em andamento
            _buildSectionItem(
              context,
              'Oportunidades Ativas',
              '5 em negociação',
              LucideIcons.target,
              Colors.orange,
            ),
            _buildSectionItem(
              context,
              'Parcerias',
              '3 advogados parceiros',
              LucideIcons.users,
              Colors.blue,
            ),
            _buildSectionItem(
              context,
              'Pipeline Mensal',
              'R\$ 45.000 em propostas',
              LucideIcons.dollarSign,
              Colors.green,
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/contractor-home'),
                icon: const Icon(LucideIcons.externalLink),
                label: const Text('Ver Dashboard Completo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuperAssociateDashboard(BuildContext context) {
    // Dashboard para super associados - foco em captação e parcerias
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.crown, size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Super Associado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSectionItem(
              context,
              'Captação Mensal',
              '12 novos leads qualificados',
              LucideIcons.userPlus,
              Colors.green,
            ),
            _buildSectionItem(
              context,
              'Parcerias Ativas',
              '8 escritórios parceiros',
              LucideIcons.building,
              Colors.blue,
            ),
            _buildSectionItem(
              context,
              'Comissões',
              'R\$ 28.500 este mês',
              LucideIcons.piggyBank,
              Colors.purple,
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/contractor-home'),
                icon: const Icon(LucideIcons.externalLink),
                label: const Text('Dashboard de Captação'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirmOwnerDashboard(BuildContext context) {
    // Dashboard para sócios de escritório - foco na gestão da equipe
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.building2, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Gestão do Escritório',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSectionItem(
              context,
              'Equipe',
              '8 advogados • 92% produtividade',
              LucideIcons.users,
              Colors.blue,
            ),
            _buildSectionItem(
              context,
              'Faturamento',
              'R\$ 145.000 este mês (+9.8%)',
              LucideIcons.trendingUp,
              Colors.green,
            ),
            _buildSectionItem(
              context,
              'Casos Ativos',
              '24 casos em andamento',
              LucideIcons.briefcase,
              Colors.orange,
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/firm-dashboard'),
                icon: const Icon(LucideIcons.externalLink),
                label: const Text('Dashboard da Firma'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssociatedLawyerDashboard(BuildContext context) {
    // Dashboard para advogados associados - foco na produtividade
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.userCheck, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Sua Produtividade',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSectionItem(
              context,
              'Casos Delegados',
              '5 casos ativos • 3 pendentes',
              LucideIcons.briefcase,
              Colors.blue,
            ),
            _buildSectionItem(
              context,
              'Eficiência',
              '92% taxa de entrega no prazo',
              LucideIcons.clock,
              Colors.green,
            ),
            _buildSectionItem(
              context,
              'Horas Trabalhadas',
              '156h este mês • Meta: 160h',
              LucideIcons.timer,
              Colors.orange,
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/dashboard'),
                icon: const Icon(LucideIcons.externalLink),
                label: const Text('Dashboard Completo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientDashboard(BuildContext context) {
    // Dashboard para clientes - foco nos casos e advogados
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.user, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Seus Casos Jurídicos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSectionItem(
              context,
              'Casos em Andamento',
              '3 casos ativos • 1 audiência próxima',
              LucideIcons.briefcase,
              Colors.blue,
            ),
            _buildSectionItem(
              context,
              'Advogados Contratados',
              '2 advogados • ⭐ 4.7 média',
              LucideIcons.userCheck,
              Colors.green,
            ),
            _buildSectionItem(
              context,
              'Mensagens',
              '5 mensagens não lidas',
              LucideIcons.messageCircle,
              Colors.orange,
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/client-home'),
                icon: const Icon(LucideIcons.externalLink),
                label: const Text('Dashboard Completo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsForUserType(BuildContext context, String? role) {
    // TODO: Implementar chamadas reais da API baseadas no tipo de usuário
    switch (role) {
      case 'lawyer':
      case 'lawyer_individual':
      case 'lawyer_office':
      case 'lawyer_platform_associate':
        return _buildLawyerMetrics(context);
      case 'lawyer_associated':
        return _buildAssociatedLawyerMetrics(context);
      case 'client':
      case 'PF':
        return _buildClientMetrics(context);
      default:
        return _buildDefaultMetrics(context);
    }
  }

  Widget _buildLawyerMetrics(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricItem(context, 'Casos Ativos', '8', LucideIcons.briefcase)),
            Expanded(child: _buildMetricItem(context, 'Taxa Sucesso', '87%', LucideIcons.trendingUp)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricItem(context, 'Avaliação', '4.7⭐', LucideIcons.star)),
            Expanded(child: _buildMetricItem(context, 'Este Mês', 'R\$ 25K', LucideIcons.dollarSign)),
          ],
        ),
      ],
    );
  }

  Widget _buildAssociatedLawyerMetrics(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricItem(context, 'Casos Ativos', '5', LucideIcons.briefcase)),
            Expanded(child: _buildMetricItem(context, 'Produtividade', '92%', LucideIcons.trendingUp)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricItem(context, 'Horas Mês', '156h', LucideIcons.clock)),
            Expanded(child: _buildMetricItem(context, 'Avaliação', '4.5⭐', LucideIcons.star)),
          ],
        ),
      ],
    );
  }

  Widget _buildClientMetrics(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricItem(context, 'Casos Ativos', '3', LucideIcons.briefcase)),
            Expanded(child: _buildMetricItem(context, 'Advogados', '2', LucideIcons.userCheck)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricItem(context, 'Audiências', '1', LucideIcons.calendar)),
            Expanded(child: _buildMetricItem(context, 'Mensagens', '5', LucideIcons.messageCircle)),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultMetrics(BuildContext context) {
    return Text(
      'Métricas não disponíveis para este tipo de usuário',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'lawyer':
        return 'Advogado de Captação';
      case 'associate_lawyer':
        return 'Advogado Associado';
      case 'client':
        return 'Cliente';
      default:
        return role;
    }
  }

  String _getPlanMenuTitle(String? role) {
    if (role?.contains('lawyer') == true) {
      return 'Planos Profissionais';
    } else if (role?.contains('firm') == true || role?.contains('office') == true) {
      return 'Planos Corporativos';
    } else {
      return 'Planos e Assinaturas';
    }
  }

  String _getPlanMenuSubtitle(String? role) {
    if (role?.contains('lawyer') == true) {
      return 'Upgrade para PRO e acesse casos premium';
    } else if (role?.contains('firm') == true || role?.contains('office') == true) {
      return 'Planos Partner e Premium para escritórios';
    } else {
      return 'Planos VIP e Enterprise disponíveis';
    }
  }

  Color _getPlanMenuColor(String? role) {
    if (role?.contains('lawyer') == true) {
      return Colors.green;
    } else if (role?.contains('firm') == true || role?.contains('office') == true) {
      return Colors.purple;
    } else {
      return Colors.amber;
    }
  }
}

class _LawyerFirmSection extends StatelessWidget {
  const _LawyerFirmSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LawyerFirmBloc, LawyerFirmState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.building2, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Escritório',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (state is LawyerFirmLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state is LawyerFirmLoaded)
                  _buildFirmInfo(context, state)
                else if (state is LawyerFirmNotAssociated)
                  _buildNotLinkedInfo(context)
                else if (state is LawyerFirmError)
                  _buildErrorInfo(context, state.message)
                else
                  _buildInitialInfo(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFirmInfo(BuildContext context, LawyerFirmLoaded state) {
    final firm = state.firm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          firm.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            const Icon(LucideIcons.userCheck, size: 16),
            const SizedBox(width: 4),
            Text(
              'Função: Advogado Associado',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        Row(
          children: [
            const Icon(LucideIcons.users, size: 16),
            const SizedBox(width: 4),
            Text(
              'Equipe: ${firm.teamSize} advogados',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        
        if (firm.kpis != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.trendingUp, size: 16),
              const SizedBox(width: 4),
              Text(
                'Taxa de Sucesso: ${(firm.kpis!.successRate * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
        
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.push('/firm/${firm.id}');
            },
            icon: const Icon(LucideIcons.eye),
            label: const Text('Ver Detalhes do Escritório'),
          ),
        ),
      ],
    );
  }

  Widget _buildNotLinkedInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advogado Independente',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Você não está vinculado a nenhum escritório.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navegar para busca de parcerias
                  // context.go('/partnerships');
                },
                icon: const Icon(LucideIcons.users),
                label: const Text('Buscar Parcerias'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navegar para criação de escritório
                  // context.go('/firm/create');
                },
                icon: const Icon(LucideIcons.plus),
                label: const Text('Criar Escritório'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorInfo(BuildContext context, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.alertCircle,
              color: Theme.of(context).colorScheme.error,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Erro ao carregar informações',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<LawyerFirmBloc>().add(const RefreshLawyerFirmInfo());
            },
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Tentar Novamente'),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Carregando informações...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<LawyerFirmBloc>().add(const LoadLawyerFirmInfo());
            },
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Carregar Informações'),
          ),
        ),
      ],
    );
  }
} 