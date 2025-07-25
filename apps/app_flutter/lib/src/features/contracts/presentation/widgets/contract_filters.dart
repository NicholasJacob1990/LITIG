import 'package:flutter/material.dart';

class ContractFilters extends StatelessWidget {
  final String selectedStatus;
  final TextEditingController searchController;
  final Function(String) onStatusChanged;
  final Function(String) onSearchChanged;

  const ContractFilters({
    super.key,
    required this.selectedStatus,
    required this.searchController,
    required this.onStatusChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de pesquisa
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar contratos...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),
          // Filtros por status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Todos', selectedStatus == 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('pending-signature', 'Aguardando', selectedStatus == 'pending-signature'),
                const SizedBox(width: 8),
                _buildFilterChip('active', 'Ativos', selectedStatus == 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('closed', 'Encerrados', selectedStatus == 'closed'),
                const SizedBox(width: 8),
                _buildFilterChip('canceled', 'Cancelados', selectedStatus == 'canceled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onStatusChanged(value);
        }
      },
      selectedColor: Colors.blue.withValues(alpha: 0.2),
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue[700] : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Colors.blue : Colors.grey[300]!,
        width: 1,
      ),
      backgroundColor: Colors.grey[50],
      elevation: 0,
      pressElevation: 2,
    );
  }
}