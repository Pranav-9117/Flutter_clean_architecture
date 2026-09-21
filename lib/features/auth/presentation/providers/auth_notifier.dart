import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  const AuthState({required this.isLoading, required this.isAuthenticated});

  final bool isLoading;
  final bool isAuthenticated;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    unawaited(_checkInitialAuth());
    return const AuthState(isLoading: true, isAuthenticated: false);
  }

  Future<void> _checkInitialAuth() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    // Replace this with a secure-storage token check when authentication is connected.
    const isUserLoggedIn = true;

    state = const AuthState(isLoading: false, isAuthenticated: isUserLoggedIn);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
