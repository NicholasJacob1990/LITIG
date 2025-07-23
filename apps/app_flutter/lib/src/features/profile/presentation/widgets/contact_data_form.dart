import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/client_profile.dart';
import '../../../../shared/widgets/custom_text_form_field.dart';

class ContactDataForm extends StatefulWidget {
  final ContactData contactData;
  final ValueChanged<ContactData> onChanged;
  
  const ContactDataForm({
    super.key,
    required this.contactData,
    required this.onChanged,
  });

  @override
  State<ContactDataForm> createState() => _ContactDataFormState();
}

class _ContactDataFormState extends State<ContactDataForm> {
  late TextEditingController _primaryPhoneController;
  late TextEditingController _secondaryPhoneController;
  late TextEditingController _whatsappNumberController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _emergencyPhoneController;
  
  late bool _whatsappAuthorized;
  late bool _smsAuthorized;
  late List<PreferredContactTime> _preferredTimes;

  @override
  void initState() {
    super.initState();
    _primaryPhoneController = TextEditingController(text: widget.contactData.primaryPhone);
    _secondaryPhoneController = TextEditingController(text: widget.contactData.secondaryPhone);
    _whatsappNumberController = TextEditingController(text: widget.contactData.whatsappNumber);
    _emergencyContactController = TextEditingController(text: widget.contactData.emergencyContact);
    _emergencyPhoneController = TextEditingController(text: widget.contactData.emergencyPhone);
    _whatsappAuthorized = widget.contactData.whatsappAuthorized;
    _smsAuthorized = widget.contactData.smsAuthorized;
    _preferredTimes = List.from(widget.contactData.preferredTimes);
  }

  @override
  void dispose() {
    _primaryPhoneController.dispose();
    _secondaryPhoneController.dispose();
    _whatsappNumberController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _updateContactData() {
    widget.onChanged(ContactData(
      primaryPhone: _primaryPhoneController.text,
      secondaryPhone: _secondaryPhoneController.text,
      whatsappNumber: _whatsappNumberController.text,
      emergencyContact: _emergencyContactController.text,
      emergencyPhone: _emergencyPhoneController.text,
      whatsappAuthorized: _whatsappAuthorized,
      smsAuthorized: _smsAuthorized,
      preferredTimes: _preferredTimes,
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
            Text('Dados de Contato', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: CustomTextFormField(
                    controller: _primaryPhoneController,
                    labelText: 'Telefone Principal',
                    hintText: '(11) 99999-9999',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      PhoneInputFormatter(),
                    ],
                    onChanged: (value) => _updateContactData(),
                    prefixIcon: Icons.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Telefone principal é obrigatório';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextFormField(
                    controller: _secondaryPhoneController,
                    labelText: 'Telefone Secundário',
                    hintText: '(11) 88888-8888',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      PhoneInputFormatter(),
                    ],
                    onChanged: (value) => _updateContactData(),
                    prefixIcon: Icons.phone_android,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            CustomTextFormField(
              controller: _whatsappNumberController,
              labelText: 'WhatsApp',
              hintText: '(11) 99999-9999',
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                PhoneInputFormatter(),
              ],
              onChanged: (value) => _updateContactData(),
              prefixIcon: Icons.chat,
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_copy),
                onPressed: () {
                  _whatsappNumberController.text = _primaryPhoneController.text;
                  _updateContactData();
                },
                tooltip: 'Copiar telefone principal',
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: CustomTextFormField(
                    controller: _emergencyContactController,
                    labelText: 'Contato de Emergência',
                    hintText: 'Nome do contato',
                    onChanged: (value) => _updateContactData(),
                    prefixIcon: Icons.emergency,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextFormField(
                    controller: _emergencyPhoneController,
                    labelText: 'Telefone de Emergência',
                    hintText: '(11) 77777-7777',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      PhoneInputFormatter(),
                    ],
                    onChanged: (value) => _updateContactData(),
                    prefixIcon: Icons.phone_in_talk,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Text('Autorizações de Contato', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            
            SwitchListTile(
              title: const Text('WhatsApp'),
              subtitle: const Text('Autorizo receber mensagens via WhatsApp'),
              value: _whatsappAuthorized,
              onChanged: (value) {
                setState(() {
                  _whatsappAuthorized = value;
                });
                _updateContactData();
              },
              secondary: const Icon(Icons.chat_bubble, color: Colors.green),
            ),
            
            SwitchListTile(
              title: const Text('SMS'),
              subtitle: const Text('Autorizo receber SMS'),
              value: _smsAuthorized,
              onChanged: (value) {
                setState(() {
                  _smsAuthorized = value;
                });
                _updateContactData();
              },
              secondary: const Icon(Icons.message, color: Colors.blue),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Horários Preferenciais', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                  onPressed: _showAddPreferredTimeDialog,
                ),
              ],
            ),
            
            if (_preferredTimes.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Nenhum horário preferencial definido'),
                  ],
                ),
              )
            else
              ..._preferredTimes.map((time) => PreferredTimeChip(
                time: time,
                onDelete: () {
                  setState(() {
                    _preferredTimes.remove(time);
                  });
                  _updateContactData();
                },
              )),
          ],
        ),
      ),
    );
  }

  void _showAddPreferredTimeDialog() {
    // Implementar diálogo para adicionar horário preferencial
    showDialog(
      context: context,
      builder: (context) => AddPreferredTimeDialog(
        onAdd: (time) {
          setState(() {
            _preferredTimes.add(time);
          });
          _updateContactData();
        },
      ),
    );
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length && i < 11; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == 7) buffer.write('-');
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class PreferredTimeChip extends StatelessWidget {
  final PreferredContactTime time;
  final VoidCallback onDelete;
  
  const PreferredTimeChip({
    super.key,
    required this.time,
    required this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Chip(
        label: Text('${_getWeekDayName(time.day)}: ${time.startTime} - ${time.endTime}'),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: onDelete,
      ),
    );
  }
  
  String _getWeekDayName(WeekDay day) {
    switch (day) {
      case WeekDay.monday:
        return 'Segunda';
      case WeekDay.tuesday:
        return 'Terça';
      case WeekDay.wednesday:
        return 'Quarta';
      case WeekDay.thursday:
        return 'Quinta';
      case WeekDay.friday:
        return 'Sexta';
      case WeekDay.saturday:
        return 'Sábado';
      case WeekDay.sunday:
        return 'Domingo';
    }
  }
}

class AddPreferredTimeDialog extends StatefulWidget {
  final Function(PreferredContactTime) onAdd;
  
  const AddPreferredTimeDialog({
    super.key,
    required this.onAdd,
  });
  
  @override
  State<AddPreferredTimeDialog> createState() => _AddPreferredTimeDialogState();
}

class _AddPreferredTimeDialogState extends State<AddPreferredTimeDialog> {
  WeekDay? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Horário Preferencial'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<WeekDay>(
            decoration: const InputDecoration(labelText: 'Dia da Semana'),
            value: _selectedDay,
            items: WeekDay.values.map((day) => DropdownMenuItem(
              value: day,
              child: Text(_getWeekDayName(day)),
            )).toList(),
            onChanged: (day) => setState(() => _selectedDay = day),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Início'),
                  subtitle: Text(_startTime?.format(context) ?? 'Selecionar'),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _startTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() => _startTime = time);
                    }
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  title: const Text('Fim'),
                  subtitle: Text(_endTime?.format(context) ?? 'Selecionar'),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _endTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() => _endTime = time);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selectedDay != null && _startTime != null && _endTime != null
              ? () {
                  widget.onAdd(PreferredContactTime(
                    day: _selectedDay!,
                    startTime: _startTime!.format(context),
                    endTime: _endTime!.format(context),
                  ));
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
  
  String _getWeekDayName(WeekDay day) {
    switch (day) {
      case WeekDay.monday:
        return 'Segunda-feira';
      case WeekDay.tuesday:
        return 'Terça-feira';
      case WeekDay.wednesday:
        return 'Quarta-feira';
      case WeekDay.thursday:
        return 'Quinta-feira';
      case WeekDay.friday:
        return 'Sexta-feira';
      case WeekDay.saturday:
        return 'Sábado';
      case WeekDay.sunday:
        return 'Domingo';
    }
  }
}