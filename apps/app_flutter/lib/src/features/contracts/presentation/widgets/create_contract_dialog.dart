import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/contracts_bloc.dart';
import '../bloc/contracts_event.dart';

class CreateContractDialog extends StatefulWidget {
  const CreateContractDialog({super.key});

  @override
  State<CreateContractDialog> createState() => _CreateContractDialogState();
}

class _CreateContractDialogState extends State<CreateContractDialog> {
  final _formKey = GlobalKey<FormState>();
  final _caseIdController = TextEditingController();
  final _lawyerIdController = TextEditingController();
  
  String _selectedFeeType = 'fixed';
  final _percentController = TextEditingController();
  final _valueController = TextEditingController();
  final _rateController = TextEditingController();

  @override
  void dispose() {
    _caseIdController.dispose();
    _lawyerIdController.dispose();
    _percentController.dispose();
    _valueController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Criar Contrato',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // ID do Caso
              TextFormField(
                controller: _caseIdController,
                decoration: const InputDecoration(
                  labelText: 'ID do Caso',
                  hintText: 'Digite o ID do caso',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite o ID do caso';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // ID do Advogado
              TextFormField(
                controller: _lawyerIdController,
                decoration: const InputDecoration(
                  labelText: 'ID do Advogado',
                  hintText: 'Digite o ID do advogado',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite o ID do advogado';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Tipo de Honorários
              Text(
                'Modelo de Honorários',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              
              DropdownButtonFormField<String>(
                value: _selectedFeeType,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'fixed', child: Text('Honorários Fixos')),
                  DropdownMenuItem(value: 'success', child: Text('Honorários de Êxito')),
                  DropdownMenuItem(value: 'hourly', child: Text('Honorários por Hora')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFeeType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Campos específicos por tipo
              _buildFeeTypeFields(),
              const SizedBox(height: 24),
              
              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _createContract,
                      child: const Text('Criar Contrato'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeeTypeFields() {
    switch (_selectedFeeType) {
      case 'fixed':
        return TextFormField(
          controller: _valueController,
          decoration: const InputDecoration(
            labelText: 'Valor Fixo (R\$)',
            hintText: '0.00',
            border: OutlineInputBorder(),
            prefixText: 'R\$ ',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, digite o valor';
            }
            if (double.tryParse(value) == null) {
              return 'Por favor, digite um valor válido';
            }
            if (double.parse(value) <= 0) {
              return 'O valor deve ser maior que zero';
            }
            return null;
          },
        );
      
      case 'success':
        return TextFormField(
          controller: _percentController,
          decoration: const InputDecoration(
            labelText: 'Percentual de Êxito (%)',
            hintText: '20',
            border: OutlineInputBorder(),
            suffixText: '%',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, digite o percentual';
            }
            if (double.tryParse(value) == null) {
              return 'Por favor, digite um percentual válido';
            }
            final percent = double.parse(value);
            if (percent <= 0 || percent > 100) {
              return 'O percentual deve estar entre 0 e 100';
            }
            return null;
          },
        );
      
      case 'hourly':
        return TextFormField(
          controller: _rateController,
          decoration: const InputDecoration(
            labelText: 'Valor por Hora (R\$)',
            hintText: '0.00',
            border: OutlineInputBorder(),
            prefixText: 'R\$ ',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, digite o valor por hora';
            }
            if (double.tryParse(value) == null) {
              return 'Por favor, digite um valor válido';
            }
            if (double.parse(value) <= 0) {
              return 'O valor deve ser maior que zero';
            }
            return null;
          },
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  void _createContract() {
    if (_formKey.currentState!.validate()) {
      final feeModel = <String, dynamic>{
        'type': _selectedFeeType,
      };

      switch (_selectedFeeType) {
        case 'fixed':
          feeModel['value'] = double.parse(_valueController.text);
          break;
        case 'success':
          feeModel['percent'] = double.parse(_percentController.text);
          break;
        case 'hourly':
          feeModel['rate'] = double.parse(_rateController.text);
          break;
      }

      context.read<ContractsBloc>().add(CreateContract(
        caseId: _caseIdController.text,
        lawyerId: _lawyerIdController.text,
        feeModel: feeModel,
      ));

      Navigator.of(context).pop();
    }
  }
} 