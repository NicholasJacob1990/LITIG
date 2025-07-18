import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/video_call_repository.dart';

class JoinVideoCallRoom implements UseCase<String, JoinVideoCallRoomParams> {
  final VideoCallRepository repository;

  JoinVideoCallRoom(this.repository);

  @override
  Future<Either<Failure, String>> call(JoinVideoCallRoomParams params) async {
    return await repository.joinRoom(
      roomName: params.roomName,
      userId: params.userId,
    );
  }
}

class JoinVideoCallRoomParams {
  final String roomName;
  final String userId;

  JoinVideoCallRoomParams({
    required this.roomName,
    required this.userId,
  });
}