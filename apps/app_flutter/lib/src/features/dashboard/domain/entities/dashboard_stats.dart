import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int activeCases;
  final int newLeads;
  final int alerts;
  
  // Contractor metrics
  final int activeClients;
  final int activePartnerships;
  final double monthlyRevenue;
  final int conversionRate;
  
  // Simple pipeline snapshot
  final int prospects;
  final int qualified;
  final int proposal;
  final int negotiation;
  final int closed;

  const DashboardStats({
    required this.activeCases,
    required this.newLeads,
    required this.alerts,
    this.activeClients = 0,
    this.activePartnerships = 0,
    this.monthlyRevenue = 0.0,
    this.conversionRate = 0,
    this.prospects = 0,
    this.qualified = 0,
    this.proposal = 0,
    this.negotiation = 0,
    this.closed = 0,
  });

  DashboardStats copyWith({
    int? activeCases,
    int? newLeads,
    int? alerts,
    int? activeClients,
    int? activePartnerships,
    double? monthlyRevenue,
    int? conversionRate,
    int? prospects,
    int? qualified,
    int? proposal,
    int? negotiation,
    int? closed,
  }) {
    return DashboardStats(
      activeCases: activeCases ?? this.activeCases,
      newLeads: newLeads ?? this.newLeads,
      alerts: alerts ?? this.alerts,
      activeClients: activeClients ?? this.activeClients,
      activePartnerships: activePartnerships ?? this.activePartnerships,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      conversionRate: conversionRate ?? this.conversionRate,
      prospects: prospects ?? this.prospects,
      qualified: qualified ?? this.qualified,
      proposal: proposal ?? this.proposal,
      negotiation: negotiation ?? this.negotiation,
      closed: closed ?? this.closed,
    );
  }

  @override
  List<Object?> get props => [
        activeCases,
        newLeads,
        alerts,
        activeClients,
        activePartnerships,
        monthlyRevenue,
        conversionRate,
        prospects,
        qualified,
        proposal,
        negotiation,
        closed,
      ];
}