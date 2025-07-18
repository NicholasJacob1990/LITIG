import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/video_call_room.dart';

abstract class VideoCallRepository {
  Future<Either<Failure, VideoCallRoom>> createRoom({
    required String roomName,
    required String clientId,
    required String lawyerId,
    required String caseId,
    bool enableRecording = false,
    int maxParticipants = 2,
  });

  Future<Either<Failure, String>> joinRoom({
    required String roomName,
    required String userId,
  });

  Future<Either<Failure, void>> endRoom(String roomName);

  Future<Either<Failure, VideoCallRoom>> getRoomStatus(String roomName);

  Future<Either<Failure, List<VideoCallRoom>>> getUserRooms(String userId);
}