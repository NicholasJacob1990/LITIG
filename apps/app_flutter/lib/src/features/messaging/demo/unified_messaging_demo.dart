import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Demonstração completa do sistema de mensagens unificadas
/// Mostra todas as funcionalidades implementadas
class UnifiedMessagingDemo extends StatefulWidget {
  const UnifiedMessagingDemo({super.key});

  @override
  State<UnifiedMessagingDemo> createState() => _UnifiedMessagingDemoState();
}

class _UnifiedMessagingDemoState extends State<UnifiedMessagingDemo> {
  int _selectedIndex = 0;
  bool _isConnected = false;

  final List<Map<String, dynamic>> _providers = [
    {
      'id': 'linkedin',
      'name': 'LinkedIn',
      'icon': Icons.business,
      'color': Colors.blue.shade700,
      'connected': true,
      'messages': 12,
    },
    {
      'id': 'instagram',
      'name': 'Instagram',
      'icon': Icons.camera_alt,
      'color': Colors.pink.shade500,
      'connected': false,
      'messages': 0,
    },
    {
      'id': 'whatsapp',
      'name': 'WhatsApp',
      'icon': Icons.message,
      'color': Colors.green.shade600,
      'connected': true,
      'messages': 8,
    },
    {
      'id': 'gmail',
      'name': 'Gmail',
      'icon': Icons.email,
      'color': Colors.red.shade500,
      'connected': true,
      'messages': 5,
    },
    {
      'id': 'outlook',
      'name': 'Outlook',
      'icon': Icons.mail_outline,
      'color': Colors.blue.shade600,
      'connected': false,
      'messages': 0,
    },
    {
      'id': 'internal',
      'name': 'Chat Interno',
      'icon': LucideIcons.users,
      'color': Colors.indigo.shade600,
      'connected': true,
      'messages': 15,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Mensagens Unificadas'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildStatusBar(),
          _buildNavigationTabs(),
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green.shade50 : Colors.red.shade50,
        border: Border(
          bottom: BorderSide(
            color: _isConnected ? Colors.green.shade200 : Colors.red.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isConnected ? LucideIcons.wifi : LucideIcons.wifiOff,
            color: _isConnected ? Colors.green.shade600 : Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isConnected 
                ? 'Sistema conectado - Sincronização em tempo real ativa'
                : 'Sistema offline - Reconectando...',
              style: TextStyle(
                color: _isConnected ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: _isConnected,
            onChanged: (value) => setState(() => _isConnected = value),
            activeColor: Colors.green.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTabs() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _buildNavTab(0, 'Visão Geral', LucideIcons.barChart3),
          _buildNavTab(1, 'Provedores', LucideIcons.link),
          _buildNavTab(2, 'Conversas', LucideIcons.messageCircle),
          _buildNavTab(3, 'Configurações', LucideIcons.settings),
        ],
      ),
    );
  }

  Widget _buildNavTab(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.indigo : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.indigo : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.indigo : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildProvidersTab();
      case 2:
        return _buildConversationsTab();
      case 3:
        return _buildSettingsTab();
      default:
        return Container();
    }
  }

  Widget _buildOverviewTab() {
    final connectedProviders = _providers.where((p) => p['connected']).length;
    final totalMessages = _providers.fold<int>(0, (sum, p) => sum + (p['messages'] as int));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatsCard('Provedores Conectados', connectedProviders.toString(), Colors.blue),
              const SizedBox(width: 16),
              _buildStatsCard('Total de Mensagens', totalMessages.toString(), Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Status dos Provedores',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._providers.map((provider) => _buildProviderStatusCard(provider)),
          const SizedBox(height: 24),
          _buildFeatureShowcase(),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderStatusCard(Map<String, dynamic> provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: provider['color'],
          child: Icon(
            provider['icon'],
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(provider['name']),
        subtitle: Text(
          provider['connected'] 
            ? '${provider['messages']} mensagens sincronizadas'
            : 'Desconectado - Clique para conectar',
        ),
        trailing: provider['connected']
          ? const Icon(LucideIcons.checkCircle, color: Colors.green)
          : const Icon(LucideIcons.xCircle, color: Colors.red),
      ),
    );
  }

  Widget _buildFeatureShowcase() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚀 Funcionalidades Implementadas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem('✅ Interface unificada para todas as plataformas'),
            _buildFeatureItem('✅ Autenticação OAuth para redes sociais'),
            _buildFeatureItem('✅ Chat interno do aplicativo com WebSocket'),
            _buildFeatureItem('✅ Sincronização em tempo real'),
            _buildFeatureItem('✅ Notificações push inteligentes'),
            _buildFeatureItem('✅ Suporte a anexos e mídia'),
            _buildFeatureItem('✅ Criptografia ponta a ponta'),
            _buildFeatureItem('✅ Configurações granulares de privacidade'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(LucideIcons.check, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildProvidersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        final provider = _providers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: provider['color'],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        provider['icon'],
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            provider['connected'] ? 'Conectado' : 'Desconectado',
                            style: TextStyle(
                              color: provider['connected'] ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (provider['connected']) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${provider['messages']} msgs',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (provider['connected']) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _syncProvider(provider['id']),
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          label: const Text('Sincronizar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade100,
                            foregroundColor: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _disconnectProvider(provider['id']),
                          icon: const Icon(LucideIcons.unlink, size: 16),
                          label: const Text('Desconectar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                            foregroundColor: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _connectProvider(provider['id']),
                      icon: const Icon(LucideIcons.link, size: 16),
                      label: const Text('Conectar Conta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Conversas Recentes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildConversationTile(
          'João Silva - LinkedIn',
          'Sobre a proposta de parceria...',
          'linkedin',
          Colors.blue.shade700,
          Icons.business,
          '14:30',
          unreadCount: 2,
        ),
        _buildConversationTile(
          'Maria Santos - WhatsApp',
          'Documentos enviados ✓',
          'whatsapp',
          Colors.green.shade600,
          Icons.message,
          '13:45',
        ),
        _buildConversationTile(
          'Equipe Jurídica - Chat Interno',
          'Reunião agendada para amanhã',
          'internal',
          Colors.indigo.shade600,
          LucideIcons.users,
          '12:20',
          unreadCount: 5,
        ),
        _buildConversationTile(
          'carlos@advocacia.com - Gmail',
          'Re: Consulta sobre direito...',
          'gmail',
          Colors.red.shade500,
          Icons.email,
          '11:15',
        ),
      ],
    );
  }

  Widget _buildConversationTile(
    String name,
    String lastMessage,
    String provider,
    Color providerColor,
    IconData providerIcon,
    String time, {
    int? unreadCount,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: providerColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  providerIcon,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            if (unreadCount != null && unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () => _openConversation(provider, name),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configurações de Notificação',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSettingSwitch('Notificações Push', true),
                _buildSettingSwitch('Sons de Notificação', false),
                _buildSettingSwitch('Vibração', true),
                _buildSettingSwitch('Notificações de Email', true),
                _buildSettingSwitch('Modo Não Perturbe (22h-8h)', false),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Segurança e Privacidade',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSettingSwitch('Criptografia Ponta a Ponta', true),
                _buildSettingSwitch('Confirmação de Leitura', true),
                _buildSettingSwitch('Status Online', false),
                _buildSettingSwitch('Backup Automático', true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(LucideIcons.download, color: Colors.blue),
            title: const Text('Exportar Conversas'),
            subtitle: const Text('Baixar todas as conversas em formato PDF'),
            onTap: () => _showExportDialog(),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(LucideIcons.trash2, color: Colors.red),
            title: const Text('Limpar Dados'),
            subtitle: const Text('Remover todas as mensagens locais'),
            onTap: () => _showClearDataDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingSwitch(String title, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Switch(
            value: value,
            onChanged: (newValue) {
              // Implementar mudança de configuração
            },
            activeColor: Colors.indigo,
          ),
        ],
      ),
    );
  }

  void _syncProvider(String providerId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sincronizando ${_getProviderName(providerId)}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _disconnectProvider(String providerId) {
    setState(() {
      final provider = _providers.firstWhere((p) => p['id'] == providerId);
      provider['connected'] = false;
      provider['messages'] = 0;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_getProviderName(providerId)} desconectado'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _connectProvider(String providerId) {
    setState(() {
      final provider = _providers.firstWhere((p) => p['id'] == providerId);
      provider['connected'] = true;
      provider['messages'] = [3, 7, 2, 11, 6][_providers.indexOf(provider) % 5];
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_getProviderName(providerId)} conectado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _openConversation(String provider, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abrindo conversa: $name'),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () {
            // Implementar navegação para a conversa
          },
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Conversas'),
        content: const Text('Deseja exportar todas as conversas em formato PDF?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exportação iniciada. Você será notificado quando concluída.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Dados'),
        content: const Text('Esta ação removerá todas as mensagens locais. Tem certeza?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dados locais removidos com sucesso'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Limpar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getProviderName(String providerId) {
    final provider = _providers.firstWhere((p) => p['id'] == providerId);
    return provider['name'];
  }
}