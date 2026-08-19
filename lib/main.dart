import 'package:sistem_cormex/Src/Config/appTheme.dart';
import 'package:sistem_cormex/Src/Dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const ComerxApp());
}

class ComerxApp extends StatelessWidget {
  const ComerxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Cormex Exchange',
      theme: AppTheme.light,
      routerConfig: getIt<GoRouter>(),
    );
  }
}
