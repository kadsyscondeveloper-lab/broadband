// lib/views/wallet/wallet_recharge_confirm_screen.dart
//
// Confirmation screen shown BEFORE opening the Payment Gateway WebView.
// Displays a receipt-style breakdown of the recharge.
// User taps "Proceed to Pay" → initiates payment → opens PG WebView.

import 'package:flutter/material.dart';
import '../../services/atom_payment_service.dart';
import '../../theme/app_theme.dart';
import '../payment/atom_payment_screen.dart';

class WalletRechargeConfirmScreen extends StatefulWidget {
  final double amount;
  final double currentBalance;
  final void Function(double newBalance)? onRechargeSuccess;

  const WalletRechargeConfirmScreen({
    super.key,
    required this.amount,
    required this.currentBalance,
    this.onRechargeSuccess,
  });

  @override
  State<WalletRechargeConfirmScreen> createState() =>
      _WalletRechargeConfirmScreenState();
}

class _WalletRechargeConfirmScreenState
    extends State<WalletRechargeConfirmScreen>
    with SingleTickerProviderStateMixin {
  final _service = AtomPaymentService();

  bool    _isLoading = false;
  String? _error;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Initiate payment ──────────────────────────────────────────────────────

  Future<void> _proceedToPay() async {
    setState(() { _isLoading = true; _error = null; });

    final initResult = await _service.initiateWalletRecharge(widget.amount);

    if (!mounted) return;

    if (initResult == null || initResult.paymentUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Unable to initiate payment. Please try again.';
      });
      return;
    }

    setState(() => _isLoading = false);

    final payResult = await Navigator.push<AtomPaymentResult>(
      context,
      MaterialPageRoute(
        builder: (_) => AtomPaymentScreen(initiateResult: initResult),
      ),
    );

    if (!mounted) return;

    if (payResult == null || payResult.isCancelled) {
      setState(() => _error = 'Payment was cancelled.');
      return;
    }

    if (payResult.isSuccess) {
      final newBalance =
          widget.currentBalance + (payResult.amount ?? widget.amount);
      widget.onRechargeSuccess?.call(newBalance);
      _showSuccessAndPop(payResult.amount ?? widget.amount);
      return;
    }

    if (payResult.isPending) {
      _showPendingDialog(payResult.orderRef ?? '');
      return;
    }

    setState(() => _error = 'Payment failed. Please try again.');
  }

  void _showSuccessAndPop(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon with ripple rings
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.green, shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 34),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Payment Successful!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(2)} has been added\nto your Speedonet wallet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  height: 1.5),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'New Balance: ₹${(widget.currentBalance + amount).toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.green),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close confirm screen
                Navigator.pop(context); // close recharge screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Done',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
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
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_top_rounded,
                color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('Payment Pending',
              style:
              TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: Text(
          'We haven\'t received confirmation yet'
              '${orderRef.isNotEmpty ? ' for order\n$orderRef' : ''}.\n\n'
              'Your wallet will be credited automatically once the bank confirms. '
              'This usually takes a few minutes.',
          style: const TextStyle(
              fontSize: 13, color: AppColors.textGrey, height: 1.55),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK, Got it',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double balanceAfter = widget.currentBalance + widget.amount;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Confirm Payment',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header label ──────────────────────────────────────
                const Text('Review your recharge',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGrey,
                        letterSpacing: 0.4)),
                const SizedBox(height: 14),

                // ── Receipt card ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [

                      // ── Top — wallet icon + amount ──────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 28, horizontal: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.82),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                        ),
                        child: Column(children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 28),
                          ),
                          const SizedBox(height: 14),
                          const Text('Wallet Recharge',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Text(
                            '₹${widget.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ]),
                      ),

                      // ── Divider with dashed cut ─────────────────────
                      _DashedDivider(),

                      // ── Receipt rows ────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                        child: Column(children: [
                          _ReceiptRow(
                            label: 'Recharge Amount',
                            value:
                            '₹${widget.amount.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 14),
                          _ReceiptRow(
                            label: 'Processing Fee',
                            value: '₹0.00',
                            valueColor: Colors.green,
                          ),
                          const SizedBox(height: 14),
                          _ReceiptRow(
                            label: 'GST / Tax',
                            value: '₹0.00',
                            valueColor: Colors.green,
                          ),
                          const SizedBox(height: 18),

                          // Divider
                          Container(
                            height: 1,
                            color: const Color(0xFFEEEEF5),
                          ),
                          const SizedBox(height: 18),

                          // Total row
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Payable',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A1A2E))),
                              Text(
                                '₹${widget.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ]),
                      ),

                      // ── Divider ─────────────────────────────────────
                      const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF0F0F7),
                          indent: 24,
                          endIndent: 24),

                      // ── Balance section ─────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: Column(children: [
                          _ReceiptRow(
                            label: 'Current Balance',
                            value:
                            '₹${widget.currentBalance.toStringAsFixed(2)}',
                            labelStyle: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 10),
                          _ReceiptRow(
                            label: 'Balance After Recharge',
                            value:
                            '₹${balanceAfter.toStringAsFixed(2)}',
                            labelStyle: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w500),
                            valueColor: Colors.green,
                            valueFontWeight: FontWeight.w700,
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Payment gateway badge ─────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEEEEF5)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shield_rounded,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Secured by Omniware',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E))),
                          const SizedBox(height: 2),
                          Text(
                            'PCI-DSS compliant · 256-bit SSL encryption',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 12),

                // Payment method icons row
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEEEEF5)),
                  ),
                  child: Row(children: [
                    const Text('Pay via',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: ['UPI', 'CC', 'DC', 'Net Banking']
                            .map((m) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                            const Color(0xFFF4F6FB),
                            borderRadius:
                            BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(
                                    0xFFE0E0EE)),
                          ),
                          child: Text(m,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3D4066))),
                        ))
                            .toList(),
                      ),
                    ),
                  ]),
                ),

                // Error message
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500)),
                      ),
                    ]),
                  ),
                ],

                const SizedBox(height: 32),

                // ── Proceed button ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _proceedToPay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                      AppColors.primary.withOpacity(0.55),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      shadowColor: AppColors.primary.withOpacity(0.35),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Proceed to Pay  ₹${widget.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cancel link
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Helper widgets
// =============================================================================

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueFontWeight;
  final TextStyle? labelStyle;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueFontWeight,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: labelStyle ??
                const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: valueFontWeight ?? FontWeight.w600,
                color: valueColor ?? const Color(0xFF1A1A2E))),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: List.generate(
          30,
              (i) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 1.5,
              color: i.isEven
                  ? const Color(0xFFE0E0EE)
                  : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}