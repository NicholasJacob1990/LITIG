import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InternalChatScreen extends StatefulWidget {
  final String recipientId;
  final String? recipientName;

  const InternalChatScreen({
    super.key,
    required this.recipientId,
    this.recipientName,
  });

  @override
  State<InternalChatScreen> createState() => _InternalChatScreenState();
}

class _InternalChatScreenState extends State<InternalChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<InternalMessage> _messages = [];
  bool _isTyping = false;
  final bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _simulateTypingIndicator();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    // Simulação de mensagens do chat interno
    _messages.addAll([
      InternalMessage(
        id: '1',
        content: 'Olá! Como está o andamento do caso ABC-123?',
        senderId: widget.recipientId,
        senderName: widget.recipientName ?? 'Colega',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isOutgoing: false,
        messageType: MessageType.text,
        status: MessageStatus.read,
      ),
      InternalMessage(
        id: '2',
        content: 'Oi! O caso está progredindo bem. Já conseguimos a documentação necessária e estamos preparando a petição inicial.',
        senderId: 'current_user',
        senderName: 'Você',
        timestamp: DateTime.now().subtract(const Duration(minutes: 50)),
        isOutgoing: true,
        messageType: MessageType.text,
        status: MessageStatus.read,
      ),
      InternalMessage(
        id: '3',
        content: 'Excelente! Você pode me enviar uma cópia da documentação?',
        senderId: widget.recipientId,
        senderName: widget.recipientName ?? 'Colega',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        isOutgoing: false,
        messageType: MessageType.text,
        status: MessageStatus.read,
      ),
      InternalMessage(
        id: '4',
        content: 'Claro! Vou anexar os documentos agora.',
        senderId: 'current_user',
        senderName: 'Você',
        timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
        isOutgoing: true,
        messageType: MessageType.text,
        status: MessageStatus.read,
      ),
    ]);
  }

  void _simulateTypingIndicator() {
    // Simular indicador de digitação ocasional
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _isTyping = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _isTyping = false);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildConnectionStatus(),
          Expanded(
            child: _buildMessageList(),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.indigo.shade600,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(
                  LucideIcons.user,
                  color: Colors.indigo.shade600,
                  size: 20,
                ),
              ),
              if (_isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipientName ?? 'Chat Interno',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _isOnline ? 'Online' : 'Visto por último há 5 min',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.phone),
          onPressed: _startVoiceCall,
          tooltip: 'Chamada de voz',
        ),
        IconButton(
          icon: const Icon(LucideIcons.video),
          onPressed: _startVideoCall,
          tooltip: 'Videochamada',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(LucideIcons.user),
                  SizedBox(width: 8),
                  Text('Ver perfil'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  Icon(LucideIcons.search),
                  SizedBox(width: 8),
                  Text('Buscar na conversa'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'notifications',
              child: Row(
                children: [
                  Icon(LucideIcons.bell),
                  SizedBox(width: 8),
                  Text('Notificações'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(LucideIcons.userX, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Bloquear usuário', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(bottom: BorderSide(color: Colors.green.shade200)),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.shield,
            size: 16,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chat interno seguro - Criptografia ponta a ponta',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            LucideIcons.wifi,
            size: 16,
            color: Colors.green.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.indigo.shade100,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              LucideIcons.messageCircle,
              size: 40,
              color: Colors.indigo.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Início da Conversa',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Envie uma mensagem para começar a conversar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(InternalMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isOutgoing 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isOutgoing) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.indigo.shade100,
              child: Icon(
                LucideIcons.user,
                size: 16,
                color: Colors.indigo.shade600,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isOutgoing 
                  ? Colors.indigo.shade600
                  : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: message.isOutgoing 
                    ? const Radius.circular(18) 
                    : const Radius.circular(4),
                  bottomRight: message.isOutgoing 
                    ? const Radius.circular(4) 
                    : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.messageType == MessageType.file) ...[
                    _buildFileMessage(message),
                  ] else ...[
                    Text(
                      message.content,
                      style: TextStyle(
                        color: message.isOutgoing ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: message.isOutgoing 
                            ? Colors.white70 
                            : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      if (message.isOutgoing) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _getStatusIcon(message.status),
                          size: 16,
                          color: _getStatusColor(message.status),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (message.isOutgoing) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.indigo.shade600,
              child: const Icon(
                LucideIcons.user,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileMessage(InternalMessage message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.fileText,
            size: 24,
            color: Colors.white70,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  '2.3 MB • PDF',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.download, color: Colors.white70),
            onPressed: () => _downloadFile(message),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.indigo.shade100,
            child: Icon(
              LucideIcons.user,
              size: 16,
              color: Colors.indigo.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.5, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(LucideIcons.plus, color: Colors.grey.shade600),
              onPressed: _showAttachmentMenu,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Digite sua mensagem...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.smile, color: Colors.grey.shade600),
                      onPressed: _showEmojiPicker,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.indigo.shade600,
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: const Icon(LucideIcons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final message = InternalMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      senderId: 'current_user',
      senderName: 'Você',
      timestamp: DateTime.now(),
      isOutgoing: true,
      messageType: MessageType.text,
      status: MessageStatus.sent,
    );

    setState(() {
      _messages.add(message);
      _messageController.clear();
    });

    _scrollToBottom();
    _simulateDeliveryStatus(message);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _simulateDeliveryStatus(InternalMessage message) {
    // Simular mudança de status da mensagem
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final index = _messages.indexOf(message);
        if (index != -1) {
          setState(() {
            _messages[index] = message.copyWith(status: MessageStatus.delivered);
          });
        }
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final index = _messages.indexOf(message);
        if (index != -1) {
          setState(() {
            _messages[index] = message.copyWith(status: MessageStatus.read);
          });
        }
      }
    });
  }

  void _startVoiceCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Iniciando chamada de voz...')),
    );
  }

  void _startVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Iniciando videochamada...')),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Anexar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              children: [
                _buildAttachmentOption(
                  'Documento',
                  LucideIcons.fileText,
                  Colors.blue,
                  _attachDocument,
                ),
                _buildAttachmentOption(
                  'Foto',
                  LucideIcons.camera,
                  Colors.green,
                  _attachPhoto,
                ),
                _buildAttachmentOption(
                  'Localização',
                  LucideIcons.mapPin,
                  Colors.red,
                  _shareLocation,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showEmojiPicker() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seletor de emoji em desenvolvimento')),
    );
  }

  void _attachDocument() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anexar documento em desenvolvimento')),
    );
  }

  void _attachPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anexar foto em desenvolvimento')),
    );
  }

  void _shareLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compartilhar localização em desenvolvimento')),
    );
  }

  void _downloadFile(InternalMessage message) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download iniciado')),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'profile':
        _showProfile();
        break;
      case 'search':
        _searchInChat();
        break;
      case 'notifications':
        _toggleNotifications();
        break;
      case 'block':
        _blockUser();
        break;
    }
  }

  void _showProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil do usuário em desenvolvimento')),
    );
  }

  void _searchInChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Busca na conversa em desenvolvimento')),
    );
  }

  void _toggleNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificações alternadas')),
    );
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear usuário'),
        content: Text('Deseja bloquear ${widget.recipientName}?'),
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
                  content: Text('Usuário bloqueado'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Bloquear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return LucideIcons.check;
      case MessageStatus.delivered:
        return LucideIcons.checkCheck;
      case MessageStatus.read:
        return LucideIcons.checkCheck;
    }
  }

  Color _getStatusColor(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Colors.white70;
      case MessageStatus.delivered:
        return Colors.white70;
      case MessageStatus.read:
        return Colors.blue.shade300;
    }
  }
}

// Models
class InternalMessage {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final bool isOutgoing;
  final MessageType messageType;
  final MessageStatus status;

  const InternalMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.isOutgoing,
    required this.messageType,
    required this.status,
  });

  InternalMessage copyWith({
    String? id,
    String? content,
    String? senderId,
    String? senderName,
    DateTime? timestamp,
    bool? isOutgoing,
    MessageType? messageType,
    MessageStatus? status,
  }) {
    return InternalMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      timestamp: timestamp ?? this.timestamp,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      messageType: messageType ?? this.messageType,
      status: status ?? this.status,
    );
  }
}

enum MessageType {
  text,
  image,
  file,
  location,
}

enum MessageStatus {
  sent,
  delivered,
  read,
}