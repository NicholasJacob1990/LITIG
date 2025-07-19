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
        // Atualizar estado local
        final updatedNotifications = state.notifications.map((notification) {
          if (notification.id == event.notificationId) {
            return notification is NotificationEntity
                ? NotificationEntity(
                    id: notification.id,
                    title: notification.title,
                    body: notification.body,
                    type: notification.type,
                    data: notification.data,
                    createdAt: notification.createdAt,
                    isRead: true,
                    offerId: notification.offerId,
                    caseId: notification.caseId,
                  )
                : notification;
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

  /// Marca todas como lidas
  Future<void> _onMarkAllAsRead(
    NotificationMarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    final result = await _repository.markAllAsRead();
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          status: NotificationStatus.success,
          unreadCount: 0,
        ));
        
        // Recarregar notificações
        add(const NotificationFetchRequested(forceRefresh: true));
      },
    );
  }

  /// Deleta notificação
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
        // Falha silenciosa para contador
        print('Erro ao buscar contador: ${failure.message}');
      },
      (count) => emit(state.copyWith(unreadCount: count)),
    );
  }

  /// Refresh das notificações
  Future<void> _onRefreshRequested(
    NotificationRefreshRequested event,
    Emitter<NotificationState> emit,
  ) async {
    add(const NotificationFetchRequested(forceRefresh: true));
    add(const NotificationUnreadCountRequested());
  }

  /// Nova notificação recebida via push
  void _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) {
    // Adicionar nova notificação no topo da lista
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
    final result = await _repository.updateFCMToken(event.token);
    
    result.fold(
      (failure) => print('Erro ao atualizar FCM token: ${failure.message}'),
      (_) => print('FCM token atualizado com sucesso'),
    );
  }

  /// Inicia polling do contador de não lidas
  void _startUnreadCountPolling() {
    _unreadCountTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => add(const NotificationUnreadCountRequested()),
    );
  }

  @override
  Future<void> close() {
    _unreadCountTimer?.cancel();
    return super.close();
  }
} 

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
        // Atualizar estado local
        final updatedNotifications = state.notifications.map((notification) {
          if (notification.id == event.notificationId) {
            return notification is NotificationEntity
                ? NotificationEntity(
                    id: notification.id,
                    title: notification.title,
                    body: notification.body,
                    type: notification.type,
                    data: notification.data,
                    createdAt: notification.createdAt,
                    isRead: true,
                    offerId: notification.offerId,
                    caseId: notification.caseId,
                  )
                : notification;
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

  /// Marca todas como lidas
  Future<void> _onMarkAllAsRead(
    NotificationMarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    final result = await _repository.markAllAsRead();
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          status: NotificationStatus.success,
          unreadCount: 0,
        ));
        
        // Recarregar notificações
        add(const NotificationFetchRequested(forceRefresh: true));
      },
    );
  }

  /// Deleta notificação
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
        // Falha silenciosa para contador
        print('Erro ao buscar contador: ${failure.message}');
      },
      (count) => emit(state.copyWith(unreadCount: count)),
    );
  }

  /// Refresh das notificações
  Future<void> _onRefreshRequested(
    NotificationRefreshRequested event,
    Emitter<NotificationState> emit,
  ) async {
    add(const NotificationFetchRequested(forceRefresh: true));
    add(const NotificationUnreadCountRequested());
  }

  /// Nova notificação recebida via push
  void _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) {
    // Adicionar nova notificação no topo da lista
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
    final result = await _repository.updateFCMToken(event.token);
    
    result.fold(
      (failure) => print('Erro ao atualizar FCM token: ${failure.message}'),
      (_) => print('FCM token atualizado com sucesso'),
    );
  }

  /// Inicia polling do contador de não lidas
  void _startUnreadCountPolling() {
    _unreadCountTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => add(const NotificationUnreadCountRequested()),
    );
  }

  @override
  Future<void> close() {
    _unreadCountTimer?.cancel();
    return super.close();
  }
} 