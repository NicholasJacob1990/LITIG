import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/auth/domain/repositories/auth_repository.dart';

class RegisterClientUseCase {
  final AuthRepository repository;

  RegisterClientUseCase(this.repository);

  Future<void> call(RegisterClientParams params) async {
    return await repository.registerClient(
      email: params.email,
      password: params.password,
      name: params.name,
      userType: params.userType,
      cpf: params.cpf,
      cnpj: params.cnpj,
    );
  }
}

class RegisterClientParams extends Equatable {
  final String email;
  final String password;
  final String name;
  final String userType;
  final String? cpf;
  final String? cnpj;

  const RegisterClientParams({
    required this.email,
    required this.password,
    required this.name,
    required this.userType,
    this.cpf,
    this.cnpj,
  });

  @override
  List<Object?> get props => [email, password, name, userType, cpf, cnpj];
} 