import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';

/// Tela principal de chats unificados LITIG-1
class UnifiedChatsScreen extends StatefulWidget {
  const UnifiedChatsScreen({super.key});

  @override
  State<UnifiedChatsScreen> createState() => _UnifiedChatsScreenState();
}

class _UnifiedChatsScreenState extends State<UnifiedChatsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<UnifiedChat> _allChats = [];
  List<ConnectedAccount> _connectedAccounts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implementar carregamento via API LITIG-1
      await Future.delayed(const Duration(seconds: 1)); // Simulação
      
      // Dados de exemplo
      _connectedAccounts = [
        ConnectedAccount(
          id: 'acc_1',
          provider: 'linkedin',
          accountName: 'João Silva',
          accountEmail: 'joao.silva@advocacia.com',
          status: 'active',
          lastSync: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        ConnectedAccount(
          id: 'acc_2',
          provider: 'gmail',
          accountName: 'João Silva',
          accountEmail: 'joao@gmail.com',
          status: 'active',
          lastSync: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
        ConnectedAccount(
          id: 'acc_3',
          provider: 'whatsapp',
          accountName: 'WhatsApp Business',
          accountEmail: null,
          status: 'active',
          lastSync: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ];
      
      _allChats = [
        UnifiedChat(
          id: 'chat_1',
          provider: 'linkedin',
          chatName: 'Maria Santos - Direito Trabalhista',
          chatType: 'direct',
          avatarUrl: null,
          lastMessage: 'Preciso de consultoria sobre demissão sem justa causa...',
          lastMessageAt: DateTime.now().subtract(const Duration(minutes: 15)),
          unreadCount: 2,
          isArchived: false,
        ),
        UnifiedChat(
          id: 'chat_2',
          provider: 'gmail',
          chatName: 'Dr. Carlos Mendes',
          chatType: 'direct',
          avatarUrl: null,
          lastMessage: 'Re: Proposta de parceria para casos empresariais',
          lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
          unreadCount: 0,
          isArchived: false,
        ),
        UnifiedChat(
          id: 'chat_3',
          provider: 'whatsapp',
          chatName: 'Ana Costa',
          chatType: 'direct',
          avatarUrl: null,
          lastMessage: 'Obrigada pela orientação! Vou seguir suas recomendações.',
          lastMessageAt: DateTime.now().subtract(const Duration(hours: 4)),
          unreadCount: 0,
          isArchived: false,
        ),
        UnifiedChat(
          id: 'chat_4',
          provider: 'instagram',
          chatName: 'Empresa XYZ',
          chatType: 'direct',
          avatarUrl: null,
          lastMessage: 'Interessados em seus serviços de consultoria jurídica',
          lastMessageAt: DateTime.now().subtract(const Duration(hours: 8)),
          unreadCount: 1,
          isArchived: false,
        ),
      ];
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensagens Unificadas'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => _showAccountsDialog(context),
            tooltip: 'Gerenciar Contas',
          ),
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: () => _showSearchDialog(context),
            tooltip: 'Buscar Conversas',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(LucideIcons.messageCircle),
              text: 'Todos',
            ),
            Tab(
              icon: Icon(LucideIcons.clock),
              text: 'Recentes',
            ),
            Tab(
              icon: Icon(LucideIcons.archive),
              text: 'Arquivados',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllChatsTab(),
          _buildRecentChatsTab(),
          _buildArchivedChatsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(context),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(LucideIcons.plus, color: Colors.white),
        tooltip: 'Nova Conversa',
      ),
    );
  }

  Widget _buildAllChatsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeChats = _allChats.where((chat) => !chat.isArchived).toList();

    if (activeChats.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.messageCircle,
        title: 'Nenhuma conversa',
        subtitle: 'Suas conversas aparecerão aqui quando você conectar suas contas',
        actionText: 'Conectar Conta',
        onAction: () => _showConnectAccountDialog(context),
      );
    }

    return Column(
      children: [
        _buildAccountsOverview(),
        Expanded(
          child: ListView.builder(
            itemCount: activeChats.length,
            itemBuilder: (context, index) {
              final chat = activeChats[index];
              return _buildChatTile(chat);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentChatsTab() {
    final recentChats = _allChats
        .where((chat) => !chat.isArchived)
        .where((chat) => 
            chat.lastMessageAt != null && 
            chat.lastMessageAt!.isAfter(DateTime.now().subtract(const Duration(days: 1)))
        )
        .toList();

    if (recentChats.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.clock,
        title: 'Nenhuma conversa recente',
        subtitle: 'Conversas das últimas 24 horas aparecerão aqui',
      );
    }

    return ListView.builder(
      itemCount: recentChats.length,
      itemBuilder: (context, index) {
        final chat = recentChats[index];
        return _buildChatTile(chat, showTimeAgo: true);
      },
    );
  }

  Widget _buildArchivedChatsTab() {
    final archivedChats = _allChats.where((chat) => chat.isArchived).toList();

    if (archivedChats.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.archive,
        title: 'Nenhuma conversa arquivada',
        subtitle: 'Conversas arquivadas aparecerão aqui',
      );
    }

    return ListView.builder(
      itemCount: archivedChats.length,
      itemBuilder: (context, index) {
        final chat = archivedChats[index];
        return _buildChatTile(chat, isArchived: true);
      },
    );
  }

  Widget _buildAccountsOverview() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.link,
                size: 16,
                color: AppColors.info,
              ),
              const SizedBox(width: 8),
              Text(
                'Contas Conectadas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showAccountsDialog(context),
                child: Text(
                  'Gerenciar',
                  style: TextStyle(color: AppColors.info),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _connectedAccounts.map((account) {
              return _buildProviderChip(account);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderChip(ConnectedAccount account) {
    final config = _getProviderConfig(account.provider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: 12,
            color: config.color,
          ),
          const SizedBox(width: 4),
          Text(
            config.name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(UnifiedChat chat, {bool showTimeAgo = false, bool isArchived = false}) {
    final providerConfig = _getProviderConfig(chat.provider);
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: providerConfig.color.withValues(alpha: 0.1),
                child: chat.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          chat.avatarUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        LucideIcons.user,
                        color: providerConfig.color,
                        size: 20,
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: providerConfig.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    providerConfig.icon,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            chat.chatName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chat.lastMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  chat.lastMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: chat.unreadCount > 0 
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (showTimeAgo && chat.lastMessageAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatTimeAgo(chat.lastMessageAt!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (chat.lastMessageAt != null && !showTimeAgo)
                Text(
                  _formatTimestamp(chat.lastMessageAt!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (chat.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        chat.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isArchived) ...[
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.archive,
                      size: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ],
                ],
              ),
            ],
          ),
          onTap: () => _openChat(context, chat),
          onLongPress: () => _showChatOptions(context, chat),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(LucideIcons.plus),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openChat(BuildContext context, UnifiedChat chat) {
    // TODO: Navegar para tela de chat específico
    Navigator.pushNamed(
      context,
      '/unified-chat',
      arguments: {
        'chatId': chat.id,
        'chatName': chat.chatName,
        'provider': chat.provider,
      },
    );
  }

  void _showChatOptions(BuildContext context, UnifiedChat chat) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                chat.isArchived ? LucideIcons.archiveRestore : LucideIcons.archive,
              ),
              title: Text(chat.isArchived ? 'Desarquivar' : 'Arquivar'),
              onTap: () {
                Navigator.pop(context);
                _toggleArchiveChat(chat);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.volumeX),
              title: const Text('Silenciar'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar silenciar chat
              },
            ),
            ListTile(
              leading: Icon(
                LucideIcons.trash2,
                color: AppColors.error,
              ),
              title: Text(
                'Deletar',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteChatDialog(context, chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contas Conectadas'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._connectedAccounts.map((account) {
                final config = _getProviderConfig(account.provider);
                return ListTile(
                  leading: Icon(config.icon, color: config.color),
                  title: Text(account.accountName ?? config.name),
                  subtitle: Text(account.accountEmail ?? 'Conectado'),
                  trailing: IconButton(
                    icon: Icon(LucideIcons.x, color: AppColors.error),
                    onPressed: () => _disconnectAccount(account),
                  ),
                );
              }),
              const Divider(),
              ListTile(
                leading: Icon(LucideIcons.plus, color: AppColors.primaryBlue),
                title: Text(
                  'Conectar Nova Conta',
                  style: TextStyle(color: AppColors.primaryBlue),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showConnectAccountDialog(context);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showConnectAccountDialog(BuildContext context) {
    // TODO: Implementar dialog de conexão de conta
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conectar Conta'),
        content: const Text('Funcionalidade em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    // TODO: Implementar busca de conversas
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar Conversas'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Digite para buscar...',
            prefixIcon: Icon(LucideIcons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    // TODO: Implementar nova conversa
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Conversa'),
        content: const Text('Funcionalidade em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteChatDialog(BuildContext context, UnifiedChat chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Conversa'),
        content: Text('Tem certeza que deseja deletar a conversa com ${chat.chatName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteChat(chat);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
  }

  void _toggleArchiveChat(UnifiedChat chat) {
    setState(() {
      chat.isArchived = !chat.isArchived;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          chat.isArchived 
              ? 'Conversa arquivada' 
              : 'Conversa desarquivada'
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _deleteChat(UnifiedChat chat) {
    setState(() {
      _allChats.remove(chat);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Conversa deletada'),
        backgroundColor: AppColors.error,
        action: SnackBarAction(
          label: 'Desfazer',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _allChats.add(chat);
            });
          },
        ),
      ),
    );
  }

  void _disconnectAccount(ConnectedAccount account) {
    // TODO: Implementar desconexão de conta
    setState(() {
      _connectedAccounts.remove(account);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Conta ${account.provider} desconectada'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  ProviderConfig _getProviderConfig(String provider) {
    switch (provider.toLowerCase()) {
      case 'linkedin':
        return ProviderConfig(
          name: 'LinkedIn',
          icon: LucideIcons.linkedin,
          color: const Color(0xFF0077B5),
        );
      case 'instagram':
        return ProviderConfig(
          name: 'Instagram',
          icon: LucideIcons.instagram,
          color: const Color(0xFFE4405F),
        );
      case 'whatsapp':
        return ProviderConfig(
          name: 'WhatsApp',
          icon: LucideIcons.messageCircle,
          color: const Color(0xFF25D366),
        );
      case 'gmail':
        return ProviderConfig(
          name: 'Gmail',
          icon: LucideIcons.mail,
          color: const Color(0xFFEA4335),
        );
      case 'outlook':
        return ProviderConfig(
          name: 'Outlook',
          icon: LucideIcons.building,
          color: const Color(0xFF0078D4),
        );
      default:
        return ProviderConfig(
          name: 'Mensagem',
          icon: LucideIcons.messageCircle,
          color: Colors.grey,
        );
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inHours > 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'agora';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return 'há ${difference.inDays} dia${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'há ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'há ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'agora';
    }
  }
}

// Models para chats unificados
class UnifiedChat {
  final String id;
  final String provider;
  final String chatName;
  final String chatType;
  final String? avatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  bool isArchived;

  UnifiedChat({
    required this.id,
    required this.provider,
    required this.chatName,
    required this.chatType,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isArchived = false,
  });
}

class ConnectedAccount {
  final String id;
  final String provider;
  final String? accountName;
  final String? accountEmail;
  final String status;
  final DateTime? lastSync;

  const ConnectedAccount({
    required this.id,
    required this.provider,
    this.accountName,
    this.accountEmail,
    required this.status,
    this.lastSync,
  });
}

class ProviderConfig {
  final String name;
  final IconData icon;
  final Color color;

  const ProviderConfig({
    required this.name,
    required this.icon,
    required this.color,
  });
}