import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/usecases/get_chat_rooms.dart';
import '../../domain/usecases/get_chat_messages.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../../../core/usecases/usecase.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatRooms extends ChatEvent {}

class LoadChatMessages extends ChatEvent {
  final String roomId;
  final int limit;
  final int offset;

  const LoadChatMessages({
    required this.roomId,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [roomId, limit, offset];
}

class SendChatMessage extends ChatEvent {
  final String roomId;
  final String content;
  final String messageType;
  final String? attachmentUrl;

  const SendChatMessage({
    required this.roomId,
    required this.content,
    this.messageType = 'text',
    this.attachmentUrl,
  });

  @override
  List<Object?> get props => [roomId, content, messageType, attachmentUrl];
}

class ConnectToRoom extends ChatEvent {
  final String roomId;

  const ConnectToRoom(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class DisconnectFromRoom extends ChatEvent {
  final String roomId;

  const DisconnectFromRoom(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class NewMessageReceived extends ChatEvent {
  final ChatMessage message;

  const NewMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class MarkMessageAsRead extends ChatEvent {
  final String roomId;
  final String messageId;

  const MarkMessageAsRead({
    required this.roomId,
    required this.messageId,
  });

  @override
  List<Object?> get props => [roomId, messageId];
}

// States
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatRoomsLoaded extends ChatState {
  final List<ChatRoom> rooms;

  const ChatRoomsLoaded(this.rooms);

  @override
  List<Object?> get props => [rooms];
}

class ChatMessagesLoaded extends ChatState {
  final String roomId;
  final List<ChatMessage> messages;
  final bool hasMore;

  const ChatMessagesLoaded({
    required this.roomId,
    required this.messages,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [roomId, messages, hasMore];
}

class ChatConnected extends ChatState {
  final String roomId;

  const ChatConnected(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class ChatDisconnected extends ChatState {
  final String roomId;

  const ChatDisconnected(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class MessageSent extends ChatState {
  final ChatMessage message;

  const MessageSent(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetChatRooms getChatRooms;
  final GetChatMessages getChatMessages;
  final SendMessage sendMessage;
  final ChatRepository chatRepository;

  StreamSubscription<ChatMessage>? _messageSubscription;
  List<ChatMessage> _currentMessages = [];
  String? _currentRoomId;

  ChatBloc({
    required this.getChatRooms,
    required this.getChatMessages,
    required this.sendMessage,
    required this.chatRepository,
  }) : super(ChatInitial()) {
    on<LoadChatRooms>(_onLoadChatRooms);
    on<LoadChatMessages>(_onLoadChatMessages);
    on<SendChatMessage>(_onSendChatMessage);
    on<ConnectToRoom>(_onConnectToRoom);
    on<DisconnectFromRoom>(_onDisconnectFromRoom);
    on<NewMessageReceived>(_onNewMessageReceived);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
  }

  Future<void> _onLoadChatRooms(
    LoadChatRooms event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());

    final result = await getChatRooms(NoParams());
    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (rooms) => emit(ChatRoomsLoaded(rooms)),
    );
  }

  Future<void> _onLoadChatMessages(
    LoadChatMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (event.offset == 0) {
      emit(ChatLoading());
      _currentMessages = [];
    }

    final result = await getChatMessages(GetChatMessagesParams(
      roomId: event.roomId,
      limit: event.limit,
      offset: event.offset,
    ));

    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (messages) {
        if (event.offset == 0) {
          _currentMessages = messages;
        } else {
          _currentMessages.addAll(messages);
        }

        _currentRoomId = event.roomId;
        emit(ChatMessagesLoaded(
          roomId: event.roomId,
          messages: List.from(_currentMessages),
          hasMore: messages.length == event.limit,
        ));
      },
    );
  }

  Future<void> _onSendChatMessage(
    SendChatMessage event,
    Emitter<ChatState> emit,
  ) async {
    final result = await sendMessage(SendMessageParams(
      roomId: event.roomId,
      content: event.content,
      messageType: event.messageType,
      attachmentUrl: event.attachmentUrl,
    ));

    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (message) {
        _currentMessages.insert(0, message);
        emit(ChatMessagesLoaded(
          roomId: event.roomId,
          messages: List.from(_currentMessages),
        ));
        emit(MessageSent(message));
      },
    );
  }

  Future<void> _onConnectToRoom(
    ConnectToRoom event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await chatRepository.connectToRoom(event.roomId);
      
      _messageSubscription?.cancel();
      _messageSubscription = chatRepository.getMessageStream(event.roomId).listen(
        (message) => add(NewMessageReceived(message)),
      );

      emit(ChatConnected(event.roomId));
    } catch (e) {
      emit(ChatError('Failed to connect to room: $e'));
    }
  }

  Future<void> _onDisconnectFromRoom(
    DisconnectFromRoom event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await chatRepository.disconnectFromRoom(event.roomId);
      await _messageSubscription?.cancel();
      _messageSubscription = null;
      
      emit(ChatDisconnected(event.roomId));
    } catch (e) {
      emit(ChatError('Failed to disconnect from room: $e'));
    }
  }

  void _onNewMessageReceived(
    NewMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    if (_currentRoomId == event.message.roomId) {
      _currentMessages.insert(0, event.message);
      emit(ChatMessagesLoaded(
        roomId: event.message.roomId,
        messages: List.from(_currentMessages),
      ));
    }
  }

  Future<void> _onMarkMessageAsRead(
    MarkMessageAsRead event,
    Emitter<ChatState> emit,
  ) async {
    final result = await chatRepository.markMessageAsRead(
      roomId: event.roomId,
      messageId: event.messageId,
    );

    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (_) {
        // Update local message as read
        final messageIndex = _currentMessages.indexWhere(
          (message) => message.id == event.messageId,
        );
        if (messageIndex != -1) {
          _currentMessages[messageIndex] = _currentMessages[messageIndex]
              .copyWith(isRead: true);
          emit(ChatMessagesLoaded(
            roomId: event.roomId,
            messages: List.from(_currentMessages),
          ));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}