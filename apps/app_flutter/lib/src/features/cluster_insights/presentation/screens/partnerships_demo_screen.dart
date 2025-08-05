import 'package:flutter/material.dart';
import '../widgets/hybrid_partnerships_widget.dart';

/// Tela de demonstração para as funcionalidades de parcerias híbridas
class PartnershipsDemoScreen extends StatelessWidget {
  const PartnershipsDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parcerias Estratégicas - Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showDemoInfo(context),
            icon: const Icon(Icons.info_outline),
            tooltip: 'Informações da Demo',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header informativo
            _buildDemoHeader(context),
            
            // Widget principal de parcerias
            const HybridPartnershipsWidget(
              currentLawyerId: 'demo_lawyer_001',
              showExpandOption: true,
            ),
            
            // Informações adicionais
            _buildDemoFeatures(context),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.rocket_launch, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Partnership Growth Plan - Demo',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sistema híbrido de recomendações com motor de aquisição viral',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeatureChip('Busca Híbrida', Icons.search, Colors.green),
              _buildFeatureChip('Curiosity Gap', Icons.lock_outline, Colors.purple),
              _buildFeatureChip('LinkedIn Integration', Icons.people, Colors.blue),
              _buildFeatureChip('Viral Growth', Icons.trending_up, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  Widget _buildDemoFeatures(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Funcionalidades Implementadas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildFeatureItem(
            context,
            '🟢 Membros Verificados',
            'Cards verdes com informações completas, botão de chat e score detalhado',
            Colors.green,
          ),
          
          _buildFeatureItem(
            context,
            '🟠 Perfis Públicos',
            'Cards laranja com "Curiosity Gap" - score limitado para gerar curiosidade',
            Colors.orange,
          ),
          
          _buildFeatureItem(
            context,
            '📧 Sistema de Convites',
            'Modal de "Notificação Assistida" com mensagem personalizada para LinkedIn',
            Colors.blue,
          ),
          
          _buildFeatureItem(
            context,
            '🔄 Toggle de Busca',
            'Alternar entre busca interna e híbrida com estatísticas em tempo real',
            Colors.purple,
          ),
          
          _buildFeatureItem(
            context,
            '📊 Analytics Integrado',
            'Contadores de perfis internos vs externos e indicadores de IA',
            Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String title, String description, Color color) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDemoInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Informações da Demo'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Esta demo implementa todas as 3 fases do Partnership Growth Plan:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text('✅ Fase 1: Busca híbrida com dados internos e externos'),
              SizedBox(height: 6),
              Text('✅ Fase 2: Sistema de convites com "Notificação Assistida"'),
              SizedBox(height: 6),
              Text('✅ Fase 3: Índice de Engajamento integrado'),
              SizedBox(height: 16),
              Text(
                'Dados Mockados:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Advogados internos verificados'),
              Text('• Perfis públicos externos simulados'),
              Text('• Scores de compatibilidade realistas'),
              Text('• Sistema de convites funcional'),
              SizedBox(height: 16),
              Text(
                'Toggle "Busca Externa" para ver a diferença entre modo interno e híbrido.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
} 