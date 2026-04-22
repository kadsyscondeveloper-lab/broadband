// lib/views/auth/contact_support_screen.dart
//
// Accessible from the login screen when a user's account is deactivated or
// they need to reach support before logging in (no auth token required).
// Calls POST /api/v1/contact — the public endpoint.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api_client.dart';
import '../../theme/app_theme.dart';

class ContactSupportScreen extends StatefulWidget {
  /// Optional pre-fill values (e.g. phone from a previous login attempt).
  final String? prefillPhone;

  const ContactSupportScreen({super.key, this.prefillPhone});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _msgCtrl     = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  bool    _isLoading  = false;
  bool    _submitted  = false;
  String? _error;
  String? _refId;

  @override
  void initState() {
    super.initState();
    if (widget.prefillPhone != null) {
      _phoneCtrl.text = widget.prefillPhone!;
    }
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _subjectCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name    = _nameCtrl.text.trim();
    final phone   = _phoneCtrl.text.trim();
    final message = _msgCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }
    if (phone.isEmpty) {
      setState(() => _error = 'Please enter your mobile number.');
      return;
    }
    if (message.isEmpty) {
      setState(() => _error = 'Please describe your issue.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final res = await ApiClient().post('/contact', data: {
        'name':    name,
        'phone':   phone,
        if (_subjectCtrl.text.trim().isNotEmpty)
          'subject': _subjectCtrl.text.trim(),
        'message': message,
      });
      final refId = res.data['data']?['reference_id'] as String?;
      if (mounted) {
        setState(() {
          _submitted = true;
          _refId     = refId;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
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
        body: Column(
          children: [
            // ── Red header ─────────────────────────────────────────────
            _Header(onBack: () => Navigator.pop(context)),

            // ── White card ─────────────────────────────────────────────
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
                      child: _submitted ? _SuccessView(refId: _refId) : _Form(
                        nameCtrl:    _nameCtrl,
                        phoneCtrl:   _phoneCtrl,
                        subjectCtrl: _subjectCtrl,
                        msgCtrl:     _msgCtrl,
                        isLoading:   _isLoading,
                        error:       _error,
                        onSubmit:    _submit,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  double.infinity,
      color:  AppColors.primary,
      padding: EdgeInsets.only(
        top:    MediaQuery.of(context).padding.top + 16,
        left:   20,
        right:  20,
        bottom: 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: Container(
              width:  36,
              height: 36,
              decoration: BoxDecoration(
                color:        Colors.white.withOpacity(0.15),
                shape:        BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size:  16,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(10),
                topRight:    Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: const Text(
              '👋 We\'re here to help',
              style: TextStyle(
                color:      AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize:   14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Contact\nSupport',
            style: TextStyle(
              color:         Colors.white,
              fontSize:      34,
              fontWeight:    FontWeight.w900,
              height:        1.15,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Form ──────────────────────────────────────────────────────────────────────

class _Form extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController subjectCtrl;
  final TextEditingController msgCtrl;
  final bool         isLoading;
  final String?      error;
  final VoidCallback onSubmit;

  const _Form({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.subjectCtrl,
    required this.msgCtrl,
    required this.isLoading,
    required this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Get in Touch',
            style: TextStyle(
              fontSize:      22,
              fontWeight:    FontWeight.w800,
              color:         AppColors.textDark,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'Fill the form below and our team will\ncontact you within 24 hours.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color:    AppColors.textGrey,
              height:   1.5,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Info banner for deactivated accounts
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Colors.orange.shade600, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'If your account was deactivated or scheduled for deletion, '
                      'mention it in your message and we\'ll restore access for you.',
                  style: TextStyle(
                    fontSize: 12,
                    color:    Color(0xFF7B5600),
                    height:   1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _Label(text: 'Full Name'),
        const SizedBox(height: 8),
        _Field(
          controller:         nameCtrl,
          hint:               'Enter your name',
          keyboardType:       TextInputType.name,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),

        _Label(text: 'Mobile No.'),
        const SizedBox(height: 8),
        _Field(
          controller:      phoneCtrl,
          hint:            'Enter mobile number',
          keyboardType:    TextInputType.phone,
          maxLength:       10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),

        _Label(text: 'Subject (optional)'),
        const SizedBox(height: 8),
        _Field(
          controller:         subjectCtrl,
          hint:               'e.g. Reactivate my account',
          keyboardType:       TextInputType.text,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),

        _Label(text: 'Message'),
        const SizedBox(height: 8),
        _Field(
          controller:         msgCtrl,
          hint:               'Describe your issue…',
          keyboardType:       TextInputType.multiline,
          maxLines:           5,
          textCapitalization: TextCapitalization.sentences,
        ),

        if (error != null) ...[
          const SizedBox(height: 14),
          Container(
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
                    error!,
                    style: const TextStyle(
                      color:      AppColors.primary,
                      fontSize:   13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 28),

        SizedBox(
          width:  double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor:         AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation:   2,
              shadowColor: AppColors.primary.withOpacity(0.35),
            ),
            child: isLoading
                ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
                : const Text(
              'Send Message',
              style: TextStyle(
                color:         Colors.white,
                fontWeight:    FontWeight.w800,
                fontSize:      16,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ── Success view ──────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final String? refId;
  const _SuccessView({this.refId});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width:  80,
          height: 80,
          decoration: BoxDecoration(
            color:  Colors.green.shade50,
            shape:  BoxShape.circle,
          ),
          child: Icon(Icons.check_circle_rounded,
              color: Colors.green.shade500, size: 44),
        ),
        const SizedBox(height: 24),
        const Text(
          'Message Sent!',
          style: TextStyle(
            fontSize:   24,
            fontWeight: FontWeight.w900,
            color:      AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Thanks for reaching out.\nOur support team will contact you within 24 hours.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color:    AppColors.textGrey,
            height:   1.6,
          ),
        ),
        if (refId != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color:        AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(
                  color: AppColors.primary.withOpacity(0.25)),
            ),
            child: Column(
              children: [
                const Text(
                  'Reference ID',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textGrey),
                ),
                const SizedBox(height: 4),
                Text(
                  refId!,
                  style: const TextStyle(
                    fontSize:      16,
                    fontWeight:    FontWeight.w800,
                    letterSpacing: 1.5,
                    color:         AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 40),
        SizedBox(
          width:  double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                color:      Colors.white,
                fontWeight: FontWeight.w800,
                fontSize:   16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize:   13,
      fontWeight: FontWeight.w600,
      color:      AppColors.primary,
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController     controller;
  final String                    hint;
  final TextInputType             keyboardType;
  final int?                      maxLength;
  final int                       maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization        textCapitalization;

  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType       = TextInputType.text,
    this.maxLength,
    this.maxLines           = 1,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller:         controller,
        keyboardType:       maxLines > 1
            ? TextInputType.multiline
            : keyboardType,
        maxLines:           maxLines,
        maxLength:          maxLength,
        inputFormatters:    inputFormatters,
        textCapitalization: textCapitalization,
        style: const TextStyle(
          fontSize:   15,
          color:      AppColors.textDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText:       hint,
          hintStyle:      const TextStyle(
              color: AppColors.textLight, fontSize: 14),
          border:         InputBorder.none,
          counterText:    '',
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}