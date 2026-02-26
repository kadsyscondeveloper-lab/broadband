// lib/views/profile/change_password_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/change_password_viewmodel.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final ChangePasswordViewModel _vm;

  final _oldPasswordCtrl     = TextEditingController();
  final _newPasswordCtrl     = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = ChangePasswordViewModel();
  }

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _onContinue() async {
    final success = await _vm.changePassword();
    if (!mounted) return;

    if (success) {
      _showSuccess();
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF4CAF50),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Password Changed!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your password has been updated successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // close dialog
                    Navigator.of(context).pop(); // go back
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // ── Old Password ───────────────────────────────────
                      _FieldLabel(label: 'Old Password'),
                      const SizedBox(height: 8),
                      _PasswordField(
                        controller:     _oldPasswordCtrl,
                        hint:           'Enter old password',
                        isVisible:      _vm.isOldPasswordVisible,
                        onToggle:       _vm.toggleOldPasswordVisibility,
                        onChanged:      _vm.setOldPassword,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),

                      // ── New Password ───────────────────────────────────
                      _FieldLabel(label: 'Password'),
                      const SizedBox(height: 8),
                      _PasswordField(
                        controller:     _newPasswordCtrl,
                        hint:           'Enter new password',
                        isVisible:      _vm.isNewPasswordVisible,
                        onToggle:       _vm.toggleNewPasswordVisibility,
                        onChanged:      _vm.setNewPassword,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),

                      // ── Confirm Password ───────────────────────────────
                      _FieldLabel(label: 'Confirm Password'),
                      const SizedBox(height: 8),
                      _PasswordField(
                        controller:     _confirmPasswordCtrl,
                        hint:           'Re-enter new password',
                        isVisible:      _vm.isConfirmPasswordVisible,
                        onToggle:       _vm.toggleConfirmPasswordVisibility,
                        onChanged:      _vm.setConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted:    (_) { if (_vm.canSubmit) _onContinue(); },
                      ),
                      const SizedBox(height: 28),

                      // ── Validation checklist ───────────────────────────
                      _ValidationChecklist(vm: _vm),

                      // ── Error message ──────────────────────────────────
                      if (_vm.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _ErrorBanner(message: _vm.errorMessage!),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Continue button ────────────────────────────────────────
              _ContinueButton(
                isLoading:  _vm.isLoading,
                canSubmit:  _vm.canSubmit,
                onPressed:  _onContinue,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIELD LABEL
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PASSWORD FIELD
// ─────────────────────────────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String                 hint;
  final bool                   isVisible;
  final VoidCallback           onToggle;
  final ValueChanged<String>   onChanged;
  final TextInputAction        textInputAction;
  final ValueChanged<String>?  onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.isVisible,
    required this.onToggle,
    required this.onChanged,
    required this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller:      controller,
        obscureText:     !isVisible,
        onChanged:       onChanged,
        textInputAction: textInputAction,
        onSubmitted:     onSubmitted,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1A1A2E),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border:         InputBorder.none,
          enabledBorder:  InputBorder.none,
          focusedBorder:  InputBorder.none,
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                isVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFFAAAAAA),
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VALIDATION CHECKLIST
// ─────────────────────────────────────────────────────────────────────────────

class _ValidationChecklist extends StatelessWidget {
  final ChangePasswordViewModel vm;
  const _ValidationChecklist({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CheckItem(
          label:   'Old Password',
          checked: vm.oldPasswordFilled,
        ),
        const SizedBox(height: 10),
        _CheckItem(
          label:   'At least 8 characters',
          checked: vm.hasMinLength,
        ),
        const SizedBox(height: 10),
        _CheckItem(
          label:   'Contains a symbol or a number',
          checked: vm.hasSymbolOrNumber,
        ),
        const SizedBox(height: 10),
        _CheckItem(
          label:   'Password matches',
          checked: vm.passwordsMatch,
        ),
      ],
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final bool   checked;

  const _CheckItem({required this.label, required this.checked});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width:  22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: checked ? AppColors.primary : const Color(0xFFCCCCCC),
              width: 1.8,
            ),
            color: checked
                ? AppColors.primary.withOpacity(0.08)
                : Colors.transparent,
          ),
          child: checked
              ? Icon(Icons.check_rounded,
              size: 14, color: AppColors.primary)
              : null,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: checked
                ? const Color(0xFF1A1A2E)
                : const Color(0xFFAAAAAA),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: Colors.red.shade200),
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded,
            color: Colors.red.shade600, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize:   13,
              color:      Colors.red.shade700,
              fontWeight: FontWeight.w500,
              height:     1.3,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTINUE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _ContinueButton extends StatelessWidget {
  final bool         isLoading;
  final bool         canSubmit;
  final VoidCallback onPressed;

  const _ContinueButton({
    required this.isLoading,
    required this.canSubmit,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        20, 12, 20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: (canSubmit && !isLoading) ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: (canSubmit && !isLoading)
                ? AppColors.primary
                : const Color(0xFFCCCCCC),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: isLoading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
              : const Text(
            'Continue',
            style: TextStyle(
              color:      Colors.white,
              fontSize:   16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}