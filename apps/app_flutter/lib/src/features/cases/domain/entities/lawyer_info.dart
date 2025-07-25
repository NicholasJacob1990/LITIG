import 'package:equatable/equatable.dart';

class LawyerInfo extends Equatable {
  final String avatarUrl;
  final String name;
  final String specialty;
  final int unreadMessages;
  final String createdDate;
  final String pendingDocsText;
  final String plan; // NOVO: Plano do advogado

  const LawyerInfo({
    required this.avatarUrl,
    required this.name,
    required this.specialty,
    required this.unreadMessages,
    required this.createdDate,
    required this.pendingDocsText,
    this.plan = 'FREE', // NOVO: Padrão FREE
  });

  /// Verifica se o advogado tem plano PRO
  bool get isPro => plan.toUpperCase() == 'PRO';

  /// Verifica se o advogado tem plano FREE
  bool get isFree => plan.toUpperCase() == 'FREE';

  factory LawyerInfo.fromJson(Map<String, dynamic> json) {
    return LawyerInfo(
      avatarUrl: json['avatar_url'] ?? '',
      name: json['name'] ?? 'Advogado não encontrado',
      specialty: json['specialty'] ?? '',
      unreadMessages: int.tryParse(json['unread_messages']?.toString() ?? '0') ?? 0,
      createdDate: json['created_date'] ?? '',
      pendingDocsText: json['pending_docs_text'] ?? '',
      plan: json['plan'] as String? ?? 'FREE', // NOVO: Consumir do backend
    );
  }

  @override
  List<Object?> get props => [avatarUrl, name, specialty, unreadMessages, createdDate, pendingDocsText, plan]; // NOVO
} 