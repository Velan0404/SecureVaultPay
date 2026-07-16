import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/primary_button.dart';

/// Dashboard "Pay" (Person -> Person) entry point — collects a mobile
/// number the exact same way register_screen.dart does (fixed +91 prefix
/// shown as static UI, only the 10-digit national number is typed), then
/// hands the fully-formatted +91XXXXXXXXXX number to SearchResultsScreen,
/// which performs the actual lookup.
class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _search() {
    if (!_formKey.currentState!.validate()) return;
    final phone = '+91${_phoneController.text.trim()}';
    context.push('/personal-payment/search-results', extra: phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: FadeSlideIn(
          child: Form(
            key: _formKey,
            child: PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.primaryRed.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.person_search_outlined, color: AppColors.primaryRed, size: 28),
                  ),
                  const SizedBox(height: 20),
                  Text('Send money to a person', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text(
                    "Enter their registered mobile number to find their SecureVault Pay account.",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _phoneController,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      hintText: '9876543210',
                      prefixIcon: Icon(Icons.phone_outlined),
                      // Fixed, non-editable country code — same convention
                      // as Register's mobile number field.
                      prefixText: '+91  ',
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length != 10) {
                        return 'Enter a valid 10-digit mobile number.';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _search(),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(label: 'Search', onPressed: _search),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
