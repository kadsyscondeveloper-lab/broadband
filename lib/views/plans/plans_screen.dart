// lib/views/plans/plans_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/plan_model.dart';
import '../../services/atom_payment_service.dart';
import '../../services/coupon_service.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/plans_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../payment/atom_payment_screen.dart';

class PlansScreen extends StatefulWidget {
  final HomeViewModel? homeViewModel;
  const PlansScreen({super.key, this.homeViewModel});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen>
    with SingleTickerProviderStateMixin {
  late final PlansViewModel _vm;
  late final TabController  _tabs;

  @override
  void initState() {
    super.initState();
    _vm   = PlansViewModel();
    _tabs = TabController(length: 3, vsync: this);
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _confirmPurchase(Plan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PurchaseSheet(
        plan: plan,
        walletBalance: widget.homeViewModel?.walletBalance ?? 0,
        onConfirm: (mode, couponCode, totalAmount) async {
          Navigator.pop(context);

          if (mode == 'pg') {
            await _handlePgPurchase(plan, couponCode, totalAmount);
          } else {
            await _handleWalletPurchase(plan, couponCode);
          }
        },
      ),
    );
  }

  // ── Wallet purchase ────────────────────────────────────────────────────────
  Future<void> _handleWalletPurchase(Plan plan, String? couponCode) async {
    await _vm.purchasePlan(plan.id, paymentMode: 'wallet', couponCode: couponCode);
    if (!mounted) return;
    if (_vm.purchaseState == PlanPurchaseState.success) {
      await widget.homeViewModel?.refreshWalletBalance();
      _showSuccessDialog(_vm.purchaseResult!);
    } else {
      _showErrorSnack(_vm.purchaseError ?? 'Purchase failed');
    }
    _vm.resetPurchaseState();
  }

  // ── Payment gateway purchase ───────────────────────────────────────────────
  Future<void> _handlePgPurchase(Plan plan, String? couponCode, double amount) async {
    // Step 1: initiate PG payment
    final pgService  = AtomPaymentService();
    final initResult = await pgService.initiateRecharge(amount);

    if (!mounted) return;

    if (initResult == null || initResult.paymentUrl.isEmpty) {
      _showErrorSnack('Unable to initiate payment. Please try again.');
      return;
    }

    // Step 2: open WebView
    final payResult = await Navigator.push<AtomPaymentResult>(
      context,
      MaterialPageRoute(
        builder: (_) => AtomPaymentScreen(initiateResult: initResult),
      ),
    );

    if (!mounted) return;

    if (payResult == null || payResult.isCancelled) {
      _showErrorSnack('Payment was cancelled.');
      return;
    }

    if (payResult.isPending) {
      _showErrorSnack(
          'Payment pending. Your plan will activate once the bank confirms.');
      return;
    }

    if (!payResult.isSuccess) {
      _showErrorSnack('Payment failed. Please try again.');
      return;
    }

    // Step 3: PG credited wallet — now purchase plan
    await _vm.purchasePlan(plan.id, paymentMode: 'wallet', couponCode: couponCode);
    if (!mounted) return;
    if (_vm.purchaseState == PlanPurchaseState.success) {
      await widget.homeViewModel?.refreshWalletBalance();
      _showSuccessDialog(_vm.purchaseResult!);
    } else {
      _showErrorSnack(_vm.purchaseError ?? 'Purchase failed');
    }
    _vm.resetPurchaseState();
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        result: result,
        onDone: () => Navigator.pop(context),
      ),
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          return CustomScrollView(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top nav row
                      Row(
                        children: [
                          if (canPop)
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Padding(
                                padding: EdgeInsets.only(right: 14),
                                child: Icon(Icons.arrow_back_ios,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          const Icon(Icons.router_outlined,
                              color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          const Text(
                            'Choose a Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Active sub banner
                      if (_vm.activeSub != null)
                        _ActiveSubBanner(sub: _vm.activeSub!),
                      if (_vm.queuedSub != null) ...[
                        const SizedBox(height: 8),
                        _QueuedSubBanner(sub: _vm.queuedSub!),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Tab bar ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabs,
                      labelColor: AppColors.textDark,
                      unselectedLabelColor: AppColors.textLight,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14),
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Monthly'),
                        Tab(text: 'Quarterly'),
                        Tab(text: 'Annual'),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Plan list ────────────────────────────────────────────────
              if (_vm.isLoading)
                const SliverFillRemaining(
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary)),
                )
              else if (_vm.error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off_outlined,
                              size: 48, color: AppColors.textLight),
                          const SizedBox(height: 12),
                          Text(_vm.error!,
                              style: const TextStyle(
                                  color: AppColors.textGrey)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _vm.load,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary),
                            child: const Text('Retry',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ]),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _PlanList(
                            plans: _vm.monthlyPlans,
                            activeSub: _vm.activeSub,
                            onSelect: _confirmPurchase),
                        _PlanList(
                            plans: _vm.quarterlyPlans,
                            activeSub: _vm.activeSub,
                            onSelect: _confirmPurchase),
                        _PlanList(
                            plans: _vm.annualPlans,
                            activeSub: _vm.activeSub,
                            onSelect: _confirmPurchase),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE SUB BANNER — with circular progress indicator
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveSubBanner extends StatelessWidget {
  final ActiveSubscription sub;
  const _ActiveSubBanner({required this.sub});

  @override
  Widget build(BuildContext context) {
    // Assume max ~365 days for the arc; clamp to [0,1]
    final progress = (sub.daysRemaining / 365.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Plan',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub.planName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${sub.speedMbps} Mbps',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Circular progress + label below
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ring painter
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CustomPaint(
                        painter: _CircleProgressPainter(progress: progress),
                      ),
                    ),
                    // Check icon
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sub.isExpiringSoon
                    ? '⚠️ ${sub.daysRemaining}d left'
                    : 'Active · ${sub.daysRemaining}d',
                style: TextStyle(
                  color: sub.isExpiringSoon
                      ? Colors.amber
                      : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Draws a thin arc ring showing subscription time remaining.
class _CircleProgressPainter extends CustomPainter {
  final double progress;
  const _CircleProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 5;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAN LIST
// ─────────────────────────────────────────────────────────────────────────────

class _PlanList extends StatelessWidget {
  final List<Plan> plans;
  final ActiveSubscription? activeSub;
  final void Function(Plan) onSelect;

  const _PlanList({
    required this.plans,
    required this.activeSub,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const Center(
        child: Text('No plans available',
            style: TextStyle(color: AppColors.textGrey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final plan = plans[i];
        final isCurrent = activeSub?.planId == plan.id &&
            !(activeSub?.startsAt?.isAfter(DateTime.now()) ?? false);
        return _PlanCard(
          plan: plan,
          isCurrent: isCurrent,
          onSelect: () => onSelect(plan),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAN CARD — redesigned to match screenshot
// ─────────────────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isCurrent;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isPopular = plan.speedMbps == 100 && plan.validityDays == 30;
    final badgeColor = isCurrent ? Colors.green : AppColors.primary;
    final badgeBg = isCurrent
        ? Colors.green.shade50
        : const Color(0xFFFFEBEB);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          // Extra top margin when popular so the floating badge has space above
          margin: isPopular && !isCurrent
              ? const EdgeInsets.only(top: 14)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent
                  ? Colors.green.shade300
                  : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // ── Speed badge ──────────────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      plan.speedMbps >= 1000
                          ? '${plan.speedMbps ~/ 1000}'
                          : '${plan.speedMbps}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: badgeColor,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      plan.speedMbps >= 1000 ? 'Gbps' : 'Mbps',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // ── Plan details ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${plan.dataLabel}  |  ${plan.validityLabel}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // ── Price + action ───────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${plan.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  isCurrent
                      ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.green.shade300),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                      : GestureDetector(
                    onTap: onSelect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Buy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── "Most Popular" badge ─────────────────────────────────────────
        if (isPopular && !isCurrent)
          Positioned(
            top: 0,
            right: 14,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Most Popular',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PURCHASE SHEET — redesigned to match screenshot
// ─────────────────────────────────────────────────────────────────────────────

class _PurchaseSheet extends StatefulWidget {
  final Plan plan;
  final double walletBalance;
  final void Function(String mode, String? couponCode, double amount) onConfirm;

  const _PurchaseSheet({
    required this.plan,
    required this.walletBalance,
    required this.onConfirm,
  });

  @override
  State<_PurchaseSheet> createState() => _PurchaseSheetState();
}

class _PurchaseSheetState extends State<_PurchaseSheet> {
  final _couponController = TextEditingController();
  final _couponFocus      = FocusNode();
  final _couponService    = CouponService();

  String _mode    = 'wallet';
  bool   _loading = false;

  bool                    _couponLoading = false;
  CouponValidationResult? _couponResult;
  String?                 _couponError;
  bool                    _couponApplied = false;

  @override
  void initState() {
    super.initState();
    _couponController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _couponController.dispose();
    _couponFocus.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    _couponFocus.unfocus();
    setState(() {
      _couponLoading = true;
      _couponError   = null;
      _couponResult  = null;
      _couponApplied = false;
    });
    final result = await _couponService.validate(
      planId: widget.plan.id, couponCode: code,
    );
    setState(() {
      _couponLoading = false;
      if (result.valid) {
        _couponResult  = result;
        _couponApplied = true;
      } else {
        _couponError   = result.error;
      }
    });
  }

  void _removeCoupon() {
    setState(() {
      _couponController.clear();
      _couponResult  = null;
      _couponError   = null;
      _couponApplied = false;
    });
  }

  double get _gstAmount =>
      double.parse((widget.plan.price * 0.18).toStringAsFixed(2));

  double get _finalTotal {
    if (_couponApplied && _couponResult != null) {
      return _couponResult!.finalTotal;
    }
    return double.parse(
        (widget.plan.price + _gstAmount).toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    final plan    = widget.plan;
    final baseAmt = plan.price;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).padding.bottom + 24),
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

              // Title
              const Text(
                'Confirm Purchase',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 18),

              // ── Plan summary card ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${plan.speedLabel} · ${plan.dataLabel} · ${plan.validityLabel}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${baseAmt.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 20),

              // ── Coupon section ───────────────────────────────────────────
              const Text(
                'Have a coupon?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),

              // Coupon row: single bordered box with field + divider + Apply
              Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _couponApplied
                        ? Colors.green
                        : _couponError != null
                        ? Colors.red
                        : const Color(0xFFDDDDDD),
                    width: 1.5,
                  ),
                  color: _couponApplied
                      ? const Color(0xFFEDF7ED)
                      : Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Row(children: [
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        focusNode: _couponFocus,
                        enabled: !_couponApplied,
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (_) => _applyCoupon(),
                        decoration: InputDecoration(
                          hintText: 'Enter coupon code',
                          hintStyle: const TextStyle(
                            color: Color(0xFFBBBBBB),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _couponApplied
                              ? Colors.green.shade700
                              : AppColors.textDark,
                        ),
                      ),
                    ),
                    // Vertical divider
                    Container(
                      width: 1,
                      height: 28,
                      color: const Color(0xFFEEEEEE),
                    ),
                    // Apply / loading / close
                    if (_couponApplied)
                      GestureDetector(
                        onTap: _removeCoupon,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(Icons.close,
                              size: 18, color: AppColors.textGrey),
                        ),
                      )
                    else if (_couponLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _couponController.text.trim().isEmpty
                            ? null
                            : _applyCoupon,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Apply',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _couponController.text.trim().isEmpty
                                  ? AppColors.primary.withOpacity(0.4)
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),

              // Coupon feedback
              if (_couponError != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.error_outline,
                      size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(_couponError!,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.red)),
                  ),
                ]),
              ],
              if (_couponApplied && _couponResult != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.check_circle_outline,
                      size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '${_couponResult!.discountLabel} — saved ₹${_couponResult!.discountAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ],

              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 16),

              // ── Amount breakdown ─────────────────────────────────────────
              _AmountRow(
                  'Plan price', '₹${baseAmt.toStringAsFixed(2)}'),
              const SizedBox(height: 10),
              _AmountRow(
                  'GST (18%)', '₹${_gstAmount.toStringAsFixed(2)}'),
              if (_couponApplied && _couponResult != null) ...[
                const SizedBox(height: 10),
                _AmountRow(
                  'Discount (${_couponResult!.discountLabel})',
                  '−₹${_couponResult!.discountAmount.toStringAsFixed(2)}',
                  valueColor: Colors.green,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '₹${_finalTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 20),

              // ── Pay via ──────────────────────────────────────────────────
              const Text(
                'Pay via',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),

              // ── Pay via ──────────────────────────────────────────────────
              const Text(
                'Pay via',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),

              // Wallet option
              GestureDetector(
                onTap: () => setState(() => _mode = 'wallet'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _mode == 'wallet'
                          ? AppColors.primary
                          : const Color(0xFFDDDDDD),
                      width: _mode == 'wallet' ? 2 : 1.5,
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Wallet Balance',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 2),
                          Text(
                            '₹${widget.walletBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                    _ModeCheckmark(selected: _mode == 'wallet'),
                  ]),
                ),
              ),

              const SizedBox(height: 10),

              // Payment Gateway option
              GestureDetector(
                onTap: () => setState(() => _mode = 'pg'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _mode == 'pg'
                          ? AppColors.primary
                          : const Color(0xFFDDDDDD),
                      width: _mode == 'pg' ? 2 : 1.5,
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.payment_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Payment Gateway',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            children: ['UPI', 'Card', 'Net Banking']
                                .map((m) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius:
                                BorderRadius.circular(4),
                              ),
                              child: Text(m,
                                  style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textGrey)),
                            ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    _ModeCheckmark(selected: _mode == 'pg'),
                  ]),
                ),
              ),

              // Secured badge
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 12, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    const Text(
                        'Secured by Omniware · PCI-DSS compliant',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textGrey)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Pay button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () {
                    setState(() => _loading = true);
                    widget.onConfirm(
                      _mode,
                      _couponApplied
                          ? _couponController.text
                          .trim()
                          .toUpperCase()
                          : null,
                      _finalTotal,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                    AppColors.primary.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                      height: 22, width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                      : Text(
                    'Pay ₹${_finalTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Small reusable checkmark circle for payment mode options
class _ModeCheckmark extends StatelessWidget {
  final bool selected;
  const _ModeCheckmark({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: selected
            ? null
            : Border.all(color: const Color(0xFFDDDDDD), width: 2),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  valueColor;
  const _AmountRow(this.label, this.value,
      {this.valueColor = AppColors.textDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textGrey)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUCCESS DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback         onDone;
  const _SuccessDialog({required this.result, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final planName  =
        (result['plan'] as Map<String, dynamic>?)?['name'] ?? 'Plan';
    final expiresAt = result['expires_at'] != null
        ? DateTime.tryParse(result['expires_at'].toString())
        : null;
    final startDate = result['start_date'] != null
        ? DateTime.tryParse(result['start_date'].toString())
        : null;
    final isQueued =
        startDate != null && startDate.isAfter(DateTime.now());
    final discount =
        (result['discount_applied'] as num?)?.toDouble() ?? 0;
    final coupon = result['coupon_code'] as String?;

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: isQueued
                  ? const Color(0xFFFFF8E1)
                  : const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isQueued
                  ? Icons.schedule_rounded
                  : Icons.check_circle_rounded,
              color: isQueued ? Colors.orange : Colors.green,
              size: 44,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isQueued ? 'Plan Queued! 🕐' : 'Plan Activated! 🎉',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Text(planName,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
          const SizedBox(height: 4),
          if (isQueued && startDate != null)
            Text(
              'Starts on ${startDate.day}/${startDate.month}/${startDate.year}',
              style: const TextStyle(
                  color: AppColors.textGrey, fontSize: 13),
            )
          else if (expiresAt != null)
            Text(
              'Valid until ${expiresAt.day}/${expiresAt.month}/${expiresAt.year}',
              style: const TextStyle(
                  color: AppColors.textGrey, fontSize: 13),
            ),
          if (discount > 0 && coupon != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: Colors.green.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.local_offer_rounded,
                    color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Coupon $coupon saved you ₹${discount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUEUED SUB BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _QueuedSubBanner extends StatelessWidget {
  final ActiveSubscription sub;
  const _QueuedSubBanner({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(children: [
        const Icon(Icons.schedule_rounded,
            color: Colors.white70, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.planName,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  sub.startsAt != null
                      ? 'Queued · Starts ${sub.startsAt!.day}/${sub.startsAt!.month}/${sub.startsAt!.year}'
                      : 'Queued · Starts after current plan',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11),
                ),
              ]),
        ),
        Text('${sub.speedMbps} Mbps',
            style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ]),
    );
  }
}