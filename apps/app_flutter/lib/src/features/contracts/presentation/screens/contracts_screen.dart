import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/contract.dart';
import '../bloc/contracts_bloc.dart';
import '../bloc/contracts_event.dart';
import '../bloc/contracts_state.dart';
import '../widgets/contract_card.dart';
import '../widgets/create_contract_dialog.dart';
import '../widgets/contract_filters.dart';

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  String _selectedStatus = 'all';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ContractsBloc>().add(const LoadContracts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Contratos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateContractDialog,
            tooltip: 'Criar Contrato',
          ),
        ],
      ),
      body: Column(
        children: [
          ContractFilters(
            selectedStatus: _selectedStatus,
            searchController: _searchController,
            onStatusChanged: (status) {
              setState(() {
                _selectedStatus = status;
              });
              _filterContracts();
            },
            onSearchChanged: (query) {
              _filterContracts();
            },
          ),
          Expanded(
            child: BlocConsumer<ContractsBloc, ContractsState>(
              listener: (context, state) {
                if (state is ContractsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is ContractSigned) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contrato assinado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (state is ContractCreated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contrato criado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ContractsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is ContractsLoaded) {
                  final contracts = _filterContractsByStatus(state.contracts);
                  
                  if (contracts.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<ContractsBloc>().add(const LoadContracts());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: contracts.length,
                      itemBuilder: (context, index) {
                        final contract = contracts[index];
                        return ContractCard(
                          contract: contract,
                          onTap: () => _showContractDetails(contract),
                          onSign: () => _signContract(contract),
                          onCancel: () => _cancelContract(contract),
                          onDownload: () => _downloadContract(contract),
                        );
                      },
                    ),
                  );
                }

                if (state is ContractsError) {
                  return _buildErrorState(state.message);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Contract> _filterContractsByStatus(List<Contract> contracts) {
    if (_selectedStatus == 'all') {
      return contracts;
    }
    return contracts.where((contract) => contract.status == _selectedStatus).toList();
  }

  void _filterContracts() {
    context.read<ContractsBloc>().add(FilterContracts(
      status: _selectedStatus == 'all' ? null : _selectedStatus,
      searchQuery: _searchController.text,
    ));
  }

  void _showCreateContractDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateContractDialog(),
    );
  }

  void _showContractDetails(Contract contract) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detalhes do Contrato',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Caso', contract.caseTitle ?? 'N/A'),
              _buildDetailRow('Advogado', contract.lawyerName ?? 'N/A'),
              _buildDetailRow('Status', _getStatusLabel(contract.status)),
              _buildDetailRow('Criado em', DateFormat('dd/MM/yyyy').format(contract.createdAt)),
              if (contract.signedClient != null)
                _buildDetailRow('Assinado pelo Cliente', DateFormat('dd/MM/yyyy HH:mm').format(contract.signedClient!)),
              if (contract.signedLawyer != null)
                _buildDetailRow('Assinado pelo Advogado', DateFormat('dd/MM/yyyy HH:mm').format(contract.signedLawyer!)),
              const SizedBox(height: 16),
              _buildFeeModelDetails(contract.feeModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeModelDetails(Map<String, dynamic> feeModel) {
    final type = feeModel['type'] as String?;
    String details = '';

    switch (type) {
      case 'success':
        final percent = feeModel['percent'] as num?;
        details = 'Honorários de Êxito: ${percent?.toStringAsFixed(1)}%';
        break;
      case 'fixed':
        final value = feeModel['value'] as num?;
        details = 'Honorários Fixos: R\$ ${value?.toStringAsFixed(2)}';
        break;
      case 'hourly':
        final rate = feeModel['rate'] as num?;
        details = 'Honorários por Hora: R\$ ${rate?.toStringAsFixed(2)}/h';
        break;
      default:
        details = 'Tipo não especificado';
    }

    return _buildDetailRow('Modelo de Honorários', details);
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending-signature':
        return 'Aguardando Assinatura';
      case 'active':
        return 'Ativo';
      case 'closed':
        return 'Encerrado';
      case 'canceled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  void _signContract(Contract contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assinar Contrato'),
        content: const Text('Deseja assinar este contrato?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ContractsBloc>().add(SignContract(
                contractId: contract.id,
                role: 'client', // ou 'lawyer' baseado no usuário atual
              ));
            },
            child: const Text('Assinar'),
          ),
        ],
      ),
    );
  }

  void _cancelContract(Contract contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Contrato'),
        content: const Text('Tem certeza que deseja cancelar este contrato?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ContractsBloc>().add(CancelContract(contractId: contract.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );
  }

  void _downloadContract(Contract contract) {
    context.read<ContractsBloc>().add(DownloadContract(contractId: contract.id));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum contrato encontrado',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie seu primeiro contrato para começar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateContractDialog,
            icon: const Icon(Icons.add),
            label: const Text('Criar Contrato'),
          ),
        ],
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
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar contratos',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.red[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<ContractsBloc>().add(const LoadContracts());
            },
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }
} 