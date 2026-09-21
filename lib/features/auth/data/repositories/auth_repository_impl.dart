import 'package:flutter_architecture_demo/features/auth/data/models/auth_response_model.dart';
import 'package:flutter_architecture_demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_architecture_demo/core/storage/token_storage.dart';
import 'package:flutter_architecture_demo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_architecture_demo/features/auth/data/models/login_request_model.dart';
import 'package:flutter_architecture_demo/features/auth/data/models/register_request_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenStorage tokenStorage;

  AuthRepositoryImpl(this.remoteDataSource, this.tokenStorage);

  @override
  Future<void> login(String email, String password) async {
    final response = await remoteDataSource.login(
      LoginRequestModel(email: email, password: password),
    );
    await _saveTokens(response);
  }

  @override
  Future<void> register(String email, String password) async {
    final response = await remoteDataSource.register(
      RegisterRequestModel(email: email, password: password),
    );
    await _saveTokens(response);
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await tokenStorage.clear();
  }

  Future<void> _saveTokens(AuthResponseModel response) async {
    if (response.accessToken != null) {
      await tokenStorage.saveAccessToken(response.accessToken!);
    }
    if (response.refreshToken != null) {
      await tokenStorage.saveRefreshToken(response.refreshToken!);
    }
  }
}
