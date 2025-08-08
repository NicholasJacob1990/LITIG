part of 'dashboard_bloc.dart';

abstract class DashboardEvent {
  const DashboardEvent();
}

class FetchLawyerStats extends DashboardEvent {} 

class FetchContractorStats extends DashboardEvent {}

class FetchClientStats extends DashboardEvent {}