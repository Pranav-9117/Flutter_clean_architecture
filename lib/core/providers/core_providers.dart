import 'package:flutter_architecture_demo/core/network/dio_client.dart';
import 'package:flutter_architecture_demo/core/storage/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});