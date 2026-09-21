import 'package:flutter_architecture_demo/core/providers/core_providers.dart';
import 'package:flutter_architecture_demo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_architecture_demo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_architecture_demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_architecture_demo/features/auth/domain/usecases/login.dart';
import 'package:flutter_architecture_demo/features/auth/domain/usecases/logout.dart';
import 'package:flutter_architecture_demo/features/auth/domain/usecases/register.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(tokenStorageProvider),
  );
});

final loginUseCaseProvider = Provider<Login>((ref) {
  return Login(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<Register>((ref) {
  return Register(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<Logout>((ref) {
  return Logout(ref.watch(authRepositoryProvider));
});