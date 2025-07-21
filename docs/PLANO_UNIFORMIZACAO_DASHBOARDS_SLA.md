# Plano de Uniformização dos Dashboards com Sistema SLA Integrado - LITIG-1

## 🎯 Objetivo Estratégico

Criar uma experiência consistente e intuitiva em todos os dashboards de advogados, integrando o sistema SLA de forma contextual e implementando um sistema de exportação em nuvem moderno, transformando o LITIG-1 em uma plataforma SaaS de referência no setor jurídico.

## 📊 Análise do Estado Atual

### Pontos Fortes Identificados
✅ **Separação clara de contextos** por tipo de usuário  
✅ **Implementação modular** com BLoC pattern  
✅ **Interface Material Design 3** consistente  
✅ **Navegação role-based** bem estruturada  

### Problemas Críticos Identificados
❌ **Dados mockados** em todos os dashboards  
❌ **Inconsistência visual** entre diferentes dashboards  
❌ **Falta de integração SLA** contextual  
❌ **Ausência de sistema de exportação** moderno  
❌ **Loading states** inadequados  
❌ **Responsividade** limitada  

## 🎨 Design System Unificado

### 1. Componentes Base Padronizados

```dart
// Dashboard Card Unificado
class UnifiedDashboardCard extends StatelessWidget {
  final String title;
  final Widget content;
  final List<ActionItem>? actions;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final SlaStatus? slaStatus; // Integração SLA contextual

  const UnifiedDashboardCard({
    Key? key,
    required this.title,
    required this.content,
    this.actions,
    this.isLoading = false,
    this.onRefresh,
    this.slaStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Header unificado com SLA
          UnifiedCardHeader(
            title: title,
            actions: actions,
            slaStatus: slaStatus,
            onRefresh: onRefresh,
          ),
          
          // Conteúdo com loading state
          if (isLoading)
            UnifiedSkeletonLoader()
          else
            Padding(
              padding: EdgeInsets.all(16),
              child: content,
            ),
        ],
      ),
    );
  }
}

// KPI Card Padronizado
class UnifiedKPICard extends StatelessWidget {
  final String title;
  final String value;
  final String? trend;
  final IconData icon;
  final Color color;
  final SlaCompliance? slaCompliance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: slaCompliance?.isAtRisk == true 
              ? Colors.red.withOpacity(0.3) 
              : color.withOpacity(0.2),
            width: slaCompliance?.isAtRisk == true ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com ícone e status SLA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                if (slaCompliance != null)
                  SlaStatusIndicator(
                    status: slaCompliance!.status,
                    size: SlaIndicatorSize.small,
                  ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Título
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 4),
            
            // Valor principal
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Trend indicator
            if (trend != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    trend!.startsWith('+') ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: trend!.startsWith('+') ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 4),
                  Text(
                    trend!,
                    style: TextStyle(
                      fontSize: 12,
                      color: trend!.startsWith('+') ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 2. Sistema de Cores Contextual

```dart
class DashboardTheme {
  // Cores principais por contexto
  static const Map<UserRole, DashboardColorScheme> colorSchemes = {
    UserRole.lawyerAssociated: DashboardColorScheme(
      primary: Color(0xFF1976D2),      // Azul profissional
      secondary: Color(0xFF42A5F5),    // Azul claro
      accent: Color(0xFF66BB6A),       // Verde produtividade
      warning: Color(0xFFFF9800),      // Laranja alertas
    ),
    
    UserRole.lawyerOffice: DashboardColorScheme(
      primary: Color(0xFF7B1FA2),      // Roxo executivo
      secondary: Color(0xFF9C27B0),    // Roxo claro
      accent: Color(0xFF4CAF50),       // Verde faturamento
      warning: Color(0xFFE91E63),      // Rosa crítico
    ),
    
    UserRole.lawyerIndividual: DashboardColorScheme(
      primary: Color(0xFF388E3C),      // Verde negócios
      secondary: Color(0xFF66BB6A),    // Verde claro
      accent: Color(0xFF2196F3),       // Azul oportunidades
      warning: Color(0xFFFF5722),      // Vermelho urgente
    ),
    
    UserRole.lawyerPlatformAssociate: DashboardColorScheme(
      primary: Color(0xFF0288D1),      // Azul platform
      secondary: Color(0xFF29B6F6),    // Azul claro
      accent: Color(0xFF00C853),       // Verde pessoal
      warning: Color(0xFFFF6F00),      // Laranja administrativo
    ),
  };
}

class DashboardColorScheme {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color warning;
  
  const DashboardColorScheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.warning,
  });
}
```

## 🔄 Sistema SLA Integrado Contextualmente

### 1. Integração por Tipo de Usuário

```dart
// SLA Contextual para Advogado Associado
class LawyerAssociatedSlaIntegration {
  static List<SlaMetric> getContextualMetrics() {
    return [
      SlaMetric(
        id: 'case_response_time',
        title: 'Tempo Resposta Casos',
        description: 'Tempo médio para primeira resposta em novos casos',
        target: Duration(hours: 4),
        current: Duration(hours: 2, minutes: 30),
        priority: SlaMetricPriority.high,
      ),
      SlaMetric(
        id: 'task_completion',
        title: 'Conclusão de Tarefas',
        description: 'Tarefas concluídas dentro do prazo estabelecido',
        target: 0.95, // 95%
        current: 0.87, // 87%
        priority: SlaMetricPriority.critical,
      ),
      SlaMetric(
        id: 'client_communication',
        title: 'Comunicação Cliente',
        description: 'Frequência de comunicação com clientes ativos',
        target: Duration(days: 3),
        current: Duration(days: 2),
        priority: SlaMetricPriority.medium,
      ),
    ];
  }
}

// SLA Contextual para Sócio de Escritório
class LawyerOfficeSlaIntegration {
  static List<SlaMetric> getContextualMetrics() {
    return [
      SlaMetric(
        id: 'team_productivity',
        title: 'Produtividade da Equipe',
        description: 'Meta de produtividade consolidada da equipe',
        target: 0.85,
        current: 0.92,
        priority: SlaMetricPriority.high,
      ),
      SlaMetric(
        id: 'revenue_targets',
        title: 'Metas de Faturamento',
        description: 'Cumprimento das metas mensais de receita',
        target: 150000.0,
        current: 145000.0,
        priority: SlaMetricPriority.critical,
      ),
      SlaMetric(
        id: 'client_satisfaction',
        title: 'Satisfação do Cliente',
        description: 'Índice de satisfação geral dos clientes',
        target: 4.5,
        current: 4.7,
        priority: SlaMetricPriority.medium,
      ),
    ];
  }
}

// SLA Contextual para Advogado Contratante
class LawyerContractorSlaIntegration {
  static List<SlaMetric> getContextualMetrics() {
    return [
      SlaMetric(
        id: 'lead_response',
        title: 'Resposta a Leads',
        description: 'Tempo para primeira resposta a novos leads',
        target: Duration(hours: 2),
        current: Duration(hours: 1, minutes: 15),
        priority: SlaMetricPriority.critical,
      ),
      SlaMetric(
        id: 'proposal_delivery',
        title: 'Entrega de Propostas',
        description: 'Prazo para entrega de propostas comerciais',
        target: Duration(days: 2),
        current: Duration(days: 1, hours: 8),
        priority: SlaMetricPriority.high,
      ),
      SlaMetric(
        id: 'partnership_maintenance',
        title: 'Manutenção Parcerias',
        description: 'Frequência de contato com parceiros ativos',
        target: Duration(days: 14),
        current: Duration(days: 10),
        priority: SlaMetricPriority.medium,
      ),
    ];
  }
}
```

### 2. Widget SLA Dashboard Unificado

```dart
class UnifiedSlaDashboard extends StatelessWidget {
  final UserRole userRole;
  final List<SlaMetric> metrics;
  final Function(SlaMetric)? onMetricTap;

  const UnifiedSlaDashboard({
    Key? key,
    required this.userRole,
    required this.metrics,
    this.onMetricTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = DashboardTheme.colorSchemes[userRole]!;
    
    return UnifiedDashboardCard(
      title: 'Indicadores SLA',
      actions: [
        ActionItem(
          icon: Icons.settings,
          onTap: () => _openSlaSettings(context),
        ),
        ActionItem(
          icon: Icons.analytics,
          onTap: () => _openSlaAnalytics(context),
        ),
        ActionItem(
          icon: Icons.cloud_upload,
          onTap: () => _openCloudExport(context),
        ),
      ],
      content: Column(
        children: [
          // SLA Overview
          SlaOverviewSection(
            metrics: metrics,
            colorScheme: colorScheme,
          ),
          
          SizedBox(height: 16),
          
          // SLA Metrics Grid
          SlaMetricsGrid(
            metrics: metrics,
            onMetricTap: onMetricTap,
            colorScheme: colorScheme,
          ),
          
          SizedBox(height: 16),
          
          // Quick Actions
          SlaQuickActions(
            userRole: userRole,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

class SlaOverviewSection extends StatelessWidget {
  final List<SlaMetric> metrics;
  final DashboardColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final overallCompliance = _calculateOverallCompliance(metrics);
    final atRiskCount = metrics.where((m) => m.isAtRisk).length;
    
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.1),
                  colorScheme.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Compliance Geral',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 8),
                CircularPercentIndicator(
                  radius: 30,
                  percent: overallCompliance,
                  center: Text(
                    '${(overallCompliance * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  progressColor: overallCompliance > 0.8 
                    ? Colors.green 
                    : overallCompliance > 0.6 
                      ? Colors.orange 
                      : Colors.red,
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(width: 16),
        
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (atRiskCount > 0 ? Colors.red : Colors.green).withOpacity(0.1),
                  (atRiskCount > 0 ? Colors.red : Colors.green).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Indicadores em Risco',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      atRiskCount > 0 ? Icons.warning : Icons.check_circle,
                      color: atRiskCount > 0 ? Colors.red : Colors.green,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '$atRiskCount de ${metrics.length}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: atRiskCount > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

## 🌐 Sistema de Exportação em Nuvem Integrado

### 1. Arquitetura de Exportação Unificada

```dart
class UnifiedCloudExportSystem {
  // Exportação contextual por dashboard
  static CloudExportConfig getExportConfigForRole(UserRole role) {
    switch (role) {
      case UserRole.lawyerAssociated:
        return CloudExportConfig(
          availableTemplates: [
            ExportTemplate.personalProductivity,
            ExportTemplate.caseProgressReport,
            ExportTemplate.slaCompliancePersonal,
          ],
          defaultDestinations: [CloudProvider.googleDrive],
          automationLevel: AutomationLevel.basic,
        );
        
      case UserRole.lawyerOffice:
        return CloudExportConfig(
          availableTemplates: [
            ExportTemplate.executiveDashboard,
            ExportTemplate.teamPerformanceReport,
            ExportTemplate.financialSummary,
            ExportTemplate.firmSlaAnalytics,
          ],
          defaultDestinations: [
            CloudProvider.googleDrive,
            CloudProvider.oneDrive,
            CloudProvider.dropbox,
          ],
          automationLevel: AutomationLevel.advanced,
        );
        
      case UserRole.lawyerIndividual:
      case UserRole.lawyerPlatformAssociate:
        return CloudExportConfig(
          availableTemplates: [
            ExportTemplate.businessDevelopment,
            ExportTemplate.clientAcquisition,
            ExportTemplate.partnershipReport,
            ExportTemplate.revenueAnalysis,
          ],
          defaultDestinations: [
            CloudProvider.googleDrive,
            CloudProvider.googleSheets,
            CloudProvider.aws,
          ],
          automationLevel: AutomationLevel.professional,
        );
    }
  }
}

// Widget de Exportação Contextual
class ContextualCloudExportWidget extends StatefulWidget {
  final UserRole userRole;
  final Map<String, dynamic> dashboardData;
  final List<SlaMetric> slaMetrics;

  @override
  Widget build(BuildContext context) {
    final exportConfig = UnifiedCloudExportSystem.getExportConfigForRole(userRole);
    
    return UnifiedDashboardCard(
      title: 'Exportação & Compartilhamento',
      actions: [
        ActionItem(
          icon: Icons.history,
          onTap: () => _showExportHistory(context),
        ),
      ],
      content: Column(
        children: [
          // Quick Export Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.email),
                  label: Text('Enviar por E-mail'),
                  onPressed: () => _startEmailExport(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardTheme.colorSchemes[userRole]!.primary,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.share),
                  label: Text('Compartilhar Link'),
                  onPressed: () => _generateShareableLink(context),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Template Selection
          Text(
            'Templates Disponíveis',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          
          SizedBox(height: 12),
          
          ...exportConfig.availableTemplates.map((template) => 
            TemplateQuickCard(
              template: template,
              onExport: () => _exportWithTemplate(template),
              onSchedule: () => _scheduleExport(template),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Cloud Providers Status
          CloudProvidersStatus(
            providers: exportConfig.defaultDestinations,
            onConfigure: (provider) => _configureProvider(provider),
          ),
        ],
      ),
    );
  }
}
```

### 2. Templates de Exportação Específicos

```dart
enum ExportTemplate {
  // Para Advogados Associados
  personalProductivity('Produtividade Pessoal', {
    'sections': ['kpis_pessoais', 'casos_ativos', 'sla_compliance', 'metas_cumpridas'],
    'charts': ['productivity_trend', 'case_distribution', 'sla_radar'],
    'format': 'personal_report',
    'frequency': 'weekly',
  }),
  
  caseProgressReport('Relatório de Casos', {
    'sections': ['casos_em_andamento', 'prazos_proximos', 'clientes_atendidos'],
    'charts': ['case_timeline', 'client_satisfaction', 'workload_distribution'],
    'format': 'professional_report',
    'frequency': 'biweekly',
  }),
  
  // Para Sócios de Escritório
  executiveDashboard('Dashboard Executivo', {
    'sections': ['visao_geral_firma', 'performance_equipe', 'financeiro', 'sla_organizacional'],
    'charts': ['revenue_trends', 'team_performance_matrix', 'client_retention'],
    'format': 'executive_summary',
    'frequency': 'monthly',
  }),
  
  teamPerformanceReport('Performance da Equipe', {
    'sections': ['produtividade_individual', 'colaboracao', 'desenvolvimento'],
    'charts': ['individual_metrics', 'collaboration_network', 'skill_development'],
    'format': 'management_report',
    'frequency': 'monthly',
  }),
  
  // Para Advogados Contratantes
  businessDevelopment('Desenvolvimento de Negócios', {
    'sections': ['captacao_clientes', 'pipeline_comercial', 'conversao_leads'],
    'charts': ['sales_funnel', 'conversion_rates', 'revenue_forecast'],
    'format': 'business_report',
    'frequency': 'weekly',
  }),
  
  clientAcquisition('Aquisição de Clientes', {
    'sections': ['novos_clientes', 'fontes_aquisicao', 'custo_aquisicao'],
    'charts': ['acquisition_trends', 'source_analysis', 'lifetime_value'],
    'format': 'marketing_report',
    'frequency': 'monthly',
  });
}

// Gerador de Templates Contextuais
class ContextualTemplateGenerator {
  static Future<ExportData> generateTemplate(
    ExportTemplate template,
    UserRole userRole,
    Map<String, dynamic> dashboardData,
    List<SlaMetric> slaMetrics,
  ) async {
    switch (template) {
      case ExportTemplate.personalProductivity:
        return _generatePersonalProductivityReport(dashboardData, slaMetrics);
        
      case ExportTemplate.executiveDashboard:
        return _generateExecutiveDashboard(dashboardData, slaMetrics);
        
      case ExportTemplate.businessDevelopment:
        return _generateBusinessDevelopmentReport(dashboardData, slaMetrics);
        
      // ... outros templates
    }
  }
  
  static ExportData _generatePersonalProductivityReport(
    Map<String, dynamic> data, 
    List<SlaMetric> slaMetrics,
  ) {
    return ExportData(
      title: 'Relatório de Produtividade Pessoal',
      subtitle: 'Período: ${DateFormat('MMMM yyyy', 'pt_BR').format(DateTime.now())}',
      sections: [
        ExportSection(
          title: 'Resumo Executivo',
          content: _buildProductivitySummary(data),
          charts: [
            ChartData(
              type: ChartType.gauge,
              title: 'Produtividade Geral',
              data: data['productivity_score'],
            ),
          ],
        ),
        ExportSection(
          title: 'Compliance SLA',
          content: _buildSlaCompliance(slaMetrics),
          charts: [
            ChartData(
              type: ChartType.radar,
              title: 'SLA por Categoria',
              data: slaMetrics.map((m) => m.complianceScore).toList(),
            ),
          ],
        ),
        ExportSection(
          title: 'Casos Ativos',
          content: _buildActiveCases(data['active_cases']),
          charts: [
            ChartData(
              type: ChartType.timeline,
              title: 'Timeline de Casos',
              data: data['case_timeline'],
            ),
          ],
        ),
      ],
      metadata: ExportMetadata(
        generatedAt: DateTime.now(),
        generatedBy: data['user_name'],
        template: ExportTemplate.personalProductivity,
        version: '1.0',
      ),
    );
  }
}
```

### 3. Integração com Google Sheets Avançada

```dart
class GoogleSheetsAdvancedIntegration {
  static Future<void> setupIntelligentSync(
    UserRole userRole,
    List<SlaMetric> slaMetrics,
    Map<String, dynamic> dashboardData,
  ) async {
    // Configuração específica por role
    final sheetConfig = _getSheetConfigForRole(userRole);
    
    // Criar planilha com estrutura inteligente
    final spreadsheet = await GoogleSheetsAPI.createSpreadsheet(
      title: '${userRole.displayName} Dashboard - ${DateFormat('MMM yyyy').format(DateTime.now())}',
      sheets: sheetConfig.sheets,
    );
    
    // Configurar fórmulas automáticas
    await _setupAutoFormulas(spreadsheet, sheetConfig);
    
    // Configurar formatação condicional
    await _setupConditionalFormatting(spreadsheet, slaMetrics);
    
    // Configurar gráficos automáticos
    await _setupAutoCharts(spreadsheet, userRole);
    
    // Configurar sincronização em tempo real
    await _setupRealTimeSync(spreadsheet, userRole);
  }
  
  static SheetConfiguration _getSheetConfigForRole(UserRole role) {
    switch (role) {
      case UserRole.lawyerAssociated:
        return SheetConfiguration(
          sheets: [
            SheetDefinition(
              name: 'Dashboard Pessoal',
              columns: ['Data', 'Casos Ativos', 'SLA Compliance', 'Produtividade', 'Alertas'],
              dataTypes: [DataType.date, DataType.number, DataType.percentage, DataType.percentage, DataType.number],
            ),
            SheetDefinition(
              name: 'SLA Detalhado',
              columns: ['Métrica', 'Target', 'Atual', 'Status', 'Trend'],
              dataTypes: [DataType.text, DataType.number, DataType.number, DataType.text, DataType.text],
            ),
          ],
        );
        
      case UserRole.lawyerOffice:
        return SheetConfiguration(
          sheets: [
            SheetDefinition(
              name: 'Dashboard Executivo',
              columns: ['Data', 'Equipe', 'Faturamento', 'Satisfação Cliente', 'SLA Geral'],
              dataTypes: [DataType.date, DataType.number, DataType.currency, DataType.rating, DataType.percentage],
            ),
            SheetDefinition(
              name: 'Performance Equipe',
              columns: ['Advogado', 'Casos', 'Produtividade', 'SLA Individual', 'Rating'],
              dataTypes: [DataType.text, DataType.number, DataType.percentage, DataType.percentage, DataType.rating],
            ),
            SheetDefinition(
              name: 'Análise Financeira',
              columns: ['Mês', 'Receita', 'Custos', 'Margem', 'Projeção'],
              dataTypes: [DataType.text, DataType.currency, DataType.currency, DataType.percentage, DataType.currency],
            ),
          ],
        );
        
      // ... outras configurações
    }
  }
  
  static Future<void> _setupAutoFormulas(
    GoogleSpreadsheet spreadsheet, 
    SheetConfiguration config,
  ) async {
    // Fórmulas para cálculos automáticos
    final formulas = {
      // SLA Compliance médio
      'sla_average': '=AVERAGE(C2:C1000)',
      
      // Tendência de produtividade
      'productivity_trend': '=SLOPE(D2:D30,A2:A30)',
      
      // Alertas automáticos
      'alert_count': '=COUNTIF(E2:E1000,">0")',
      
      // Projeções futuras
      'next_month_projection': '=FORECAST(TODAY()+30,B2:B30,A2:A30)',
    };
    
    for (final entry in formulas.entries) {
      await spreadsheet.updateCell(
        sheetName: config.sheets.first.name,
        cell: entry.key,
        value: entry.value,
      );
    }
  }
  
  static Future<void> _setupConditionalFormatting(
    GoogleSpreadsheet spreadsheet,
    List<SlaMetric> slaMetrics,
  ) async {
    // Formatação condicional para SLA
    await spreadsheet.addConditionalFormatRule(
      sheetName: 'Dashboard Pessoal',
      range: 'C2:C1000',
      rules: [
        ConditionalFormatRule(
          condition: '>= 0.95',
          format: CellFormat(backgroundColor: Colors.green.shade100),
        ),
        ConditionalFormatRule(
          condition: '>= 0.80',
          format: CellFormat(backgroundColor: Colors.yellow.shade100),
        ),
        ConditionalFormatRule(
          condition: '< 0.80',
          format: CellFormat(backgroundColor: Colors.red.shade100),
        ),
      ],
    );
  }
}
```

## 📱 Layouts Responsivos Unificados

### 1. Sistema de Breakpoints

```dart
class ResponsiveDashboardLayout extends StatelessWidget {
  final UserRole userRole;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile: < 600px
        if (constraints.maxWidth < 600) {
          return MobileDashboardLayout(
            userRole: userRole,
            sections: sections,
          );
        }
        // Tablet: 600-1200px
        else if (constraints.maxWidth < 1200) {
          return TabletDashboardLayout(
            userRole: userRole,
            sections: sections,
          );
        }
        // Desktop: > 1200px
        else {
          return DesktopDashboardLayout(
            userRole: userRole,
            sections: sections,
          );
        }
      },
    );
  }
}

class MobileDashboardLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header com SLA quick view
            DashboardHeader(userRole: userRole),
            
            SizedBox(height: 16),
            
            // SLA Overview compacto
            CompactSlaOverview(userRole: userRole),
            
            SizedBox(height: 16),
            
            // Seções empilhadas verticalmente
            ...sections.map((section) => Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: section,
            )),
            
            // Export section sempre no final
            CloudExportSection(userRole: userRole),
          ],
        ),
      ),
    );
  }
}

class TabletDashboardLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar com navegação SLA
        Container(
          width: 280,
          child: DashboardSidebar(
            userRole: userRole,
            slaMetrics: slaMetrics,
          ),
        ),
        
        // Conteúdo principal em grid 2x2
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: sections,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DesktopDashboardLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar expandida com analytics
        Container(
          width: 320,
          child: ExpandedDashboardSidebar(
            userRole: userRole,
            slaMetrics: slaMetrics,
            showAnalytics: true,
          ),
        ),
        
        // Conteúdo principal em grid flexível
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(32),
              child: StaggeredGrid.count(
                crossAxisCount: 4,
                children: [
                  // SLA overview span 2 colunas
                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 1,
                    child: sections[0],
                  ),
                  
                  // Métricas principais
                  ...sections.skip(1).take(4).map((section) => 
                    StaggeredGridTile.count(
                      crossAxisCellCount: 1,
                      mainAxisCellCount: 1,
                      child: section,
                    ),
                  ),
                  
                  // Seções grandes span 2 colunas
                  ...sections.skip(5).map((section) => 
                    StaggeredGridTile.count(
                      crossAxisCellCount: 2,
                      mainAxisCellCount: 1,
                      child: section,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Panel de exportação/ações
        Container(
          width: 300,
          child: DashboardActionsPanel(
            userRole: userRole,
            exportConfig: exportConfig,
          ),
        ),
      ],
    );
  }
}
```

## 🎯 Implementação Contextual Específica

### 1. Dashboard Advogado Associado Unificado

```dart
class UnifiedLawyerAssociatedDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveDashboardLayout(
      userRole: UserRole.lawyerAssociated,
      sections: [
        // 1. SLA Overview contextual
        UnifiedSlaDashboard(
          userRole: UserRole.lawyerAssociated,
          metrics: LawyerAssociatedSlaIntegration.getContextualMetrics(),
        ),
        
        // 2. KPIs Pessoais
        UnifiedKPIGrid(
          kpis: [
            UnifiedKPICard(
              title: 'Casos Ativos',
              value: '12',
              trend: '+2',
              icon: Icons.folder_open,
              color: Colors.blue,
              slaCompliance: SlaCompliance.fromMetric(slaMetrics[0]),
              onTap: () => context.push('/cases'),
            ),
            UnifiedKPICard(
              title: 'Prazo Médio',
              value: '2.5h',
              trend: '-0.3h',
              icon: Icons.schedule,
              color: Colors.green,
              slaCompliance: SlaCompliance.fromMetric(slaMetrics[1]),
            ),
            UnifiedKPICard(
              title: 'Satisfação',
              value: '4.8⭐',
              trend: '+0.2',
              icon: Icons.star,
              color: Colors.amber,
            ),
          ],
        ),
        
        // 3. Firm Info integrado com SLA
        FirmInfoWithSlaIntegration(),
        
        // 4. Actions contextual
        LawyerAssociatedQuickActions(),
        
        // 5. Export Section
        ContextualCloudExportWidget(
          userRole: UserRole.lawyerAssociated,
          dashboardData: dashboardData,
          slaMetrics: slaMetrics,
        ),
      ],
    );
  }
}
```

### 2. Dashboard Sócio Escritório Unificado

```dart
class UnifiedLawyerOfficeDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveDashboardLayout(
      userRole: UserRole.lawyerOffice,
      sections: [
        // 1. SLA Organizacional
        UnifiedSlaDashboard(
          userRole: UserRole.lawyerOffice,
          metrics: LawyerOfficeSlaIntegration.getContextualMetrics(),
        ),
        
        // 2. Métricas da Firma
        FirmMetricsWithSla(
          firmData: firmData,
          slaMetrics: slaMetrics,
        ),
        
        // 3. Performance da Equipe
        TeamPerformanceWithSla(
          teamData: teamData,
          individualSlaMetrics: individualSlaMetrics,
        ),
        
        // 4. Análise Financeira
        FinancialAnalysisWithTargets(
          financialData: financialData,
          revenueTargets: revenueTargets,
        ),
        
        // 5. Export Executivo
        ExecutiveCloudExportWidget(
          userRole: UserRole.lawyerOffice,
          firmData: firmData,
          teamMetrics: teamMetrics,
        ),
      ],
    );
  }
}
```

### 3. Dashboard Contratante Unificado

```dart
class UnifiedContractorDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveDashboardLayout(
      userRole: userRole, // lawyer_individual ou lawyer_platform_associate
      sections: [
        // 1. SLA de Negócios
        UnifiedSlaDashboard(
          userRole: userRole,
          metrics: LawyerContractorSlaIntegration.getContextualMetrics(),
        ),
        
        // 2. Métricas de Captação
        BusinessCaptationMetrics(
          captationData: captationData,
          slaMetrics: slaMetrics,
        ),
        
        // 3. Pipeline Comercial
        BusinessPipelineWithSla(
          pipelineData: pipelineData,
          conversionTargets: conversionTargets,
        ),
        
        // 4. Parcerias Ativas
        ActivePartnershipsWithMaintenance(
          partnershipsData: partnershipsData,
          maintenanceSchedule: maintenanceSchedule,
        ),
        
        // 5. Export de Negócios
        BusinessCloudExportWidget(
          userRole: userRole,
          businessData: businessData,
          pipelineMetrics: pipelineMetrics,
        ),
      ],
    );
  }
}
```

## 📊 Sistema de Analytics Unificado

### 1. Analytics Contextual por Usuário

```dart
class UnifiedDashboardAnalytics {
  static AnalyticsConfig getAnalyticsForRole(UserRole role) {
    switch (role) {
      case UserRole.lawyerAssociated:
        return AnalyticsConfig(
          trackingEvents: [
            'case_opened',
            'task_completed',
            'client_communication',
            'sla_violation',
            'export_generated',
          ],
          customMetrics: [
            'productivity_score',
            'response_time_average',
            'client_satisfaction_rating',
          ],
          reportingFrequency: ReportingFrequency.weekly,
        );
        
      case UserRole.lawyerOffice:
        return AnalyticsConfig(
          trackingEvents: [
            'team_performance_review',
            'revenue_milestone',
            'client_retention',
            'firm_sla_compliance',
            'executive_report_generated',
          ],
          customMetrics: [
            'firm_productivity',
            'team_satisfaction',
            'revenue_growth_rate',
            'client_lifetime_value',
          ],
          reportingFrequency: ReportingFrequency.monthly,
        );
    }
  }
}

// Widget de Analytics Integrado
class DashboardAnalyticsWidget extends StatelessWidget {
  final UserRole userRole;
  final Duration timeRange;

  @override
  Widget build(BuildContext context) {
    return UnifiedDashboardCard(
      title: 'Analytics & Insights',
      actions: [
        ActionItem(
          icon: Icons.tune,
          onTap: () => _configureAnalytics(context),
        ),
      ],
      content: Column(
        children: [
          // Período selector
          TimeRangeSelector(
            selectedRange: timeRange,
            onChanged: (range) => _updateTimeRange(range),
          ),
          
          SizedBox(height: 16),
          
          // Métricas principais
          AnalyticsMetricsGrid(
            userRole: userRole,
            timeRange: timeRange,
          ),
          
          SizedBox(height: 16),
          
          // Insights automáticos
          AIInsightsSection(
            userRole: userRole,
            timeRange: timeRange,
          ),
          
          SizedBox(height: 16),
          
          // Export analytics
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.analytics),
                  label: Text('Relatório Completo'),
                  onPressed: () => _generateAnalyticsReport(),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.schedule),
                  label: Text('Agendar Relatório'),
                  onPressed: () => _scheduleAnalyticsReport(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

## 🚀 Plano de Implementação

### Fase 1: Fundação (2 semanas)
- [ ] Criar componentes base unificados
- [ ] Implementar sistema de cores contextual
- [ ] Desenvolver SLA integration básica
- [ ] Configurar responsive layouts

### Fase 2: SLA Integration (3 semanas)
- [ ] Implementar métricas SLA contextuais
- [ ] Criar widgets SLA unificados
- [ ] Integrar alertas e notificações SLA
- [ ] Desenvolver analytics SLA

### Fase 3: Cloud Export System (4 semanas)
- [ ] Implementar templates contextuais
- [ ] Desenvolver Google Sheets integration
- [ ] Criar sistema de agendamento
- [ ] Implementar sharing avançado

### Fase 4: Dashboard Unification (3 semanas)
- [ ] Refatorar dashboard do advogado associado
- [ ] Refatorar dashboard do sócio
- [ ] Refatorar dashboard contratante
- [ ] Implementar analytics unificado

### Fase 5: Polish & Testing (2 semanas)
- [ ] Testes de usabilidade
- [ ] Otimização de performance
- [ ] Correção de bugs
- [ ] Documentação final

## 📈 Métricas de Sucesso

### Métricas de UX
- **Task Completion Rate**: > 95%
- **Time to Complete Export**: < 30 segundos
- **User Satisfaction**: > 4.5/5
- **SLA Awareness**: > 80% dos usuários verificam SLA diariamente

### Métricas de Negócio
- **Export Usage**: > 70% dos usuários usam export semanal
- **SLA Compliance**: Melhoria de 25% na compliance
- **Data Accuracy**: > 99% precisão nos dados exportados
- **User Retention**: +15% retenção mensal

### Métricas Técnicas
- **Loading Time**: < 2s para dashboard completo
- **Export Generation**: < 10s para relatórios simples
- **Error Rate**: < 0.1% em operações de export
- **Uptime**: > 99.9% disponibilidade do sistema

---

**Documento criado em**: 20 de Janeiro de 2025  
**Autor**: Sistema de Planejamento LITIG-1  
**Versão**: 1.0 - Plano de Uniformização Completo  
**Status**: Pronto para implementação