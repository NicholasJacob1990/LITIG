class HiringProposal {
  final String id;
  final String lawyerId;
  final String clientId;
  final String caseId;
  final String contractType; // 'hourly', 'fixed', 'success'
  final double budget;
  final String? notes;
  final String status; // 'pending', 'accepted', 'rejected', 'expired'
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? responseMessage;
  final DateTime expiresAt;

  const HiringProposal({
    required this.id,
    required this.lawyerId,
    required this.clientId,
    required this.caseId,
    required this.contractType,
    required this.budget,
    this.notes,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.responseMessage,
    required this.expiresAt,
  });

  HiringProposal copyWith({
    String? id,
    String? lawyerId,
    String? clientId,
    String? caseId,
    String? contractType,
    double? budget,
    String? notes,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? responseMessage,
    DateTime? expiresAt,
  }) {
    return HiringProposal(
      id: id ?? this.id,
      lawyerId: lawyerId ?? this.lawyerId,
      clientId: clientId ?? this.clientId,
      caseId: caseId ?? this.caseId,
      contractType: contractType ?? this.contractType,
      budget: budget ?? this.budget,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      responseMessage: responseMessage ?? this.responseMessage,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isExpired => status == 'expired' || DateTime.now().isAfter(expiresAt);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HiringProposal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}