import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_providers.dart';

final walletServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return WalletService(dio);
});

final walletBalanceProvider = FutureProvider((ref) async {
  return ref.watch(walletServiceProvider).getBalance();
});

final walletTransactionsProvider = FutureProvider((ref) async {
  return ref.watch(walletServiceProvider).getTransactions();
});

class WalletService {
  final Dio _dio;

  WalletService(this._dio);

  Future<Map<String, dynamic>> getBalance() async {
    final response = await _dio.get('wallet/balance');
    return response.data;
  }

  Future<List<dynamic>> getTransactions() async {
    final response = await _dio.get('wallet/transactions');
    return response.data;
  }
}
