// lib/views/kyc/video_kyc_screen.dart
//
// Video KYC screen — shown as the second step inside kyc_screen.dart
// (or navigated to standalone). Lets the user schedule a video call
// slot; the agent calls them at the selected time.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/video_kyc_service.dart';
import 'video_call_screen.dart';

class VideoKycScreen extends StatefulWidget {
  final String docKycStatus;
  final bool embedded;

  const VideoKycScreen({
    super.key,
    required this.docKycStatus,
    this.embedded = false,
  });

  @override
  State<VideoKycScreen> createState() => _VideoKycScreenState();
}

class _VideoKycScreenState extends State<VideoKycScreen> {
  final _service    = VideoKycService();
  final _phoneCtrl  = TextEditingController();

  VideoKycRequest? _existing;
  bool             _isLoading  = true;
  bool             _isSubmitting = false;
  bool             _isCancelling = false;
  String?          _error;

  // Form state
  DateTime?      _selectedDate;
  VideoKycSlot   _selectedSlot = VideoKycSlot.morning;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    _existing = await _service.getStatus();
    setState(() => _isLoading = false);
  }

  Future<void> _submit() async {
    final phone = _phoneCtrl.text.trim();
    if (_selectedDate == null) {
      setState(() => _error = 'Please select a preferred date.');
      return;
    }
    if (phone.isEmpty || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      setState(() => _error = 'Enter a valid 10-digit mobile number.');
      return;
    }

    setState(() { _isSubmitting = true; _error = null; });
    final result = await _service.schedule(
      preferredDate: _selectedDate!,
      preferredSlot: _selectedSlot,
      callPhone:     phone,
    );
    if (!mounted) return;

    if (result.success) {
      setState(() { _existing = result.data; _isSubmitting = false; });
    } else {
      setState(() { _error = result.error; _isSubmitting = false; });
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Video KYC?'),
        content: const Text(
            'This will cancel your scheduled call. You can reschedule anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() { _isCancelling = true; _error = null; });
    final result = await _service.cancel();
    if (!mounted) return;

    if (result.success) {
      setState(() { _existing = null; _isCancelling = false; });
    } else {
      setState(() { _error = result.error; _isCancelling = false; });
    }
  }


  Future<void> _joinCall() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _service.getCallToken();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!result.success) {
      setState(() => _error = result.error);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          credentials: VideoCallCredentials(
            appId: result.appId!,
            channel: result.channel!,
            token: result.token!,
            uid: result.uid!,
            requestId: result.requestId!,
          ),
        ),
        fullscreenDialog: true,
      ),
    );

    _load();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildBody();

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Video KYC',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body,
    );
  }

  Widget _buildBody() {
    final docStatus = widget.docKycStatus;

    if (docStatus == 'not_submitted') {
      return _GateBanner(
        icon: Icons.lock_outline_rounded,
        color: Colors.orange,
        title: 'Complete Document KYC First',
        message:
        'Please upload your address proof and ID proof documents before scheduling a video KYC call.',
        buttonLabel: 'Go to Documents',
        onTap: () {
          if (!widget.embedded) {
            Navigator.pop(context);
          }
        },
      );
    }

    if (_existing?.isCompleted == true) {
      return _CompletedView(request: _existing!);
    }

    if (_existing?.isFailed == true) {
      return _FailedView(
        request: _existing!,
        onReschedule: () => setState(() => _existing = null),
      );
    }

    if (_existing?.isCallReady == true) {
      return _CallReadyView(
        request: _existing!,
        isJoining: _isLoading,
        error: _error,
        onJoin: _joinCall,
        onRefresh: _load,
      );
    }

    if (_existing?.isPending == true) {
      return _PendingView(
        request: _existing!,
        isCancelling: _isCancelling,
        error: _error,
        onCancel: _cancel,
        onRefresh: _load,
      );
    }

    return _ScheduleForm(
      docKycStatus: docStatus,
      phoneCtrl: _phoneCtrl,
      selectedDate: _selectedDate,
      selectedSlot: _selectedSlot,
      isSubmitting: _isSubmitting,
      error: _error,
      onDateChanged: (d) => setState(() {
        _selectedDate = d;
        _error = null;
      }),
      onSlotChanged: (s) => setState(() => _selectedSlot = s),
      onSubmit: _submit,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCHEDULE FORM
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleForm extends StatelessWidget {
  final String               docKycStatus;
  final TextEditingController phoneCtrl;
  final DateTime?            selectedDate;
  final VideoKycSlot         selectedSlot;
  final bool                 isSubmitting;
  final String?              error;
  final ValueChanged<DateTime?>    onDateChanged;
  final ValueChanged<VideoKycSlot> onSlotChanged;
  final VoidCallback         onSubmit;

  const _ScheduleForm({
    required this.docKycStatus,
    required this.phoneCtrl,
    required this.selectedDate,
    required this.selectedSlot,
    required this.isSubmitting,
    required this.error,
    required this.onDateChanged,
    required this.onSlotChanged,
    required this.onSubmit,
  });

  String get _docStatusBadge {
    switch (docKycStatus) {
      case 'pending':      return '⏳ Documents Under Review';
      case 'under_review': return '🔍 Documents Being Verified';
      case 'approved':     return '✅ Documents Approved';
      default:             return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Info card ──────────────────────────────────────────────────
          _InfoCard(docStatusBadge: _docStatusBadge),
          const SizedBox(height: 24),

          // ── How it works ───────────────────────────────────────────────
          const _HowItWorksCard(),
          const SizedBox(height: 28),

          // ── Date picker ────────────────────────────────────────────────
          const _Label(text: 'Preferred Date'),
          const SizedBox(height: 10),
          _DatePicker(
            selectedDate: selectedDate,
            onChanged:    onDateChanged,
          ),
          const SizedBox(height: 20),

          // ── Time slot picker ───────────────────────────────────────────
          const _Label(text: 'Preferred Time Slot'),
          const SizedBox(height: 10),
          _SlotPicker(
            selected:  selectedSlot,
            onChanged: onSlotChanged,
          ),
          const SizedBox(height: 20),

          // ── Phone ──────────────────────────────────────────────────────
          const _Label(text: 'Call Me On'),
          const SizedBox(height: 10),
          Container(
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
              controller:   phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength:    10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                  fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                hintText:       'Enter mobile number',
                hintStyle:      TextStyle(color: AppColors.textLight, fontSize: 14),
                border:         InputBorder.none,
                counterText:    '',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixIcon:     Icon(Icons.phone_outlined,
                    color: AppColors.primary, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Our agent will call this number at the selected time.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),

          // ── Error ──────────────────────────────────────────────────────
          if (error != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: error!),
          ],

          const SizedBox(height: 32),

          // ── Submit ─────────────────────────────────────────────────────
          SizedBox(
            width:  double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor:         AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: isSubmitting
                  ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
                  : const Text(
                'Schedule Video KYC Call',
                style: TextStyle(
                  color:      Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize:   16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATE PICKER
// ─────────────────────────────────────────────────────────────────────────────

class _DatePicker extends StatelessWidget {
  final DateTime?            selectedDate;
  final ValueChanged<DateTime?> onChanged;

  const _DatePicker({required this.selectedDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final today   = DateTime.now();
    final maxDate = today.add(const Duration(days: 30));

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context:     context,
          initialDate: selectedDate ?? today,
          firstDate:   today,
          lastDate:    maxDate,
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(
            color: selectedDate != null
                ? AppColors.primary.withOpacity(0.5)
                : AppColors.borderColor,
            width: selectedDate != null ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size:  20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedDate != null
                    ? '${selectedDate!.day} ${_monthName(selectedDate!.month)} ${selectedDate!.year}'
                    : 'Select a date',
                style: TextStyle(
                  fontSize:   15,
                  fontWeight: FontWeight.w500,
                  color: selectedDate != null
                      ? AppColors.textDark
                      : AppColors.textLight,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded,
                color: AppColors.textGrey, size: 24),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[m];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLOT PICKER
// ─────────────────────────────────────────────────────────────────────────────

class _SlotPicker extends StatelessWidget {
  final VideoKycSlot         selected;
  final ValueChanged<VideoKycSlot> onChanged;

  const _SlotPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: VideoKycSlot.values.map((slot) {
        final isSelected = slot == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(slot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(
                right: slot != VideoKycSlot.evening ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color:        isSelected
                    ? AppColors.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.borderColor,
                  width: isSelected ? 1.5 : 1.2,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color:      AppColors.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset:     const Offset(0, 3),
                  ),
                ]
                    : [
                  BoxShadow(
                    color:      Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset:     const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    slot.icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    slot.value[0].toUpperCase() + slot.value.substring(1),
                    style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                      color:      isSelected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    slot == VideoKycSlot.morning   ? '9 AM–12 PM'  :
                    slot == VideoKycSlot.afternoon ? '12 PM–4 PM'  : '4 PM–7 PM',
                    style: TextStyle(
                      fontSize: 10,
                      color:    isSelected
                          ? Colors.white.withOpacity(0.8)
                          : AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PENDING STATE
// ─────────────────────────────────────────────────────────────────────────────

class _PendingView extends StatelessWidget {
  final VideoKycRequest request;
  final bool            isCancelling;
  final String?         error;
  final VoidCallback    onCancel;
  final VoidCallback    onRefresh;

  const _PendingView({
    required this.request,
    required this.isCancelling,
    required this.error,
    required this.onCancel,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isConfirmed = request.isConfirmed;
    final color       = isConfirmed ? Colors.blue : Colors.orange;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color:        color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border:       Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(
                  isConfirmed
                      ? Icons.event_available_rounded
                      : Icons.hourglass_top_rounded,
                  color: color, size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConfirmed
                          ? 'Video Call Confirmed!'
                          : 'Call Scheduled — Pending Confirmation',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize:   15,
                        color:      color.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isConfirmed
                          ? 'Our agent has confirmed the call. Expect a call at the time below.'
                          : 'Our team will confirm your slot shortly.',
                      style: TextStyle(
                          fontSize: 12, color: color.shade600, height: 1.4),
                    ),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Details card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(14),
              border:       Border.all(color: AppColors.borderColor),
            ),
            child: Column(children: [
              _DetailRow(label: 'Reference ID', value: request.referenceId, mono: true),
              const Divider(height: 20),
              _DetailRow(label: 'Preferred Date', value: request.preferredDate),
              const Divider(height: 20),
              _DetailRow(
                label: 'Time Slot',
                value: request.preferredSlot.label,
              ),
              const Divider(height: 20),
              _DetailRow(label: 'Call Number', value: request.callPhone, mono: true),
              if (request.confirmedSlot != null) ...[
                const Divider(height: 20),
                _DetailRow(label: 'Confirmed Time', value: request.confirmedSlot!),
              ],
            ]),
          ),
          const SizedBox(height: 12),

          // Tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: const Color(0xFFF5C842).withOpacity(0.4)),
            ),
            child: Row(children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Keep your ID document handy for the video call. '
                      'Our agent will ask you to show it briefly on camera.',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF8B6914), height: 1.5),
                ),
              ),
            ]),
          ),

          if (error != null) ...[
            const SizedBox(height: 14),
            _ErrorBanner(message: error!),
          ],

          const SizedBox(height: 24),

          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isCancelling ? null : onCancel,
                icon: isCancelling
                    ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cancel_outlined, size: 18),
                label: Text(isCancelling ? 'Cancelling…' : 'Cancel Request'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side:  BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side:  BorderSide(color: AppColors.primary.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}



class _CallReadyView extends StatelessWidget {
  final VideoKycRequest request;
  final bool isJoining;
  final String? error;
  final VoidCallback onJoin;
  final VoidCallback onRefresh;

  const _CallReadyView({
    required this.request,
    required this.isJoining,
    required this.onJoin,
    required this.onRefresh,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const _PulsingCallIcon(),
          const SizedBox(height: 28),

          const Text(
            'Agent is Ready!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Your verification agent has joined.\nTap below to start your KYC video call.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 28),

          if (error != null) ...[
            _ErrorBanner(message: error!),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: isJoining ? null : onJoin,
              icon: isJoining
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : const Icon(Icons.videocam_rounded),
              label: Text(
                isJoining ? 'Connecting...' : 'Join Video Call',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh status'),
          ),
        ],
      ),
    );
  }
}

class _PulsingCallIcon extends StatefulWidget {
  const _PulsingCallIcon();

  @override
  State<_PulsingCallIcon> createState() => _PulsingCallIconState();
}

class _PulsingCallIconState extends State<_PulsingCallIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.35),
              blurRadius: 22,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(
          Icons.videocam_rounded,
          color: Colors.white,
          size: 52,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPLETED STATE
// ─────────────────────────────────────────────────────────────────────────────

class _CompletedView extends StatelessWidget {
  final VideoKycRequest request;
  const _CompletedView({required this.request});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.verified_rounded,
                  color: Colors.green, size: 56),
            ),
            const SizedBox(height: 24),
            const Text(
              'Video KYC Complete! 🎉',
              style: TextStyle(
                fontSize:   22,
                fontWeight: FontWeight.w900,
                color:      AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your video verification was successful. '
                  'Your KYC is now fully complete.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:    Colors.grey.shade600,
                height:   1.6,
              ),
            ),
            if (request.agentNotes != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:        Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  '📝 Agent note: ${request.agentNotes}',
                  style: TextStyle(
                      fontSize: 13, color: Colors.green.shade700, height: 1.4),
                ),
              ),
            ],
            const SizedBox(height: 32),
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
                child: const Text('Back to KYC',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAILED STATE
// ─────────────────────────────────────────────────────────────────────────────

class _FailedView extends StatelessWidget {
  final VideoKycRequest request;
  final VoidCallback    onReschedule;
  const _FailedView({required this.request, required this.onReschedule});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                  color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.video_call_rounded,
                  color: Colors.red.shade500, size: 48),
            ),
            const SizedBox(height: 24),
            Text('Video KYC Failed',
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: Colors.red.shade700,
                )),
            const SizedBox(height: 12),
            if (request.rejectionReason != null)
              Text(
                'Reason: ${request.rejectionReason}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14,
                    color: Colors.red.shade600, height: 1.5),
              ),
            const SizedBox(height: 8),
            Text(
              'Please schedule a new slot for another attempt.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onReschedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Reschedule',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GATE BANNER (when pre-requisites aren't met)
// ─────────────────────────────────────────────────────────────────────────────

class _GateBanner extends StatelessWidget {
  final IconData  icon;
  final Color     color;
  final String    title;
  final String    message;
  final String    buttonLabel;
  final VoidCallback onTap;

  const _GateBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 44),
            ),
            const SizedBox(height: 24),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textGrey, height: 1.6)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(buttonLabel,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO CARDS
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String docStatusBadge;
  const _InfoCard({required this.docStatusBadge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.videocam_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Video KYC Call',
                style: TextStyle(fontWeight: FontWeight.w800,
                    fontSize: 15, color: AppColors.textDark)),
          ),
          if (docStatusBadge.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:        Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border:       Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                docStatusBadge,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: Colors.green.shade700),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        const Text(
          'Schedule a short call with a Speedonet verification agent. '
              'The call takes about 2–3 minutes — just have your ID document ready.',
          style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.5),
        ),
      ]),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1', 'Schedule', 'Pick your preferred date and time slot below'),
      ('2', 'We call you', 'Our agent will call your number at the selected time'),
      ('3', 'Quick verify', 'Show your ID card on the call — 2-3 minutes'),
      ('4', 'Done!', 'KYC completes and you get full account access'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('How it works',
            style: TextStyle(fontWeight: FontWeight.w800,
                fontSize: 14, color: AppColors.textDark)),
        const SizedBox(height: 14),
        ...steps.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 24, height: 24,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: Center(
                child: Text(s.$1,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.$2, style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13,
                    color: AppColors.textDark)),
                Text(s.$3, style: const TextStyle(
                    fontSize: 11, color: AppColors.textGrey, height: 1.4)),
              ],
            )),
          ]),
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.primary));
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool   mono;
  const _DetailRow({required this.label, required this.value, this.mono = false});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
    const Spacer(),
    Text(value, style: TextStyle(
      fontSize:      13,
      fontWeight:    FontWeight.w700,
      color:         AppColors.textDark,
      fontFamily:    mono ? 'monospace' : null,
      letterSpacing: mono ? 0.5 : 0,
    )),
  ]);
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color:        AppColors.primary.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
      border:       Border.all(color: AppColors.primary.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.primary, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: const TextStyle(
          color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );
}