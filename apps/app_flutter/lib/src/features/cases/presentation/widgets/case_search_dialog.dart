import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/cases_bloc.dart';

class CaseSearchDialog extends StatefulWidget {
  final Function(CaseSearchFilters) onSearch;
  final CaseSearchFilters? initialFilters;
  
  const CaseSearchDialog({
    super.key,
    required this.onSearch,
    this.initialFilters,
  });

  @override
  State<CaseSearchDialog> createState() => _CaseSearchDialogState();
}

class _CaseSearchDialogState extends State<CaseSearchDialog> {
  final _searchController = TextEditingController();
  final _clientController = TextEditingController();
  final _lawyerController = TextEditingController();
  
  String? _selectedStatus;
  String? _selectedCategory;
  String? _selectedPriority;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  double? _minValue;
  double? _maxValue;
  
  final List<String> _statusOptions = [
    'Todos',
    'Em Análise',
    'Em Andamento', 
    'Aguardando Cliente',
    'Aguardando Tribunal',
    'Concluído',
    'Cancelado',
  ];
  
  final List<String> _categoryOptions = [
    'Todas',
    'Direito Civil',
    'Direito Criminal',
    'Direito Trabalhista',
    'Direito Empresarial',
    'Direito de Família',
    'Direito Tributário',
  ];
  
  final List<String> _priorityOptions = [
    'Todas',
    'Baixa',
    'Média',
    'Alta',
    'Urgente',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  void _initializeFilters() {
    if (widget.initialFilters != null) {
      final filters = widget.initialFilters!;
      _searchController.text = filters.searchQuery ?? '';
      _clientController.text = filters.clientName ?? '';
      _lawyerController.text = filters.lawyerName ?? '';
      _selectedStatus = filters.status;
      _selectedCategory = filters.category;
      _selectedPriority = filters.priority;
      _dateFrom = filters.dateFrom;
      _dateTo = filters.dateTo;
      _minValue = filters.minValue;
      _maxValue = filters.maxValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(LucideIcons.search),
          const SizedBox(width: 8),
          const Text('Busca Avançada'),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.x),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchField(),
              const SizedBox(height: 16),
              _buildPersonFields(),
              const SizedBox(height: 16),
              _buildDropdownFilters(),
              const SizedBox(height: 16),
              _buildDateFilters(),
              const SizedBox(height: 16),
              _buildValueFilters(),
              const SizedBox(height: 16),
              _buildQuickFilters(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _clearFilters,
          child: const Text('Limpar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _performSearch,
          icon: const Icon(LucideIcons.search),
          label: const Text('Buscar'),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        labelText: 'Buscar por título ou ID do caso',
        hintText: 'Digite o termo de busca...',
        prefixIcon: Icon(LucideIcons.search),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPersonFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pessoas Envolvidas',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _clientController,
                decoration: const InputDecoration(
                  labelText: 'Cliente',
                  prefixIcon: Icon(LucideIcons.user),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _lawyerController,
                decoration: const InputDecoration(
                  labelText: 'Advogado',
                  prefixIcon: Icon(LucideIcons.userCheck),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtros',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: _statusOptions.map((status) => 
                  DropdownMenuItem(value: status, child: Text(status))
                ).toList(),
                onChanged: (value) => setState(() => _selectedStatus = value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Área do Direito',
                  border: OutlineInputBorder(),
                ),
                items: _categoryOptions.map((category) => 
                  DropdownMenuItem(value: category, child: Text(category))
                ).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedPriority,
          decoration: const InputDecoration(
            labelText: 'Prioridade',
            border: OutlineInputBorder(),
          ),
          items: _priorityOptions.map((priority) => 
            DropdownMenuItem(value: priority, child: Text(priority))
          ).toList(),
          onChanged: (value) => setState(() => _selectedPriority = value),
        ),
      ],
    );
  }

  Widget _buildDateFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Período',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data Inicial',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(LucideIcons.calendar),
                  ),
                  child: Text(
                    _dateFrom != null ? _formatDate(_dateFrom!) : 'Selecionar',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data Final',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(LucideIcons.calendar),
                  ),
                  child: Text(
                    _dateTo != null ? _formatDate(_dateTo!) : 'Selecionar',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValueFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valor da Causa',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor Mínimo',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _minValue = double.tryParse(value.replaceAll(',', '.'));
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor Máximo',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _maxValue = double.tryParse(value.replaceAll(',', '.'));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtros Rápidos',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickFilterChip('Casos Urgentes', LucideIcons.alertCircle),
            _buildQuickFilterChip('Esta Semana', LucideIcons.clock),
            _buildQuickFilterChip('Em Andamento', LucideIcons.play),
            _buildQuickFilterChip('Vencendo', LucideIcons.alertTriangle),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFilterChip(String label, IconData icon) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          _applyQuickFilter(label);
        }
      },
    );
  }

  void _selectDate(bool isStartDate) async {
    final result = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (result != null) {
      setState(() {
        if (isStartDate) {
          _dateFrom = result;
        } else {
          _dateTo = result;
        }
      });
    }
  }

  void _applyQuickFilter(String filterType) {
    switch (filterType) {
      case 'Casos Urgentes':
        setState(() => _selectedPriority = 'Urgente');
        break;
      case 'Esta Semana':
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        setState(() {
          _dateFrom = startOfWeek;
          _dateTo = now;
        });
        break;
      case 'Em Andamento':
        setState(() => _selectedStatus = 'Em Andamento');
        break;
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _clientController.clear();
      _lawyerController.clear();
      _selectedStatus = null;
      _selectedCategory = null;
      _selectedPriority = null;
      _dateFrom = null;
      _dateTo = null;
      _minValue = null;
      _maxValue = null;
    });
  }

  void _performSearch() {
    final filters = CaseSearchFilters(
      searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
      clientName: _clientController.text.isEmpty ? null : _clientController.text,
      lawyerName: _lawyerController.text.isEmpty ? null : _lawyerController.text,
      status: _selectedStatus == 'Todos' ? null : _selectedStatus,
      category: _selectedCategory == 'Todas' ? null : _selectedCategory,
      priority: _selectedPriority == 'Todas' ? null : _selectedPriority,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      minValue: _minValue,
      maxValue: _maxValue,
    );
    
    widget.onSearch(filters);
    Navigator.of(context).pop();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _clientController.dispose();
    _lawyerController.dispose();
    super.dispose();
  }
}