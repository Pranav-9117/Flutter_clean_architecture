import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_architecture_demo/app/app.dart';

export 'package:flutter_architecture_demo/app/app.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}
