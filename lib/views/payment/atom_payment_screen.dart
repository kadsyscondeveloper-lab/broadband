// lib/views/payment/atom_payment_screen.dart
//
// Uses the official ntt_atom_flutter SDK.
// The SDK handles:
//   - All encryption (AES + hash)
//   - Opening its own InAppWebView payment screen
//   - Detecting transaction completion
//   - Returning TransactionStatus + raw response data
//
// Our backend:
//   - POST /api/v1/payments/atom/initiate  → creates DB order, returns txnid
//   - POST /api/v1/payments/atom/callback  → Atom webhooks here (credits wallet)
//   - GET  /api/v1/payments/atom/status/:orderRef → Flutter polls this
//
// NOTE: We do NOT pass a returnUrl to the SDK. Per the SDK docs, passing a
// custom returnUrl disables automatic transaction detection. Instead we rely
// on the backend callback (webhook) to credit the wallet, and poll /status
// once the SDK's onClose fires to get the authoritative result.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ntt_atom_flutter/ntt_atom_flutter.dart';
import '../../services/atom_payment_service.dart';
import '../../theme/app_theme.dart';

class AtomPaymentScreen extends StatefulWidget {
  final AtomInitiateResult initiateResult;
  const AtomPaymentScreen({super.key, required this.initiateResult});

  @override
  State<AtomPaymentScreen> createState() => _AtomPaymentScreenState();
}

class _AtomPaymentScreenState extends State<AtomPaymentScreen> {
  final _service = AtomPaymentService();

  bool    _isLaunching = false;
  bool    _isPolling   = false;
  String? _statusMsg;

  // ── Atom credentials from your KAD_syscon_NTT_Details.xlsx ───────────────
  // These are passed directly to the SDK — no server round-trip needed for
  // the checkout itself (the SDK calls Atom's API directly).
  static const _login      = '792811';         // MerchId
  static const _password   = 'fb1489ed';       // Transaction Password
  static const _prodid     = 'SYSCON';         // Product ID
  static const _reqHashKey = '2a63f76ede75f9a022';          // HashRequest Key
  static const _resHashKey = 'e0e6459946dff4c378';          // HashResponse Key
  static const _reqEncKey  = '1CFAC0C7097BD6FAA950892F87B45960'; // AES Req Salt
  static const _resDecKey  = 'D32C2C50D8AC0FD983D7A710C64FB2BD'; // AES Res Salt

  @override
  void initState() {
    super.initState();
    // Launch payment on the next frame so the loading UI renders first
    WidgetsBinding.instance.addPostFrameCallback((_) => _launchPayment());
  }

  Future<void> _launchPayment() async {
    final r = widget.initiateResult;
    if (r.orderRef == null) {
      _finishWith(AtomPaymentResult.failed(''));
      return;
    }

    if (mounted) setState(() => _isLaunching = true);

    final sdk = AtomSDK();

    // checkOut() pushes the SDK's own payment screen onto the navigator.
    // onClose fires when the user completes or cancels payment.
    await sdk.checkOut(
      sdkOptions: AtomPaymentOptions(
        login:                _login,
        password:             _password,
        prodid:               _prodid,
        requestHashKey:       _reqHashKey,
        responseHashKey:      _resHashKey,
        requestEncryptionKey: _reqEncKey,
        responseDecryptionKey:_resDecKey,
        txncurr:              'INR',
        amount:               r.amount ?? '0.00',
        txnid:                r.orderRef!,
        clientcode:           r.orderRef!,   // unique per txn
        custFirstName:        r.custFirstName ?? '',
        custLastName:         r.custLastName  ?? '',
        email:                r.custEmail     ?? '',
        mobile:               r.custMobile    ?? '',
        address:              '',
        custacc:              '0',           // '0' for non-broker merchants
        mode:                 AtomPaymentMode.live,
        // DO NOT set returnUrl — disables SDK's auto transaction detection
      ),
      onClose: (TransactionStatus status, dynamic data) {
        debugPrint('[Atom] onClose status=${status.name} data=$data');
        _handleSdkResult(status, r.orderRef!);
      },
    );

    if (mounted) setState(() => _isLaunching = false);
  }

  void _handleSdkResult(TransactionStatus status, String orderRef) {
    if (status == TransactionStatus.success) {
      // SDK says success — poll backend for authoritative confirmation
      _pollAndFinish(orderRef);
    } else if (status == TransactionStatus.failed) {
      _pollAndFinish(orderRef); // still poll — backend callback may have arrived
    } else {
      // cancelled / unknown — go back immediately
      _finishWith(AtomPaymentResult.cancelled());
    }
  }

  Future<void> _pollAndFinish(String orderRef) async {
    if (!mounted) return;
    setState(() { _isPolling = true; _statusMsg = 'Verifying payment…'; });

    final result = await _service.pollPaymentStatus(
      orderRef,
      maxAttempts: 10,
      delay: const Duration(seconds: 2),
    );

    if (!mounted) return;

    if (result == null) {
      _finishWith(AtomPaymentResult.pending(orderRef));
    } else if (result.isSuccess) {
      _finishWith(AtomPaymentResult.success(
        orderRef:     orderRef,
        amount:       double.tryParse(result.totalAmount) ?? 0,
        gatewayTxnId: result.gatewayTxnId,
      ));
    } else {
      _finishWith(AtomPaymentResult.failed(orderRef));
    }
  }

  void _finishWith(AtomPaymentResult result) {
    if (mounted) Navigator.pop(context, result);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  // This screen just shows a loading/verifying state. The actual payment UI
  // is rendered by the SDK on top of it.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Secure Payment',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: _isPolling
            ? const SizedBox.shrink()
            : IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => _finishWith(AtomPaymentResult.cancelled()),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Row(children: [
              Icon(Icons.lock_outline,
                  color: Colors.white.withOpacity(0.8), size: 16),
              const SizedBox(width: 4),
              Text('SSL',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            _isPolling
                ? (_statusMsg ?? 'Verifying payment…')
                : 'Opening payment gateway…',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: AppColors.textDark),
            textAlign: TextAlign.center,
          ),
          if (_isPolling) ...[
            const SizedBox(height: 8),
            const Text('Please do not close this screen.',
                style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ],
        ]),
      ),
    );
  }
}

// =============================================================================
// Result types (unchanged — zero changes needed in callers)
// =============================================================================

enum AtomPaymentResultType { success, failed, cancelled, pending }

class AtomPaymentResult {
  final AtomPaymentResultType type;
  final String? orderRef;
  final double? amount;
  final String? gatewayTxnId;

  const AtomPaymentResult._({
    required this.type, this.orderRef, this.amount, this.gatewayTxnId,
  });

  factory AtomPaymentResult.success({
    required String orderRef, required double amount, String? gatewayTxnId,
  }) => AtomPaymentResult._(
      type: AtomPaymentResultType.success,
      orderRef: orderRef, amount: amount, gatewayTxnId: gatewayTxnId);

  factory AtomPaymentResult.failed(String orderRef) =>
      AtomPaymentResult._(type: AtomPaymentResultType.failed, orderRef: orderRef);

  factory AtomPaymentResult.cancelled() =>
      const AtomPaymentResult._(type: AtomPaymentResultType.cancelled);

  factory AtomPaymentResult.pending(String orderRef) =>
      AtomPaymentResult._(type: AtomPaymentResultType.pending, orderRef: orderRef);

  bool get isSuccess   => type == AtomPaymentResultType.success;
  bool get isFailed    => type == AtomPaymentResultType.failed;
  bool get isCancelled => type == AtomPaymentResultType.cancelled;
  bool get isPending   => type == AtomPaymentResultType.pending;
}