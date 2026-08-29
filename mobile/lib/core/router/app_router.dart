import 'package:go_router/go_router.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/splash/splash_screen.dart';

final router = GoRouter(
  initialLocation: "/",

  routes: [
    GoRoute(path: "/", builder: (_, __) => const SplashScreen()),

    GoRoute(path: "/login", builder: (_, __) => const LoginScreen()),

    GoRoute(path: "/dashboard", builder: (_, __) => const DashboardScreen()),
  ],
);
