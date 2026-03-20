// lib/views/payment/payment_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/plan_model.dart';
import '../../services/plan_service.dart';
import '../../theme/app_theme.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final _service = PlanService();

  List<PlanTransaction> _txns    = [];
  bool                  _loading = true;
  String?               _error;
  String                _filter  = 'All';

  static const _filters = ['All', 'Debit', 'Credit'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _txns = await _service.getTransactions(limit: 50);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PlanTransaction> get _filtered {
    switch (_filter) {
      case 'Debit':  return _txns.where((t) => !t.isCredit).toList();
      case 'Credit': return _txns.where((t) =>  t.isCredit).toList();
      default:       return _txns;
    }
  }

  Map<String, List<PlanTransaction>> _grouped(List<PlanTransaction> list) {
    final map = <String, List<PlanTransaction>>{};
    for (final t in list) {
      map.putIfAbsent(_dateKey(t.createdAt), () => []).add(t);
    }
    return map;
  }

  String _dateKey(DateTime d) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dt    = DateTime(d.year, d.month, d.day);
    if (dt == today) return 'Today';
    if (dt == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month-1]}, ${d.year}';
  }

  double get _monthlySpend {
    final now = DateTime.now();
    return _txns
        .where((t) => !t.isCredit &&
        t.createdAt.year  == now.year &&
        t.createdAt.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
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
            // ── Header ──────────────────────────────────────────────────
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
                          if (Navigator.canPop(context))
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 38, height: 38,
                                margin: const EdgeInsets.only(right: 14),
                                decoration: BoxDecoration(
                                  color:  Colors.white.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Payment History',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800)),
                                SizedBox(height: 2),
                                Text('All your Speedonet transactions',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ]),
                        const SizedBox(height: 20),

                        if (!_loading && _txns.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color:  Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.25)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.calendar_month_rounded,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Text('This month: ',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13)),
                              Text(
                                '₹${_monthlySpend.toStringAsFixed(2)} spent',
                                style: const TextStyle(
                                    color:      Colors.white,
                                    fontSize:   13,
                                    fontWeight: FontWeight.w700),
                              ),
                            ]),
                          ),
                        const SizedBox(height: 16),

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

            // ── Body ────────────────────────────────────────────────────
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(
                    color: AppColors.primary)),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: _ErrorState(error: _error!, onRetry: _load),
              )
            else if (_filtered.isEmpty)
                const SliverFillRemaining(child: _EmptyState())
              else
                _GroupedList(
                  grouped:  _grouped(_filtered),
                  dateKeys: _grouped(_filtered).keys.toList(),
                ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GROUPED LIST
// ─────────────────────────────────────────────────────────────────────────────

class _GroupedList extends StatelessWidget {
  final Map<String, List<PlanTransaction>> grouped;
  final List<String>                        dateKeys;
  const _GroupedList({required this.grouped, required this.dateKeys});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (_, i) {
            final key  = dateKeys[i];
            final list = grouped[key]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      bottom: 10, top: i == 0 ? 0 : 20),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(key,
                          style: const TextStyle(
                              fontSize:   12,
                              fontWeight: FontWeight.w700,
                              color:      AppColors.primary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Divider(
                        color: Colors.grey.shade200, height: 1)),
                  ]),
                ),
                ...list.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TxnCard(txn: t),
                )),
              ],
            );
          },
          childCount: dateKeys.length,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRANSACTION CARD
// ─────────────────────────────────────────────────────────────────────────────

class _TxnCard extends StatelessWidget {
  final PlanTransaction txn;
  const _TxnCard({required this.txn});

  _TxnStyle get _style {
    if (txn.isCredit) {
      return _TxnStyle(
        icon:      Icons.arrow_downward_rounded,
        iconColor: const Color(0xFF2E7D32),
        iconBg:    const Color(0xFFE8F5E9),
        amtColor:  const Color(0xFF2E7D32),
        typeLabel: 'Credit',
        typeBg:    const Color(0xFFE8F5E9),
        typeColor: const Color(0xFF2E7D32),
      );
    }
    return _TxnStyle(
      icon:      Icons.arrow_upward_rounded,
      iconColor: AppColors.primary,
      iconBg:    const Color(0xFFFFECEF),
      amtColor:  AppColors.primary,
      typeLabel: 'Debit',
      typeBg:    const Color(0xFFFFECEF),
      typeColor: AppColors.primary,
    );
  }

  String _time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _cleanDesc(String desc) =>
      desc.replaceAll(RegExp(r'[^\x00-\x7F·\-()₹%.,0-9a-zA-Z ]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  String _titleFromDesc(String desc) {
    if (desc.contains('Plan purchase:')) {
      final after =
      desc.split('Plan purchase:').last.split('(').first.trim();
      if (after.isNotEmpty) return after;
    }
    if (desc.contains('Wallet recharge')) return 'Wallet Recharge';
    if (desc.contains('Referral reward')) return 'Referral Reward';
    return 'Transaction';
  }

  String _niceType(String type) {
    switch (type) {
      case 'payment_order':   return 'Plan Purchase';
      case 'wallet_recharge': return 'Recharge';
      case 'referral':        return 'Referral';
      default:                return type.replaceAll('_', ' ');
    }
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _TxnDetailSheet(txn: txn),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration:
            BoxDecoration(color: s.iconBg, shape: BoxShape.circle),
            child: Icon(s.icon, color: s.iconColor, size: 22),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.planName ?? _titleFromDesc(txn.description),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize:   15,
                      color:      Color(0xFF1F1A1B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _cleanDesc(txn.description),
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF857375)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  if (txn.paymentStatus != null)
                    _Badge(
                      label: txn.paymentStatus!,
                      color: txn.paymentStatus == 'success'
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFED6C02),
                      bg: txn.paymentStatus == 'success'
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                    ),
                  if (txn.referenceType != null)
                    _Badge(
                      label: _niceType(txn.referenceType!),
                      color: const Color(0xFF534345),
                      bg:    const Color(0xFFF4DDDF),
                    ),
                  if (txn.orderRef != null)
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: txn.orderRef!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:  Text('Order ref copied'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: _Badge(
                        label: txn.orderRef!,
                        color: const Color(0xFF534345),
                        bg:    const Color(0xFFF0F0F0),
                        icon:  Icons.copy_rounded,
                      ),
                    ),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(txn.amountLabel,
                  style: TextStyle(
                      fontSize:   18,
                      fontWeight: FontWeight.w900,
                      color:      s.amtColor)),
              const SizedBox(height: 4),
              Text(_time(txn.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFFAAAAAA))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '₹${txn.balanceAfter.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize:   10,
                      color:      Color(0xFF857375),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _TxnDetailSheet extends StatelessWidget {
  final PlanTransaction txn;
  const _TxnDetailSheet({required this.txn});

  String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}, '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.isCredit;
    final amtColor =
    isCredit ? const Color(0xFF2E7D32) : AppColors.primary;

    return Container(
      decoration: const BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color:        Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isCredit
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFECEF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color:  amtColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: amtColor, size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(txn.amountLabel,
                style: TextStyle(
                    fontSize:   32,
                    fontWeight: FontWeight.w900,
                    color:      amtColor)),
            const SizedBox(height: 4),
            Text(isCredit ? 'Money Credited' : 'Money Debited',
                style: TextStyle(
                    fontSize:   13,
                    color:      amtColor,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 20),

        _DetailRow('Date & Time', _fmt(txn.createdAt)),
        const Divider(height: 20),
        _DetailRow('Balance After',
            '₹${txn.balanceAfter.toStringAsFixed(2)}'),
        if (txn.planName != null) ...[
          const Divider(height: 20),
          _DetailRow('Plan', txn.planName!),
        ],
        if (txn.orderRef != null) ...[
          const Divider(height: 20),
          _DetailRow('Order Reference', txn.orderRef!,
              copyable: true, sheetContext: context),
        ],
        if (txn.paymentStatus != null) ...[
          const Divider(height: 20),
          _DetailRow('Payment Status',
              txn.paymentStatus!.toUpperCase()),
        ],
        if (txn.referenceType != null) ...[
          const Divider(height: 20),
          _DetailRow(
              'Type', txn.referenceType!.replaceAll('_', ' ')),
        ],
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String       label;
  final String       value;
  final bool         copyable;
  final BuildContext? sheetContext;
  const _DetailRow(this.label, this.value,
      {this.copyable = false, this.sheetContext});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize:   13,
                color:      Color(0xFF857375),
                fontWeight: FontWeight.w500)),
        Flexible(
          child: Row(children: [
            Flexible(
              child: Text(value,
                  style: const TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF1F1A1B)),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis),
            ),
            if (copyable) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(sheetContext ?? context)
                      .showSnackBar(
                    const SnackBar(
                      content:  Text('Copied'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Icon(Icons.copy_rounded,
                    size: 14, color: Color(0xFFAAAAAA)),
              ),
            ],
          ]),
        ),   // closes Flexible
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String    label;
  final Color     color, bg;
  final IconData? icon;
  const _Badge({required this.label, required this.color,
    required this.bg, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STYLE — no const constructor (AppColors.primary is not a compile-time const)
// ─────────────────────────────────────────────────────────────────────────────

class _TxnStyle {
  final IconData icon;
  final Color    iconColor, iconBg, amtColor, typeBg, typeColor;
  final String   typeLabel;

  _TxnStyle({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.amtColor,
    required this.typeLabel,
    required this.typeBg,
    required this.typeColor,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY & ERROR
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color:  AppColors.primary.withOpacity(0.07),
                shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppColors.primary, size: 36)),
        const SizedBox(height: 20),
        const Text('No Transactions Yet',
            style: TextStyle(
                fontSize:   18,
                fontWeight: FontWeight.w800,
                color:      Color(0xFF1F1A1B))),
        const SizedBox(height: 8),
        const Text('Your payment history will appear here',
            style:     TextStyle(
                fontSize: 13, color: Color(0xFF857375)),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String       error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded,
            size: 48, color: Color(0xFFBBAAAA)),
        const SizedBox(height: 12),
        Text(error,
            style: const TextStyle(color: Color(0xFF857375)),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          child: const Text('Retry',
              style: TextStyle(color: Colors.white)),
        ),
      ]),
    ),
  );
}