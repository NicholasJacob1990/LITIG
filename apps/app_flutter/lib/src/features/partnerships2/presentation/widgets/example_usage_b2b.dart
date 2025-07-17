import 'package:flutter/material.dart';

import '../../../firms/domain/entities/law_firm.dart';
import 'enhanced_firm_card.dart';

/// Exemplo de como usar o sistema B2B completo em uma tela de busca
/// 
/// Este arquivo demonstra a integração de todas as funcionalidades B2B:
/// 1. Renderização mista de advogados e escritórios
/// 2. Navegação contextual interna vs modal
/// 3. Sistema de contratação de escritórios
/// 4. Integração com FirmBloc e estados
class ExampleB2BUsage extends StatefulWidget {
  const ExampleB2BUsage({super.key});

  @override
  State<ExampleB2BUsage> createState() => _ExampleB2BUsageState();
}

class _ExampleB2BUsageState extends State<ExampleB2BUsage> {
  bool showMixedResults = false;
  List<LawFirm> mockFirms = [];

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  void _loadMockData() {
    // Mock data para demonstração
    mockFirms = [
      LawFirm(
        id: '1',
        name: 'Escritório Silva & Associados',
        teamSize: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        mainLat: -23.550520,
        mainLon: -46.633309,
      ),
      LawFirm(
        id: '2',
        name: 'Advocacia Santos & Partners',
        teamSize: 8,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      LawFirm(
        id: '3',
        name: 'Machado Advocacia Empresarial',
        teamSize: 25,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        mainLat: -23.561414,
        mainLon: -46.656219,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema B2B - Exemplo'),
        actions: [
          Switch(
            value: showMixedResults,
            onChanged: (value) {
              setState(() {
                showMixedResults = value;
              });
            },
          ),
          const SizedBox(width: 8),
          const Text('Resultados\nMistos'),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildFirmsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Funcionalidades B2B Implementadas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildFeatureList(),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      '✅ Renderização mista (toggle acima)',
      '✅ Navegação contextual (toque longo no card)',
      '✅ Sistema de contratação (botão "Contratar")',
      '✅ Estados do BLoC integrados',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((feature) => 
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            feature,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildFirmsList() {
    if (mockFirms.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView.builder(
      itemCount: mockFirms.length,
      itemBuilder: (context, index) {
        final firm = mockFirms[index];
        
        if (showMixedResults) {
          return _buildMixedResultCard(firm, index);
        }
        
        return _buildStandardFirmCard(firm);
      },
    );
  }

  Widget _buildMixedResultCard(LawFirm firm, int index) {
    // Simula renderização mista intercalando com dados de advogados
    if (index % 3 == 1) {
      return _buildMockLawyerCard(index);
    }
    
    return EnhancedFirmCard(
      firm: firm,
      showHireButton: true,
      onFirmHire: _handleFirmHire,
      currentCaseId: 'case_123',
      currentClientId: 'client_456',
    );
  }

  Widget _buildStandardFirmCard(LawFirm firm) {
    return EnhancedFirmCard(
      firm: firm,
      showHireButton: true,
      onFirmHire: _handleFirmHire,
      currentCaseId: 'case_123',
      currentClientId: 'client_456',
    );
  }

  Widget _buildMockLawyerCard(int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: const Icon(Icons.person, color: Colors.blue),
        ),
        title: Text('Advogado Mock ${index + 1}'),
        subtitle: const Text('Especialista em Direito Civil'),
        trailing: OutlinedButton(
          onPressed: () => _showMockLawyerHire(index),
          child: const Text('Contratar'),
        ),
      ),
    );
  }

  void _handleFirmHire(String firmId, String caseId, String clientId) {
    debugPrint('🏢 Contratando escritório: $firmId para caso: $caseId (cliente: $clientId)');
    
    // Aqui seria feita a integração com o backend
    // Por exemplo: FirmHiringService.hireFirm(firmId, caseId, clientId)
    
    // Para demonstração, mostramos apenas um log
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Backend: Escritório $firmId contratado para caso $caseId'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showMockLawyerHire(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('👨‍💼 Advogado Mock ${index + 1} contratado'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// Widget helper para demonstrar navegação contextual
class B2BNavigationDemo extends StatelessWidget {
  const B2BNavigationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navegação B2B'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.navigation,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Demonstração de Navegação',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Esta tela demonstra as opções de navegação\ncontextual implementadas no sistema B2B',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildNavigationOptions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationOptions(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.visibility),
          title: const Text('Navegação Interna'),
          subtitle: const Text('Mantém contexto das abas'),
          onTap: () => _showInfo(context, 'Navegação interna ativada'),
        ),
        ListTile(
          leading: const Icon(Icons.fullscreen),
          title: const Text('Navegação Modal'),
          subtitle: const Text('Sobreposição de tela cheia'),
          onTap: () => _showInfo(context, 'Navegação modal ativada'),
        ),
        ListTile(
          leading: const Icon(Icons.group),
          title: const Text('Ver Advogados'),
          subtitle: const Text('Lista de profissionais do escritório'),
          onTap: () => _showInfo(context, 'Lista de advogados ativada'),
        ),
      ],
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
} 