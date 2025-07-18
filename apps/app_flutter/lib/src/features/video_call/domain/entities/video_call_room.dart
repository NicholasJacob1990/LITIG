class VideoCallRoom {
  final String id;
  final String roomName;
  final String roomUrl;
  final String clientId;
  final String lawyerId;
  final String caseId;
  final String status;
  final DateTime createdAt;
  final DateTime? joinedAt;
  final DateTime? endedAt;
  final DateTime expiresAt;
  final String? recordingUrl;
  final int durationMinutes;
  final List<String> participants;

  const VideoCallRoom({
    required this.id,
    required this.roomName,
    required this.roomUrl,
    required this.clientId,
    required this.lawyerId,
    required this.caseId,
    required this.status,
    required this.createdAt,
    this.joinedAt,
    this.endedAt,
    required this.expiresAt,
    this.recordingUrl,
    required this.durationMinutes,
    required this.participants,
  });

  bool get isActive => status == 'active';
  bool get isEnded => status == 'ended';
  bool get isExpired => status == 'expired' || DateTime.now().isAfter(expiresAt);
  bool get canJoin => status == 'created' || status == 'active';

  VideoCallRoom copyWith({
    String? id,
    String? roomName,
    String? roomUrl,
    String? clientId,
    String? lawyerId,
    String? caseId,
    String? status,
    DateTime? createdAt,
    DateTime? joinedAt,
    DateTime? endedAt,
    DateTime? expiresAt,
    String? recordingUrl,
    int? durationMinutes,
    List<String>? participants,
  }) {
    return VideoCallRoom(
      id: id ?? this.id,
      roomName: roomName ?? this.roomName,
      roomUrl: roomUrl ?? this.roomUrl,
      clientId: clientId ?? this.clientId,
      lawyerId: lawyerId ?? this.lawyerId,
      caseId: caseId ?? this.caseId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      joinedAt: joinedAt ?? this.joinedAt,
      endedAt: endedAt ?? this.endedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      participants: participants ?? this.participants,
    );
  }

  @override
  String toString() {
    return 'VideoCallRoom(id: $id, roomName: $roomName, status: $status, participants: ${participants.length})';
  }
}