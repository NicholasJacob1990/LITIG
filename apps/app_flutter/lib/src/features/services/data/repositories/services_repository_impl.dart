import 'package:meu_app/src/core/utils/result.dart';
import '../../domain/entities/legal_service.dart';
import '../../domain/entities/service_booking.dart';
import '../../domain/repositories/services_repository.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  
  @override
  Future<Result<List<LegalService>>> getServices() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return Result.success(_getMockServices());
    } catch (e) {
      return Result.genericFailure('Erro ao buscar serviços', 'GET_SERVICES_ERROR');
    }
  }

  @override
  Future<Result<List<LegalService>>> getServicesByCategory(String category) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final services = _getMockServices()
          .where((service) => service.category.toLowerCase() == category.toLowerCase())
          .toList();
      return Result.success(services);
    } catch (e) {
      return Result.genericFailure('Erro ao buscar serviços por categoria', 'GET_SERVICES_BY_CATEGORY_ERROR');
    }
  }

  @override
  Future<Result<LegalService>> getServiceById(String id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final service = _getMockServices().where((s) => s.id == id).firstOrNull;
      if (service == null) {
        return Result.notFoundFailure('Serviço não encontrado', 'SERVICE_NOT_FOUND');
      }
      return Result.success(service);
    } catch (e) {
      return Result.genericFailure('Erro ao buscar serviço', 'GET_SERVICE_BY_ID_ERROR');
    }
  }

  @override
  Future<Result<List<LegalService>>> getPopularServices() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final services = _getMockServices()
          .where((service) => service.isPopular)
          .toList();
      return Result.success(services);
    } catch (e) {
      return Result.genericFailure('Erro ao buscar serviços populares', 'GET_POPULAR_SERVICES_ERROR');
    }
  }

  @override
  Future<Result<List<LegalService>>> getDiscountedServices() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final services = _getMockServices()
          .where((service) => service.hasDiscount)
          .toList();
      return Result.success(services);
    } catch (e) {
      return Result.genericFailure('Erro ao buscar serviços com desconto', 'GET_DISCOUNTED_SERVICES_ERROR');
    }
  }

  @override
  Future<Result<List<LegalService>>> getServicesByProvider(String providerId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final services = _getMockServices()
          .where((service) => service.providerId == providerId)
          .toList();
      return Result.success(services);
    } catch (e) {
      return Result.genericFailure('Erro ao buscar serviços do provedor', 'GET_SERVICES_BY_PROVIDER_ERROR');
    }
  }

  @override
  Future<Result<List<LegalService>>> searchServices({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      var services = _getMockServices();

      // Filtrar por query
      if (query != null && query.isNotEmpty) {
        services = services.where((service) =>
          service.name.toLowerCase().contains(query.toLowerCase()) ||
          service.description.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }

      // Filtrar por categoria
      if (category != null && category.isNotEmpty) {
        services = services.where((service) =>
          service.category.toLowerCase() == category.toLowerCase()
        ).toList();
      }

      // Filtrar por preço mínimo
      if (minPrice != null) {
        services = services.where((service) => service.finalPrice >= minPrice).toList();
      }

      // Filtrar por preço máximo
      if (maxPrice != null) {
        services = services.where((service) => service.finalPrice <= maxPrice).toList();
      }

      // Filtrar por rating mínimo
      if (minRating != null) {
        services = services.where((service) => service.rating >= minRating).toList();
      }

      // Ordenar
      if (sortBy != null) {
        switch (sortBy) {
          case 'price_asc':
            services.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
            break;
          case 'price_desc':
            services.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
            break;
          case 'rating':
            services.sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case 'popular':
            services.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
            break;
        }
      }

      return Result.success(services);
    } catch (e) {
      return Result.genericFailure('Erro ao pesquisar serviços', 'SEARCH_SERVICES_ERROR');
    }
  }

  @override
  Future<Result<ServiceBooking>> bookService({
    required String serviceId,
    required String clientId,
    required DateTime scheduledDate,
    String? notes,
    Map<String, dynamic>? requirements,
    List<String>? attachments,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final booking = ServiceBooking(
        id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
        serviceId: serviceId,
        clientId: clientId,
        providerId: 'provider_001',
        status: BookingStatus.pending,
        agreedPrice: 299.90,
        scheduledDate: scheduledDate,
        notes: notes,
        requirements: requirements ?? {},
        attachments: attachments ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return Result.success(booking);
    } catch (e) {
      return Result.genericFailure('Erro ao agendar serviço', 'BOOK_SERVICE_ERROR');
    }
  }

  @override
  Future<Result<List<ServiceBooking>>> getClientBookings(String clientId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return Result.success(_getMockBookings());
    } catch (e) {
      return Result.genericFailure('Erro ao buscar agendamentos', 'GET_CLIENT_BOOKINGS_ERROR');
    }
  }

  @override
  Future<Result<List<ServiceBooking>>> getProviderBookings(String providerId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return Result.success(_getMockBookings());
    } catch (e) {
      return Result.genericFailure('Erro ao buscar agendamentos do provedor', 'GET_PROVIDER_BOOKINGS_ERROR');
    }
  }

  @override
  Future<Result<ServiceBooking>> getBookingById(String id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final booking = _getMockBookings().where((b) => b.id == id).firstOrNull;
      if (booking == null) {
        return Result.notFoundFailure('Agendamento não encontrado', 'BOOKING_NOT_FOUND');
      }
      return Result.success(booking);
    } catch (e) {
      return Result.genericFailure('Erro ao buscar agendamento', 'GET_BOOKING_BY_ID_ERROR');
    }
  }

  @override
  Future<Result<ServiceBooking>> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final booking = _getMockBookings().where((b) => b.id == bookingId).firstOrNull;
      if (booking == null) {
        return Result.notFoundFailure('Agendamento não encontrado', 'BOOKING_NOT_FOUND');
      }
      final updatedBooking = booking.copyWith(status: status, updatedAt: DateTime.now());
      return Result.success(updatedBooking);
    } catch (e) {
      return Result.genericFailure('Erro ao atualizar status', 'UPDATE_BOOKING_STATUS_ERROR');
    }
  }

  @override
  Future<Result<void>> cancelBooking(String bookingId, String reason) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return Result.success(null);
    } catch (e) {
      return Result.genericFailure('Erro ao cancelar agendamento', 'CANCEL_BOOKING_ERROR');
    }
  }

  @override
  Future<Result<ServiceBooking>> confirmBooking(String bookingId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return updateBookingStatus(bookingId, BookingStatus.confirmed);
    } catch (e) {
      return Result.genericFailure('Erro ao confirmar agendamento', 'CONFIRM_BOOKING_ERROR');
    }
  }

  @override
  Future<Result<ServiceBooking>> completeBooking(String bookingId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return updateBookingStatus(bookingId, BookingStatus.completed);
    } catch (e) {
      return Result.genericFailure('Erro ao completar agendamento', 'COMPLETE_BOOKING_ERROR');
    }
  }

  @override
  Future<Result<void>> rateService({
    required String serviceId,
    required String clientId,
    required double rating,
    String? comment,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return Result.success(null);
    } catch (e) {
      return Result.genericFailure('Erro ao avaliar serviço', 'RATE_SERVICE_ERROR');
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getServiceReviews(String serviceId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      return Result.success(_getMockReviews());
    } catch (e) {
      return Result.genericFailure('Erro ao buscar avaliações', 'GET_SERVICE_REVIEWS_ERROR');
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getServiceStats(String serviceId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      return Result.success({
        'total_bookings': 156,
        'completed_bookings': 142,
        'average_rating': 4.7,
        'total_reviews': 89,
        'completion_rate': 0.91,
      });
    } catch (e) {
      return Result.genericFailure('Erro ao buscar estatísticas', 'GET_SERVICE_STATS_ERROR');
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getServiceCategories() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      return Result.success([
        {'category': 'civil', 'name': 'Direito Civil', 'count': 23, 'icon': 'gavel'},
        {'category': 'criminal', 'name': 'Direito Criminal', 'count': 18, 'icon': 'shield'},
        {'category': 'labor', 'name': 'Direito Trabalhista', 'count': 31, 'icon': 'briefcase'},
        {'category': 'corporate', 'name': 'Direito Empresarial', 'count': 15, 'icon': 'building'},
        {'category': 'family', 'name': 'Direito de Família', 'count': 27, 'icon': 'users'},
        {'category': 'tax', 'name': 'Direito Tributário', 'count': 12, 'icon': 'calculator'},
      ]);
    } catch (e) {
      return Result.genericFailure('Erro ao buscar categorias', 'GET_SERVICE_CATEGORIES_ERROR');
    }
  }

  // Dados mock
  List<LegalService> _getMockServices() {
    final now = DateTime.now();
    return [
      LegalService(
        id: 'service_001',
        name: 'Consultoria Jurídica Empresarial',
        description: 'Consultoria completa para estruturação e regularização de empresas',
        category: 'corporate',
        basePrice: 499.90,
        discountPrice: 399.90,
        duration: '2-3 dias úteis',
        expertise: 'Direito Empresarial',
        requirements: ['CNPJ da empresa', 'Contrato social', 'Últimas alterações'],
        deliverables: ['Parecer jurídico', 'Plano de ação', 'Documentação revisada'],
        isActive: true,
        isPopular: true,
        rating: 4.8,
        reviewCount: 127,
        providerId: 'provider_001',
        providerName: 'Dr. João Silva',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      LegalService(
        id: 'service_002',
        name: 'Revisão de Contrato de Trabalho',
        description: 'Análise detalhada de contratos trabalhistas e adequações à legislação vigente',
        category: 'labor',
        basePrice: 249.90,
        duration: '1-2 dias úteis',
        expertise: 'Direito Trabalhista',
        requirements: ['Contrato atual', 'Histórico de alterações'],
        deliverables: ['Contrato revisado', 'Lista de adequações', 'Orientações legais'],
        isActive: true,
        isPopular: false,
        rating: 4.6,
        reviewCount: 89,
        providerId: 'provider_002',
        providerName: 'Dra. Maria Santos',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      LegalService(
        id: 'service_003',
        name: 'Planejamento Sucessório',
        description: 'Elaboração de plano sucessório para proteção patrimonial familiar',
        category: 'family',
        basePrice: 899.90,
        discountPrice: 699.90,
        duration: '5-7 dias úteis',
        expertise: 'Direito de Família e Sucessões',
        requirements: ['Documentos pessoais', 'Inventário de bens', 'Certidões'],
        deliverables: ['Plano sucessório', 'Documentos legais', 'Orientação fiscal'],
        isActive: true,
        isPopular: true,
        rating: 4.9,
        reviewCount: 156,
        providerId: 'provider_003',
        providerName: 'Dr. Carlos Oliveira',
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      LegalService(
        id: 'service_004',
        name: 'Defesa em Processo Criminal',
        description: 'Representação legal completa em processos criminais',
        category: 'criminal',
        basePrice: 1299.90,
        duration: 'Conforme andamento processual',
        expertise: 'Direito Criminal',
        requirements: ['Documentos do processo', 'Histórico dos fatos'],
        deliverables: ['Peças processuais', 'Acompanhamento integral', 'Recurso se necessário'],
        isActive: true,
        isPopular: false,
        rating: 4.7,
        reviewCount: 73,
        providerId: 'provider_004',
        providerName: 'Dra. Ana Costa',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  List<ServiceBooking> _getMockBookings() {
    final now = DateTime.now();
    return [
      ServiceBooking(
        id: 'booking_001',
        serviceId: 'service_001',
        clientId: 'client_001',
        providerId: 'provider_001',
        status: BookingStatus.confirmed,
        agreedPrice: 399.90,
        scheduledDate: now.add(const Duration(days: 3)),
        notes: 'Preciso de consultoria urgente para abertura de filial',
        requirements: {'urgency': 'high', 'documents_ready': true},
        attachments: [],
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
      ServiceBooking(
        id: 'booking_002',
        serviceId: 'service_002',
        clientId: 'client_001',
        providerId: 'provider_002',
        status: BookingStatus.completed,
        agreedPrice: 249.90,
        scheduledDate: now.subtract(const Duration(days: 5)),
        notes: null,
        requirements: {},
        attachments: ['contract.pdf'],
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 5)),
        completedAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  List<Map<String, dynamic>> _getMockReviews() {
    return [
      {
        'id': 'review_001',
        'client_name': 'João Silva',
        'rating': 5.0,
        'comment': 'Excelente atendimento, muito profissional e eficiente.',
        'date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'id': 'review_002',
        'client_name': 'Maria Santos',
        'rating': 4.5,
        'comment': 'Bom serviço, dentro do prazo e com qualidade.',
        'date': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
      },
      {
        'id': 'review_003',
        'client_name': 'Carlos Costa',
        'rating': 5.0,
        'comment': 'Superou minhas expectativas. Recomendo!',
        'date': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      },
    ];
  }
}