import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/client_profile.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/custom_text_form_field.dart';

class AddressesSection extends StatefulWidget {
  final List<Address> addresses;
  final ValueChanged<List<Address>> onChanged;

  const AddressesSection({
    super.key,
    required this.addresses,
    required this.onChanged,
  });

  @override
  State<AddressesSection> createState() => _AddressesSectionState();
}

class _AddressesSectionState extends State<AddressesSection> {
  late List<Address> _addresses;

  @override
  void initState() {
    super.initState();
    _addresses = List.from(widget.addresses);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Endereços', style: Theme.of(context).textTheme.titleLarge),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                  onPressed: _showAddAddressDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_addresses.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Nenhum endereço cadastrado'),
                  ],
                ),
              )
            else
              ...(_addresses.asMap().entries.map((entry) {
                final index = entry.key;
                final address = entry.value;
                return AddressCard(
                  address: address,
                  isPrimary: address.isPrimary,
                  onEdit: () => _editAddress(index),
                  onDelete: () => _deleteAddress(index),
                  onSetPrimary: () => _setPrimaryAddress(index),
                );
              })),
          ],
        ),
      ),
    );
  }

  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (context) => AddressDialog(
        onSave: (address) => _addAddress(address),
      ),
    );
  }

  void _editAddress(int index) {
    showDialog(
      context: context,
      builder: (context) => AddressDialog(
        address: _addresses[index],
        onSave: (address) => _updateAddress(index, address),
      ),
    );
  }

  void _addAddress(Address address) {
    setState(() {
      // If this is the first address, make it primary
      final isPrimary = _addresses.isEmpty;
      final newAddress = Address(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: address.type,
        zipCode: address.zipCode,
        street: address.street,
        number: address.number,
        complement: address.complement,
        neighborhood: address.neighborhood,
        city: address.city,
        state: address.state,
        country: address.country,
        isPrimary: isPrimary,
        isActive: true,
      );
      
      _addresses.add(newAddress);
    });
    
    widget.onChanged(_addresses);
  }

  void _updateAddress(int index, Address updatedAddress) {
    setState(() {
      _addresses[index] = updatedAddress;
    });
    
    widget.onChanged(_addresses);
  }

  void _deleteAddress(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Endereço'),
        content: const Text('Tem certeza que deseja excluir este endereço?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                final wasMainAddress = _addresses[index].isPrimary;
                _addresses.removeAt(index);
                
                // If we deleted the main address and there are others, make the first one main
                if (wasMainAddress && _addresses.isNotEmpty) {
                  _addresses[0] = Address(
                    id: _addresses[0].id,
                    type: _addresses[0].type,
                    zipCode: _addresses[0].zipCode,
                    street: _addresses[0].street,
                    number: _addresses[0].number,
                    complement: _addresses[0].complement,
                    neighborhood: _addresses[0].neighborhood,
                    city: _addresses[0].city,
                    state: _addresses[0].state,
                    country: _addresses[0].country,
                    isPrimary: true,
                    isActive: _addresses[0].isActive,
                  );
                }
              });
              
              widget.onChanged(_addresses);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _setPrimaryAddress(int index) {
    setState(() {
      // Remove primary flag from all addresses
      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i] = Address(
          id: _addresses[i].id,
          type: _addresses[i].type,
          zipCode: _addresses[i].zipCode,
          street: _addresses[i].street,
          number: _addresses[i].number,
          complement: _addresses[i].complement,
          neighborhood: _addresses[i].neighborhood,
          city: _addresses[i].city,
          state: _addresses[i].state,
          country: _addresses[i].country,
          isPrimary: i == index,
          isActive: _addresses[i].isActive,
        );
      }
    });
    
    widget.onChanged(_addresses);
  }
}

class AddressCard extends StatelessWidget {
  final Address address;
  final bool isPrimary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetPrimary;

  const AddressCard({
    super.key,
    required this.address,
    required this.isPrimary,
    required this.onEdit,
    required this.onDelete,
    required this.onSetPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isPrimary ? Theme.of(context).primaryColor : Colors.grey[300]!,
          width: isPrimary ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getAddressTypeIcon(address.type),
                  color: isPrimary ? Theme.of(context).primaryColor : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getAddressTypeName(address.type),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isPrimary ? Theme.of(context).primaryColor : null,
                      fontWeight: isPrimary ? FontWeight.bold : null,
                    ),
                  ),
                ),
                if (isPrimary)
                  Chip(
                    label: const Text('Principal'),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleAction(action),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    if (!isPrimary)
                      const PopupMenuItem(value: 'set_primary', child: Text('Tornar Principal')),
                    const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              '${address.street}, ${address.number}${address.complement?.isNotEmpty == true ? ', ${address.complement}' : ''}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            
            Text(
              '${address.neighborhood} - ${address.city}/${address.state}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            Text(
              'CEP: ${address.zipCode}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAddressTypeIcon(AddressType type) {
    switch (type) {
      case AddressType.residential:
        return Icons.home;
      case AddressType.commercial:
        return Icons.business;
      case AddressType.billing:
        return Icons.receipt_long;
      case AddressType.correspondence:
        return Icons.mail;
    }
  }

  String _getAddressTypeName(AddressType type) {
    switch (type) {
      case AddressType.residential:
        return 'Residencial';
      case AddressType.commercial:
        return 'Comercial';
      case AddressType.billing:
        return 'Cobrança';
      case AddressType.correspondence:
        return 'Correspondência';
    }
  }

  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        onEdit();
        break;
      case 'set_primary':
        onSetPrimary();
        break;
      case 'delete':
        onDelete();
        break;
    }
  }
}

class AddressDialog extends StatefulWidget {
  final Address? address;
  final Function(Address) onSave;

  const AddressDialog({
    super.key,
    this.address,
    required this.onSave,
  });

  @override
  State<AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<AddressDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _zipCodeController;
  late TextEditingController _streetController;
  late TextEditingController _numberController;
  late TextEditingController _complementController;
  late TextEditingController _neighborhoodController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  
  AddressType _selectedType = AddressType.residential;
  bool _isLoadingCEP = false;

  @override
  void initState() {
    super.initState();
    
    _zipCodeController = TextEditingController(text: widget.address?.zipCode ?? '');
    _streetController = TextEditingController(text: widget.address?.street ?? '');
    _numberController = TextEditingController(text: widget.address?.number ?? '');
    _complementController = TextEditingController(text: widget.address?.complement ?? '');
    _neighborhoodController = TextEditingController(text: widget.address?.neighborhood ?? '');
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _stateController = TextEditingController(text: widget.address?.state ?? '');
    
    _selectedType = widget.address?.type ?? AddressType.residential;
  }

  @override
  void dispose() {
    _zipCodeController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.address == null ? 'Novo Endereço' : 'Editar Endereço'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<AddressType>(
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Endereço',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedType,
                  items: AddressType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(_getAddressTypeName(type)),
                  )).toList(),
                  onChanged: (type) => setState(() => _selectedType = type!),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: _zipCodeController,
                        labelText: 'CEP',
                        hintText: '00000-000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CEPInputFormatter(),
                        ],
                        validator: Validators.validateCEP,
                        onChanged: (value) => _onCEPChanged(value),
                        suffixIcon: _isLoadingCEP
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                        prefixIcon: Icons.location_on,
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar'),
                      onPressed: () => _searchCEP(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: CustomTextFormField(
                        controller: _streetController,
                        labelText: 'Logradouro',
                        hintText: 'Rua, Avenida, etc.',
                        validator: (value) => value?.isEmpty == true ? 'Logradouro é obrigatório' : null,
                        prefixIcon: Icons.route,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextFormField(
                        controller: _numberController,
                        labelText: 'Número',
                        hintText: '123',
                        validator: (value) => value?.isEmpty == true ? 'Número é obrigatório' : null,
                        prefixIcon: Icons.numbers,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                CustomTextFormField(
                  controller: _complementController,
                  labelText: 'Complemento',
                  hintText: 'Apto, Bloco, etc. (opcional)',
                  prefixIcon: Icons.add_location,
                ),
                
                const SizedBox(height: 16),
                
                CustomTextFormField(
                  controller: _neighborhoodController,
                  labelText: 'Bairro',
                  hintText: 'Nome do bairro',
                  validator: (value) => value?.isEmpty == true ? 'Bairro é obrigatório' : null,
                  prefixIcon: Icons.location_city,
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextFormField(
                        controller: _cityController,
                        labelText: 'Cidade',
                        hintText: 'Nome da cidade',
                        validator: (value) => value?.isEmpty == true ? 'Cidade é obrigatória' : null,
                        prefixIcon: Icons.location_city,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextFormField(
                        controller: _stateController,
                        labelText: 'Estado',
                        hintText: 'SP',
                        validator: (value) => value?.isEmpty == true ? 'Estado é obrigatório' : null,
                        prefixIcon: Icons.map,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveAddress,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  String _getAddressTypeName(AddressType type) {
    switch (type) {
      case AddressType.residential:
        return 'Residencial';
      case AddressType.commercial:
        return 'Comercial';
      case AddressType.billing:
        return 'Cobrança';
      case AddressType.correspondence:
        return 'Correspondência';
    }
  }

  void _onCEPChanged(String value) {
    if (value.length == 9) { // CEP formatado: 00000-000
      _searchCEP();
    }
  }

  Future<void> _searchCEP() async {
    final cep = _zipCodeController.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cep.length != 8) {
      return;
    }
    
    setState(() => _isLoadingCEP = true);
    
    try {
      // Mock CEP search - replace with real ViaCEP API
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data
      setState(() {
        _streetController.text = 'Rua das Flores';
        _neighborhoodController.text = 'Centro';
        _cityController.text = 'São Paulo';
        _stateController.text = 'SP';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Endereço encontrado e preenchido automaticamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CEP não encontrado'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() => _isLoadingCEP = false);
    }
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final address = Address(
        id: widget.address?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedType,
        zipCode: _zipCodeController.text,
        street: _streetController.text,
        number: _numberController.text,
        complement: _complementController.text.isNotEmpty ? _complementController.text : null,
        neighborhood: _neighborhoodController.text,
        city: _cityController.text,
        state: _stateController.text,
        country: 'Brasil',
        isPrimary: widget.address?.isPrimary ?? false,
        isActive: widget.address?.isActive ?? true,
      );
      
      widget.onSave(address);
      Navigator.of(context).pop();
    }
  }
}

class CEPInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length && i < 8; i++) {
      if (i == 5) buffer.write('-');
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}