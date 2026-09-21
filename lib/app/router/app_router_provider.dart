import 'package:flutter_architecture_demo/app/router/app_router.dart';
import 'package:flutter_architecture_demo/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  return AppRouter(authState: authState).appRouter;
});
