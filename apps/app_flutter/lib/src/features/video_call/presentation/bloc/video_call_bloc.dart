import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/video_call_room.dart';
import '../../domain/usecases/create_video_call_room.dart';
import '../../domain/usecases/join_video_call_room.dart';
import '../../../../core/services/video_call_service.dart';

part 'video_call_event.dart';
part 'video_call_state.dart';

class VideoCallBloc extends Bloc<VideoCallEvent, VideoCallState> {
  final CreateVideoCallRoom createVideoCallRoom;
  final JoinVideoCallRoom joinVideoCallRoom;
  final VideoCallService videoCallService;

  VideoCallBloc({
    required this.createVideoCallRoom,
    required this.joinVideoCallRoom,
    required this.videoCallService,
  }) : super(VideoCallInitial()) {
    on<CreateVideoCallRoomEvent>(_onCreateVideoCallRoom);
    on<JoinVideoCallRoomEvent>(_onJoinVideoCallRoom);
    on<EndVideoCallEvent>(_onEndVideoCall);
    on<ToggleCameraEvent>(_onToggleCamera);
    on<ToggleMicrophoneEvent>(_onToggleMicrophone);
  }

  Future<void> _onCreateVideoCallRoom(
    CreateVideoCallRoomEvent event,
    Emitter<VideoCallState> emit,
  ) async {
    emit(VideoCallLoading());

    try {
      // Inicializar serviço de videochamada
      await videoCallService.initialize();

      // Criar sala na API
      final result = await createVideoCallRoom(
        CreateVideoCallRoomParams(
          roomName: event.roomName,
          clientId: event.clientId,
          lawyerId: event.lawyerId,
          caseId: event.caseId,
          enableRecording: event.enableRecording,
          maxParticipants: event.maxParticipants,
        ),
      );

      result.fold(
        (failure) => emit(VideoCallError(failure.toString())),
        (room) => emit(VideoCallRoomCreated(room)),
      );
    } catch (e) {
      emit(VideoCallError('Erro ao criar sala: ${e.toString()}'));
    }
  }

  Future<void> _onJoinVideoCallRoom(
    JoinVideoCallRoomEvent event,
    Emitter<VideoCallState> emit,
  ) async {
    emit(VideoCallLoading());

    try {
      // Entrar na sala via API
      final result = await joinVideoCallRoom(
        JoinVideoCallRoomParams(
          roomName: event.roomName,
          userId: event.userId,
        ),
      );

      result.fold(
        (failure) => emit(VideoCallError(failure.toString())),
        (token) async {
          // Entrar na sala via Daily.co
          await videoCallService.joinRoom(event.roomUrl);
          emit(VideoCallJoined(
            roomName: event.roomName,
            roomUrl: event.roomUrl,
            token: token,
          ));
        },
      );
    } catch (e) {
      emit(VideoCallError('Erro ao entrar na sala: ${e.toString()}'));
    }
  }

  Future<void> _onEndVideoCall(
    EndVideoCallEvent event,
    Emitter<VideoCallState> emit,
  ) async {
    try {
      await videoCallService.leaveRoom();
      emit(VideoCallEnded());
    } catch (e) {
      emit(VideoCallError('Erro ao encerrar chamada: ${e.toString()}'));
    }
  }

  Future<void> _onToggleCamera(
    ToggleCameraEvent event,
    Emitter<VideoCallState> emit,
  ) async {
    try {
      await videoCallService.toggleCamera();
      emit(VideoCallControlsUpdated(
        isCameraEnabled: videoCallService.isCameraEnabled,
        isMicrophoneEnabled: videoCallService.isMicrophoneEnabled,
      ));
    } catch (e) {
      emit(VideoCallError('Erro ao alternar câmera: ${e.toString()}'));
    }
  }

  Future<void> _onToggleMicrophone(
    ToggleMicrophoneEvent event,
    Emitter<VideoCallState> emit,
  ) async {
    try {
      await videoCallService.toggleMicrophone();
      emit(VideoCallControlsUpdated(
        isCameraEnabled: videoCallService.isCameraEnabled,
        isMicrophoneEnabled: videoCallService.isMicrophoneEnabled,
      ));
    } catch (e) {
      emit(VideoCallError('Erro ao alternar microfone: ${e.toString()}'));
    }
  }
}