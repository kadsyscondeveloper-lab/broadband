import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/installation_service.dart';
import '../views/installation/installation_address_screen.dart';
import '../views/installation/installation_tracker_screen.dart';
import '../models/installation_status.dart';

class InstallationStatusCard extends StatefulWidget {
  const InstallationStatusCard({super.key});

  @override
  State<InstallationStatusCard> createState() => _InstallationStatusCardState();
}

class _InstallationStatusCardState extends State<InstallationStatusCard> {
  final _service = InstallationService();

  InstallStatusData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _service.getInstallationStatus();
      if (mounted) setState(() { _data = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final data = _data;

    // ── Nothing to show: installation done OR no plan purchased yet ──────
    if (data == null) return const SizedBox.shrink();
    if (data.installationCompleted && data.pendingPlan == null) {
      return const SizedBox.shrink();
    }

    // ── Case 1: Plan purchased but installation not yet submitted ─────────
    if (data.pendingPlan != null && data.installation == null) {
      return _ActionCard(
        icon: Icons.router_rounded,
        iconColor: AppColors.primary,
        iconBg: AppColors.primary.withOpacity(0.08),
        title: 'Complete Your Installation',
        subtitle:
        '${data.pendingPlan!.planName} plan is paid and ready. '
            'Submit your installation address to get started.',
        buttonLabel: 'Schedule Installation',
        buttonColor: AppColors.primary,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const InstallationAddressScreen(),
            ),
          );
          _load(); // refresh after returning
        },
      );
    }

    // ── Case 2: Installation submitted — show tracker with plan context ───
    if (data.installation != null && !data.installationCompleted) {
      final status = data.installation!.status;
      final (Color color, IconData icon, String label) = _statusMeta(status);

      return _ActionCard(
        icon: icon,
        iconColor: color,
        iconBg: color.withOpacity(0.08),
        title: 'Installation ${_capitalize(label)}',
        subtitle: data.pendingPlan != null
            ? '${data.pendingPlan!.planName} activates automatically once '
            'your router is installed.'
            : 'Track your installation progress.',
        buttonLabel: 'View Status',
        buttonColor: AppColors.primary,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InstallationTrackerScreen(
                requestId: data.installation!.id,
              ),
            ),
          );
          _load();
        },
      );
    }

    return const SizedBox.shrink();
  }

  (Color, IconData, String) _statusMeta(String status) {
    switch (status) {
      case 'assigned':
        return (Colors.purple.shade600, Icons.person_pin_circle_rounded, 'assigned');
      case 'scheduled':
        return (Colors.blue.shade600, Icons.calendar_month_rounded, 'scheduled');
      case 'in_progress':
        return (Colors.orange.shade600, Icons.construction_rounded, 'in progress');
      default: // pending
        return (Colors.orange.shade600, Icons.pending_rounded, 'pending');
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable card widget
// ─────────────────────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final Color    iconBg;
  final String   title;
  final String   subtitle;
  final String   buttonLabel;
  final Color    buttonColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textGrey, height: 1.4),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

