import 'package:flutter_architecture_demo/app/router/route_names.dart';
import 'package:flutter_architecture_demo/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_architecture_demo/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_architecture_demo/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter_architecture_demo/features/shell/presentation/screens/dashboard_screen.dart';
import 'package:flutter_architecture_demo/features/shell/presentation/screens/equipment_screen.dart';
import 'package:flutter_architecture_demo/features/shell/presentation/screens/services_screen.dart';
import 'package:flutter_architecture_demo/features/shell/presentation/screens/settings_screen.dart';
import 'package:flutter_architecture_demo/features/shell/presentation/screens/shell_screen.dart';
import 'package:flutter_architecture_demo/features/shell/presentation/screens/users_screen.dart';
import 'package:flutter_architecture_demo/features/splash/presentation/screens/splash_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter({required this.authState}) : appRouter = _createRouter(authState);

  final AuthState authState;
  final GoRouter appRouter;

  static GoRouter _createRouter(AuthState authState) {
    return GoRouter(
      initialLocation: RouteNames.splash,
      redirect: (context, state) {
        final isSplashRoute = state.matchedLocation == RouteNames.splash;
        final isAuthRoute =
            state.matchedLocation == RouteNames.login ||
            state.matchedLocation == RouteNames.register;

        if (authState.isLoading) {
          return isSplashRoute ? null : RouteNames.splash;
        }

        if (!authState.isAuthenticated) {
          return isSplashRoute || isAuthRoute ? null : RouteNames.login;
        }

        return isSplashRoute || isAuthRoute ? RouteNames.dashboard : null;
      },
      routes: [
        GoRoute(
          path: RouteNames.splash,
          builder: (context, state) {
            return SplashScreen();
          },
        ),
        GoRoute(
          path: RouteNames.login,
          builder: (context, state) {
            return LoginScreen();
          },
        ),
        GoRoute(
          path: RouteNames.register,
          builder: (context, state) {
            return RegisterScreen();
          },
        ),
        ShellRoute(
          builder: (context, state, child) {
            return ShellScreen(child: child);
          },
          routes: [
            GoRoute(
              path: RouteNames.dashboard,
              builder: (_, _) {
                return DashboardScreen();
              },
            ),
            GoRoute(
              path: RouteNames.users,
              builder: (_, _) {
                return UsersScreen();
              },
            ),
            GoRoute(
              path: RouteNames.services,
              builder: (_, _) {
                return ServicesScreen();
              },
            ),
            GoRoute(
              path: RouteNames.equipment,
              builder: (_, _) {
                return EquipmentScreen();
              },
            ),
            GoRoute(
              path: RouteNames.settings,
              builder: (_, _) {
                return SettingsScreen();
              },
            ),
          ],
        ),
      ],
    );
  }
}
