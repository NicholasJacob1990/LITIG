class TrendingCluster {
  final String clusterId;
  final String clusterLabel;
  final double momentumScore;
  final int totalCases;
  final bool isEmergent;
  final DateTime? emergentSince;
  final double labelConfidence;

  const TrendingCluster({
    required this.clusterId,
    required this.clusterLabel,
    required this.momentumScore,
    required this.totalCases,
    required this.isEmergent,
    this.emergentSince,
    required this.labelConfidence,
  });

  factory TrendingCluster.fromJson(Map<String, dynamic> json) {
    return TrendingCluster(
      clusterId: json['cluster_id'] ?? '',
      clusterLabel: json['cluster_label'] ?? '',
      momentumScore: (json['momentum_score'] ?? 0.0).toDouble(),
      totalCases: json['total_items'] ?? 0,
      isEmergent: json['is_emergent'] ?? false,
      emergentSince: json['emergent_since'] != null 
          ? DateTime.parse(json['emergent_since']) 
          : null,
      labelConfidence: (json['label_confidence'] ?? 0.8).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cluster_id': clusterId,
      'cluster_label': clusterLabel,
      'momentum_score': momentumScore,
      'total_items': totalCases,
      'is_emergent': isEmergent,
      'emergent_since': emergentSince?.toIso8601String(),
      'label_confidence': labelConfidence,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrendingCluster &&
        other.clusterId == clusterId &&
        other.clusterLabel == clusterLabel;
  }

  @override
  int get hashCode {
    return clusterId.hashCode ^ clusterLabel.hashCode;
  }

  @override
  String toString() {
    return 'TrendingCluster(clusterId: $clusterId, clusterLabel: $clusterLabel, momentumScore: $momentumScore, totalCases: $totalCases)';
  }
} 