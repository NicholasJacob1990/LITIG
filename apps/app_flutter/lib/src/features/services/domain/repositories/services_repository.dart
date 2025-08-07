import 'package:meu_app/src/core/utils/result.dart';
import '../entities/legal_service.dart';
import '../entities/service_booking.dart';

abstract class ServicesRepository {
  /// Busca todos os serviços disponíveis
  Future<Result<List<LegalService>>> getServices();

  /// Busca serviços por categoria
  Future<Result<List<LegalService>>> getServicesByCategory(String category);

  /// Busca um serviço específico por ID
  Future<Result<LegalService>> getServiceById(String id);

  /// Busca serviços populares
  Future<Result<List<LegalService>>> getPopularServices();

  /// Busca serviços com desconto
  Future<Result<List<LegalService>>> getDiscountedServices();

  /// Busca serviços de um provedor específico
  Future<Result<List<LegalService>>> getServicesByProvider(String providerId);

  /// Busca serviços com filtros
  Future<Result<List<LegalService>>> searchServices({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
  });

  /// Cria uma nova reserva de serviço
  Future<Result<ServiceBooking>> bookService({
    required String serviceId,
    required String clientId,
    required DateTime scheduledDate,
    String? notes,
    Map<String, dynamic>? requirements,
    List<String>? attachments,
  });

  /// Busca reservas do cliente
  Future<Result<List<ServiceBooking>>> getClientBookings(String clientId);

  /// Busca reservas do provedor
  Future<Result<List<ServiceBooking>>> getProviderBookings(String providerId);

  /// Busca uma reserva específica
  Future<Result<ServiceBooking>> getBookingById(String id);

  /// Atualiza o status de uma reserva
  Future<Result<ServiceBooking>> updateBookingStatus(
    String bookingId, 
    BookingStatus status,
  );

  /// Cancela uma reserva
  Future<Result<void>> cancelBooking(String bookingId, String reason);

  /// Confirma uma reserva (provedor)
  Future<Result<ServiceBooking>> confirmBooking(String bookingId);

  /// Completa uma reserva
  Future<Result<ServiceBooking>> completeBooking(String bookingId);

  /// Avalia um serviço
  Future<Result<void>> rateService({
    required String serviceId,
    required String clientId,
    required double rating,
    String? comment,
  });

  /// Busca avaliações de um serviço
  Future<Result<List<Map<String, dynamic>>>> getServiceReviews(String serviceId);

  /// Busca estatísticas de um serviço
  Future<Result<Map<String, dynamic>>> getServiceStats(String serviceId);

  /// Busca categorias de serviços com contadores
  Future<Result<List<Map<String, dynamic>>>> getServiceCategories();
}