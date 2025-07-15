import 'package:equatable/equatable.dart';

abstract class PartnershipsEvent extends Equatable {
  const PartnershipsEvent();

  @override
  List<Object> get props => [];
}

class FetchPartnerships extends PartnershipsEvent {} 