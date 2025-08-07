import 'package:meu_app/src/core/utils/app_logger.dart';
import '../../../notifications/domain/entities/notification_entity.dart';
import '../../../notifications/domain/repositories/notification_repository.dart';
import '../../../notifications/data/models/notification_model.dart';
import '../../data/datasources/case_notification_remote_data_source.dart';

class CaseNotificationService {
  final NotificationRepository _notificationRepository;
  final CaseNotificationRemoteDataSource _remoteDataSource;

  CaseNotificationService(
    this._notificationRepository,
    this._remoteDataSource,
  );

  /// Método utilitário para criar notificação local e enviar email
  Future<void> _sendCompleteNotification({
    required String notificationType,
    required String title,
    required String body,
    required NotificationType type,
    required String caseId,
    required Map<String, dynamic> data,
    required Map<String, dynamic> caseData,
    required Map<String, dynamic> notificationData,
    String? userEmail,
    String? userName,
  }) async {
    try {
      // 1. Criar notificação local no app
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        data: data,
        createdAt: DateTime.now(),
        isRead: false,
        caseId: caseId,
      );

      final result = await _notificationRepository.createNotification(notification);
      result.fold(
        (failure) => throw Exception('Erro ao criar notificação: ${failure.message}'),
        (_) => null,
      );

      // 2. Enviar email via backend (se dados de email estiverem disponíveis)
      if (userEmail != null && userName != null) {
        await _remoteDataSource.sendCaseNotificationEmail(
          notificationType: notificationType,
          userEmail: userEmail,
          userName: userName,
          caseData: caseData,
          notificationData: notificationData,
        );
      }

      AppLogger.info('Notificação completa enviada', {
        'type': notificationType,
        'case_id': caseId,
        'email_sent': userEmail != null,
      });
    } catch (e) {
      AppLogger.error('Erro ao enviar notificação completa', {'error': e.toString()});
      rethrow;
    }
  }

  /// Notifica quando um caso é atribuído a um advogado
  Future<void> notifyCaseAssigned({
    required String caseId,
    required String caseTitle,
    required String lawyerId,
    required String clientName,
    String? userEmail,
    String? userName,
  }) async {
    await _sendCompleteNotification(
      notificationType: 'caseAssigned',
      title: 'Novo Caso Atribuído',
      body: 'O caso "$caseTitle" foi atribuído a você pelo cliente $clientName',
      type: NotificationType.caseAssigned,
      caseId: caseId,
      data: {
        'action': 'view_case',
        'case_title': caseTitle,
        'client_name': clientName,
      },
      caseData: {
        'id': caseId,
        'title': caseTitle,
        'client_name': clientName,
      },
      notificationData: {
        'lawyer_id': lawyerId,
        'assigned_date': DateTime.now().toIso8601String(),
      },
      userEmail: userEmail,
      userName: userName,
    );
  }

  /// Notifica quando o status de um caso muda
  Future<void> notifyCaseStatusChanged({
    required String caseId,
    required String caseTitle,
    required String userId,
    required String oldStatus,
    required String newStatus,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Status do Caso Atualizado',
        body: 'O caso "$caseTitle" mudou de "$oldStatus" para "$newStatus"',
        type: NotificationType.caseStatusChanged,
        data: {
          'action': 'view_case',
          'case_title': caseTitle,
          'old_status': oldStatus,
          'new_status': newStatus,
        },
        createdAt: DateTime.now(),
        isRead: false,
        caseId: caseId,
      );

      final result = await _notificationRepository.createNotification(notification);
      result.fold(
        (failure) => throw Exception('Erro ao criar notificação: ${failure.message}'),
        (_) => null,
      );
      AppLogger.info('Notificação de mudança de status enviada', {
        'case_id': caseId,
        'user_id': userId,
        'new_status': newStatus,
      });
    } catch (e) {
      AppLogger.error('Erro ao enviar notificação de mudança de status', {'error': e.toString()});
    }
  }

  /// Notifica quando um documento é carregado
  Future<void> notifyDocumentUploaded({
    required String caseId,
    required String caseTitle,
    required String userId,
    required String documentName,
    required String uploaderName,
    String? userEmail,
    String? userName,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Novo Documento Carregado',
        body: '$uploaderName carregou o documento "$documentName" no caso "$caseTitle"',
        type: NotificationType.documentUploaded,
        data: {
          'action': 'view_documents',
          'case_title': caseTitle,
          'document_name': documentName,
          'uploader_name': uploaderName,
        },
        createdAt: DateTime.now(),
        isRead: false,
        caseId: caseId,
      );

      final result = await _notificationRepository.createNotification(notification);
      result.fold(
        (failure) => throw Exception('Erro ao criar notificação: ${failure.message}'),
        (_) => null,
      );
      AppLogger.info('Notificação de documento carregado enviada', {
        'case_id': caseId,
        'user_id': userId,
        'document': documentName,
      });
    } catch (e) {
      AppLogger.error('Erro ao enviar notificação de documento carregado', {'error': e.toString()});
    }
  }

  /// Notifica quando um documento é aprovado
  Future<void> notifyDocumentApproved({
    required String caseId,
    required String caseTitle,
    required String userId,
    required String documentName,
    required String approverName,
    String? userEmail,
    String? userName,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Documento Aprovado',
        body: '$approverName aprovou o documento "$documentName" do caso "$caseTitle"',
        type: NotificationType.documentApproved,
        data: {
          'action': 'view_documents',
          'case_title': caseTitle,
          'document_name': documentName,
          'approver_name': approverName,
        },
        createdAt: DateTime.now(),
        isRead: false,
        caseId: caseId,
      );

      final result = await _notificationRepository.createNotification(notification);
      result.fold(
        (failure) => throw Exception('Erro ao criar notificação: ${failure.message}'),
        (_) => null,
      );
      AppLogger.info('Notificação de documento aprovado enviada', {
        'case_id': caseId,
        'user_id': userId,
        'document': documentName,
      });
    } catch (e) {
      AppLogger.error('Erro ao enviar notificação de documento aprovado', {'error': e.toString()});
    }
  }

  /// Notifica quando um documento é rejeitado
  Future<void> notifyDocumentRejected({
    required String caseId,
    required String caseTitle,
    required String userId,
    required String documentName,
    required String rejectionReason,
    required String reviewerName,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Documento Rejeitado',
        body: '$reviewerName rejeitou o documento "$documentName" do caso "$caseTitle"',
        type: NotificationType.documentRejected,
        data: {
          'action': 'view_documents',
          'case_title': caseTitle,
          'document_name': documentName,
          'rejection_reason': rejectionReason,
          'reviewer_name': reviewerName,
        },
        createdAt: DateTime.now(),
        isRead: false,
        caseId: caseId,
      );

      final result = await _notificationRepository.createNotification(notification);
      result.fold(
        (failure) => throw Exception('Erro ao criar notificação: ${failure.message}'),
        (_) => null,
      );
      AppLogger.info('Notificação de documento rejeitado enviada', {
        'case_id': caseId,
        'user_id': userId,
        'document': documentName,
      });
    } catch (e) {
      AppLogger.error('Erro ao enviar notificação de documento rejeitado', {'error': e.toString()});
    }
  }

  /// Notifica quando há uma nova mensagem no chat do caso
  Future<void> notifyNewCaseMessage({
    required String caseId,
    required String caseTitle,
    required String userId,
    required String senderName,
    required String messagePreview,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Nova Mensagem no Caso',
        body: '$senderName: $messagePreview',
        type: NotificationType.newCaseMessage,
        data: {
          'action': 'view_case_chat',
          'case_title': caseTitle,
          'sender_name': senderName,
          'message_preview': messagePreview,
        },
        createdAt: DateTime.now(),
        isRead: false,
        caseId: caseId,
      );

      final result = await _notificationRepository.createNotification(notification);
      result.fold(
        (failure) => throw Exception('Erro ao criar notificação: ${failure.message}'),
        (_) => null,
      );
      AppLogger.info('Notificação de nova mensagem enviada', {
        'case_id': caseId,
        'user_id': userId,
        'sender': senderName,
      });
    } catch (e) {
      AppLogger.error('Erro ao enviar notificação de nova mensagem', {'error': e.toString()});
    }
  }

  /// Notifica quando um prazo está se aproximando
  Future<void> notifyCaseDeadlineApproaching({
    required String caseId,
    required String caseTitle,
    required String userId,
    required DateTime deadline,
    required String taskDescription,
  }) async {
    try {
      final daysUntilDeadline = deadline.difference(DateTime.now()).inDays;
      final timeText = daysUntilDeadline > 1 
          ? '$daysUntilDeadline dias'
          : daysUntilDeadline == 1 
              ? 'amanhã'
              : 'hoje';

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Prazo Próximo',
        body: 'O prazo para "$taskDescription" do caso "$caseTitle" vence $timeText',
        type: NotificationType.caseDeadlineApproaching,
        data: {
          'action': 'view_case',
          'case_title': caseTitle,
          'task_description': taskDescription,
          'deadline': deadline.toIso8601String(),
          'days_until_deadline': daysUntilDeadline,
        },
        createdAt: DateTime.now(),
        isRead: false,
        caseId: caseId,
      );

      final result = await _notificationRepository.createNotification(notification);
      result.fold(
        (failure) => throw Exception('Erro ao criar notificação: ${failure.message}'),
        (_) => null,
      );
      AppLogger.info('Notificação de prazo próximo enviada', {
        'case_id': caseId,
        'user_id': userId,
        'days_until_deadline': daysUntilDeadline,
      });
    } catch (e) {
      AppLogger.error('Erro ao enviar notificação de prazo próximo', {'error': e.toString()});
    }
  }

  /// Notifica quando um caso é concluído
  Future<void> notifyCaseCompleted({
    required String caseId,
    required String caseTitle,
    required String userId,
    required String completedBy,
    String? userEmail,
    String? userName,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Caso Concluído',
        body: 'O caso "$caseTitle" foi concluído por $completedBy',
        type: NotificationType.caseCompleted,
        data: {
          'action': 'view_case',
          'case_title': caseTitle,
          'completed_by': completedBy,
        },
        createdAt: DateTime.now(),
        isRead: false,
        caseId: caseId,
      );

      final result = await _notificationRepository.createNotification(notification);
      result.fold(
        (failure) => throw Exception('Erro ao criar notificação: ${failure.message}'),
        (_) => null,
      );
      AppLogger.info('Notificação de caso concluído enviada', {
        'case_id': caseId,
        'user_id': userId,
        'completed_by': completedBy,
      });
    } catch (e) {
      AppLogger.error('Erro ao enviar notificação de caso concluído', {'error': e.toString()});
    }
  }

  /// Notifica quando uma audiência é marcada
  Future<void> notifyHearingScheduled({
    required String caseId,
    required String caseTitle,
    required String userId,
    required DateTime hearingDate,
    required String location,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Audiência Marcada',
        body: 'Audiência do caso "$caseTitle" marcada para ${_formatDate(hearingDate)} às ${_formatTime(hearingDate)}',
        type: NotificationType.hearingScheduled,
        data: {
          'action': 'view_case',
          'case_title': caseTitle,
          'hearing_date': hearingDate.toIso8601String(),
          'location': location,
        },
        createdAt: DateTime.now(),
        isRead: false,
        caseId: caseId,
      );

      final result = await _notificationRepository.createNotification(notification);
      result.fold(
        (failure) => throw Exception('Erro ao criar notificação: ${failure.message}'),
        (_) => null,
      );
      AppLogger.info('Notificação de audiência marcada enviada', {
        'case_id': caseId,
        'user_id': userId,
        'hearing_date': hearingDate.toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('Erro ao enviar notificação de audiência marcada', {'error': e.toString()});
    }
  }

  /// Notifica quando um caso é transferido
  Future<void> notifyCaseTransferred({
    required String caseId,
    required String caseTitle,
    required String userId,
    required String fromLawyer,
    required String toLawyer,
    required String transferReason,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Caso Transferido',
        body: 'O caso "$caseTitle" foi transferido de $fromLawyer para $toLawyer',
        type: NotificationType.caseTransferred,
        data: {
          'action': 'view_case',
          'case_title': caseTitle,
          'from_lawyer': fromLawyer,
          'to_lawyer': toLawyer,
          'transfer_reason': transferReason,
        },
        createdAt: DateTime.now(),
        isRead: false,
        caseId: caseId,
      );

      final result = await _notificationRepository.createNotification(notification);
      result.fold(
        (failure) => throw Exception('Erro ao criar notificação: ${failure.message}'),
        (_) => null,
      );
      AppLogger.info('Notificação de caso transferido enviada', {
        'case_id': caseId,
        'user_id': userId,
        'from_lawyer': fromLawyer,
        'to_lawyer': toLawyer,
      });
    } catch (e) {
      AppLogger.error('Erro ao enviar notificação de caso transferido', {'error': e.toString()});
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}