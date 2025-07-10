import 'package:meu_app/src/features/auth/domain/entities/user.dart';
import 'package:meu_app/src/features/auth/domain/repositories/auth_repository.dart';

class GetAuthStateChangesUseCase {
  final AuthRepository repository;

  GetAuthStateChangesUseCase(this.repository);

  Stream<User?> call() {
    return repository.authStateChanges;
  }
} 