// lib/services/wallet_service.dart
import 'package:dio/dio.dart';
import '../core/api_client.dart';

class WalletTransaction {
  final int id;
  final String type;        // credit | debit
  final double amount;
  final double balanceAfter;
  final String description;
  final String? orderRef;
  final String? paymentMethod;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    this.orderRef,
    this.paymentMethod,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> j) => WalletTransaction(
    id:            j['id']           as int,
    type:          j['type']         as String,
    amount:        (j['amount'] as num).toDouble(),
    balanceAfter:  (j['balance_after'] as num).toDouble(),
    description:   j['description']  as String? ?? '',
    orderRef:      j['order_ref']    as String?,
    paymentMethod: j['payment_method'] as String?,
    createdAt:     DateTime.parse(j['created_at'] as String),
  );
}

class RechargeResult {
  final bool    success;
  final String? error;
  final double? newBalance;
  final String? orderRef;

  const RechargeResult({required this.success, this.error, this.newBalance, this.orderRef});
}

class WalletService {
  static final WalletService _i = WalletService._();
  factory WalletService() => _i;
  WalletService._();

  final _api = ApiClient();

  Future<double> getBalance() async {
    final res = await _api.get('/wallet/balance');
    return (res.data['data']['balance'] as num).toDouble();
  }

  Future<List<WalletTransaction>> getTransactions({int page = 1, int limit = 20}) async {
    final res = await _api.get('/wallet/transactions', params: {'page': page, 'limit': limit});
    final list = res.data['data']['transactions'] as List<dynamic>;
    return list.map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Recharge the wallet.
  /// [paymentMethod]: 'upi' | 'card' | 'netbanking'
  /// In production, pass gatewayOrderId and gatewayTxnId after gateway confirms.
  Future<RechargeResult> recharge({
    required double amount,
    required String paymentMethod,
    String? gatewayOrderId,
    String? gatewayTxnId,
  }) async {
    try {
      final res = await _api.post('/wallet/recharge', data: {
        'amount':           amount,
        'payment_method':   paymentMethod,
        if (gatewayOrderId != null) 'gateway_order_id': gatewayOrderId,
        if (gatewayTxnId   != null) 'gateway_txn_id':   gatewayTxnId,
      });
      final data = res.data['data'] as Map<String, dynamic>;
      return RechargeResult(
        success:    true,
        newBalance: (data['balance_after'] as num).toDouble(),
        orderRef:   data['order_ref'] as String?,
      );
    } on DioException catch (e) {
      return RechargeResult(
        success: false,
        error:   ApiException.fromDio(e).message,
      );
    } catch (e) {
      return RechargeResult(success: false, error: e.toString());
    }
  }
}