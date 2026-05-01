// lib/widgets/plan_usage_dashboard.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/plan_model.dart';
import '../services/rent_service.dart';

class PlanUsageDashboard extends StatelessWidget {
  final ActiveSubscription? activeSub;
  final RentStatus rentStatus;

  const PlanUsageDashboard({
    super.key,
    required this.activeSub,
    required this.rentStatus,
  });

  // ── Visibility guard ────────────────────────────────────────────────────────

  bool get _shouldShow =>
      activeSub != null || rentStatus.hasActivePlan;

  // ── Derived values ──────────────────────────────────────────────────────────

  double get _amountPaid => activeSub?.amountPaid ?? 0;

  double get _percentage =>
      _amountPaid > 0
          ? (rentStatus.totalCollected / _amountPaid).clamp(0.0, 1.0)
          : 0.0;

  String get _planName =>
      activeSub?.planName ?? rentStatus.planName ?? 'Active Plan';

  String get _speedLabel => activeSub?.speedLabel ?? '';

  String get _dataLabel => activeSub?.dataLabel ?? 'Unlimited';

  int get _daysRemaining => activeSub?.daysRemaining ?? 0;

  bool get _isExpiringSoon => _daysRemaining <= 5;

  String _formatExpiry(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  Color _gaugeColor(double pct) {
    if (pct >= 0.7) return const Color(0xFF4ADE80); // green
    if (pct >= 0.4) return const Color(0xFFFBBF24); // amber
    return const Color(0xFF60A5FA);                  // blue
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    final pct        = _percentage;
    final gaugeColor = _gaugeColor(pct);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildMainRow(pct, gaugeColor),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 14),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        // Plan + speed badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 7),
              Text(
                _planName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_speedLabel.isNotEmpty) ...[
                Container(
                  width: 1,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.white.withOpacity(0.25),
                ),
                Text(
                  _speedLabel,
                  style: const TextStyle(
                    color: Color(0xFFFCD34D),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Spacer(),
        // Days remaining badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _isExpiringSoon
                ? const Color(0xFFEF4444).withOpacity(0.15)
                : const Color(0xFF34D399).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isExpiringSoon
                  ? const Color(0xFFEF4444).withOpacity(0.35)
                  : const Color(0xFF34D399).withOpacity(0.25),
            ),
          ),
          child: Text(
            '$_daysRemaining days left',
            style: TextStyle(
              color: _isExpiringSoon
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFF6EE7B7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Main row: gauge + stats ─────────────────────────────────────────────────

  Widget _buildMainRow(double pct, Color gaugeColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Arc gauge
        SizedBox(
          width: 110,
          height: 110,
          child: CustomPaint(
            painter: _ArcGaugePainter(percentage: pct, color: gaugeColor),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(pct * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'recovered',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Stats
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rent recovery',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              // Amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹${rentStatus.totalCollected.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'of ₹${_amountPaid.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
                ),
              ),
              const SizedBox(height: 10),
              // Daily earn rate
              Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    color: Color(0xFFFCD34D),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+₹${rentStatus.dailyRent.toStringAsFixed(2)}/day',
                    style: const TextStyle(
                      color: Color(0xFFFCD34D),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Footer: speed / data / expiry ────────────────────────────────────────────

  Widget _buildFooter() {
    return Row(
      children: [
        _FooterStat(
          icon: Icons.speed_rounded,
          label: _speedLabel.isEmpty ? '—' : _speedLabel,
          sublabel: 'speed',
        ),
        _buildVerticalDivider(),
        _FooterStat(
          icon: Icons.cloud_outlined,
          label: _dataLabel,
          sublabel: 'data',
        ),
        _buildVerticalDivider(),
        _FooterStat(
          icon: Icons.calendar_today_rounded,
          label: _formatExpiry(activeSub?.expiresAt),
          sublabel: 'expires',
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() => Container(
    width: 1,
    height: 28,
    color: Colors.white.withOpacity(0.08),
  );
}

// ── Footer stat chip ─────────────────────────────────────────────────────────

class _FooterStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;

  const _FooterStat({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.4), size: 11),
              const SizedBox(width: 4),
              Text(
                sublabel,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Arc gauge painter ────────────────────────────────────────────────────────

class _ArcGaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  const _ArcGaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = size.width / 2 - 8;
    // Arc spans 270° — starts at 135° (bottom-left) sweeps clockwise
    const startAngle = pi * 0.75;
    const sweepFull  = pi * 1.5;

    final bgPaint = Paint()
      ..color      = Colors.white.withOpacity(0.08)
      ..strokeWidth = 10
      ..style      = PaintingStyle.stroke
      ..strokeCap  = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull,
      false,
      bgPaint,
    );

    if (percentage > 0) {
      final fgPaint = Paint()
        ..color       = color
        ..strokeWidth  = 10
        ..style       = PaintingStyle.stroke
        ..strokeCap   = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepFull * percentage,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) =>
      old.percentage != percentage || old.color != color;
}