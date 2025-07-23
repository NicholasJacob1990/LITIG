import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/client_profile.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/custom_text_form_field.dart';

class PersonalDataFormPJ extends StatefulWidget {
  final PersonalData personalData;
  final ValueChanged<PersonalData> onChanged;
  
  const PersonalDataFormPJ({
    super.key,
    required this.personalData,
    required this.onChanged,
  });

  @override
  State<PersonalDataFormPJ> createState() => _PersonalDataFormPJState();
}

class _PersonalDataFormPJState extends State<PersonalDataFormPJ> {
  late TextEditingController _cnpjController;
  late TextEditingController _stateRegistrationController;
  late TextEditingController _municipalRegistrationController;
  late TextEditingController _legalRepresentativeController;
  late TextEditingController _businessSectorController;
  
  DateTime? _foundingDate;
  String? _companySize;

  @override
  void initState() {
    super.initState();
    _cnpjController = TextEditingController(text: widget.personalData.cnpj);
    _stateRegistrationController = TextEditingController(text: widget.personalData.stateRegistration);
    _municipalRegistrationController = TextEditingController(text: widget.personalData.municipalRegistration);
    _legalRepresentativeController = TextEditingController(text: widget.personalData.legalRepresentative);
    _businessSectorController = TextEditingController(text: widget.personalData.businessSector);
    _foundingDate = widget.personalData.foundingDate;
    _companySize = widget.personalData.companySize;
  }

  @override
  void dispose() {
    _cnpjController.dispose();
    _stateRegistrationController.dispose();
    _municipalRegistrationController.dispose();
    _legalRepresentativeController.dispose();
    _businessSectorController.dispose();
    super.dispose();
  }

  void _updatePersonalData() {
    widget.onChanged(PersonalData(
      cnpj: _cnpjController.text,
      stateRegistration: _stateRegistrationController.text,
      municipalRegistration: _municipalRegistrationController.text,
      legalRepresentative: _legalRepresentativeController.text,
      companySize: _companySize,
      businessSector: _businessSectorController.text,
      foundingDate: _foundingDate,
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
            Text('Dados da Empresa', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            CustomTextFormField(
              controller: _cnpjController,
              labelText: 'CNPJ',
              hintText: '00.000.000/0000-00',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CnpjInputFormatter(),
              ],
              validator: (value) => Validators.validateCNPJ(value),
              onChanged: (value) => _updatePersonalData(),
              prefixIcon: Icons.business,
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: CustomTextFormField(
                    controller: _stateRegistrationController,
                    labelText: 'Inscrição Estadual',
                    hintText: 'Número da IE',
                    onChanged: (value) => _updatePersonalData(),
                    prefixIcon: Icons.assignment,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextFormField(
                    controller: _municipalRegistrationController,
                    labelText: 'Inscrição Municipal',
                    hintText: 'Número da IM',
                    onChanged: (value) => _updatePersonalData(),
                    prefixIcon: Icons.location_city,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            CustomTextFormField(
              controller: _legalRepresentativeController,
              labelText: 'Representante Legal',
              hintText: 'Nome completo do representante',
              onChanged: (value) => _updatePersonalData(),
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Representante legal é obrigatório';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Porte da Empresa',
                prefixIcon: Icon(Icons.business_center),
                border: OutlineInputBorder(),
              ),
              value: _companySize,
              items: [
                'Microempresa (ME)',
                'Empresa de Pequeno Porte (EPP)',
                'Média Empresa',
                'Grande Empresa',
              ].map((size) => DropdownMenuItem(
                value: size,
                child: Text(size),
              )).toList(),
              onChanged: (size) {
                setState(() {
                  _companySize = size;
                });
                _updatePersonalData();
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecione o porte da empresa';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            CustomTextFormField(
              controller: _businessSectorController,
              labelText: 'Setor de Atuação',
              hintText: 'Ex: Tecnologia, Indústria, Comércio',
              onChanged: (value) => _updatePersonalData(),
              prefixIcon: Icons.category,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Setor de atuação é obrigatório';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _foundingDate ?? DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  helpText: 'Selecione a data de fundação',
                );
                if (picked != null) {
                  setState(() {
                    _foundingDate = picked;
                  });
                  _updatePersonalData();
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data de Fundação',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _foundingDate != null 
                      ? DateFormat('dd/MM/yyyy').format(_foundingDate!)
                      : 'Selecione a data',
                  style: TextStyle(
                    color: _foundingDate != null ? null : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length && i < 14; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('/');
      if (i == 12) buffer.write('-');
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}