import 'package:equatable/equatable.dart';

/// Representa uma reserva/agendamento de serviço
class ServiceBooking extends Equatable {
  final String id;
  final String serviceId;
  final String clientId;
  final String providerId;
  final BookingStatus status;
  final double agreedPrice;
  final DateTime scheduledDate;
  final String? notes;
  final Map<String, dynamic> requirements;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  const ServiceBooking({
    required this.id,
    required this.serviceId,
    required this.clientId,
    required this.providerId,
    required this.status,
    required this.agreedPrice,
    required this.scheduledDate,
    this.notes,
    required this.requirements,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  /// Verifica se a reserva pode ser cancelada
  bool get canCancel {
    return status == BookingStatus.pending || 
           status == BookingStatus.confirmed;
  }

  /// Verifica se a reserva está ativa
  bool get isActive {
    return status != BookingStatus.cancelled && 
           status != BookingStatus.completed;
  }

  /// Copia a reserva com novos parâmetros
  ServiceBooking copyWith({
    String? id,
    String? serviceId,
    String? clientId,
    String? providerId,
    BookingStatus? status,
    double? agreedPrice,
    DateTime? scheduledDate,
    String? notes,
    Map<String, dynamic>? requirements,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    return ServiceBooking(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      clientId: clientId ?? this.clientId,
      providerId: providerId ?? this.providerId,
      status: status ?? this.status,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      notes: notes ?? this.notes,
      requirements: requirements ?? this.requirements,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  @override
  List<Object?> get props => [
    id,
    serviceId,
    clientId,
    providerId,
    status,
    agreedPrice,
    scheduledDate,
    notes,
    requirements,
    attachments,
    createdAt,
    updatedAt,
    completedAt,
    cancelledAt,
    cancellationReason,
  ];
}

/// Status da reserva de serviço
enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  paymentPending,
}