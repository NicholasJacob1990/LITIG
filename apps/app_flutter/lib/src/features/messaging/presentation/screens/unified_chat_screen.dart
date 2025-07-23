import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../bloc/unified_chat_bloc.dart';
// import '../bloc/unified_chat_state.dart';
// import '../bloc/unified_chat_event.dart';
// import '../../domain/entities/unified_message.dart';

// Mocks para demonstração, já que o BLoC ainda não foi criado
class UnifiedMessage {
  final String senderName;
  final String content;
  final DateTime sentAt;
  final bool isOutgoing;

  UnifiedMessage({required this.senderName, required this.content, required this.sentAt, required this.isOutgoing});
}

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
  
  // Dados de exemplo
  final List<UnifiedMessage> _messages = [
    UnifiedMessage(senderName: 'Outra Pessoa', content: 'Olá! Como posso ajudar com o caso de hoje?', sentAt: DateTime.now().subtract(const Duration(minutes: 5)), isOutgoing: false),
    UnifiedMessage(senderName: 'Eu', content: 'Olá! Preciso revisar a cláusula 5 do contrato que me enviou.', sentAt: DateTime.now().subtract(const Duration(minutes: 4)), isOutgoing: true),
    UnifiedMessage(senderName: 'Outra Pessoa', content: 'Claro, um momento enquanto eu a localizo.', sentAt: DateTime.now().subtract(const Duration(minutes: 2)), isOutgoing: false),
    UnifiedMessage(senderName: 'Outra Pessoa', content: 'Aqui está. A cláusula 5 refere-se aos termos de pagamento. Alguma dúvida específica?', sentAt: DateTime.now().subtract(const Duration(minutes: 1)), isOutgoing: false),
  ];

  @override
  Widget build(BuildContext context) {
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
                  Text(widget.chatName, style: const TextStyle(fontSize: 16)),
                  Text(
                    _getProviderName(widget.provider),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.moreVertical),
            onPressed: () {}, // _showChatOptions(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(_messages),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildProviderIcon(String provider) {
    String svgAsset;
    Color iconColor;
    
    switch (provider.toLowerCase()) {
      case 'linkedin':
        svgAsset = 'assets/icons/linkedin.svg';
        iconColor = const Color(0xFF0077B5);
        break;
      case 'instagram':
        svgAsset = 'assets/icons/instagram.svg';
        iconColor = const Color(0xFFE4405F);
        break;
      case 'whatsapp':
        svgAsset = 'assets/icons/whatsapp.svg';
        iconColor = const Color(0xFF25D366);
        break;
      case 'gmail':
        svgAsset = 'assets/icons/gmail.svg';
        iconColor = const Color(0xFFEA4335);
        break;
      case 'outlook':
        svgAsset = 'assets/icons/outlook.svg';
        iconColor = const Color(0xFF0078D4);
        break;
      default:
        svgAsset = 'assets/icons/whatsapp.svg';
        iconColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SvgPicture.asset(
        svgAsset,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }

  String _getProviderName(String provider) {
    switch (provider.toLowerCase()) {
      case 'linkedin': return 'via LinkedIn';
      case 'instagram': return 'via Instagram';
      case 'whatsapp': return 'via WhatsApp';
      case 'gmail': return 'via Gmail';
      default: return 'Mensagem';
    }
  }

  Widget _buildMessageList(List<UnifiedMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Começa do fim da lista
      padding: const EdgeInsets.all(8.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        // Invertendo a ordem para o modo reverse
        final message = messages[messages.length - 1 - index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(UnifiedMessage message) {
    final isOutgoing = message.isOutgoing;
    final theme = Theme.of(context);
    
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        elevation: 1,
        color: isOutgoing ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isOutgoing ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isOutgoing ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isOutgoing)
                Text(
                  message.senderName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              const SizedBox(height: 4),
              Text(message.content),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  _formatTimestamp(message.sentAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Material(
      elevation: 5,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.paperclip),
              onPressed: () {}, // _showAttachmentOptions(),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(LucideIcons.send),
              onPressed: () {}, // _sendMessage(),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTimestamp(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}