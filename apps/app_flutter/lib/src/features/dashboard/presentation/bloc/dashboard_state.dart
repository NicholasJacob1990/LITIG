part of 'dashboard_bloc.dart';

abstract class DashboardState {
  const DashboardState();
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  const DashboardLoaded(this.stats);
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
} 