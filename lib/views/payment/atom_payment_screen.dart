// lib/views/payment/atom_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/atom_payment_service.dart';
import '../../theme/app_theme.dart';

/// Launches the Atom checkout in a WebView.
/// Pops with [AtomPaymentResult] when done.
class AtomPaymentScreen extends StatefulWidget {
  final AtomInitiateResult initiateResult;

  const AtomPaymentScreen({super.key, required this.initiateResult});

  @override
  State<AtomPaymentScreen> createState() => _AtomPaymentScreenState();
}

class _AtomPaymentScreenState extends State<AtomPaymentScreen> {
  late final WebViewController _controller;
  final _service = AtomPaymentService();

  bool _isLoading = true;
  bool _isPolling = false;
  String? _statusMsg;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final r = widget.initiateResult;

    if (r.atomUrl == null || r.encData == null) {
      Navigator.pop(context, AtomPaymentResult.failed(r.orderRef ?? ''));
      return;
    }

    final html = """
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Redirecting...</title>
  </head>
  <body>
    <form id="payForm" method="post" action="${r.atomUrl}">
      <input type="hidden" name="encData" value="${r.encData}" />
    </form>
    <p style="text-align:center;font-family:sans-serif;margin-top:40px;">
      Redirecting to secure payment gateway...
    </p>
    <script>
      window.onload = function() {
        setTimeout(function() {
          document.getElementById('payForm').submit();
        }, 100);
      };
    </script>
  </body>
</html>
""";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('>>> Page started: $url');
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            debugPrint('>>> Page finished: $url');
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint(
                '>>> WebView error: ${error.description} (${error.errorCode})');
          },
          onNavigationRequest: (req) {
            debugPrint('>>> Navigating to: ${req.url}');
            if (req.url.contains('/payments/atom/callback')) {
              _pollAndClose(r.orderRef!);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse('http://103.88.81.7:3000/api/v1/payments/atom/redirect/${r
            .orderRef}'),
        headers: {
          'Authorization': 'Bearer ${widget.initiateResult.authToken}',
        },
      );
  }

  void _handleAtomCallback(String url) {
    final uri = Uri.parse(url.replaceFirst('atomcallback://', 'https://atomcallback/'));
    final status = uri.queryParameters['status'];

    if (status == 'cancel') {
      Navigator.pop(context, AtomPaymentResult.cancelled());
      return;
    }

    _pollAndClose(widget.initiateResult.orderRef!);
  }

  Future<void> _pollAndClose(String orderRef) async {
    if (_isPolling) return;
    setState(() {
      _isPolling = true;
      _statusMsg = 'Verifying payment…';
    });

    final status = await _service.pollPaymentStatus(orderRef);

    if (!mounted) return;

    if (status == null) {
      Navigator.pop(context, AtomPaymentResult.pending(orderRef));
    } else if (status.isSuccess) {
      Navigator.pop(context, AtomPaymentResult.success(
        orderRef: orderRef,
        amount: double.tryParse(status.totalAmount) ?? 0,
        gatewayTxnId: status.gatewayTxnId,
      ));
    } else {
      Navigator.pop(context, AtomPaymentResult.failed(orderRef));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Secure Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Cancel Payment?'),
                content: const Text('Are you sure you want to cancel this payment?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context, AtomPaymentResult.cancelled());
                    },
                    child: const Text(
                      'Yes, Cancel',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          // Page loading indicator
          if (_isLoading && !_isPolling)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // Polling overlay
          if (_isPolling)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        _statusMsg ?? 'Verifying payment…',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Result model returned to the caller ──────────────────────────────────────

enum AtomPaymentResultType { success, failed, cancelled, pending }

class AtomPaymentResult {
  final AtomPaymentResultType type;
  final String? orderRef;
  final double? amount;
  final String? gatewayTxnId;

  const AtomPaymentResult._({
    required this.type,
    this.orderRef,
    this.amount,
    this.gatewayTxnId,
  });

  factory AtomPaymentResult.success({
    required String orderRef,
    required double amount,
    String? gatewayTxnId,
  }) =>
      AtomPaymentResult._(
        type: AtomPaymentResultType.success,
        orderRef: orderRef,
        amount: amount,
        gatewayTxnId: gatewayTxnId,
      );

  factory AtomPaymentResult.failed(String orderRef) =>
      AtomPaymentResult._(type: AtomPaymentResultType.failed, orderRef: orderRef);

  factory AtomPaymentResult.cancelled() =>
      const AtomPaymentResult._(type: AtomPaymentResultType.cancelled);

  factory AtomPaymentResult.pending(String orderRef) =>
      AtomPaymentResult._(type: AtomPaymentResultType.pending, orderRef: orderRef);

  bool get isSuccess => type == AtomPaymentResultType.success;
  bool get isFailed => type == AtomPaymentResultType.failed;
  bool get isCancelled => type == AtomPaymentResultType.cancelled;
  bool get isPending => type == AtomPaymentResultType.pending;
}