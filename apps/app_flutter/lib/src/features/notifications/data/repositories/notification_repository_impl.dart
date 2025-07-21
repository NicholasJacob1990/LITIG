import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/simple_api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final SimpleApiService _apiService;
  final StorageService _storageService;
  
  static const String _notificationsCacheKey = 'cached_notifications';
  static const Duration _cacheExpiration = Duration(minutes: 5);

  NotificationRepositoryImpl({
    required SimpleApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService,
       _storageService = storageService;

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    try {
      // Verificar cache primeiro (se não for refresh forçado)
      if (!forceRefresh) {
        final cachedNotifications = await _getCachedNotifications();
        if (cachedNotifications.isNotEmpty) {
          return Right(cachedNotifications);
        }
      }

      // Buscar do backend
      final response = await _apiService.get(
        '/notifications?page=${page.toString()}&limit=${limit.toString()}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> notificationsJson = response.data['notifications'];
        final notifications = notificationsJson
            .map((json) => NotificationModel.fromJson(json))
            .cast<NotificationEntity>()
            .toList();

        // Salvar no cache
        await _cacheNotifications(notifications);

        return Right(notifications);
      } else {
        return Left(ServerFailure(message: 'Falha ao buscar notificações'));
      }
    } catch (e) {
      // Tentar retornar cache em caso de erro
      final cachedNotifications = await _getCachedNotifications();
      if (cachedNotifications.isNotEmpty) {
        return Right(cachedNotifications);
      }
      
      return Left(ServerFailure(message: 'Erro ao carregar notificações: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      final response = await _apiService.patch(
        '/notifications/$notificationId/read',
      );

      if (response.statusCode == 200) {
        // Atualizar cache local
        await _updateNotificationInCache(notificationId, isRead: true);
        return const Right(null);
      } else {
        return Left(ServerFailure(message: 'Falha ao marcar notificação como lida'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao marcar como lida: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      final response = await _apiService.patch('/notifications/read-all');

      if (response.statusCode == 200) {
        // Limpar cache para forçar reload
        await _clearNotificationsCache();
        return const Right(null);
      } else {
        return Left(ServerFailure(message: 'Falha ao marcar todas como lidas'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao marcar todas como lidas: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String notificationId) async {
    try {
      final response = await _apiService.delete('/notifications/$notificationId');

      if (response.statusCode == 200) {
        // Remover do cache local
        await _removeNotificationFromCache(notificationId);
        return const Right(null);
      } else {
        return Left(ServerFailure(message: 'Falha ao deletar notificação'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao deletar notificação: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final response = await _apiService.get('/notifications/unread-count');

      if (response.statusCode == 200) {
        final count = response.data['count'] as int;
        return Right(count);
      } else {
        return Left(ServerFailure(message: 'Falha ao buscar contador de não lidas'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao buscar contador: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateFCMToken(String token) async {
    try {
      final response = await _apiService.post(
        '/notifications/fcm-token',
        data: {'token': token},
      );

      if (response.statusCode == 200) {
        return const Right(null);
      } else {
        return Left(ServerFailure(message: 'Falha ao atualizar token FCM'));
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao atualizar token: $e'));
    }
  }

  /// Busca notificações do cache local
  Future<List<NotificationEntity>> _getCachedNotifications() async {
    try {
      final cachedData = await _storageService.getJson(_notificationsCacheKey);
      if (cachedData != null) {
        final Map<String, dynamic> cache = Map<String, dynamic>.from(cachedData);
        final DateTime cacheTime = DateTime.parse(cache['timestamp']);
        
        // Verificar se cache ainda é válido
        if (DateTime.now().difference(cacheTime) < _cacheExpiration) {
          final List<dynamic> notificationsJson = cache['notifications'];
          return notificationsJson
              .map((json) => NotificationModel.fromJson(json))
              .cast<NotificationEntity>()
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Erro ao ler cache de notificações: $e');
    }
    return [];
  }

  /// Salva notificações no cache local
  Future<void> _cacheNotifications(List<NotificationEntity> notifications) async {
    try {
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'notifications': notifications
            .map((n) => (n as NotificationModel).toJson())
            .toList(),
      };
      await _storageService.saveJson(_notificationsCacheKey, cacheData);
    } catch (e) {
      debugPrint('Erro ao salvar cache de notificações: $e');
    }
  }

  /// Atualiza uma notificação específica no cache
  Future<void> _updateNotificationInCache(String notificationId, {bool? isRead}) async {
    try {
      final cachedNotifications = await _getCachedNotifications();
      final updatedNotifications = cachedNotifications.map((notification) {
        if (notification.id == notificationId) {
          return (notification as NotificationModel).copyWith(isRead: isRead);
        }
        return notification;
      }).toList();
      
      await _cacheNotifications(updatedNotifications);
    } catch (e) {
      debugPrint('Erro ao atualizar cache: $e');
    }
  }

  /// Remove uma notificação do cache
  Future<void> _removeNotificationFromCache(String notificationId) async {
    try {
      final cachedNotifications = await _getCachedNotifications();
      final filteredNotifications = cachedNotifications
          .where((notification) => notification.id != notificationId)
          .toList();
      
      await _cacheNotifications(filteredNotifications);
    } catch (e) {
      debugPrint('Erro ao remover do cache: $e');
    }
  }

  /// Limpa o cache de notificações
  Future<void> _clearNotificationsCache() async {
    try {
      await _storageService.remove(_notificationsCacheKey);
    } catch (e) {
      debugPrint('Erro ao limpar cache: $e');
    }
  }
} 
