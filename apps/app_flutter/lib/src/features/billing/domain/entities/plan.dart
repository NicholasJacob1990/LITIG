import 'package:equatable/equatable.dart';

class Plan extends Equatable {
  final String id;
  final String name;
  final double priceMonthly;
  final List<String> features;
  final String description;
  final String entityType; // 'client', 'lawyer', 'firm'

  const Plan({
    required this.id,
    required this.name,
    required this.priceMonthly,
    required this.features,
    required this.description,
    required this.entityType,
  });

  @override
  List<Object?> get props => [id, name, priceMonthly, features, description, entityType];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price_monthly': priceMonthly,
      'features': features,
      'description': description,
      'entity_type': entityType,
    };
  }

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'],
      name: json['name'],
      priceMonthly: json['price_monthly']?.toDouble() ?? 0.0,
      features: List<String>.from(json['features'] ?? []),
      description: json['description'] ?? '',
      entityType: json['entity_type'] ?? 'client',
    );
  }

  Plan copyWith({
    String? id,
    String? name,
    double? priceMonthly,
    List<String>? features,
    String? description,
    String? entityType,
  }) {
    return Plan(
      id: id ?? this.id,
      name: name ?? this.name,
      priceMonthly: priceMonthly ?? this.priceMonthly,
      features: features ?? this.features,
      description: description ?? this.description,
      entityType: entityType ?? this.entityType,
    );
  }
} 