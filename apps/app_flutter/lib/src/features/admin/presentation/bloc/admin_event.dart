import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

// Eventos de Carregamento de Dados
class LoadAdminDashboard extends AdminEvent {
  const LoadAdminDashboard();
}

class LoadAdminMetrics extends AdminEvent {
  final String metricsType; // 'system', 'users', 'cases', 'quality'

  const LoadAdminMetrics({required this.metricsType});

  @override
  List<Object?> get props => [metricsType];
}

class LoadAdminAuditLogs extends AdminEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? logType; // 'all', 'auth', 'cases', 'payments', 'system'

  const LoadAdminAuditLogs({
    this.startDate,
    this.endDate,
    this.logType,
  });

  @override
  List<Object?> get props => [startDate, endDate, logType];
}

// Eventos de Relatórios
class GenerateExecutiveReport extends AdminEvent {
  final String reportType; // 'monthly', 'quarterly', 'annual', 'custom'
  final Map<String, dynamic>? dateRange;

  const GenerateExecutiveReport({
    required this.reportType,
    this.dateRange,
  });

  @override
  List<Object?> get props => [reportType, dateRange];
}

class ExportAdminReport extends AdminEvent {
  final String format; // 'pdf', 'excel', 'csv'
  final String reportType;

  const ExportAdminReport({
    required this.format,
    required this.reportType,
  });

  @override
  List<Object?> get props => [format, reportType];
}

// Eventos de Sincronização
class ForceGlobalSync extends AdminEvent {
  const ForceGlobalSync();
}

// Eventos de Atualização
class RefreshAdminData extends AdminEvent {
  const RefreshAdminData();
}

class UpdateAdminSettings extends AdminEvent {
  final Map<String, dynamic> settings;

  const UpdateAdminSettings({required this.settings});

  @override
  List<Object?> get props => [settings];
}

// Eventos de Usuários
class LoadAdminUsers extends AdminEvent {
  final String? userType; // 'all', 'lawyers', 'clients', 'admins'
  final String? status; // 'all', 'active', 'inactive', 'pending'

  const LoadAdminUsers({
    this.userType,
    this.status,
  });

  @override
  List<Object?> get props => [userType, status];
}

class UpdateUserStatus extends AdminEvent {
  final String userId;
  final String newStatus; // 'active', 'inactive', 'suspended'

  const UpdateUserStatus({
    required this.userId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [userId, newStatus];
}

// Eventos de Casos
class LoadAdminCases extends AdminEvent {
  final String? status; // 'all', 'active', 'closed', 'pending'
  final String? priority; // 'all', 'high', 'medium', 'low'

  const LoadAdminCases({
    this.status,
    this.priority,
  });

  @override
  List<Object?> get props => [status, priority];
}

// Eventos de Sistema
class LoadSystemHealth extends AdminEvent {
  const LoadSystemHealth();
}

class UpdateSystemConfig extends AdminEvent {
  final Map<String, dynamic> config;

  const UpdateSystemConfig({required this.config});

  @override
  List<Object?> get props => [config];
}

// Eventos de Auditoria
class LoadAuditTrail extends AdminEvent {
  final String? action; // 'all', 'login', 'case_update', 'payment', 'admin'
  final String? userId;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadAuditTrail({
    this.action,
    this.userId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [action, userId, startDate, endDate];
}

// Eventos de Pagamentos
class LoadPaymentAnalytics extends AdminEvent {
  final String? period; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadPaymentAnalytics({
    this.period,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [period, startDate, endDate];
}

// Eventos de Notificações
class LoadAdminNotifications extends AdminEvent {
  final String? type; // 'all', 'system', 'user', 'payment', 'security'
  final bool? isRead;

  const LoadAdminNotifications({
    this.type,
    this.isRead,
  });

  @override
  List<Object?> get props => [type, isRead];
}

class MarkNotificationAsRead extends AdminEvent {
  final String notificationId;

  const MarkNotificationAsRead({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

// Eventos de Backup e Restauração
class CreateSystemBackup extends AdminEvent {
  final String backupType; // 'full', 'data', 'config'
  final String? description;

  const CreateSystemBackup({
    required this.backupType,
    this.description,
  });

  @override
  List<Object?> get props => [backupType, description];
}

class RestoreSystemBackup extends AdminEvent {
  final String backupId;

  const RestoreSystemBackup({required this.backupId});

  @override
  List<Object?> get props => [backupId];
}

// Eventos de Segurança
class LoadSecurityLogs extends AdminEvent {
  final String? severity; // 'all', 'low', 'medium', 'high', 'critical'
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadSecurityLogs({
    this.severity,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [severity, startDate, endDate];
}

class UpdateSecuritySettings extends AdminEvent {
  final Map<String, dynamic> securitySettings;

  const UpdateSecuritySettings({required this.securitySettings});

  @override
  List<Object?> get props => [securitySettings];
} 