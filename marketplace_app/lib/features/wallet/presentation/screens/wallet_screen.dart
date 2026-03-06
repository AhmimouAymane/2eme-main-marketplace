import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/wallet_service.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Portefeuille'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.cloviGreen,
        elevation: 0,
      ),
      body: balanceAsync.when(
        data: (data) {
          final double balance = (data['balance'] ?? 0.0).toDouble();
          final int orderCount = data['orderCount'] ?? 0;

          return RefreshIndicator(
            onRefresh: () => ref.refresh(walletBalanceProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildBalanceCard(balance, orderCount),
                const SizedBox(height: 32),
                const Text(
                  'Historique des ventes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cloviGreen,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTransactionList(ref),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildBalanceCard(double balance, int orderCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cloviGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.cloviGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Solde disponible',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '${balance.toStringAsFixed(2)} DH',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '$orderCount ventes confirmées',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(WidgetRef ref) {
    final transactionsAsync = ref.watch(walletTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'Aucune vente encore confirmée.',
                style: TextStyle(color: AppColors.textSecondaryLight),
              ),
            ),
          );
        }

        return Column(
          children: transactions.map((t) => _buildTransactionItem(t)).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text('Erreur chargement transactions'),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(dynamic transaction) {
    final double amount = (transaction['totalPrice'] ?? 0.0).toDouble()
        - (transaction['serviceFee'] ?? 0.0).toDouble()
        - (transaction['shippingFee'] ?? 0.0).toDouble();
    final product = transaction['product'];
    final String title = product != null ? product['title'] : 'Produit';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cloviGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: AppColors.cloviGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Vente confirmée',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '+ ${amount.toStringAsFixed(2)} DH',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.cloviGreen,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
