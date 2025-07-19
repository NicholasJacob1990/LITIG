import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/video_call_room.dart';
import '../../domain/repositories/video_call_repository.dart';
import '../datasources/video_call_remote_data_source.dart';

class VideoCallRepositoryImpl implements VideoCallRepository {
  final VideoCallRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  VideoCallRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, VideoCallRoom>> createRoom({
    required String roomName,
    required String clientId,
    required String lawyerId,
    required String caseId,
    bool enableRecording = false,
    int maxParticipants = 2,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.createRoom(
          roomName: roomName,
          clientId: clientId,
          lawyerId: lawyerId,
          caseId: caseId,
          enableRecording: enableRecording,
          maxParticipants: maxParticipants,
        );
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'Sem conexão com a internet'));
    }
  }

  @override
  Future<Either<Failure, String>> joinRoom({
    required String roomName,
    required String userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.joinRoom(
          roomName: roomName,
          userId: userId,
        );
        return Right(result['token'] as String);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'Sem conexão com a internet'));
    }
  }

  @override
  Future<Either<Failure, void>> endRoom(String roomName) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.endRoom(roomName);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'Sem conexão com a internet'));
    }
  }

  @override
  Future<Either<Failure, VideoCallRoom>> getRoomStatus(String roomName) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getRoomStatus(roomName);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'Sem conexão com a internet'));
    }
  }

  @override
  Future<Either<Failure, List<VideoCallRoom>>> getUserRooms(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getUserRooms(userId);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'Sem conexão com a internet'));
    }
  }
}