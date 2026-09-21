import 'package:flutter/material.dart';
import 'package:flutter_architecture_demo/features/shell/widgets/app_side_bar.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const AppSideBar(),
          Expanded(child: child),
        ],
      ),
    );
  }
}
