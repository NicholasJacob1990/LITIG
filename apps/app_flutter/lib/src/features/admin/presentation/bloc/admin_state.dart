import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_dashboard_data.dart';
import '../../domain/entities/admin_metrics.dart';
import '../../domain/entities/admin_audit_log.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

// Estados Iniciais
class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}

// Estados de Dashboard
class AdminDashboardLoaded extends AdminState {
  final AdminDashboardData dashboardData;

  const AdminDashboardLoaded(this.dashboardData);

  @override
  List<Object?> get props => [dashboardData];
}

// Estados de Métricas
class AdminMetricsLoaded extends AdminState {
  final AdminDashboardData dashboardData;
  final AdminMetrics metrics;

  const AdminMetricsLoaded({
    required this.dashboardData,
    required this.metrics,
  });

  @override
  List<Object?> get props => [dashboardData, metrics];
}

// Estados de Auditoria
class AdminAuditLogsLoaded extends AdminState {
  final AdminDashboardData dashboardData;
  final List<AdminAuditLog> auditLogs;

  const AdminAuditLogsLoaded({
    required this.dashboardData,
    required this.auditLogs,
  });

  @override
  List<Object?> get props => [dashboardData, auditLogs];
}

// Estados de Relatórios
class AdminGeneratingReport extends AdminState {
  final AdminDashboardData dashboardData;

  const AdminGeneratingReport(this.dashboardData);

  @override
  List<Object?> get props => [dashboardData];
}

class AdminReportGenerated extends AdminState {
  final AdminDashboardData dashboardData;
  final Map<String, dynamic> report;

  const AdminReportGenerated({
    required this.dashboardData,
    required this.report,
  });

  @override
  List<Object?> get props => [dashboardData, report];
}

class AdminExporting extends AdminState {
  final AdminDashboardData dashboardData;

  const AdminExporting(this.dashboardData);

  @override
  List<Object?> get props => [dashboardData];
}

class AdminExportCompleted extends AdminState {
  final AdminDashboardData dashboardData;
  final Map<String, dynamic> report;
  final String exportPath;

  const AdminExportCompleted({
    required this.dashboardData,
    required this.report,
    required this.exportPath,
  });

  @override
  List<Object?> get props => [dashboardData, report, exportPath];
}

// Estados de Sincronização
class AdminSyncing extends AdminState {
  final AdminDashboardData dashboardData;

  const AdminSyncing(this.dashboardData);

  @override
  List<Object?> get props => [dashboardData];
}

class AdminSyncCompleted extends AdminState {
  final AdminDashboardData dashboardData;
  final Map<String, dynamic> syncResult;

  const AdminSyncCompleted({
    required this.dashboardData,
    required this.syncResult,
  });

  @override
  List<Object?> get props => [dashboardData, syncResult];
}

// Estados de Atualização
class AdminUpdating extends AdminState {
  final AdminDashboardData dashboardData;

  const AdminUpdating(this.dashboardData);

  @override
  List<Object?> get props => [dashboardData];
}

class AdminSettingsUpdated extends AdminState {
  final AdminDashboardData dashboardData;
  final Map<String, dynamic> settings;

  const AdminSettingsUpdated({
    required this.dashboardData,
    required this.settings,
  });

  @override
  List<Object?> get props => [dashboardData, settings];
}

// Estados de Usuários
class AdminUsersLoaded extends AdminState {
  final AdminDashboardData dashboardData;
  final List<Map<String, dynamic>> users;
  final String? userType;
  final String? status;

  const AdminUsersLoaded({
    required this.dashboardData,
    required this.users,
    this.userType,
    this.status,
  });

  @override
  List<Object?> get props => [dashboardData, users, userType, status];
}

class AdminUserStatusUpdated extends AdminState {
  final AdminDashboardData dashboardData;
  final String userId;
  final String newStatus;

  const AdminUserStatusUpdated({
    required this.dashboardData,
    required this.userId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [dashboardData, userId, newStatus];
}

// Estados de Casos
class AdminCasesLoaded extends AdminState {
  final AdminDashboardData dashboardData;
  final List<Map<String, dynamic>> cases;
  final String? status;
  final String? priority;

  const AdminCasesLoaded({
    required this.dashboardData,
    required this.cases,
    this.status,
    this.priority,
  });

  @override
  List<Object?> get props => [dashboardData, cases, status, priority];
}

// Estados de Sistema
class AdminSystemHealthLoaded extends AdminState {
  final AdminDashboardData dashboardData;
  final Map<String, dynamic> systemHealth;

  const AdminSystemHealthLoaded({
    required this.dashboardData,
    required this.systemHealth,
  });

  @override
  List<Object?> get props => [dashboardData, systemHealth];
}

class AdminSystemConfigUpdated extends AdminState {
  final AdminDashboardData dashboardData;
  final Map<String, dynamic> config;

  const AdminSystemConfigUpdated({
    required this.dashboardData,
    required this.config,
  });

  @override
  List<Object?> get props => [dashboardData, config];
}

// Estados de Auditoria
class AdminAuditTrailLoaded extends AdminState {
  final AdminDashboardData dashboardData;
  final List<Map<String, dynamic>> auditTrail;
  final String? action;
  final String? userId;
  final DateTime? startDate;
  final DateTime? endDate;

  const AdminAuditTrailLoaded({
    required this.dashboardData,
    required this.auditTrail,
    this.action,
    this.userId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [dashboardData, auditTrail, action, userId, startDate, endDate];
}

// Estados de Pagamentos
class AdminPaymentAnalyticsLoaded extends AdminState {
  final AdminDashboardData dashboardData;
  final Map<String, dynamic> paymentAnalytics;
  final String? period;
  final DateTime? startDate;
  final DateTime? endDate;

  const AdminPaymentAnalyticsLoaded({
    required this.dashboardData,
    required this.paymentAnalytics,
    this.period,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [dashboardData, paymentAnalytics, period, startDate, endDate];
}

// Estados de Notificações
class AdminNotificationsLoaded extends AdminState {
  final AdminDashboardData dashboardData;
  final List<Map<String, dynamic>> notifications;
  final String? type;
  final bool? isRead;

  const AdminNotificationsLoaded({
    required this.dashboardData,
    required this.notifications,
    this.type,
    this.isRead,
  });

  @override
  List<Object?> get props => [dashboardData, notifications, type, isRead];
}

class AdminNotificationMarkedAsRead extends AdminState {
  final AdminDashboardData dashboardData;
  final String notificationId;

  const AdminNotificationMarkedAsRead({
    required this.dashboardData,
    required this.notificationId,
  });

  @override
  List<Object?> get props => [dashboardData, notificationId];
}

// Estados de Backup
class AdminBackupCreating extends AdminState {
  final AdminDashboardData dashboardData;
  final String backupType;

  const AdminBackupCreating({
    required this.dashboardData,
    required this.backupType,
  });

  @override
  List<Object?> get props => [dashboardData, backupType];
}

class AdminBackupCreated extends AdminState {
  final AdminDashboardData dashboardData;
  final String backupId;
  final String backupType;
  final String? description;

  const AdminBackupCreated({
    required this.dashboardData,
    required this.backupId,
    required this.backupType,
    this.description,
  });

  @override
  List<Object?> get props => [dashboardData, backupId, backupType, description];
}

class AdminBackupRestoring extends AdminState {
  final AdminDashboardData dashboardData;
  final String backupId;

  const AdminBackupRestoring({
    required this.dashboardData,
    required this.backupId,
  });

  @override
  List<Object?> get props => [dashboardData, backupId];
}

class AdminBackupRestored extends AdminState {
  final AdminDashboardData dashboardData;
  final String backupId;

  const AdminBackupRestored({
    required this.dashboardData,
    required this.backupId,
  });

  @override
  List<Object?> get props => [dashboardData, backupId];
}

// Estados de Segurança
class AdminSecurityLogsLoaded extends AdminState {
  final AdminDashboardData dashboardData;
  final List<Map<String, dynamic>> securityLogs;
  final String? severity;
  final DateTime? startDate;
  final DateTime? endDate;

  const AdminSecurityLogsLoaded({
    required this.dashboardData,
    required this.securityLogs,
    this.severity,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [dashboardData, securityLogs, severity, startDate, endDate];
}

class AdminSecuritySettingsUpdated extends AdminState {
  final AdminDashboardData dashboardData;
  final Map<String, dynamic> securitySettings;

  const AdminSecuritySettingsUpdated({
    required this.dashboardData,
    required this.securitySettings,
  });

  @override
  List<Object?> get props => [dashboardData, securitySettings];
} 