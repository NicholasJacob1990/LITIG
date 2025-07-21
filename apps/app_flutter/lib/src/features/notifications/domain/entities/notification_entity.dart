import 'package:equatable/equatable.dart';

enum NotificationType {
  newOffer,
  offerAccepted,
  offerDeclined,
  offerExpired,
  caseUpdate,
  partnershipRequest,
  paymentReceived,
  deadlineReminder,
  general,
}

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;
  final String? offerId;
  final String? caseId;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.createdAt,
    required this.isRead,
    this.offerId,
    this.caseId,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        type,
        data,
        createdAt,
        isRead,
        offerId,
        caseId,
      ];

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    String? offerId,
    String? caseId,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      offerId: offerId ?? this.offerId,
      caseId: caseId ?? this.caseId,
    );
  }

  /// Verifica se a notificação é crítica (requer ação imediata)
  bool get isCritical {
    return type == NotificationType.newOffer ||
           type == NotificationType.deadlineReminder ||
           type == NotificationType.offerExpired;
  }

  /// Verifica se a notificação é relacionada a ofertas
  bool get isOfferRelated {
    return type == NotificationType.newOffer ||
           type == NotificationType.offerAccepted ||
           type == NotificationType.offerDeclined ||
           type == NotificationType.offerExpired;
  }

  /// Retorna a cor da notificação baseada no tipo
  String get colorHex {
    switch (type) {
      case NotificationType.newOffer:
        return '#4CAF50'; // Verde
      case NotificationType.offerAccepted:
        return '#2196F3'; // Azul
      case NotificationType.offerDeclined:
        return '#FF9800'; // Laranja
      case NotificationType.offerExpired:
        return '#F44336'; // Vermelho
      case NotificationType.deadlineReminder:
        return '#FF5722'; // Vermelho escuro
      case NotificationType.partnershipRequest:
        return '#9C27B0'; // Roxo
      case NotificationType.paymentReceived:
        return '#4CAF50'; // Verde
      case NotificationType.caseUpdate:
        return '#607D8B'; // Azul acinzentado
      default:
        return '#757575'; // Cinza
    }
  }

  /// Retorna o ícone da notificação baseado no tipo
  String get iconName {
    switch (type) {
      case NotificationType.newOffer:
        return 'work_outline';
      case NotificationType.offerAccepted:
        return 'check_circle_outline';
      case NotificationType.offerDeclined:
        return 'cancel_outlined';
      case NotificationType.offerExpired:
        return 'access_time';
      case NotificationType.deadlineReminder:
        return 'schedule';
      case NotificationType.partnershipRequest:
        return 'handshake';
      case NotificationType.paymentReceived:
        return 'payment';
      case NotificationType.caseUpdate:
        return 'update';
      default:
        return 'notifications';
    }
  }
} 