// lib/services/atom_payment_service.dart
import 'package:dio/dio.dart';
import '../core/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class AtomInitiateResult {
  final bool success;
  final String? atomUrl;
  final String? encData;
  final String? orderRef;
  final String? amount;
  final String? error;

  const AtomInitiateResult({
    required this.success,
    this.atomUrl,
    this.encData,
    this.orderRef,
    this.amount,
    this.error,
  });
}

class AtomPaymentStatus {
  final String orderRef;
  final String status;
  final String totalAmount;
  final String? gatewayTxnId;

  const AtomPaymentStatus({
    required this.orderRef,
    required this.status,
    required this.totalAmount,
    this.gatewayTxnId,
  });

  bool get isSuccess => status == 'success';
  bool get isPending => status == 'pending';
  bool get isFailed  => status == 'failed';

  factory AtomPaymentStatus.fromJson(Map<String, dynamic> j) =>
      AtomPaymentStatus(
        orderRef:     j['order_ref']      as String,
        status:       j['payment_status'] as String,
        totalAmount:  j['total_amount']   as String,
        gatewayTxnId: j['gateway_txn_id'] as String?,
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class AtomPaymentService {
  static final AtomPaymentService _i = AtomPaymentService._();
  factory AtomPaymentService() => _i;
  AtomPaymentService._();

  final _api = ApiClient();

  /// Step 1 — Call backend to create pending order and get encData.
  Future<AtomInitiateResult> initiateWalletRecharge(double amount) async {
    try {
      final res = await _api.post(
        '/payments/atom/initiate',
        data: {'amount': amount},
      );

      final data = res.data['data'] as Map<String, dynamic>;

      return AtomInitiateResult(
        success:  true,
        atomUrl:  data['atomUrl']  as String?,
        encData:  data['encData']  as String?,
        orderRef: data['orderRef'] as String?,
        amount:   data['amount']   as String?,
      );
    } on DioException catch (e) {
      return AtomInitiateResult(
        success: false,
        error: e.response?.data?['message'] as String? ??
            'Failed to initiate payment',
      );
    } catch (e) {
      return AtomInitiateResult(success: false, error: e.toString());
    }
  }

  /// Step 3 — Poll backend for payment result after WebView closes.
  Future<AtomPaymentStatus?> pollPaymentStatus(
      String orderRef, {
        int maxAttempts = 8,
        Duration delay = const Duration(seconds: 2),
      }) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final res   = await _api.get('/payments/atom/status/$orderRef');
        final order = res.data['data']['order'] as Map<String, dynamic>;
        final status = AtomPaymentStatus.fromJson(order);

        if (status.isSuccess || status.isFailed) return status;

        await Future.delayed(delay);
      } catch (_) {
        await Future.delayed(delay);
      }
    }
    return null;
  }
}