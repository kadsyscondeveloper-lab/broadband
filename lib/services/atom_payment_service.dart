 // lib/services/atom_payment_service.dart
import '../core/api_client.dart';
import '../core/app_config.dart';

// ── Initiate response model ───────────────────────────────────────────────────

class AtomInitiateResult {
  final String? orderRef;
  final String? amount;
  final String? custEmail;
  final String? custMobile;
  final String? custFirstName;
  final String? custLastName;
  final String? authToken;

  const AtomInitiateResult({
    this.orderRef,
    this.amount,
    this.custEmail,
    this.custMobile,
    this.custFirstName,
    this.custLastName,
    this.authToken,
  });

  factory AtomInitiateResult.fromJson(Map<String, dynamic> json) {
    return AtomInitiateResult(
      orderRef:      json['orderRef']      as String?,
      amount:        json['amount']        as String?,
      custEmail:     json['custEmail']     as String?,
      custMobile:    json['custMobile']    as String?,
      custFirstName: json['custFirstName'] as String?,
      custLastName:  json['custLastName']  as String?,
      authToken:     json['authToken']     as String?,
    );
  }
}
  
// ── Payment status model ──────────────────────────────────────────────────────

class AtomPaymentStatus {
  final String orderRef;
  final String paymentStatus;
  final String totalAmount;
  final String? gatewayTxnId;
  final String? gatewayOrderId;

  const AtomPaymentStatus({
    required this.orderRef,
    required this.paymentStatus,
    required this.totalAmount,
    this.gatewayTxnId,
    this.gatewayOrderId,
  });

  bool get isSuccess => paymentStatus == 'success';
  bool get isPending => paymentStatus == 'pending';

  factory AtomPaymentStatus.fromJson(Map<String, dynamic> json) {
    final o = json['order'] as Map<String, dynamic>? ?? json;
    return AtomPaymentStatus(
      orderRef:       (o['order_ref']        ?? '').toString(),
      paymentStatus:  (o['payment_status']   ?? '').toString(),
      totalAmount:    (o['total_amount']      ?? '0').toString(),
      gatewayTxnId:   o['gateway_txn_id']?.toString(),
      gatewayOrderId: o['gateway_order_id']?.toString(),
    );
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class AtomPaymentService {
  final _api = ApiClient();

  /// POST /api/v1/payments/atom/initiate
  /// Used for plan purchases (recharge screen).
  Future<AtomInitiateResult?> initiateRecharge(double amount) async {
    return _initiate(amount);
  }

  /// POST /api/v1/payments/atom/initiate
  /// Used for wallet top-ups (wallet recharge screen).
  /// Alias for [initiateRecharge] — both hit the same endpoint.
  Future<AtomInitiateResult?> initiateWalletRecharge(double amount) async {
    return _initiate(amount);
  }

  Future<AtomInitiateResult?> _initiate(double amount) async {
    try {
      final response = await _api.post(
        '${AppConfig.baseUrl}/payments/atom/initiate',
        data: {'amount': amount},
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return AtomInitiateResult.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// GET /api/v1/payments/atom/status/:orderRef
  /// Polls until status is no longer 'pending', up to [maxAttempts] times.
  Future<AtomPaymentStatus?> pollPaymentStatus(
      String orderRef, {
        int maxAttempts = 10,
        Duration delay = const Duration(seconds: 2),
      }) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final response = await _api.get(
          '${AppConfig.baseUrl}/payments/atom/status/$orderRef',
        );

        if (response.data['success'] == true) {
          final status = AtomPaymentStatus.fromJson(
            response.data['data'] as Map<String, dynamic>,
          );
          if (!status.isPending) return status;
        }
      } catch (_) {}

      if (i < maxAttempts - 1) {
        await Future.delayed(delay);
      }
    }
    return null; // still pending after all attempts
  }
}