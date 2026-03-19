// lib/views/payment/atom_payment_screen.dart
//
// Handles BOTH gateways:
//   Omniware → opens paymentUrl in WebView
//   Atom     → uses NTT Atom Flutter SDK (ntt_atom_flutter)

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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

  // ── WebView state (Omniware only) ─────────────────────────────────────────
  late final WebViewController _webViewController;
  bool   _isLoading     = true;
  bool   _isPolling     = false;
  bool   _resultHandled = false;
  String _statusMsg     = 'Opening payment gateway…';
  double _loadProgress  = 0;

  static const _callbackPath     = '/api/v1/payments/pg/callback';
  static const _atomCallbackPath = '/api/v1/payments/atom/callback';

  // ── Atom SDK credentials ──────────────────────────────────────────────────
  // static const _atomLogin      = '317159';
  // static const _atomPassword   = 'Test@123';
  // static const _atomProdId     = 'NSE';
  // static const _atomReqHashKey = 'KEY123657234';
  // static const _atomResHashKey = 'KEYRESP123657234';
  // static const _atomReqEncKey  = 'A4476C2062FFA58980DC8F79EB6A799E';
  // static const _atomResDecKey  = '75AEF0FA1B94B3C10D4F5B268F757F11';
  // static const _atomMccCode    = '4814';
  static const _atomLogin      = '792811';
  static const _atomPassword   = 'fb1489ed';
  static const _atomProdId     = 'SYSCON';
  static const _atomReqHashKey = '2a63f76ede75f9a022';
  static const _atomResHashKey = 'e0e6459946dff4c378';
  static const _atomReqEncKey  = '1CFAC0C7097BD6FAA950892F87B45960';
  static const _atomResDecKey  = 'D32C2C50D8AC0FD983D7A710C64FB2BD';
  static const _atomMccCode    = '7372';

  static const _atomMerchType  = 'R';
  // Atom POSTs result here → backend processes it → credits wallet
  // Change this to your production URL when going live
  static const _atomReturnUrl  = 'https://unworshipping-kathrin-parablastic.ngrok-free.dev/api/v1/payments/atom/callback';

  @override
  void initState() {
    super.initState();

    if (widget.initiateResult.isAtom) {
      // Launch Atom SDK on next frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _launchAtomSdk());
    } else {
      // Init WebView for Omniware
      _initWebView();
    }
  }

  // ── Atom SDK flow ─────────────────────────────────────────────────────────

  void _launchAtomSdk() {
    final r = widget.initiateResult;
    if (r.orderRef.isEmpty) {
      _finishWith(AtomPaymentResult.failed(''));
      return;
    }

    final fullName  = r.custName ?? '';
    final spaceIdx  = fullName.indexOf(' ');
    final firstName = spaceIdx == -1 ? fullName : fullName.substring(0, spaceIdx);
    final lastName  = spaceIdx == -1 ? '' : fullName.substring(spaceIdx + 1);

    final sdk = AtomSDK();
    sdk.checkOut(
      sdkOptions: AtomPaymentOptions(
        login:                _atomLogin,
        password:             _atomPassword,
        prodid:               _atomProdId,
        requestHashKey:       _atomReqHashKey,
        responseHashKey:      _atomResHashKey,
        requestEncryptionKey: _atomReqEncKey,
        responseDecryptionKey: _atomResDecKey,
        txncurr:              'INR',
        amount:               r.amount,
        txnid:                r.orderRef,
        clientcode:           r.orderRef,
        custFirstName:        firstName,
        custLastName:         lastName,
        email:                r.custEmail ?? '',
        mobile:               r.custMobile ?? '',
        address:              '',
        custacc:              '0',
        mccCode:              _atomMccCode,
        merchType:            _atomMerchType,
        mode:                 AtomPaymentMode.live,
        // returnUrl tells Atom to POST result to our backend
        // SDK won't auto-detect status but backend gets webhook → credits wallet
        // We then poll /status to confirm from Flutter side
        returnUrl:            _atomReturnUrl,
      ),
      onClose: (transactionStatus, data) {
        debugPrint('[Atom SDK] onClose status=${transactionStatus.name} data=$data');
        // Always poll backend — returnUrl means SDK status is unreliable
        // but backend will have received the webhook by now
        _pollAndFinish(r.orderRef);
      },
    );
  }

  // ── Omniware WebView flow ─────────────────────────────────────────────────

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() { _isLoading = true; _loadProgress = 0; });
            _checkCallbackUrl(url);
          },
          onPageFinished: (url) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            _checkCallbackUrl(url);
          },
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _loadProgress = progress / 100);
          },
          onWebResourceError: (error) {
            if (!mounted || _resultHandled) return;
            if (error.isForMainFrame ?? true) {
              setState(() => _isLoading = false);
            }
          },
          onNavigationRequest: (request) {
            if (_isCallbackUrl(request.url)) {
              _handleCallbackUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initiateResult.paymentUrl));
  }

  bool _isCallbackUrl(String url) =>
      url.contains(_callbackPath) || url.contains(_atomCallbackPath);

  void _checkCallbackUrl(String url) {
    if (_isCallbackUrl(url) && !_resultHandled) {
      _handleCallbackUrl(url);
    }
  }

  void _handleCallbackUrl(String url) {
    if (_resultHandled) return;
    _resultHandled = true;

    final uri          = Uri.tryParse(url);
    final responseCode = uri?.queryParameters['response_code'];
    final orderRef     = widget.initiateResult.orderRef;

    if (responseCode == '0') {
      _pollAndFinish(orderRef);
    } else if (responseCode != null && responseCode != '0') {
      _finishWith(AtomPaymentResult.failed(orderRef));
    } else {
      _pollAndFinish(orderRef);
    }
  }

  // ── Shared polling ────────────────────────────────────────────────────────

  Future<void> _pollAndFinish(String orderRef) async {
    if (!mounted) return;
    setState(() { _isPolling = true; _statusMsg = 'Verifying payment…'; });

    final result = await _service.pollPaymentStatus(
      orderRef,
      maxAttempts: 12,
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

  void _onBackPressed() {
    if (_isPolling) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Are you sure you want to cancel?\n\n'
              'If you have already paid, your wallet will be credited automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue', style: TextStyle(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _finishWith(AtomPaymentResult.cancelled());
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Atom SDK manages its own UI — show loading/polling overlay only
    if (widget.initiateResult.isAtom) {
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
                Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.8), size: 16),
                const SizedBox(width: 4),
                Text('SSL', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              _isPolling ? _statusMsg : 'Opening NTT Atom payment…',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
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

    // Omniware — full WebView
    return WillPopScope(
      onWillPop: () async {
        if (_isPolling) return false;
        _onBackPressed();
        return false;
      },
      child: Scaffold(
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
            onPressed: _onBackPressed,
          ),
          bottom: _isLoading && !_isPolling
              ? PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: LinearProgressIndicator(
              value: _loadProgress > 0 ? _loadProgress : null,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 3,
            ),
          )
              : null,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Row(children: [
                Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.8), size: 16),
                const SizedBox(width: 4),
                Text('SSL', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ),
        body: _isPolling ? _buildPollingOverlay() : WebViewWidget(controller: _webViewController),
      ),
    );
  }

  Widget _buildPollingOverlay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(_statusMsg,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text('Please do not close this screen.',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// =============================================================================
// Result types
// =============================================================================

enum AtomPaymentResultType { success, failed, cancelled, pending }

class AtomPaymentResult {
  final AtomPaymentResultType type;
  final String? orderRef;
  final double? amount;
  final String? gatewayTxnId;

  const AtomPaymentResult._({required this.type, this.orderRef, this.amount, this.gatewayTxnId});

  factory AtomPaymentResult.success({required String orderRef, required double amount, String? gatewayTxnId}) =>
      AtomPaymentResult._(type: AtomPaymentResultType.success, orderRef: orderRef, amount: amount, gatewayTxnId: gatewayTxnId);

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