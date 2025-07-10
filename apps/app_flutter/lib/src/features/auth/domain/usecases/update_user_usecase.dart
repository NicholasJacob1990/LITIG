import '../repositories/auth_repository.dart';

class UpdateUserUseCase {
  final AuthRepository repository;

  UpdateUserUseCase(this.repository);

  Future<void> call(UpdateUserParams params) async {
    try {
      await repository.updateUser(fullName: params.fullName);
    } catch (e) {
      rethrow;
    }
  }
}

class UpdateUserParams {
  final String fullName;

  UpdateUserParams({
    required this.fullName,
  });
} 