import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/purpose_wallet_model.dart';
import '../providers/auth_provider.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/auth/create_pin_screen.dart';
import '../screens/auth/enable_biometric_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/pin_unlock_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/merchant/confirm_payment_pin_screen.dart';
import '../screens/merchant/create_payment_pin_screen.dart';
import '../screens/merchant/enter_payment_pin_screen.dart';
import '../screens/merchant/merchant_details_screen.dart';
import '../screens/merchant/merchant_list_screen.dart';
import '../screens/merchant/merchant_payment_result_screen.dart';
import '../screens/merchant/merchant_payment_screen.dart';
import '../screens/merchant/select_purpose_wallet_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/wallet/main_wallet_screen.dart';
import '../screens/wallet/purpose_wallet_form_screen.dart';
import '../screens/wallet/transaction_authentication_screen.dart';
import '../screens/wallet/transaction_history_screen.dart';
import '../screens/wallet/transfer_money_screen.dart';
import '../screens/wallet/wallet_details_screen.dart';
import '../widgets/app_shell.dart';

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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                pageBuilder: (context, state) => _fadeThroughPage(state, const DashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallet/main',
                pageBuilder: (context, state) => _fadeThroughPage(state, const MainWalletScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schedule',
                pageBuilder: (context, state) => _fadeThroughPage(state, const ScheduleScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                pageBuilder: (context, state) => _fadeThroughPage(state, const AnalyticsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => _fadeThroughPage(state, const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/wallet/create',
        pageBuilder: (context, state) => _fadeThroughPage(state, const PurposeWalletFormScreen()),
      ),
      GoRoute(
        path: '/wallet/transfer',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, TransferMoneyScreen(preselectedWallet: state.extra as PurposeWalletModel?)),
      ),
      GoRoute(
        path: '/wallet/transaction-auth',
        pageBuilder: (context, state) {
          final args = state.extra! as TransactionAuthRouteArgs;
          return _fadeThroughPage(
            state,
            TransactionAuthenticationScreen(
              purposeWalletId: args.wallet.id,
              purposeWalletName: args.wallet.name,
              purposeWalletIcon: args.wallet.icon,
              purposeWalletColor: args.wallet.color,
              amount: args.amount,
            ),
          );
        },
      ),
      GoRoute(
        path: '/wallet/transactions',
        pageBuilder: (context, state) => _fadeThroughPage(state, const TransactionHistoryScreen()),
      ),
      GoRoute(
        path: '/wallet/:id',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, WalletDetailsScreen(walletId: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/wallet/:id/edit',
        pageBuilder: (context, state) => _fadeThroughPage(
          state,
          PurposeWalletFormScreen(existingWallet: state.extra as PurposeWalletModel?),
        ),
      ),
      GoRoute(
        path: '/merchants',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, MerchantListScreen(wallet: state.extra! as PurposeWalletModel)),
      ),
      // Every static /merchants/... route MUST be declared before /merchants/:id
      // below — go_router tries top-level routes in list order, and /merchants/:id
      // matches ANY single path segment (including "payment-result"), so a static
      // route declared after it would never be reached and its `extra` would be
      // force-cast to the wrong type by /merchants/:id's screen instead. This
      // exact ordering bug (once caused a MerchantPaymentResultArgs -> PurposeWalletModel
      // cast crash) is why this route sits here rather than further down the list.
      GoRoute(
        path: '/merchants/payment-result',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, MerchantPaymentResultScreen(args: state.extra! as MerchantPaymentResultArgs)),
      ),
      GoRoute(
        path: '/merchants/:id',
        pageBuilder: (context, state) => _fadeThroughPage(
          state,
          MerchantDetailsScreen(merchantId: state.pathParameters['id']!, wallet: state.extra! as PurposeWalletModel),
        ),
      ),
      GoRoute(
        path: '/merchants/:id/pay',
        pageBuilder: (context, state) {
          final args = state.extra! as MerchantPaymentRouteArgs;
          return _fadeThroughPage(state, MerchantPaymentScreen(merchant: args.merchant, wallet: args.wallet));
        },
      ),
      GoRoute(
        path: '/pay-merchant',
        pageBuilder: (context, state) => _fadeThroughPage(state, const SelectPurposeWalletScreen()),
      ),
      GoRoute(
        path: '/payment-pin/create',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, CreatePaymentPinScreen(args: state.extra! as PaymentPinFlowArgs)),
      ),
      GoRoute(
        path: '/payment-pin/confirm',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, ConfirmPaymentPinScreen(args: state.extra! as ConfirmPaymentPinArgs)),
      ),
      GoRoute(
        path: '/payment-pin/enter',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, EnterPaymentPinScreen(args: state.extra! as PaymentPinFlowArgs)),
      ),
    ],
  );
});
