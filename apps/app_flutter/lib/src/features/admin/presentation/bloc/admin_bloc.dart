import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_admin_dashboard.dart';
import '../../domain/usecases/get_admin_metrics.dart';
import '../../domain/usecases/get_admin_audit_logs.dart';
import '../../domain/usecases/generate_executive_report.dart' as usecases;
import '../../domain/usecases/force_global_sync.dart' as usecases;
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final GetAdminDashboard _getAdminDashboard;
  final GetAdminMetrics _getAdminMetrics;
  final GetAdminAuditLogs _getAdminAuditLogs;
  final usecases.GenerateExecutiveReport _generateExecutiveReport;
  final usecases.ForceGlobalSync _forceGlobalSync;

  AdminBloc({
    required GetAdminDashboard getAdminDashboard,
    required GetAdminMetrics getAdminMetrics,
    required GetAdminAuditLogs getAdminAuditLogs,
    required usecases.GenerateExecutiveReport generateExecutiveReport,
    required usecases.ForceGlobalSync forceGlobalSync,
  })  : _getAdminDashboard = getAdminDashboard,
        _getAdminMetrics = getAdminMetrics,
        _getAdminAuditLogs = getAdminAuditLogs,
        _generateExecutiveReport = generateExecutiveReport,
        _forceGlobalSync = forceGlobalSync,
        super(const AdminInitial()) {
    
    on<LoadAdminDashboard>(_onLoadAdminDashboard);
    on<LoadAdminMetrics>(_onLoadAdminMetrics);
    on<LoadAdminAuditLogs>(_onLoadAdminAuditLogs);
    on<GenerateExecutiveReport>(_onGenerateExecutiveReport);
    on<ForceGlobalSync>(_onForceGlobalSync);
    on<RefreshAdminData>(_onRefreshAdminData);
    on<ExportAdminReport>(_onExportAdminReport);
    on<UpdateAdminSettings>(_onUpdateAdminSettings);
  }

  Future<void> _onLoadAdminDashboard(
    LoadAdminDashboard event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    
    final result = await _getAdminDashboard(NoParams());
    
    result.fold(
      (failure) => emit(AdminError(_mapFailureToMessage(failure))),
      (dashboardData) => emit(AdminDashboardLoaded(dashboardData)),
    );
  }

  Future<void> _onLoadAdminMetrics(
    LoadAdminMetrics event,
    Emitter<AdminState> emit,
  ) async {
    if (state is AdminDashboardLoaded) {
      final currentState = state as AdminDashboardLoaded;
      
      final result = await _getAdminMetrics(GetAdminMetricsParams(metricsType: event.metricsType));
      
      result.fold(
        (failure) => emit(AdminError(_mapFailureToMessage(failure))),
        (metrics) => emit(AdminMetricsLoaded(
          dashboardData: currentState.dashboardData,
          metrics: metrics,
        )),
      );
    }
  }

  Future<void> _onLoadAdminAuditLogs(
    LoadAdminAuditLogs event,
    Emitter<AdminState> emit,
  ) async {
    if (state is AdminDashboardLoaded) {
      final currentState = state as AdminDashboardLoaded;
      
      final result = await _getAdminAuditLogs(GetAdminAuditLogsParams(
        startDate: event.startDate,
        endDate: event.endDate,
        logType: event.logType,
      ));
      
      result.fold(
        (failure) => emit(AdminError(_mapFailureToMessage(failure))),
        (auditLogs) => emit(AdminAuditLogsLoaded(
          dashboardData: currentState.dashboardData,
          auditLogs: auditLogs,
        )),
      );
    }
  }

  Future<void> _onGenerateExecutiveReport(
    GenerateExecutiveReport event,
    Emitter<AdminState> emit,
  ) async {
    if (state is AdminDashboardLoaded) {
      final currentState = state as AdminDashboardLoaded;
      
      emit(AdminGeneratingReport(currentState.dashboardData));
      
      final result = await _generateExecutiveReport(usecases.GenerateExecutiveReportParams(
        reportType: event.reportType,
        dateRange: event.dateRange,
      ));
      
      result.fold(
        (failure) => emit(AdminError(_mapFailureToMessage(failure))),
        (report) => emit(AdminReportGenerated(
          dashboardData: currentState.dashboardData,
          report: report,
        )),
      );
    }
  }

  Future<void> _onForceGlobalSync(
    ForceGlobalSync event,
    Emitter<AdminState> emit,
  ) async {
    if (state is AdminDashboardLoaded) {
      final currentState = state as AdminDashboardLoaded;
      
      emit(AdminSyncing(currentState.dashboardData));
      
      final result = await _forceGlobalSync(NoParams());
      
      result.fold(
        (failure) => emit(AdminError(_mapFailureToMessage(failure))),
        (syncResult) => emit(AdminSyncCompleted(
          dashboardData: currentState.dashboardData,
          syncResult: syncResult,
        )),
      );
    }
  }

  Future<void> _onRefreshAdminData(
    RefreshAdminData event,
    Emitter<AdminState> emit,
  ) async {
    add(const LoadAdminDashboard());
  }

  Future<void> _onExportAdminReport(
    ExportAdminReport event,
    Emitter<AdminState> emit,
  ) async {
    if (state is AdminReportGenerated) {
      final currentState = state as AdminReportGenerated;
      
      emit(AdminExporting(currentState.dashboardData));
      
      // TODO: Implementar exportação
      await Future.delayed(const Duration(seconds: 2));
      
      emit(AdminExportCompleted(
        dashboardData: currentState.dashboardData,
        report: currentState.report,
        exportPath: '/tmp/admin_report.pdf',
      ));
    }
  }

  Future<void> _onUpdateAdminSettings(
    UpdateAdminSettings event,
    Emitter<AdminState> emit,
  ) async {
    if (state is AdminDashboardLoaded) {
      final currentState = state as AdminDashboardLoaded;
      
      emit(AdminUpdating(currentState.dashboardData));
      
      // TODO: Implementar atualização de configurações
      await Future.delayed(const Duration(seconds: 1));
      
      emit(AdminSettingsUpdated(
        dashboardData: currentState.dashboardData,
        settings: event.settings,
      ));
    }
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Erro no servidor: ${failure.message}';
    } else if (failure is NetworkFailure) {
      return 'Erro de conexão: ${failure.message}';
    } else if (failure is AuthFailure) {
      return 'Erro de autenticação: ${failure.message}';
    } else if (failure is PermissionFailure) {
      return 'Sem permissão: ${failure.message}';
    } else {
      return 'Erro desconhecido: ${failure.message}';
    }
  }
} 