import 'package:equatable/equatable.dart';

class DataSourceInfo extends Equatable {
  final String sourceName;
  final DateTime lastUpdated;
  final double qualityScore;
  final bool hasError;
  final String? errorMessage;

  const DataSourceInfo({
    required this.sourceName,
    required this.lastUpdated,
    required this.qualityScore,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props =>
      [sourceName, lastUpdated, qualityScore, hasError, errorMessage];
} 