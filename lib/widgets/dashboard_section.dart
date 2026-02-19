// lib/widgets/dashboard_section.dart
//
// Usage in home_screen.dart:
//   import '../../widgets/dashboard_section.dart';
//   DashboardSection(data: vm.dashboardData, onPayNow: widget.onNavigateToPay),

import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum RouterConnectionState { online, offline, limited }

class DashboardData {
  final RouterConnectionState connectionState;
  final String planName;
  final String planSpeed;
  final DateTime planExpiry;
  final int daysRemaining;

  final double dataUsedGb;
  final double dataTotalGb; // 0 = unlimited

  final double uploadGb;
  final double downloadGb;

  final double outstandingAmount;
  final DateTime? nextBillDate;

  const DashboardData({
    required this.connectionState,
    required this.planName,
    required this.planSpeed,
    required this.planExpiry,
    required this.daysRemaining,
    required this.dataUsedGb,
    required this.dataTotalGb,
    required this.uploadGb,
    required this.downloadGb,
    required this.outstandingAmount,
    this.nextBillDate,
  });

  bool get isUnlimited => dataTotalGb == 0;
  double get usagePercent =>
      isUnlimited ? 0 : (dataUsedGb / dataTotalGb).clamp(0.0, 1.0);

  static DashboardData mock() => DashboardData(
    connectionState:   RouterConnectionState.online,
    planName:          'Speedo Gold 100',
    planSpeed:         '100 Mbps',
    planExpiry:        DateTime.now().add(const Duration(days: 18)),
    daysRemaining:     18,
    dataUsedGb:        62.4,
    dataTotalGb:       100.0,
    uploadGb:          12.1,
    downloadGb:        50.3,
    outstandingAmount: 1299.0,
    nextBillDate:      DateTime.now().add(const Duration(days: 18)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ROOT WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class DashboardSection extends StatelessWidget {
  final DashboardData? data;
  final VoidCallback? onPayNow;

  const DashboardSection({super.key, this.data, this.onPayNow});

  @override
  Widget build(BuildContext context) {
    final d = data;
    if (d == null) return const _SkeletonDashboard();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Row 1: Upload | Download | Ping — 3 separate cards
        _TopStatsRow(data: d),
        const SizedBox(height: 12),

        // Row 2: Plan card with connection status inline
        _PlanCardWide(data: d),
        const SizedBox(height: 12),

        // Row 3: Data usage gauge
        _DataUsageCard(data: d),
        const SizedBox(height: 12),

        // Row 4: Billing card
        _BillingCard(data: d, onPayNow: onPayNow),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP STATS ROW — 3 individual cards side by side
// ─────────────────────────────────────────────────────────────────────────────

class _TopStatsRow extends StatelessWidget {
  final DashboardData data;
  const _TopStatsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(
          icon: Icons.upload_outlined,
          label: 'Upload',
          value: '${data.uploadGb.toStringAsFixed(1)} GB',
          color: const Color(0xFF4CAF50),
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          icon: Icons.download_outlined,
          label: 'Download',
          value: '${data.downloadGb.toStringAsFixed(1)} GB',
          color: const Color(0xFF2196F3),
        )),
        const SizedBox(width: 10),
        // Ping — replace '12 ms' with real latency from your API
        const Expanded(child: _StatCard(
          icon: Icons.wifi_tethering,
          label: 'Ping',
          value: '12 ms',
          color: Color(0xFF9C27B0),
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF1A1A2E), size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAN CARD WIDE  (plan info left | divider | connection status right)
// ─────────────────────────────────────────────────────────────────────────────

class _PlanCardWide extends StatelessWidget {
  final DashboardData data;
  const _PlanCardWide({required this.data});

  Color get _stateColor {
    switch (data.connectionState) {
      case RouterConnectionState.online:  return const Color(0xFF4CAF50);
      case RouterConnectionState.limited: return const Color(0xFFFFA726);
      case RouterConnectionState.offline: return const Color(0xFFF44336);
    }
  }

  String get _stateLabel {
    switch (data.connectionState) {
      case RouterConnectionState.online:  return 'Online';
      case RouterConnectionState.limited: return 'Limited';
      case RouterConnectionState.offline: return 'Offline';
    }
  }

  IconData get _stateIcon {
    switch (data.connectionState) {
      case RouterConnectionState.online:  return Icons.wifi_rounded;
      case RouterConnectionState.limited: return Icons.wifi_lock_rounded;
      case RouterConnectionState.offline: return Icons.wifi_off_rounded;
    }
  }

  Color get _expiryColor {
    if (data.daysRemaining <= 5)  return const Color(0xFFF44336);
    if (data.daysRemaining <= 10) return const Color(0xFFFFA726);
    return const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // ── Left: plan info ──────────────────────────────────────────────
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Active Plan',
                  style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
              const SizedBox(height: 4),
              Text(
                data.planName,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(data.planSpeed,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Icon(Icons.calendar_today_rounded, size: 12, color: _expiryColor),
                const SizedBox(width: 3),
                Text('${data.daysRemaining}d left',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _expiryColor)),
              ]),
            ]),
          ),

          // ── Divider ──────────────────────────────────────────────────────
          Container(
            width: 1, height: 52,
            color: const Color(0xFFEEEEEE),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // ── Right: connection status ──────────────────────────────────────
          Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(color: _stateColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(_stateLabel,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: _stateColor)),
            ]),
            const SizedBox(height: 8),
            Icon(_stateIcon, size: 28, color: _stateColor),
            const SizedBox(height: 4),
            const Text('Router',
                style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA USAGE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _DataUsageCard extends StatelessWidget {
  final DashboardData data;
  const _DataUsageCard({required this.data});

  Color get _barColor {
    final p = data.usagePercent;
    if (p >= 0.9) return const Color(0xFFF44336);
    if (p >= 0.7) return const Color(0xFFFFA726);
    return const Color(0xFF1A1A2E);
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Data Usage',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          Text(
            data.isUnlimited
                ? 'Unlimited'
                : '${data.dataTotalGb.toStringAsFixed(0)} GB plan',
            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
        ]),
        const SizedBox(height: 16),

        if (data.isUnlimited)
          _UnlimitedBadge()
        else ...[
          Center(
            child: SizedBox(
              width: 140, height: 80,
              child: CustomPaint(
                painter: _ArcPainter(progress: data.usagePercent, color: _barColor),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        data.dataUsedGb.toStringAsFixed(1),
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _barColor),
                      ),
                      const Text('GB used',
                          style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: data.usagePercent,
              minHeight: 8,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation(_barColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${data.dataUsedGb.toStringAsFixed(1)} GB used',
                style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
            Text(
                '${(data.dataTotalGb - data.dataUsedGb).toStringAsFixed(1)} GB left',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _barColor)),
          ]),
        ],
      ]),
    );
  }
}

class _UnlimitedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(children: [
      const Icon(Icons.all_inclusive_rounded, size: 40, color: Color(0xFF1A1A2E)),
      const SizedBox(height: 8),
      const Text('Unlimited Data',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
      const SizedBox(height: 4),
      Text('No data cap on your current plan',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
    ]));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ARC PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 4;
    final r  = size.width / 2 - 8;

    final trackPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi, math.pi, false, trackPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi, math.pi * progress, false, fillPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// BILLING CARD
// ─────────────────────────────────────────────────────────────────────────────

class _BillingCard extends StatelessWidget {
  final DashboardData data;
  final VoidCallback? onPayNow;
  const _BillingCard({required this.data, this.onPayNow});

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final hasOutstanding = data.outstandingAmount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasOutstanding
              ? [const Color(0xFF1A1A2E), const Color(0xFF2D2D5E)]
              : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            hasOutstanding ? 'Amount Due' : 'All Paid ✓',
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            hasOutstanding
                ? '₹${data.outstandingAmount.toStringAsFixed(0)}'
                : '₹0',
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          if (data.nextBillDate != null) ...[
            const SizedBox(height: 4),
            Text(
              hasOutstanding
                  ? 'Due by ${_formatDate(data.nextBillDate!)}'
                  : 'Next bill ${_formatDate(data.nextBillDate!)}',
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
            ),
          ],
        ])),
        if (hasOutstanding)
          GestureDetector(
            onTap: onPayNow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Pay Now',
                  style: TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ),
          )
        else
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 40),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON LOADER
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonDashboard extends StatefulWidget {
  const _SkeletonDashboard();
  @override
  State<_SkeletonDashboard> createState() => _SkeletonDashboardState();
}

class _SkeletonDashboardState extends State<_SkeletonDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Column(children: [
          Row(children: [
            Expanded(child: _SkeletonBox(height: 90)),
            const SizedBox(width: 10),
            Expanded(child: _SkeletonBox(height: 90)),
            const SizedBox(width: 10),
            Expanded(child: _SkeletonBox(height: 90)),
          ]),
          const SizedBox(height: 12),
          _SkeletonBox(height: 80),
          const SizedBox(height: 12),
          _SkeletonBox(height: 180),
          const SizedBox(height: 12),
          _SkeletonBox(height: 90),
        ]),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  const _SkeletonBox({required this.height});
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFEEEEEE),
      borderRadius: BorderRadius.circular(16),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED CARD SHELL
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
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
    child: child,
  );
}