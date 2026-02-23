// lib/views/wallet/wallet_recharge_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/atom_payment_service.dart';
import '../../theme/app_theme.dart';
import '../payment/atom_payment_screen.dart';

class WalletRechargeScreen extends StatefulWidget {
  final double initialBalance;
  final void Function(double newBalance)? onRechargeSuccess;

  const WalletRechargeScreen({
    super.key,
    required this.initialBalance,
    this.onRechargeSuccess,
  });

  @override
  State<WalletRechargeScreen> createState() => _WalletRechargeScreenState();
}

class _WalletRechargeScreenState extends State<WalletRechargeScreen> {
  final _amountController = TextEditingController();
  final _atomService      = AtomPaymentService();

  bool    _isLoading = false;
  String? _error;

  // Quick-select amounts
  final _quickAmounts = [100, 200, 500, 1000, 2000, 5000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // ── Initiate payment ──────────────────────────────────────────────────────

  Future<void> _startPayment() async {
    final raw    = _amountController.text.trim();
    final amount = double.tryParse(raw);

    if (amount == null || amount < 10) {
      setState(() => _error = 'Minimum recharge amount is ₹10');
      return;
    }
    if (amount > 50000) {
      setState(() => _error = 'Maximum recharge amount is ₹50,000');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    // Step 1 — Get atomTokenId from backend
    final initResult = await _atomService.initiateWalletRecharge(amount);

    if (!mounted) return;

    if (!initResult.success) {
      setState(() { _isLoading = false; _error = initResult.error; });
      return;
    }

    setState(() => _isLoading = false);

    // Step 2 — Open Atom WebView
    final payResult = await Navigator.push<AtomPaymentResult>(
      context,
      MaterialPageRoute(
        builder: (_) => AtomPaymentScreen(initiateResult: initResult),
      ),
    );

    if (!mounted) return;

    // Step 3 — Handle result
    if (payResult == null || payResult.isCancelled) {
      setState(() => _error = 'Payment was cancelled.');
      return;
    }

    if (payResult.isSuccess) {
      final newBalance = widget.initialBalance + (payResult.amount ?? amount);
      widget.onRechargeSuccess?.call(newBalance);
      _showSuccessAndPop(payResult.amount ?? amount);
      return;
    }

    if (payResult.isPending) {
      _showPendingDialog(payResult.orderRef!);
      return;
    }

    // Failed
    setState(() => _error = 'Payment failed. Please try again.');
  }

  void _showSuccessAndPop(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(
                color: Colors.green, shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Payment Successful!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('₹${amount.toStringAsFixed(2)} added to your wallet.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGrey)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close recharge screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Done',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPendingDialog(String orderRef) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Payment Pending'),
        content: Text(
          'We haven\'t received confirmation yet for order $orderRef.\n\n'
              'Your wallet will be credited automatically once the bank confirms. '
              'Usually takes a few minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Recharge Wallet',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Current balance card ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFCC0000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Current Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  '₹${widget.initialBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 28),

            // ── Amount input ─────────────────────────────────────────────
            const Text('Enter Amount',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04),
                      blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (_) => setState(() => _error = null),
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark),
                decoration: const InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 16, right: 4, top: 14),
                    child: Text('₹',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                  prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                  hintText: '0.00',
                  hintStyle: TextStyle(color: AppColors.textLight, fontSize: 22),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
              ),
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: const TextStyle(
                            color: AppColors.primary, fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 24),

            // ── Quick amounts ────────────────────────────────────────────
            const Text('Quick Select',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _quickAmounts.map((amt) {
                final selected = _amountController.text == amt.toString();
                return GestureDetector(
                  onTap: () => setState(() {
                    _amountController.text = amt.toString();
                    _error = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected ? AppColors.primary : AppColors.borderColor),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04),
                            blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      '₹$amt',
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // ── Pay button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Pay Securely',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Payment methods badge ────────────────────────────────────
            Center(
              child: Column(children: [
                const Text('Powered by Atom Payment Gateway',
                    style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['UPI', 'CC', 'DC', 'Net Banking', 'Wallet']
                      .map((m) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Text(m,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w500)),
                  ))
                      .toList(),
                ),
              ]),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}