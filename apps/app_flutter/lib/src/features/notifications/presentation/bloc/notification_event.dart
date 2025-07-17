part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationFetchRequested extends NotificationEvent {
  final int page;
  final int limit;
  final bool forceRefresh;

  const NotificationFetchRequested({
    this.page = 1,
    this.limit = 20,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [page, limit, forceRefresh];
}

class NotificationMarkAsRead extends NotificationEvent {
  final String notificationId;

  const NotificationMarkAsRead(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

class NotificationMarkAllAsRead extends NotificationEvent {
  const NotificationMarkAllAsRead();
}

class NotificationDelete extends NotificationEvent {
  final String notificationId;

  const NotificationDelete(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

class NotificationUnreadCountRequested extends NotificationEvent {
  const NotificationUnreadCountRequested();
}

class NotificationRefreshRequested extends NotificationEvent {
  const NotificationRefreshRequested();
}

class NotificationReceived extends NotificationEvent {
  final NotificationEntity notification;

  const NotificationReceived(this.notification);

  @override
  List<Object> get props => [notification];
}

class NotificationFCMTokenUpdate extends NotificationEvent {
  final String token;

  const NotificationFCMTokenUpdate(this.token);

  @override
  List<Object> get props => [token];
} 

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationFetchRequested extends NotificationEvent {
  final int page;
  final int limit;
  final bool forceRefresh;

  const NotificationFetchRequested({
    this.page = 1,
    this.limit = 20,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [page, limit, forceRefresh];
}

class NotificationMarkAsRead extends NotificationEvent {
  final String notificationId;

  const NotificationMarkAsRead(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

class NotificationMarkAllAsRead extends NotificationEvent {
  const NotificationMarkAllAsRead();
}

class NotificationDelete extends NotificationEvent {
  final String notificationId;

  const NotificationDelete(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

class NotificationUnreadCountRequested extends NotificationEvent {
  const NotificationUnreadCountRequested();
}

class NotificationRefreshRequested extends NotificationEvent {
  const NotificationRefreshRequested();
}

class NotificationReceived extends NotificationEvent {
  final NotificationEntity notification;

  const NotificationReceived(this.notification);

  @override
  List<Object> get props => [notification];
}

class NotificationFCMTokenUpdate extends NotificationEvent {
  final String token;

  const NotificationFCMTokenUpdate(this.token);

  @override
  List<Object> get props => [token];
} 