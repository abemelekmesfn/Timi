import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/storage/auth_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goToLogin();
  }

  Future<void> _goToLogin() async {
    await AuthStorage().logout();
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    context.go("/login");
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "TIMI",
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
