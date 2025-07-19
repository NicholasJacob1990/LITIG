import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/sla_metrics_entity.dart';
import '../bloc/sla_analytics_bloc.dart';
import '../bloc/sla_analytics_event.dart';
import '../bloc/sla_analytics_state.dart';

class SlaAnalyticsWidget extends StatefulWidget {
  const SlaAnalyticsWidget({super.key});

  @override
  State<SlaAnalyticsWidget> createState() => _SlaAnalyticsWidgetState();
}

class _SlaAnalyticsWidgetState extends State<SlaAnalyticsWidget> {
  DateTimeRange? _selectedDateRange;
  String _selectedFilter = 'all';
  String _selectedChart = 'compliance';

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    _loadAnalytics();
  }

  void _loadAnalytics() {
    context.read<SlaAnalyticsBloc>().add(
      LoadSlaAnalyticsEvent(
        dateRange: _selectedDateRange!,
        filters: {'type': _selectedFilter},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SlaAnalyticsBloc, SlaAnalyticsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildFilters(),
              const SizedBox(height: 24),
              if (state is SlaAnalyticsLoaded) ...[
                _buildKPICards(state.metrics),
                const SizedBox(height: 24),
                _buildChartsSection(state),
                const SizedBox(height: 24),
                _buildRecentViolations(state.recentViolations),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ] else if (state is SlaAnalyticsLoading)
                _buildLoadingState()
              else if (state is SlaAnalyticsError)
                _buildErrorState(state.message)
              else
                _buildInitialState(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'Analytics SLA',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Visualize métricas de performance, compliance e tendências dos SLAs.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Período',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.date_range, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _formatDateRange(),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Todos')),
                          DropdownMenuItem(value: 'normal', child: Text('Normal')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                          DropdownMenuItem(value: 'emergency', child: Text('Emergência')),
                          DropdownMenuItem(value: 'complex', child: Text('Complexo')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedFilter = value!);
                          _loadAnalytics();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _loadAnalytics,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICards(SlaMetricsEntity metrics) {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            'Compliance Geral',
            '${metrics.overallComplianceRate.toStringAsFixed(1)}%',
            Icons.check_circle,
            _getComplianceColor(metrics.overallComplianceRate),
            subtitle: _getComplianceStatus(metrics.overallComplianceRate),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            'Tempo Médio',
            _formatDuration(metrics.averageResponseTime),
            Icons.schedule,
            Colors.blue,
            subtitle: 'Resposta média',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            'Violações',
            '${metrics.totalViolations}',
            Icons.warning,
            Colors.red,
            subtitle: 'No período',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            'Score SLA',
            '${metrics.slaScore}/100',
            Icons.score,
            _getScoreColor(metrics.slaScore),
            subtitle: metrics.scoringLevel,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(SlaAnalyticsLoaded state) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Gráficos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'compliance',
                      label: Text('Compliance'),
                      icon: Icon(Icons.trending_up, size: 16),
                    ),
                    ButtonSegment(
                      value: 'violations',
                      label: Text('Violações'),
                      icon: Icon(Icons.warning, size: 16),
                    ),
                    ButtonSegment(
                      value: 'response_time',
                      label: Text('Tempo'),
                      icon: Icon(Icons.schedule, size: 16),
                    ),
                  ],
                  selected: {_selectedChart},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedChart = selection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: _buildChart(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(SlaAnalyticsLoaded state) {
    switch (_selectedChart) {
      case 'compliance':
        return _buildComplianceChart(state.metrics);
      case 'violations':
        return _buildViolationsChart(state.metrics);
      case 'response_time':
        return _buildResponseTimeChart(state.metrics);
      default:
        return _buildComplianceChart(state.metrics);
    }
  }

  Widget _buildComplianceChart(SlaMetricsEntity metrics) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}d');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: _generateComplianceSpots(metrics),
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationsChart(SlaMetricsEntity metrics) {
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final types = ['Normal', 'Urgente', 'Emerg.', 'Complex'];
                if (value.toInt() < types.length) {
                  return Text(types[value.toInt()]);
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        barGroups: _generateViolationBars(metrics),
      ),
    );
  }

  Widget _buildResponseTimeChart(SlaMetricsEntity metrics) {
    return PieChart(
      PieChartData(
        sections: _generateResponseTimeSections(metrics),
        centerSpaceRadius: 60,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildRecentViolations(List<dynamic> violations) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Violações Recentes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (violations.isEmpty)
              _buildEmptyViolations()
            else
              ...violations.take(5).map((violation) => _buildViolationItem(violation)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyViolations() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: Colors.green[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma violação recente',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.green[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Excelente! Todos os SLAs estão sendo cumpridos.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationItem(dynamic violation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Caso #${violation['caseId'] ?? 'N/A'}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  violation['reason'] ?? 'Violação de SLA',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            _formatTimeAgo(violation['timestamp']),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _exportReport(),
            icon: const Icon(Icons.download),
            label: const Text('Exportar Relatório'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _scheduleReport(),
            icon: const Icon(Icons.schedule),
            label: const Text('Agendar Relatório'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _generateCustomReport(),
            icon: const Icon(Icons.analytics),
            label: const Text('Relatório Customizado'),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando analytics...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.error, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text('Erro ao carregar analytics'),
          const SizedBox(height: 8),
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalytics,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.analytics, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Carregue os analytics para visualizar as métricas'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalytics,
            child: const Text('Carregar Analytics'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatDateRange() {
    if (_selectedDateRange == null) return 'Selecionar período';
    return '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - '
        '${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}';
  }

  Color _getComplianceColor(double rate) {
    if (rate >= 95) return Colors.green;
    if (rate >= 85) return Colors.orange;
    return Colors.red;
  }

  String _getComplianceStatus(double rate) {
    if (rate >= 95) return 'Excelente';
    if (rate >= 85) return 'Bom';
    if (rate >= 70) return 'Aceitável';
    return 'Crítico';
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Agora';
    final date = DateTime.tryParse(timestamp.toString()) ?? DateTime.now();
    final diff = DateTime.now().difference(date);
    
    if (diff.inDays > 0) return '${diff.inDays}d atrás';
    if (diff.inHours > 0) return '${diff.inHours}h atrás';
    return '${diff.inMinutes}m atrás';
  }

  List<FlSpot> _generateComplianceSpots(SlaMetricsEntity metrics) {
    // Generate mock data for demonstration
    return List.generate(30, (index) {
      final base = metrics.overallComplianceRate;
      final variation = (index % 7 - 3) * 2; // ±6% variation
      return FlSpot(index.toDouble(), (base + variation).clamp(0, 100));
    });
  }

  List<BarChartGroupData> _generateViolationBars(SlaMetricsEntity metrics) {
    final data = [5, 3, 8, 2]; // Mock data for each priority type
    return List.generate(4, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data[index].toDouble(),
            color: [Colors.green, Colors.orange, Colors.red, Colors.purple][index],
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  List<PieChartSectionData> _generateResponseTimeSections(SlaMetricsEntity metrics) {
    return [
      PieChartSectionData(
        value: 40,
        title: '< 24h',
        color: Colors.green,
        radius: 100,
      ),
      PieChartSectionData(
        value: 30,
        title: '24-48h',
        color: Colors.orange,
        radius: 100,
      ),
      PieChartSectionData(
        value: 20,
        title: '48-72h',
        color: Colors.red,
        radius: 100,
      ),
      PieChartSectionData(
        value: 10,
        title: '> 72h',
        color: Colors.purple,
        radius: 100,
      ),
    ];
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _loadAnalytics();
    }
  }

  void _exportReport() {
    context.read<SlaAnalyticsBloc>().add(
      ExportSlaReportEvent(
        format: 'pdf',
        dateRange: _selectedDateRange!,
      ),
    );
  }

  void _scheduleReport() {
    // TODO: Implement scheduled reports
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de agendamento em desenvolvimento')),
    );
  }

  void _generateCustomReport() {
    context.read<SlaAnalyticsBloc>().add(
      GenerateCustomSlaReportEvent(
        dateRange: _selectedDateRange!,
        filters: {'type': _selectedFilter},
      ),
    );
  }
} 

class SlaAnalyticsWidget extends StatefulWidget {
  const SlaAnalyticsWidget({super.key});

  @override
  State<SlaAnalyticsWidget> createState() => _SlaAnalyticsWidgetState();
}

class _SlaAnalyticsWidgetState extends State<SlaAnalyticsWidget> {
  DateTimeRange? _selectedDateRange;
  String _selectedFilter = 'all';
  String _selectedChart = 'compliance';

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    _loadAnalytics();
  }

  void _loadAnalytics() {
    context.read<SlaAnalyticsBloc>().add(
      LoadSlaAnalyticsEvent(
        dateRange: _selectedDateRange!,
        filters: {'type': _selectedFilter},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SlaAnalyticsBloc, SlaAnalyticsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildFilters(),
              const SizedBox(height: 24),
              if (state is SlaAnalyticsLoaded) ...[
                _buildKPICards(state.metrics),
                const SizedBox(height: 24),
                _buildChartsSection(state),
                const SizedBox(height: 24),
                _buildRecentViolations(state.recentViolations),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ] else if (state is SlaAnalyticsLoading)
                _buildLoadingState()
              else if (state is SlaAnalyticsError)
                _buildErrorState(state.message)
              else
                _buildInitialState(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'Analytics SLA',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Visualize métricas de performance, compliance e tendências dos SLAs.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Período',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.date_range, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _formatDateRange(),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Todos')),
                          DropdownMenuItem(value: 'normal', child: Text('Normal')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                          DropdownMenuItem(value: 'emergency', child: Text('Emergência')),
                          DropdownMenuItem(value: 'complex', child: Text('Complexo')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedFilter = value!);
                          _loadAnalytics();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _loadAnalytics,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICards(SlaMetricsEntity metrics) {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            'Compliance Geral',
            '${metrics.overallComplianceRate.toStringAsFixed(1)}%',
            Icons.check_circle,
            _getComplianceColor(metrics.overallComplianceRate),
            subtitle: _getComplianceStatus(metrics.overallComplianceRate),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            'Tempo Médio',
            _formatDuration(metrics.averageResponseTime),
            Icons.schedule,
            Colors.blue,
            subtitle: 'Resposta média',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            'Violações',
            '${metrics.totalViolations}',
            Icons.warning,
            Colors.red,
            subtitle: 'No período',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            'Score SLA',
            '${metrics.slaScore}/100',
            Icons.score,
            _getScoreColor(metrics.slaScore),
            subtitle: metrics.scoringLevel,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(SlaAnalyticsLoaded state) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Gráficos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'compliance',
                      label: Text('Compliance'),
                      icon: Icon(Icons.trending_up, size: 16),
                    ),
                    ButtonSegment(
                      value: 'violations',
                      label: Text('Violações'),
                      icon: Icon(Icons.warning, size: 16),
                    ),
                    ButtonSegment(
                      value: 'response_time',
                      label: Text('Tempo'),
                      icon: Icon(Icons.schedule, size: 16),
                    ),
                  ],
                  selected: {_selectedChart},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedChart = selection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: _buildChart(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(SlaAnalyticsLoaded state) {
    switch (_selectedChart) {
      case 'compliance':
        return _buildComplianceChart(state.metrics);
      case 'violations':
        return _buildViolationsChart(state.metrics);
      case 'response_time':
        return _buildResponseTimeChart(state.metrics);
      default:
        return _buildComplianceChart(state.metrics);
    }
  }

  Widget _buildComplianceChart(SlaMetricsEntity metrics) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}d');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: _generateComplianceSpots(metrics),
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationsChart(SlaMetricsEntity metrics) {
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final types = ['Normal', 'Urgente', 'Emerg.', 'Complex'];
                if (value.toInt() < types.length) {
                  return Text(types[value.toInt()]);
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        barGroups: _generateViolationBars(metrics),
      ),
    );
  }

  Widget _buildResponseTimeChart(SlaMetricsEntity metrics) {
    return PieChart(
      PieChartData(
        sections: _generateResponseTimeSections(metrics),
        centerSpaceRadius: 60,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildRecentViolations(List<dynamic> violations) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Violações Recentes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (violations.isEmpty)
              _buildEmptyViolations()
            else
              ...violations.take(5).map((violation) => _buildViolationItem(violation)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyViolations() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: Colors.green[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma violação recente',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.green[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Excelente! Todos os SLAs estão sendo cumpridos.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationItem(dynamic violation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Caso #${violation['caseId'] ?? 'N/A'}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  violation['reason'] ?? 'Violação de SLA',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            _formatTimeAgo(violation['timestamp']),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _exportReport(),
            icon: const Icon(Icons.download),
            label: const Text('Exportar Relatório'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _scheduleReport(),
            icon: const Icon(Icons.schedule),
            label: const Text('Agendar Relatório'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _generateCustomReport(),
            icon: const Icon(Icons.analytics),
            label: const Text('Relatório Customizado'),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando analytics...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.error, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text('Erro ao carregar analytics'),
          const SizedBox(height: 8),
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalytics,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.analytics, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Carregue os analytics para visualizar as métricas'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalytics,
            child: const Text('Carregar Analytics'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatDateRange() {
    if (_selectedDateRange == null) return 'Selecionar período';
    return '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - '
        '${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}';
  }

  Color _getComplianceColor(double rate) {
    if (rate >= 95) return Colors.green;
    if (rate >= 85) return Colors.orange;
    return Colors.red;
  }

  String _getComplianceStatus(double rate) {
    if (rate >= 95) return 'Excelente';
    if (rate >= 85) return 'Bom';
    if (rate >= 70) return 'Aceitável';
    return 'Crítico';
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Agora';
    final date = DateTime.tryParse(timestamp.toString()) ?? DateTime.now();
    final diff = DateTime.now().difference(date);
    
    if (diff.inDays > 0) return '${diff.inDays}d atrás';
    if (diff.inHours > 0) return '${diff.inHours}h atrás';
    return '${diff.inMinutes}m atrás';
  }

  List<FlSpot> _generateComplianceSpots(SlaMetricsEntity metrics) {
    // Generate mock data for demonstration
    return List.generate(30, (index) {
      final base = metrics.overallComplianceRate;
      final variation = (index % 7 - 3) * 2; // ±6% variation
      return FlSpot(index.toDouble(), (base + variation).clamp(0, 100));
    });
  }

  List<BarChartGroupData> _generateViolationBars(SlaMetricsEntity metrics) {
    final data = [5, 3, 8, 2]; // Mock data for each priority type
    return List.generate(4, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data[index].toDouble(),
            color: [Colors.green, Colors.orange, Colors.red, Colors.purple][index],
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  List<PieChartSectionData> _generateResponseTimeSections(SlaMetricsEntity metrics) {
    return [
      PieChartSectionData(
        value: 40,
        title: '< 24h',
        color: Colors.green,
        radius: 100,
      ),
      PieChartSectionData(
        value: 30,
        title: '24-48h',
        color: Colors.orange,
        radius: 100,
      ),
      PieChartSectionData(
        value: 20,
        title: '48-72h',
        color: Colors.red,
        radius: 100,
      ),
      PieChartSectionData(
        value: 10,
        title: '> 72h',
        color: Colors.purple,
        radius: 100,
      ),
    ];
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _loadAnalytics();
    }
  }

  void _exportReport() {
    context.read<SlaAnalyticsBloc>().add(
      ExportSlaReportEvent(
        format: 'pdf',
        dateRange: _selectedDateRange!,
      ),
    );
  }

  void _scheduleReport() {
    // TODO: Implement scheduled reports
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de agendamento em desenvolvimento')),
    );
  }

  void _generateCustomReport() {
    context.read<SlaAnalyticsBloc>().add(
      GenerateCustomSlaReportEvent(
        dateRange: _selectedDateRange!,
        filters: {'type': _selectedFilter},
      ),
    );
  }
} 