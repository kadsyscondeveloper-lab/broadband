// lib/views/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/signup_viewmodel.dart';

class SignupScreen extends StatefulWidget {
  /// Called when signup succeeds — navigate to AppShell from here.
  final VoidCallback onSignupSuccess;

  /// Called when user taps "Already have an account? Login"
  final VoidCallback onNavigateToLogin;

  const SignupScreen({
    super.key,
    required this.onSignupSuccess,
    required this.onNavigateToLogin,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _vm                     = SignupViewModel();
  final _nameController         = TextEditingController();
  final _phoneController        = TextEditingController();
  final _passwordController     = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController     = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end:   Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    _vm.dispose();
    super.dispose();
  }

  // ── Signup action ─────────────────────────────────────────────────────────

  Future<void> _handleSignup() async {
    _vm.setName(_nameController.text);
    _vm.setPhone(_phoneController.text);
    _vm.setPassword(_passwordController.text);
    _vm.setConfirmPassword(_confirmPasswordController.text);
    _vm.setReferralCode(_referralController.text);

    final ok = await _vm.signup();
    if (ok && mounted) widget.onSignupSuccess();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        resizeToAvoidBottomInset: true,
        body: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            return Column(
              children: [
                // ── Red hero section ───────────────────────────────────
                _HeroSection(),

                // ── White form card ────────────────────────────────────
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft:  Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left:   24,
                            right:  24,
                            top:    28,
                            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                          ),
                          child: _SignupForm(
                            vm:                       _vm,
                            nameController:           _nameController,
                            phoneController:          _phoneController,
                            passwordController:       _passwordController,
                            confirmPasswordController: _confirmPasswordController,
                            referralController:       _referralController,
                            onSignup:                 _handleSignup,
                            onNavigateToLogin: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Hero section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width:  double.infinity,
      color:  AppColors.primary,
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 20, right: 60,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Cloud shapes
          Positioned(
            top: 55, right: 20,
            child: _CloudShape(width: 48, height: 24, opacity: 0.25),
          ),
          Positioned(
            top: 35, right: 130,
            child: _CloudShape(width: 32, height: 16, opacity: 0.18),
          ),

          // Content
          Padding(
            padding: EdgeInsets.only(
              top:   MediaQuery.of(context).padding.top + 20,
              left:  28,
              right: 28,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text side
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "Hello" speech bubble
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft:     Radius.circular(12),
                          topRight:    Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:      Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset:     const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Hello',
                        style: TextStyle(
                          color:      AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize:   20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Let's Get\nStarted!",
                      style: TextStyle(
                        color:       Colors.white,
                        fontSize:    34,
                        fontWeight:  FontWeight.w900,
                        height:      1.15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Illustration
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Image.asset(
                    'assets/images/signup_illustration.png',
                    width:  150,
                    height: 170,
                    fit:    BoxFit.contain,
                    // Fallback if asset not available yet
                    errorBuilder: (_, __, ___) => const SizedBox(
                        width: 150, height: 170),
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

class _CloudShape extends StatelessWidget {
  final double width, height, opacity;
  const _CloudShape(
      {required this.width, required this.height, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
    width:  width,
    height: height,
    decoration: BoxDecoration(
      color:        Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(height / 2),
    ),
  );
}

// ── Signup form ───────────────────────────────────────────────────────────────

class _SignupForm extends StatelessWidget {
  final SignupViewModel           vm;
  final TextEditingController     nameController;
  final TextEditingController     phoneController;
  final TextEditingController     passwordController;
  final TextEditingController     confirmPasswordController;
  final TextEditingController     referralController;
  final VoidCallback              onSignup;
  final VoidCallback              onNavigateToLogin;

  const _SignupForm({
    required this.vm,
    required this.nameController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.referralController,
    required this.onSignup,
    required this.onNavigateToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Title
        const Center(
          child: Text(
            'Create an Account',
            style: TextStyle(
              fontSize:   22,
              fontWeight: FontWeight.w800,
              color:      AppColors.textDark,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Full Name
        _FieldLabel(text: 'Full Name'),
        const SizedBox(height: 8),
        _SignupTextField(
          controller:    nameController,
          hint:          'Enter your full name',
          keyboardType:  TextInputType.name,
          textCapitalization: TextCapitalization.words,
          onChanged:     vm.setName,
        ),
        const SizedBox(height: 20),

        // Mobile No.
        _FieldLabel(text: 'Mobile No.'),
        const SizedBox(height: 8),
        _SignupTextField(
          controller:       phoneController,
          hint:             'Enter mobile number',
          keyboardType:     TextInputType.phone,
          maxLength:        10,
          inputFormatters:  [FilteringTextInputFormatter.digitsOnly],
          onChanged:        vm.setPhone,
        ),
        const SizedBox(height: 20),

        // Password
        _FieldLabel(text: 'Password'),
        const SizedBox(height: 8),
        _SignupTextField(
          controller:  passwordController,
          hint:        'Create a password',
          obscureText: !vm.isPasswordVisible,
          onChanged:   vm.setPassword,
          suffixIcon: GestureDetector(
            onTap: vm.togglePasswordVisibility,
            child: Icon(
              vm.isPasswordVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textGrey,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Confirm Password
        _FieldLabel(text: 'Confirm Password'),
        const SizedBox(height: 8),
        _SignupTextField(
          controller:  confirmPasswordController,
          hint:        'Re-enter your password',
          obscureText: !vm.isConfirmPasswordVisible,
          onChanged:   vm.setConfirmPassword,
          suffixIcon: GestureDetector(
            onTap: vm.toggleConfirmPasswordVisibility,
            child: Icon(
              vm.isConfirmPasswordVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textGrey,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Referral Code
        _FieldLabel(text: 'Referral Code'),
        const SizedBox(height: 8),
        _SignupTextField(
          controller: referralController,
          hint:       'Enter referral code (optional)',
          onChanged:  vm.setReferralCode,
        ),
        const SizedBox(height: 24),

        // Terms & Conditions checkbox
        GestureDetector(
          onTap: vm.toggleAgreedToTerms,
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width:  24,
                height: 24,
                child: Checkbox(
                  value:           vm.agreedToTerms,
                  onChanged:       (_) => vm.toggleAgreedToTerms(),
                  activeColor:     AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textGrey),
                    children: [
                      const TextSpan(text: 'Yes, I agree to the '),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: const TextStyle(
                          color:      AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Error banner
        if (vm.errorMessage != null) ...[
          const SizedBox(height: 8),
          _ErrorBanner(message: vm.errorMessage!),
        ],

        const SizedBox(height: 24),

        // Sign Up button
        SizedBox(
          width:  double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: vm.isLoading ? null : onSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor:         AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation:   2,
              shadowColor: AppColors.primary.withOpacity(0.35),
            ),
            child: vm.isLoading
                ? const SizedBox(
              width:  22,
              height: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            )
                : const Text(
              'Sign Up',
              style: TextStyle(
                color:      Colors.white,
                fontWeight: FontWeight.w800,
                fontSize:   16,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Already have an account?
        Center(
          child: GestureDetector(
            onTap: onNavigateToLogin,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textGrey),
                children: [
                  const TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Login',
                    style: const TextStyle(
                      color:      AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize:   13,
      fontWeight: FontWeight.w600,
      color:      AppColors.textGrey,
    ),
  );
}

class _SignupTextField extends StatelessWidget {
  final TextEditingController      controller;
  final String                     hint;
  final bool                       obscureText;
  final TextInputType              keyboardType;
  final int?                       maxLength;
  final List<TextInputFormatter>?  inputFormatters;
  final Widget?                    suffixIcon;
  final ValueChanged<String>?      onChanged;
  final TextCapitalization         textCapitalization;

  const _SignupTextField({
    required this.controller,
    required this.hint,
    this.obscureText         = false,
    this.keyboardType        = TextInputType.text,
    this.maxLength,
    this.inputFormatters,
    this.suffixIcon,
    this.onChanged,
    this.textCapitalization  = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.borderColor, width: 1.2),
      ),
      child: TextField(
        controller:         controller,
        obscureText:        obscureText,
        keyboardType:       keyboardType,
        maxLength:          maxLength,
        inputFormatters:    inputFormatters,
        onChanged:          onChanged,
        textCapitalization: textCapitalization,
        style: const TextStyle(
          fontSize:   15,
          color:      AppColors.textDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText:       hint,
          hintStyle: const TextStyle(
              color: AppColors.textLight, fontSize: 14),
          suffixIcon:     suffixIcon,
          border:         InputBorder.none,
          counterText:    '',
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color:      AppColors.primary,
                fontSize:   13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}