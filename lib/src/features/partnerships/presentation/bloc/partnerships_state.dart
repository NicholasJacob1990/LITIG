import '../../domain/entities/partnership.dart';

abstract class PartnershipsState {
  const PartnershipsState();
}

class PartnershipsInitial extends PartnershipsState {
  const PartnershipsInitial();
}

class PartnershipsLoading extends PartnershipsState {
  const PartnershipsLoading();
}

class PartnershipsLoaded extends PartnershipsState {
  final List<Partnership> sent;
  final List<Partnership> received;
  
  const PartnershipsLoaded({
    required this.sent,
    required this.received,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PartnershipsLoaded &&
        other.sent == sent &&
        other.received == received;
  }

  @override
  int get hashCode => sent.hashCode ^ received.hashCode;
}

class PartnershipsError extends PartnershipsState {
  final String message;
  
  const PartnershipsError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PartnershipsError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
} 