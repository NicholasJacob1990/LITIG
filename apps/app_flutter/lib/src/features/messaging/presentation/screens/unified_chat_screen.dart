import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';

/// Tela de chat individual unificado
class UnifiedChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String provider;
  
  const UnifiedChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.provider,
  });

  @override
  State<UnifiedChatScreen> createState() => _UnifiedChatScreenState();
}

class _UnifiedChatScreenState extends State<UnifiedChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isSending = false;
  List<UnifiedMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implementar carregamento via API LITIG-1
      await Future.delayed(const Duration(seconds: 1)); // Simulação
      
      // Mensagens de exemplo baseadas no provedor
      _messages = _generateMockMessages();
      
    } catch (e) {
      debugPrint('Erro ao carregar mensagens: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<UnifiedMessage> _generateMockMessages() {
    final now = DateTime.now();
    
    switch (widget.provider.toLowerCase()) {
      case 'linkedin':
        return [
          UnifiedMessage(
            id: 'msg_1',
            chatId: widget.chatId,
            providerMessageId: 'ln_msg_1',
            senderName: widget.chatName.split(' - ')[0],
            messageType: 'text',
            content: 'Olá! Vi seu perfil e fiquei interessada em seus serviços de consultoria jurídica.',
            isOutgoing: false,
            isRead: true,
            sentAt: now.subtract(const Duration(hours: 2)),
          ),
          UnifiedMessage(
            id: 'msg_2',
            chatId: widget.chatId,
            providerMessageId: 'ln_msg_2',
            senderName: 'Você',
            messageType: 'text',
            content: 'Olá! Obrigado pelo interesse. Será um prazer ajudá-la. Em que posso auxiliar?',
            isOutgoing: true,
            isRead: true,
            sentAt: now.subtract(const Duration(hours: 1, minutes: 45)),
          ),
          UnifiedMessage(
            id: 'msg_3',
            chatId: widget.chatId,
            providerMessageId: 'ln_msg_3',
            senderName: widget.chatName.split(' - ')[0],
            messageType: 'text',
            content: 'Preciso de consultoria sobre demissão sem justa causa. Tenho algumas dúvidas sobre meus direitos.',
            isOutgoing: false,
            isRead: true,
            sentAt: now.subtract(const Duration(minutes: 15)),
          ),
        ];
      
      case 'gmail':
        return [
          UnifiedMessage(
            id: 'msg_1',
            chatId: widget.chatId,
            providerMessageId: 'gmail_msg_1',
            senderName: widget.chatName,
            messageType: 'email',
            content: '**Proposta de parceria para casos empresariais**\n\nCaro colega,\n\nEspero que esteja bem. Gostaria de propor uma parceria para casos de direito empresarial...',
            isOutgoing: false,
            isRead: true,
            sentAt: now.subtract(const Duration(hours: 3)),
          ),
          UnifiedMessage(
            id: 'msg_2',
            chatId: widget.chatId,
            providerMessageId: 'gmail_msg_2',
            senderName: 'Você',
            messageType: 'email',
            content: '**Re: Proposta de parceria para casos empresariais**\n\nCaro Dr. Carlos,\n\nObrigado pela proposta. Estou interessado em discutir os detalhes...',
            isOutgoing: true,
            isRead: true,
            sentAt: now.subtract(const Duration(hours: 2)),
          ),
        ];
      
      case 'whatsapp':
        return [
          UnifiedMessage(
            id: 'msg_1',
            chatId: widget.chatId,
            providerMessageId: 'wa_msg_1',
            senderName: widget.chatName,
            messageType: 'text',
            content: 'Boa tarde, Dr.! Como está?',
            isOutgoing: false,
            isRead: true,
            sentAt: now.subtract(const Duration(hours: 5)),
          ),
          UnifiedMessage(
            id: 'msg_2',
            chatId: widget.chatId,
            providerMessageId: 'wa_msg_2',
            senderName: 'Você',
            messageType: 'text',
            content: 'Boa tarde! Tudo bem, obrigado. Como posso ajudá-la?',
            isOutgoing: true,
            isRead: true,
            sentAt: now.subtract(const Duration(hours: 4, minutes: 55)),
          ),
          UnifiedMessage(
            id: 'msg_3',
            chatId: widget.chatId,
            providerMessageId: 'wa_msg_3',
            senderName: widget.chatName,
            messageType: 'text',
            content: 'Obrigada pela orientação sobre o contrato! Vou seguir suas recomendações. 👍',
            isOutgoing: false,
            isRead: true,
            sentAt: now.subtract(const Duration(hours: 4)),
          ),
        ];
      
      default:
        return [
          UnifiedMessage(
            id: 'msg_1',
            chatId: widget.chatId,
            providerMessageId: 'default_msg_1',
            senderName: widget.chatName,
            messageType: 'text',
            content: 'Olá! Como posso ajudá-lo?',
            isOutgoing: false,
            isRead: true,
            sentAt: now.subtract(const Duration(minutes: 30)),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _buildProviderIcon(widget.provider),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatName,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _getProviderName(widget.provider),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.provider == 'whatsapp' || widget.provider == 'instagram')
            IconButton(
              icon: const Icon(LucideIcons.phone),
              onPressed: () => _startCall(),
              tooltip: 'Ligar',
            ),
          if (widget.provider == 'whatsapp' || widget.provider == 'instagram')
            IconButton(
              icon: const Icon(LucideIcons.video),
              onPressed: () => _startVideoCall(),
              tooltip: 'Videochamada',
            ),
          IconButton(
            icon: const Icon(LucideIcons.moreVertical),
            onPressed: () => _showChatOptions(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildConnectionIndicator(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    final providerConfig = _getProviderConfig(widget.provider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: providerConfig.color.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: providerConfig.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.checkCircle,
            size: 14,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Conectado via ${_getProviderName(widget.provider)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: providerConfig.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_isSending) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            const SizedBox(width: 8),
            Text(
              'Enviando...',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderIcon(String provider) {
    final config = _getProviderConfig(provider);
    
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        config.icon,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.messageCircle,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Início da conversa',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Envie uma mensagem para começar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages.reversed.toList()[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(UnifiedMessage message) {
    final isOutgoing = message.isOutgoing;
    final theme = Theme.of(context);
    final isEmail = message.messageType == 'email';
    
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isOutgoing 
                ? AppColors.primaryBlue
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOutgoing 
                  ? Colors.transparent
                  : theme.dividerColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isOutgoing && message.senderName != null) ...[
                Text(
                  message.senderName!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getProviderConfig(widget.provider).color,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (isEmail) ...[
                _buildEmailContent(message, isOutgoing),
              ] else ...[
                Text(
                  message.content ?? '',
                  style: TextStyle(
                    color: isOutgoing ? Colors.white : null,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTimestamp(message.sentAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isOutgoing ? Colors.white70 : theme.colorScheme.outline,
                      fontSize: 10,
                    ),
                  ),
                  if (isOutgoing) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? LucideIcons.checkCheck : LucideIcons.check,
                      size: 12,
                      color: message.isRead ? AppColors.success : Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailContent(UnifiedMessage message, bool isOutgoing) {
    final lines = message.content?.split('\n') ?? [];
    String? subject;
    String body = '';
    
    // Extrai assunto do e-mail
    if (lines.isNotEmpty && lines.first.startsWith('**') && lines.first.endsWith('**')) {
      subject = lines.first.replaceAll('**', '');
      body = lines.skip(1).join('\n').trim();
    } else {
      body = message.content ?? '';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subject != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isOutgoing ? Colors.white : AppColors.primaryBlue).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.mail,
                  size: 12,
                  color: isOutgoing ? AppColors.primaryBlue : Colors.white70,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subject,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isOutgoing ? AppColors.primaryBlue : Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          body,
          style: TextStyle(
            color: isOutgoing ? Colors.white : null,
            fontSize: 14,
          ),
          maxLines: 10,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.paperclip),
              onPressed: _isSending ? null : () => _showAttachmentOptions(),
              tooltip: 'Anexar arquivo',
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor),
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
                        enabled: !_isSending,
                      ),
                    ),
                    if (widget.provider == 'whatsapp') ...[
                      IconButton(
                        icon: const Icon(LucideIcons.smile),
                        onPressed: _isSending ? null : () => _showEmojiPicker(),
                        tooltip: 'Emoji',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(LucideIcons.send, color: Colors.white),
                onPressed: _isSending ? null : () => _sendMessage(),
                tooltip: 'Enviar',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;
    
    setState(() => _isSending = true);
    
    try {
      // TODO: Implementar envio via API LITIG-1
      await Future.delayed(const Duration(seconds: 1)); // Simulação
      
      final newMessage = UnifiedMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        chatId: widget.chatId,
        providerMessageId: 'sent_${DateTime.now().millisecondsSinceEpoch}',
        senderName: 'Você',
        messageType: 'text',
        content: content,
        isOutgoing: true,
        isRead: false,
        sentAt: DateTime.now(),
      );
      
      setState(() {
        _messages.add(newMessage);
        _messageController.clear();
      });
      
      // Auto-scroll para a última mensagem
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      
    } catch (e) {
      debugPrint('Erro ao enviar mensagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar mensagem: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.image, color: AppColors.primaryBlue),
              title: const Text('Imagem'),
              onTap: () {
                Navigator.pop(context);
                _attachImage();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.fileText, color: AppColors.primaryBlue),
              title: const Text('Documento'),
              onTap: () {
                Navigator.pop(context);
                _attachDocument();
              },
            ),
            if (widget.provider == 'whatsapp') ...[
              ListTile(
                leading: const Icon(LucideIcons.mapPin, color: AppColors.primaryBlue),
                title: const Text('Localização'),
                onTap: () {
                  Navigator.pop(context);
                  _shareLocation();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.archive),
              title: const Text('Arquivar conversa'),
              onTap: () {
                Navigator.pop(context);
                _archiveChat();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.volumeX),
              title: const Text('Silenciar notificações'),
              onTap: () {
                Navigator.pop(context);
                _muteChat();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.search),
              title: const Text('Buscar nesta conversa'),
              onTap: () {
                Navigator.pop(context);
                _searchInChat();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: AppColors.error),
              title: const Text('Deletar conversa', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _deleteChat();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startCall() {
    // TODO: Implementar chamada de voz
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chamada de voz em desenvolvimento')),
    );
  }

  void _startVideoCall() {
    // TODO: Implementar videochamada
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Videochamada em desenvolvimento')),
    );
  }

  void _attachImage() {
    // TODO: Implementar anexo de imagem
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anexar imagem em desenvolvimento')),
    );
  }

  void _attachDocument() {
    // TODO: Implementar anexo de documento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anexar documento em desenvolvimento')),
    );
  }

  void _shareLocation() {
    // TODO: Implementar compartilhamento de localização
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compartilhar localização em desenvolvimento')),
    );
  }

  void _showEmojiPicker() {
    // TODO: Implementar seletor de emoji
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seletor de emoji em desenvolvimento')),
    );
  }

  void _archiveChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversa arquivada'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _muteChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificações silenciadas'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _searchInChat() {
    // TODO: Implementar busca na conversa
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Busca na conversa em desenvolvimento')),
    );
  }

  void _deleteChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar conversa'),
        content: const Text('Tem certeza que deseja deletar esta conversa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversa deletada'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
  }

  ProviderConfig _getProviderConfig(String provider) {
    switch (provider.toLowerCase()) {
      case 'linkedin':
        return const ProviderConfig(
          name: 'LinkedIn',
          icon: LucideIcons.linkedin,
          color: Color(0xFF0077B5),
        );
      case 'instagram':
        return const ProviderConfig(
          name: 'Instagram',
          icon: LucideIcons.instagram,
          color: Color(0xFFE4405F),
        );
      case 'whatsapp':
        return const ProviderConfig(
          name: 'WhatsApp',
          icon: LucideIcons.messageCircle,
          color: Color(0xFF25D366),
        );
      case 'gmail':
        return const ProviderConfig(
          name: 'Gmail',
          icon: LucideIcons.mail,
          color: Color(0xFFEA4335),
        );
      case 'outlook':
        return const ProviderConfig(
          name: 'Outlook',
          icon: LucideIcons.building,
          color: Color(0xFF0078D4),
        );
      default:
        return const ProviderConfig(
          name: 'Mensagem',
          icon: LucideIcons.messageCircle,
          color: Colors.grey,
        );
    }
  }

  String _getProviderName(String provider) {
    return _getProviderConfig(provider).name;
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

// Models para mensagens unificadas
class UnifiedMessage {
  final String id;
  final String chatId;
  final String providerMessageId;
  final String? senderName;
  final String messageType;
  final String? content;
  final bool isOutgoing;
  final bool isRead;
  final DateTime? sentAt;

  const UnifiedMessage({
    required this.id,
    required this.chatId,
    required this.providerMessageId,
    this.senderName,
    required this.messageType,
    this.content,
    required this.isOutgoing,
    required this.isRead,
    this.sentAt,
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