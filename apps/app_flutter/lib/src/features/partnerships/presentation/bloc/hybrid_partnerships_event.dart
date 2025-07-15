import 'package:equatable/equatable.dart';

abstract class HybridPartnershipsEvent extends Equatable {
  const HybridPartnershipsEvent();

  @override
  List<Object?> get props => [];
}

class LoadHybridPartnerships extends HybridPartnershipsEvent {
  final bool refresh;
  
  const LoadHybridPartnerships({this.refresh = false});
  
  @override
  List<Object?> get props => [refresh];
}

class LoadMoreHybridPartnerships extends HybridPartnershipsEvent {
  const LoadMoreHybridPartnerships();
}

class FilterHybridPartnershipsByStatus extends HybridPartnershipsEvent {
  final String status;
  
  const FilterHybridPartnershipsByStatus(this.status);
  
  @override
  List<Object?> get props => [status];
}

class SearchHybridPartnerships extends HybridPartnershipsEvent {
  final String query;
  
  const SearchHybridPartnerships(this.query);
  
  @override
  List<Object?> get props => [query];
} 