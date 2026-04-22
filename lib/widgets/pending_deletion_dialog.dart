// lib/widgets/pending_deletion_dialog.dart
//
// Shown on the login screen when the server returns PENDING_DELETION:<date>.
// Usage:
//   if (result.pendingDeletion) {
//     PendingDeletionDialog.show(context, deletionDate: result.deletionDate);
//   }

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // add 'intl' to pubspec if not already present
import '../theme/app_theme.dart';

class PendingDeletionDialog extends StatelessWidget {
  final DateTime? deletionDate;

  const PendingDeletionDialog({super.key, this.deletionDate});

  static void show(BuildContext context, {DateTime? deletionDate}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PendingDeletionDialog(deletionDate: deletionDate),
    );
  }

  String get _formattedDate {
    if (deletionDate == null) return 'soon';
    return DateFormat('MMMM d, yyyy').format(deletionDate!.toLocal());
  }

  String get _daysLeft {
    if (deletionDate == null) return '';
    final days = deletionDate!.difference(DateTime.now()).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'in 1 day';
    return 'in $days days';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Icon ────────────────────────────────────────────────────
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color:  Colors.orange.shade50,
                shape:  BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule_rounded,
                size:  38,
                color: Colors.orange.shade600,
              ),
            ),
            const SizedBox(height: 16),

            // ── Title ────────────────────────────────────────────────────
            const Text(
              'Account Scheduled\nfor Deletion',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize:   20,
                fontWeight: FontWeight.w800,
                color:      Color(0xFF1A1A2E),
                height:     1.3,
              ),
            ),
            const SizedBox(height: 12),

            // ── Body ─────────────────────────────────────────────────────
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize:   14,
                  color:      Colors.grey.shade600,
                  height:     1.5,
                ),
                children: [
                  const TextSpan(
                    text: 'Your account is scheduled for permanent deletion ',
                  ),
                  TextSpan(
                    text: _daysLeft,
                    style: TextStyle(
                      color:      Colors.orange.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: deletionDate != null
                        ? ' (on $_formattedDate).'
                        : '.',
                  ),
                  const TextSpan(
                    text: '\n\nContact our support team before that date to '
                        'cancel the deletion and restore access.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Contact Support button ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: navigate to support / open WhatsApp / email
                  // e.g. launchUrl(Uri.parse('mailto:support@speedonet.in'))
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:         const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Contact Support',
                  style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize:   15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Dismiss ──────────────────────────────────────────────────
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Dismiss',
                style: TextStyle(
                  color:    Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}