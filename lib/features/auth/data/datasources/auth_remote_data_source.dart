import 'package:dio/dio.dart';
import 'package:flutter_architecture_demo/core/network/dio_client.dart';
import 'package:flutter_architecture_demo/features/auth/data/models/auth_response_model.dart';
import 'package:flutter_architecture_demo/features/auth/data/models/login_request_model.dart';
import 'package:flutter_architecture_demo/features/auth/data/models/register_request_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(LoginRequestModel request);
  Future<AuthResponseModel> register(RegisterRequestModel request);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this.client);

  final DioClient client;

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    final response = await client.dio.post(
      '/auth/login',
      data: request.toJson(),
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    final response = await client.dio.post(
      '/users/add',
      data: request.toJson(),
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    try {
      await client.dio.post('/auth/logout');
    } on DioException {
    }
  }
}
