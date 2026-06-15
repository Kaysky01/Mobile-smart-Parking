import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/data/student_repository.dart';
import 'core/network/api_client.dart';
import 'core/state/app_controller.dart';
import 'core/storage/session_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/navigation/presentation/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = SessionStorage();
  final apiClient = ApiClient(storage);
  final controller = AppController(
    storage,
    AuthRepository(apiClient.dio, storage),
    StudentRepository(apiClient.dio),
  );
  runApp(MyParkingApp(controller: controller));
}

class MyParkingApp extends StatefulWidget {
  const MyParkingApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<MyParkingApp> createState() => _MyParkingAppState();
}

class _MyParkingAppState extends State<MyParkingApp> {
  @override
  void initState() {
    super.initState();
    widget.controller.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.controller,
      child: MaterialApp(
        title: 'MyParking',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _SessionGate(),
      ),
    );
  }
}

class _SessionGate extends StatelessWidget {
  const _SessionGate();

  @override
  Widget build(BuildContext context) {
    final status = context.select<AppController, SessionStatus>(
      (controller) => controller.status,
    );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: switch (status) {
        SessionStatus.checking => const _SplashScreen(key: ValueKey('splash')),
        SessionStatus.signedOut => const LoginScreen(key: ValueKey('login')),
        SessionStatus.authenticated => const MainShell(key: ValueKey('shell')),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1D4ED8), AppColors.secondary],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'lib/assets/logo parking.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              const Text(
                'MyParking',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
