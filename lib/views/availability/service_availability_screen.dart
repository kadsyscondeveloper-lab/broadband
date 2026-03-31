// lib/views/availability/service_availability_screen.dart
//
// Usage (standalone — no longer returns a bool gate):
//   Navigator.push(
//     context,
//     MaterialPageRoute(builder: (_) => const ServiceAvailabilityScreen()),
//   );

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/availability_viewmodel.dart';

class ServiceAvailabilityScreen extends StatefulWidget {
  const ServiceAvailabilityScreen({super.key});

  @override
  State<ServiceAvailabilityScreen> createState() =>
      _ServiceAvailabilityScreenState();
}

class _ServiceAvailabilityScreenState
    extends State<ServiceAvailabilityScreen> {
  final _vm          = AvailabilityViewModel();
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _pinCtrl     = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl   = TextEditingController();

  @override
  void dispose() {
    _vm.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Check Availability',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.isSuccess) {
            return _SuccessView(
              referenceId: _vm.referenceId,
              onDone:      () => Navigator.pop(context),
            );
          }
          return _InquiryFormView(
            vm:          _vm,
            nameCtrl:    _nameCtrl,
            phoneCtrl:   _phoneCtrl,
            pinCtrl:     _pinCtrl,
            addressCtrl: _addressCtrl,
            emailCtrl:   _emailCtrl,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INQUIRY FORM VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _InquiryFormView extends StatelessWidget {
  final AvailabilityViewModel  vm;
  final TextEditingController  nameCtrl;
  final TextEditingController  phoneCtrl;
  final TextEditingController  pinCtrl;
  final TextEditingController  addressCtrl;
  final TextEditingController  emailCtrl;

  const _InquiryFormView({
    required this.vm,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.pinCtrl,
    required this.addressCtrl,
    required this.emailCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Hero ────────────────────────────────────────────────────────
          Center(
            child: Container(
              width:  100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_find_rounded,
                color: AppColors.primary,
                size:  50,
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Center(
            child: Text(
              'Check Service Availability',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize:   22,
                fontWeight: FontWeight.w800,
                color:      AppColors.textDark,
                height:     1.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Submit your details and our team will\nconfirm availability in your area within 24 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:    AppColors.textGrey,
                height:   1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Form card ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(16),
              border:       Border.all(color: AppColors.borderColor),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset:     const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Header
                Row(children: [
                  Container(
                    width:  36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:        AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.campaign_rounded,
                      color: AppColors.primary,
                      size:  20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Register Your Interest',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize:   15,
                          color:      AppColors.textDark,
                        ),
                      ),
                      Text(
                        "We'll confirm and contact you shortly",
                        style: TextStyle(
                          fontSize: 12,
                          color:    AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 24),

                // PIN Code
                _FormField(
                  label:      'PIN Code *',
                  controller: pinCtrl,
                  hint:       '6-digit PIN code',
                  onChanged:  vm.setPinCode,
                  inputType:  TextInputType.number,
                  maxLength:  6,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  prefixIcon: Icons.location_pin,
                ),
                const SizedBox(height: 14),

                // Full Name
                _FormField(
                  label:      'Full Name *',
                  controller: nameCtrl,
                  hint:       'Your full name',
                  onChanged:  vm.setName,
                  inputType:  TextInputType.name,
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),

                // Phone
                _FormField(
                  label:      'Mobile Number *',
                  controller: phoneCtrl,
                  hint:       '10-digit mobile number',
                  onChanged:  vm.setPhone,
                  inputType:  TextInputType.phone,
                  maxLength:  10,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 14, right: 8),
                    child: Text(
                      '+91',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color:      AppColors.textDark,
                        fontSize:   14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Address (optional)
                _FormField(
                  label:      'Address (Optional)',
                  controller: addressCtrl,
                  hint:       'Your locality or street',
                  onChanged:  vm.setAddress,
                  inputType:  TextInputType.streetAddress,
                  maxLines:   2,
                  prefixIcon: Icons.home_outlined,
                ),
                const SizedBox(height: 14),

                // Email (optional)
                _FormField(
                  label:      'Email (Optional)',
                  controller: emailCtrl,
                  hint:       'your@email.com',
                  onChanged:  vm.setEmail,
                  inputType:  TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                ),

                // Error
                if (vm.error != null) ...[
                  const SizedBox(height: 16),
                  _ErrorStrip(message: vm.error!),
                ],

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (vm.isSubmitting || !vm.canSubmit)
                        ? null
                        : vm.submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:         AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: vm.isSubmitting
                        ? const SizedBox(
                      width:  22,
                      height: 22,
                      child:  CircularProgressIndicator(
                        color:       Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      'Submit Inquiry',
                      style: TextStyle(
                        color:      Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize:   16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Info note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.blue.shade600, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Our support team will review your request and '
                        'call or message you within 24 hours to confirm '
                        'whether Speedonet service is available in your area.',
                    style: TextStyle(
                      fontSize: 13,
                      color:    Colors.blue.shade700,
                      height:   1.5,
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

// ─────────────────────────────────────────────────────────────────────────────
// SUCCESS VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final String?      referenceId;
  final VoidCallback onDone;

  const _SuccessView({this.referenceId, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Container(
            width:  120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_rounded,
              color: Colors.orange.shade700,
              size:  60,
            ),
          ),
          const SizedBox(height: 32),

          const Text(
            "Inquiry Submitted! 🎉",
            style: TextStyle(
              fontSize:   24,
              fontWeight: FontWeight.w800,
              color:      AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            "Our support team will review your request and "
                "contact you within 24 hours to confirm service "
                "availability in your area.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color:    AppColors.textGrey,
              height:   1.6,
            ),
          ),

          if (referenceId != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical:   14,
              ),
              decoration: BoxDecoration(
                color:        AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: AppColors.borderColor),
              ),
              child: Column(children: [
                const Text(
                  'Reference ID',
                  style: TextStyle(
                    fontSize: 12,
                    color:    AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  referenceId!,
                  style: const TextStyle(
                    fontSize:      18,
                    fontWeight:    FontWeight.w800,
                    color:         AppColors.textDark,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Save this for your records',
                  style: TextStyle(
                    fontSize: 11,
                    color:    AppColors.textLight,
                  ),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 32),

          // What happens next
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: Colors.green.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What happens next?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize:   13,
                    color:      Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 10),
                _NextStep(
                  icon:  Icons.support_agent_rounded,
                  color: Colors.green.shade700,
                  text:  'Our team reviews your area',
                ),
                const SizedBox(height: 8),
                _NextStep(
                  icon:  Icons.phone_in_talk_rounded,
                  color: Colors.green.shade700,
                  text:  'We contact you within 24 hours',
                ),
                const SizedBox(height: 8),
                _NextStep(
                  icon:  Icons.notifications_active_rounded,
                  color: Colors.green.shade700,
                  text:  "You'll get a notification in the app",
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(
                  color:      Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize:   16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   text;

  const _NextStep({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color:    color,
          height:   1.4,
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final String                    label;
  final TextEditingController     controller;
  final String                    hint;
  final ValueChanged<String>      onChanged;
  final TextInputType             inputType;
  final int                       maxLines;
  final int?                      maxLength;
  final List<TextInputFormatter>? formatters;
  final Widget?                   prefix;
  final IconData?                 prefixIcon;

  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.inputType  = TextInputType.text,
    this.maxLines   = 1,
    this.maxLength,
    this.formatters,
    this.prefix,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize:   13,
            fontWeight: FontWeight.w600,
            color:      AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: AppColors.borderColor),
          ),
          child: Row(children: [
            if (prefix != null)
              prefix!
            else if (prefixIcon != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(prefixIcon,
                    color: AppColors.textLight, size: 18),
              ),
            Expanded(
              child: TextField(
                controller:      controller,
                keyboardType:    inputType,
                maxLines:        maxLines,
                maxLength:       maxLength,
                inputFormatters: formatters,
                style: const TextStyle(
                  fontSize: 14,
                  color:    AppColors.textDark,
                ),
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color:    AppColors.textLight,
                    fontSize: 14,
                  ),
                  border:         InputBorder.none,
                  counterText:    '',
                  contentPadding: (prefix != null)
                      ? const EdgeInsets.symmetric(vertical: 14)
                      : const EdgeInsets.only(
                      top: 14, bottom: 14, right: 14),
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _ErrorStrip extends StatelessWidget {
  final String message;
  const _ErrorStrip({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: Colors.red.shade200),
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded,
            color: Colors.red.shade600, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color:    Colors.red.shade700,
              fontSize: 13,
            ),
          ),
        ),
      ]),
    );
  }
}