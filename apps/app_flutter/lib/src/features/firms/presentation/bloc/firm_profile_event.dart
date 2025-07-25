import 'package:equatable/equatable.dart';

abstract class FirmProfileEvent extends Equatable {
  const FirmProfileEvent();

  @override
  List<Object> get props => [];
}

class LoadFirmProfile extends FirmProfileEvent {
  final String firmId;

  const LoadFirmProfile(this.firmId);

  @override
  List<Object> get props => [firmId];
}

class RefreshFirmProfile extends FirmProfileEvent {
  final String firmId;

  const RefreshFirmProfile(this.firmId);

  @override
  List<Object> get props => [firmId];
} 