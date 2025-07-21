import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;
  final bool showActions;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _parseColor(notification.colorHex);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: notification.isRead ? 1 : 3,
      color: notification.isRead 
          ? theme.cardColor 
          : theme.cardColor.withValues(alpha: 0.95),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            onMarkAsRead?.call();
          }
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com ícone, título e timestamp
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconData(notification.iconName),
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: notification.isRead 
                                      ? FontWeight.normal 
                                      : FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimestamp(notification.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Body da notificação
              Text(
                notification.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: notification.isRead 
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                      : theme.colorScheme.onSurface,
                ),
              ),
              
              // Badges de tipo e criticidade
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTypeBadge(context, notification.type, color),
                  if (notification.isCritical) ...[
                    const SizedBox(width: 8),
                    _buildCriticalBadge(context),
                  ],
                  const Spacer(),
                  if (showActions) _buildActions(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context, NotificationType type, Color color) {
    final theme = Theme.of(context);
    String label;
    
    switch (type) {
      case NotificationType.newOffer:
        label = 'Nova Oferta';
        break;
      case NotificationType.offerAccepted:
        label = 'Oferta Aceita';
        break;
      case NotificationType.offerDeclined:
        label = 'Oferta Recusada';
        break;
      case NotificationType.offerExpired:
        label = 'Oferta Expirada';
        break;
      case NotificationType.deadlineReminder:
        label = 'Lembrete';
        break;
      case NotificationType.partnershipRequest:
        label = 'Parceria';
        break;
      case NotificationType.paymentReceived:
        label = 'Pagamento';
        break;
      case NotificationType.caseUpdate:
        label = 'Atualização';
        break;
      default:
        label = 'Geral';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCriticalBadge(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.priority_high,
            size: 12,
            color: Colors.red,
          ),
          const SizedBox(width: 2),
          Text(
            'Urgente',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!notification.isRead && onMarkAsRead != null)
          IconButton(
            onPressed: onMarkAsRead,
            icon: const Icon(Icons.mark_email_read_outlined),
            tooltip: 'Marcar como lida',
            iconSize: 20,
          ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Deletar',
            iconSize: 20,
          ),
      ],
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.grey;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work_outline':
        return Icons.work_outline;
      case 'check_circle_outline':
        return Icons.check_circle_outline;
      case 'cancel_outlined':
        return Icons.cancel_outlined;
      case 'access_time':
        return Icons.access_time;
      case 'schedule':
        return Icons.schedule;
      case 'handshake':
        return Icons.handshake;
      case 'payment':
        return Icons.payment;
      case 'update':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }
}
