// lib/views/bills/my_bills_screen.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../services/bill_service.dart';
import '../../theme/app_theme.dart';

class MyBillsScreen extends StatefulWidget {
  const MyBillsScreen({super.key});

  @override
  State<MyBillsScreen> createState() => _MyBillsScreenState();
}

class _MyBillsScreenState extends State<MyBillsScreen> {
  final _service = BillService();

  List<Bill> _bills = [];
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
      _bills = await _service.getBills();
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
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Bills',
                            style: TextStyle(color: Colors.white, fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('Your Speedonet invoices',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
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
                child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  PhosphorIcon(PhosphorIcons.warningCircle(), size: 48, color: AppColors.textLight),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.textGrey),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _load,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ])),
              )
            else if (_bills.isEmpty)
                const SliverFillRemaining(child: _EmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BillCard(
                          bill: _bills[i],
                          onTap: () => _showBillDetail(context, _bills[i]),
                        ),
                      ),
                      childCount: _bills.length,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _showBillDetail(BuildContext context, Bill bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BillDetailSheet(bill: bill),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BILL CARD
// ─────────────────────────────────────────────────────────────────────────────

class _BillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;
  const _BillCard({required this.bill, required this.onTap});

  Color get _statusColor {
    if (bill.isPaid)    return Colors.green;
    if (bill.isOverdue) return AppColors.primary;
    return Colors.orange;
  }

  String get _statusLabel {
    if (bill.isPaid)    return 'Paid';
    if (bill.isOverdue) return 'Overdue';
    return 'Unpaid';
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2),
          )],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                // Icon
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: PhosphorIcon(
                    bill.isPaid
                        ? PhosphorIcons.checkCircle()
                        : PhosphorIcons.receipt(),
                    color: _statusColor, size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Plan + bill number
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.planName ?? 'Speedonet Plan',
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
                        bill.billNumber,
                        style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  '₹${bill.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 12),

            // Bottom row — billing period + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  PhosphorIcon(PhosphorIcons.calendarBlank(),
                      size: 13, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    '${_fmt(bill.billingPeriodStart)} – ${_fmt(bill.billingPeriodEnd)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                  ),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: _statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BILL DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _BillDetailSheet extends StatelessWidget {
  final Bill bill;
  const _BillDetailSheet({required this.bill});

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Color get _statusColor {
    if (bill.isPaid)    return Colors.green;
    if (bill.isOverdue) return AppColors.primary;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  bill.planName ?? 'Speedonet Plan',
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bill.isPaid ? 'Paid' : bill.isOverdue ? 'Overdue' : 'Unpaid',
                  style: TextStyle(
                    color: _statusColor, fontWeight: FontWeight.w700, fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(bill.billNumber,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
          const SizedBox(height: 20),

          // Amount box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              _AmountRow('Base Amount', '₹${bill.baseAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _AmountRow('GST (18%)', '₹${bill.gstAmount.toStringAsFixed(2)}'),
              const Divider(height: 20),
              _AmountRow(
                'Total Amount',
                '₹${bill.totalAmount.toStringAsFixed(2)}',
                bold: true,
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Details rows
          _DetailRow(PhosphorIcons.calendarBlank(), 'Billing Period',
              '${_fmt(bill.billingPeriodStart)} – ${_fmt(bill.billingPeriodEnd)}'),
          const SizedBox(height: 12),
          _DetailRow(PhosphorIcons.calendarCheck(), 'Due Date',
              _fmt(bill.dueDate)),
          if (bill.paidAt != null) ...[
            const SizedBox(height: 12),
            _DetailRow(PhosphorIcons.checkCircle(), 'Paid On',
                _fmt(bill.paidAt!)),
          ],
          const SizedBox(height: 12),
          _DetailRow(PhosphorIcons.receipt(), 'Generated On',
              _fmt(bill.createdAt)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _AmountRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: bold ? AppColors.textDark : AppColors.textGrey,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
          fontSize: bold ? 15 : 13,
        )),
        Text(value, style: TextStyle(
          color: bold ? AppColors.primary : AppColors.textDark,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          fontSize: bold ? 16 : 13,
        )),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  final String value;
  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhosphorIcon(icon, size: 16, color: AppColors.textLight),
        const SizedBox(width: 10),
        Text('$label  ', style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
        Expanded(
          child: Text(value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
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
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: PhosphorIcon(PhosphorIcons.receipt(), size: 48, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text('No Bills Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 8),
          const Text('Your Speedonet invoices will appear here',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}