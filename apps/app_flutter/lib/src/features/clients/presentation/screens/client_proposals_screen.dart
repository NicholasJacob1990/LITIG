import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../lawyers/presentation/bloc/lawyer_hiring_bloc.dart';
import '../widgets/client_proposal_card.dart';
import 'package:meu_app/injection_container.dart';
import '../../../../shared/widgets/molecules/empty_state_widget.dart';
import '../../../../shared/widgets/atoms/loading_indicator.dart';

class ClientProposalsScreen extends StatefulWidget {
  const ClientProposalsScreen({super.key});

  @override
  State<ClientProposalsScreen> createState() => _ClientProposalsScreenState();
}

class _ClientProposalsScreenState extends State<ClientProposalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
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
    return BlocProvider(
      create: (context) => getIt<LawyerHiringBloc>()
        ..add(const LoadHiringProposals(lawyerId: 'current_client_id')), // TODO: Get from auth
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Minhas Propostas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A237E),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.refreshCw),
              onPressed: () => _refreshProposals(),
              tooltip: 'Atualizar',
            ),
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.moreVertical),
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'filter_date',
                  child: ListTile(
                    leading: Icon(LucideIcons.calendar),
                    title: Text('Filtrar por Data'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(LucideIcons.download),
                    title: Text('Exportar Relatório'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1A237E),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFF1A237E),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                isScrollable: true,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.clock, size: 16),
                        const SizedBox(width: 6),
                        const Text('Pendentes'),
                        BlocBuilder<LawyerHiringBloc, LawyerHiringState>(
                          builder: (context, state) {
                            if (state is HiringProposalsLoaded) {
                              final count = state.proposals
                                  .where((p) => p.status == 'pending')
                                  .length;
                              if (count > 0) {
                                return Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    count.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.checkCircle, size: 16),
                        SizedBox(width: 6),
                        Text('Aceitas'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.xCircle, size: 16),
                        SizedBox(width: 6),
                        Text('Rejeitadas'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.archive, size: 16),
                        SizedBox(width: 6),
                        Text('Arquivo'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: BlocConsumer<LawyerHiringBloc, LawyerHiringState>(
          listener: (context, state) {
            if (state is LawyerHiringError || state is HiringProposalsError) {
              final message = state is LawyerHiringError 
                  ? state.message 
                  : (state as HiringProposalsError).message;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro: $message'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is HiringProposalsLoading) {
              return const Center(child: LoadingIndicator());
            }
            
            if (state is HiringProposalsError) {
              return _buildErrorView(state.message);
            }
            
            if (state is HiringProposalsLoaded) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildProposalsTab(state.proposals, 'pending'),
                  _buildProposalsTab(state.proposals, 'accepted'),
                  _buildProposalsTab(state.proposals, 'rejected'),
                  _buildProposalsTab(state.proposals, 'archive'),
                ],
              );
            }
            
            return const Center(child: LoadingIndicator());
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateToLawyers,
          icon: const Icon(LucideIcons.userPlus),
          label: const Text('Nova Proposta'),
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProposalsTab(List<dynamic> allProposals, String filter) {
    final proposals = _filterProposals(allProposals, filter);
    
    if (proposals.isEmpty) {
      return _buildEmptyState(filter);
    }
    
    return RefreshIndicator(
      onRefresh: () async => _refreshProposals(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: proposals.length,
        itemBuilder: (context, index) {
          return ClientProposalCard(
            proposal: proposals[index],
            onCancel: filter == 'pending' ? _cancelProposal : null,
            onViewDetails: _viewProposalDetails,
            onContact: _contactLawyer,
          );
        },
      ),
    );
  }

  List<dynamic> _filterProposals(List<dynamic> proposals, String filter) {
    switch (filter) {
      case 'pending':
        return proposals.where((p) => p.status == 'pending').toList();
      case 'accepted':
        return proposals.where((p) => p.status == 'accepted').toList();
      case 'rejected':
        return proposals.where((p) => p.status == 'rejected').toList();
      case 'archive':
        return proposals
            .where((p) => ['expired', 'cancelled'].contains(p.status))
            .toList();
      default:
        return proposals;
    }
  }

  Widget _buildEmptyState(String filter) {
    String message;
    String subtitle;
    IconData icon;
    String? actionText;
    VoidCallback? onAction;
    
    switch (filter) {
      case 'pending':
        message = 'Nenhuma proposta pendente';
        subtitle = 'Suas propostas aguardando resposta aparecerão aqui.';
        icon = LucideIcons.clock;
        actionText = 'Enviar Nova Proposta';
        onAction = _navigateToLawyers;
        break;
      case 'accepted':
        message = 'Nenhuma proposta aceita';
        subtitle = 'Quando um advogado aceitar sua proposta, aparecerá aqui.';
        icon = LucideIcons.checkCircle;
        break;
      case 'rejected':
        message = 'Nenhuma proposta rejeitada';
        subtitle = 'Propostas rejeitadas pelos advogados aparecerão aqui.';
        icon = LucideIcons.xCircle;
        break;
      case 'archive':
        message = 'Nenhuma proposta arquivada';
        subtitle = 'Propostas expiradas ou canceladas aparecerão aqui.';
        icon = LucideIcons.archive;
        break;
      default:
        message = 'Nenhuma proposta encontrada';
        subtitle = 'Suas propostas aparecerão aqui.';
        icon = LucideIcons.folderOpen;
    }
    
    return EmptyStateWidget(
      icon: icon,
      message: message,
      actionText: actionText,
      onActionPressed: onAction,
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                LucideIcons.alertTriangle,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Erro ao carregar propostas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshProposals,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshProposals() {
    context.read<LawyerHiringBloc>().add(
      const LoadHiringProposals(lawyerId: 'current_client_id'), // TODO: Get from auth
    );
  }

  void _cancelProposal(dynamic proposal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.orange),
            SizedBox(width: 12),
            Text('Cancelar Proposta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirma que deseja cancelar esta proposta?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalhes da Proposta:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Advogado: ${proposal.lawyerName}'),
                  Text('Caso: ${proposal.caseTitle}'),
                  Text('Valor: R\$ ${proposal.budget.toStringAsFixed(2)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Esta ação não pode ser desfeita.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementar cancelamento
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Proposta cancelada com sucesso'),
                  backgroundColor: Colors.orange,
                ),
              );
              _refreshProposals();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancelar Proposta'),
          ),
        ],
      ),
    );
  }

  void _viewProposalDetails(dynamic proposal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.fileText,
                      color: Color(0xFF1A237E),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalhes da Proposta',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Enviada em ${_formatDate(proposal.createdAt)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(proposal.status),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailSection('Advogado', [
                      _buildDetailRow('Nome', proposal.lawyerName),
                      _buildDetailRow('Especialização', 'Direito Civil'), // TODO: Get from proposal
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailSection('Caso', [
                      _buildDetailRow('Título', proposal.caseTitle),
                      _buildDetailRow('Descrição', proposal.caseDescription ?? 'N/A'),
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailSection('Proposta', [
                      _buildDetailRow('Valor', 'R\$ ${proposal.budget.toStringAsFixed(2)}'),
                      _buildDetailRow('Tipo de Contrato', _getContractTypeLabel(proposal.contractType)),
                      _buildDetailRow('Observações', proposal.notes?.isNotEmpty == true ? proposal.notes : 'Nenhuma'),
                      if (proposal.status == 'pending')
                        _buildDetailRow('Expira em', _formatDate(proposal.expiresAt)),
                    ]),
                    if (proposal.responseMessage?.isNotEmpty == true) ...[
                      const SizedBox(height: 20),
                      _buildDetailSection('Resposta do Advogado', [
                        _buildDetailRow('Mensagem', proposal.responseMessage),
                        _buildDetailRow('Respondido em', _formatDate(proposal.respondedAt)),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _contactLawyer(dynamic proposal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.messageSquare, color: Color(0xFF1A237E)),
            SizedBox(width: 12),
            Text('Entrar em Contato'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Como deseja entrar em contato com ${proposal.lawyerName}?'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // TODO: Implementar chat
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat em breve!')),
                      );
                    },
                    icon: const Icon(LucideIcons.messageSquare),
                    label: const Text('Chat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // TODO: Implementar videochamada
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Videochamada em breve!')),
                      );
                    },
                    icon: const Icon(LucideIcons.video),
                    label: const Text('Vídeo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLawyers() {
    // TODO: Implementar navegação para tela de advogados
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navegando para busca de advogados...'),
        backgroundColor: Color(0xFF1A237E),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pendente';
        icon = LucideIcons.clock;
        break;
      case 'accepted':
        color = Colors.green;
        label = 'Aceita';
        icon = LucideIcons.checkCircle;
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejeitada';
        icon = LucideIcons.xCircle;
        break;
      case 'expired':
        color = Colors.grey;
        label = 'Expirada';
        icon = LucideIcons.clock;
        break;
      case 'cancelled':
        color = Colors.grey;
        label = 'Cancelada';
        icon = LucideIcons.ban;
        break;
      default:
        color = Colors.grey;
        label = status;
        icon = LucideIcons.helpCircle;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getContractTypeLabel(String type) {
    switch (type) {
      case 'hourly':
        return 'Por Hora';
      case 'fixed':
        return 'Valor Fixo';
      case 'success':
        return 'Por Êxito';
      default:
        return type;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'filter_date':
        // TODO: Implementar filtro por data
        break;
      case 'export':
        // TODO: Implementar exportação
        break;
    }
  }
} 