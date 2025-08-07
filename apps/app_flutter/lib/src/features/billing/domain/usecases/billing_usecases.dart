import 'package:meu_app/src/features/billing/domain/entities/plan.dart';
import 'package:meu_app/src/features/billing/domain/entities/billing_record.dart';
import 'package:meu_app/src/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:meu_app/src/core/utils/logger.dart';

class BillingUseCases {
  final BillingRemoteDataSource _remoteDataSource;

  BillingUseCases({required BillingRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;
  
  Future<List<Plan>> getAvailablePlans(String entityType) async {
    try {
      AppLogger.info('Getting available plans for entity type: $entityType');
      
      final plansData = await _remoteDataSource.getAvailablePlans(entityType);
      final plans = plansData.map((planJson) => Plan.fromJson(planJson)).toList();
      
      AppLogger.success('Retrieved ${plans.length} available plans');
      return plans;
    } catch (e) {
      AppLogger.error('Error getting available plans', error: e);
      rethrow;
    }
  }
  
  Future<Plan?> getCurrentPlan(String entityType, String entityId) async {
    try {
      AppLogger.info('Getting current plan for $entityType: $entityId');
      
      final planData = await _remoteDataSource.getCurrentPlan(entityType, entityId);
      if (planData == null) {
        AppLogger.info('No current plan found');
        return null;
      }
      
      final plan = Plan.fromJson(planData);
      AppLogger.success('Retrieved current plan: ${plan.name}');
      return plan;
    } catch (e) {
      AppLogger.error('Error getting current plan', error: e);
      rethrow;
    }
  }
  
  Future<String> createCheckoutSession({
    required String targetPlan,
    required String entityType,
    required String entityId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      AppLogger.info('Creating checkout session for plan: $targetPlan');
      
      final sessionData = await _remoteDataSource.createCheckoutSession(
        targetPlan: targetPlan,
        entityType: entityType,
        entityId: entityId,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );
      
      final checkoutUrl = sessionData['checkout_url'] as String;
      AppLogger.success('Checkout session created successfully');
      return checkoutUrl;
    } catch (e) {
      AppLogger.error('Error creating checkout session', error: e);
      rethrow;
    }
  }
  
  Future<List<BillingRecord>> getBillingHistory(String entityType, String entityId) async {
    try {
      AppLogger.info('Getting billing history for $entityType: $entityId');
      
      final records = await _remoteDataSource.getBillingHistory(entityType, entityId);
      
      AppLogger.success('Retrieved ${records.length} billing records');
      return records;
    } catch (e) {
      AppLogger.error('Error getting billing history', error: e);
      rethrow;
    }
  }

  Future<void> cancelSubscription(String entityType, String entityId) async {
    try {
      AppLogger.info('Cancelling subscription for $entityType: $entityId');
      
      // API call would be implemented here
      await Future.delayed(const Duration(milliseconds: 500));
      
      AppLogger.success('Subscription cancelled successfully');
    } catch (e) {
      AppLogger.error('Error cancelling subscription', error: e);
      rethrow;
    }
  }

  Future<void> updatePaymentMethod(String entityType, String entityId, Map<String, dynamic> paymentMethodData) async {
    try {
      AppLogger.info('Updating payment method for $entityType: $entityId');
      
      // API call would be implemented here
      await Future.delayed(const Duration(milliseconds: 300));
      
      AppLogger.success('Payment method updated successfully');
    } catch (e) {
      AppLogger.error('Error updating payment method', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getInvoiceDetails(String invoiceId) async {
    try {
      AppLogger.info('Getting invoice details for: $invoiceId');
      
      // API call would be implemented here
      await Future.delayed(const Duration(milliseconds: 200));
      
      final mockInvoice = {
        'id': invoiceId,
        'amount': 99.90,
        'currency': 'BRL',
        'status': 'paid',
        'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'due_date': DateTime.now().subtract(const Duration(days: 25)).toIso8601String(),
        'paid_at': DateTime.now().subtract(const Duration(days: 25)).toIso8601String(),
        'items': [
          {
            'description': 'Plano VIP - Mensal',
            'quantity': 1,
            'unit_price': 99.90,
            'total': 99.90,
          }
        ]
      };
      
      AppLogger.success('Retrieved invoice details');
      return mockInvoice;
    } catch (e) {
      AppLogger.error('Error getting invoice details', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPlanHistory(String entityType, String entityId) async {
    try {
      AppLogger.info('Getting plan history for $entityType: $entityId');
      
      final history = await _remoteDataSource.getPlanHistory(entityType, entityId);
      
      AppLogger.success('Retrieved ${history.length} plan history records');
      return history;
    } catch (e) {
      AppLogger.error('Error getting plan history', error: e);
      rethrow;
    }
  }
} 