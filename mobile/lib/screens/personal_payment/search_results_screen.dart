import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../models/personal_payment_receiver_model.dart';
import '../../providers/personal_payment_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/primary_button.dart';
import 'personal_payment_preview_screen.dart';

/// Performs `GET /personal-payment/search?phone=...` for the number
/// SearchUserScreen collected, and shows either the found account (with a
/// Continue into the existing Personal Payment Preview/Select Wallet/Confirm/
/// Payment PIN flow — nothing new is built for the payment itself) or the
/// "No SecureVault Pay account found." empty state.
class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  bool _isLoading = true;
  bool _notFound = false;
  String? _errorMessage;
  PersonalPaymentReceiverModel? _receiver;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _notFound = false;
      _errorMessage = null;
    });
    try {
      final receiver = await ref.read(personalPaymentProvider.notifier).searchByPhone(widget.phone);
      if (mounted) setState(() => _receiver = receiver);
    } on AppException catch (e) {
      if (mounted) {
        if (e.code == 'RECEIVER_NOT_FOUND') {
          setState(() => _notFound = true);
        } else {
          setState(() => _errorMessage = e.message);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Results')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const LoadingScreen()
            : _notFound
                ? Center(
                    child: EmptyState(
                      icon: Icons.person_off_outlined,
                      title: 'No SecureVault Pay account found.',
                      message: 'Double-check the mobile number and try again.',
                      onRetry: () => context.pop(),
                      retryLabel: 'Search Again',
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: EmptyState(
                          icon: Icons.error_outline,
                          title: 'Something went wrong',
                          message: _errorMessage!,
                          onRetry: _search,
                        ),
                      )
                    : _buildFound(_receiver!),
      ),
    );
  }

  Widget _buildFound(PersonalPaymentReceiverModel receiver) {
    return FadeSlideIn(
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.primaryRed.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Text(
                    receiver.fullName.isNotEmpty ? receiver.fullName[0].toUpperCase() : 'S',
                    style: const TextStyle(color: AppColors.primaryRed, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(receiver.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      if (receiver.maskedPhoneNumber != null)
                        Text(receiver.maskedPhoneNumber!, style: const TextStyle(color: AppColors.textSecondary)),
                      if (receiver.secureVaultId != null)
                        Text(
                          receiver.secureVaultId!,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, letterSpacing: 0.5),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Continue',
              onPressed: () => context.push('/personal-payment/preview', extra: PersonalPaymentScanArgs(receiver: receiver)),
            ),
          ],
        ),
      ),
    );
  }
}
