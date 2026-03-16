// lib/services/atom_payment_service.dart
//
// Payment Gateway (Omniware / KAD SYSCON) integration
// Replaces old Atom logic — keeping same class/method names so no other files break

import 'package:dio/dio.dart';
import '../core/api_client.dart';

// ── Initiate result ───────────────────────────────────────────────────────────

class AtomInitiateResult {
  final String  orderRef;
  final String  amount;
  final String  paymentUrl;  // unique PG payment page URL
  final String? uuid;
  final String? expiresAt;

  const AtomInitiateResult({
    required this.orderRef,
    required this.amount,
    required this.paymentUrl,
    this.uuid,
    this.expiresAt,
  });

  factory AtomInitiateResult.fromJson(Map<String, dynamic> json) {
    return AtomInitiateResult(
      orderRef:   json['orderRef']   as String? ?? '',
      amount:     json['amount']     as String? ?? '0.00',
      paymentUrl: json['paymentUrl'] as String? ?? '',
      uuid:       json['uuid']       as String?,
      expiresAt:  json['expiresAt']  as String?,
    );
  }
}

// ── Payment status result ─────────────────────────────────────────────────────

class AtomPaymentStatus {
  final String  orderRef;
  final String  paymentStatus; // 'pending' | 'success' | 'failed'
  final String  totalAmount;
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
  bool get isFailed  => paymentStatus == 'failed';

  factory AtomPaymentStatus.fromJson(Map<String, dynamic> json) {
    final o = json['order'] as Map<String, dynamic>? ?? json;
    return AtomPaymentStatus(
      orderRef:       (o['order_ref']        ?? '').toString(),
      paymentStatus:  (o['payment_status']   ?? '').toString(),
      totalAmount:    (o['total_amount']     ?? '0').toString(),
      gatewayTxnId:   o['gateway_txn_id']?.toString(),
      gatewayOrderId: o['gateway_order_id']?.toString(),
    );
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class AtomPaymentService {
  // Singleton
  static final AtomPaymentService _i = AtomPaymentService._();
  factory AtomPaymentService() => _i;
  AtomPaymentService._();

  final _api = ApiClient();

  /// POST /api/v1/payments/pg/initiate
  /// Used for wallet top-ups (wallet recharge screen).
  Future<AtomInitiateResult?> initiateWalletRecharge(double amount) async {
    return _initiate(amount);
  }

  /// POST /api/v1/payments/pg/initiate
  /// Used for plan purchases (recharge screen).
  Future<AtomInitiateResult?> initiateRecharge(double amount) async {
    return _initiate(amount);
  }

  Future<AtomInitiateResult?> _initiate(double amount) async {
    try {
      final response = await _api.post(
        '/payments/pg/initiate',
        data: {'amount': amount},
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return AtomInitiateResult.fromJson(data);
      }
      return null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET /api/v1/payments/pg/status/:orderRef
  /// Polls until status is no longer 'pending', up to [maxAttempts] times.
  Future<AtomPaymentStatus?> pollPaymentStatus(
      String orderRef, {
        int maxAttempts = 12,
        Duration delay = const Duration(seconds: 2),
      }) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final response = await _api.get(
          '/payments/pg/status/$orderRef',
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