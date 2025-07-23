import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/client_profile.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/custom_text_form_field.dart';

class PersonalDataFormPF extends StatefulWidget {
  final PersonalData personalData;
  final ValueChanged<PersonalData> onChanged;
  
  const PersonalDataFormPF({
    super.key,
    required this.personalData,
    required this.onChanged,
  });

  @override
  State<PersonalDataFormPF> createState() => _PersonalDataFormPFState();
}

class _PersonalDataFormPFState extends State<PersonalDataFormPF> {
  late TextEditingController _cpfController;
  late TextEditingController _rgController;
  late TextEditingController _rgIssuingBodyController;
  late TextEditingController _professionController;
  late TextEditingController _nationalityController;
  late TextEditingController _motherNameController;
  late TextEditingController _fatherNameController;
  
  DateTime? _birthDate;
  String? _maritalStatus;

  @override
  void initState() {
    super.initState();
    _cpfController = TextEditingController(text: widget.personalData.cpf);
    _rgController = TextEditingController(text: widget.personalData.rg);
    _rgIssuingBodyController = TextEditingController(text: widget.personalData.rgIssuingBody);
    _professionController = TextEditingController(text: widget.personalData.profession);
    _nationalityController = TextEditingController(text: widget.personalData.nationality ?? 'Brasileiro(a)');
    _motherNameController = TextEditingController(text: widget.personalData.motherName);
    _fatherNameController = TextEditingController(text: widget.personalData.fatherName);
    _birthDate = widget.personalData.birthDate;
    _maritalStatus = widget.personalData.maritalStatus;
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _rgController.dispose();
    _rgIssuingBodyController.dispose();
    _professionController.dispose();
    _nationalityController.dispose();
    _motherNameController.dispose();
    _fatherNameController.dispose();
    super.dispose();
  }

  void _updatePersonalData() {
    widget.onChanged(PersonalData(
      cpf: _cpfController.text,
      rg: _rgController.text,
      rgIssuingBody: _rgIssuingBodyController.text,
      birthDate: _birthDate,
      maritalStatus: _maritalStatus,
      profession: _professionController.text,
      nationality: _nationalityController.text,
      motherName: _motherNameController.text,
      fatherName: _fatherNameController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dados Pessoais', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            CustomTextFormField(
              controller: _cpfController,
              labelText: 'CPF',
              hintText: '000.000.000-00',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CpfInputFormatter(),
              ],
              validator: (value) => Validators.validateCPF(value),
              onChanged: (value) => _updatePersonalData(),
              prefixIcon: Icons.badge,
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextFormField(
                    controller: _rgController,
                    labelText: 'RG',
                    hintText: 'Número do RG',
                    onChanged: (value) => _updatePersonalData(),
                    prefixIcon: Icons.credit_card,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextFormField(
                    controller: _rgIssuingBodyController,
                    labelText: 'Órgão Emissor',
                    hintText: 'SSP/SP',
                    onChanged: (value) => _updatePersonalData(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 6570)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _birthDate = picked;
                  });
                  _updatePersonalData();
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data de Nascimento',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _birthDate != null 
                      ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                      : 'Selecione a data',
                  style: TextStyle(
                    color: _birthDate != null ? null : Colors.grey[600],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Estado Civil',
                prefixIcon: Icon(Icons.favorite),
                border: OutlineInputBorder(),
              ),
              value: _maritalStatus,
              items: [
                'Solteiro(a)',
                'Casado(a)',
                'Divorciado(a)',
                'Viúvo(a)',
                'União Estável',
                'Separado(a)',
              ].map((status) => DropdownMenuItem(
                value: status,
                child: Text(status),
              )).toList(),
              onChanged: (status) {
                setState(() {
                  _maritalStatus = status;
                });
                _updatePersonalData();
              },
            ),
            
            const SizedBox(height: 16),
            
            CustomTextFormField(
              controller: _professionController,
              labelText: 'Profissão',
              hintText: 'Ex: Engenheiro, Médico, Professor',
              onChanged: (value) => _updatePersonalData(),
              prefixIcon: Icons.work,
            ),
            
            const SizedBox(height: 16),
            
            CustomTextFormField(
              controller: _nationalityController,
              labelText: 'Nacionalidade',
              hintText: 'Brasileiro(a)',
              onChanged: (value) => _updatePersonalData(),
              prefixIcon: Icons.flag,
            ),
            
            const SizedBox(height: 16),
            
            CustomTextFormField(
              controller: _motherNameController,
              labelText: 'Nome da Mãe',
              hintText: 'Nome completo da mãe',
              onChanged: (value) => _updatePersonalData(),
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nome da mãe é obrigatório';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            CustomTextFormField(
              controller: _fatherNameController,
              labelText: 'Nome do Pai',
              hintText: 'Nome completo do pai (opcional)',
              onChanged: (value) => _updatePersonalData(),
              prefixIcon: Icons.person_outline,
            ),
          ],
        ),
      ),
    );
  }
}

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length && i < 11; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}