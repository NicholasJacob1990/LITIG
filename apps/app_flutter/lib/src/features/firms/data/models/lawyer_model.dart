import '../../domain/entities/lawyer.dart';

/// O `LawyerModel` é a implementação do `Lawyer` para a camada de dados.
///
/// Ele estende a entidade `Lawyer` e adiciona a capacidade de ser
/// criado a partir de um mapa JSON vindo da API.
class LawyerModel extends Lawyer {
  const LawyerModel({
    required super.id,
    required super.name,
    super.email,
    super.specialization,
    super.avatarUrl,
    required super.firmId,
  });

  /// Factory constructor para criar uma instância de `LawyerModel` a partir de um JSON.
  factory LawyerModel.fromJson(Map<String, dynamic> json) {
    return LawyerModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      specialization: json['specialization'],
      avatarUrl: json['avatar_url'],
      firmId: json['firm_id'],
    );
  }

  /// Método para converter a instância de `LawyerModel` para um mapa JSON.
  /// (Útil para enviar dados para a API, se necessário)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'specialization': specialization,
      'avatar_url': avatarUrl,
      'firm_id': firmId,
    };
  }
} 