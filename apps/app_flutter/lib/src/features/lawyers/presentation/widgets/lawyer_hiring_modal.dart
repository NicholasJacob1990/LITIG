import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/lawyer_hiring_bloc.dart';
import 'package:meu_app/injection_container.dart';
import 'package:meu_app/src/features/lawyers/domain/usecases/hire_lawyer.dart';

class LawyerHiringModal extends StatefulWidget {
  final MatchedLawyer lawyer;
  final String caseId;
  final String clientId;

  const LawyerHiringModal({
    super.key,
    required this.lawyer,
    required this.caseId,
    required this.clientId,
  });

  @override
  State<LawyerHiringModal> createState() => _LawyerHiringModalState();
}

class _LawyerHiringModalState extends State<LawyerHiringModal> {
  String _selectedContractType = 'hourly';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LawyerHiringBloc>(
      create: (context) => getIt<LawyerHiringBloc>(),
      child: Dialog(
        // Melhoria de acessibilidade: adicionar semantics para screen readers
        child: Semantics(
          label: 'Modal de contratação de advogado ${widget.lawyer.nome}',
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildLawyerInfo(),
                const SizedBox(height: 24),
                _buildContractOptions(),
                const SizedBox(height: 16),
                _buildBudgetInput(),
                const SizedBox(height: 16),
                _buildNotesInput(),
                const SizedBox(height: 24),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.gavel, size: 32, color: Colors.blue),
        const SizedBox(width: 12),
        const Text(
          'Contratar Advogado',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildLawyerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: widget.lawyer.avatarUrl.isNotEmpty
                ? NetworkImage(widget.lawyer.avatarUrl)
                : null,
            child: widget.lawyer.avatarUrl.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lawyer.nome,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text('Área: ${widget.lawyer.primaryArea}'),
                Text('Experiência: ${widget.lawyer.experienceYears ?? 'N/I'} anos'),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(' ${widget.lawyer.rating?.toStringAsFixed(1) ?? 'N/A'}'),
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on, size: 16),
                    Text(' ${widget.lawyer.distanceKm.toStringAsFixed(1)} km'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Contrato',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        RadioListTile<String>(
          title: const Text('Por Hora'),
          subtitle: const Text('Pagamento por hora trabalhada'),
          value: 'hourly',
          groupValue: _selectedContractType,
          onChanged: (value) => setState(() => _selectedContractType = value!),
        ),
        RadioListTile<String>(
          title: const Text('Valor Fixo'),
          subtitle: const Text('Valor fixo para todo o caso'),
          value: 'fixed',
          groupValue: _selectedContractType,
          onChanged: (value) => setState(() => _selectedContractType = value!),
        ),
        RadioListTile<String>(
          title: const Text('Êxito'),
          subtitle: const Text('Pagamento apenas em caso de sucesso'),
          value: 'success',
          groupValue: _selectedContractType,
          onChanged: (value) => setState(() => _selectedContractType = value!),
        ),
      ],
    );
  }

  Widget _buildBudgetInput() {
    return Semantics(
      label: 'Campo de orçamento',
      child: TextField(
        controller: _budgetController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: _selectedContractType == 'hourly' 
              ? 'Valor por Hora (R\$)'
              : 'Orçamento Total (R\$)',
          prefixText: 'R\$ ',
          border: const OutlineInputBorder(),
          // Melhoria de acessibilidade: adicionar hint semântico
          helperText: 'Digite o valor em reais',
        ),
      ),
    );
  }

  Widget _buildNotesInput() {
    return Semantics(
      label: 'Campo de observações opcionais',
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Observações (opcional)',
          hintText: 'Informações adicionais sobre o caso...',
          border: OutlineInputBorder(),
          // Melhoria de acessibilidade: adicionar hint semântico
          helperText: 'Campo opcional para informações extras',
        ),
      ),
    );
  }

  Widget _buildActions() {
    return BlocConsumer<LawyerHiringBloc, LawyerHiringState>(
      listener: (context, state) {
        if (state is LawyerHiringSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proposta enviada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is LawyerHiringError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is LawyerHiringLoading;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: isLoading ? null : _sendHiringProposal,
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enviar Proposta'),
            ),
          ],
        );
      },
    );
  }

  void _sendHiringProposal() {
    if (_budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe o valor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final budget = double.tryParse(_budgetController.text.replaceAll(',', '.'));
    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valor inválido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final params = HireLawyerParams(
      lawyerId: widget.lawyer.id,
      caseId: widget.caseId,
      clientId: widget.clientId,
      contractType: _selectedContractType,
      budget: budget,
      notes: _notesController.text,
    );

    context.read<LawyerHiringBloc>().add(
      ConfirmLawyerHiring(params: params),
    );
  }
}