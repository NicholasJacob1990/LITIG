part of 'video_call_bloc.dart';

abstract class VideoCallState extends Equatable {
  const VideoCallState();

  @override
  List<Object?> get props => [];
}

class VideoCallInitial extends VideoCallState {}

class VideoCallLoading extends VideoCallState {}

class VideoCallRoomCreated extends VideoCallState {
  final VideoCallRoom room;

  const VideoCallRoomCreated(this.room);

  @override
  List<Object?> get props => [room];
}

class VideoCallJoined extends VideoCallState {
  final String roomName;
  final String roomUrl;
  final String token;

  const VideoCallJoined({
    required this.roomName,
    required this.roomUrl,
    required this.token,
  });

  @override
  List<Object?> get props => [roomName, roomUrl, token];
}

class VideoCallEnded extends VideoCallState {}

class VideoCallControlsUpdated extends VideoCallState {
  final bool isCameraEnabled;
  final bool isMicrophoneEnabled;

  const VideoCallControlsUpdated({
    required this.isCameraEnabled,
    required this.isMicrophoneEnabled,
  });

  @override
  List<Object?> get props => [isCameraEnabled, isMicrophoneEnabled];
}

class VideoCallError extends VideoCallState {
  final String message;

  const VideoCallError(this.message);

  @override
  List<Object?> get props => [message];
}