part of 'video_call_bloc.dart';

abstract class VideoCallEvent extends Equatable {
  const VideoCallEvent();

  @override
  List<Object?> get props => [];
}

class CreateVideoCallRoomEvent extends VideoCallEvent {
  final String roomName;
  final String clientId;
  final String lawyerId;
  final String caseId;
  final bool enableRecording;
  final int maxParticipants;

  const CreateVideoCallRoomEvent({
    required this.roomName,
    required this.clientId,
    required this.lawyerId,
    required this.caseId,
    this.enableRecording = false,
    this.maxParticipants = 2,
  });

  @override
  List<Object?> get props => [
        roomName,
        clientId,
        lawyerId,
        caseId,
        enableRecording,
        maxParticipants,
      ];
}

class JoinVideoCallRoomEvent extends VideoCallEvent {
  final String roomName;
  final String roomUrl;
  final String userId;

  const JoinVideoCallRoomEvent({
    required this.roomName,
    required this.roomUrl,
    required this.userId,
  });

  @override
  List<Object?> get props => [roomName, roomUrl, userId];
}

class EndVideoCallEvent extends VideoCallEvent {
  const EndVideoCallEvent();
}

class ToggleCameraEvent extends VideoCallEvent {
  const ToggleCameraEvent();
}

class ToggleMicrophoneEvent extends VideoCallEvent {
  const ToggleMicrophoneEvent();
}