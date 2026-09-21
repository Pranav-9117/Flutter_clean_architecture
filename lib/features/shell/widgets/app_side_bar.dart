import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_architecture_demo/app/router/route_names.dart';
import 'package:flutter_architecture_demo/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSideBar extends ConsumerWidget {
  const AppSideBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String curLocation = GoRouterState.of(context).uri.path;
    return Container(
      width: 250,
      color: Theme.of(context).cardColor, // Optional: gives it a background color
      child: Column(
        children: [
          ListTile(
            title: Text("Dashboard"),
            selected: curLocation.startsWith(RouteNames.dashboard),
            onTap: () {
              context.go(RouteNames.dashboard);
            },
          ),
          ListTile(
            title: Text("Users"),
            selected: curLocation.startsWith(RouteNames.users),
            onTap: () {
              context.go(RouteNames.users);
            },
          ),
          ListTile(
            title: Text("Services"),
            selected: curLocation.startsWith(RouteNames.services),
            onTap: () {
              context.go(RouteNames.services);
            },
          ),
          ListTile(
            title: Text("Equipments"),
            selected: curLocation.startsWith(RouteNames.equipment),
            onTap: () {
              context.go(RouteNames.equipment);
            },
          ),
          ListTile(
            title: Text("Settings"),
            selected: curLocation.startsWith(RouteNames.settings),
            onTap: () {
              context.go(RouteNames.settings);
            },
          ),
          const Spacer(),
          ListTile(
            title: const Text('Logout'),
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
