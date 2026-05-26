// lib/widgets/plan_usage_dashboard.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/plan_model.dart';
import '../services/rent_service.dart';
import '../theme/app_theme.dart';

class PlanUsageDashboard extends StatelessWidget {
  final ActiveSubscription? activeSub;
  final RentStatus rentStatus;

  const PlanUsageDashboard({
    super.key,
    required this.activeSub,
    required this.rentStatus,
  });

  // ── Visibility guard ────────────────────────────────────────────────────────

  bool get _shouldShow => activeSub != null || rentStatus.hasActivePlan;

  // ── Plan meta ───────────────────────────────────────────────────────────────

  String get _planName =>
      activeSub?.planName ?? rentStatus.planName ?? 'Active Plan';

  String get _speedLabel => activeSub?.speedLabel ?? '';
  String get _dataLabel  => activeSub?.dataLabel  ?? 'Unlimited';
  int    get _daysRemaining => activeSub?.daysRemaining ?? 0;
  int    get _validityDays  => activeSub?.validityDays  ?? 30;
  bool   get _isExpiringSoon => _daysRemaining <= 5;

  // ── Data-usage proxy (days elapsed → estimated GB) ──────────────────────────

  int get _daysElapsed =>
      (_validityDays - _daysRemaining).clamp(0, _validityDays);

  double get _usagePercentage =>
      _validityDays > 0
          ? (_daysElapsed / _validityDays).clamp(0.0, 1.0)
          : 0.0;

  /// Parse "200 GB" → 200.0 | "Unlimited" → null
  double? get _totalDataGb {
    final raw = _dataLabel.trim();
    if (raw.toLowerCase() == 'unlimited') return null;
    final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
    return m != null ? double.tryParse(m.group(1)!) : null;
  }

  String get _dataUsedLabel {
    final total = _totalDataGb;
    if (total == null) return '$_daysElapsed days';
    final used = total * _usagePercentage;
    return used < 1
        ? '${(used * 1024).toStringAsFixed(0)} MB'
        : '${used.toStringAsFixed(1)} GB';
  }

  String get _dataTotalLabel {
    final total = _totalDataGb;
    return total == null ? 'Unlimited' : '${total.toStringAsFixed(0)} GB';
  }

  // ── Formatting ──────────────────────────────────────────────────────────────

  String _formatExpiry(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    const red = AppColors.primary;
    final pct = _usagePercentage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // Reduced from 0.07/16 → 0.05/10 and 0.08/24 → 0.05/14
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 18),
          _buildMainRow(pct, red),
          const SizedBox(height: 14),
          Divider(color: Colors.grey.shade100, height: 1),
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
        // ── Plan name pill: solid red bg + white text ──────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary,          // solid fill, not washed-out tint
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_rounded, color: Colors.white, size: 13),
              const SizedBox(width: 5),
              Text(
                _planName,
                style: const TextStyle(
                  color: Colors.white,           // white on red — proper contrast
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),

        // ── Speed pill: outlined, sits right next to plan name ─────────────
        if (_speedLabel.isNotEmpty) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.35),
                width: 1.2,
              ),
            ),
            child: Text(
              _speedLabel,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],

        const Spacer(),

        // ── Days remaining pill: solid green or red + white text ───────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _isExpiringSoon
                ? const Color(0xFFE53935)       // solid red
                : const Color(0xFF2E7D32),      // solid deep green
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isExpiringSoon
                    ? Icons.warning_amber_rounded
                    : Icons.access_time_rounded,
                color: Colors.white,
                size: 11,
              ),
              const SizedBox(width: 4),
              Text(
                '$_daysRemaining days left',
                style: const TextStyle(
                  color: Colors.white,           // white on solid bg — clear read
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Main row: arc gauge + stats ─────────────────────────────────────────────

  Widget _buildMainRow(double pct, Color red) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Arc gauge
        SizedBox(
          width: 110,
          height: 110,
          child: CustomPaint(
            painter: _ArcGaugePainter(percentage: pct, color: red),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(pct * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'used',
                    style: TextStyle(
                      color: Colors.grey.shade400,
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
        // Stats column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data usage',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _dataUsedLabel,
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'of $_dataTotalLabel',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Progress bar — red
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(red),
                ),
              ),
              const SizedBox(height: 10),
              // Daily rent — secondary line
              Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: red, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '+₹${rentStatus.dailyRent.toStringAsFixed(2)}/day earned',
                    style: TextStyle(
                      color: red,
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

  // ── Footer: speed / data / expiry ───────────────────────────────────────────

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
    color: Colors.grey.shade100,
  );
}

// ── Footer stat chip ──────────────────────────────────────────────────────────

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
              Icon(icon, color: Colors.grey.shade400, size: 11),
              const SizedBox(width: 4),
              Text(
                sublabel,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Arc gauge painter ─────────────────────────────────────────────────────────

class _ArcGaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  const _ArcGaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center     = Offset(size.width / 2, size.height / 2);
    final radius     = size.width / 2 - 8;
    const startAngle = pi * 0.75;   // 135° — bottom-left
    const sweepFull  = pi * 1.5;    // 270° sweep

    // Background track
    final bgPaint = Paint()
      ..color       = Colors.grey.shade100
      ..strokeWidth  = 10
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull,
      false,
      bgPaint,
    );

    // Filled arc
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