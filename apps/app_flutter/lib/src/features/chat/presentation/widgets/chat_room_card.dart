import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/chat_room.dart';

class ChatRoomCard extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback onTap;

  const ChatRoomCard({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const currentUserId = 'current_user_id'; // TODO: Get from AuthBloc
    final otherPartyName = room.getOtherPartyName(currentUserId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        elevation: room.hasUnreadMessages ? 2 : 1,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: room.hasUnreadMessages 
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                    : Colors.grey[200]!,
                width: room.hasUnreadMessages ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: room.hasUnreadMessages 
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  child: Icon(
                    LucideIcons.user,
                    color: room.hasUnreadMessages 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and time
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherPartyName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: room.hasUnreadMessages 
                                    ? FontWeight.bold 
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (room.lastMessageAt != null)
                            Text(
                              _formatTime(room.lastMessageAt!),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Case title
                      Text(
                        room.caseTitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Status indicator
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: room.isActive 
                                  ? Colors.green[100]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              room.isActive ? 'Ativo' : 'Inativo',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: room.isActive 
                                    ? Colors.green[700]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (room.hasUnreadMessages) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                room.unreadCount.toString(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                const SizedBox(width: 12),
                Icon(
                  LucideIcons.chevronRight,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Ontem';
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('EEE', 'pt_BR').format(dateTime);
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }
}