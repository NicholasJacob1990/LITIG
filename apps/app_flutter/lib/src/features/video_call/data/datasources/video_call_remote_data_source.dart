import 'package:dio/dio.dart';
import '../models/video_call_room_model.dart';

abstract class VideoCallRemoteDataSource {
  Future<VideoCallRoomModel> createRoom({
    required String roomName,
    required String clientId,
    required String lawyerId,
    required String caseId,
    bool enableRecording = false,
    int maxParticipants = 2,
  });

  Future<Map<String, dynamic>> joinRoom({
    required String roomName,
    required String userId,
  });

  Future<void> endRoom(String roomName);

  Future<VideoCallRoomModel> getRoomStatus(String roomName);

  Future<List<VideoCallRoomModel>> getUserRooms(String userId);
}

class VideoCallRemoteDataSourceImpl implements VideoCallRemoteDataSource {
  final Dio dio;

  VideoCallRemoteDataSourceImpl({required this.dio});

  @override
  Future<VideoCallRoomModel> createRoom({
    required String roomName,
    required String clientId,
    required String lawyerId,
    required String caseId,
    bool enableRecording = false,
    int maxParticipants = 2,
  }) async {
    try {
      final response = await dio.post(
        '/api/video-calls/rooms',
        data: {
          'room_name': roomName,
          'client_id': clientId,
          'lawyer_id': lawyerId,
          'case_id': caseId,
          'enable_recording': enableRecording,
          'max_participants': maxParticipants,
        },
      );

      return VideoCallRoomModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao criar sala de videochamada: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> joinRoom({
    required String roomName,
    required String userId,
  }) async {
    try {
      final response = await dio.post(
        '/api/video-calls/rooms/$roomName/join',
        data: {
          'room_url': roomName,
          'user_id': userId,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Erro ao entrar na sala: $e');
    }
  }

  @override
  Future<void> endRoom(String roomName) async {
    try {
      await dio.post('/api/video-calls/rooms/$roomName/end');
    } catch (e) {
      throw Exception('Erro ao encerrar sala: $e');
    }
  }

  @override
  Future<VideoCallRoomModel> getRoomStatus(String roomName) async {
    try {
      final response = await dio.get('/api/video-calls/rooms/$roomName/status');
      return VideoCallRoomModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao obter status da sala: $e');
    }
  }

  @override
  Future<List<VideoCallRoomModel>> getUserRooms(String userId) async {
    try {
      final response = await dio.get('/api/video-calls/user/$userId/rooms');
      
      final List<dynamic> roomsData = response.data;
      return roomsData.map((data) => VideoCallRoomModel.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Erro ao carregar salas do usuário: $e');
    }
  }
}