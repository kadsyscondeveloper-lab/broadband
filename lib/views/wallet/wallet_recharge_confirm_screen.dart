// lib/views/wallet/wallet_recharge_confirm_screen.dart

import 'package:flutter/material.dart';
import '../../services/atom_payment_service.dart';
import '../../theme/app_theme.dart';
import '../payment/atom_payment_screen.dart';

enum _Gateway { omniware, atom }

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

  _Gateway _selectedGateway = _Gateway.omniware;
  bool     _isLoading       = false;
  String?  _error;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Initiate ──────────────────────────────────────────────────────────────

  Future<void> _proceedToPay() async {
    setState(() { _isLoading = true; _error = null; });

    final initResult = await _service.initiateWalletRecharge(
      widget.amount,
      gateway: _selectedGateway == _Gateway.atom ? 'atom' : 'omniware',
    );

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
      final newBalance = widget.currentBalance + (payResult.amount ?? widget.amount);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(alignment: Alignment.center, children: [
            Container(width: 80, height: 80,
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), shape: BoxShape.circle)),
            Container(width: 64, height: 64,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 34)),
          ]),
          const SizedBox(height: 20),
          const Text('Payment Successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Text('₹${amount.toStringAsFixed(2)} has been added\nto your Speedonet wallet.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Text('New Balance: ₹${(widget.currentBalance + amount).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.green)),
          ),
        ]),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Done',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 20)),
          const SizedBox(width: 10),
          const Text('Payment Pending', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: Text(
          'We haven\'t received confirmation yet${orderRef.isNotEmpty ? ' for order\n$orderRef' : ''}.\n\n'
              'Your wallet will be credited automatically once the bank confirms.',
          style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.55),
        ),
        actions: [
          SizedBox(width: double.infinity,
            child: TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); Navigator.pop(context); },
              child: const Text('OK, Got it',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
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

                // ── Receipt card ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))],
                  ),
                  child: Column(children: [

                    // top gradient header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withOpacity(0.82)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 14),
                        const Text('Wallet Recharge',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text('₹${widget.amount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1)),
                      ]),
                    ),

                    _DashedDivider(),

                    // receipt rows
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Column(children: [
                        _ReceiptRow(label: 'Recharge Amount', value: '₹${widget.amount.toStringAsFixed(2)}'),
                        const SizedBox(height: 14),
                        _ReceiptRow(label: 'Processing Fee', value: '₹0.00', valueColor: Colors.green),
                        const SizedBox(height: 14),
                        _ReceiptRow(label: 'GST / Tax', value: '₹0.00', valueColor: Colors.green),
                        const SizedBox(height: 18),
                        Container(height: 1, color: const Color(0xFFEEEEF5)),
                        const SizedBox(height: 18),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Total Payable',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                          Text('₹${widget.amount.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
                        ]),
                      ]),
                    ),

                    const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F7), indent: 24, endIndent: 24),

                    // balance rows
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(children: [
                        _ReceiptRow(
                          label: 'Current Balance',
                          value: '₹${widget.currentBalance.toStringAsFixed(2)}',
                          labelStyle: const TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        _ReceiptRow(
                          label: 'Balance After Recharge',
                          value: '₹${balanceAfter.toStringAsFixed(2)}',
                          labelStyle: const TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                          valueColor: Colors.green,
                          valueFontWeight: FontWeight.w700,
                        ),
                      ]),
                    ),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── Gateway selection ─────────────────────────────────
                const Text('Pay via',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.textGrey, letterSpacing: 0.3)),
                const SizedBox(height: 12),

                Row(children: [
                  // Omniware
                  Expanded(
                    child: _GatewayCard(
                      selected:  _selectedGateway == _Gateway.omniware,
                      logoAsset: 'assets/images/omniware.png',
                      name:      'Omniware',
                      tag:       'Live',
                      tagColor:  Colors.green,
                      features:  'UPI · Cards · Net Banking\nWallets & more',
                      onTap: () => setState(() => _selectedGateway = _Gateway.omniware),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // NTT Atom
                  Expanded(
                    child: _GatewayCard(
                      selected:  _selectedGateway == _Gateway.atom,
                      logoAsset: 'assets/images/atom.png',
                      name:      'NTT Atom',
                      tag:       'Live',
                      tagColor:  Colors.blue,
                      features:  'CC · DC · UPI\nNet Banking',
                      onTap: () => setState(() => _selectedGateway = _Gateway.atom),
                    ),
                  ),
                ]),

                const SizedBox(height: 14),

                // ── Info strip ────────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _selectedGateway == _Gateway.omniware
                      ? _InfoStrip(
                    key: const ValueKey('omni'),
                    icon: Icons.shield_rounded,
                    iconColor: Colors.green,
                    title: 'Secured by Omniware',
                    subtitle: 'PCI-DSS compliant · 256-bit SSL · Live payments',
                  )
                      : _InfoStrip(
                    key: const ValueKey('atom'),
                    icon: Icons.shield_rounded,
                    iconColor: Colors.blue,
                    title: 'Secured by NTT Atom',
                    subtitle: 'PCI-DSS compliant · 256-bit SSL · Live payments',
                  ),
                ),

                // ── Error ─────────────────────────────────────────────
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_error!,
                          style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w500))),
                    ]),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Pay button ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _proceedToPay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      shadowColor: AppColors.primary.withOpacity(0.35),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Pay ₹${widget.amount.toStringAsFixed(2)} · '
                              '${_selectedGateway == _Gateway.omniware ? 'Omniware' : 'NTT Atom'}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
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

class _GatewayCard extends StatelessWidget {
  final bool       selected;
  final String     logoAsset;
  final String     name;
  final String     tag;
  final Color      tagColor;
  final String     features;
  final VoidCallback onTap;

  const _GatewayCard({
    required this.selected, required this.logoAsset,
    required this.name, required this.tag,
    required this.tagColor, required this.features, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // Fixed height so both cards are always equal
        height: 175,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE8E8F0),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: logo + checkmark
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo in a clean white box — fixed 52×52 so both are identical size
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEF5), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    logoAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.payment_rounded,
                      size: 24,
                      color: tagColor,
                    ),
                  ),
                ),
                // Checkmark
                AnimatedOpacity(
                  opacity: selected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Gateway name
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.primary : const Color(0xFF1A1A2E),
              ),
            ),

            const SizedBox(height: 3),

            // Features
            Text(
              features,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),

            const Spacer(),

            // Live/UAT badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tagColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: tagColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final String   subtitle;

  const _InfoStrip({super.key, required this.icon, required this.iconColor, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEF5)),
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.10), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
        ])),
      ]),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueFontWeight;
  final TextStyle? labelStyle;

  const _ReceiptRow({required this.label, required this.value, this.valueColor, this.valueFontWeight, this.labelStyle});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: labelStyle ?? const TextStyle(fontSize: 14, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: valueFontWeight ?? FontWeight.w600, color: valueColor ?? const Color(0xFF1A1A2E))),
    ]);
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: List.generate(30, (i) => Expanded(
          child: Container(margin: const EdgeInsets.symmetric(horizontal: 2), height: 1.5,
              color: i.isEven ? const Color(0xFFE0E0EE) : Colors.transparent),
        )),
      ),
    );
  }
}