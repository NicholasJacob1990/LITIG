import 'package:equatable/equatable.dart';

class AdminMetrics extends Equatable {
  final String metricsType;
  final Map<String, dynamic> data;
  final DateTime generatedAt;
  final Map<String, dynamic>? metadata;

  const AdminMetrics({
    required this.metricsType,
    required this.data,
    required this.generatedAt,
    this.metadata,
  });

  @override
  List<Object?> get props => [metricsType, data, generatedAt, metadata];

  AdminMetrics copyWith({
    String? metricsType,
    Map<String, dynamic>? data,
    DateTime? generatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return AdminMetrics(
      metricsType: metricsType ?? this.metricsType,
      data: data ?? this.data,
      generatedAt: generatedAt ?? this.generatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Getters específicos por tipo de métrica
  Map<String, dynamic> get systemMetrics => 
      metricsType == 'system' ? data : <String, dynamic>{};
  
  Map<String, dynamic> get userMetrics => 
      metricsType == 'users' ? data : <String, dynamic>{};
  
  Map<String, dynamic> get caseMetrics => 
      metricsType == 'cases' ? data : <String, dynamic>{};
  
  Map<String, dynamic> get qualityMetrics => 
      metricsType == 'quality' ? data : <String, dynamic>{};
} 