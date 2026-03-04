// lib/views/payments/payments_screen.dart

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/plan_model.dart';
import '../../services/plan_service.dart';
import '../../theme/app_theme.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _service = PlanService();

  List<PlanTransaction> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _transactions = await _service.getTransactions();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20, right: 20, bottom: 24,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft:  Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment History',
                        style: TextStyle(color: Colors.white, fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('All your Speedonet plan transactions',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/no_transactions.png',
                        width: 160, height: 160,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: const TextStyle(color: AppColors.textGrey),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        child: const Text('Retry',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              )
            else if (_transactions.isEmpty)
                const SliverFillRemaining(child: _EmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TransactionCard(tx: _transactions[i]),
                      ),
                      childCount: _transactions.length,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRANSACTION CARD
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final PlanTransaction tx;
  const _TransactionCard({required this.tx});

  // Status chip color (success / failed / pending)
  Color get _statusColor {
    switch (tx.paymentStatus) {
      case 'success': return Colors.green;
      case 'failed':  return Colors.red;
      default:        return Colors.orange;
    }
  }

  // Icon color based on what the transaction IS, not just credit/debit
  Color get _iconColor {
    switch (tx.referenceType) {
      case 'wallet_recharge': return Colors.green;
      case 'payment_order':   return AppColors.primary;
      case 'refund':          return Colors.teal;
      default:
        return tx.isCredit ? Colors.green : AppColors.primary;
    }
  }

  // Icon based on transaction type — much more descriptive than +/−
  dynamic get _typeIcon {
    switch (tx.referenceType) {
      case 'wallet_recharge':
      // Money coming into wallet
        return PhosphorIcons.wallet(PhosphorIconsStyle.fill);
      case 'payment_order':
      // Plan purchase / internet payment
        return PhosphorIcons.wifiHigh(PhosphorIconsStyle.fill);
      case 'refund':
      // Money returned
        return PhosphorIcons.arrowCounterClockwise(PhosphorIconsStyle.fill);
      default:
      // Fallback: directional arrow based on credit/debit
        return tx.isCredit
            ? PhosphorIcons.arrowCircleDown(PhosphorIconsStyle.fill)
            : PhosphorIcons.arrowCircleUp(PhosphorIconsStyle.fill);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date    = tx.createdAt;
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ── Icon avatar ─────────────────────────────────────────────
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _iconColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: PhosphorIcon(_typeIcon, color: _iconColor, size: 22),
              ),
              const SizedBox(width: 12),

              // ── Title + date ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.planName ?? tx.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$dateStr at $timeStr',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Amount ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 58),
            child: Text(
              tx.amountLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: tx.isCredit ? Colors.green : AppColors.textDark,
              ),
            ),
          ),

          // ── Chips ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 58),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (tx.paymentStatus != null)
                  _Chip(label: tx.paymentStatus!, color: _statusColor),
                if (tx.referenceType != null)
                  _Chip(label: tx.referenceType!, color: AppColors.textLight),
                if (tx.orderRef != null)
                  _Chip(label: tx.orderRef!, color: AppColors.textLight),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color  color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 9, color: color, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset(
            'assets/images/no_transactions.png',
            width:  160,
            height: 160,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          const Text(
            'No transactions yet',
            style: TextStyle(
                fontSize:   18,
                fontWeight: FontWeight.w700,
                color:      AppColors.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your plan purchases will appear here',
            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}