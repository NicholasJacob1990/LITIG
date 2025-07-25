import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PremiumCriteriaFormPage extends StatefulWidget {
  final Map<String, dynamic>? criteria;

  const PremiumCriteriaFormPage({super.key, this.criteria});

  @override
  _PremiumCriteriaFormPageState createState() => _PremiumCriteriaFormPageState();
}

class _PremiumCriteriaFormPageState extends State<PremiumCriteriaFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _nameController;
  late final TextEditingController _serviceCodeController;
  late final TextEditingController _subserviceCodeController;
  late final TextEditingController _minValorController;
  late final TextEditingController _maxValorController;
  late final TextEditingController _minUrgencyController;
  
  bool _enabled = true;
  List<String> _selectedComplexity = [];
  List<String> _selectedVipPlans = [];

  final List<String> _complexityOptions = ['LOW', 'MEDIUM', 'HIGH'];
  final List<String> _vipPlanOptions = ['premium', 'gold', 'platinum'];


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.criteria?['name']);
    _serviceCodeController = TextEditingController(text: widget.criteria?['service_code']);
    _subserviceCodeController = TextEditingController(text: widget.criteria?['subservice_code']);
    _minValorController = TextEditingController(text: widget.criteria?['min_valor_causa']?.toString());
    _maxValorController = TextEditingController(text: widget.criteria?['max_valor_causa']?.toString());
    _minUrgencyController = TextEditingController(text: widget.criteria?['min_urgency_h']?.toString());
    _enabled = widget.criteria?['enabled'] ?? true;
    
    if (widget.criteria?['complexity_levels'] != null) {
      _selectedComplexity = List<String>.from(widget.criteria!['complexity_levels']);
    }
    if (widget.criteria?['vip_client_plans'] != null) {
      _selectedVipPlans = List<String>.from(widget.criteria!['vip_client_plans']);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serviceCodeController.dispose();
    _subserviceCodeController.dispose();
    _minValorController.dispose();
    _maxValorController.dispose();
    _minUrgencyController.dispose();
    super.dispose();
  }

  Future<void> _saveCriteria() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      try {
        final data = {
          'name': _nameController.text,
          'service_code': _serviceCodeController.text,
          'subservice_code': _subserviceCodeController.text.isNotEmpty ? _subserviceCodeController.text : null,
          'enabled': _enabled,
          'min_valor_causa': _minValorController.text.isNotEmpty ? double.tryParse(_minValorController.text) : null,
          'max_valor_causa': _maxValorController.text.isNotEmpty ? double.tryParse(_maxValorController.text) : null,
          'min_urgency_h': _minUrgencyController.text.isNotEmpty ? int.tryParse(_minUrgencyController.text) : null,
          'complexity_levels': _selectedComplexity,
          'vip_client_plans': _selectedVipPlans,
        };

        if (widget.criteria == null) {
          // Create
          await Supabase.instance.client.from('premium_criteria').insert(data);
        } else {
          // Update
          await Supabase.instance.client.from('premium_criteria').update(data).eq('id', widget.criteria!['id']);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Critério salvo com sucesso!'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop();

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar critério: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      } finally {
        setState(() { _isLoading = false; });
      }
    }
  }

  Widget _buildChipGroup(String title, List<String> options, List<String> selected, ValueChanged<String> onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onSelected(option),
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.criteria == null ? 'Novo Critério' : 'Editar Critério'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveCriteria,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nome da Regra'),
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _serviceCodeController,
                    decoration: const InputDecoration(labelText: 'Área Jurídica (service_code)'),
                     validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _subserviceCodeController,
                    decoration: const InputDecoration(labelText: 'Subárea (opcional)'),
                  ),
                   const SizedBox(height: 16),
                  TextFormField(
                    controller: _minValorController,
                    decoration: const InputDecoration(labelText: 'Valor Mínimo da Causa'),
                    keyboardType: TextInputType.number,
                  ),
                   const SizedBox(height: 16),
                  TextFormField(
                    controller: _maxValorController,
                    decoration: const InputDecoration(labelText: 'Valor Máximo da Causa'),
                    keyboardType: TextInputType.number,
                  ),
                   const SizedBox(height: 16),
                  TextFormField(
                    controller: _minUrgencyController,
                    decoration: const InputDecoration(labelText: 'Urgência Mínima (horas)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Ativo'),
                    value: _enabled,
                    onChanged: (value) => setState(() => _enabled = value),
                  ),
                  const SizedBox(height: 24),
                  _buildChipGroup(
                    'Níveis de Complexidade',
                    _complexityOptions,
                    _selectedComplexity,
                    (option) {
                      setState(() {
                        if (_selectedComplexity.contains(option)) {
                          _selectedComplexity.remove(option);
                        } else {
                          _selectedComplexity.add(option);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildChipGroup(
                    'Planos VIP de Cliente',
                    _vipPlanOptions,
                    _selectedVipPlans,
                    (option) {
                      setState(() {
                        if (_selectedVipPlans.contains(option)) {
                          _selectedVipPlans.remove(option);
                        } else {
                          _selectedVipPlans.add(option);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
    );
  }
} 