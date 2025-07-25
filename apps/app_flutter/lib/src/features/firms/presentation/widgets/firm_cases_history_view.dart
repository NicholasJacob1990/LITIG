import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../firms/domain/entities/case_info.dart';

class FirmCasesHistoryView extends StatefulWidget {
  final String firmId;

  const FirmCasesHistoryView({
    super.key,
    required this.firmId,
  });

  @override
  State<FirmCasesHistoryView> createState() => _FirmCasesHistoryViewState();
}

class _FirmCasesHistoryViewState extends State<FirmCasesHistoryView> {
  String _selectedFilter = 'all';
  String _selectedArea = 'all';
  List<CaseInfo> _filteredCases = [];
  final List<CaseInfo> _allCases = _getMockCases();

  @override
  void initState() {
    super.initState();
    _filteredCases = _allCases;
  }

  void _applyFilters() {
    setState(() {
      _filteredCases = _allCases.where((caseInfo) {
        bool statusMatch = _selectedFilter == 'all' || 
                          (_selectedFilter == 'active' && caseInfo.status == CaseStatus.active) ||
                          (_selectedFilter == 'closed' && caseInfo.status == CaseStatus.closed) ||
                          (_selectedFilter == 'won' && caseInfo.status == CaseStatus.won) ||
                          (_selectedFilter == 'lost' && caseInfo.status == CaseStatus.lost);
        
        bool areaMatch = _selectedArea == 'all' || 
                        caseInfo.area.name == _selectedArea;
        
        return statusMatch && areaMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatisticsSection(),
          const SizedBox(height: 24),
          _buildFiltersSection(),
          const SizedBox(height: 24),
          _buildCasesListSection(),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final totalCases = _allCases.length;
    final activeCases = _allCases.where((c) => c.status == CaseStatus.active).length;
    final wonCases = _allCases.where((c) => c.status == CaseStatus.won).length;
    final successRate = totalCases > 0 ? (wonCases / totalCases * 100) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.briefcase, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Estatísticas de Casos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatisticCard(
                    'Total de Casos',
                    totalCases.toString(),
                    LucideIcons.fileText,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatisticCard(
                    'Casos Ativos',
                    activeCases.toString(),
                    LucideIcons.clock,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatisticCard(
                    'Taxa de Sucesso',
                    '${successRate.toStringAsFixed(1)}%',
                    LucideIcons.trendingUp,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Todos')),
                          DropdownMenuItem(value: 'active', child: Text('Ativos')),
                          DropdownMenuItem(value: 'closed', child: Text('Encerrados')),
                          DropdownMenuItem(value: 'won', child: Text('Ganhos')),
                          DropdownMenuItem(value: 'lost', child: Text('Perdidos')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Área', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedArea,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('Todas as áreas')),
                          ...CaseArea.values.map((area) => DropdownMenuItem(
                            value: area.name,
                            child: Text(area.displayName),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedArea = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Mostrando ${_filteredCases.length} de ${_allCases.length} casos',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCasesListSection() {
    if (_filteredCases.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(LucideIcons.search, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Nenhum caso encontrado',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tente ajustar os filtros para ver mais resultados',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histórico de Casos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._filteredCases.map((caseInfo) => _buildCaseCard(caseInfo)),
      ],
    );
  }

  Widget _buildCaseCard(CaseInfo caseInfo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            caseInfo.caseNumber,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(caseInfo.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        caseInfo.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildAreaChip(caseInfo.area),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              caseInfo.summary,
              style: TextStyle(color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(LucideIcons.user, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  caseInfo.clientName,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                Icon(LucideIcons.calendar, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${caseInfo.startDate.day}/${caseInfo.startDate.month}/${caseInfo.startDate.year}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(LucideIcons.dollarSign, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'R\$ ${(caseInfo.caseValue / 1000).toStringAsFixed(0)}k',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            if (caseInfo.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: caseInfo.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(fontSize: 10),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(CaseStatus status) {
    Color color;
    switch (status) {
      case CaseStatus.active:
        color = Colors.blue;
        break;
      case CaseStatus.won:
        color = Colors.green;
        break;
      case CaseStatus.lost:
        color = Colors.red;
        break;
      case CaseStatus.closed:
        color = Colors.grey;
        break;
      case CaseStatus.pending:
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAreaChip(CaseArea area) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        area.displayName,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static List<CaseInfo> _getMockCases() {
    return [
      CaseInfo(
        id: '1',
        caseNumber: '0001234-56.2024.8.26.0100',
        title: 'Ação de Indenização por Danos Morais e Materiais',
        area: CaseArea.civil,
        status: CaseStatus.active,
        startDate: DateTime(2024, 1, 15),
        summary: 'Cliente busca indenização por danos causados em acidente de trânsito. Valor da causa estimado em R\$ 250.000.',
        successProbability: 0.85,
        clientName: 'João Silva Santos',
        caseValue: 250000,
        tags: ['Acidente', 'Trânsito', 'Indenização'],
      ),
      CaseInfo(
        id: '2',
        caseNumber: '0002345-67.2023.8.26.0001',
        title: 'Rescisão Indireta de Contrato de Trabalho',
        area: CaseArea.labor,
        status: CaseStatus.won,
        startDate: DateTime(2023, 8, 20),
        endDate: DateTime(2024, 2, 10),
        summary: 'Funcionário comprova descumprimento das obrigações patronais. Caso encerrado com acordo favorável.',
        successProbability: 0.92,
        clientName: 'Maria Oliveira Costa',
        caseValue: 180000,
        tags: ['Rescisão', 'Acordo', 'Trabalhista'],
      ),
      CaseInfo(
        id: '3',
        caseNumber: '0003456-78.2024.8.26.0224',
        title: 'Constituição de Sociedade Empresária',
        area: CaseArea.corporate,
        status: CaseStatus.closed,
        startDate: DateTime(2024, 3, 5),
        endDate: DateTime(2024, 4, 12),
        summary: 'Assessoria jurídica para constituição de startup no setor de tecnologia. Documentação finalizada.',
        successProbability: 0.98,
        clientName: 'TechStart Ltda.',
        caseValue: 50000,
        tags: ['Startup', 'Constituição', 'Tecnologia'],
      ),
      CaseInfo(
        id: '4',
        caseNumber: '0004567-89.2024.8.26.0063',
        title: 'Defesa em Ação Penal - Crime Tributário',
        area: CaseArea.criminal,
        status: CaseStatus.active,
        startDate: DateTime(2024, 2, 28),
        summary: 'Defesa de empresário acusado de sonegação fiscal. Processo em fase de instrução.',
        successProbability: 0.75,
        clientName: 'Carlos Eduardo Nunes',
        caseValue: 500000,
        tags: ['Crime Tributário', 'Defesa', 'Sonegação'],
      ),
      CaseInfo(
        id: '5',
        caseNumber: '0005678-90.2023.8.26.0114',
        title: 'Divórcio Consensual com Partilha de Bens',
        area: CaseArea.family,
        status: CaseStatus.closed,
        startDate: DateTime(2023, 11, 10),
        endDate: DateTime(2024, 1, 25),
        summary: 'Divórcio amigável com definição de guarda compartilhada e partilha equitativa dos bens.',
        successProbability: 0.95,
        clientName: 'Ana e Roberto Lima',
        caseValue: 120000,
        tags: ['Divórcio', 'Consensual', 'Guarda'],
      ),
    ];
  }
} 