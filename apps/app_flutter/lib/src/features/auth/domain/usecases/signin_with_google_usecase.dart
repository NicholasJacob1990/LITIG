import 'package:meu_app/src/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogleUseCase {
  final AuthRepository _repository;

  SignInWithGoogleUseCase(this._repository);

  Future<void> call() async {
    return await _repository.signInWithGoogle();
  }
} 