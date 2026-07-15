import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/wallet_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/wallet_transaction_tile.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(walletProvider.notifier).loadTransactions());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(walletProvider.notifier).loadMoreTransactions();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: state.isLoadingTransactions && state.transactions.isEmpty
          ? const LoadingScreen()
          : state.transactions.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No transactions yet',
                      message: 'Demo money loads and wallet transfers will show up here.',
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(walletProvider.notifier).loadTransactions(),
                  color: AppColors.primaryRed,
                  backgroundColor: AppColors.surface,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: state.transactions.length + (state.nextTransactionCursor != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.transactions.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: LoadingIndicator(size: 22)),
                        );
                      }
                      return WalletTransactionTile(transaction: state.transactions[index]);
                    },
                  ),
                ),
    );
  }
}
