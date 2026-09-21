import '../repositories/auth_repository.dart';

class Register {
  final AuthRepository repository;

  Register(this.repository);

  Future<void> call(String email, String password) {
    return repository.register(email, password);
  }
}
