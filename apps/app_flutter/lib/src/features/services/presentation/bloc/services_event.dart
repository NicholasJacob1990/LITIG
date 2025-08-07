import 'package:equatable/equatable.dart';

abstract class ServicesEvent extends Equatable {
  const ServicesEvent();

  @override
  List<Object?> get props => [];
}

class LoadServices extends ServicesEvent {}

class LoadServicesByCategory extends ServicesEvent {
  final String category;

  const LoadServicesByCategory({required this.category});

  @override
  List<Object> get props => [category];
}

class LoadServiceById extends ServicesEvent {
  final String id;

  const LoadServiceById({required this.id});

  @override
  List<Object> get props => [id];
}

class LoadPopularServices extends ServicesEvent {}

class LoadDiscountedServices extends ServicesEvent {}

class SearchServices extends ServicesEvent {
  final String? query;
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final String? sortBy;

  const SearchServices({
    this.query,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.sortBy,
  });

  @override
  List<Object?> get props => [query, category, minPrice, maxPrice, minRating, sortBy];
}

class BookService extends ServicesEvent {
  final String serviceId;
  final String clientId;
  final DateTime scheduledDate;
  final String? notes;
  final Map<String, dynamic>? requirements;
  final List<String>? attachments;

  const BookService({
    required this.serviceId,
    required this.clientId,
    required this.scheduledDate,
    this.notes,
    this.requirements,
    this.attachments,
  });

  @override
  List<Object?> get props => [serviceId, clientId, scheduledDate, notes, requirements, attachments];
}

class LoadClientBookings extends ServicesEvent {
  final String clientId;

  const LoadClientBookings({required this.clientId});

  @override
  List<Object> get props => [clientId];
}

class LoadBookingById extends ServicesEvent {
  final String id;

  const LoadBookingById({required this.id});

  @override
  List<Object> get props => [id];
}

class CancelBooking extends ServicesEvent {
  final String bookingId;
  final String reason;

  const CancelBooking({required this.bookingId, required this.reason});

  @override
  List<Object> get props => [bookingId, reason];
}

class RateService extends ServicesEvent {
  final String serviceId;
  final String clientId;
  final double rating;
  final String? comment;

  const RateService({
    required this.serviceId,
    required this.clientId,
    required this.rating,
    this.comment,
  });

  @override
  List<Object?> get props => [serviceId, clientId, rating, comment];
}

class LoadServiceCategories extends ServicesEvent {}

class RefreshServices extends ServicesEvent {}