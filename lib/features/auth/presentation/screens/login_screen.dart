import 'package:flutter/material.dart';
import 'package:flutter_architecture_demo/app/router/route_names.dart';
import 'package:flutter_architecture_demo/features/auth/presentation/providers/auth_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'emilys');
  final _passwordController = TextEditingController(text: 'emilyspass');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 16),
                if (authState.error != null)
                  Text(authState.error!, style: const TextStyle(color: Colors.red)),
                FilledButton(
                  onPressed: authState.isLoading
                      ? null
                      : () => ref.read(authProvider.notifier).login(
                            _emailController.text.trim(),
                            _passwordController.text,
                          ),
                  child: Text(authState.isLoading ? 'Signing in...' : 'Sign in'),
                ),
                TextButton(
                  onPressed: () => context.go(RouteNames.register),
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
