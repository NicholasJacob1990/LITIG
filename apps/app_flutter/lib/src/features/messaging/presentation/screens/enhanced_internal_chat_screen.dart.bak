import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import 'package:meu_app/src/shared/widgets/voice_recorder_widget.dart';
import 'package:meu_app/src/shared/widgets/voice_message_player_widget.dart';
import 'package:intl/intl.dart';

class EnhancedInternalChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  
  const EnhancedInternalChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  State<EnhancedInternalChatScreen> createState() => _EnhancedInternalChatScreenState();
}

class InternalMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final MessageStatus status;
  final String? replyToMessageId;
  final List<String> attachments;
  final MessageType type;
  
  InternalMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.timestamp,
    required this.isMe,
    this.status = MessageStatus.sent,
    this.replyToMessageId,
    this.attachments = const [],
    this.type = MessageType.text,
  });
}

enum MessageStatus { sending, sent, delivered, read, failed }
enum MessageType { text, image, document, audio, video, system }

class _EnhancedInternalChatScreenState extends State<EnhancedInternalChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  List<InternalMessage> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  String _typingUser = '';
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupTypingAnimation();
    _messageFocusNode.addListener(_onFocusChange);
  }

  void _setupTypingAnimation() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _typingAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    ));
    _typingAnimationController.repeat(reverse: true);
  }

  void _onFocusChange() {
    if (_messageFocusNode.hasFocus) {
      _scrollToBottom();
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    final now = DateTime.now();
    _messages = [
      InternalMessage(
        id: 'msg_1',
        senderId: 'user_1',
        senderName: 'Dr. Carlos Silva',
        content: 'Boa tarde! Preciso discutir o caso ABC-123 com urgência.',
        timestamp: now.subtract(const Duration(hours: 2)),
        isMe: false,
        status: MessageStatus.read,
      ),
      InternalMessage(
        id: 'msg_2',
        senderId: 'me',
        senderName: 'Você',
        content: 'Olá Dr. Carlos! Claro, estou disponível. Qual a questão específica?',
        timestamp: now.subtract(const Duration(hours: 2, minutes: -5)),
        isMe: true,
        status: MessageStatus.read,
      ),
      InternalMessage(
        id: 'msg_3',
        senderId: 'user_1',
        senderName: 'Dr. Carlos Silva',
        content: 'O cliente está preocupado com os prazos processuais. Precisamos revisar a estratégia de defesa.',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 45)),
        isMe: false,
        status: MessageStatus.delivered,
      ),
      InternalMessage(
        id: 'msg_4',
        senderId: 'me',
        senderName: 'Você',
        content: 'Perfeito. Já analisei os documentos. Podemos marcar uma reunião para hoje às 16h?',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
        isMe: true,
        status: MessageStatus.read,
      ),
      InternalMessage(
        id: 'msg_5',
        senderId: 'user_1',
        senderName: 'Dr. Carlos Silva',
        content: 'Excelente! Às 16h está confirmado. Vou preparar os pontos principais para discussão.',
        timestamp: now.subtract(const Duration(minutes: 45)),
        isMe: false,
        status: MessageStatus.sent,
      ),
    ];
    
    setState(() => _isLoading = false);
    _scrollToBottom();
    
    // Simular digitação após 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isTyping = true;
          _typingUser = 'Dr. Carlos Silva';
        });
        
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() {
              _isTyping = false;
              _typingUser = '';
            });
          }
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                  child: Text(
                    widget.chatName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
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
                    widget.chatName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _isTyping ? 'digitando...' : 'online',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isTyping ? AppColors.primaryBlue : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(LucideIcons.phone, size: 18, color: Colors.green),
            ),
            onPressed: _makeCall,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(LucideIcons.video, size: 18, color: Colors.blue),
            ),
            onPressed: _makeVideoCall,
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(LucideIcons.search, size: 16),
                    SizedBox(width: 8),
                    Text('Buscar mensagens'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(LucideIcons.volumeX, size: 16),
                    SizedBox(width: 8),
                    Text('Silenciar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Limpar conversa', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primaryBlue),
                        SizedBox(height: 16),
                        Text('Carregando mensagens...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(InternalMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: Text(
                message.senderName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
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
                color: message.isMe ? AppColors.primaryBlue : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                  bottomRight: Radius.circular(message.isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  _buildMessageContent(message),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: message.isMe 
                              ? Colors.white.withValues(alpha: 0.8) 
                              : Colors.grey.shade500,
                        ),
                      ),
                      if (message.isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _getStatusIcon(message.status),
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: const Icon(
                LucideIcons.user,
                size: 12,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
            child: Text(
              _typingUser.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypingDot(0),
                    const SizedBox(width: 4),
                    _buildTypingDot(1),
                    const SizedBox(width: 4),
                    _buildTypingDot(2),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    final delay = index * 0.2;
    final animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingAnimationController,
      curve: Interval(delay, 1.0, curve: Curves.easeInOut),
    ));

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: animation.value),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(LucideIcons.paperclip, size: 18, color: Colors.grey.shade600),
            ),
            onPressed: _showAttachmentOptions,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                decoration: const InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                minLines: 1,
                maxLines: 4,
                onChanged: (text) {
                  // Implementar indicador de digitação em tempo real
                },
                onSubmitted: (text) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _messageController,
            builder: (context, value, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: value.text.trim().isEmpty 
                    ? IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(LucideIcons.mic, size: 18, color: Colors.grey.shade600),
                        ),
                        onPressed: _startVoiceRecording,
                      )
                    : IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.send, size: 18, color: Colors.white),
                        ),
                        onPressed: _sendMessage,
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return LucideIcons.clock;
      case MessageStatus.sent:
        return LucideIcons.check;
      case MessageStatus.delivered:
        return LucideIcons.checkCheck;
      case MessageStatus.read:
        return LucideIcons.checkCheck;
      case MessageStatus.failed:
        return LucideIcons.alertCircle;
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = InternalMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      senderName: 'Você',
      content: text,
      timestamp: DateTime.now(),
      isMe: true,
      status: MessageStatus.sending,
    );

    setState(() {
      _messages.add(message);
    });

    _messageController.clear();
    _scrollToBottom();

    // Simular envio
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = InternalMessage(
              id: message.id,
              senderId: message.senderId,
              senderName: message.senderName,
              content: message.content,
              timestamp: message.timestamp,
              isMe: message.isMe,
              status: MessageStatus.delivered,
            );
          }
        });
      }
    });
  }

  void _makeCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.phone, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Ligando para ${widget.chatName}...'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _makeVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.video, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Iniciando videochamada com ${widget.chatName}...'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'search':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Busca em desenvolvimento')),
        );
        break;
      case 'mute':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversa com ${widget.chatName} silenciada')),
        );
        break;
      case 'clear':
        _showClearChatDialog();
        break;
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar conversa'),
        content: const Text('Tem certeza que deseja limpar todas as mensagens desta conversa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conversa limpa')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Limpar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
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
              'Anexar arquivo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: LucideIcons.camera,
                  label: 'Câmera',
                  color: Colors.blue,
                  onTap: () => Navigator.pop(context),
                ),
                _buildAttachmentOption(
                  icon: LucideIcons.image,
                  label: 'Galeria',
                  color: Colors.purple,
                  onTap: () => Navigator.pop(context),
                ),
                _buildAttachmentOption(
                  icon: LucideIcons.fileText,
                  label: 'Documento',
                  color: Colors.orange,
                  onTap: () => Navigator.pop(context),
                ),
                _buildAttachmentOption(
                  icon: LucideIcons.mapPin,
                  label: 'Localização',
                  color: Colors.green,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startVoiceRecording() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
        ),
        child: VoiceRecorderWidget(
          primaryColor: AppColors.primaryBlue,
          onRecordingComplete: (filePath, duration) {
            Navigator.pop(context);
            _sendVoiceMessage(filePath, duration);
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _sendVoiceMessage(String filePath, Duration duration) {
    final message = InternalMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'current_user',
      senderName: 'Você',
      content: filePath, // Store file path as content for audio messages
      timestamp: DateTime.now(),
      isMe: true,
      type: MessageType.audio,
      status: MessageStatus.sending,
    );

    setState(() {
      _messages.add(message);
    });

    _scrollToBottom();

    // Simulate message sent
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = InternalMessage(
              id: message.id,
              senderId: message.senderId,
              senderName: message.senderName,
              content: message.content,
              timestamp: message.timestamp,
              isMe: message.isMe,
              type: message.type,
              status: MessageStatus.sent,
            );
          }
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.mic, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Mensagem de voz enviada (${_formatDuration(duration)})'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildMessageContent(InternalMessage message) {
    switch (message.type) {
      case MessageType.audio:
        return VoiceMessagePlayerWidget(
          filePath: message.content,
          isSentByMe: message.isMe,
          primaryColor: message.isMe ? Colors.white : AppColors.primaryBlue,
          timestamp: message.timestamp,
          showTimestamp: false, // We show timestamp separately
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
                maxHeight: 200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.content,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.imageOff,
                            color: message.isMe ? Colors.white : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Imagem não disponível',
                            style: TextStyle(
                              color: message.isMe ? Colors.white : Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      case MessageType.document:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (message.isMe ? Colors.white : AppColors.primaryBlue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.file,
                color: message.isMe ? Colors.white : AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: message.isMe ? Colors.white : AppColors.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      case MessageType.system:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        );
      case MessageType.text:
      default:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 16,
            color: message.isMe ? Colors.white : Colors.grey.shade800,
            height: 1.4,
          ),
        );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}