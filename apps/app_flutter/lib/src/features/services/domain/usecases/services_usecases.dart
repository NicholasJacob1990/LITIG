import 'package:meu_app/src/core/utils/result.dart';
import '../entities/legal_service.dart';
import '../entities/service_booking.dart';
import '../repositories/services_repository.dart';

/// Use cases para o sistema de serviços
class ServicesUseCases {
  final ServicesRepository _repository;

  ServicesUseCases(this._repository);

  /// Busca todos os serviços disponíveis
  Future<Result<List<LegalService>>> getServices() {
    return _repository.getServices();
  }

  /// Busca serviços por categoria
  Future<Result<List<LegalService>>> getServicesByCategory(String category) {
    return _repository.getServicesByCategory(category);
  }

  /// Busca um serviço específico
  Future<Result<LegalService>> getServiceById(String id) {
    return _repository.getServiceById(id);
  }

  /// Busca serviços populares
  Future<Result<List<LegalService>>> getPopularServices() {
    return _repository.getPopularServices();
  }

  /// Busca serviços com desconto
  Future<Result<List<LegalService>>> getDiscountedServices() {
    return _repository.getDiscountedServices();
  }

  /// Busca serviços com filtros
  Future<Result<List<LegalService>>> searchServices({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
  }) {
    return _repository.searchServices(
      query: query,
      category: category,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minRating: minRating,
      sortBy: sortBy,
    );
  }

  /// Agenda um serviço
  Future<Result<ServiceBooking>> bookService({
    required String serviceId,
    required String clientId,
    required DateTime scheduledDate,
    String? notes,
    Map<String, dynamic>? requirements,
    List<String>? attachments,
  }) {
    return _repository.bookService(
      serviceId: serviceId,
      clientId: clientId,
      scheduledDate: scheduledDate,
      notes: notes,
      requirements: requirements,
      attachments: attachments,
    );
  }

  /// Busca reservas do cliente
  Future<Result<List<ServiceBooking>>> getClientBookings(String clientId) {
    return _repository.getClientBookings(clientId);
  }

  /// Busca uma reserva específica
  Future<Result<ServiceBooking>> getBookingById(String id) {
    return _repository.getBookingById(id);
  }

  /// Cancela uma reserva
  Future<Result<void>> cancelBooking(String bookingId, String reason) {
    return _repository.cancelBooking(bookingId, reason);
  }

  /// Avalia um serviço
  Future<Result<void>> rateService({
    required String serviceId,
    required String clientId,
    required double rating,
    String? comment,
  }) {
    return _repository.rateService(
      serviceId: serviceId,
      clientId: clientId,
      rating: rating,
      comment: comment,
    );
  }

  /// Busca categorias de serviços
  Future<Result<List<Map<String, dynamic>>>> getServiceCategories() {
    return _repository.getServiceCategories();
  }
}