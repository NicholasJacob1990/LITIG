import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/video_call_room.dart';
import '../repositories/video_call_repository.dart';

class CreateVideoCallRoom implements UseCase<VideoCallRoom, CreateVideoCallRoomParams> {
  final VideoCallRepository repository;

  CreateVideoCallRoom(this.repository);

  @override
  Future<Either<Failure, VideoCallRoom>> call(CreateVideoCallRoomParams params) async {
    return await repository.createRoom(
      roomName: params.roomName,
      clientId: params.clientId,
      lawyerId: params.lawyerId,
      caseId: params.caseId,
      enableRecording: params.enableRecording,
      maxParticipants: params.maxParticipants,
    );
  }
}

class CreateVideoCallRoomParams {
  final String roomName;
  final String clientId;
  final String lawyerId;
  final String caseId;
  final bool enableRecording;
  final int maxParticipants;

  CreateVideoCallRoomParams({
    required this.roomName,
    required this.clientId,
    required this.lawyerId,
    required this.caseId,
    this.enableRecording = false,
    this.maxParticipants = 2,
  });
}