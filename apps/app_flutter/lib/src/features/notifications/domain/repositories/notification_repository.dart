import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  /// Busca lista de notificações do usuário
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  });

  /// Marca uma notificação como lida
  Future<Either<Failure, void>> markAsRead(String notificationId);

  /// Marca todas as notificações como lidas
  Future<Either<Failure, void>> markAllAsRead();

  /// Deleta uma notificação
  Future<Either<Failure, void>> deleteNotification(String notificationId);

  /// Busca quantidade de notificações não lidas
  Future<Either<Failure, int>> getUnreadCount();

  /// Atualiza token FCM do usuário no backend
  Future<Either<Failure, void>> updateFCMToken(String token);

  /// Cria uma nova notificação
  Future<Either<Failure, void>> createNotification(NotificationEntity notification);
}