import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/lawyer_hiring_bloc.dart';
import '../widgets/hiring_proposal_card.dart';
import '../../domain/entities/hiring_proposal.dart';
import '../../../../../injection_container.dart';

class HiringProposalsScreen extends StatefulWidget {
  const HiringProposalsScreen({super.key});

  @override
  State<HiringProposalsScreen> createState() => _HiringProposalsScreenState();
}

class _HiringProposalsScreenState extends State<HiringProposalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<LawyerHiringBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Propostas de Contratação'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
            indicatorColor: Theme.of(context).colorScheme.onPrimary,
            tabs: const [
              Tab(
                icon: Icon(Icons.pending_actions),
                text: 'Pendentes',
              ),
              Tab(
                icon: Icon(Icons.check_circle),
                text: 'Aceitas',
              ),
              Tab(
                icon: Icon(Icons.history),
                text: 'Histórico',
              ),
            ],
          ),
        ),
        body: const HiringProposalsScreenContent(),
      ),
    );
  }
}

/// Widget de conteúdo que pode ser usado tanto na tela independente quanto dentro de outras telas
class HiringProposalsScreenContent extends StatefulWidget {
  const HiringProposalsScreenContent({super.key});

  @override
  State<HiringProposalsScreenContent> createState() => _HiringProposalsScreenContentState();
}

class _HiringProposalsScreenContentState extends State<HiringProposalsScreenContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Carregar propostas quando o widget for inicializado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LawyerHiringBloc>().add(
        const LoadHiringProposals(lawyerId: 'current_user'), // TODO: Usar user ID real
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar para quando usado como conteúdo independente
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Pendentes',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Aceitas',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Histórico',
            ),
          ],
        ),
        Expanded(
          child: BlocConsumer<LawyerHiringBloc, LawyerHiringState>(
            listener: (context, state) {
              if (state is ProposalResponseSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.proposal.isAccepted ? 'Proposta aceita com sucesso!' : 'Proposta rejeitada.',
                    ),
                    backgroundColor: state.proposal.isAccepted ? Colors.green : Colors.orange,
                  ),
                );
                // Recarregar a lista
                context.read<LawyerHiringBloc>().add(
                  const LoadHiringProposals(lawyerId: 'current_user'),
                );
              } else if (state is ProposalResponseError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro: ${state.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is HiringProposalsLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (state is HiringProposalsError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<LawyerHiringBloc>().add(
                            const LoadHiringProposals(lawyerId: 'current_user'),
                          );
                        },
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                );
              }
              
              if (state is HiringProposalsLoaded) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProposalsTab(state.proposals, 'pending'),
                    _buildProposalsTab(state.proposals, 'accepted'),
                    _buildProposalsTab(state.proposals, 'history'),
                  ],
                );
              }
              
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProposalsTab(List<HiringProposal> allProposals, String filter) {
    final filteredProposals = _filterProposals(allProposals, filter);
    
    if (filteredProposals.isEmpty) {
      return _buildEmptyState(filter);
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        context.read<LawyerHiringBloc>().add(
          const LoadHiringProposals(lawyerId: 'current_user'),
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredProposals.length,
        itemBuilder: (context, index) {
          return HiringProposalCard(
            proposal: filteredProposals[index],
            onAccept: filter == 'pending' ? (proposal) {
              _showAcceptDialog(context, proposal);
            } : null,
            onReject: filter == 'pending' ? (proposal) {
              _showRejectDialog(context, proposal);
            } : null,
          );
        },
      ),
    );
  }

  List<HiringProposal> _filterProposals(List<HiringProposal> proposals, String filter) {
    switch (filter) {
      case 'pending':
        return proposals.where((p) => p.status == 'pending').toList();
      case 'accepted':
        return proposals.where((p) => p.status == 'accepted').toList();
      case 'history':
        return proposals.where((p) => p.status == 'rejected' || p.status == 'expired').toList();
      default:
        return proposals;
    }
  }

  Widget _buildEmptyState(String filter) {
    String message;
    IconData icon;
    
    switch (filter) {
      case 'pending':
        message = 'Nenhuma proposta pendente';
        icon = Icons.inbox;
        break;
      case 'accepted':
        message = 'Nenhuma proposta aceita';
        icon = Icons.check_circle_outline;
        break;
      case 'history':
        message = 'Nenhuma proposta no histórico';
        icon = Icons.history;
        break;
      default:
        message = 'Nenhuma proposta encontrada';
        icon = Icons.folder_open;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showAcceptDialog(BuildContext context, HiringProposal proposal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceitar Proposta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirma que deseja aceitar a proposta de contratação?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Valor: R\$ ${proposal.budget.toStringAsFixed(2)}'),
                  Text('Tipo: ${_getContractTypeText(proposal.contractType)}'),
                  if (proposal.notes?.isNotEmpty == true)
                    Text('Observações: ${proposal.notes}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<LawyerHiringBloc>().add(
                AcceptHiringProposal(proposalId: proposal.id),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aceitar'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, HiringProposal proposal) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeitar Proposta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Por que está rejeitando esta proposta?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Motivo da rejeição...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<LawyerHiringBloc>().add(
                RejectHiringProposal(
                  proposalId: proposal.id,
                  reason: reasonController.text.trim().isEmpty 
                      ? 'Sem motivo especificado' 
                      : reasonController.text.trim(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );
  }

  String _getContractTypeText(String contractType) {
    switch (contractType) {
      case 'hourly':
        return 'Por Hora';
      case 'fixed':
        return 'Valor Fixo';
      case 'success':
        return 'Êxito';
      default:
        return contractType;
    }
  }
} 