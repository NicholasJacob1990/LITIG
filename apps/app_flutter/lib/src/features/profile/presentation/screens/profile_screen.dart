import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:meu_app/src/features/dashboard/presentation/bloc/lawyer_firm_bloc.dart';
import '../../../../../injection_container.dart';

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
                context.go('/profile/settings');
              },
            ),
          ],
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) {
              final user = state.user;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Área do perfil centralizada
                    Center(
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
                    ),
                    const SizedBox(height: 32),
                    
                    // Seção de Escritório (apenas para advogados)
                    if (user.role == 'lawyer' || user.role == 'associate_lawyer')
                      const _LawyerFirmSection(),
                    
                    const SizedBox(height: 32),
                    
                    // Botão de editar perfil
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.go('/profile/edit');
                        },
                        icon: const Icon(LucideIcons.edit),
                        label: const Text('Editar Perfil'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
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

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'partner':
        return 'Sócio';
      case 'associate':
        return 'Associado';
      case 'junior':
        return 'Júnior';
      case 'senior':
        return 'Sênior';
      default:
        return role;
    }
  }
} 