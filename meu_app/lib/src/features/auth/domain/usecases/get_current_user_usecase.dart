import 'package:meu_app/src/features/auth/domain/entities/user.dart';
import 'package:meu_app/src/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<User?> call() async {
    return await repository.getCurrentUser();
  }
} 