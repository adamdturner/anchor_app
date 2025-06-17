import 'package:flutter/material.dart';

import '/presentation/screens/auth/login_screen.dart';
import '/presentation/screens/account/role_selection_screen.dart';
import '/presentation/screens/auth/signup_screen.dart';
import '/presentation/screens/auth/loading_screen.dart';
import 'package:anchor_app/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:anchor_app/presentation/fitness/fitness_tracking_screen.dart';


class AppRouter {
  /// Routes for public/unauthed access, handled in main.dart
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/role_selection':
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      case '/admin_signup':
        return MaterialPageRoute(builder: (_) => const SignupScreen(role: 'admin'));
      case '/user_signup':
        return MaterialPageRoute(builder: (_) => const SignupScreen(role: 'user'));
      case '/loading':
        return MaterialPageRoute(builder: (_) => const LoadingScreen());
      default:
        return null;
    }
  }
  
  /// Routes used after user is authenticated — used in `AuthenticatedApp`
  static Route<dynamic>? authenticatedRoutes(RouteSettings settings) {
    switch (settings.name) {    
      case '/dashboard':
        return _noAnimationRoute(const DashboardScreen());

      case '/fitness':
        return _noAnimationRoute(const FitnessTrackingScreen());

      case '/logout':
        return _noAnimationRoute(const LoginScreen());

      default:
        return _noAnimationRoute(const DashboardScreen());
    }
  }
}

Route<dynamic> _noAnimationRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}