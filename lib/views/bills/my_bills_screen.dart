// lib/views/bills/my_bills_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/bill_service.dart';
import '../../theme/app_theme.dart';

class MyBillsScreen extends StatefulWidget {
  const MyBillsScreen({super.key});

  @override
  State<MyBillsScreen> createState() => _MyBillsScreenState();
}

class _MyBillsScreenState extends State<MyBillsScreen> {
  final _service = BillService();

  List<Bill> _bills   = [];
  bool       _loading = true;
  String?    _error;
  String     _filter  = 'All';

  static const _filters = ['All', 'Unpaid', 'Paid'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _bills = await _service.getBills();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Bill> get _filtered {
    switch (_filter) {
      case 'Paid':   return _bills.where((b) => b.isPaid).toList();
      case 'Unpaid': return _bills.where((b) => !b.isPaid).toList();
      default:       return _bills;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── Pure red header ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.primary,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft:  Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color:  Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('My Bills',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800)),
                              SizedBox(height: 2),
                              Text('Your Speedonet invoices',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13)),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _filters.map((f) {
                              final active = f == _filter;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () => setState(() => _filter = f),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: active
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(f,
                                        style: TextStyle(
                                          color: active
                                              ? AppColors.primary
                                              : Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize:   13,
                                        )),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Body ───────────────────────────────────────────────────
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(
                    color: AppColors.primary)),
              )
            else if (_error != null)
              SliverFillRemaining(
                  child: _ErrorState(error: _error!, onRetry: _load))
            else if (_filtered.isEmpty)
                SliverFillRemaining(child: _EmptyState(filter: _filter))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _BillCard(
                          bill: _filtered[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  _BillDetailScreen(bill: _filtered[i]),
                            ),
                          ),
                        ),
                      ),
                      childCount: _filtered.length,
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
// BILL CARD
// ─────────────────────────────────────────────────────────────────────────────

class _BillCard extends StatelessWidget {
  final Bill         bill;
  final VoidCallback onTap;
  const _BillCard({required this.bill, required this.onTap});

  _StatusStyle get _s {
    if (bill.isPaid) return const _StatusStyle(
      label: 'PAID', color: Color(0xFF2E7D32),
      bg: Color(0xFFE8F5E9), icon: Icons.check_circle_rounded,
    );
    if (bill.isOverdue) return _StatusStyle(
      label: 'OVERDUE', color: AppColors.primary,
      bg: const Color(0xFFFFECEF), icon: Icons.error_rounded,
    );
    return const _StatusStyle(
      label: 'UNPAID', color: Color(0xFFED6C02),
      bg: Color(0xFFFFF3E0), icon: Icons.schedule_rounded,
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16, offset: const Offset(0, 4),
          )],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: s.bg, shape: BoxShape.circle),
                  child: Icon(s.icon, color: s.color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bill.planName ?? 'Speedonet Plan',
                        style: const TextStyle(fontWeight: FontWeight.w800,
                            fontSize: 16, color: Color(0xFF1F1A1B))),
                    const SizedBox(height: 3),
                    Text(bill.billNumber,
                        style: const TextStyle(fontSize: 11,
                            color: Color(0xFF857375), fontWeight: FontWeight.w500)),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: s.bg, borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(s.label, style: TextStyle(
                      color: s.color, fontSize: 10,
                      fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.isOverdue ? 'DUE DATE' : 'BILLING PERIOD',
                      style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w800,
                          color: bill.isOverdue ? AppColors.primary
                              : const Color(0xFF857375),
                          letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bill.isOverdue
                          ? _fmt(bill.dueDate)
                          : '${_fmt(bill.billingPeriodStart)} – ${_fmt(bill.billingPeriodEnd)}',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: bill.isOverdue ? AppColors.primary
                              : const Color(0xFF1F1A1B)),
                    ),
                    if (bill.hasCoupon) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:  Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.local_offer_rounded,
                              size: 10, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(bill.couponCode!,
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  color: Colors.green.shade700,
                                  letterSpacing: 0.5)),
                        ]),
                      ),
                    ],
                  ],
                )),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('AMOUNT', style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w800,
                      color: Color(0xFF857375), letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text('₹${bill.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18,
                          fontWeight: FontWeight.w900, color: Color(0xFF1F1A1B))),
                  if (bill.hasCoupon) ...[
                    const SizedBox(height: 2),
                    Text('-₹${bill.discountAmount.toStringAsFixed(2)} saved',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                            color: Colors.green.shade700)),
                  ],
                ]),
              ],
            ),
          ),
          if (bill.isOverdue)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Pay Now', style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700,
                      fontSize: 14)),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BILL DETAIL — FULL SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _BillDetailScreen extends StatelessWidget {
  final Bill bill;
  const _BillDetailScreen({required this.bill});

  String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day.toString().padLeft(2,'0')} ${m[d.month-1]}, ${d.year}';
  }

  Color    get _sc  {
    if (bill.isPaid)    return const Color(0xFF2E7D32);
    if (bill.isOverdue) return AppColors.primary;
    return const Color(0xFFED6C02);
  }
  Color    get _sbg {
    if (bill.isPaid)    return const Color(0xFFE8F5E9);
    if (bill.isOverdue) return const Color(0xFFFFECEF);
    return const Color(0xFFFFF3E0);
  }
  String   get _sl  {
    if (bill.isPaid)    return 'PAID';
    if (bill.isOverdue) return 'OVERDUE';
    return 'UNPAID';
  }
  IconData get _si  {
    if (bill.isPaid)    return Icons.check_circle_rounded;
    if (bill.isOverdue) return Icons.error_rounded;
    return Icons.schedule_rounded;
  }

  // Amount before discount
  double get _subTotal => bill.baseAmount + bill.gstAmount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(children: [
        // ── Pure red header ──────────────────────────────────────────
        Container(
          color: AppColors.primary,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color:  Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My Bills', style: TextStyle(
                        color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(bill.planName ?? 'Speedonet Plan',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ],
                )),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: bill.billNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:  Text('Invoice number copied'),
                          duration: Duration(seconds: 1)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color:  Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.copy_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ),
          ),
        ),

        // ── Scrollable content ───────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: Column(children: [

              // Hero amount card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color:  _sbg,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _sc.withOpacity(0.2)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_si, color: _sc, size: 14),
                      const SizedBox(width: 5),
                      Text(_sl, style: TextStyle(color: _sc, fontSize: 11,
                          fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Text('₹${bill.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1F1A1B), height: 1)),
                  const SizedBox(height: 6),
                  const Text('TOTAL AMOUNT', style: TextStyle(
                      fontSize: 10, color: Color(0xFFAA9999),
                      fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                ]),
              ),
              const SizedBox(height: 16),

              // Breakdown card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  _BreakRow('Base Amount',
                      '₹${bill.baseAmount.toStringAsFixed(2)}'),
                  Divider(height: 1, color: Colors.grey.shade100,
                      indent: 20, endIndent: 20),
                  _BreakRow('GST (18%)',
                      '₹${bill.gstAmount.toStringAsFixed(2)}'),

                  // ── Coupon section ──────────────────────────────────
                  if (bill.hasCoupon) ...[
                    Divider(height: 1, color: Colors.grey.shade100,
                        indent: 20, endIndent: 20),
                    _BreakRow('Sub-total',
                        '₹${_subTotal.toStringAsFixed(2)}'),
                    Divider(height: 1, color: Colors.grey.shade100,
                        indent: 20, endIndent: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color:  Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.local_offer_rounded,
                                  size: 14, color: Colors.green.shade700),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Coupon Discount',
                                    style: TextStyle(
                                        fontSize:   13,
                                        color:      Colors.green.shade700,
                                        fontWeight: FontWeight.w600)),
                                Text(bill.couponCode!,
                                    style: TextStyle(
                                        fontSize:      10,
                                        color:         Colors.green.shade600,
                                        fontWeight:    FontWeight.w800,
                                        letterSpacing: 0.8)),
                              ],
                            ),
                          ]),
                          Text('-₹${bill.discountAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize:   16,
                                  fontWeight: FontWeight.w700,
                                  color:      Colors.green.shade700)),
                        ],
                      ),
                    ),
                  ],

                  Divider(height: 1, color: Colors.grey.shade100),
                  // Total payable row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: const BorderRadius.only(
                        bottomLeft:  Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL PAYABLE', style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800,
                            color: AppColors.primary, letterSpacing: 0.8)),
                        Text('₹${bill.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Timeline card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.event_repeat_rounded,
                            color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text('LIFECYCLE & TIMELINE', style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800,
                          color: Color(0xFF4C212F), letterSpacing: 1)),
                    ]),
                    const SizedBox(height: 24),
                    _Timeline(items: [
                      _TItem(label: 'BILLING PERIOD',
                          value: '${_fmt(bill.billingPeriodStart)} – ${_fmt(bill.billingPeriodEnd)}',
                          dotColor: Colors.grey.shade400, filled: false),
                      _TItem(label: 'DUE DATE',
                          value: _fmt(bill.dueDate),
                          dotColor: AppColors.primary.withOpacity(0.7),
                          filled: false,
                          labelColor: AppColors.primary),
                      if (bill.paidAt != null)
                        _TItem(label: 'PAID ON',
                            value: _fmt(bill.paidAt!),
                            dotColor: const Color(0xFF2E7D32),
                            filled: true,
                            labelColor: const Color(0xFF2E7D32)),
                      _TItem(label: 'GENERATED ON',
                          value: _fmt(bill.createdAt),
                          dotColor: Colors.grey.shade400, filled: false),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Download button
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invoice download coming soon'),
                      duration: Duration(seconds: 2)),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(
                        color:      AppColors.primary.withOpacity(0.30),
                        blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_rounded,
                          color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text('Download Invoice (PDF)',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('INVOICE #${bill.billNumber}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFFBBAAAA),
                      fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMELINE
// ─────────────────────────────────────────────────────────────────────────────

class _TItem {
  final String  label, value;
  final Color   dotColor;
  final bool    filled;
  final Color?  labelColor;
  const _TItem({required this.label, required this.value,
    required this.dotColor, required this.filled, this.labelColor});
}

class _Timeline extends StatelessWidget {
  final List<_TItem> items;
  const _Timeline({required this.items});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned(left: 11, top: 8, bottom: 8,
          child: Container(width: 1, color: Colors.grey.shade100)),
      Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final last = e.key == items.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color:  item.filled ? item.dotColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: item.dotColor, width: 2),
                    boxShadow: item.filled ? [BoxShadow(
                        color: item.dotColor.withOpacity(0.3),
                        blurRadius: 6, offset: const Offset(0, 2))] : null,
                  ),
                  child: item.filled ? null : Center(child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                          color: item.dotColor, shape: BoxShape.circle))),
                ),
                const SizedBox(width: 16),
                Expanded(child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.label, style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800,
                        color: item.labelColor ?? Colors.grey.shade500,
                        letterSpacing: 0.6)),
                    Flexible(child: Text(item.value,
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1A1B)),
                        textAlign: TextAlign.end)),
                  ],
                )),
              ],
            ),
          );
        }).toList(),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _BreakRow extends StatelessWidget {
  final String label, value;
  const _BreakRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14,
              color: Color(0xFF857375), fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 16,
              fontWeight: FontWeight.w700, color: Color(0xFF1F1A1B))),
        ],
      ),
    );
  }
}

class _StatusStyle {
  final String   label;
  final Color    color, bg;
  final IconData icon;
  const _StatusStyle({required this.label, required this.color,
    required this.bg, required this.icon});
}

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 80, height: 80,
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppColors.primary, size: 36)),
        const SizedBox(height: 20),
        Text(filter == 'All' ? 'No Bills Yet' : 'No $filter Bills',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: Color(0xFF1F1A1B))),
        const SizedBox(height: 8),
        const Text('Your Speedonet invoices will appear here',
            style: TextStyle(fontSize: 13, color: Color(0xFF857375)),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFBBAAAA)),
        const SizedBox(height: 12),
        Text(error, style: const TextStyle(color: Color(0xFF857375)),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Retry', style: TextStyle(color: Colors.white))),
      ]),
    ),
  );
}