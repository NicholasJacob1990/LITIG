import '../../domain/entities/video_call_room.dart';

class VideoCallRoomModel extends VideoCallRoom {
  const VideoCallRoomModel({
    required super.id,
    required super.roomName,
    required super.roomUrl,
    required super.clientId,
    required super.lawyerId,
    required super.caseId,
    required super.status,
    required super.createdAt,
    super.joinedAt,
    super.endedAt,
    required super.expiresAt,
    super.recordingUrl,
    required super.durationMinutes,
    required super.participants,
  });

  factory VideoCallRoomModel.fromJson(Map<String, dynamic> json) {
    return VideoCallRoomModel(
      id: json['id'] as String,
      roomName: json['room_name'] as String,
      roomUrl: json['room_url'] as String,
      clientId: json['client_id'] as String,
      lawyerId: json['lawyer_id'] as String,
      caseId: json['case_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      joinedAt: json['joined_at'] != null 
          ? DateTime.parse(json['joined_at'] as String) 
          : null,
      endedAt: json['ended_at'] != null 
          ? DateTime.parse(json['ended_at'] as String) 
          : null,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      recordingUrl: json['recording_url'] as String?,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      participants: List<String>.from(json['participants'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_name': roomName,
      'room_url': roomUrl,
      'client_id': clientId,
      'lawyer_id': lawyerId,
      'case_id': caseId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'joined_at': joinedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'recording_url': recordingUrl,
      'duration_minutes': durationMinutes,
      'participants': participants,
    };
  }

  factory VideoCallRoomModel.fromEntity(VideoCallRoom entity) {
    return VideoCallRoomModel(
      id: entity.id,
      roomName: entity.roomName,
      roomUrl: entity.roomUrl,
      clientId: entity.clientId,
      lawyerId: entity.lawyerId,
      caseId: entity.caseId,
      status: entity.status,
      createdAt: entity.createdAt,
      joinedAt: entity.joinedAt,
      endedAt: entity.endedAt,
      expiresAt: entity.expiresAt,
      recordingUrl: entity.recordingUrl,
      durationMinutes: entity.durationMinutes,
      participants: entity.participants,
    );
  }
}