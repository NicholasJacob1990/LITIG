import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';

class ScheduleSlaNotification implements UseCase<bool, ScheduleSlaNotificationParams> {
  final SlaNotificationRepository repository;

  ScheduleSlaNotification(this.repository);

  @override
  Future<Either<Failure, bool>> call(ScheduleSlaNotificationParams params) async {
    return await repository.scheduleNotification(
      caseId: params.caseId,
      type: params.type,
      scheduledFor: params.scheduledFor,
      recipients: params.recipients,
      template: params.template,
      data: params.data,
    );
  }
}

class ScheduleSlaNotificationParams {
  final String caseId;
  final SlaNotificationType type;
  final DateTime scheduledFor;
  final List<String> recipients;
  final String template;
  final Map<String, dynamic> data;

  ScheduleSlaNotificationParams({
    required this.caseId,
    required this.type,
    required this.scheduledFor,
    required this.recipients,
    required this.template,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'caseId': caseId,
      'type': type.toString(),
      'scheduledFor': scheduledFor.toIso8601String(),
      'recipients': recipients,
      'template': template,
      'data': data,
    };
  }
}

enum SlaNotificationType {
  deadlineApproaching,
  deadlineReached,
  slaViolated,
  escalationRequired,
  reminderSent,
  clientNotification,
  managerAlert,
  systemNotification
}

abstract class SlaNotificationRepository {
  Future<Either<Failure, bool>> scheduleNotification({
    required String caseId,
    required SlaNotificationType type,
    required DateTime scheduledFor,
    required List<String> recipients,
    required String template,
    required Map<String, dynamic> data,
  });

  Future<Either<Failure, bool>> cancelScheduledNotification(String notificationId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getScheduledNotifications(String firmId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getNotificationHistory({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, bool>> sendImmediateNotification({
    required String caseId,
    required SlaNotificationType type,
    required List<String> recipients,
    required String template,
    required Map<String, dynamic> data,
  });

  Future<Either<Failure, Map<String, dynamic>>> getNotificationTemplates(String firmId);
  Future<Either<Failure, bool>> updateNotificationTemplate({
    required String firmId,
    required String templateId,
    required Map<String, dynamic> template,
  });
}

class CancelSlaNotification implements UseCase<bool, CancelSlaNotificationParams> {
  final SlaNotificationRepository repository;

  CancelSlaNotification(this.repository);

  @override
  Future<Either<Failure, bool>> call(CancelSlaNotificationParams params) async {
    return await repository.cancelScheduledNotification(params.notificationId);
  }
}

class CancelSlaNotificationParams {
  final String notificationId;

  CancelSlaNotificationParams({required this.notificationId});
}

class SendImmediateSlaNotification implements UseCase<bool, SendImmediateSlaNotificationParams> {
  final SlaNotificationRepository repository;

  SendImmediateSlaNotification(this.repository);

  @override
  Future<Either<Failure, bool>> call(SendImmediateSlaNotificationParams params) async {
    return await repository.sendImmediateNotification(
      caseId: params.caseId,
      type: params.type,
      recipients: params.recipients,
      template: params.template,
      data: params.data,
    );
  }
}

class SendImmediateSlaNotificationParams {
  final String caseId;
  final SlaNotificationType type;
  final List<String> recipients;
  final String template;
  final Map<String, dynamic> data;

  SendImmediateSlaNotificationParams({
    required this.caseId,
    required this.type,
    required this.recipients,
    required this.template,
    required this.data,
  });
}
