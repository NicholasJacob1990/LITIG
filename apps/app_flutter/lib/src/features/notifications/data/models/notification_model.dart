import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.type,
    required super.data,
    required super.createdAt,
    required super.isRead,
    super.offerId,
    super.caseId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: _parseNotificationType(json['type'] as String),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      offerId: json['offer_id'] as String?,
      caseId: json['case_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'offer_id': offerId,
      'case_id': caseId,
    };
  }

  NotificationModel copyWith({
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
    return NotificationModel(
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

  static NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'new_offer':
        return NotificationType.newOffer;
      case 'offer_accepted':
        return NotificationType.offerAccepted;
      case 'offer_declined':
        return NotificationType.offerDeclined;
      case 'offer_expired':
        return NotificationType.offerExpired;
      case 'case_update':
        return NotificationType.caseUpdate;
      case 'partnership_request':
        return NotificationType.partnershipRequest;
      case 'payment_received':
        return NotificationType.paymentReceived;
      case 'deadline_reminder':
        return NotificationType.deadlineReminder;
      default:
        return NotificationType.general;
    }
  }
} 
