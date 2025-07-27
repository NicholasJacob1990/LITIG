import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../firms/domain/entities/partnership_info.dart';

class FirmPartnershipsView extends StatefulWidget {
  final String firmId;

  const FirmPartnershipsView({
    super.key,
    required this.firmId,
  });

  @override
  State<FirmPartnershipsView> createState() => _FirmPartnershipsViewState();
}

class _FirmPartnershipsViewState extends State<FirmPartnershipsView> {
  String _selectedTypeFilter = 'all';
  String _selectedStatusFilter = 'all';
  List<PartnershipInfo> _filteredPartnerships = [];
  final List<PartnershipInfo> _allPartnerships = _getMockPartnerships();

  @override
  void initState() {
    super.initState();
    _filteredPartnerships = _allPartnerships;
  }

  void _applyFilters() {
    setState(() {
      _filteredPartnerships = _allPartnerships.where((partnership) {
        bool typeMatch = _selectedTypeFilter == 'all' || 
                        partnership.type.name == _selectedTypeFilter;
        
        bool statusMatch = _selectedStatusFilter == 'all' || 
                          partnership.status.name == _selectedStatusFilter;
        
        return typeMatch && statusMatch;
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
          _buildPartnershipsOverview(),
          const SizedBox(height: 24),
          _buildFiltersSection(),
          const SizedBox(height: 24),
          _buildPartnershipsList(),
        ],
      ),
    );
  }

  Widget _buildPartnershipsOverview() {
    final totalPartnerships = _allPartnerships.length;
    final activePartnerships = _allPartnerships.where((p) => p.status == PartnershipStatus.active).length;
    final strategicPartnerships = _allPartnerships.where((p) => p.type == PartnershipType.strategic).length;
    final averageScore = _allPartnerships.isNotEmpty 
        ? _allPartnerships.map((p) => p.collaborationScore).reduce((a, b) => a + b) / _allPartnerships.length
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.userCheck, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Visão Geral das Parcerias',
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
                  child: _buildOverviewCard(
                    'Total de Parcerias',
                    totalPartnerships.toString(),
                    LucideIcons.users,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewCard(
                    'Parcerias Ativas',
                    activePartnerships.toString(),
                    LucideIcons.checkCircle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewCard(
                    'Estratégicas',
                    strategicPartnerships.toString(),
                    LucideIcons.target,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewCard(
                    'Score Médio',
                    '${(averageScore * 100).toInt()}%',
                    LucideIcons.trendingUp,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
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
                      const Text('Tipo de Parceria', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedTypeFilter,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('Todos os tipos')),
                          ...PartnershipType.values.map((type) => DropdownMenuItem(
                            value: type.name,
                            child: Text(type.displayName),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTypeFilter = value!;
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
                      const Text('Status', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedStatusFilter,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('Todos os status')),
                          ...PartnershipStatus.values.map((status) => DropdownMenuItem(
                            value: status.name,
                            child: Text(status.displayName),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatusFilter = value!;
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
              'Mostrando ${_filteredPartnerships.length} de ${_allPartnerships.length} parcerias',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnershipsList() {
    if (_filteredPartnerships.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(LucideIcons.search, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma parceria encontrada',
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
          'Lista de Parcerias',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._filteredPartnerships.map((partnership) => _buildPartnershipCard(partnership)),
      ],
    );
  }

  Widget _buildPartnershipCard(PartnershipInfo partnership) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    partnership.partnerName[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            partnership.partnerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          _buildStatusChip(partnership.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildTypeChip(partnership.type),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getScoreColor(partnership.collaborationScore).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.star,
                                  size: 12,
                                  color: _getScoreColor(partnership.collaborationScore),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(partnership.collaborationScore * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getScoreColor(partnership.collaborationScore),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              partnership.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (partnership.benefits.isNotEmpty) ...[
              const Text(
                'Benefícios da Parceria:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: partnership.benefits.map((benefit) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    benefit,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (partnership.sharedAreas.isNotEmpty) ...[
              const Text(
                'Áreas de Colaboração:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: partnership.sharedAreas.map((area) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    area,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Icon(LucideIcons.user, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  partnership.contactPerson,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(LucideIcons.mail, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  partnership.contactEmail,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                Icon(LucideIcons.calendar, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Desde ${partnership.startDate.day}/${partnership.startDate.month}/${partnership.startDate.year}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(PartnershipStatus status) {
    Color color;
    switch (status) {
      case PartnershipStatus.active:
        color = Colors.green;
        break;
      case PartnershipStatus.inactive:
        color = Colors.grey;
        break;
      case PartnershipStatus.pending:
        color = Colors.orange;
        break;
      case PartnershipStatus.suspended:
        color = Colors.red;
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

  Widget _buildTypeChip(PartnershipType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type.displayName,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  static List<PartnershipInfo> _getMockPartnerships() {
    return [
      PartnershipInfo(
        id: '1',
        partnerName: 'Baker McKenzie International',
        partnerLogo: '',
        type: PartnershipType.international,
        status: PartnershipStatus.active,
        startDate: DateTime(2020, 3, 15),
        description: 'Parceria estratégica para assessoria jurídica internacional em operações cross-border e M&A globais.',
        benefits: const ['Acesso a mercados internacionais', 'Know-how em legislação estrangeira', 'Rede global de contatos'],
        sharedAreas: const ['Direito Internacional', 'M&A', 'Compliance Global'],
        contactPerson: 'James Wilson',
        contactEmail: 'j.wilson@bakermckenzie.com',
        collaborationScore: 0.92,
      ),
      PartnershipInfo(
        id: '2',
        partnerName: 'TechLaw Solutions',
        partnerLogo: '',
        type: PartnershipType.technology,
        status: PartnershipStatus.active,
        startDate: DateTime(2022, 8, 10),
        description: 'Parceria tecnológica para desenvolvimento de soluções jurídicas inovadoras e automação de processos.',
        benefits: const ['Automação de processos', 'Inteligência artificial jurídica', 'Análise de dados avançada'],
        sharedAreas: const ['LegalTech', 'Automação', 'Análise de Dados'],
        contactPerson: 'Dr. Ana Silva',
        contactEmail: 'ana.silva@techlawsolutions.com',
        collaborationScore: 0.88,
      ),
      PartnershipInfo(
        id: '3',
        partnerName: 'Universidade de São Paulo - Faculdade de Direito',
        partnerLogo: '',
        type: PartnershipType.academic,
        status: PartnershipStatus.active,
        startDate: DateTime(2019, 2, 20),
        description: 'Parceria acadêmica para pesquisa jurídica, estágios e desenvolvimento de talentos na área do Direito.',
        benefits: const ['Acesso a pesquisas jurídicas', 'Pipeline de talentos', 'Credibilidade acadêmica'],
        sharedAreas: const ['Pesquisa Jurídica', 'Formação Profissional', 'Publicações'],
        contactPerson: 'Prof. Carlos Mendes',
        contactEmail: 'carlos.mendes@usp.br',
        collaborationScore: 0.85,
      ),
      PartnershipInfo(
        id: '4',
        partnerName: 'Escritório Associado Nordeste',
        partnerLogo: '',
        type: PartnershipType.referral,
        status: PartnershipStatus.active,
        startDate: DateTime(2021, 11, 5),
        description: 'Parceria de referência para casos na região Nordeste, fortalecendo nossa presença nacional.',
        benefits: const ['Expansão geográfica', 'Casos regionais', 'Conhecimento local'],
        sharedAreas: const ['Direito Regional', 'Casos Trabalhistas', 'Direito Ambiental'],
        contactPerson: 'Maria Santos',
        contactEmail: 'm.santos@eanordeste.com.br',
        collaborationScore: 0.78,
      ),
      PartnershipInfo(
        id: '5',
        partnerName: 'Corporate Finance Partners',
        partnerLogo: '',
        type: PartnershipType.strategic,
        status: PartnershipStatus.pending,
        startDate: DateTime(2024, 1, 10),
        description: 'Parceria estratégica em desenvolvimento para operações financeiras complexas e reestruturações corporativas.',
        benefits: const ['Expertise financeira', 'Operações complexas', 'Reestruturações'],
        sharedAreas: const ['Direito Financeiro', 'Reestruturação', 'Mercado de Capitais'],
        contactPerson: 'Roberto Lima',
        contactEmail: 'r.lima@cfpartners.com',
        collaborationScore: 0.82,
      ),
      PartnershipInfo(
        id: '6',
        partnerName: 'Green Law Initiative',
        partnerLogo: '',
        type: PartnershipType.commercial,
        status: PartnershipStatus.active,
        startDate: DateTime(2023, 6, 15),
        description: 'Parceria comercial focada em sustentabilidade e direito ambiental, atendendo demandas ESG.',
        benefits: const ['Expertise ESG', 'Sustentabilidade corporativa', 'Compliance ambiental'],
        sharedAreas: const ['Direito Ambiental', 'ESG', 'Sustentabilidade'],
        contactPerson: 'Fernanda Verde',
        contactEmail: 'f.verde@greenlaw.org',
        collaborationScore: 0.90,
      ),
    ];
  }
} 