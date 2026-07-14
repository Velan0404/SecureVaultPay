import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/create_pin_screen.dart';
import '../screens/auth/enable_biometric_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/pin_unlock_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/dashboard/dashboard_placeholder_screen.dart';

const _publicRoutes = {'/login', '/register', '/forgot-password', '/reset-password'};
const _onboardingRoutes = {'/create-pin', '/enable-biometric'};

/// Visual-only fade+slide transition wrapper — does not affect route
/// matching, redirects, or navigation state in any way.
CustomTransitionPage<void> _fadeThroughPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (previous, next) {
      if (previous?.status != next.status) notifyListeners();
    });
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final status = ref.read(authProvider).status;
      final location = state.matchedLocation;

      switch (status) {
        case AuthStatus.unknown:
          return location == '/splash' ? null : '/splash';
        case AuthStatus.unauthenticated:
          if (location == '/splash' || !_publicRoutes.contains(location)) return '/login';
          return null;
        case AuthStatus.needsUnlock:
          return location == '/unlock' ? null : '/unlock';
        case AuthStatus.onboarding:
          return _onboardingRoutes.contains(location) ? null : '/create-pin';
        case AuthStatus.authenticated:
          final blocked = location == '/splash' ||
              location == '/unlock' ||
              _publicRoutes.contains(location) ||
              _onboardingRoutes.contains(location);
          return blocked ? '/dashboard' : null;
      }
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fadeThroughPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadeThroughPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _fadeThroughPage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _fadeThroughPage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, ResetPasswordScreen(email: state.extra as String? ?? '')),
      ),
      GoRoute(
        path: '/create-pin',
        pageBuilder: (context, state) => _fadeThroughPage(state, const CreatePinScreen()),
      ),
      GoRoute(
        path: '/enable-biometric',
        pageBuilder: (context, state) => _fadeThroughPage(state, const EnableBiometricScreen()),
      ),
      GoRoute(
        path: '/unlock',
        pageBuilder: (context, state) => _fadeThroughPage(state, const PinUnlockScreen()),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => _fadeThroughPage(state, const DashboardPlaceholderScreen()),
      ),
    ],
  );
});
