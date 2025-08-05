import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/law_firm.dart';
import '../../domain/usecases/hire_firm.dart';
import '../bloc/firm_hiring_bloc.dart';
import '../../../../shared/widgets/instrumented_widgets.dart';

/// Modal para confirmação de contratação de escritório
/// 
/// Apresenta informações do escritório e opções de contrato
/// para o cliente confirmar a contratação.
class FirmHiringModal extends StatefulWidget {
  const FirmHiringModal({
    super.key,
    required this.firm,
    required this.caseId,
    required this.clientId,
  });

  final LawFirm firm;
  final String caseId;
  final String clientId;

  @override
  State<FirmHiringModal> createState() => _FirmHiringModalState();
}

class _FirmHiringModalState extends State<FirmHiringModal> {
  String _selectedContractType = 'hourly';
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FirmHiringBloc, FirmHiringState>(
      listener: (context, state) {
        if (state is FirmHiringSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Escritório contratado com sucesso! Contrato #${state.result.contractId}'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is FirmHiringError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao contratar: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildFirmInfo(),
              const SizedBox(height: 24),
              _buildContractOptions(),
              const SizedBox(height: 24),
              _buildNotesSection(),
              const SizedBox(height: 32),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.handshake,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contratar Escritório',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Confirme os detalhes da contratação',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildFirmInfo() {
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
          Row(
            children: [
              Icon(Icons.business, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Informações do Escritório',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Nome', widget.firm.name),
          _buildInfoRow('Equipe', '${widget.firm.teamSize} advogados'),
          if (widget.firm.kpis != null) ...[
            _buildInfoRow('Taxa de Sucesso', '${(widget.firm.kpis!.successRate * 100).toStringAsFixed(1)}%'),
            _buildInfoRow('Reputação', '${widget.firm.kpis!.reputationScore.toStringAsFixed(1)}/5.0'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
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
        Row(
          children: [
            Icon(Icons.description, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Tipo de Contrato',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildContractOption(
          'hourly',
          'Por Hora',
          'Pagamento baseado em horas trabalhadas',
          Icons.schedule,
        ),
        _buildContractOption(
          'fixed',
          'Valor Fixo',
          'Valor total acordado previamente',
          Icons.attach_money,
        ),
        _buildContractOption(
          'success_fee',
          'Taxa de Êxito',
          'Pagamento baseado no resultado obtido',
          Icons.trending_up,
        ),
      ],
    );
  }

  Widget _buildContractOption(String value, String title, String description, IconData icon) {
    final isSelected = _selectedContractType == value;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedContractType = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.note_add, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Observações (Opcional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Adicione detalhes específicos sobre o caso ou preferências...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return BlocBuilder<FirmHiringBloc, FirmHiringState>(
      builder: (context, state) {
        final isLoading = state is FirmHiringLoading;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 16),
            InstrumentedInviteButton(
              recipientId: widget.firm.id,
              invitationType: 'firm_hire_confirmation',
              additionalData: {
                'firm_name': widget.firm.name,
                'firm_team_size': widget.firm.teamSize,
                'contract_type': _selectedContractType,
                'case_id': widget.caseId,
                'client_id': widget.clientId,
                'has_notes': _notesController.text.trim().isNotEmpty,
                'notes_length': _notesController.text.trim().length,
                'firm_success_rate': widget.firm.kpis?.successRate,
                'firm_reputation': widget.firm.kpis?.reputationScore,
                'hiring_context': 'firm_hiring_modal',
              },
              onPressed: isLoading ? null : _handleConfirmHiring,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirmar Contratação'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleConfirmHiring() {
    final params = HireFirmParams(
      firmId: widget.firm.id,
      caseId: widget.caseId,
      clientId: widget.clientId,
      contractType: _selectedContractType,
      notes: _notesController.text.trim().isEmpty ? '' : _notesController.text.trim(),
    );

    context.read<FirmHiringBloc>().add(ConfirmFirmHiring(params: params));
  }
} 