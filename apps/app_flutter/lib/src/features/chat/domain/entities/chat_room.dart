import 'package:equatable/equatable.dart';

class ChatRoom extends Equatable {
  final String id;
  final String clientId;
  final String lawyerId;
  final String caseId;
  final String? contractId;
  final String status;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String clientName;
  final String lawyerName;
  final String caseTitle;
  final int unreadCount;

  const ChatRoom({
    required this.id,
    required this.clientId,
    required this.lawyerId,
    required this.caseId,
    this.contractId,
    required this.status,
    required this.createdAt,
    this.lastMessageAt,
    required this.clientName,
    required this.lawyerName,
    required this.caseTitle,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        clientId,
        lawyerId,
        caseId,
        contractId,
        status,
        createdAt,
        lastMessageAt,
        clientName,
        lawyerName,
        caseTitle,
        unreadCount,
      ];

  ChatRoom copyWith({
    String? id,
    String? clientId,
    String? lawyerId,
    String? caseId,
    String? contractId,
    String? status,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? clientName,
    String? lawyerName,
    String? caseTitle,
    int? unreadCount,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      lawyerId: lawyerId ?? this.lawyerId,
      caseId: caseId ?? this.caseId,
      contractId: contractId ?? this.contractId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      clientName: clientName ?? this.clientName,
      lawyerName: lawyerName ?? this.lawyerName,
      caseTitle: caseTitle ?? this.caseTitle,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  String getOtherPartyName(String currentUserId) {
    return currentUserId == clientId ? lawyerName : clientName;
  }

  String getOtherPartyId(String currentUserId) {
    return currentUserId == clientId ? lawyerId : clientId;
  }

  bool get hasUnreadMessages => unreadCount > 0;
  bool get isActive => status == 'active';
}