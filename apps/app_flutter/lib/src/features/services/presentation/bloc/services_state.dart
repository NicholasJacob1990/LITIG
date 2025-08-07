import 'package:equatable/equatable.dart';
import '../../domain/entities/legal_service.dart';
import '../../domain/entities/service_booking.dart';

abstract class ServicesState extends Equatable {
  const ServicesState();

  @override
  List<Object?> get props => [];
}

class ServicesInitial extends ServicesState {}

class ServicesLoading extends ServicesState {}

class ServicesLoaded extends ServicesState {
  final List<LegalService> services;

  const ServicesLoaded(this.services);

  @override
  List<Object> get props => [services];
}

class ServiceDetailLoaded extends ServicesState {
  final LegalService service;

  const ServiceDetailLoaded(this.service);

  @override
  List<Object> get props => [service];
}

class ServiceBookingSuccess extends ServicesState {
  final ServiceBooking booking;

  const ServiceBookingSuccess(this.booking);

  @override
  List<Object> get props => [booking];
}

class ClientBookingsLoaded extends ServicesState {
  final List<ServiceBooking> bookings;

  const ClientBookingsLoaded(this.bookings);

  @override
  List<Object> get props => [bookings];
}

class BookingDetailLoaded extends ServicesState {
  final ServiceBooking booking;

  const BookingDetailLoaded(this.booking);

  @override
  List<Object> get props => [booking];
}

class ServiceCategoriesLoaded extends ServicesState {
  final List<Map<String, dynamic>> categories;

  const ServiceCategoriesLoaded(this.categories);

  @override
  List<Object> get props => [categories];
}

class ServicesError extends ServicesState {
  final String message;

  const ServicesError(this.message);

  @override
  List<Object> get props => [message];
}

class ActionSuccess extends ServicesState {
  final String message;

  const ActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}