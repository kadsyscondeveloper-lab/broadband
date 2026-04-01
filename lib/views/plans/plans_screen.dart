// lib/views/plans/plans_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/plan_model.dart';
import '../../services/atom_payment_service.dart';
import '../../services/coupon_service.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/plans_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../installation/installation_address_screen.dart';
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

  // ── KYC check ─────────────────────────────────────────────────────────────

  bool get _kycApproved {
    final status = widget.homeViewModel?.kycStatus;
    if (status == null) return true;
    return status.isApproved;
  }

  void _showKycRequiredSheet() {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => const _KycRequiredSheet(),
    );
  }

  // ── Purchase entry point ──────────────────────────────────────────────────

  void _confirmPurchase(Plan plan) {
    if (!_kycApproved) {
      _showKycRequiredSheet();
      return;
    }

    // ── New guard: 2-day renewal window / already-queued ──────────────────
    if (!_vm.canPurchaseNewPlan) {
      if (_vm.queuedSub != null) {
        _showAlreadyQueuedSheet(_vm.queuedSub!);
      } else {
        _showRenewalWindowSheet();
      }
      return;
    }

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

  // ── Blocked-purchase sheets ───────────────────────────────────────────────

  void _showAlreadyQueuedSheet(ActiveSubscription queued) {
    final startDate = queued.startsAt;
    final dateStr = startDate != null
        ? '${startDate.day}/${startDate.month}/${startDate.year}'
        : 'soon';

    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _InfoSheet(
        icon:       Icons.schedule_rounded,
        iconColor:  Colors.orange.shade700,
        iconBg:     Colors.orange.shade50,
        title:      'Plan Already Queued',
        body:       '${queued.planName} is queued and will start on $dateStr. '
            'You can only have one plan queued at a time.',
        buttonLabel: 'Got It',
      ),
    );
  }

  void _showRenewalWindowSheet() {
    final renewalDate = _vm.renewalAvailableFrom;
    final expiryDate  = _vm.activeSub?.expiresAt;

    final renewalStr = renewalDate != null
        ? _fmtDate(renewalDate)
        : 'soon';
    final expiryStr = expiryDate != null
        ? _fmtDate(expiryDate)
        : 'the expiry date';

    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _InfoSheet(
        icon:       Icons.lock_clock_rounded,
        iconColor:  AppColors.primary,
        iconBg:     AppColors.primary.withOpacity(0.08),
        title:      'Renewal Window Not Open Yet',
        body:       'Your current plan is active until $expiryStr. '
            'You can purchase a new plan from $renewalStr '
            '(2 days before expiry). This ensures a seamless transition.',
        buttonLabel: 'Got It',
      ),
    );
  }

  // ── Wallet purchase ────────────────────────────────────────────────────────
  Future<void> _handleWalletPurchase(Plan plan, String? couponCode) async {
    await _vm.purchasePlan(plan.id,
        paymentMode: 'wallet', couponCode: couponCode);
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
  Future<void> _handlePgPurchase(
      Plan plan, String? couponCode, double amount) async {
    final pgService  = AtomPaymentService();
    final initResult = await pgService.initiateRecharge(amount);

    if (!mounted) return;

    if (initResult == null || initResult.paymentUrl.isEmpty) {
      _showErrorSnack('Unable to initiate payment. Please try again.');
      return;
    }

    final payResult = await Navigator.push<AtomPaymentResult>(
      context,
      MaterialPageRoute(
          builder: (_) => AtomPaymentScreen(initiateResult: initResult)),
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

    await _vm.purchasePlan(plan.id,
        paymentMode: 'wallet', couponCode: couponCode);
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
        onDone: () {
          Navigator.pop(context); // close dialog
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const InstallationAddressScreen(),
            ),
          );
        },
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // Label shown on locked Buy buttons (e.g. "Renew 28 Jun" or "Plan queued")
  String? get _purchaseBlockLabel {
    if (!_vm.canPurchaseNewPlan) {
      if (_vm.queuedSub != null) return 'Plan queued';
      final from = _vm.renewalAvailableFrom;
      if (from != null) return 'Renew ${_fmtDate(from)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          // Compute once and pass down so all plan cards are consistent.
          final purchaseAllowed = _vm.canPurchaseNewPlan;
          final blockLabel      = _purchaseBlockLabel;

          return CustomScrollView(
            slivers: [
              // ── Header ─────────────────────────────────────────────────
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
                      Row(children: [
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
                      ]),
                      const SizedBox(height: 20),
                      if (_vm.activeSub != null)
                        _ActiveSubBanner(sub: _vm.activeSub!),
                      if (_vm.queuedSub != null) ...[
                        const SizedBox(height: 8),
                        _QueuedSubBanner(sub: _vm.queuedSub!),
                      ],
                      // ── Renewal window notice ──────────────────────────
                      if (!purchaseAllowed && _vm.queuedSub == null) ...[
                        const SizedBox(height: 12),
                        _RenewalWindowStrip(
                          renewalDate: _vm.renewalAvailableFrom,
                          onTap: _showRenewalWindowSheet,
                        ),
                      ],
                      // ── KYC warning strip ──────────────────────────────
                      if (!_kycApproved) ...[
                        const SizedBox(height: 12),
                        _KycWarningStrip(onTap: _showKycRequiredSheet),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Tab bar ────────────────────────────────────────────────
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
                            blurRadius: 6, offset: const Offset(0, 2),
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

              // ── Plan list ──────────────────────────────────────────────
              if (_vm.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(
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
                              style: const TextStyle(color: AppColors.textGrey)),
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
                            queuedSub: _vm.queuedSub,
                            kycApproved: _kycApproved,
                            purchaseAllowed: purchaseAllowed,
                            purchaseBlockLabel: blockLabel,
                            onSelect: _confirmPurchase),
                        _PlanList(
                            plans: _vm.quarterlyPlans,
                            activeSub: _vm.activeSub,
                            queuedSub: _vm.queuedSub,
                            kycApproved: _kycApproved,
                            purchaseAllowed: purchaseAllowed,
                            purchaseBlockLabel: blockLabel,
                            onSelect: _confirmPurchase),
                        _PlanList(
                            plans: _vm.annualPlans,
                            activeSub: _vm.activeSub,
                            queuedSub: _vm.queuedSub,
                            kycApproved: _kycApproved,
                            purchaseAllowed: purchaseAllowed,
                            purchaseBlockLabel: blockLabel,
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
// RENEWAL WINDOW STRIP  (shown in header when active plan has > 2 days left)
// ─────────────────────────────────────────────────────────────────────────────

class _RenewalWindowStrip extends StatelessWidget {
  final DateTime?    renewalDate;
  final VoidCallback onTap;
  const _RenewalWindowStrip({required this.renewalDate, required this.onTap});

  static String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final label = renewalDate != null
        ? 'Renewal opens ${_fmt(renewalDate!)} — 2 days before expiry'
        : 'Renewal available near your plan expiry';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(children: [
          const Icon(Icons.lock_clock_rounded,
              color: Colors.white70, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4)),
          ),
          const Icon(Icons.info_outline_rounded,
              color: Colors.white38, size: 14),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GENERIC INFO SHEET  (used for "already queued" and "renewal window" blocks)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoSheet extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final Color    iconBg;
  final String   title;
  final String   body;
  final String   buttonLabel;

  const _InfoSheet({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
    required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
              color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 28),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
              color: iconBg, shape: BoxShape.circle,
              border: Border.all(
                  color: iconColor.withOpacity(0.25), width: 1.5)),
          child: Icon(icon, size: 36, color: iconColor),
        ),
        const SizedBox(height: 20),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: AppColors.textDark)),
        const SizedBox(height: 12),
        Text(body,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textGrey, height: 1.6)),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(buttonLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KYC WARNING STRIP
// ─────────────────────────────────────────────────────────────────────────────

class _KycWarningStrip extends StatelessWidget {
  final VoidCallback onTap;
  const _KycWarningStrip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.shade700.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade300.withOpacity(0.5)),
        ),
        child: Row(children: [
          const Icon(Icons.lock_outline_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'KYC required to purchase a plan. Tap to learn more.',
              style: TextStyle(color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w500, height: 1.4),
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white54, size: 12),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KYC REQUIRED SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _KycRequiredSheet extends StatelessWidget {
  const _KycRequiredSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: Colors.amber.shade50, shape: BoxShape.circle,
            border: Border.all(color: Colors.amber.shade200, width: 1.5),
          ),
          child: Icon(Icons.verified_user_outlined,
              size: 36, color: Colors.amber.shade700),
        ),
        const SizedBox(height: 20),
        const Text('KYC Verification Required',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 10),
        const Text(
          'To purchase a Speedonet plan, you need to complete your KYC '
              'verification first. This is a one-time process.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF666680), height: 1.6),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade100),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('How to complete KYC:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: Colors.amber.shade800)),
            const SizedBox(height: 10),
            ...[
              ('1', 'Go to Home → tap KYC'),
              ('2', 'Upload your address proof'),
              ('3', 'Upload your ID proof'),
              ('4', 'Wait for approval (usually within 24h)'),
            ].map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                      color: Colors.amber.shade700, shape: BoxShape.circle),
                  child: Center(child: Text(step.$1,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 10, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(step.$2,
                    style: TextStyle(fontSize: 13,
                        color: Colors.amber.shade900, height: 1.4))),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Got It',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE SUB BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveSubBanner extends StatelessWidget {
  final ActiveSubscription sub;
  const _ActiveSubBanner({required this.sub});

  @override
  Widget build(BuildContext context) {
    final progress = (sub.daysRemaining / 365.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.30)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Current Plan',
                style: TextStyle(color: Colors.white70, fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(sub.planName,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 22)),
            const SizedBox(height: 2),
            Text('${sub.speedMbps} Mbps',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 72, height: 72,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 72, height: 72,
                  child: CustomPaint(
                      painter: _CircleProgressPainter(progress: progress))),
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Text(
            sub.isExpiringSoon
                ? '⚠️ ${sub.daysRemaining}d left'
                : 'Active · ${sub.daysRemaining}d',
            style: TextStyle(
              color: sub.isExpiringSoon ? Colors.amber : Colors.white70,
              fontSize: 10, fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      ]),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  const _CircleProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 5;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    canvas.drawCircle(Offset(cx, cy), radius,
        Paint()
          ..color = Colors.white.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAN LIST
// ─────────────────────────────────────────────────────────────────────────────

class _PlanList extends StatelessWidget {
  final List<Plan>          plans;
  final ActiveSubscription? activeSub;
  final ActiveSubscription? queuedSub;
  final bool                kycApproved;
  final bool                purchaseAllowed;
  final String?             purchaseBlockLabel;
  final void Function(Plan) onSelect;

  const _PlanList({
    required this.plans,
    required this.activeSub,
    required this.queuedSub,
    required this.kycApproved,
    required this.purchaseAllowed,
    required this.purchaseBlockLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const Center(child: Text('No plans available',
          style: TextStyle(color: AppColors.textGrey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final plan = plans[i];
        final isCurrent = activeSub?.planId == plan.id &&
            !(activeSub?.startsAt?.isAfter(DateTime.now()) ?? false);
        // This specific plan is the queued one
        final isThisPlanQueued = queuedSub?.planId == plan.id;
        return _PlanCard(
          plan:               plan,
          isCurrent:          isCurrent,
          isQueued:           isThisPlanQueued,
          kycApproved:        kycApproved,
          purchaseAllowed:    purchaseAllowed,
          purchaseBlockLabel: purchaseBlockLabel,
          onSelect:           () => onSelect(plan),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAN CARD
// ─────────────────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final Plan         plan;
  final bool         isCurrent;
  final bool         isQueued;           // this plan is the queued one
  final bool         kycApproved;
  final bool         purchaseAllowed;    // global gate (2-day window / queued)
  final String?      purchaseBlockLabel; // text shown on locked button
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.isQueued,
    required this.kycApproved,
    required this.purchaseAllowed,
    required this.purchaseBlockLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isPopular  = plan.speedMbps == 100 && plan.validityDays == 30;
    final badgeColor = isCurrent ? Colors.green : AppColors.primary;
    final badgeBg    = isCurrent ? Colors.green.shade50 : const Color(0xFFFFEBEB);
    final buyLocked  = !kycApproved && !isCurrent && !isQueued;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: isPopular && !isCurrent
              ? const EdgeInsets.only(top: 14)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent
                  ? Colors.green.shade300
                  : isQueued
                  ? Colors.orange.shade300
                  : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04),
                  blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [

            // Speed badge
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  color: badgeBg, borderRadius: BorderRadius.circular(14)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  plan.speedMbps >= 1000
                      ? '${plan.speedMbps ~/ 1000}'
                      : '${plan.speedMbps}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                      color: badgeColor, height: 1.1),
                ),
                Text(plan.speedMbps >= 1000 ? 'Gbps' : 'Mbps',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: badgeColor)),
              ]),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(plan.name,
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 15, color: AppColors.textDark)),
                const SizedBox(height: 5),
                Text('${plan.dataLabel}  |  ${plan.validityLabel}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textGrey)),
              ]),
            ),
            const SizedBox(width: 12),

            // Price + action
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹${plan.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                      color: AppColors.textDark)),
              const SizedBox(height: 6),

              // ── Action button / badge ──────────────────────────────────
              if (isCurrent)
                _StatusChip(label: 'Active', color: Colors.green)
              else if (isQueued)
                _StatusChip(label: 'Queued ✓', color: Colors.orange.shade700)
              else if (!purchaseAllowed)
                // Renewal window / another plan queued
                  _BlockedChip(label: purchaseBlockLabel ?? 'Locked')
                else
                // Normal Buy button (may have KYC lock icon)
                  GestureDetector(
                    onTap: onSelect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: buyLocked
                            ? AppColors.primary.withOpacity(0.45)
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (buyLocked) ...[
                          const Icon(Icons.lock_rounded,
                              color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                        ],
                        const Text('Buy',
                            style: TextStyle(color: Colors.white, fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
            ]),
          ]),
        ),

        // "Most Popular" badge
        if (isPopular && !isCurrent && !isQueued)
          Positioned(
            top: 0, right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Most Popular',
                  style: TextStyle(color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}

/// Active / Queued pill badge — no tap.
class _StatusChip extends StatelessWidget {
  final String label;
  final Color  color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 12,
            fontWeight: FontWeight.w700)),
  );
}

/// Locked-Buy chip — greyed out, shows the reason (e.g. "Renew 28 Jun").
class _BlockedChip extends StatelessWidget {
  final String label;
  const _BlockedChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.lock_clock_rounded, color: Colors.grey.shade500, size: 12),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11,
              fontWeight: FontWeight.w600)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PURCHASE SHEET  (unchanged from original)
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
        planId: widget.plan.id, couponCode: code);
    setState(() {
      _couponLoading = false;
      if (result.valid) {
        _couponResult  = result;
        _couponApplied = true;
      } else {
        _couponError = result.error;
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
    if (_couponApplied && _couponResult != null) return _couponResult!.finalTotal;
    return double.parse(
        (widget.plan.price + _gstAmount).toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    final plan    = widget.plan;
    final baseAmt = plan.price;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              Center(
                child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              const Text('Confirm Purchase',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 18),

              // Plan summary
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(plan.name,
                          style: const TextStyle(fontWeight: FontWeight.w700,
                              fontSize: 16, color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text('${plan.speedLabel} · ${plan.dataLabel} · ${plan.validityLabel}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                    ]),
                    Text('₹${baseAmt.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 20,
                            fontWeight: FontWeight.w900, color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 20),

              // Coupon
              const Text('Have a coupon?',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                      color: AppColors.textDark)),
              const SizedBox(height: 10),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _couponApplied ? Colors.green
                        : _couponError != null ? Colors.red
                        : const Color(0xFFDDDDDD),
                    width: 1.5,
                  ),
                  color: _couponApplied ? const Color(0xFFEDF7ED) : Colors.white,
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
                              color: Color(0xFFBBBBBB), fontSize: 14),
                          border:         InputBorder.none,
                          enabledBorder:  InputBorder.none,
                          focusedBorder:  InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense:        true,
                          contentPadding: EdgeInsets.zero,
                          filled:         false,
                        ),
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: _couponApplied
                              ? Colors.green.shade700 : AppColors.textDark,
                        ),
                      ),
                    ),
                    Container(width: 1, height: 28, color: const Color(0xFFEEEEEE)),
                    if (_couponApplied)
                      GestureDetector(
                        onTap: _removeCoupon,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(Icons.close, size: 18, color: AppColors.textGrey),
                        ),
                      )
                    else if (_couponLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: AppColors.primary, strokeWidth: 2)),
                      )
                    else
                      GestureDetector(
                        onTap: _couponController.text.trim().isEmpty
                            ? null : _applyCoupon,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Apply',
                              style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14,
                                color: _couponController.text.trim().isEmpty
                                    ? AppColors.primary.withOpacity(0.4)
                                    : AppColors.primary,
                              )),
                        ),
                      ),
                  ]),
                ),
              ),
              if (_couponError != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.error_outline, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(child: Text(_couponError!,
                      style: const TextStyle(fontSize: 12, color: Colors.red))),
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
                    style: const TextStyle(fontSize: 12, color: Colors.green,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ],

              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 16),

              // Amount breakdown
              _AmountRow('Plan price', '₹${baseAmt.toStringAsFixed(2)}'),
              const SizedBox(height: 10),
              _AmountRow('GST (18%)', '₹${_gstAmount.toStringAsFixed(2)}'),
              if (_couponApplied && _couponResult != null) ...[
                const SizedBox(height: 10),
                _AmountRow(
                  'Discount (${_couponResult!.discountLabel})',
                  '−₹${_couponResult!.discountAmount.toStringAsFixed(2)}',
                  valueColor: Colors.green,
                ),
              ],
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17,
                        color: AppColors.primary)),
                Text('₹${_finalTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w900,
                        fontSize: 22, color: AppColors.primary)),
              ]),

              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 20),

              // Pay via
              const Text('Pay via',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                      color: AppColors.textDark)),
              const SizedBox(height: 12),

              _PayOption(
                mode: 'wallet', selected: _mode == 'wallet',
                icon: Icons.account_balance_wallet_outlined,
                title: 'Wallet Balance',
                subtitle: '₹${widget.walletBalance.toStringAsFixed(2)}',
                onTap: () => setState(() => _mode = 'wallet'),
              ),
              const SizedBox(height: 10),
              _PayOption(
                mode: 'pg', selected: _mode == 'pg',
                icon: Icons.payment_rounded,
                title: 'Payment Gateway',
                subtitle: 'UPI · Card · Net Banking',
                onTap: () => setState(() => _mode = 'pg'),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.shield_outlined, size: 12, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  const Text('Secured by Omniware · PCI-DSS compliant',
                      style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
                ]),
              ),
              const SizedBox(height: 24),

              // Pay button
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : () {
                    setState(() => _loading = true);
                    widget.onConfirm(
                      _mode,
                      _couponApplied
                          ? _couponController.text.trim().toUpperCase()
                          : null,
                      _finalTotal,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(height: 22, width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                      : Text('Pay ₹${_finalTotal.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w700, fontSize: 17)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  final String mode, title, subtitle;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _PayOption({
    required this.mode, required this.title, required this.subtitle,
    required this.selected, required this.icon, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFDDDDDD),
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 14, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(
                    fontSize: 12, color: AppColors.textGrey)),
              ])),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: selected ? null : Border.all(
                  color: const Color(0xFFDDDDDD), width: 2),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _AmountRow extends StatelessWidget {
  final String label, value;
  final Color  valueColor;
  const _AmountRow(this.label, this.value,
      {this.valueColor = AppColors.textDark});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textGrey)),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
          color: valueColor)),
    ]);
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
        ? DateTime.tryParse(result['expires_at'].toString()) : null;
    final startDate = result['start_date'] != null
        ? DateTime.tryParse(result['start_date'].toString()) : null;
    final isQueued  = result['is_queued'] == true;
    final discount  = (result['discount_applied'] as num?)?.toDouble() ?? 0;
    final coupon    = result['coupon_code'] as String?;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: isQueued ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isQueued ? Icons.schedule_rounded : Icons.check_circle_rounded,
              color: isQueued ? Colors.orange : Colors.green, size: 44,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isQueued ? 'Plan Queued! 🕐' : 'Plan Activated! 🎉',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Text(planName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
          const SizedBox(height: 4),
          if (isQueued && startDate != null)
            Text('Starts on ${startDate.day}/${startDate.month}/${startDate.year}',
                style: const TextStyle(color: AppColors.textGrey, fontSize: 13))
          else if (expiresAt != null)
            Text(
                'Valid until ${expiresAt.day}/${expiresAt.month}/${expiresAt.year}',
                style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
          if (discount > 0 && coupon != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.local_offer_rounded,
                    color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(
                  'Coupon $coupon saved you ₹${discount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, color: Colors.green,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis, maxLines: 2,
                )),
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done',
                  style: TextStyle(color: Colors.white,
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
        const Icon(Icons.schedule_rounded, color: Colors.white70, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sub.planName,
                style: const TextStyle(color: Colors.white70,
                    fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              sub.startsAt != null
                  ? 'Queued · Starts ${sub.startsAt!.day}/${sub.startsAt!.month}/${sub.startsAt!.year}'
                  : 'Queued · Starts after current plan',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ]),
        ),
        Text('${sub.speedMbps} Mbps',
            style: const TextStyle(color: Colors.white60,
                fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }
}