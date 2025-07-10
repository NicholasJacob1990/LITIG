import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int activeCases;
  final int newLeads;
  final int alerts;

  const DashboardStats({
    required this.activeCases,
    required this.newLeads,
    required this.alerts,
  });

  @override
  List<Object?> get props => [activeCases, newLeads, alerts];
} 