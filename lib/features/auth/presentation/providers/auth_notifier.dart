import 'dart:async';

import 'package:flutter_architecture_demo/core/providers/core_providers.dart';
import 'package:flutter_architecture_demo/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  const AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.error,
  });

  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    unawaited(_checkInitialAuth());
    return const AuthState(isLoading: true, isAuthenticated: false);
  }

  Future<void> _checkInitialAuth() async {
    final token = await ref.read(tokenStorageProvider).getAccessToken();
    state = AuthState(
      isLoading: false,
      isAuthenticated: token != null && token.isNotEmpty,
    );
  }

  Future<void> login(String email, String password) async {
    state = const AuthState(isLoading: true, isAuthenticated: false);
    try {
      await ref.read(loginUseCaseProvider)(email, password);
      state = const AuthState(isLoading: false, isAuthenticated: true);
    } catch (error) {
      state = AuthState(
        isLoading: false,
        isAuthenticated: false,
        error: error.toString(),
      );
    }
  }

  Future<void> register(String email, String password) async {
    state = const AuthState(isLoading: true, isAuthenticated: false);
    try {
      await ref.read(registerUseCaseProvider)(email, password);
      state = const AuthState(isLoading: false, isAuthenticated: true);
    } catch (error) {
      state = AuthState(
        isLoading: false,
        isAuthenticated: false,
        error: error.toString(),
      );
    }
  }

  Future<void> logout() async {
    state = const AuthState(isLoading: true, isAuthenticated: true);
    try {
      await ref.read(logoutUseCaseProvider)();
      state = const AuthState(isLoading: false, isAuthenticated: false);
    } catch (error) {
      state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        error: error.toString(),
      );
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
