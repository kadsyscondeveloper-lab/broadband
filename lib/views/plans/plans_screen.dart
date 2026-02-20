// lib/views/plans/plans_screen.dart

import 'package:flutter/material.dart';
import '../../models/plan_model.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/plans_viewmodel.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen>
    with SingleTickerProviderStateMixin {
  late final PlansViewModel _vm;
  late final TabController _tabs;

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

  // ── Purchase confirm dialog ──────────────────────────────────────────────────
  void _confirmPurchase(Plan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PurchaseSheet(
        plan: plan,
        onConfirm: (mode) async {
          Navigator.pop(context);
          await _vm.purchasePlan(plan.id, paymentMode: mode);
          if (!mounted) return;
          if (_vm.purchaseState == PlanPurchaseState.success) {
            _showSuccessDialog(_vm.purchaseResult!);
          } else {
            _showErrorSnack(_vm.purchaseError ?? 'Purchase failed');
          }
          _vm.resetPurchaseState();
        },
      ),
    );
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(result: result, onDone: () => Navigator.pop(context)),
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
                      Row(children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const Text('Choose a Plan',
                            style: TextStyle(color: Colors.white,
                                fontSize: 20, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 20),

                      // Active subscription banner
                      if (_vm.activeSub != null) _ActiveSubBanner(sub: _vm.activeSub!),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                    ),
                    child: TabBar(
                      controller: _tabs,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textLight,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      padding: const EdgeInsets.all(4),
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
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (_vm.error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      Text(_vm.error!, style: const TextStyle(color: AppColors.textGrey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _vm.load,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
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
                        _PlanList(plans: _vm.monthlyPlans,   activeSub: _vm.activeSub, onSelect: _confirmPurchase),
                        _PlanList(plans: _vm.quarterlyPlans, activeSub: _vm.activeSub, onSelect: _confirmPurchase),
                        _PlanList(plans: _vm.annualPlans,    activeSub: _vm.activeSub, onSelect: _confirmPurchase),
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
// ACTIVE SUBSCRIPTION BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveSubBanner extends StatelessWidget {
  final ActiveSubscription sub;
  const _ActiveSubBanner({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.30)),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(sub.planName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            sub.isExpiringSoon
                ? '⚠️ Expires in ${sub.daysRemaining} days'
                : 'Active · ${sub.daysRemaining} days left',
            style: TextStyle(
              color: sub.isExpiringSoon ? Colors.amber : Colors.white70,
              fontSize: 12,
            ),
          ),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${sub.speedMbps} Mbps',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const Text('current plan', style: TextStyle(color: Colors.white60, fontSize: 10)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAN LIST
// ─────────────────────────────────────────────────────────────────────────────

class _PlanList extends StatelessWidget {
  final List<Plan> plans;
  final ActiveSubscription? activeSub;
  final void Function(Plan) onSelect;

  const _PlanList({required this.plans, required this.activeSub, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const Center(
        child: Text('No plans available', style: TextStyle(color: AppColors.textGrey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final plan = plans[i];
        final isCurrent = activeSub?.planId == plan.id;
        return _PlanCard(plan: plan, isCurrent: isCurrent, onSelect: () => onSelect(plan));
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAN CARD
// ─────────────────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isCurrent;
  final VoidCallback onSelect;

  const _PlanCard({required this.plan, required this.isCurrent, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isPopular = plan.speedMbps == 100 && plan.validityDays == 30;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent
                  ? Colors.green
                  : isPopular
                  ? AppColors.primary
                  : AppColors.borderColor,
              width: isCurrent || isPopular ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            // Speed badge
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                color: isCurrent
                    ? Colors.green.shade50
                    : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  plan.speedMbps >= 1000
                      ? '${plan.speedMbps ~/ 1000}'
                      : '${plan.speedMbps}',
                  style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900,
                    color: isCurrent ? Colors.green : AppColors.primary,
                  ),
                ),
                Text(
                  plan.speedMbps >= 1000 ? 'Gbps' : 'Mbps',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isCurrent ? Colors.green : AppColors.primary,
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 14),

            // Plan details
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(plan.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                      color: AppColors.textDark)),
              const SizedBox(height: 4),
              Row(children: [
                _Tag(icon: Icons.data_usage, label: plan.dataLabel),
                const SizedBox(width: 8),
                _Tag(icon: Icons.calendar_today_outlined, label: plan.validityLabel),
              ]),
              // description removed — column does not exist in broadband_plans
              if (plan.category != null) ...[               // ← show category badge instead
                const SizedBox(height: 4),
                Text(plan.category!,
                    style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ])),
            const SizedBox(width: 12),

            // Price + button
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹${plan.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                      color: AppColors.textDark)),
              const SizedBox(height: 6),
              isCurrent
                  ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text('Active',
                    style: TextStyle(color: Colors.green, fontSize: 11,
                        fontWeight: FontWeight.w700)),
              )
                  : GestureDetector(
                onTap: onSelect,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Buy',
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),

        // Popular badge
        if (isPopular && !isCurrent)
          Positioned(
            top: -10, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Popular',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AppColors.textGrey),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PURCHASE BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _PurchaseSheet extends StatefulWidget {
  final Plan plan;
  final void Function(String mode) onConfirm;

  const _PurchaseSheet({required this.plan, required this.onConfirm});

  @override
  State<_PurchaseSheet> createState() => _PurchaseSheetState();
}

class _PurchaseSheetState extends State<_PurchaseSheet> {
  String _mode = 'wallet';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Handle
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 20),

        const Text('Confirm Purchase',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 16),

        // Plan summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(plan.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text('${plan.speedLabel} · ${plan.dataLabel} · ${plan.validityLabel}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            ]),
            Text('₹${plan.price.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
          ]),
        ),
        const SizedBox(height: 20),

        // Payment mode
        const Text('Pay via', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const SizedBox(height: 10),

        _ModeOption(value: 'wallet', selected: _mode, label: 'Wallet Balance',
            icon: Icons.account_balance_wallet_outlined,
            onTap: () => setState(() => _mode = 'wallet')),

        const SizedBox(height: 24),

        // Confirm button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : () {
              setState(() => _loading = true);
              widget.onConfirm(_mode);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
            ),
            child: _loading
                ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Pay ₹${plan.price.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
      ]),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String value, selected, label;
  final IconData icon;
  final VoidCallback onTap;

  const _ModeOption({
    required this.value, required this.selected,
    required this.label, required this.icon, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon, color: isSelected ? AppColors.primary : AppColors.textLight, size: 22),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textDark,
          )),
          const Spacer(),
          if (isSelected)
            const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUCCESS DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onDone;

  const _SuccessDialog({required this.result, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final planName  = (result['plan'] as Map<String, dynamic>?)?['name'] ?? 'Plan';
    final expiresAt = result['expires_at'] != null
        ? DateTime.tryParse(result['expires_at'] as String)
        : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 44),
          ),
          const SizedBox(height: 16),
          const Text('Plan Activated!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text(planName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary)),
          if (expiresAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Valid until ${expiresAt.day}/${expiresAt.month}/${expiresAt.year}',
              style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}