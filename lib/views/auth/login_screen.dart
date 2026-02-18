import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  /// Called when login succeeds — navigate to AppShell from here.
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _vm = AuthViewModel();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _vm.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    _vm.setPhone(_phoneController.text);
    _vm.setPassword(_passwordController.text);
    final ok = await _vm.loginWithPassword();
    if (ok && mounted) widget.onLoginSuccess();
  }

  Future<void> _handleOtpAction() async {
    _vm.setPhone(_phoneController.text);
    if (!_vm.otpSent) {
      await _vm.requestOtp();
    } else {
      _vm.setOtp(_otpController.text);
      final ok = await _vm.verifyOtp();
      if (ok && mounted) widget.onLoginSuccess();
    }
  }

  void _showForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ForgotPasswordSheet(vm: _vm),
    );
  }

  void _showSignUp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sign up flow coming soon!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
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
                // ── Red hero section ─────────────────────────────────────
                _HeroSection(),

                // ── White card ───────────────────────────────────────────
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
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: 24,
                            right: 24,
                            top: 28,
                            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                          ),
                          child: _vm.mode == AuthMode.password
                              ? _PasswordForm(
                                  vm: _vm,
                                  phoneController: _phoneController,
                                  passwordController: _passwordController,
                                  onLogin: _handleLogin,
                                  onForgotPassword: _showForgotPassword,
                                  onSignUp: _showSignUp,
                                  onSwitchToOtp: () =>
                                      _vm.switchMode(AuthMode.otp),
                                )
                              : _OtpForm(
                                  vm: _vm,
                                  phoneController: _phoneController,
                                  otpController: _otpController,
                                  onAction: _handleOtpAction,
                                  onSignUp: _showSignUp,
                                  onSwitchToPassword: () =>
                                      _vm.switchMode(AuthMode.password),
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

// ── Hero section (red area with illustration) ────────────────────────────────

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      width: double.infinity,
      color: AppColors.primary,
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 60,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Cloud shapes
          Positioned(
            top: 55,
            right: 20,
            child: _CloudShape(width: 48, height: 24, opacity: 0.25),
          ),
          Positioned(
            top: 35,
            right: 90,
            child: _CloudShape(width: 32, height: 16, opacity: 0.18),
          ),

          // Content
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 28,
              right: 28,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text side
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "Hi" speech bubble
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Hi',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Welcome\nBack!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Illustration (person on rocket)
                _RocketIllustration(),
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
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

class _RocketIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rocket body
          Positioned(
            bottom: 0,
            child: Container(
              width: 70,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                border:
                    Border.all(color: Colors.white.withOpacity(0.4), width: 2),
              ),
            ),
          ),
          // Flame
          Positioned(
            bottom: -10,
            child: Container(
              width: 30,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.yellow],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          // Person silhouette
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                // Head
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD5B4),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 2),
                // Body
                Container(
                  width: 36,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white70,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          // Waving hand
          Positioned(
            top: 20,
            right: 0,
            child: Transform.rotate(
              angle: -0.4,
              child: Container(
                width: 16,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD5B4),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Password login form ───────────────────────────────────────────────────────

class _PasswordForm extends StatelessWidget {
  final AuthViewModel vm;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignUp;
  final VoidCallback onSwitchToOtp;

  const _PasswordForm({
    required this.vm,
    required this.phoneController,
    required this.passwordController,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onSignUp,
    required this.onSwitchToOtp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Log In',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Mobile number
        _FieldLabel(text: 'Mobile No.'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: phoneController,
          hint: 'Enter mobile number',
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: vm.setPhone,
        ),
        const SizedBox(height: 20),

        // Password
        _FieldLabel(text: 'Password'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: passwordController,
          hint: 'Enter password',
          obscureText: !vm.isPasswordVisible,
          onChanged: vm.setPassword,
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

        // Error message
        if (vm.errorMessage != null) ...[
          const SizedBox(height: 10),
          _ErrorBanner(message: vm.errorMessage!),
        ],

        // Forgot password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Login button
        _PrimaryButton(
          label: 'Login',
          isLoading: vm.isLoading,
          onTap: onLogin,
        ),
        const SizedBox(height: 20),

        // Sign up
        Center(
          child: GestureDetector(
            onTap: onSignUp,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
                children: [
                  const TextSpan(text: "Don't have an account? "),
                  TextSpan(
                    text: 'Sign up',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),
        const _Divider(label: 'OR'),
        const SizedBox(height: 20),

        // Login with OTP
        Center(
          child: TextButton(
            onPressed: onSwitchToOtp,
            child: const Text(
              'Login with OTP',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── OTP login form ────────────────────────────────────────────────────────────

class _OtpForm extends StatelessWidget {
  final AuthViewModel vm;
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final VoidCallback onAction;
  final VoidCallback onSignUp;
  final VoidCallback onSwitchToPassword;

  const _OtpForm({
    required this.vm,
    required this.phoneController,
    required this.otpController,
    required this.onAction,
    required this.onSignUp,
    required this.onSwitchToPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Log In with OTP',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Mobile number
        _FieldLabel(text: 'Mobile No.'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: phoneController,
          hint: 'Enter mobile number',
          keyboardType: TextInputType.phone,
          maxLength: 10,
          enabled: !vm.otpSent,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: vm.setPhone,
        ),

        // OTP field (shown after OTP is sent)
        if (vm.otpSent) ...[
          const SizedBox(height: 20),
          _FieldLabel(text: 'Enter OTP'),
          const SizedBox(height: 8),
          _AuthTextField(
            controller: otpController,
            hint: '6-digit OTP',
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: vm.setOtp,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => vm.switchMode(AuthMode.otp),
              child: const Text(
                'Resend OTP',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],

        // Error message
        if (vm.errorMessage != null) ...[
          const SizedBox(height: 10),
          _ErrorBanner(message: vm.errorMessage!),
        ],

        // Success banner
        if (vm.otpSent && vm.status != AuthStatus.error) ...[
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: Colors.green.shade600, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'OTP sent! Use 123456 for demo.',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Primary action button
        _PrimaryButton(
          label: vm.otpSent ? 'Verify OTP' : 'Send OTP',
          isLoading: vm.isLoading,
          onTap: onAction,
        ),
        const SizedBox(height: 20),

        // Sign up
        Center(
          child: GestureDetector(
            onTap: onSignUp,
            child: RichText(
              text: TextSpan(
                style:
                    const TextStyle(fontSize: 14, color: AppColors.textGrey),
                children: [
                  const TextSpan(text: "Don't have an account? "),
                  TextSpan(
                    text: 'Sign up',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),
        const _Divider(label: 'OR'),
        const SizedBox(height: 20),

        // Switch back to password
        Center(
          child: TextButton(
            onPressed: onSwitchToPassword,
            child: const Text(
              'Login with Password',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Forgot password bottom sheet ─────────────────────────────────────────────

class _ForgotPasswordSheet extends StatefulWidget {
  final AuthViewModel vm;
  const _ForgotPasswordSheet({required this.vm});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _ctrl = TextEditingController();
  bool _sent = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.vm.forgotPassword();
    if (mounted) {
      setState(() {
        _loading = false;
        if (result) {
          _sent = true;
        } else {
          _error = widget.vm.errorMessage;
        }
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Enter your registered mobile number and we'll send a reset link.",
            style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.5),
          ),
          const SizedBox(height: 24),

          if (!_sent) ...[
            _FieldLabel(text: 'Mobile No.'),
            const SizedBox(height: 8),
            _AuthTextField(
              controller: _ctrl,
              hint: 'Enter mobile number',
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: widget.vm.setPhone,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              _ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 20),
            _PrimaryButton(
              label: 'Send Reset Link',
              isLoading: _loading,
              onTap: _submit,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Reset link sent! Check your messages.',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _PrimaryButton(
              label: 'Done',
              isLoading: false,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final bool enabled;
  final TextInputType keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const _AuthTextField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.inputFormatters,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1.2),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          counterText: '',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          shadowColor: AppColors.primary.withOpacity(0.35),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
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
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.borderColor, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.borderColor, height: 1)),
      ],
    );
  }
}