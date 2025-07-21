import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;
  Timer? _unreadCountTimer;

  NotificationBloc({
    required NotificationRepository repository,
  }) : _repository = repository,
       super(const NotificationState()) {
    
    on<NotificationFetchRequested>(_onFetchRequested);
    on<NotificationMarkAsRead>(_onMarkAsRead);
    on<NotificationMarkAllAsRead>(_onMarkAllAsRead);
    on<NotificationDelete>(_onDelete);
    on<NotificationUnreadCountRequested>(_onUnreadCountRequested);
    on<NotificationRefreshRequested>(_onRefreshRequested);
    on<NotificationReceived>(_onNotificationReceived);
    on<NotificationFCMTokenUpdate>(_onFCMTokenUpdate);

    // Iniciar polling do contador de não lidas
    _startUnreadCountPolling();
  }

  /// Busca notificações
  Future<void> _onFetchRequested(
    NotificationFetchRequested event,
    Emitter<NotificationState> emit,
  ) async {
    if (event.page == 1) {
      emit(state.copyWith(status: NotificationStatus.loading));
    } else {
      emit(state.copyWith(status: NotificationStatus.loadingMore));
    }

    final result = await _repository.getNotifications(
      page: event.page,
      limit: event.limit,
      forceRefresh: event.forceRefresh,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: failure.message,
      )),
      (notifications) {
        final allNotifications = event.page == 1
            ? notifications
            : [...state.notifications, ...notifications];

        emit(state.copyWith(
          status: NotificationStatus.success,
          notifications: allNotifications,
          hasReachedMax: notifications.length < event.limit,
        ));
      },
    );
  }

  /// Marca notificação como lida
  Future<void> _onMarkAsRead(
    NotificationMarkAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _repository.markAsRead(event.notificationId);
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedNotifications = state.notifications.map((notification) {
          if (notification.id == event.notificationId) {
            return notification.copyWith(isRead: true);
          }
          return notification;
        }).toList();

        emit(state.copyWith(
          notifications: updatedNotifications,
          unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
        ));
      },
    );
  }

  /// Marca todas as notificações como lidas
  Future<void> _onMarkAllAsRead(
    NotificationMarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _repository.markAllAsRead();
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedNotifications = state.notifications.map((notification) {
          return notification.copyWith(isRead: true);
        }).toList();

        emit(state.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
        ));
      },
    );
  }

  /// Remove notificação
  Future<void> _onDelete(
    NotificationDelete event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _repository.deleteNotification(event.notificationId);
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedNotifications = state.notifications
            .where((notification) => notification.id != event.notificationId)
            .toList();

        emit(state.copyWith(
          notifications: updatedNotifications,
        ));
      },
    );
  }

  /// Busca contador de não lidas
  Future<void> _onUnreadCountRequested(
    NotificationUnreadCountRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _repository.getUnreadCount();
    
    result.fold(
      (failure) {
        // Em caso de erro, mantém o contador atual
      },
      (count) => emit(state.copyWith(unreadCount: count)),
    );
  }

  /// Força refresh das notificações
  Future<void> _onRefreshRequested(
    NotificationRefreshRequested event,
    Emitter<NotificationState> emit,
  ) async {
    add(const NotificationFetchRequested(page: 1, forceRefresh: true));
    add(const NotificationUnreadCountRequested());
  }

  /// Processa nova notificação recebida
  Future<void> _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) async {
    final updatedNotifications = [event.notification, ...state.notifications];
    
    emit(state.copyWith(
      notifications: updatedNotifications,
      unreadCount: state.unreadCount + 1,
    ));
  }

  /// Atualiza token FCM
  Future<void> _onFCMTokenUpdate(
    NotificationFCMTokenUpdate event,
    Emitter<NotificationState> emit,
  ) async {
    await _repository.updateFCMToken(event.token);
  }

  /// Inicia polling periódico do contador de não lidas
  void _startUnreadCountPolling() {
    _unreadCountTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => add(const NotificationUnreadCountRequested()),
    );
  }

  @override
  Future<void> close() {
    _unreadCountTimer?.cancel();
    return super.close();
  }
}