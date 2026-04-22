// lib/views/profile/delete_account_sheet.dart
//
// Bottom sheet that walks the user through account deletion confirmation.
// Usage:
//   await DeleteAccountSheet.show(context, onDeleted: () => /* navigate to login */);

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class DeleteAccountSheet extends StatefulWidget {
  final VoidCallback onDeleted;

  const DeleteAccountSheet({super.key, required this.onDeleted});

  /// Convenience helper — show as a modal bottom sheet.
  static Future<void> show(
      BuildContext context, {
        required VoidCallback onDeleted,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeleteAccountSheet(onDeleted: onDeleted),
    );
  }

  @override
  State<DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<DeleteAccountSheet> {
  bool _confirmed  = false;
  bool _isLoading  = false;
  String? _error;

  static const _deletionDays = 3;

  Future<void> _submit() async {
    if (!_confirmed) return;

    setState(() { _isLoading = true; _error = null; });

    final result = await AuthService().deleteAccount();

    if (!mounted) return;

    if (result.success) {
      Navigator.of(context).pop(); // close sheet
      widget.onDeleted();
    } else {
      setState(() {
        _isLoading = false;
        _error     = result.error ?? 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom
        + MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 8, 24, bottomPad + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Handle ─────────────────────────────────────────────────────
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Warning icon ───────────────────────────────────────────────
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color:  Colors.red.shade50,
              shape:  BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_forever_rounded,
              size:  38,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 16),

          // ── Title ──────────────────────────────────────────────────────
          const Text(
            'Delete Account',
            style: TextStyle(
              fontSize:   20,
              fontWeight: FontWeight.w800,
              color:      Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),

          // ── Body text ──────────────────────────────────────────────────
          Text(
            'Your account will be deactivated immediately and '
                'permanently deleted after $_deletionDays days.\n\n'
                'During this period you will not be able to log in. '
                'Contact support before the deadline to cancel the deletion.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize:   14,
              color:      Colors.grey.shade600,
              height:     1.5,
            ),
          ),
          const SizedBox(height: 8),

          // ── What you'll lose ───────────────────────────────────────────
          _WillLoseList(),
          const SizedBox(height: 20),

          // ── Confirmation checkbox ──────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _confirmed = !_confirmed),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value:           _confirmed,
                    onChanged:       (v) => setState(() => _confirmed = v ?? false),
                    activeColor:     Colors.red.shade600,
                    shape:           RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'I understand that this action cannot be undone and '
                          'I will lose access to my account and all associated data.',
                      style: TextStyle(
                        fontSize:   13,
                        color:      Colors.grey.shade700,
                        height:     1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Error ──────────────────────────────────────────────────────
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border:       Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // ── Action buttons ─────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding:       const EdgeInsets.symmetric(vertical: 14),
                  side:          BorderSide(color: Colors.grey.shade300),
                  shape:         RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color:      Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (_confirmed && !_isLoading) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:         Colors.red.shade600,
                  disabledBackgroundColor: Colors.red.shade200,
                  padding:                 const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5,
                  ),
                )
                    : const Text(
                  'Delete Account',
                  style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── What you'll lose list ─────────────────────────────────────────────────────

class _WillLoseList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      'Active plan & subscription',
      'Wallet balance',
      'Support ticket history',
      'All account data',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You will permanently lose:',
            style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w700,
              color:      Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.remove_circle_outline_rounded,
                    size: 15, color: Colors.red.shade400),
                const SizedBox(width: 8),
                Text(
                  item,
                  style: TextStyle(
                    fontSize: 13,
                    color:    Colors.red.shade700,
                    height:   1.3,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}