class HiringResult {
  final String proposalId;
  final String contractId;
  final String message;
  final DateTime createdAt;

  const HiringResult({
    required this.proposalId,
    required this.contractId,
    required this.message,
    required this.createdAt,
  });

  HiringResult copyWith({
    String? proposalId,
    String? contractId,
    String? message,
    DateTime? createdAt,
  }) {
    return HiringResult(
      proposalId: proposalId ?? this.proposalId,
      contractId: contractId ?? this.contractId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HiringResult && other.proposalId == proposalId;
  }

  @override
  int get hashCode => proposalId.hashCode;
}