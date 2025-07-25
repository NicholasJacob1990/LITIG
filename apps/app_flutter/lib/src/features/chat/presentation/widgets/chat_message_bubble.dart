import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/chat_message.dart';
import 'package:meu_app/src/shared/widgets/atoms/initials_avatar.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onTap;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const currentUserId = 'current_user_id'; // TODO: Get from AuthBloc
    final isFromCurrentUser = message.senderId == currentUserId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isFromCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser) ...[
            // Avatar for other party
            InitialsAvatar(
              text: message.senderName,
              radius: 16,
              avatarUrl: message.senderAvatarUrl,
            ),
            const SizedBox(width: 8),
          ],
          
          // Message bubble
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isFromCurrentUser 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isFromCurrentUser 
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                    bottomRight: isFromCurrentUser 
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender name (only for group chats or if needed)
                    if (!isFromCurrentUser) ...[
                      Text(
                        message.senderName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    
                    // Message content
                    _buildMessageContent(context, isFromCurrentUser),
                    
                    // Time and status
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isFromCurrentUser 
                                ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)
                                : Colors.grey[600],
                          ),
                        ),
                        if (isFromCurrentUser) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead 
                                ? LucideIcons.checkCheck
                                : LucideIcons.check,
                            size: 14,
                            color: message.isRead 
                                ? Colors.blue[200]
                                : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (isFromCurrentUser) ...[
            const SizedBox(width: 8),
            // Avatar for current user
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                LucideIcons.user,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isFromCurrentUser) {
    switch (message.messageType) {
      case 'text':
        return Text(
          message.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isFromCurrentUser 
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.black87,
          ),
        );
      
      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.attachmentUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.attachmentUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(
                      LucideIcons.imageOff,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isFromCurrentUser 
                      ? Theme.of(context).colorScheme.onPrimary
                      : Colors.black87,
                ),
              ),
            ],
          ],
        );
      
      case 'document':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFromCurrentUser 
                ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.1)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.file,
                color: isFromCurrentUser 
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message.content.isNotEmpty ? message.content : 'Documento',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isFromCurrentUser 
                        ? Theme.of(context).colorScheme.onPrimary
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      
      default:
        return Text(
          message.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isFromCurrentUser 
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.black87,
          ),
        );
    }
  }
}