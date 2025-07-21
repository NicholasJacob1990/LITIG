# Documentação do Cliente - Navegação e Dashboard LITIG-1

## 📱 Estrutura de Navegação para Clientes

### 🎯 Filosofia da Interface Cliente

A interface para clientes prioriza a **experiência de atendimento** e **transparência nas informações**. O foco principal é facilitar a comunicação com advogados e fornecer visibilidade completa sobre o andamento dos casos.

### 📍 Menu de Navegação Principal

```
┌─────────────────────────────────────┐
│ 🏠 Início                          │ ← Triagem inteligente com IA
│ 📁 Meus Casos                     │ ← Acompanhar processos
│ 🔍 Advogados                      │ ← Buscar profissionais
│ 💬 Mensagens                      │ ← Comunicação direta
│ 💼 Serviços                       │ ← Catálogo de serviços
│ 👤 Perfil + Dashboard             │ ← Dados pessoais + métricas
└─────────────────────────────────────┘
```

## 🏠 Aba Início (Triagem Inteligente)

### **Implementação Atual**: Interface acolhedora com direcionamento para IA

#### **Estado Atual (Mantido)**:
A tela de início dos clientes já está implementada e funcionando perfeitamente conforme esperado:

#### **HomeScreen** - Página de Boas-vindas:
```
┌─────────────────────────────────────┐
│ Bem-vindo, [Nome do Cliente]        │
│                                     │
│         💬 [Ícone Chat]            │
│                                     │
│ "Seu Problema Jurídico, Resolvido   │
│  com Inteligência"                  │
│                                     │
│ "Use nossa IA para uma pré-análise  │
│  gratuita e seja conectado ao       │
│  advogado certo para o seu caso."   │
│                                     │
│ [🌟 Iniciar Consulta com IA]       │ ← Direciona para /triage
│                                     │
└─────────────────────────────────────┘
```

#### **ChatTriageScreen** - Sistema de Triagem:
```
┌─────────────────────────────────────┐
│ Triagem Inteligente                 │
│                                     │
│ 🤖 Assistente: Como posso ajudar?   │
│ 👤 Cliente: [mensagem do cliente]   │
│ 🤖 Assistente: [resposta da IA]     │
│ 👤 Cliente: [nova mensagem]         │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Digite sua mensagem...          │🔄│
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

#### **Funcionalidades Implementadas**:
- ✅ **Interface acolhedora** com boas-vindas personalizadas
- ✅ **Direcionamento inteligente** para sistema de triagem
- ✅ **Chat de IA funcional** para análise de casos
- ✅ **Fluxo completo** de triagem → recomendação de advogados
- ✅ **Design responsivo** com tema escuro elegante
- ✅ **Integração automática** com sistema de busca de advogados

## 👤 Aba Perfil + Dashboard

### **Estrutura em Abas**:

```
┌─────────────────────────────────────┐
│ [👤 Perfil] [📊 Dashboard] [📅 Agenda] │
└─────────────────────────────────────┘
```

### **📊 Sub-aba Dashboard:**
- **Cliente PF**: Dashboard com métricas pessoais, ROI, documentos centralizados
- **Cliente PJ**: Dashboard executivo com compliance, analytics departamental, ROI empresarial

### **📅 Sub-aba Agenda:**
- **Cliente PF**: Audiências, consultas, prazos processuais, reuniões com advogados
- **Cliente PJ**: Audiências corporativas, prazos compliance, reuniões departamentais, auditorias agendadas

## 📊 Dashboard do Cliente

### 🏢 **Cliente Pessoa Jurídica (PJ)**

#### **Visão Executiva**
```
┌─────────────────────────────────────┐
│ 📈 Painel Executivo - [Nome da Empresa] │
│                                     │
│ ┌─────────┬─────────┬─────────────┐ │
│ │ Casos   │ Gasto   │ Advogados   │ │
│ │ Ativos  │ Mensal  │ Contratados │ │
│ │   15    │ R$ 45k  │     8       │ │
│ │ ↑ +2    │ ↓ -12%  │   ↑ +1      │ │
│ └─────────┴─────────┴─────────────┘ │
│                                     │
│ 📊 Distribuição por Área:          │
│ ┌─────────────────────────────────┐ │
│ │ Trabalhista    ████████ 40%    │ │
│ │ Tributário     ██████   30%    │ │
│ │ Empresarial    ████     20%    │ │
│ │ Outros         ██       10%    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🎯 Métricas de Performance:        │
│ • Taxa de Sucesso: 87%             │
│ • Tempo Médio de Resolução: 4.2 meses │
│ • Satisfação com Advogados: 4.8⭐  │
│                                     │
│ 📋 Casos Prioritários:             │
│ • Auditoria Fiscal - Prazo: 5 dias │
│ • Rescisão Trabalhista - Em análise │
│ • Contrato Fornecedor - Aguardando │
│                                     │
│ 💰 Análise Financeira:             │
│ ┌─────────────────────────────────┐ │
│ │ Orçado: R$ 180k │ Gasto: R$ 142k │ │
│ │ Economia: R$ 38k (21% abaixo)   │ │
│ │ ┌─────┬─────┬─────┬─────┬─────┐ │ │
│ │ │ Jan │ Fev │ Mar │ Abr │ Mai │ │ │
│ │ │ 32k │ 28k │ 35k │ 47k │ 39k │ │ │
│ │ └─────┴─────┴─────┴─────┴─────┘ │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 📈 ROI Jurídico:                   │
│ • Valor Recuperado: R$ 2.1M        │
│ • Investimento Legal: R$ 285k      │
│ • ROI: 637% 📈                    │
│                                     │
│ 🚨 Alertas & Riscos:               │
│ • 3 prazos processuais próximos    │
│ • 1 renovação contratual pendente  │
│ • 2 compliance checks atrasados    │
│                                     │
│ ⚖️ Compliance Legal:               │
│ ┌─────────────────────────────────┐ │
│ │ Trabalhista    ✅ 98% Conforme │ │
│ │ Tributário     ⚠️  85% Conforme │ │
│ │ Ambiental      ✅ 100% Conforme│ │
│ │ LGPD           ⚠️  92% Conforme │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 📊 Relatórios Executivos:          │
│ • [📄 Relatório Mensal]           │
│ • [📈 Dashboard para Diretoria]   │
│ • [💼 Análise de Custos]          │
│ • [🎯 Metas de Compliance]        │
└─────────────────────────────────────┘
```

## 🚫 Evitando Redundância com "Meus Casos"

### **O que JÁ está coberto na aba "Meus Casos":**
- ✅ **Lista detalhada de casos ativos** com status individual
- ✅ **Informações específicas de cada advogado** contratado  
- ✅ **Pré-análise IA por caso** e detalhes operacionais
- ✅ **Filtros por status** (Em Andamento, Concluído, etc.)
- ✅ **Próximas audiências** e compromissos específicos
- ✅ **Mensagens não lidas** por advogado/caso
- ✅ **Recomendações de escritórios** (para PJ)

### **O que deve ficar APENAS no Dashboard** (sem redundância):

### 👤 **Cliente Pessoa Física (PF) - Métricas Consolidadas**

```
┌─────────────────────────────────────┐
│ 💰 Resumo Financeiro Consolidado    │
│ ┌─────────┬─────────┬─────────────┐ │
│ │ Total   │ Valor   │ ROI         │ │
│ │ Investido│ Disputa │ Histórico   │ │
│ │ R$ 8.5k │ R$ 45k  │ 276% 📈     │ │
│ └─────────┴─────────┴─────────────┘ │
│                                     │
│ 📈 Performance Histórica (Todos os Casos)│
│ • Total de Casos: 12 casos         │
│ • Taxa de Sucesso: 75% (9/12)      │
│ • Tempo Médio: 8.3 meses/caso      │
│ • Satisfação Média: 4.7⭐          │
│                                     │
│ 🎯 Insights Pessoais:              │
│ • Área mais frequente: Trabalhista │
│ • Melhor performance: Consumidor   │
│ • Tendência: +15% gastos/ano       │
│ • Recomendação: Seguro jurídico    │
│                                     │
│ 📋 Documentos Centralizados:       │
│ • [📄 Procurações ativas (3)]     │
│ • [📑 Certidões válidas (5)]      │
│ • [💼 Contratos vigentes (2)]     │
│ • [🎯 Relatórios consolidados]    │
│                                     │
│ 🔔 Lembretes Pessoais:             │
│ • RG vence em 2 meses              │
│ • Renovar procuração Dr. Silva     │
│ • Revisar seguros jurídicos        │
│ • Reunião trimestral agendada      │
└─────────────────────────────────────┘
```

### 🏢 **Cliente Pessoa Jurídica (PJ) - Analytics Executivos**

```
┌─────────────────────────────────────┐
│ 📊 Performance Departamental        │
│ ┌─────────┬─────────┬─────────────┐ │
│ │ Budget  │ Gasto   │ Economia    │ │
│ │ Anual   │ YTD     │ Obtida      │ │
│ │ R$ 180k │ R$ 142k │ R$ 38k      │ │
│ └─────────┴─────────┴─────────────┘ │
│                                     │
│ 📈 Distribuição por Área Jurídica: │
│ ┌─────────────────────────────────┐ │
│ │ Trabalhista  ████████ 40% R$68k│ │
│ │ Tributário   ██████   30% R$51k│ │
│ │ Comercial    ████     20% R$34k│ │
│ │ Compliance   ██       10% R$17k│ │
│ └─────────────────────────────────┘ │
│                                     │
│ ⚖️ Compliance Consolidado:         │
│ ┌─────────────────────────────────┐ │
│ │ Trabalhista    ✅ 98% Conforme │ │
│ │ Tributário     ⚠️  85% Conforme │ │
│ │ Ambiental      ✅ 100% Conforme│ │
│ │ LGPD           ⚠️  92% Conforme │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🚨 Gestão de Riscos Corporativos:  │
│ • 3 auditorias fiscais pendentes   │
│ • 5 renovações contratuais         │
│ • 2 licenças ambientais vencendo   │
│ • 1 investigação trabalhista       │
│                                     │
│ 💼 ROI Departamento Jurídico:      │
│ • Valor Economizado: R$ 2.1M       │
│ • Investimento Total: R$ 285k      │
│ • ROI Consolidado: 637% 📈         │
│                                     │
│ 📊 Relatórios Executivos:          │
│ • [📈 Dashboard Diretoria]         │
│ • [💰 Análise Custos Trimestral]  │
│ • [⚖️ Relatório Compliance]       │
│ • [🎯 Previsão Orçamentária]      │
└─────────────────────────────────────┘
```

## 🔍 Diferenciação Clara: "Meus Casos" vs Dashboard

| **"Meus Casos"** | **Dashboard** |
|-------------------|---------------|
| Lista individual de casos | Métricas consolidadas |
| Status específico por caso | Tendências históricas |
| Advogado por caso | Performance geral |
| Detalhes operacionais | Insights estratégicos |
| Ações por caso | Recomendações gerais |
| Próximas audiências | Alertas preventivos |
| Mensagens por advogado | Documentos centralizados |

### **Pessoa Física (PF)**:
- **Dashboard**: ROI consolidado, histórico geral, insights pessoais
- **"Meus Casos"**: Casos específicos, advogados, audiências

### **Pessoa Jurídica (PJ)**:
- **Dashboard**: Analytics departamental, compliance, ROI empresarial
- **"Meus Casos"**: Casos individuais, recomendações de escritórios

## 📊 Componentes Técnicos

### **Sistema de Design Unificado (baseado no LITIG-1)**:

#### **1. Componentes Base Padronizados**
```dart
// Dashboard Card Unificado para Clientes
class UnifiedClientDashboardCard extends StatelessWidget {
  final String title;
  final Widget content;
  final List<ActionItem>? actions;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final ClientType clientType; // PF ou PJ

  @override
  Widget build(BuildContext context) {
    final colorScheme = ClientDashboardTheme.getSchemeForType(clientType);
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Header unificado
          UnifiedCardHeader(
            title: title,
            actions: actions,
            colorScheme: colorScheme,
            onRefresh: onRefresh,
          ),
          
          // Conteúdo com loading state
          if (isLoading)
            ClientDashboardSkeletonLoader()
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

// KPI Card Padronizado para Clientes
class UnifiedClientKPICard extends StatelessWidget {
  final String title;
  final String value;
  final String? trend;
  final IconData icon;
  final Color color;
  final ClientType clientType;
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
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com ícone
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                if (clientType == ClientType.corporate)
                  ComplianceStatusIndicator(value: value),
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

#### **2. Sistema de Cores Contextual para Clientes**
```dart
class ClientDashboardTheme {
  // Cores específicas por tipo de cliente
  static const Map<ClientType, ClientColorScheme> colorSchemes = {
    ClientType.individual: ClientColorScheme(
      primary: Color(0xFF2E7D32),       // Verde confiança (PF)
      secondary: Color(0xFF66BB6A),     // Verde claro
      accent: Color(0xFF1976D2),        // Azul informativo  
      warning: Color(0xFFFF9800),       // Laranja alertas
      success: Color(0xFF388E3C),       // Verde sucesso
    ),
    
    ClientType.corporate: ClientColorScheme(
      primary: Color(0xFF1565C0),       // Azul corporativo (PJ)
      secondary: Color(0xFF42A5F5),     // Azul claro
      accent: Color(0xFF7B1FA2),        // Roxo executivo
      warning: Color(0xFFE91E63),       // Rosa crítico
      success: Color(0xFF2E7D32),       // Verde performance
    ),
  };
  
  static ClientColorScheme getSchemeForType(ClientType type) {
    return colorSchemes[type] ?? colorSchemes[ClientType.individual]!;
  }
}

class ClientColorScheme {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color warning;
  final Color success;
  
  const ClientColorScheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.warning,
    required this.success,
  });
}

enum ClientType { individual, corporate }
```

### **Implementação dos Dashboards**:

```dart
// Dashboard PF (com componentes unificados)
class PersonalClientDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveClientDashboardLayout(
      clientType: ClientType.individual,
      sections: [
        // ✅ Financeiro consolidado
        UnifiedClientDashboardCard(
          title: 'Resumo Financeiro',
          clientType: ClientType.individual,
          content: ConsolidatedFinancialSummary(),
        ),
        
        // ✅ Performance histórica
        UnifiedClientDashboardCard(
          title: 'Minha Performance',
          clientType: ClientType.individual,
          content: PersonalPerformanceHistory(),
        ),
        
        // ✅ Insights personalizados
        UnifiedClientDashboardCard(
          title: 'Insights Pessoais',
          clientType: ClientType.individual,
          content: PersonalInsightsWidget(),
        ),
        
        // ✅ Documentos centralizados
        UnifiedClientDashboardCard(
          title: 'Meus Documentos',
          clientType: ClientType.individual,
          content: CentralizedDocuments(),
        ),
      ],
    );
  }
}

// Dashboard PJ (com componentes unificados)
class CorporateClientDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveClientDashboardLayout(
      clientType: ClientType.corporate,
      sections: [
        // ✅ Analytics departamental
        UnifiedClientDashboardCard(
          title: 'Performance Empresarial',
          clientType: ClientType.corporate,
          content: DepartmentalPerformanceGrid(),
        ),
        
        // ✅ Compliance corporativo
        UnifiedClientDashboardCard(
          title: 'Compliance & Riscos',
          clientType: ClientType.corporate,
          content: CorporateComplianceOverview(),
        ),
        
        // ✅ ROI departamento jurídico
        UnifiedClientDashboardCard(
          title: 'ROI Jurídico',
          clientType: ClientType.corporate,
          content: LegalDepartmentROI(),
        ),
        
        // ✅ Relatórios executivos
        UnifiedClientDashboardCard(
          title: 'Relatórios Executivos',
          clientType: ClientType.corporate,
          content: ExecutiveReportsSection(),
        ),
      ],
    );
  }
}
```

## 🎯 Benefícios da Estrutura Atual

### **Para o Cliente**:
- **Triagem Eficiente**: Sistema IA já implementado encontra ajuda rapidamente
- **Transparência Total**: Dashboard no perfil mostra tudo sobre casos
- **Dashboard Personalizado**: Métricas relevantes ao perfil (PF/PJ)
- **Comunicação Integrada**: Fluxo completo em um só lugar

### **Para a Plataforma**:
- **Engajamento Maior**: Interface já focada na necessidade do cliente
- **Dados Estruturados**: Triagem atual coleta informações organizadas
- **Satisfação Cliente**: Experiência diferenciada PF/PJ
- **Eficiência Operacional**: Direcionamento automático funcionando

## 📱 Fluxo de Uso Implementado

### **Cliente Novo**:
1. **Início** → Boas-vindas + "Iniciar Consulta com IA"
2. **Triagem** → Chat inteligente analisa o problema
3. **Direcionamento** → IA conecta com advogados especializados
4. **Contratação** → Cliente aceita proposta via plataforma
5. **Acompanhamento** → Dashboard no perfil monitora progresso

### **Cliente Existente**:
1. **Início** → Acesso rápido a nova triagem quando necessário
2. **Dashboard** → (No perfil) Monitora casos ativos
3. **Mensagens** → Comunicação contínua com advogados
4. **Casos** → Acompanha documentos e andamentos

## 🎨 **Diretrizes de UX/UI para Dashboards Cliente**

### **Princípios de Design Aplicados**:
- ✅ **Material Design 3** com visual moderno e consistente
- ✅ **Componentes modulares** e reutilizáveis entre PF/PJ
- ✅ **Gerenciamento de estado** robusto com BLoC pattern
- ✅ **Separação clara** de responsabilidades (Clean Architecture)

### **Melhorias de UX Implementadas**:

#### **1. Responsividade Adaptativa Unificada**
```dart
class ResponsiveClientDashboardLayout extends StatelessWidget {
  final ClientType clientType;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile: < 600px - Empilhado vertical
        if (constraints.maxWidth < 600) {
          return MobileClientDashboardLayout(
            clientType: clientType,
            sections: sections,
          );
        }
        // Tablet: 600-1200px - Grid 2 colunas
        else if (constraints.maxWidth < 1200) {
          return TabletClientDashboardLayout(
            clientType: clientType,
            sections: sections,
          );
        }
        // Desktop: > 1200px - Grid 3 colunas
        else {
          return DesktopClientDashboardLayout(
            clientType: clientType,
            sections: sections,
          );
        }
      },
    );
  }
}

class MobileClientDashboardLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = ClientDashboardTheme.getSchemeForType(clientType);
    
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header personalizado por tipo
            ClientDashboardHeader(
              clientType: clientType,
              colorScheme: colorScheme,
            ),
            
            SizedBox(height: 16),
            
            // KPIs overview compacto
            ClientKPIsOverview(clientType: clientType),
            
            SizedBox(height: 16),
            
            // Seções empilhadas verticalmente
            ...sections.map((section) => Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: section,
            )),
          ],
        ),
      ),
    );
  }
}
```

#### **2. Loading States com Skeleton**
```dart
class DashboardSkeletonLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SkeletonLoader(
                height: 120, 
                borderRadius: BorderRadius.circular(12)
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: SkeletonLoader(
                height: 120, 
                borderRadius: BorderRadius.circular(12)
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        SkeletonLoader(height: 200, borderRadius: BorderRadius.circular(12)),
      ],
    );
  }
}
```

#### **3. Acessibilidade Aprimorada**
```dart
Widget _buildMetricCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
}) {
  return Semantics(
    label: '$title: $value',
    button: true,
    hint: 'Toque para ver detalhes de $title',
    child: Card(
      child: InkWell(
        onTap: () => _showMetricDetails(title),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              SizedBox(height: 8),
              Text(title, style: TextStyle(fontSize: 14)),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    ),
  );
}
```

#### **4. Dark Mode Support**
```dart
class ClientDashboardTheme {
  static ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    cardTheme: CardTheme(
      color: Colors.grey[850],
      elevation: 2,
    ),
  );
}
```

## 📅 **Agenda do Cliente - Especificação Detalhada**

### **🎯 Visão Geral da Agenda**

A agenda do cliente integra **compromissos jurídicos**, **prazos processuais** e **reuniões** em uma interface unificada, aproveitando o sistema SLA existente e adicionando integrações com calendários externos.

### **📱 Interface da Agenda por Tipo de Cliente**

#### **👤 Cliente Pessoa Física (PF):**
```
┌─────────────────────────────────────┐
│ 📅 Agenda Pessoal - [Nome Cliente] │
│                                     │
│ 📊 Resumo do Mês:                  │
│ • 3 Audiências agendadas           │
│ • 2 Consultas marcadas             │
│ • 5 Prazos importantes             │
│ • 1 Reunião de acompanhamento      │
│                                     │
│ 🔴 Próximos 7 dias:                │
│ ┌─────────────────────────────────┐ │
│ │ 25/01 - 14:00 Audiência TRT    │ │
│ │ 26/01 - 09:00 Consulta Dr.Silva│ │
│ │ 28/01 - Prazo: Recurso (3 dias)│ │
│ │ 30/01 - 15:30 Reunião Caso X   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🔗 Integrações:                    │
│ [📅 + Google] [📧 + Outlook]       │
│                                     │
│ [📱 Ver Calendário] [⚙️ Config]    │
└─────────────────────────────────────┘
```

#### **🏢 Cliente Pessoa Jurídica (PJ):**
```
┌─────────────────────────────────────┐
│ 📅 Agenda Corporativa - [Empresa]  │
│                                     │
│ 📊 Dashboard Executivo:            │
│ • 8 Audiências departamentais      │
│ • 12 Prazos compliance             │
│ • 4 Auditorias agendadas           │
│ • 6 Reuniões estratégicas          │
│                                     │
│ 🎯 Por Departamento:               │
│ ┌─────────────────────────────────┐ │
│ │ Jurídico    ████████ 45%       │ │
│ │ Compliance  ██████   30%       │ │
│ │ Fiscal      ████     20%       │ │
│ │ RH          ██       5%        │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🚨 Críticos (próximos 15 dias):    │
│ • Auditoria SOX - 03/02            │
│ • Prazo LGPD - 07/02               │
│ • Renovação Licença - 10/02        │
│                                     │
│ 🔗 Integrações Corporativas:       │
│ [📅 + Outlook 365] [📊 + Teams]    │
│                                     │
│ [📱 Calendário] [📊 Relatórios]    │
└─────────────────────────────────────┘
```

### **📋 Tipos de Eventos na Agenda**

#### **⚖️ Eventos Jurídicos:**
- **Audiências**: Presenciais/virtuais, cível/trabalhista
- **Consultas**: Reuniões com advogados, orientações
- **Prazos Processuais**: Recursos, contestações, manifestações
- **Deadlines**: Documentos, contratos, renovações

#### **🏢 Eventos Corporativos (PJ):**
- **Auditorias**: Internas/externas, compliance, fiscal
- **Reuniões Departamentais**: Jurídico, compliance, diretoria
- **Prazos Regulatórios**: LGPD, SOX, ISO, licenças
- **Eventos de Governança**: Board meetings, assembleias

### **📅 Agenda por Caso Individual**

Cada caso na tela "Meus Casos" agora possui um **botão de agenda específico**:

```
┌─────────────────────────────────────┐
│ [Título do Caso] [PF] [Em Andamento]│
│ Descrição do caso...                │
│ [Advogado Info] [Pré-análise IA]    │
│                                     │
│           [📅 Agenda] [👁 Ver Detalhes]│
└─────────────────────────────────────┘
```

#### **🎯 Funcionalidades da Agenda por Caso:**
- **Rota específica**: `/case-detail/$caseId/agenda`
- **Eventos filtrados**: Apenas eventos relacionados ao caso específico
- **Ícone verde**: `LucideIcons.calendar` com cor `AppColors.success`
- **Contexto isolado**: Agenda focada apenas no caso selecionado

#### **📋 Conteúdo da Agenda por Caso:**
- Audiências específicas do processo
- Prazos processuais do caso
- Reuniões com o advogado responsável
- Deadlines de documentos do processo
- Lembretes de acompanhamento

### **🔗 Integrações com Calendários Externos**

**IMPORTANTE**: A integração com calendários (Google Calendar e Outlook) aproveitará o SDK da Unipile já existente no sistema.

#### **📅 Integração via Unipile SDK**

**Status Atual do SDK Unipile no LITIG-1:**
- ✅ **Email**: Gmail, Outlook, IMAP totalmente funcionais
- ✅ **Social**: LinkedIn, Instagram, Facebook integrados
- ✅ **Calendários**: **API DISPONÍVEL** - Pronto para implementação

**Arquitetura Existente:**
```dart
// O sistema já possui integração híbrida Python/Node.js com Unipile
class UnipileCalendarIntegration {
  final UnipileService unipileService;
  
  // API de calendários já disponível na Unipile
  Future<void> syncWithCalendar(String accountId, CalendarProvider provider) async {
    // Aproveita a infraestrutura existente do SDK
    final calendars = await unipileService.listCalendars(accountId);
    
    for (final calendar in calendars) {
      final events = await unipileService.listCalendarEvents(
        calendarId: calendar.id,
        accountId: accountId,
      );
    
    // Sincronização bidirecional usando SDK unificado
    await _syncEventsWithLitig(events);
  }
  
  // Criar evento via Unipile (API já disponível)
  Future<void> createCalendarEvent(String calendarId, LegalEvent event) async {
    // Usar API oficial: POST /api/v1/calendars/{calendar_id}/events
    await unipileService.createCalendarEvent(
      calendarId: calendarId,
      event: {
        'title': event.title,
        'description': '${event.description}\n\n🏛️ Evento LITIG-1\nCaso: ${event.caseNumber}',
        'start_time': event.startTime.toIso8601String(),
        'end_time': event.endTime.toIso8601String(),
        'location': event.location,
        'attendees': [event.clientEmail, event.lawyerEmail],
        'reminders': [
          {'method': 'popup', 'minutes': 60},
          {'method': 'email', 'minutes': 1440}, // 24h
        ],
      },
    );
  }
}
```

**Benefícios da Integração Unipile (CALENDÁRIOS DISPONÍVEIS):**
1. **API Unificada**: Mesmo SDK para email, social e calendário
2. **Autenticação Simplificada**: OAuth gerenciado pela Unipile
3. **Multi-provider**: Google e Outlook com mesma interface
4. **Infraestrutura Existente**: Aproveita `/packages/backend/unipile_sdk_service.js`
5. **Suporte Profissional**: SDK oficial com documentação completa
6. **🆕 API de Calendários**: Endpoints completos já disponíveis

**📅 Endpoints de Calendário Unipile Disponíveis:**
- `GET /api/v1/calendars` - Listar calendários
- `GET /api/v1/calendars/{calendar_id}` - Obter calendário específico  
- `GET /api/v1/calendars/{calendar_id}/events` - Listar eventos
- `POST /api/v1/calendars/{calendar_id}/events` - Criar evento
- `GET /api/v1/calendars/{calendar_id}/events/{event_id}` - Obter evento
- `PUT /api/v1/calendars/{calendar_id}/events/{event_id}` - Editar evento
- `DELETE /api/v1/calendars/{calendar_id}/events/{event_id}` - Deletar evento

**Arquivos de Integração Existentes:**
```
/packages/backend/
├── unipile_sdk_service.js          # SDK oficial Node.js (ADICIONAR calendários)
├── services/
│   ├── unipile_service.py          # Serviço REST API (ADICIONAR endpoints)
│   ├── unipile_sdk_wrapper.py      # Wrapper Python/Node.js (ADICIONAR métodos)
│   └── hybrid_legal_data_service.py # Integração com matching
└── docs/
    └── UNIPILE_SDK_INTEGRATION_GUIDE.md # Documentação completa (ATUALIZAR)
```
          IdentitySet(user: User(id: id))
        ).toList(),
      ),
    );
    
    await microsoftGraphAPI.createOnlineMeeting(meeting);
  }
}
```

### **⏰ Sistema de Lembretes e Notificações**

#### **🔔 Lembretes Inteligentes:**
```dart
class LegalReminderSystem {
  // Lembretes baseados no tipo de evento
  List<ReminderConfig> getLegalReminders(EventType type) {
    switch (type) {
      case EventType.hearing:
        return [
          ReminderConfig(duration: Duration(days: 7), message: 'Audiência em uma semana'),
          ReminderConfig(duration: Duration(days: 1), message: 'Audiência amanhã - preparar documentos'),
          ReminderConfig(duration: Duration(hours: 2), message: 'Audiência em 2 horas - partir agora'),
        ];
      
      case EventType.deadline:
        return [
          ReminderConfig(duration: Duration(days: 15), message: 'Prazo se aproximando'),
          ReminderConfig(duration: Duration(days: 7), message: 'Uma semana para o prazo'),
          ReminderConfig(duration: Duration(days: 3), message: 'URGENTE: 3 dias para o prazo'),
          ReminderConfig(duration: Duration(days: 1), message: 'CRÍTICO: Prazo amanhã'),
        ];
      
      case EventType.consultation:
        return [
          ReminderConfig(duration: Duration(days: 1), message: 'Consulta amanhã'),
          ReminderConfig(duration: Duration(hours: 1), message: 'Consulta em 1 hora'),
        ];
    }
  }
}
```

### **📱 Interface Mobile da Agenda**

#### **📲 Widget de Agenda (Dashboard):**
```dart
class AgendaWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue),
                SizedBox(width: 8),
                Text('Próximos Compromissos', style: Theme.of(context).textTheme.titleMedium),
                Spacer(),
                TextButton(
                  child: Text('Ver Agenda'),
                  onPressed: () => context.push('/profile/agenda'),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Lista de próximos eventos
            ...upcomingEvents.take(3).map((event) => 
              AgendaEventItem(event: event)
            ),
            
            if (upcomingEvents.length > 3) ...[
              SizedBox(height: 8),
              Text('+ ${upcomingEvents.length - 3} eventos adicionais',
                style: TextStyle(color: Colors.grey[600])),
            ],
          ],
        ),
      ),
    );
  }
}

class AgendaEventItem extends StatelessWidget {
  final LegalEvent event;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.left(
          color: _getEventTypeColor(event.type),
          width: 4,
        ),
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('dd/MM - HH:mm').format(event.dateTime),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                event.title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (event.location != null)
                Text(
                  event.location!,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
            ],
          ),
          Spacer(),
          Icon(_getEventTypeIcon(event.type), size: 16),
        ],
      ),
    );
  }
}
```

### **🎯 Funcionalidades Específicas por Cliente**

#### **👤 Pessoa Física (PF):**
- **Audiências Pessoais**: TRT, cível, criminal, família
- **Consultas Jurídicas**: Orientação, acompanhamento, dúvidas
- **Prazos Processuais**: Recursos, contestações, manifestações
- **Lembretes Personais**: Documentos, renovações, vencimentos

#### **🏢 Pessoa Jurídica (PJ):**
- **Audiências Corporativas**: Trabalhistas, tributárias, comerciais
- **Compliance Calendar**: LGPD, SOX, ISO, auditorias
- **Reuniões Departamentais**: Jurídico, fiscal, RH, diretoria
- **Prazos Regulatórios**: Licenças, renovações, declarações

## ✅ **Status de Implementação**

### **Já Implementado**:
- ✅ **HomeScreen**: Interface de boas-vindas funcional
- ✅ **ChatTriageScreen**: Sistema de triagem com IA
- ✅ **Fluxo de navegação**: Integração completa
- ✅ **Direcionamento**: Para busca de advogados
- ✅ **Clean Architecture**: Base sólida implementada
- ✅ **Sistema SLA**: Base para cálculo de prazos e deadlines

### **A Implementar com Foco em UX Avançada**:
- 🔲 **Dashboard no Perfil**: Abas Perfil + Dashboard + Agenda responsivos
- 🔲 **Agenda Completa**: Interface de calendário com eventos jurídicos
- 🔲 **Agenda por Caso**: Botão de agenda em cada caso individual (rota: `/case-detail/$caseId/agenda`)
- 🔲 **Integrações Calendar**: Google Calendar e Outlook/Exchange
- 🔲 **Diferenciação PF/PJ**: Dashboards e agendas específicos
- 🔲 **IA & Insights**: Dashboard inteligente com predições
- 🔲 **Notificações Smart**: Sistema de alertas contextuais
- 🔲 **Visualizações Avançadas**: Heatmaps e timelines interativas
- 🔲 **Loading States**: Skeleton loading para melhor experiência
- 🔲 **Acessibilidade**: Semantic labels e navegação por voz
- 🔲 **Dark Mode**: Suporte completo a tema escuro

### **✅ Especificações Completas Documentadas**:
- ✅ **Sistema de Exportação Cloud-Integrada**: Especificação completa abaixo
- ✅ **Agenda Jurídica Integrada**: Especificação completa acima

## ☁️ **Sistema de Exportação Cloud-Integrada para Clientes**

### **Visão Geral**
Sistema moderno de exportação e compartilhamento que transforma os dashboards cliente em plataforma colaborativa conectada à nuvem, permitindo acesso e compartilhamento profissional dos dados jurídicos.

### **🎯 Templates de Exportação Específicos para Clientes**

#### **Cliente Pessoa Física (PF):**
- **"Relatório Pessoal"**: Histórico completo, ROI, documentos centralizados
- **"Prestação de Contas"**: Resumo financeiro para declaração IR
- **"Portfólio Jurídico"**: Casos resolvidos, recomendações, satisfação

#### **Cliente Pessoa Jurídica (PJ):**
- **"Relatório Executivo Trimestral"**: Métricas departamentais, compliance, ROI
- **"Dashboard Diretoria"**: KPIs consolidados, análise de custos, tendências
- **"Relatório de Compliance"**: Status regulatório, auditorias, riscos mitigados

### **📧 Funcionalidades de Exportação por E-mail**

```dart
class ClientEmailExportFlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Compartilhar Dashboard', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 20),
            
            // Seletor de template específico para cliente
            ClientTemplateSelector(
              clientType: widget.clientType,
              templates: _getClientTemplates(),
              onChanged: (template) => _updateSelectedTemplate(template),
            ),
            
            SizedBox(height: 16),
            
            // Lista de destinatários com sugestões
            ClientRecipientsList(
              suggestions: [
                'Contador responsável',
                'Advogado principal', 
                'Sócio da empresa',
                'Departamento financeiro'
              ],
            ),
            
            SizedBox(height: 16),
            
            // Agendamento para relatórios recorrentes
            ClientScheduleSelector(
              frequencies: ['Mensal', 'Trimestral', 'Semestral', 'Anual'],
              onScheduled: (schedule) => _setupRecurringExport(schedule),
            ),
            
            SizedBox(height: 16),
            
            // Preview personalizado
            ClientEmailPreview(
              template: _selectedTemplate,
              clientType: widget.clientType,
            ),
            
            SizedBox(height: 20),
            
            Row(
              children: [
                OutlinedButton(
                  onPressed: _saveAsDraft,
                  child: Text('Salvar Rascunho'),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.send),
                  label: Text('Enviar Agora'),
                  onPressed: _sendClientReport,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### **📊 Integração Google Sheets para Clientes**

```dart
class ClientGoogleSheetsIntegration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Exportar para Google Sheets', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          
          // Mapeamento específico para dados do cliente
          ClientDataMappingTable(
            sourceFields: widget.clientType == ClientType.individual 
              ? ['ROI Total', 'Casos Ativos', 'Gastos Anuais', 'Satisfação Média']
              : ['Budget Anual', 'Compliance Score', 'ROI Departamental', 'Casos por Área'],
            targetSheet: 'Dashboard_Cliente_${widget.clientType}',
          ),
          
          SizedBox(height: 16),
          
          // Preview da planilha
          GoogleSheetsPreview(
            sheetType: widget.clientType,
            dataPreview: _getClientDataPreview(),
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.table_chart),
                label: Text('Criar Planilha'),
                onPressed: _createClientSpreadsheet,
              ),
              SizedBox(width: 12),
              OutlinedButton.icon(
                icon: Icon(Icons.sync),
                label: Text('Sincronizar'),
                onPressed: _syncWithExistingSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### **⏰ Agendamento Automático para Clientes**

```dart
class ClientBackupScheduling extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Relatórios Automáticos', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            
            // Frequência específica para clientes
            DropdownButtonFormField<ClientReportFrequency>(
              decoration: InputDecoration(labelText: 'Frequência de Relatórios'),
              items: [
                DropdownMenuItem(value: ClientReportFrequency.monthly, child: Text('Mensal (para controle financeiro)')),
                DropdownMenuItem(value: ClientReportFrequency.quarterly, child: Text('Trimestral (para acompanhamento estratégico)')),
                DropdownMenuItem(value: ClientReportFrequency.yearly, child: Text('Anual (para declaração IR/auditoria)')),
              ],
              onChanged: (value) => _updateFrequency(value),
            ),
            
            SizedBox(height: 16),
            
            // Templates automáticos por tipo de cliente
            Text('Templates Incluídos:', style: Theme.of(context).textTheme.titleMedium),
            ...getClientAutoTemplates().map((template) => CheckboxListTile(
              title: Text(template.name),
              subtitle: Text(template.description),
              value: _selectedTemplates.contains(template),
              onChanged: (selected) => _toggleTemplate(template, selected),
            )),
            
            SizedBox(height: 16),
            
            // Destinos específicos para clientes
            Text('Destinos dos Relatórios:', style: Theme.of(context).textTheme.titleMedium),
            Column(
              children: [
                CheckboxListTile(
                  leading: Icon(Icons.email),
                  title: Text('E-mail do responsável financeiro'),
                  value: _emailEnabled,
                  onChanged: (value) => _toggleEmailDestination(value),
                ),
                CheckboxListTile(
                  leading: Icon(Icons.cloud),
                  title: Text('Google Drive (pasta "Relatórios Jurídicos")'),
                  value: _driveEnabled,
                  onChanged: (value) => _toggleDriveDestination(value),
                ),
                CheckboxListTile(
                  leading: Icon(Icons.folder_shared),
                  title: Text('OneDrive (compartilhado com contador)'),
                  value: _onedriveEnabled,
                  onChanged: (value) => _toggleOneDriveDestination(value),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Preview do próximo relatório
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Próximo relatório: ${_getNextReportDate()}'),
                        Text(
                          'Incluirá: ${_getSelectedTemplatesCount()} templates, ${_getDestinationsCount()} destinos',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### **📋 Histórico de Exportações do Cliente**

```dart
class ClientExportHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtros específicos para clientes
        ClientExportFilters(
          filters: [
            'Todos os relatórios',
            'Relatórios Pessoais',
            'Prestação de Contas', 
            'Relatórios Executivos',
            'Compliance Reports'
          ],
          onFilterChanged: (filter) => _applyClientFilter(filter),
        ),
        
        // Lista de exportações com contexto cliente
        Expanded(
          child: ListView.builder(
            itemCount: _clientExports.length,
            itemBuilder: (context, index) {
              final export = _clientExports[index];
              return ClientExportHistoryCard(
                export: export,
                onRedownload: () => _redownloadClientReport(export),
                onShare: () => _shareClientReport(export), 
                onScheduleRecurrence: () => _scheduleRecurring(export),
                onAddToFavorites: () => _addToFavoriteTemplates(export),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ClientExportHistoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getClientTemplateColor(export.template),
          child: Icon(_getClientTemplateIcon(export.template), color: Colors.white),
        ),
        title: Text(export.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${export.template.displayName} • ${export.formattedFileSize}'),
            Row(
              children: [
                Icon(Icons.access_time, size: 12),
                SizedBox(width: 4),
                Text(
                  'Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(export.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (export.wasShared) 
              Row(
                children: [
                  Icon(Icons.share, size: 12, color: Colors.blue),
                  SizedBox(width: 4),
                  Text('Compartilhado com ${export.sharedWith.length} pessoas',
                    style: TextStyle(fontSize: 12, color: Colors.blue)),
                ],
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleClientExportAction(action, export),
          itemBuilder: (context) => [
            if (export.status == ExportStatus.completed) ...[ 
              PopupMenuItem(value: 'download', child: Row(children: [Icon(Icons.download), SizedBox(width: 8), Text('Baixar')])),
              PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share), SizedBox(width: 8), Text('Compartilhar')])),
              PopupMenuItem(value: 'email', child: Row(children: [Icon(Icons.email), SizedBox(width: 8), Text('Enviar por Email')])),
            ],
            PopupMenuItem(value: 'schedule', child: Row(children: [Icon(Icons.schedule), SizedBox(width: 8), Text('Agendar Recorrência')])),
            PopupMenuItem(value: 'favorite', child: Row(children: [Icon(Icons.star), SizedBox(width: 8), Text('Favoritar Template')])),
            PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete), SizedBox(width: 8), Text('Excluir')])),
          ],
        ),
      ),
    );
  }
}
```

### **🔗 Recursos de Compartilhamento para Clientes**

```dart
class ClientSharingFeatures extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Geração de link para cliente
        ClientShareableLinkGenerator(
          linkTypes: [
            'Link público (visualização)',
            'Link privado (senha protegida)',
            'Link temporário (7 dias)',
            'Link para contador/advogado'
          ],
        ),
        
        SizedBox(height: 24),
        
        // QR Code para acesso rápido  
        ClientQRCodeGenerator(
          qrTypes: [
            'Dashboard resumo',
            'Relatório específico', 
            'Histórico completo'
          ],
        ),
        
        SizedBox(height: 24),
        
        // Configurações de privacidade específicas
        ClientPrivacySettings(
          privacyLevels: [
            'Público: Qualquer pessoa com link',
            'Restrito: Apenas e-mails autorizados',
            'Privado: Apenas você e profissionais contratados'
          ],
        ),
      ],
    );
  }
}

class ClientShareableLinkGenerator extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compartilhamento de Dashboard Cliente', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 12),
            
            // Seleção do tipo de compartilhamento
            DropdownButtonFormField<ClientSharingType>(
              decoration: InputDecoration(labelText: 'Tipo de Compartilhamento'),
              items: [
                DropdownMenuItem(value: ClientSharingType.public, child: Text('Público (apenas visualização)')),
                DropdownMenuItem(value: ClientSharingType.protected, child: Text('Protegido por senha')), 
                DropdownMenuItem(value: ClientSharingType.professional, child: Text('Apenas profissionais jurídicos')),
                DropdownMenuItem(value: ClientSharingType.accountant, child: Text('Compartilhar com contador')),
              ],
              onChanged: (value) => _updateSharingType(value),
            ),
            
            SizedBox(height: 12),
            
            // Campo do link gerado
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _linkController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Link será gerado após configurar tipo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: _hasLink ? _copyClientLink : null,
                  tooltip: 'Copiar link',
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.link),
                  label: Text(_hasLink ? 'Regenerar Link' : 'Gerar Link Seguro'),
                  onPressed: _generateClientShareableLink,
                ),
                SizedBox(width: 12),
                if (_hasLink)
                  OutlinedButton.icon(
                    icon: Icon(Icons.share),
                    label: Text('Enviar'),
                    onPressed: _showClientShareOptions,
                  ),
              ],
            ),
            
            if (_hasLink) ...[ 
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getSharingSecurityInfo(),
                        style: TextStyle(fontSize: 12, color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### **☁️ Integrações Cloud para Clientes**

```dart
class ClientCloudIntegrations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Integração Google Drive
        CloudIntegrationCard(
          service: CloudService.googleDrive,
          title: 'Google Drive',
          description: 'Sincronize relatórios automaticamente',
          features: [
            'Pasta "Documentos Jurídicos" automática',
            'Backup diário dos dashboards',
            'Compartilhamento com contador/advogado',
            'Histórico versionado'
          ],
          onConnect: () => _connectGoogleDrive(),
        ),
        
        SizedBox(height: 16),
        
        // Integração OneDrive
        CloudIntegrationCard(
          service: CloudService.oneDrive,
          title: 'Microsoft OneDrive',
          description: 'Integração com Office 365',
          features: [
            'Exportação para Excel nativo',
            'Power BI dashboard integration',
            'Teams sharing automático',
            'Outlook calendar events'
          ],
          onConnect: () => _connectOneDrive(),
        ),
        
        SizedBox(height: 16),
        
        // Integração Dropbox
        CloudIntegrationCard(
          service: CloudService.dropbox,
          title: 'Dropbox Business',
          description: 'Colaboração profissional',
          features: [
            'Pasta compartilhada com escritório',
            'Paper docs com insights',
            'Assinatura digital integrada',
            'Auditoria de acesso'
          ],
          onConnect: () => _connectDropbox(),
        ),
      ],
    );
  }
}

class CloudIntegrationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getServiceColor(service),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getServiceIcon(service), color: Colors.white, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      Text(description, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                _buildConnectionStatus(),
              ],
            ),
            
            SizedBox(height: 12),
            
            Text('Recursos:', style: Theme.of(context).textTheme.titleSmall),
            ...features.map((feature) => Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.check, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(child: Text(feature, style: TextStyle(fontSize: 13))),
                ],
              ),
            )),
            
            SizedBox(height: 12),
            
            Row(
              children: [
                if (_isConnected) ...[ 
                  ElevatedButton.icon(
                    icon: Icon(Icons.sync),
                    label: Text('Sincronizar'),
                    onPressed: _syncWithService,
                  ),
                  SizedBox(width: 8),
                  OutlinedButton(
                    child: Text('Configurar'),
                    onPressed: _configureService,
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    icon: Icon(Icons.link),
                    label: Text('Conectar'),
                    onPressed: onConnect,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### **📊 Indicadores de Status para Clientes**

```dart
class ClientSyncStatusIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getClientStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getClientStatusColor(status).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildClientStatusIcon(),
          SizedBox(width: 8),
          Text(
            _getClientStatusText(),
            style: TextStyle(
              color: _getClientStatusColor(status),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
```

## 🔧 **Funcionalidades Técnicas Avançadas do Sistema Cliente**

### **1. Sistema de Exportação por Email Avançado**

```dart
class AdvancedClientEmailSystem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClientEmailConfigurationWizard(
      steps: [
        // Configuração de destinatários
        EmailRecipientsStep(
          individualRecipients: true,
          groupManagement: true,
          tags: ['Contador', 'Advogado', 'Família', 'Sócios'],
          validation: (recipients) => _validateLegalEmails(recipients),
        ),
        
        // Preview do email
        EmailPreviewStep(
          livePreview: true,
          templateCustomization: true,
          brandingOptions: ['Cliente PF', 'Cliente PJ', 'Neutro'],
        ),
        
        // Configuração de anexos
        AttachmentConfigStep(
          formats: ['PDF', 'Excel', 'CSV', 'JSON'],
          compression: true,
          encryption: true, // Para dados jurídicos sensíveis
          digitalSignature: true, // Validade jurídica
        ),
      ],
      
      // Recursos específicos para área jurídica
      legalFeatures: ClientLegalEmailFeatures(
        disclaimerAutomatic: true,
        confidentialityNotice: true,
        attorneyClientPrivilege: true,
        retentionPolicyInfo: true,
      ),
    );
  }
}

// Logs de entrega para compliance
class ClientEmailDeliveryLogs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: [
        DataColumn(label: Text('Data/Hora')),
        DataColumn(label: Text('Destinatário')),
        DataColumn(label: Text('Tipo Relatório')),
        DataColumn(label: Text('Status Entrega')),
        DataColumn(label: Text('Confirmação Leitura')), // Importante para área jurídica
        DataColumn(label: Text('Ações')),
      ],
      rows: _buildEmailLogRows(),
    );
  }
}
```

### **2. Integração Google Sheets com Compliance Jurídico**

```dart
class LegalCompliantGoogleSheetsIntegration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Autenticação OAuth 2.0 com verificação jurídica
        GoogleWorkspaceAuthCard(
          requiredScopes: [
            'spreadsheets.readonly',
            'drive.file',
            'audit.reports.readonly' // Para compliance
          ],
          complianceChecks: [
            'Verificação LGPD',
            'Auditoria de acesso',
            'Criptografia em trânsito',
            'Retenção de dados'
          ],
        ),
        
        // Mapeamento de campos específico para área jurídica
        LegalDataMappingInterface(
          clientFields: widget.clientType == ClientType.individual
            ? {
                'CPF': 'A1',
                'Nome Completo': 'B1', 
                'Casos Ativos': 'C1',
                'Valor Total Investido': 'D1',
                'ROI Jurídico': 'E1',
                'Última Atualização': 'F1',
                'Status Compliance': 'G1'
              }
            : {
                'CNPJ': 'A1',
                'Razão Social': 'B1',
                'Departamento Jurídico': 'C1',
                'Budget Anual': 'D1',
                'Compliance Score': 'E1',
                'Auditorias Pendentes': 'F1',
                'ROI Departamental': 'G1'
              },
          
          // Formatação automática baseada no tipo
          autoFormatting: {
            'Valores Monetários': 'R$ #,##0.00',
            'Percentuais': '0.00%',
            'Datas': 'DD/MM/AAAA',
            'CPF/CNPJ': '@', // Texto para preservar formatação
          },
          
          // Controle de permissões
          permissionsControl: GoogleSheetsPermissions(
            viewOnly: false,
            editRestricted: true,
            auditTrail: true,
            shareRestrictions: ['@clientedomain.com', '@advocaciapartner.com'],
          ),
        ),
        
        // Sincronização bidirecional
        BidirectionalSyncConfig(
          readFromSheets: true,
          writeToSheets: true,
          conflictResolution: ConflictResolution.clientPriority,
          syncFrequency: SyncFrequency.realTime,
          backupBeforeSync: true,
        ),
      ],
    );
  }
}
```

### **3. Agendamento de Backups com Compliance Legal**

```dart
class LegalCompliantBackupScheduler extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Templates pré-definidos para área jurídica
          LegalBackupTemplates(
            templates: [
              BackupTemplate(
                name: 'Backup Compliance Diário',
                frequency: 'Diário às 2:00',
                includes: ['Dados sensíveis', 'Documentos', 'Logs de auditoria'],
                retention: '7 anos', // Retenção legal
                encryption: 'AES-256',
              ),
              BackupTemplate(
                name: 'Relatório Mensal IR',
                frequency: 'Último dia útil do mês',
                includes: ['Dados financeiros', 'ROI', 'Gastos'],
                retention: '5 anos',
                format: 'PDF assinado digitalmente',
              ),
              BackupTemplate(
                name: 'Auditoria Trimestral',
                frequency: 'Trimestral',
                includes: ['Compliance full', 'Histórico completo'],
                retention: '10 anos',
                recipients: ['Contador', 'Auditor externo'],
              ),
            ],
          ),
          
          // Configuração de janelas de manutenção
          MaintenanceWindowConfig(
            allowedHours: ['2:00-4:00', '22:00-23:59'],
            excludeDates: ['Feriados nacionais', 'Finais de semana críticos'],
            timezone: 'America/Sao_Paulo',
          ),
          
          // Sistema de retry automático
          AutoRetryConfig(
            maxRetries: 3,
            retryInterval: Duration(minutes: 30),
            escalation: EscalationConfig(
              afterFailures: 2,
              notifyContacts: ['TI', 'Compliance Officer'],
              fallbackStorage: 'Local + Nuvem secundária',
            ),
          ),
          
          // Tipos de backup específicos para clientes
          ClientBackupTypes(
            types: [
              'Backup Completo Histórico',
              'Backup Incremental Diário', 
              'Backup Configurações Dashboard',
              'Backup Relatórios Assinados',
              'Backup Documentos Jurídicos',
              'Backup Logs Auditoria'
            ],
          ),
        ],
      ),
    );
  }
}
```

### **4. Rastreamento Avançado com Auditoria Legal**

```dart
class LegalAuditTrailInterface extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dados rastreados específicos para compliance
        AuditDataTracker(
          trackedFields: [
            'Timestamp com fuso horário',
            'Usuário + IP + Device fingerprint',
            'Tipo de relatório + classificação sensibilidade',
            'Formato + assinatura digital',
            'Destinatários + confirmação recebimento',
            'Status operação + códigos erro',
            'Tamanho arquivo + hash integridade',
            'Versão dados + snapshot momento',
            'Geolocalização acesso',
            'Duração sessão + ações realizadas'
          ],
        ),
        
        // Interface de histórico com filtros legais
        LegalHistoryInterface(
          filters: [
            FilterGroup(
              name: 'Compliance',
              filters: ['LGPD', 'Auditoria', 'Retenção Legal', 'Confidencial']
            ),
            FilterGroup(
              name: 'Tipo Documento', 
              filters: ['Contrato', 'Petição', 'Parecer', 'Relatório', 'Procuração']
            ),
            FilterGroup(
              name: 'Status Legal',
              filters: ['Ativo', 'Arquivado', 'Sob Sigilo', 'Público']
            ),
          ],
          
          // Visualização em timeline para casos jurídicos
          timelineView: true,
          chronologicalOrder: true,
          legalMilestones: true,
          
          // Exportação de auditoria
          auditExport: AuditExportOptions(
            formats: ['PDF assinado', 'JSON', 'CSV'],
            includeHashVerification: true,
            digitalSignature: true,
            notarization: true, // Para validade jurídica
          ),
        ),
      ],
    );
  }
}
```

### **5. Compartilhamento Avançado com Segurança Jurídica**

```dart
class LegalSecureSharing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Geração de links com controles jurídicos
        LegalShareableLinkGenerator(
          securityLevels: [
            SecurityLevel.public(
              name: 'Público Geral',
              restrictions: 'Apenas visualização, dados anonimizados',
              watermark: true,
            ),
            SecurityLevel.protected(
              name: 'Protegido por OTP',
              authentication: '2FA via SMS/Email',
              sessionTimeout: Duration(hours: 2),
            ),
            SecurityLevel.professional(
              name: 'Apenas Profissionais Jurídicos',
              validation: 'OAB + CPF verification',
              auditLog: true,
              disclaimer: 'Sigilo profissional',
            ),
            SecurityLevel.privileged(
              name: 'Sigilo Advogado-Cliente', 
              encryption: 'End-to-end',
              accessLog: 'Completo com geolocalização',
              autoDestruct: Duration(days: 30),
            ),
          ],
          
          // Controles de acesso granulares
          accessControls: [
            'IP whitelisting por escritório',
            'Geo-blocking internacional',
            'Horário comercial restrito',
            'Device fingerprinting',
            'Concurrent session limits'
          ],
        ),
        
        // QR Codes com segurança legal
        LegalQRCodeGenerator(
          qrTypes: [
            QRType.dashboardSummary(
              dataLevel: 'Resumo executivo',
              encryption: true,
              timeToLive: Duration(hours: 24),
            ),
            QRType.specificReport(
              reportType: 'Confidencial',
              requiresAuthentication: true,
              auditTrail: true,
            ),
            QRType.fullHistory(
              accessLevel: 'Privilégio advogado-cliente',
              multiFactorAuth: true,
              notarization: true,
            ),
          ],
          
          // Recursos de segurança
          securityFeatures: [
            'Criptografia AES-256',
            'Assinatura digital incorporada',
            'Tracking de scans com localização',
            'Auto-destruição após expiração',
            'Watermark com timestamp'
          ],
        ),
      ],
    );
  }
}
```

### **6. Templates Especializados para Área Jurídica**

```dart
enum LegalClientTemplate {
  // Para Pessoa Física
  personalLegalReport('Relatório Jurídico Pessoal', {
    'sections': ['historico_casos', 'roi_investimento', 'documentos_validos', 'prazos_importantes'],
    'charts': ['evolucao_gastos', 'sucesso_por_area', 'timeline_processos'],
    'format': 'relatorio_pessoal_assinado',
    'compliance': ['LGPD', 'sigilo_advocaticio']
  }),
  
  taxAccountingReport('Prestação de Contas IR', {
    'sections': ['gastos_dedutiveis', 'honorarios_pagos', 'documentos_fiscais'],
    'charts': ['distribuicao_gastos', 'evolucao_anual'],
    'format': 'declaracao_ir_compativel',
    'compliance': ['receita_federal', 'auditoria_fiscal']
  }),
  
  legalPortfolio('Portfólio Jurídico', {
    'sections': ['casos_ganhos', 'especializacoes', 'recomendacoes'],
    'charts': ['taxa_sucesso', 'areas_atuacao', 'satisfacao_temporal'],
    'format': 'portfolio_profissional',
    'compliance': ['marketing_juridico', 'etica_oab']
  }),
  
  // Para Pessoa Jurídica
  corporateComplianceReport('Relatório de Compliance Corporativo', {
    'sections': ['status_regulatorio', 'auditorias_internas', 'riscos_mitigados', 'planos_acao'],
    'charts': ['score_compliance', 'evolucao_riscos', 'areas_criticas'],
    'format': 'relatorio_executivo_assinado',
    'compliance': ['sox', 'lgpd', 'iso_27001', 'auditoria_externa']
  }),
  
  executiveLegalDashboard('Dashboard Executivo Jurídico', {
    'sections': ['kpis_departamento', 'roi_juridico', 'benchmarking_mercado'],
    'charts': ['custos_por_area', 'performance_advogados', 'tendencias_litigios'],
    'format': 'dashboard_c_level',
    'compliance': ['governanca_corporativa', 'relatorio_diretoria']
  }),
  
  quarterlyLegalReview('Revisão Trimestral Jurídica', {
    'sections': ['metricas_periodo', 'casos_relevantes', 'mudancas_regulatorias'],
    'charts': ['evolucao_trimestral', 'distribuicao_recursos', 'previsoes'],
    'format': 'relatorio_trimestral_completo',
    'compliance': ['planning_estrategico', 'budget_review']
  });
}

class LegalTemplateBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TemplateConfigurationWizard(
      templates: LegalClientTemplate.values,
      customizationOptions: [
        'Logo e branding cliente',
        'Disclaimer jurídico personalizado', 
        'Assinatura digital automática',
        'Watermark com timestamp',
        'Criptografia por seção',
        'Níveis de confidencialidade',
        'Auditoria de acesso incorporada'
      ],
      
      outputFormats: [
        'PDF assinado digitalmente',
        'Excel com proteção por senha',
        'JSON criptografado para APIs',
        'Blockchain timestamped (para evidências)',
        'Print-friendly com QR verification'
      ],
    );
  }
}
```

### **7. Integrações Corporativas Específicas da Área Jurídica**

```dart
class LegalCorporateIntegrations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sistema de Gestão Jurídica
        LegalSystemIntegration(
          systems: [
            'Projuris (Gestão de escritórios)',
            'Astrea (Contratos e documentos)', 
            'LexOne (Pesquisa jurisprudencial)',
            'Themis (Gestão de processos)',
            'Sage (Controle financeiro jurídico)'
          ],
          syncCapabilities: [
            'Importação de dados processuais',
            'Sincronização de honorários',
            'Update automático de prazos',
            'Integração timeline casos'
          ],
        ),
        
        // Tribunais e Órgãos Públicos
        PublicSystemIntegration(
          systems: [
            'PJe (Processo Judicial Eletrônico)',
            'SEEU (Sistema Eletrônico de Execução Unificado)',
            'Portal e-SAJ',
            'Receita Federal (Consultas CNPJ/CPF)',
            'SERASA/SPC (Consultas de crédito)'
          ],
          automations: [
            'Monitoramento automático de processos',
            'Alertas de movimentação processual', 
            'Download automático de decisões',
            'Atualização status casos'
          ],
        ),
        
        // Ferramentas de Comunicação Jurídica
        LegalCommunicationIntegration(
          platforms: [
            'Microsoft Teams (com compliance)',
            'Slack (canais por caso)',
            'WhatsApp Business (atendimento cliente)',
            'Email corporativo (assinatura digital)',
            'Zoom (audiências virtuais)'
          ],
          features: [
            'Notificações de prazos críticos',
            'Compartilhamento seguro de documentos',
            'Gravação e transcrição de reuniões',
            'Lembretes automáticos de audiências'
          ],
        ),
      ],
    );
  }
}
```

### **8. Armazenamento e Compliance com Marco Civil**

```dart
class LegalCompliantCloudStorage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Provedores com data center no Brasil (Marco Civil)
        BrazilianCloudProviders(
          providers: [
            CloudProvider(
              name: 'AWS São Paulo',
              region: 'sa-east-1',
              compliance: ['LGPD', 'Marco Civil', 'ISO 27001'],
              dataResidency: 'Brasil',
              encryption: 'AES-256 at rest + in transit'
            ),
            CloudProvider(
              name: 'Google Cloud São Paulo', 
              region: 'southamerica-east1',
              compliance: ['LGPD', 'SOC 2', 'ISO 27017'],
              dataResidency: 'Brasil',
              backup: 'Multi-region dentro do Brasil'
            ),
            CloudProvider(
              name: 'Microsoft Azure Brasil',
              region: 'Brazil South',
              compliance: ['LGPD', 'ISO 27018', 'PCI DSS'],
              dataResidency: 'Brasil',
              integration: 'Office 365 local'
            ),
          ],
        ),
        
        // Indicadores de status com compliance
        LegalComplianceStatusIndicators(
          indicators: [
            StatusIndicator(
              icon: Icons.security,
              status: 'LGPD Compliant',
              color: Colors.green,
              details: 'Dados pessoais protegidos conforme Lei 13.709/2018'
            ),
            StatusIndicator(
              icon: Icons.location_on,
              status: 'Data Residency BR',
              color: Colors.blue,
              details: 'Dados armazenados exclusivamente no Brasil'
            ),
            StatusIndicator(
              icon: Icons.verified_user,
              status: 'Sigilo Profissional',
              color: Colors.purple,
              details: 'Proteção advogado-cliente garantida'
            ),
            StatusIndicator(
              icon: Icons.backup,
              status: 'Backup 7 anos',
              color: Colors.orange,
              details: 'Retenção conforme prazo legal'
            ),
          ],
        ),
        
        // Métricas específicas para área jurídica
        LegalStorageMetrics(
          metrics: [
            'Documentos sob sigilo: Criptografados separadamente',
            'Processos ativos: Backup diário automático',
            'Dados históricos: Compressão com verificação integridade',
            'Logs auditoria: Imutáveis com timestamp blockchain',
            'Custos compliance: R$ xxx/mês por requisitos legais'
          ],
        ),
      ],
    );
  }
}
```

### **💡 Benefícios do Sistema Cloud Avançado para Clientes**

#### **Para Cliente Pessoa Física (PF):**
- ✅ **Compliance LGPD**: Proteção completa de dados pessoais
- ✅ **Validade Jurídica**: Documentos com assinatura digital e timestamp
- ✅ **Backup Legal**: Retenção automática por 7 anos
- ✅ **Acesso Seguro**: 2FA e auditoria completa de acessos
- ✅ **Integração IR**: Relatórios prontos para Receita Federal

#### **Para Cliente Pessoa Jurídica (PJ):**
- ✅ **Governança Corporativa**: Dashboards executivos com trilha de auditoria
- ✅ **Compliance Multi-regulatório**: SOX, LGPD, ISO 27001 automatizado
- ✅ **Integração ERP/CRM**: Conexão com sistemas corporativos
- ✅ **Relatórios C-Level**: Templates executivos prontos para diretoria
- ✅ **Auditoria Externa**: Evidências digitais para auditores

### **🎯 Métricas de Sucesso Sistema Cloud Cliente**

#### **Adoção:**
- **Taxa de uso**: > 75% dos clientes usando exportação cloud
- **Templates favoritos**: > 3 templates salvos por cliente PJ
- **Compartilhamentos**: > 2 links gerados por mês (PF), > 5 (PJ)

#### **Engagement:**
- **Relatórios agendados**: > 60% dos clientes com backup automático
- **Integração cloud**: > 40% conectados a pelo menos 1 serviço
- **Satisfação**: > 4.6/5 para funcionalidades de exportação

## 🎨 **Especificações de Interface Cliente**

### **Layout Principal do Centro de Exportação**
```
Header: Logo LITIG-1 + Menu Cliente + Notificações Jurídicas + User Menu
Sidebar Cliente: 
  - 📊 Dashboard Overview
  - ☁️ Centro de Exportação 🎯
  - ⏰ Agendamentos Legais
  - 📋 Histórico Compliance
  - 🔗 Integrações Jurídicas
  - ⚙️ Configurações LGPD

Main Content Area:
  - Quick Actions Panel (templates jurídicos)
  - Status Overview Cards (compliance, backup, sync)
  - Recent Exports Table (com auditoria)
  - Legal Integration Status Grid
  - Compliance Dashboard Widget
```

### **Componentes UI Específicos para Clientes**
```
- Legal Export Configuration Wizard (PF/PJ específico)
- Real-time Compliance Status Dashboard
- Drag-and-drop Legal Template Builder
- Interactive Legal Calendar (prazos, audiências)
- Progress Bars para Operações Longas (backup, auditoria)
- Legal Toast Notifications (alertas críticos)
- Modal Dialogs com Disclaimer Jurídico
- Expandable Legal Detail Panels
- LGPD Consent Management Interface
- Digital Signature Verification Widget
```

## 🔒 **Requisitos de Segurança Específicos para Área Jurídica**

### **Autenticação e Autorização Jurídica**
- **Multi-factor Authentication (MFA)** obrigatório para dados sensíveis
- **Role-based Access Control (RBAC)** com níveis jurídicos:
  - Cliente Individual (PF)
  - Cliente Corporativo (PJ) 
  - Contador Autorizado
  - Advogado Responsável
  - Auditor Externo
- **Single Sign-On (SSO)** com OAB integration
- **API token management** com escopo jurídico

### **Proteção de Dados Jurídicos**
- **Encryption at rest (AES-256)** para todos os documentos
- **Encryption in transit (TLS 1.3)** obrigatório
- **Data anonymization** para relatórios públicos
- **LGPD compliance** completo com:
  - Consentimento explícito
  - Direito ao esquecimento
  - Portabilidade de dados
  - Relatório de impacto
- **Audit trails completos** imutáveis
- **Digital signature** em todos os documentos críticos

### **Controles de Acesso Jurídico**
- **IP whitelisting** por escritório/contador
- **Geo-blocking** para países sem tratado jurídico
- **Horário comercial** restrito para dados sensíveis
- **Session timeout** baseado em classificação de dados
- **Concurrent session limits** por tipo de usuário

## 📊 **Métricas e Monitoramento Jurídico**

### **KPIs Específicos do Sistema Cliente**
- **Success rate** de exportações críticas > 99.5%
- **Compliance score** LGPD automático
- **Tempo médio** de processamento relatórios < 15s
- **Volume** de dados exportados com classificação
- **Utilização** de integrações jurídicas
- **User engagement** metrics específicas PF/PJ

### **Alertas Automáticos Jurídicos**
- **Falhas** de exportação/sincronização críticas
- **Limites** de armazenamento com impacto compliance
- **Anomalias** nos dados jurídicos
- **Tentativas** de acesso não autorizado com geolocalização
- **Performance** degradation com impacto SLA
- **Prazos** processuais próximos
- **Vencimento** de documentos importantes
- **Auditorias** agendadas pendentes

## 🚀 **Fases de Implementação para Clientes**

### **Fase 1 - Core Legal Features (Sprints 1-3)**
- Sistema básico de exportação com compliance LGPD
- Templates fundamentais PF/PJ
- Histórico de exportações com auditoria
- Integração email com disclaimer jurídico
- Backup básico com retenção legal

### **Fase 2 - Cloud Integrations Jurídicas (Sprints 4-6)**  
- Google Sheets integration com compliance
- Cloud storage providers brasileiros
- Sistema de agendamento legal
- Status monitoring com alertas críticos
- Integração básica com sistemas jurídicos

### **Fase 3 - Advanced Legal Features (Sprints 7-9)**
- Sharing capabilities com níveis de segurança
- QR code generation com criptografia
- Advanced templates especializados
- Mobile optimization para acesso campo
- Digital signature integration

### **Fase 4 - Enterprise Legal Integrations (Sprints 10-12)**
- Integração PJe, e-SAJ, Receita Federal
- Advanced security features (blockchain)
- Analytics and reporting executivo
- Performance optimization
- Auditoria externa compliance

## 🧪 **Critérios de Teste Específicos para Área Jurídica**

### **Testes Funcionais Jurídicos**
- Todos os fluxos de exportação com validação legal
- Integrações com APIs de tribunais/órgãos públicos
- Agendamento e automação de relatórios críticos
- Compartilhamento e segurança com níveis jurídicos
- Compliance LGPD e Marco Civil
- Digital signature validation
- Backup e recovery com retenção legal

### **Testes de Performance Jurídica**
- Load testing com volumes empresariais grandes
- Concurrent user testing (escritórios, departamentos)
- API response times críticos (< 3s para relatórios)
- Storage/bandwidth optimization com criptografia
- Database performance com dados históricos 7+ anos

### **Testes de Segurança Jurídica**
- Penetration testing específico para dados jurídicos
- Vulnerability scanning com foco LGPD
- Data encryption validation (AES-256)
- Access control verification multi-nível
- Audit trail integrity testing
- Digital signature validation
- Compliance framework testing (LGPD, ISO 27001)

## 📈 **Métricas de Sucesso Específicas para Clientes**

### **Quantitativas Jurídicas**
- **99.9%+** success rate nas exportações críticas
- **< 15s** tempo médio de processamento relatórios
- **99.99%** uptime do sistema (SLA jurídico)
- **< 3s** tempo de carregamento páginas críticas
- **100%** compliance LGPD automático
- **0** vazamentos de dados em auditoria
- **< 24h** resolução incidentes críticos

### **Qualitativas Jurídicas**
- **User satisfaction score >4.7/5** específico clientes
- **Redução de 90%** no tempo manual de reporting
- **Aumento de 80%** na frequência de análise de dados
- **100%** compliance com requisitos de auditoria
- **95%+** aprovação em auditorias externas
- **Redução de 70%** em requests de suporte
- **Aumento de 60%** na adesão a backups automáticos

---

## 💡 **Considerações Adicionais para Área Jurídica**

### **Escalabilidade Jurídica**
- **Arquitetura microserviços** com isolamento por criticidade
- **Containerização** (Docker/Kubernetes) com segurança jurídica
- **Auto-scaling** capabilities com limites compliance
- **CDN brasileiro** para assets estáticos
- **Multi-region** dentro do Brasil (Marco Civil)

### **Manutenibilidade Jurídica**  
- **Documentação técnica** completa com aspectos legais
- **Code review standards** com security checks
- **Automated testing pipeline** com compliance validation
- **Monitoring e observabilidade** com audit trails
- **Change management** com aprovação jurídica

### **Experiência do Usuário Jurídica**
- **Responsive design** otimizado para tablets (campo)
- **Progressive Web App** features com offline compliance
- **Offline capabilities** limitadas para dados não-sensíveis
- **Accessibility compliance** (WCAG 2.1) para inclusão
- **Multi-language** support (português brasileiro)
- **Legal terminology** consistency
- **Contextual help** com referências legais

---

## 📈 **Métricas de Sucesso para Dashboards Cliente**

### **Quantitativas**:
- **Tempo de carregamento**: < 2s para dashboard completo
- **Taxa de erro**: < 0.1% nas interações do dashboard
- **Cobertura de testes**: > 80% nos componentes cliente
- **Performance Score**: > 90 (Lighthouse)

### **Qualitativas**:
- **SUS Score**: > 80 (System Usability Scale)
- **Task Success Rate**: > 95% para tarefas principais
- **User Satisfaction**: > 4.5/5 na experiência do dashboard
- **Error Recovery Rate**: > 90% recuperação de erros

### **Roadmap de UX**:

#### **Fase 1: Fundação (2 semanas)**
- [ ] Implementar abas Perfil + Dashboard responsivo
- [ ] Criar componentes base reutilizáveis PF/PJ
- [ ] Integrar skeleton loading states
- [ ] Adicionar tratamento de erros gracioso

#### **Fase 2: Diferenciação (2 semanas)**
- [ ] Desenvolver métricas específicas PF vs PJ
- [ ] Implementar analytics consolidados
- [ ] Criar sistema de insights personalizados
- [ ] Adicionar documentos centralizados

#### **Fase 3: Acessibilidade (1 semana)**
- [ ] Implementar semantic labels completos
- [ ] Verificar contrastes WCAG 2.1 AA
- [ ] Testar navegação com screen readers
- [ ] Ajustar tamanhos de toque (min 44px)

#### **Fase 4: Polish & Exportação (2 semanas)**
- [ ] Implementar dark mode completo
- [ ] Adicionar micro-interações suaves
- [ ] Criar sistema de exportação de relatórios
- [ ] Otimizar performance e animações

---

## 🎯 **Benefícios da Uniformização**

### **Integração com Sistema LITIG-1**:
- ✅ **Componentes reutilizáveis** entre todos os dashboards da plataforma
- ✅ **Cores contextuais** diferenciadas (PF verde, PJ azul)
- ✅ **Layouts responsivos** unificados
- ✅ **Estados de loading** consistentes
- ✅ **Experiência visual** coesa em toda a plataforma

### **Vantagens para Desenvolvimento**:
- 🔧 **Manutenção simplificada** com componentes base
- 🎨 **Design system** aplicado consistentemente  
- 📱 **Responsividade** padronizada para todos os dispositivos
- ⚡ **Performance otimizada** com reutilização de widgets
- 🧪 **Testabilidade** aprimorada com componentes isolados

### **Experiência do Cliente**:
- 🌟 **Interface familiar** alinhada com resto da plataforma
- 🎯 **Personalização visual** por tipo de cliente (PF/PJ)
- 📊 **Métricas relevantes** e não redundantes
- 🔄 **Navegação intuitiva** e consistente
- 📈 **Insights acionáveis** baseados no perfil

---

**Documento atualizado em**: 20 de Janeiro de 2025  
**Versão**: 1.8 - Navegação + Dashboard + **Agenda Integrada (Unipile Calendar API ✅)** + UX + Sistema Unificado + Exportação Cloud  
**Status**: Página Início ✅ | Dashboard 🔲 + **Agenda Jurídica** ✅ + Design System ✅ + Sistema Cloud ✅ + **Unipile Calendar API** 🆕