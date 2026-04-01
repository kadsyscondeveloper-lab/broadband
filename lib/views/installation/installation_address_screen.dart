// lib/views/installation/installation_address_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/installation_viewmodel.dart';
import '../../services/installation_service.dart';
import 'installation_tracker_screen.dart';

class InstallationAddressScreen extends StatefulWidget {
  const InstallationAddressScreen({super.key});

  @override
  State<InstallationAddressScreen> createState() =>
      _InstallationAddressScreenState();
}

class _InstallationAddressScreenState
    extends State<InstallationAddressScreen> {
  final _vm = InstallationAddressViewModel();

  late final TextEditingController _houseCtrl;
  late final TextEditingController _addrCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _houseCtrl = TextEditingController();
    _addrCtrl  = TextEditingController();
    _cityCtrl  = TextEditingController();
    _stateCtrl = TextEditingController();
    _pinCtrl   = TextEditingController();
    _notesCtrl = TextEditingController();
    _vm.addListener(_syncControllers);
    _vm.init();
  }

  void _syncControllers() {
    if (_vm.step == InstallationAddressStep.form) {
      _houseCtrl.text = _vm.houseNo;
      _addrCtrl.text  = _vm.address;
      _cityCtrl.text  = _vm.city;
      _stateCtrl.text = _vm.state;
      _pinCtrl.text   = _vm.pinCode;
    }
    if (_vm.step == InstallationAddressStep.success &&
        _vm.createdRequest != null) {
      _vm.removeListener(_syncControllers);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => InstallationTrackerScreen(
                initialRequest: _vm.createdRequest),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_syncControllers);
    _vm.dispose();
    _houseCtrl.dispose();
    _addrCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pinCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context:      context,
      initialDate:  now.add(const Duration(days: 1)),
      firstDate:    now.add(const Duration(days: 1)),
      lastDate:     now.add(const Duration(days: 30)),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) _vm.setPreferredDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Installation Address',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
          switch (_vm.step) {
            case InstallationAddressStep.loading:
              return const Center(child: CircularProgressIndicator(
                  color: AppColors.primary));
            case InstallationAddressStep.alreadyInstalled:
              return _buildAlreadyInstalledView();
            default:
              return _buildForm();
          }
        },
      ),
    );
  }

  // ── Already installed ──────────────────────────────────────────────────────

  Widget _buildAlreadyInstalledView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.shade200, width: 2),
              ),
              child: Icon(Icons.check_circle_rounded,
                  color: Colors.green.shade600, size: 52),
            ),
            const SizedBox(height: 28),
            const Text(
              'Router Already Installed',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your Speedonet router has already been installed at your premises. '
                  'Installations are a one-time process.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  height: 1.6),
            ),
            const SizedBox(height: 32),

            // Primary: go back (plan is active, all good)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Great, Go Back',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary: raise support ticket
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Pop back to the shell and let the user navigate to Help
                  Navigator.pop(context);
                  // Optionally navigate to support — depends on your nav setup
                },
                icon: const Icon(Icons.support_agent_rounded,
                    color: AppColors.primary, size: 18),
                label: const Text('Contact Support',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Address form ───────────────────────────────────────────────────────────

  Widget _buildForm() {
    final submitting = _vm.isSubmitting;

    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.18)),
                ),
                child: Row(children: [
                  Icon(Icons.build_circle_rounded,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Almost there!',
                              style: TextStyle(fontWeight: FontWeight.w800,
                                  fontSize: 15, color: AppColors.textDark)),
                          SizedBox(height: 3),
                          Text(
                              'Confirm where we should install your connection. '
                                  "We've pre-filled your profile address.",
                              style: TextStyle(fontSize: 12,
                                  color: AppColors.textGrey, height: 1.4)),
                        ]),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              const _SectionLabel('Installation Address'),
              const SizedBox(height: 14),

              _FieldRow(
                label: 'House / Flat No.', controller: _houseCtrl,
                hint: 'e.g. A-204', onChanged: _vm.setHouseNo, required: true,
              ),
              const SizedBox(height: 12),
              _FieldRow(
                label: 'Street / Locality', controller: _addrCtrl,
                hint: 'Building name, street', onChanged: _vm.setAddress,
                required: true, maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _FieldRow(
                  label: 'City', controller: _cityCtrl,
                  hint: 'City', onChanged: _vm.setCity, required: true,
                )),
                const SizedBox(width: 12),
                Expanded(child: _FieldRow(
                  label: 'State', controller: _stateCtrl,
                  hint: 'State', onChanged: _vm.setState_, required: true,
                )),
              ]),
              const SizedBox(height: 12),
              _FieldRow(
                label: 'PIN Code', controller: _pinCtrl,
                hint: '6-digit PIN code', onChanged: _vm.setPinCode,
                required: true, inputType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
              ),
              const SizedBox(height: 24),

              // Preferred date
              const _SectionLabel('Preferred Installation Date'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_today_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _vm.preferredDate != null
                            ? _fmtDate(_vm.preferredDate!)
                            : 'Select a date (optional)',
                        style: TextStyle(
                          fontSize: 14,
                          color: _vm.preferredDate != null
                              ? AppColors.textDark
                              : AppColors.textLight,
                          fontWeight: _vm.preferredDate != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (_vm.preferredDate != null)
                      GestureDetector(
                        onTap: () => _vm.setPreferredDate(null),
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.textGrey, size: 18),
                      )
                    else
                      const Icon(Icons.keyboard_arrow_right_rounded,
                          color: AppColors.textGrey),
                  ]),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Our technician will contact you to confirm the slot',
                style: TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
              const SizedBox(height: 24),

              // Notes
              const _SectionLabel('Additional Notes (Optional)'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  onChanged: _vm.setNotes,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textDark),
                  decoration: const InputDecoration(
                    hintText: 'E.g. call before arriving, gate code, landmark...',
                    hintStyle: TextStyle(
                        color: AppColors.textLight, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),

              // Error banner
              if (_vm.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline_rounded,
                        color: Colors.red.shade600, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_vm.error!,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13))),
                  ]),
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // Bottom action bar
      Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12, offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _StepDot(active: true,  label: 'Plan'),
            _StepLine(),
            _StepDot(active: true,  label: 'Address'),
            _StepLine(),
            _StepDot(active: false, label: 'Installation'),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (submitting || !_vm.canSubmit) ? null : _vm.submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: submitting
                  ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
                  : const Text('Confirm Installation Address',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ]),
      ),
    ]);
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
  );
}

class _FieldRow extends StatelessWidget {
  final String                   label;
  final TextEditingController    controller;
  final String                   hint;
  final ValueChanged<String>     onChanged;
  final bool                     required;
  final int                      maxLines;
  final TextInputType            inputType;
  final List<TextInputFormatter>? formatters;
  final int?                     maxLength;

  const _FieldRow({
    required this.label,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.required    = false,
    this.maxLines    = 1,
    this.inputType   = TextInputType.text,
    this.formatters,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(
        text: TextSpan(
          text:  label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
          children: required
              ? [const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.primary))]
              : [],
        ),
      ),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: TextField(
          controller:         controller,
          maxLines:           maxLines,
          maxLength:          maxLength,
          keyboardType:       inputType,
          inputFormatters:    formatters,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          onChanged:          onChanged,
          decoration: InputDecoration(
            hintText:       hint,
            hintStyle:      const TextStyle(
                color: AppColors.textLight, fontSize: 14),
            border:         InputBorder.none,
            counterText:    '',
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ),
    ]);
  }
}

class _StepDot extends StatelessWidget {
  final bool   active;
  final String label;
  const _StepDot({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 16, height: 16,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: active
            ? const Icon(Icons.check_rounded, size: 10, color: Colors.white)
            : null,
      ),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.primary : AppColors.textLight)),
    ]);
  }
}

class _StepLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 40, height: 2,
    margin: const EdgeInsets.only(bottom: 16),
    color: AppColors.primary.withOpacity(0.3),
  );
}