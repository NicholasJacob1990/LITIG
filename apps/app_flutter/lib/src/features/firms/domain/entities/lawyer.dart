import 'package:equatable/equatable.dart';

/// A entidade `Lawyer` representa um advogado no domínio do aplicativo.
///
/// Contém as informações essenciais sobre um advogado, independentemente
/// da fonte de dados (API, banco de dados local, etc.).
class Lawyer extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? specialization;
  final String? avatarUrl;
  final String firmId;

  const Lawyer({
    required this.id,
    required this.name,
    this.email,
    this.specialization,
    this.avatarUrl,
    required this.firmId,
  });

  @override
  List<Object?> get props => [id, name, email, specialization, avatarUrl, firmId];
} 