import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/core/utils/app_logger.dart';
import '../../domain/usecases/services_usecases.dart';
import 'services_event.dart';
import 'services_state.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final ServicesUseCases _servicesUseCases;

  ServicesBloc({
    required ServicesUseCases servicesUseCases,
  }) : _servicesUseCases = servicesUseCases,
       super(ServicesInitial()) {
    on<LoadServices>(_onLoadServices);
    on<LoadServicesByCategory>(_onLoadServicesByCategory);
    on<LoadServiceById>(_onLoadServiceById);
    on<LoadPopularServices>(_onLoadPopularServices);
    on<LoadDiscountedServices>(_onLoadDiscountedServices);
    on<SearchServices>(_onSearchServices);
    on<BookService>(_onBookService);
    on<LoadClientBookings>(_onLoadClientBookings);
    on<LoadBookingById>(_onLoadBookingById);
    on<CancelBooking>(_onCancelBooking);
    on<RateService>(_onRateService);
    on<LoadServiceCategories>(_onLoadServiceCategories);
    on<RefreshServices>(_onRefreshServices);
  }

  Future<void> _onLoadServices(
    LoadServices event,
    Emitter<ServicesState> emit,
  ) async {
    try {
      emit(ServicesLoading());
      AppLogger.info('Loading services...');
      
      final result = await _servicesUseCases.getServices();
      
      if (result.isSuccess) {
        AppLogger.info('Services loaded successfully: ${result.value.length} services');
        emit(ServicesLoaded(result.value));
      } else {
        AppLogger.error('Failed to load services: ${result.failure.message}');
        emit(ServicesError(result.failure.message));
      }
    } catch (e) {
      AppLogger.error('Exception loading services', {'error': e.toString()});
      emit(const ServicesError('Erro inesperado ao carregar serviços'));
    }
  }

  Future<void> _onLoadServicesByCategory(
    LoadServicesByCategory event,
    Emitter<ServicesState> emit,
  ) async {
    try {
      emit(ServicesLoading());
      AppLogger.info('Loading services by category: ${event.category}');
      
      final result = await _servicesUseCases.getServicesByCategory(event.category);
      
      if (result.isSuccess) {
        AppLogger.info('Services loaded by category: ${result.value.length} services');
        emit(ServicesLoaded(result.value));
      } else {
        AppLogger.error('Failed to load services by category: ${result.failure.message}');
        emit(ServicesError(result.failure.message));
      }
    } catch (e) {
      AppLogger.error('Exception loading services by category', {'error': e.toString()});
      emit(const ServicesError('Erro inesperado ao carregar serviços por categoria'));
    }
  }

  Future<void> _onLoadServiceById(
    LoadServiceById event,
    Emitter<ServicesState> emit,
  ) async {
    try {
      emit(ServicesLoading());
      AppLogger.info('Loading service by ID: ${event.id}');
      
      final result = await _servicesUseCases.getServiceById(event.id);
      
      if (result.isSuccess) {
        AppLogger.info('Service loaded successfully: ${result.value.name}');
        emit(ServiceDetailLoaded(result.value));
      } else {
        AppLogger.error('Failed to load service by ID: ${result.failure.message}');
        emit(ServicesError(result.failure.message));
      }
    } catch (e) {
      AppLogger.error('Exception loading service by ID', {'error': e.toString()});
      emit(const ServicesError('Erro inesperado ao carregar serviço'));
    }
  }

  Future<void> _onLoadPopularServices(
    LoadPopularServices event,
    Emitter<ServicesState> emit,
  ) async {
    try {
      emit(ServicesLoading());
      AppLogger.info('Loading popular services...');
      
      final result = await _servicesUseCases.getPopularServices();
      
      if (result.isSuccess) {
        AppLogger.info('Popular services loaded: ${result.value.length} services');
        emit(ServicesLoaded(result.value));
      } else {
        AppLogger.error('Failed to load popular services: ${result.failure.message}');
        emit(ServicesError(result.failure.message));
      }
    } catch (e) {
      AppLogger.error('Exception loading popular services', {'error': e.toString()});
      emit(const ServicesError('Erro inesperado ao carregar serviços populares'));
    }
  }

  Future<void> _onLoadDiscountedServices(
    LoadDiscountedServices event,
    Emitter<ServicesState> emit,
  ) async {
    try {
      emit(ServicesLoading());
      AppLogger.info('Loading discounted services...');
      
      final result = await _servicesUseCases.getDiscountedServices();
      
      if (result.isSuccess) {
        AppLogger.info('Discounted services loaded: ${result.value.length} services');
        emit(ServicesLoaded(result.value));
      } else {
        AppLogger.error('Failed to load discounted services: ${result.failure.message}');
        emit(ServicesError(result.failure.message));
      }
    } catch (e) {
      AppLogger.error('Exception loading discounted services', {'error': e.toString()});
      emit(const ServicesError('Erro inesperado ao carregar serviços com desconto'));
    }
  }

  Future<void> _onSearchServices(
    SearchServices event,
    Emitter<ServicesState> emit,
  ) async {
    try {
      emit(ServicesLoading());
      AppLogger.info('Searching services with query: ${event.query}');
      
      final result = await _servicesUseCases.searchServices(
        query: event.query,
        category: event.category,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        minRating: event.minRating,
        sortBy: event.sortBy,
      );
      
      if (result.isSuccess) {
        AppLogger.info('Search completed: ${result.value.length} services found');
        emit(ServicesLoaded(result.value));
      } else {
        AppLogger.error('Failed to search services: ${result.failure.message}');
        emit(ServicesError(result.failure.message));
      }
    } catch (e) {
      AppLogger.error('Exception searching services', {'error': e.toString()});
      emit(const ServicesError('Erro inesperado ao pesquisar serviços'));
    }
  }

  Future<void> _onBookService(
    BookService event,
    Emitter<ServicesState> emit,
  ) async {
    try {
      emit(ServicesLoading());
      AppLogger.info('Booking service: ${event.serviceId} for client: ${event.clientId}');
      
      final result = await _servicesUseCases.bookService(
        serviceId: event.serviceId,
        clientId: event.clientId,
        scheduledDate: event.scheduledDate,
        notes: event.notes,
        requirements: event.requirements,
        attachments: event.attachments,
      );
      
      if (result.isSuccess) {
        AppLogger.info('Service booked successfully: ${result.value.id}');
        emit(ServiceBookingSuccess(result.value));
      } else {
        AppLogger.error('Failed to book service: ${result.failure.message}');
        emit(ServicesError(result.failure.message));
      }
    } catch (e) {
      AppLogger.error('Exception booking service', {'error': e.toString()});
      emit(const ServicesError('Erro inesperado ao agendar serviço'));
    }
  }

  Future<void> _onLoadClientBookings(
    LoadClientBookings event,
    Emitter<ServicesState> emit,
  ) async {
    try {
      emit(ServicesLoading());
      AppLogger.info('Loading client bookings for: ${event.clientId}');
      
      final result = await _servicesUseCases.getClientBookings(event.clientId);
      
      if (result.isSuccess) {
        AppLogger.info('Client bookings loaded: ${result.value.length} bookings');
        emit(ClientBookingsLoaded(result.value));
      } else {
        AppLogger.error('Failed to load client bookings: ${result.failure.message}');
        emit(ServicesError(result.failure.message));
      }
    } catch (e) {
      AppLogger.error('Exception loading client bookings', {'error': e.toString()});
      emit(const ServicesError('Erro inesperado ao carregar agendamentos'));
    }
  }

  Future<void> _onLoadBookingById(
    LoadBookingById event,
    Emitter<ServicesState> emit,
  ) async {
    try {
      emit(ServicesLoading());
      AppLogger.info('Loading booking by ID: ${event.id}');
      
      final result = await _servicesUseCases.getBookingById(event.id);
      
      if (result.isSuccess) {
        AppLogger.info('Booking loaded successfully');
        emit(BookingDetailLoaded(result.value));
      } else {
        AppLogger.error('Failed to load booking: ${result.failure.message}');
        emit(ServicesError(result.failure.message));
      }
    } catch (e) {
      AppLogger.error('Exception loading booking', {'error': e.toString()});
      emit(const ServicesError('Erro inesperado ao carregar agendamento'));
    }
  }

  Future<void> _onCancelBooking(
    CancelBooking event,
    Emitter<ServicesState> emit,
  ) async {
    try {
      emit(ServicesLoading());
      AppLogger.info('Cancelling booking: ${event.bookingId}');
      
      final result = await _servicesUseCases.cancelBooking(event.bookingId, event.reason);
      
      if (result.isSuccess) {
        AppLogger.info('Booking cancelled successfully');
        emit(const ActionSuccess('Agendamento cancelado com sucesso'));
      } else {
        AppLogger.error('Failed to cancel booking: ${result.failure.message}');
        emit(ServicesError(result.failure.message));
      }
    } catch (e) {
      AppLogger.error('Exception cancelling booking', {'error': e.toString()});
      emit(const ServicesError('Erro inesperado ao cancelar agendamento'));
    }
  }

  Future<void> _onRateService(
    RateService event,
    Emitter<ServicesState> emit,
  ) async {
    try {
      emit(ServicesLoading());
      AppLogger.info('Rating service: ${event.serviceId}');
      
      final result = await _servicesUseCases.rateService(
        serviceId: event.serviceId,
        clientId: event.clientId,
        rating: event.rating,
        comment: event.comment,
      );
      
      if (result.isSuccess) {
        AppLogger.info('Service rated successfully');
        emit(const ActionSuccess('Serviço avaliado com sucesso'));
      } else {
        AppLogger.error('Failed to rate service: ${result.failure.message}');
        emit(ServicesError(result.failure.message));
      }
    } catch (e) {
      AppLogger.error('Exception rating service', {'error': e.toString()});
      emit(const ServicesError('Erro inesperado ao avaliar serviço'));
    }
  }

  Future<void> _onLoadServiceCategories(
    LoadServiceCategories event,
    Emitter<ServicesState> emit,
  ) async {
    try {
      emit(ServicesLoading());
      AppLogger.info('Loading service categories...');
      
      final result = await _servicesUseCases.getServiceCategories();
      
      if (result.isSuccess) {
        AppLogger.info('Service categories loaded: ${result.value.length} categories');
        emit(ServiceCategoriesLoaded(result.value));
      } else {
        AppLogger.error('Failed to load service categories: ${result.failure.message}');
        emit(ServicesError(result.failure.message));
      }
    } catch (e) {
      AppLogger.error('Exception loading service categories', {'error': e.toString()});
      emit(const ServicesError('Erro inesperado ao carregar categorias'));
    }
  }

  Future<void> _onRefreshServices(
    RefreshServices event,
    Emitter<ServicesState> emit,
  ) async {
    // Simply reload all services
    add(LoadServices());
  }
}