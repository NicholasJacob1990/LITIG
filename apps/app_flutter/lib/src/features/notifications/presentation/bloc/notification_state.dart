part of 'notification_bloc.dart';

enum NotificationStatus {
  initial,
  loading,
  loadingMore,
  success,
  error,
}

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final bool hasReachedMax;
  final String? errorMessage;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.unreadCount = 0,
    this.hasReachedMax = false,
    this.errorMessage,
  });

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationEntity>? notifications,
    int? unreadCount,
    bool? hasReachedMax,
    String? errorMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Verifica se há notificações não lidas
  bool get hasUnreadNotifications => unreadCount > 0;

  /// Verifica se está carregando pela primeira vez
  bool get isInitialLoading => status == NotificationStatus.loading && notifications.isEmpty;

  /// Verifica se está carregando mais dados
  bool get isLoadingMore => status == NotificationStatus.loadingMore;

  /// Verifica se houve erro
  bool get hasError => status == NotificationStatus.error;

  /// Verifica se está em estado de sucesso
  bool get isSuccess => status == NotificationStatus.success;

  /// Retorna notificações não lidas
  List<NotificationEntity> get unreadNotifications =>
      notifications.where((notification) => !notification.isRead).toList();

  /// Retorna notificações críticas não lidas
  List<NotificationEntity> get criticalUnreadNotifications =>
      unreadNotifications.where((notification) => notification.isCritical).toList();

  /// Retorna notificações relacionadas a ofertas
  List<NotificationEntity> get offerNotifications =>
      notifications.where((notification) => notification.isOfferRelated).toList();

  @override
  List<Object?> get props => [
        status,
        notifications,
        unreadCount,
        hasReachedMax,
        errorMessage,
      ];
} 