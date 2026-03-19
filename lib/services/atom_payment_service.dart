// lib/services/atom_payment_service.dart

import 'package:dio/dio.dart';
import '../core/api_client.dart';

class AtomInitiateResult {
  final String  orderRef;
  final String  amount;
  final String  paymentUrl;
  final String  gateway;      // 'omniware' or 'atom'
  final String? uuid;
  final String? expiresAt;
  final String? custName;
  final String? custEmail;
  final String? custMobile;

  const AtomInitiateResult({
    required this.orderRef,
    required this.amount,
    required this.paymentUrl,
    required this.gateway,
    this.uuid,
    this.expiresAt,
    this.custName,
    this.custEmail,
    this.custMobile,
  });

  bool get isAtom     => gateway == 'atom';
  bool get isOmniware => gateway == 'omniware';

  factory AtomInitiateResult.fromJson(Map<String, dynamic> json) {
    return AtomInitiateResult(
      orderRef:   json['orderRef']    as String? ?? '',
      amount:     json['amount']      as String? ?? '0.00',
      paymentUrl: json['paymentUrl']  as String? ?? '',
      gateway:    json['gateway']     as String? ?? 'omniware',
      uuid:       json['uuid']        as String?,
      expiresAt:  json['expiresAt']   as String?,
      custName:   json['custName']    as String?,
      custEmail:  json['custEmail']   as String?,
      custMobile: json['custMobile']  as String?,
    );
  }
}

class AtomPaymentStatus {
  final String  orderRef;
  final String  paymentStatus;
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

class AtomPaymentService {
  static final AtomPaymentService _i = AtomPaymentService._();
  factory AtomPaymentService() => _i;
  AtomPaymentService._();

  final _api = ApiClient();

  /// POST /api/v1/payments/pg/initiate
  ///
  /// [gateway] — 'omniware' (default/live) or 'atom' (UAT/test)
  Future<AtomInitiateResult?> initiateWalletRecharge(
      double amount, {
        String gateway = 'omniware',
      }) async {
    try {
      final response = await _api.post(
        '/payments/pg/initiate',
        data: {
          'amount':  amount,
          'gateway': gateway,
        },
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

  /// Alias for backward compatibility
  Future<AtomInitiateResult?> initiateRecharge(double amount) async {
    return initiateWalletRecharge(amount);
  }

  /// GET /api/v1/payments/pg/status/:orderRef
  Future<AtomPaymentStatus?> pollPaymentStatus(
      String orderRef, {
        int maxAttempts = 12,
        Duration delay = const Duration(seconds: 2),
      }) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final response = await _api.get('/payments/pg/status/$orderRef');
        if (response.data['success'] == true) {
          final status = AtomPaymentStatus.fromJson(
              response.data['data'] as Map<String, dynamic>);
          if (!status.isPending) return status;
        }
      } catch (_) {}
      if (i < maxAttempts - 1) await Future.delayed(delay);
    }
    return null;
  }
}