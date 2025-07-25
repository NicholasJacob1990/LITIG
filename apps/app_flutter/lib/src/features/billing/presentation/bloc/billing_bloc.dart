import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/billing/domain/usecases/billing_usecases.dart';
import 'package:meu_app/src/features/billing/domain/entities/billing_record.dart';
import 'package:meu_app/src/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:meu_app/src/core/services/analytics_service.dart';

// Events
abstract class BillingEvent extends Equatable {
  const BillingEvent();

  @override
  List<Object?> get props => [];
}

class LoadAvailablePlans extends BillingEvent {
  final String entityType;

  const LoadAvailablePlans(this.entityType);

  @override
  List<Object?> get props => [entityType];
}

class LoadCurrentPlan extends BillingEvent {
  final String entityType;
  final String entityId;

  const LoadCurrentPlan(this.entityType, this.entityId);

  @override
  List<Object?> get props => [entityType, entityId];
}

class CreateCheckoutSession extends BillingEvent {
  final String targetPlan;
  final String entityType;
  final String entityId;
  final String successUrl;
  final String cancelUrl;

  const CreateCheckoutSession({
    required this.targetPlan,
    required this.entityType,
    required this.entityId,
    required this.successUrl,
    required this.cancelUrl,
  });

  @override
  List<Object?> get props => [targetPlan, entityType, entityId, successUrl, cancelUrl];
}

class LoadBillingHistory extends BillingEvent {
  final String entityType;
  final String entityId;

  const LoadBillingHistory(this.entityType, this.entityId);

  @override
  List<Object?> get props => [entityType, entityId];
}

class RefreshBillingData extends BillingEvent {
  final String entityType;
  final String entityId;

  const RefreshBillingData(this.entityType, this.entityId);

  @override
  List<Object?> get props => [entityType, entityId];
}

// States
abstract class BillingState extends Equatable {
  const BillingState();

  @override
  List<Object?> get props => [];
}

class BillingInitial extends BillingState {}

class BillingLoading extends BillingState {}

class PlansLoaded extends BillingState {
  final List<Map<String, dynamic>> availablePlans;
  final Map<String, dynamic>? currentPlan;

  const PlansLoaded({
    required this.availablePlans,
    this.currentPlan,
  });

  @override
  List<Object?> get props => [availablePlans, currentPlan];

  PlansLoaded copyWith({
    List<Map<String, dynamic>>? availablePlans,
    Map<String, dynamic>? currentPlan,
  }) {
    return PlansLoaded(
      availablePlans: availablePlans ?? this.availablePlans,
      currentPlan: currentPlan ?? this.currentPlan,
    );
  }
}

class CheckoutSessionCreated extends BillingState {
  final String checkoutUrl;
  final String sessionId;

  const CheckoutSessionCreated({
    required this.checkoutUrl,
    required this.sessionId,
  });

  @override
  List<Object?> get props => [checkoutUrl, sessionId];
}

class BillingHistoryLoaded extends BillingState {
  final List<BillingRecord> billingRecords;
  final List<Map<String, dynamic>> planHistory;

  const BillingHistoryLoaded({
    required this.billingRecords,
    required this.planHistory,
  });

  @override
  List<Object?> get props => [billingRecords, planHistory];
}

class PlanUpgraded extends BillingState {
  final String newPlan;

  const PlanUpgraded(this.newPlan);

  @override
  List<Object?> get props => [newPlan];
}

class BillingError extends BillingState {
  final String message;

  const BillingError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final BillingUseCases? _billingUseCases;
  final BillingRemoteDataSource? _dataSource;

  BillingBloc({
    BillingUseCases? billingUseCases,
    BillingRemoteDataSource? dataSource,
  })  : _billingUseCases = billingUseCases,
        _dataSource = dataSource,
        super(BillingInitial()) {
    on<LoadAvailablePlans>(_onLoadAvailablePlans);
    on<LoadCurrentPlan>(_onLoadCurrentPlan);
    on<CreateCheckoutSession>(_onCreateCheckoutSession);
    on<LoadBillingHistory>(_onLoadBillingHistory);
    on<RefreshBillingData>(_onRefreshBillingData);
  }

  Future<void> _onLoadAvailablePlans(
    LoadAvailablePlans event,
    Emitter<BillingState> emit,
  ) async {
    try {
      emit(BillingLoading());

      // Track analytics
      await AnalyticsService.instance.trackBillingPageView(event.entityType);

      List<Map<String, dynamic>> plans;
      
      if (_dataSource != null) {
        // Use real API call
        plans = await _dataSource.getAvailablePlans(event.entityType);
      } else {
        // Fallback to mock data
        plans = _getMockPlansForEntityType(event.entityType);
      }

      final currentState = state;
      if (currentState is PlansLoaded) {
        emit(currentState.copyWith(availablePlans: plans));
      } else {
        emit(PlansLoaded(availablePlans: plans));
      }
    } catch (e) {
      // Track error
      await AnalyticsService.instance.trackBillingError(
        'load_plans_failed', 
        e.toString(),
        entityType: event.entityType,
      );
      emit(BillingError('Erro ao carregar planos: $e'));
    }
  }

  Future<void> _onLoadCurrentPlan(
    LoadCurrentPlan event,
    Emitter<BillingState> emit,
  ) async {
    try {
      Map<String, dynamic>? currentPlan;
      
      if (_dataSource != null) {
        // Use real API call
        currentPlan = await _dataSource.getCurrentPlan(event.entityType, event.entityId);
      } else {
        // Fallback to mock data
        currentPlan = _getMockCurrentPlan(event.entityType);
      }

      final currentState = state;
      if (currentState is PlansLoaded) {
        emit(currentState.copyWith(currentPlan: currentPlan));
      } else {
        List<Map<String, dynamic>> plans;
        if (_dataSource != null) {
          plans = await _dataSource.getAvailablePlans(event.entityType);
        } else {
          plans = _getMockPlansForEntityType(event.entityType);
        }
        emit(PlansLoaded(availablePlans: plans, currentPlan: currentPlan));
      }
    } catch (e) {
      emit(BillingError('Erro ao carregar plano atual: $e'));
    }
  }

  Future<void> _onCreateCheckoutSession(
    CreateCheckoutSession event,
    Emitter<BillingState> emit,
  ) async {
    try {
      emit(BillingLoading());

      // Track checkout started
      await AnalyticsService.instance.trackCheckoutStarted(
        event.entityType,
        event.targetPlan,
        _getPlanPrice(event.targetPlan),
      );

      Map<String, dynamic> checkoutData;
      
      if (_dataSource != null) {
        // Use real API call
        checkoutData = await _dataSource.createCheckoutSession(
          targetPlan: event.targetPlan,
          entityType: event.entityType,
          entityId: event.entityId,
          successUrl: event.successUrl,
          cancelUrl: event.cancelUrl,
        );
      } else {
        // Fallback to mock data
        checkoutData = {
          'checkout_url': 'https://checkout.stripe.com/mock-session',
          'session_id': 'mock-session-id',
        };
      }
      
      emit(CheckoutSessionCreated(
        checkoutUrl: checkoutData['checkout_url'],
        sessionId: checkoutData['session_id'],
      ));
    } catch (e) {
      // Track checkout error
      await AnalyticsService.instance.trackBillingError(
        'checkout_creation_failed',
        e.toString(),
        entityType: event.entityType,
        planId: event.targetPlan,
      );
      emit(BillingError('Erro ao criar sessão de checkout: $e'));
    }
  }

  Future<void> _onLoadBillingHistory(
    LoadBillingHistory event,
    Emitter<BillingState> emit,
  ) async {
    try {
      emit(BillingLoading());

      // Mock billing history - replace with actual API call
      final billingRecords = <BillingRecord>[];
      final planHistory = <Map<String, dynamic>>[];

      emit(BillingHistoryLoaded(
        billingRecords: billingRecords,
        planHistory: planHistory,
      ));
    } catch (e) {
      emit(BillingError('Erro ao carregar histórico: $e'));
    }
  }

  Future<void> _onRefreshBillingData(
    RefreshBillingData event,
    Emitter<BillingState> emit,
  ) async {
    add(LoadAvailablePlans(event.entityType));
    add(LoadCurrentPlan(event.entityType, event.entityId));
    add(LoadBillingHistory(event.entityType, event.entityId));
  }

  double _getPlanPrice(String planId) {
    const prices = {
      'FREE': 0.0,
      'VIP': 99.90,
      'ENTERPRISE': 299.90,
      'PRO': 149.90,
      'PARTNER': 499.90,
      'PREMIUM': 999.90,
    };
    return prices[planId] ?? 0.0;
  }

  List<Map<String, dynamic>> _getMockPlansForEntityType(String entityType) {
    switch (entityType) {
      case 'client':
        return [
          {
            'id': 'FREE',
            'name': 'Gratuito',
            'price_monthly': 0.0,
            'features': [
              'Até 2 casos por mês',
              'Suporte por email',
              'Advogados verificados'
            ],
            'description': 'Plano básico para explorar a plataforma'
          },
          {
            'id': 'VIP',
            'name': 'VIP',
            'price_monthly': 99.90,
            'features': [
              'Casos ilimitados',
              'Prioridade no matching',
              'Advogados PRO exclusivos',
              'Suporte prioritário',
              'Manager dedicado'
            ],
            'description': 'Serviço concierge e priorização'
          },
          {
            'id': 'ENTERPRISE',
            'name': 'Enterprise',
            'price_monthly': 299.90,
            'features': [
              'Tudo do VIP',
              'SLA de 1 hora',
              'Integração via API',
              'Relatórios customizados',
              'Suporte 24/7',
              'Account manager executivo'
            ],
            'description': 'SLA corporativo e suporte dedicado'
          }
        ];

      case 'lawyer':
        return [
          {
            'id': 'FREE',
            'name': 'Gratuito',
            'price_monthly': 0.0,
            'features': [
              'Perfil básico',
              'Até 5 casos por mês',
              'Comissão padrão: 15%'
            ],
            'description': 'Plano básico para começar'
          },
          {
            'id': 'PRO',
            'name': 'PRO',
            'price_monthly': 149.90,
            'features': [
              'Perfil destacado',
              'Casos premium exclusivos',
              'Comissão reduzida: 10%',
              'Prioridade no matching',
              'Analytics avançado',
              'Suporte prioritário'
            ],
            'description': 'Para advogados que querem destaque e casos premium'
          }
        ];

      case 'firm':
        return [
          {
            'id': 'FREE',
            'name': 'Gratuito',
            'price_monthly': 0.0,
            'features': [
              'Perfil básico do escritório',
              'Até 3 advogados',
              'Comissão padrão: 15%'
            ],
            'description': 'Plano básico para escritórios pequenos'
          },
          {
            'id': 'PARTNER',
            'name': 'Partner',
            'price_monthly': 499.90,
            'features': [
              'Perfil destacado',
              'Até 20 advogados',
              'Comissão reduzida: 12%',
              'Dashboard administrativo',
              'Relatórios de performance',
              'API de integração'
            ],
            'description': 'Para escritórios que buscam crescimento'
          },
          {
            'id': 'PREMIUM',
            'name': 'Premium',
            'price_monthly': 999.90,
            'features': [
              'Tudo do Partner',
              'Advogados ilimitados',
              'Comissão reduzida: 8%',
              'White-label disponível',
              'SLA corporativo',
              'Account manager dedicado',
              'Integração ERP customizada'
            ],
            'description': 'Máxima visibilidade e recursos empresariais'
          }
        ];

      default:
        return [];
    }
  }

  Map<String, dynamic>? _getMockCurrentPlan(String entityType) {
    final plans = _getMockPlansForEntityType(entityType);
    return plans.isNotEmpty ? plans.first : null; // Return FREE plan as current
  }
} 