import 'package:flutter/material.dart';
import 'package:meu_app/src/features/cases/domain/entities/lawyer_info.dart';
import 'package:meu_app/src/features/cases/presentation/widgets/case_card.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  String _selectedFilter = 'Todos';

  final List<String> _filters = ['Todos', 'Em Andamento', 'Concluído', 'Aguardando'];

  final List<Map<String, dynamic>> _mockCases = [
    {
      'id': 'case-123',
      'title': 'Rescisão Trabalhista',
      'subtitle': 'Demissão sem justa causa - Cálculo de verbas rescisórias',
      'clientType': 'PF',
      'status': 'Em Andamento',
      'preAnalysisDate': '15/01/2024, 07:30:00',
      'lawyer': LawyerInfo(
        avatarUrl: 'https://i.pravatar.cc/150?u=carlos',
        name: 'Dr. Carlos Mendes',
        specialty: 'Direito Trabalhista',
        unreadMessages: 12,
        createdDate: '14/01/2024',
        pendingDocsText: '',
      ),
    },
    // Adicione mais casos aqui se necessário
  ];

  @override
  Widget build(BuildContext context) {
    final filteredCases = _selectedFilter == 'Todos'
        ? _mockCases
        : _mockCases.where((caseData) => caseData['status'] == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Casos'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: filteredCases.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: filteredCases.length,
                    itemBuilder: (context, index) {
                      final caseData = filteredCases[index];
                      return CaseCard(
                        caseId: caseData['id'],
                        title: caseData['title'],
                        subtitle: caseData['subtitle'],
                        clientType: caseData['clientType'],
                        status: caseData['status'],
                        preAnalysisDate: caseData['preAnalysisDate'],
                        lawyer: caseData['lawyer'],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterSection() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[200],
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.folderX, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Não há casos com status "$_selectedFilter"',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
} 