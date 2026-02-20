// lib/views/wallet/wallet_recharge_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/wallet_service.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/wallet_viewmodel.dart';

class WalletRechargeScreen extends StatefulWidget {
  /// Pass the current balance in so we can display it immediately
  /// while the VM fetches the freshest value.
  final double initialBalance;
  /// Called when recharge succeeds — lets the parent refresh the balance display.
  final ValueChanged<double>? onRechargeSuccess;

  const WalletRechargeScreen({
    super.key,
    this.initialBalance = 0.0,
    this.onRechargeSuccess,
  });

  @override
  State<WalletRechargeScreen> createState() => _WalletRechargeScreenState();
}

class _WalletRechargeScreenState extends State<WalletRechargeScreen> {
  final _vm             = WalletViewModel();
  final _customCtrl     = TextEditingController();
  String _paymentMethod = 'upi';
  bool   _useCustom     = false;

  @override
  void initState() {
    super.initState();
    _vm.loadBalance();
    _vm.loadTransactions();
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    _vm.dispose();
    super.dispose();
  }

  void _selectPreset(double amount) {
    setState(() => _useCustom = false);
    _customCtrl.clear();
    _vm.setAmount(amount);
  }

  void _onCustomAmountChanged(String value) {
    final parsed = double.tryParse(value) ?? 0;
    _vm.setAmount(parsed);
  }

  Future<void> _pay() async {
    // ── GATEWAY HOOK ────────────────────────────────────────────────────────
    // When you integrate Razorpay:
    //   1. Call your backend to create a Razorpay order: POST /wallet/recharge/initiate
    //   2. Open Razorpay checkout with the returned order_id
    //   3. On success, call _vm.recharge() with the gateway IDs
    //
    // For now, auto-confirms.
    // ────────────────────────────────────────────────────────────────────────
    await _vm.recharge(paymentMethod: _paymentMethod);

    if (!mounted) return;
    if (_vm.rechargeState == RechargeState.success) {
      widget.onRechargeSuccess?.call(_vm.newBalance ?? 0.0);
      _showSuccess();
    }
  }

  void _showSuccess() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _SuccessSheet(
        amount:   _vm.selectedAmount,
        balance:  _vm.newBalance ?? 0.0,
        orderRef: _vm.lastOrderRef ?? '',
        onDone: () {
          Navigator.pop(context); // close sheet
          _vm.resetRechargeState();
          _vm.loadTransactions(); // refresh list
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Add Money'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Wallet balance banner ──────────────────────────
                      _WalletBalanceBanner(
                        balance: _vm.balanceLoading
                            ? widget.initialBalance
                            : _vm.balance,
                        isLoading: _vm.balanceLoading,
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Amount presets ─────────────────────────
                            const Text(
                              'Select Amount',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                ..._vm.customAmountPresets.map((amt) {
                                  final isSelected = !_useCustom &&
                                      _vm.selectedAmount == amt;
                                  return _AmountChip(
                                    label: '₹${amt.toStringAsFixed(0)}',
                                    isSelected: isSelected,
                                    onTap: () => _selectPreset(amt),
                                  );
                                }),
                                _AmountChip(
                                  label: 'Custom',
                                  isSelected: _useCustom,
                                  onTap: () {
                                    setState(() => _useCustom = true);
                                    _vm.setAmount(0);
                                    _customCtrl.clear();
                                  },
                                ),
                              ],
                            ),

                            // ── Custom amount input ────────────────────
                            if (_useCustom) ...[
                              const SizedBox(height: 16),
                              _CustomAmountField(
                                controller: _customCtrl,
                                onChanged: _onCustomAmountChanged,
                              ),
                            ],

                            // ── Amount summary ─────────────────────────
                            if (_vm.selectedAmount >= 10) ...[
                              const SizedBox(height: 20),
                              _AmountSummaryCard(amount: _vm.selectedAmount),
                            ],

                            const SizedBox(height: 28),

                            // ── Payment method ─────────────────────────
                            const Text(
                              'Pay via',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _PayMethodOption(
                              value: 'upi',
                              selected: _paymentMethod,
                              icon: Icons.phone_android_outlined,
                              label: 'UPI',
                              subtitle: 'PhonePe, GPay, Paytm & more',
                              onTap: () => setState(() => _paymentMethod = 'upi'),
                            ),
                            const SizedBox(height: 8),
                            _PayMethodOption(
                              value: 'card',
                              selected: _paymentMethod,
                              icon: Icons.credit_card_outlined,
                              label: 'Debit / Credit Card',
                              subtitle: 'Visa, Mastercard, RuPay & more',
                              onTap: () => setState(() => _paymentMethod = 'card'),
                            ),
                            const SizedBox(height: 8),
                            _PayMethodOption(
                              value: 'net_banking',
                              selected: _paymentMethod,
                              icon: Icons.account_balance_outlined,
                              label: 'Net Banking',
                              subtitle: 'All major Indian banks',
                              onTap: () => setState(() => _paymentMethod = 'net_banking'),
                            ),

                            // ── Error banner ───────────────────────────
                            if (_vm.rechargeState == RechargeState.error) ...[
                              const SizedBox(height: 16),
                              _ErrorBanner(message: _vm.rechargeError ?? 'Something went wrong'),
                            ],

                            const SizedBox(height: 20),

                            // ── Transaction history ────────────────────
                            if (_vm.transactions.isNotEmpty) ...[
                              const Text(
                                'Recent Transactions',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._vm.transactions.take(5).map(
                                    (tx) => _TransactionRow(tx: tx),
                              ),
                            ],

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Pay button ─────────────────────────────────────────────
              _PayButton(
                amount:    _vm.selectedAmount,
                isLoading: _vm.isRecharging,
                enabled:   _vm.selectedAmount >= 10 && !_vm.isRecharging,
                onTap:     _pay,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WALLET BALANCE BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _WalletBalanceBanner extends StatelessWidget {
  final double balance;
  final bool   isLoading;

  const _WalletBalanceBanner({required this.balance, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Wallet Balance',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          isLoading
              ? const SizedBox(
            height: 36,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
          )
              : Text(
            '₹${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add money to pay for plans instantly',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AMOUNT CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _AmountChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AmountChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color:        isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color:      isSelected ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize:   14,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM AMOUNT FIELD
// ─────────────────────────────────────────────────────────────────────────────

class _CustomAmountField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>  onChanged;

  const _CustomAmountField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: TextField(
        controller:       controller,
        onChanged:        onChanged,
        keyboardType:     TextInputType.number,
        inputFormatters:  [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
        decoration: const InputDecoration(
          prefixText:      '₹ ',
          prefixStyle:     TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
          hintText:        'Enter amount',
          hintStyle:       TextStyle(color: AppColors.textLight, fontSize: 18),
          border:          InputBorder.none,
          contentPadding:  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AMOUNT SUMMARY CARD
// ─────────────────────────────────────────────────────────────────────────────

class _AmountSummaryCard extends StatelessWidget {
  final double amount;
  const _AmountSummaryCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('You will add',
              style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT METHOD OPTION
// ─────────────────────────────────────────────────────────────────────────────

class _PayMethodOption extends StatelessWidget {
  final String   value, selected, label, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PayMethodOption({
    required this.value,
    required this.selected,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.primary : AppColors.textDark,
                    fontSize: 14,
                  )),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.textGrey, fontSize: 11)),
            ]),
          ),
          if (isSelected)
            const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRANSACTION ROW
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionRow extends StatelessWidget {
  final WalletTransaction tx;
  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.type == 'credit';
    final color    = isCredit ? Colors.green : AppColors.textDark;
    final date     = tx.createdAt;
    final dateStr  =
        '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            tx.description,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13,
                color: AppColors.textDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(dateStr,
              style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
        ])),
        Text(
          '${isCredit ? '+' : '-'}₹${tx.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: color,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAY BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _PayButton extends StatelessWidget {
  final double amount;
  final bool   isLoading;
  final bool   enabled;
  final VoidCallback onTap;

  const _PayButton({
    required this.amount,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:         AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.35),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 2,
            shadowColor: AppColors.primary.withOpacity(0.4),
          ),
          child: isLoading
              ? const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5),
          )
              : Text(
            amount >= 10
                ? 'Add ₹${amount.toStringAsFixed(0)} to Wallet'
                : 'Select an Amount',
            style: const TextStyle(
              color:      Colors.white,
              fontWeight: FontWeight.w800,
              fontSize:   16,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          child: Text(message,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUCCESS BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  final double amount;
  final double balance;
  final String orderRef;
  final VoidCallback onDone;

  const _SuccessSheet({
    required this.amount,
    required this.balance,
    required this.orderRef,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Success icon
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9), shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 50),
        ),
        const SizedBox(height: 20),
        const Text('Money Added!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark)),
        const SizedBox(height: 8),
        Text(
          '₹${amount.toStringAsFixed(2)} has been added to your wallet',
          style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            _SummaryRow(label: 'Amount Added',
                value: '₹${amount.toStringAsFixed(2)}',
                valueColor: Colors.green),
            const Divider(height: 20),
            _SummaryRow(label: 'New Balance',
                value: '₹${balance.toStringAsFixed(2)}',
                isBold: true),
            const Divider(height: 20),
            _SummaryRow(label: 'Reference', value: orderRef,
                valueColor: AppColors.textGrey),
          ]),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Done',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
        ),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textGrey, fontSize: 13)),
        Text(value,
            style: TextStyle(
              color:      valueColor ?? AppColors.textDark,
              fontSize:   13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            )),
      ],
    );
  }
}