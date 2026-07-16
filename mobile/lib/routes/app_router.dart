import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/merchant_model.dart';
import '../models/personal_payment_receiver_model.dart';
import '../models/purpose_wallet_model.dart';
import '../models/qr_validation_model.dart';
import '../models/scheduled_payment_model.dart';
import '../providers/auth_provider.dart';
import '../screens/analytics/analytics_dashboard_screen.dart';
import '../screens/analytics/insights_screen.dart';
import '../screens/analytics/monthly_report_screen.dart';
import '../screens/analytics/purpose_wallet_analytics_screen.dart';
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
import '../screens/merchant/demo_merchant_qr_screen.dart';
import '../screens/merchant/demo_qr_generator_screen.dart';
import '../screens/merchant/enter_payment_pin_screen.dart';
import '../screens/merchant/merchant_details_screen.dart';
import '../screens/merchant/merchant_list_screen.dart';
import '../screens/merchant/merchant_payment_result_screen.dart';
import '../screens/merchant/merchant_payment_screen.dart';
import '../screens/merchant/qr_merchant_preview_screen.dart';
import '../screens/merchant/qr_payment_confirm_screen.dart';
import '../screens/merchant/qr_scanner_screen.dart';
import '../screens/merchant/select_purpose_wallet_screen.dart';
import '../screens/personal_payment/my_qr_screen.dart';
import '../screens/personal_payment/personal_payment_confirm_screen.dart';
import '../screens/personal_payment/personal_payment_preview_screen.dart';
import '../screens/personal_payment/search_results_screen.dart';
import '../screens/personal_payment/search_user_screen.dart';
import '../screens/profile/developer_tools_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/schedule/create_schedule_screen.dart';
import '../screens/schedule/edit_schedule_screen.dart';
import '../screens/schedule/schedule_details_screen.dart';
import '../screens/schedule/schedule_execution_history_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/schedule/select_merchant_screen.dart';
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
                pageBuilder: (context, state) => _fadeThroughPage(state, const AnalyticsDashboardScreen()),
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
        pageBuilder: (context, state) {
          // Extra is a QrValidationModel only when arriving from
          // QrMerchantPreviewScreen's Continue button; null for the plain
          // Dashboard "Pay Merchant" entry point (unchanged default).
          final validation = state.extra as QrValidationModel?;
          return _fadeThroughPage(
            state,
            SelectPurposeWalletScreen(
              onSelect: validation == null
                  ? null
                  : (context, wallet) => context.push(
                        '/qr/confirm',
                        extra: QrPaymentConfirmArgs(validation: validation, wallet: wallet),
                      ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/merchants/:id/qr',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, DemoMerchantQrScreen(merchant: state.extra! as MerchantModel)),
      ),
      GoRoute(
        path: '/qr/scan',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, QrScannerScreen(preselectedWallet: state.extra as PurposeWalletModel?)),
      ),
      GoRoute(
        path: '/qr/preview',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, QrMerchantPreviewScreen(args: state.extra! as QrPreviewRouteArgs)),
      ),
      GoRoute(
        path: '/qr/confirm',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, QrPaymentConfirmScreen(args: state.extra! as QrPaymentConfirmArgs)),
      ),
      GoRoute(
        path: '/my-qr',
        pageBuilder: (context, state) => _fadeThroughPage(state, const MyQrScreen()),
      ),
      GoRoute(
        path: '/personal-payment/search',
        pageBuilder: (context, state) => _fadeThroughPage(state, const SearchUserScreen()),
      ),
      GoRoute(
        path: '/personal-payment/search-results',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, SearchResultsScreen(phone: state.extra! as String)),
      ),
      GoRoute(
        path: '/personal-payment/preview',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, PersonalPaymentPreviewScreen(args: state.extra! as PersonalPaymentScanArgs)),
      ),
      GoRoute(
        path: '/personal-payment/select-wallet',
        pageBuilder: (context, state) {
          final receiver = state.extra! as PersonalPaymentReceiverModel;
          return _fadeThroughPage(
            state,
            SelectPurposeWalletScreen(
              onSelect: (context, wallet) => context.push(
                '/personal-payment/confirm',
                extra: PersonalPaymentConfirmArgs(receiver: receiver, wallet: wallet),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/personal-payment/confirm',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, PersonalPaymentConfirmScreen(args: state.extra! as PersonalPaymentConfirmArgs)),
      ),
      GoRoute(
        path: '/profile/developer-tools',
        pageBuilder: (context, state) => _fadeThroughPage(state, const DeveloperToolsScreen()),
      ),
      GoRoute(
        path: '/profile/developer-tools/demo-qr',
        pageBuilder: (context, state) => _fadeThroughPage(state, const DemoQrGeneratorScreen()),
      ),
      // Every static /schedule/... route MUST be declared before
      // /schedule/:id below — same static-before-dynamic discipline as
      // /merchants/payment-result vs /merchants/:id (see that comment above).
      GoRoute(
        path: '/schedule/create',
        pageBuilder: (context, state) => _fadeThroughPage(state, const CreateScheduleScreen()),
      ),
      GoRoute(
        path: '/schedule/create/select-merchant',
        pageBuilder: (context, state) => _fadeThroughPage(state, const SelectMerchantScreen()),
      ),
      GoRoute(
        path: '/schedule/create/select-receiver',
        pageBuilder: (context, state) => _fadeThroughPage(
          state,
          QrScannerScreen(onPersonalReceiverSelected: (receiver) => context.pop(receiver)),
        ),
      ),
      GoRoute(
        path: '/schedule/:id',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, ScheduleDetailsScreen(scheduleId: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/schedule/:id/edit',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, EditScheduleScreen(schedule: state.extra! as ScheduledPaymentModel)),
      ),
      GoRoute(
        path: '/schedule/:id/executions',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, ScheduleExecutionHistoryScreen(scheduleId: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/analytics/wallets',
        pageBuilder: (context, state) => _fadeThroughPage(state, const PurposeWalletAnalyticsScreen()),
      ),
      GoRoute(
        path: '/analytics/report',
        pageBuilder: (context, state) => _fadeThroughPage(state, const MonthlyReportScreen()),
      ),
      GoRoute(
        path: '/analytics/insights',
        pageBuilder: (context, state) => _fadeThroughPage(state, const InsightsScreen()),
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
