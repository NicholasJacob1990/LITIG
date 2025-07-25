import 'package:equatable/equatable.dart';

class BillingRecord extends Equatable {
  final String id;
  final String userId;
  final String entityType;
  final String entityId;
  final String stripeSubscriptionId;
  final String plan;
  final int amountCents;
  final String status;
  final DateTime billingPeriodStart;
  final DateTime billingPeriodEnd;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BillingRecord({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.stripeSubscriptionId,
    required this.plan,
    required this.amountCents,
    required this.status,
    required this.billingPeriodStart,
    required this.billingPeriodEnd,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    entityType,
    entityId,
    stripeSubscriptionId,
    plan,
    amountCents,
    status,
    billingPeriodStart,
    billingPeriodEnd,
    createdAt,
    updatedAt,
  ];

  double get amountReais => amountCents / 100.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'entity_type': entityType,
      'entity_id': entityId,
      'stripe_subscription_id': stripeSubscriptionId,
      'plan': plan,
      'amount_cents': amountCents,
      'status': status,
      'billing_period_start': billingPeriodStart.toIso8601String(),
      'billing_period_end': billingPeriodEnd.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory BillingRecord.fromJson(Map<String, dynamic> json) {
    return BillingRecord(
      id: json['id'],
      userId: json['user_id'],
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      stripeSubscriptionId: json['stripe_subscription_id'],
      plan: json['plan'],
      amountCents: json['amount_cents'],
      status: json['status'],
      billingPeriodStart: DateTime.parse(json['billing_period_start']),
      billingPeriodEnd: DateTime.parse(json['billing_period_end']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  BillingRecord copyWith({
    String? id,
    String? userId,
    String? entityType,
    String? entityId,
    String? stripeSubscriptionId,
    String? plan,
    int? amountCents,
    String? status,
    DateTime? billingPeriodStart,
    DateTime? billingPeriodEnd,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BillingRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      plan: plan ?? this.plan,
      amountCents: amountCents ?? this.amountCents,
      status: status ?? this.status,
      billingPeriodStart: billingPeriodStart ?? this.billingPeriodStart,
      billingPeriodEnd: billingPeriodEnd ?? this.billingPeriodEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 