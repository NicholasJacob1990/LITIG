import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import 'package:meu_app/src/core/services/unipile_service.dart';
import 'package:intl/intl.dart';
import 'package:meu_app/src/features/messaging/presentation/widgets/calendar_integration_widget.dart';
import 'dart:async';

class UnifiedMessagingScreen extends StatefulWidget {
  const UnifiedMessagingScreen({super.key});

  @override
  State<UnifiedMessagingScreen> createState() => _UnifiedMessagingScreenState();
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime timestamp;
  final String provider;
  final bool isRead;
  final MessageType type;
  final List<String>? attachments;
  
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.timestamp,
    required this.provider,
    this.isRead = false,
    this.type = MessageType.text,
    this.attachments,
  });
}

enum MessageType { text, image, document, audio, video }

class UnifiedChat {
  final String id;
  final String name;
  final String? avatar;
  final String provider;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final bool isOnline;
  final DateTime lastActive;
  final bool isPinned;
  final bool isMuted;
  
  UnifiedChat({
    required this.id,
    required this.name,
    this.avatar,
    required this.provider,
    this.lastMessage,
    this.unreadCount = 0,
    this.isOnline = false,
    required this.lastActive,
    this.isPinned = false,
    this.isMuted = false,
  });
}

class _UnifiedMessagingScreenState extends State<UnifiedMessagingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final UnipileService _unipileService = UnipileService();
  List<UnifiedChat> _allChats = [];
  List<UnifiedChat> _filteredChats = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Para atualização em tempo real
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadChats();
    _searchController.addListener(_onSearchChanged);
    _startRealTimeUpdates();
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  void _startRealTimeUpdates() {
    // Atualizar a cada 30 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadChats();
      }
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterChats();
    });
  }

  void _filterChats() {
    if (_searchQuery.isEmpty) {
      _filteredChats = List.from(_allChats);
    } else {
      _filteredChats = _allChats
          .where((chat) =>
              chat.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (chat.lastMessage?.content.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
          .toList();
    }
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    
    try {
      // Carregar chats reais usando o serviço instanciado
      final chatsData = await _unipileService.getAllChats();
      _allChats = chatsData.map((chatData) => _mapChatFromUnipile(chatData)).toList();
    } catch (e) {
      // Em caso de erro, usar dados de exemplo
      _allChats = _getFallbackChats();
    }
    
    _filterChats();
    setState(() => _isLoading = false);
  }

  UnifiedChat _mapChatFromUnipile(Map<String, dynamic> chatData) {
    return UnifiedChat(
      id: chatData['id'] ?? '',
      name: chatData['name'] ?? 'Usuário desconhecido',
      avatar: chatData['avatar'],
      provider: chatData['provider'] ?? 'unknown',
      lastMessage: chatData['last_message'] != null 
          ? ChatMessage(
              id: chatData['last_message']['id'] ?? '',
              senderId: chatData['last_message']['sender_id'] ?? '',
              senderName: chatData['last_message']['sender_name'] ?? '',
              content: chatData['last_message']['content'] ?? '',
              timestamp: DateTime.tryParse(chatData['last_message']['timestamp'] ?? '') ?? DateTime.now(),
              provider: chatData['provider'] ?? 'unknown',
              isRead: chatData['last_message']['is_read'] ?? false,
            )
          : null,
      unreadCount: chatData['unread_count'] ?? 0,
      isOnline: chatData['is_online'] ?? false,
      lastActive: DateTime.tryParse(chatData['last_active'] ?? '') ?? DateTime.now(),
    );
  }

  List<UnifiedChat> _getFallbackChats() {
    final now = DateTime.now();
    return [
      UnifiedChat(
        id: 'chat_1',
        name: 'Dr. Carlos Silva',
        avatar: null,
        provider: 'outlook',
        lastMessage: ChatMessage(
          id: 'msg_1',
          senderId: 'user_1',
          senderName: 'Dr. Carlos Silva',
          content: 'Sobre o contrato de prestação de serviços...',
          timestamp: now.subtract(const Duration(minutes: 5)),
          provider: 'outlook',
          isRead: false,
        ),
        unreadCount: 2,
        isOnline: true,
        lastActive: now.subtract(const Duration(minutes: 2)),
        isPinned: true,
      ),
      UnifiedChat(
        id: 'chat_2',
        name: 'Ana Santos - Cliente',
        avatar: null,
        provider: 'internal',
        lastMessage: ChatMessage(
          id: 'msg_2',
          senderId: 'user_2',
          senderName: 'Ana Santos',
          content: 'Obrigada pela orientação jurídica! 👩‍⚖️',
          timestamp: now.subtract(const Duration(minutes: 15)),
          provider: 'internal',
          isRead: true,
        ),
        unreadCount: 0,
        isOnline: false,
        lastActive: now.subtract(const Duration(minutes: 15)),
      ),
      UnifiedChat(
        id: 'chat_3',
        name: 'Escritório Legal Partners',
        avatar: null,
        provider: 'teams',
        lastMessage: ChatMessage(
          id: 'msg_3',
          senderId: 'user_3',
          senderName: 'João Advocacia',
          content: 'Reunião de alinhamento às 14h',
          timestamp: now.subtract(const Duration(hours: 2)),
          provider: 'teams',
          isRead: true,
        ),
        unreadCount: 0,
        isOnline: true,
        lastActive: now.subtract(const Duration(minutes: 30)),
      ),
      UnifiedChat(
        id: 'chat_4',
        name: 'Maria Consultoria',
        avatar: null,
        provider: 'whatsapp',
        lastMessage: ChatMessage(
          id: 'msg_4',
          senderId: 'user_4',
          senderName: 'Maria',
          content: 'Documentos enviados ✓',
          timestamp: now.subtract(const Duration(hours: 4)),
          provider: 'whatsapp',
          isRead: true,
        ),
        unreadCount: 1,
        isOnline: false,
        lastActive: now.subtract(const Duration(hours: 1)),
      ),
    ];
    
    _filterChats();
    setState(() => _isLoading = false);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Mensagens',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.settings, size: 20, color: AppColors.primaryBlue),
            ),
            onPressed: () => context.push('/connect-accounts'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.userPlus, size: 20, color: Colors.green),
            ),
            onPressed: _showNewChatDialog,
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar conversas...',
                      prefixIcon: Icon(LucideIcons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: AppColors.primaryBlue,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                tabs: const [
                  Tab(text: 'Todas'),
                  Tab(text: 'E-mail'),
                  Tab(text: 'Redes Sociais'),
                  Tab(text: 'Interno'),
                  Tab(icon: Icon(LucideIcons.calendar), text: 'Calendário'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Contas conectadas
          _buildConnectedAccountsBar(),
          
          // Lista de conversas por abas
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primaryBlue),
                        SizedBox(height: 16),
                        Text('Carregando conversas...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllChatsTab(),
                      _buildEmailChatsTab(),
                      _buildSocialNetworksTab(),
                      _buildInternalChatTab(),
                      _buildCalendarTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showNewChatDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(LucideIcons.plus, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildConnectedAccountsBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(LucideIcons.link, size: 16, color: Colors.green.shade600),
              ),
              const SizedBox(width: 8),
              Text(
                'Contas Conectadas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/connect-accounts'),
                child: const Text(
                  'Gerenciar',
                  style: TextStyle(color: AppColors.primaryBlue, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildProviderChip('Outlook', 'assets/icons/outlook.svg', const Color(0xFF0078D4), true),
                _buildProviderChip('Teams', 'assets/icons/teams.svg', Colors.indigo.shade600, true),
                _buildProviderChip('WhatsApp', 'assets/icons/whatsapp.svg', const Color(0xFF25D366), true),
                _buildProviderChip('LinkedIn', 'assets/icons/linkedin.svg', const Color(0xFF0077B5), false),
                _buildProviderChip('Instagram', 'assets/icons/instagram.svg', const Color(0xFFE4405F), false),
                _buildProviderChip('Gmail', 'assets/icons/gmail.svg', const Color(0xFFEA4335), false),
                _buildProviderChip('Google Calendar', 'assets/icons/google_calendar.svg', const Color(0xFF4285F4), false),
                _buildProviderChip('Outlook Calendar', 'assets/icons/outlook_calendar.svg', const Color(0xFF0078D4), true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderChip(String name, String iconPath, Color color, bool isConnected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => isConnected ? null : _connectProvider(name.toLowerCase()),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isConnected ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isConnected ? color.withValues(alpha: 0.3) : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: iconPath.endsWith('.svg')
                        ? SvgPicture.asset(
                            iconPath,
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              isConnected ? color : Colors.grey.shade400,
                              BlendMode.srcIn,
                            ),
                          )
                        : Icon(
                            _getProviderIcon(name),
                            size: 20,
                            color: isConnected ? color : Colors.grey.shade400,
                          ),
                  ),
                  if (isConnected)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isConnected ? color : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'outlook': return LucideIcons.mail;
      case 'teams': return LucideIcons.users;
      case 'whatsapp': return LucideIcons.messageCircle;
      case 'linkedin': return LucideIcons.linkedin;
      case 'instagram': return LucideIcons.instagram;
      case 'gmail': return LucideIcons.mail;
      case 'google calendar': return LucideIcons.calendar;
      case 'outlook calendar': return LucideIcons.calendar;
      default: return LucideIcons.messageSquare;
    }
  }

  Widget _buildEmptyChatsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                LucideIcons.messageCircle,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma conversa ainda',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Conecte suas contas ou inicie uma nova conversa para começar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showNewChatDialog,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Nova Conversa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.search,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum resultado encontrado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente buscar por um nome ou mensagem diferente',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWithAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(icon, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(actionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllChatsTab() {
    if (_filteredChats.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptySearchState();
    }
    
    if (_filteredChats.isEmpty) {
      return _buildEmptyChatsState();
    }

    // Separate pinned and unpinned chats
    final pinnedChats = _filteredChats.where((chat) => chat.isPinned).toList();
    final unpinnedChats = _filteredChats.where((chat) => !chat.isPinned).toList();
    
    // Sort by last activity
    unpinnedChats.sort((a, b) => b.lastActive.compareTo(a.lastActive));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        if (pinnedChats.isNotEmpty) ...[
          _buildSectionHeader('Fixadas', LucideIcons.pin),
          ...pinnedChats.map((chat) => _buildModernChatTile(chat)),
          const SizedBox(height: 16),
        ],
        if (unpinnedChats.isNotEmpty) ...[
          _buildSectionHeader('Recentes', LucideIcons.clock),
          ...unpinnedChats.map((chat) => _buildModernChatTile(chat)),
        ],
      ],
    );
  }

  Widget _buildEmailChatsTab() {
    final emailChats = _filteredChats.where((chat) => 
        chat.provider == 'outlook' || chat.provider == 'gmail').toList();
    
    if (emailChats.isEmpty) {
      return _buildEmptyStateWithAction(
        icon: LucideIcons.mail,
        title: 'Nenhum e-mail',
        subtitle: 'Conecte sua conta de e-mail para ver as conversas',
        actionText: 'Conectar E-mail',
        onAction: () => _connectProvider('outlook'),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: emailChats.map((chat) => _buildModernChatTile(chat)).toList(),
    );
  }

  Widget _buildSocialNetworksTab() {
    final socialChats = _filteredChats.where((chat) => 
        ['linkedin', 'instagram', 'whatsapp', 'telegram', 'twitter'].contains(chat.provider)).toList();
    
    if (socialChats.isEmpty) {
      return _buildEmptyStateWithAction(
        icon: LucideIcons.share2,
        title: 'Nenhuma rede social',
        subtitle: 'Conecte suas redes sociais para centralizar as conversas',
        actionText: 'Conectar Redes',
        onAction: () => context.push('/connect-accounts'),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        _buildSectionHeader('Redes Sociais', LucideIcons.share2),
        ...socialChats.map((chat) => _buildModernChatTile(chat)),
      ],
    );
  }

  Widget _buildInternalChatTab() {
    final internalChats = _filteredChats.where((chat) => 
        chat.provider == 'internal' || chat.provider == 'teams').toList();
    
    if (internalChats.isEmpty) {
      return _buildEmptyStateWithAction(
        icon: LucideIcons.users,
        title: 'Nenhuma conversa interna',
        subtitle: 'Inicie conversas com outros advogados e clientes',
        actionText: 'Nova Conversa',
        onAction: () => _showNewInternalChatDialog(),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        _buildSectionHeader('Conversas Internas', LucideIcons.users),
        ...internalChats.map((chat) => _buildModernChatTile(chat)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernChatTile(UnifiedChat chat) {
    final providerColor = _getProviderColor(chat.provider);
    final isUnread = chat.unreadCount > 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread ? providerColor.withValues(alpha: 0.2) : Colors.grey.shade200,
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openChat(chat),
          onLongPress: () => _showChatOptions(chat),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar with online status and provider indicator
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            providerColor.withValues(alpha: 0.1),
                            providerColor.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: providerColor.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          chat.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: providerColor,
                          ),
                        ),
                      ),
                    ),
                    // Online status
                    if (chat.isOnline)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    // Provider indicator
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: providerColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(
                          _getProviderIcon(chat.provider),
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Pinned indicator
                    if (chat.isPinned)
                      Positioned(
                        left: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: const Icon(
                            LucideIcons.pin,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Chat content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.isMuted)
                            Icon(
                              LucideIcons.volumeX,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (chat.lastMessage != null)
                        Text(
                          chat.lastMessage!.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: isUnread ? Colors.grey.shade700 : Colors.grey.shade500,
                            fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Time and unread indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(chat.lastActive),
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnread ? providerColor : Colors.grey.shade500,
                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (chat.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: providerColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: providerColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'outlook': return const Color(0xFF0078D4);
      case 'gmail': return const Color(0xFFEA4335);
      case 'whatsapp': return const Color(0xFF25D366);
      case 'linkedin': return const Color(0xFF0077B5);
      case 'instagram': return const Color(0xFFE4405F);
      case 'teams': return Colors.indigo.shade600;
      case 'telegram': return Colors.blue.shade500;
      case 'twitter': return Colors.blue.shade400;
      case 'internal': return AppColors.primaryBlue;
      default: return Colors.grey.shade600;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) return 'ontem';
      if (difference.inDays < 7) return '${difference.inDays}d';
      return DateFormat('dd/MM').format(dateTime);
    }
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h';
    }
    
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    }
    
    return 'agora';
  }

  void _connectProvider(String provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getProviderColor(provider).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getProviderIcon(provider),
                size: 20,
                color: _getProviderColor(provider),
              ),
            ),
            const SizedBox(width: 12),
            Text('Conectar ${provider.toUpperCase()}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deseja conectar sua conta do $provider para centralizar suas mensagens?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.shield, size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Suas credenciais são protegidas com criptografia de ponta a ponta',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showOAuthDialog(provider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getProviderColor(provider),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
  }

  void _showOAuthDialog(String provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getProviderColor(provider).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                _getProviderIcon(provider),
                size: 32,
                color: _getProviderColor(provider),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Conectando com $provider',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aguarde enquanto estabelecemos a conexão segura...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProviderColor(provider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
    // Simular processo OAuth com diferentes durações por provedor
    final duration = provider == 'outlook' ? 3 : 2;
    Future.delayed(Duration(seconds: duration), () {
      Navigator.pop(context);
      
      // Mostrar snackbar com design melhorado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  LucideIcons.check,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Conta $provider conectada!',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Suas mensagens serão sincronizadas automaticamente',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
      
      // Recarregar chats após conectar
      _loadChats();
    });
  }

  void _openChat(UnifiedChat chat) {
    final route = chat.provider == 'internal' || chat.provider == 'teams'
        ? '/internal-chat/${chat.id}?chatName=${Uri.encodeComponent(chat.name)}'
        : '/unified-chat/${chat.provider}/${chat.id}?chatName=${Uri.encodeComponent(chat.name)}';
    
    context.push(route);
  }

  void _showChatOptions(UnifiedChat chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getProviderColor(chat.provider).withValues(alpha: 0.1),
                  child: Text(
                    chat.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: _getProviderColor(chat.provider),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        chat.provider.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getProviderColor(chat.provider),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildChatOptionTile(
              icon: chat.isPinned ? LucideIcons.pinOff : LucideIcons.pin,
              title: chat.isPinned ? 'Desafixar' : 'Fixar conversa',
              onTap: () {
                Navigator.pop(context);
                _togglePinChat(chat);
              },
            ),
            _buildChatOptionTile(
              icon: chat.isMuted ? LucideIcons.volume2 : LucideIcons.volumeX,
              title: chat.isMuted ? 'Ativar notificações' : 'Silenciar',
              onTap: () {
                Navigator.pop(context);
                _toggleMuteChat(chat);
              },
            ),
            _buildChatOptionTile(
              icon: LucideIcons.archive,
              title: 'Arquivar conversa',
              onTap: () {
                Navigator.pop(context);
                _archiveChat(chat);
              },
            ),
            _buildChatOptionTile(
              icon: LucideIcons.trash2,
              title: 'Deletar conversa',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _showDeleteChatConfirmation(chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDestructive ? Colors.red.shade600 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? Colors.red.shade600 : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewChatDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.messageCircle,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Nova Conversa',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildNewChatOption(
              icon: LucideIcons.users,
              title: 'Chat Interno',
              subtitle: 'Conversar com outros advogados da plataforma',
              color: AppColors.primaryBlue,
              onTap: () {
                Navigator.pop(context);
                _showNewInternalChatDialog();
              },
            ),
            _buildNewChatOption(
              icon: LucideIcons.mail,
              title: 'Novo E-mail',
              subtitle: 'Enviar e-mail via Outlook ou Gmail',
              color: const Color(0xFF0078D4),
              onTap: () {
                Navigator.pop(context);
                _showEmailProviderDialog();
              },
            ),
            _buildNewChatOption(
              icon: LucideIcons.messageCircle,
              title: 'WhatsApp Business',
              subtitle: 'Iniciar conversa no WhatsApp',
              color: const Color(0xFF25D366),
              onTap: () {
                Navigator.pop(context);
                _showWhatsAppMessageDialog();
              },
            ),
            _buildNewChatOption(
              icon: LucideIcons.linkedin,
              title: 'LinkedIn',
              subtitle: 'Conectar e conversar no LinkedIn',
              color: const Color(0xFF0077B5),
              onTap: () {
                Navigator.pop(context);
                _connectProvider('linkedin');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNewChatOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNewInternalChatDialog() {
    context.push('/internal-chat/new');
  }

  void _showEmailProviderDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Escolha o provedor de e-mail',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildNewChatOption(
              icon: LucideIcons.mail,
              title: 'Microsoft Outlook',
              subtitle: 'Conectar conta do Outlook/Office 365',
              color: const Color(0xFF0078D4),
              onTap: () {
                Navigator.pop(context);
                _connectProvider('outlook');
              },
            ),
            _buildNewChatOption(
              icon: LucideIcons.mail,
              title: 'Gmail',
              subtitle: 'Conectar conta do Google Gmail',
              color: const Color(0xFFEA4335),
              onTap: () {
                Navigator.pop(context);
                _connectProvider('gmail');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _togglePinChat(UnifiedChat chat) {
    setState(() {
      final index = _allChats.indexWhere((c) => c.id == chat.id);
      if (index != -1) {
        _allChats[index] = UnifiedChat(
          id: chat.id,
          name: chat.name,
          avatar: chat.avatar,
          provider: chat.provider,
          lastMessage: chat.lastMessage,
          unreadCount: chat.unreadCount,
          isOnline: chat.isOnline,
          lastActive: chat.lastActive,
          isPinned: !chat.isPinned,
          isMuted: chat.isMuted,
        );
        _filterChats();
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(chat.isPinned ? 'Conversa desafixada' : 'Conversa fixada'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleMuteChat(UnifiedChat chat) {
    setState(() {
      final index = _allChats.indexWhere((c) => c.id == chat.id);
      if (index != -1) {
        _allChats[index] = UnifiedChat(
          id: chat.id,
          name: chat.name,
          avatar: chat.avatar,
          provider: chat.provider,
          lastMessage: chat.lastMessage,
          unreadCount: chat.unreadCount,
          isOnline: chat.isOnline,
          lastActive: chat.lastActive,
          isPinned: chat.isPinned,
          isMuted: !chat.isMuted,
        );
        _filterChats();
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(chat.isMuted ? 'Notificações ativadas' : 'Conversa silenciada'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _archiveChat(UnifiedChat chat) {
    setState(() {
      _allChats.removeWhere((c) => c.id == chat.id);
      _filterChats();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Conversa arquivada'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () {
            setState(() {
              _allChats.add(chat);
              _filterChats();
            });
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDeleteChatConfirmation(UnifiedChat chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Deletar conversa'),
        content: Text(
          'Tem certeza que deseja deletar a conversa com ${chat.name}? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteChat(chat);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
  }

  void _deleteChat(UnifiedChat chat) {
    setState(() {
      _allChats.removeWhere((c) => c.id == chat.id);
      _filterChats();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversa deletada'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  Widget _buildCalendarTab() {
    return const SingleChildScrollView(
      child: CalendarIntegrationWidget(),
    );
  }

  void _showWhatsAppMessageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar conversa WhatsApp'),
        content: const Text('Esta funcionalidade será implementada em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}