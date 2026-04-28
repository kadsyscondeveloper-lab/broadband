// lib/views/kyc/video_kyc_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../theme/app_theme.dart';
import '../../services/video_kyc_service.dart';

class VideoKycScreen extends StatefulWidget {
  final String docKycStatus;
  final bool   embedded;

  const VideoKycScreen({
    super.key,
    required this.docKycStatus,
    this.embedded = false,
  });

  @override
  State<VideoKycScreen> createState() => _VideoKycScreenState();
}

class _VideoKycScreenState extends State<VideoKycScreen> {
  final _service = VideoKycService();
  final _picker  = ImagePicker();

  VideoKycRequest? _existing;

  bool    _isLoading    = true;
  bool    _isSubmitting = false;
  bool    _isCancelling = false;
  String? _error;

  File?                    _videoFile;
  VideoPlayerController?   _playerCtrl;
  bool                     _playerReady = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _playerCtrl?.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    _existing = await _service.getStatus();
    setState(() => _isLoading = false);
  }

  // ── Video recording / picking ─────────────────────────────────────────────

  Future<void> _recordVideo() async {
    final picked = await _picker.pickVideo(
      source:                ImageSource.camera,
      maxDuration:           const Duration(seconds: 30),
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null) return;
    await _setVideo(File(picked.path));
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickVideo(
      source:      ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (picked == null) return;
    await _setVideo(File(picked.path));
  }

  Future<void> _setVideo(File file) async {
    await _playerCtrl?.dispose();
    final ctrl = VideoPlayerController.file(file);
    await ctrl.initialize();
    ctrl.setLooping(false);
    setState(() {
      _videoFile   = file;
      _playerCtrl  = ctrl;
      _playerReady = true;
      _error       = null;
    });
  }

  void _clearVideo() {
    _playerCtrl?.dispose();
    setState(() {
      _videoFile   = null;
      _playerCtrl  = null;
      _playerReady = false;
    });
  }

  // ── Submission ────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_videoFile == null) return;

    final bytes = await _videoFile!.length();
    if (bytes > 50 * 1024 * 1024) {
      setState(() => _error = 'Video is too large. Please keep it under 50 MB.');
      return;
    }

    setState(() { _isSubmitting = true; _error = null; });

    final result = await _service.submitVideo(_videoFile!);

    if (!mounted) return;

    if (result.success) {
      _clearVideo();
      setState(() => _isSubmitting = false);
      await _load(); // re-fetch full record so pending UI shows correctly
    }
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Video KYC?'),
        content: const Text(
            'Your submission will be cancelled. You can record and submit again anytime.'),
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
      setState(() {
        _existing     = null;
        _isCancelling = false;
      });
      await _load();
    } else {
      setState(() { _error = result.error; _isCancelling = false; });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildBody();

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Video KYC',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body,
    );
  }

  Widget _buildBody() {
    final docStatus = widget.docKycStatus;

    // Gate: docs not submitted yet
    if (docStatus == 'not_submitted') {
      return _GateBanner(
        icon:        Icons.lock_outline_rounded,
        color:       Colors.orange,
        title:       'Complete Document KYC First',
        message:     'Upload your address proof and ID proof before recording a video.',
        buttonLabel: 'Go to Documents',
        onTap:       () { if (!widget.embedded) Navigator.pop(context); },
      );
    }

    // Under review (pending or under_review)
    if (_existing?.isInReview == true) {
      return _PendingView(
        request:      _existing!,
        isCancelling: _isCancelling,
        error:        _error,
        onCancel:     _cancel,
        onRefresh:    _load,
      );
    }

    // Fully verified
    if (_existing?.isCompleted == true) {
      return _CompletedView(request: _existing!);
    }

    // Rejected or failed — show reason and let user re-record
    if (_existing?.isRejected == true || _existing?.isFailed == true) {
      return _FailedView(
        request: _existing!,
        onRetry: () => setState(() => _existing = null),
      );
    }

    // Not yet submitted (or cancelled) → show recording UI
    return _RecordingView(
      videoFile:    _videoFile,
      playerCtrl:   _playerCtrl,
      playerReady:  _playerReady,
      isSubmitting: _isSubmitting,
      error:        _error,
      onRecord:     _recordVideo,
      onGallery:    _pickFromGallery,
      onClear:      _clearVideo,
      onSubmit:     _submit,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECORDING VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _RecordingView extends StatelessWidget {
  final File?                  videoFile;
  final VideoPlayerController? playerCtrl;
  final bool                   playerReady;
  final bool                   isSubmitting;
  final String?                error;
  final VoidCallback           onRecord;
  final VoidCallback           onGallery;
  final VoidCallback           onClear;
  final VoidCallback           onSubmit;

  const _RecordingView({
    required this.videoFile,
    required this.playerCtrl,
    required this.playerReady,
    required this.isSubmitting,
    required this.error,
    required this.onRecord,
    required this.onGallery,
    required this.onClear,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // How it works
          const _HowItWorksCard(),
          const SizedBox(height: 20),

          // Video preview or pick buttons
          videoFile == null
              ? _PickButtons(onRecord: onRecord, onGallery: onGallery)
              : _VideoPreview(
            videoFile:   videoFile!,
            playerCtrl:  playerCtrl,
            playerReady: playerReady,
            onClear:     onClear,
          ),
          const SizedBox(height: 16),

          // Tips
          const _TipsCard(),
          const SizedBox(height: 16),

          // Error
          if (error != null) ...[
            _ErrorBanner(message: error!),
            const SizedBox(height: 16),
          ],

          // Submit
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (videoFile != null && !isSubmitting) ? onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:         AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
                  : Text(
                videoFile == null
                    ? 'Record a Video to Continue'
                    : 'Submit for Verification',
                style: const TextStyle(
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
// PICK BUTTONS
// ─────────────────────────────────────────────────────────────────────────────

class _PickButtons extends StatelessWidget {
  final VoidCallback onRecord;
  final VoidCallback onGallery;

  const _PickButtons({required this.onRecord, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        flex: 3,
        child: _BigButton(
          icon:  Icons.videocam_rounded,
          label: 'Record Video',
          sub:   'Uses front camera',
          color: AppColors.primary,
          onTap: onRecord,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: _BigButton(
          icon:  Icons.photo_library_rounded,
          label: 'From Gallery',
          sub:   'Pick existing',
          color: Colors.grey.shade600,
          onTap: onGallery,
        ),
      ),
    ]);
  }
}

class _BigButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final String       sub;
  final Color        color;
  final VoidCallback onTap;

  const _BigButton({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13, color: color)),
          const SizedBox(height: 2),
          Text(sub,
              style: TextStyle(fontSize: 11, color: color.withOpacity(0.65))),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIDEO PREVIEW
// ─────────────────────────────────────────────────────────────────────────────

class _VideoPreview extends StatefulWidget {
  final File                   videoFile;
  final VideoPlayerController? playerCtrl;
  final bool                   playerReady;
  final VoidCallback           onClear;

  const _VideoPreview({
    required this.videoFile,
    required this.playerCtrl,
    required this.playerReady,
    required this.onClear,
  });

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  bool _playing = false;

  void _toggle() {
    final ctrl = widget.playerCtrl;
    if (ctrl == null || !widget.playerReady) return;
    if (_playing) {
      ctrl.pause();
    } else {
      ctrl.play();
    }
    setState(() => _playing = !_playing);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl   = widget.playerCtrl;
    final ready  = widget.playerReady;
    final dur    = ctrl?.value.duration ?? Duration.zero;
    final durStr = '${dur.inSeconds}s';

    return Column(children: [
      Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ready && ctrl != null
                ? AspectRatio(
                aspectRatio: ctrl.value.aspectRatio,
                child: VideoPlayer(ctrl))
                : Container(
              height: 220,
              color:  Colors.black87,
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
          ),
          GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white, size: 36,
              ),
            ),
          ),
          Positioned(
            bottom: 10, right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:        Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(durStr,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.videoFile.path.split('/').last,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13,
                color: AppColors.textDark),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _Chip(label: 'Re-record', color: AppColors.primary, onTap: widget.onClear),
      ]),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PENDING VIEW
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
    final isUnderReview = request.isUnderReview;
    final color = isUnderReview ? Colors.blue : Colors.orange;
    final title = isUnderReview
        ? 'Under Review'
        : 'Verifying Your Video…';
    final subtitle = isUnderReview
        ? 'Our team is reviewing your submission. We\'ll notify you once complete.'
        : 'Your video has been received and is queued for review. This usually takes a few minutes.';

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
                  isUnderReview
                      ? Icons.manage_search_rounded
                      : Icons.hourglass_top_rounded,
                  color: color, size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: color)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: color, height: 1.4)),
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
              _DetailRow(
                  label: 'Reference ID',
                  value: request.referenceId,
                  mono: true),
              const Divider(height: 20),
              _DetailRow(
                  label: 'Submitted',
                  value: _fmtDate(request.createdAt)),
            ]),
          ),
          const SizedBox(height: 12),

          // Tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(
                  color: const Color(0xFFF5C842).withOpacity(0.4)),
            ),
            child: const Row(children: [
              Text('💡', style: TextStyle(fontSize: 18)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You will receive a notification once verification is complete.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B6914),
                      height: 1.5),
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
                    ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cancel_outlined, size: 18),
                label: Text(isCancelling ? 'Cancelling…' : 'Cancel & Re-record'),
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
                  side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
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

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPLETED VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _CompletedView extends StatelessWidget {
  final VideoKycRequest request;
  const _CompletedView({required this.request});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.verified_rounded,
                color: Colors.green, size: 56),
          ),
          const SizedBox(height: 24),
          const Text('Video KYC Complete! 🎉',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark)),
          const SizedBox(height: 12),
          Text(
            'Your video was verified successfully. '
                'Your KYC is now fully complete.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: Colors.grey.shade600, height: 1.6),
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
              child: Text('📝 Note: ${request.agentNotes}',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade700,
                      height: 1.4)),
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
              child: const Text('Done',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAILED / REJECTED VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _FailedView extends StatelessWidget {
  final VideoKycRequest request;
  final VoidCallback    onRetry;
  const _FailedView({required this.request, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
                color: Colors.red.shade50, shape: BoxShape.circle),
            child: Icon(Icons.videocam_off_rounded,
                color: Colors.red.shade500, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            request.isRejected ? 'Verification Rejected' : 'Verification Failed',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.red.shade700),
          ),
          const SizedBox(height: 12),
          if (request.rejectionReason != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'Reason: ${request.rejectionReason}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade700,
                    height: 1.5),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Please record a new video and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.videocam_rounded),
              label: const Text('Record Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOW IT WORKS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1', 'Record a short video', 'Use your front camera — 5 to 30 seconds is enough'),
      ('2', 'Submit', 'Upload the video directly from your device'),
      ('3', 'Review', 'Our team reviews your video within a short time'),
      ('4', 'Done!', 'Verification completes and you get full account access'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Text('How Video KYC works',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.textDark)),
        ]),
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
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.$2,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textDark)),
                  Text(s.$3,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textGrey,
                          height: 1.4)),
                ],
              ),
            ),
          ]),
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIPS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    const tips = [
      'Use good lighting — your face must be clearly visible',
      'Hold your phone steady and look directly at the camera',
      'Keep background noise minimal',
      'Video must be between 5 and 30 seconds',
      'Maximum file size is 50 MB',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(
            color: const Color(0xFFF5C842).withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.lightbulb_outline_rounded,
              color: Color(0xFF8B6914), size: 18),
          SizedBox(width: 8),
          Text('Tips for a successful verification',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF8B6914))),
        ]),
        const SizedBox(height: 10),
        ...tips.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('• ',
                style: TextStyle(
                    color: Color(0xFF8B6914),
                    fontWeight: FontWeight.w700)),
            Expanded(
              child: Text(t,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B6914),
                      height: 1.4)),
            ),
          ]),
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GATE BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _GateBanner extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       title;
  final String       message;
  final String       buttonLabel;
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
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
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool   mono;
  const _DetailRow(
      {required this.label, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label,
        style:
        const TextStyle(fontSize: 13, color: AppColors.textGrey)),
    const Spacer(),
    Flexible(
      child: Text(value,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              fontFamily: mono ? 'monospace' : null),
          textAlign: TextAlign.end),
    ),
  ]);
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color:        Colors.red.shade50,
      borderRadius: BorderRadius.circular(10),
      border:       Border.all(color: Colors.red.shade200),
    ),
    child: Row(children: [
      Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Text(message,
            style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ),
    ]),
  );
}