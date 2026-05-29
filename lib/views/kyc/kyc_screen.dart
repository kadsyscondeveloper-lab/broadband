// lib/views/kyc/kyc_screen.dart
//
// Changes vs original:
//  1. Video KYC tab — date picker and time slot removed.
//     Tab now shows: video upload tile (required) + contact number (required).
//  2. canSubmitVideo gating updated to match new viewmodel logic.
//  3. _VideoScheduledCard still shows date/slot if the server returned them
//     (backwards compatible with old scheduled requests).
//  4. Success message updated to reflect upload-only flow.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/kyc_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../services/kyc_service.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen>
    with SingleTickerProviderStateMixin {

  final _vm = KycViewModel();
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _vm.addListener(_onVmChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _vm.init());
  }

  void _onVmChange() {
    if (!mounted) return;
    if (_vm.videoError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_vm.videoError!),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      _vm.clearVideoError();
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChange);
    _vm.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('KYC Verification',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Document KYC'),
            Tab(text: 'Video KYC'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _vm,
        builder: (_, __) {
          if (_vm.step == KycStep.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_vm.step == KycStep.error && _vm.isProfileIncomplete) {
            return _ProfileIncompleteCard(
              message: _vm.errorMessage ?? '',
              onGoToProfile: () => Navigator.pop(context),
            );
          }
          return TabBarView(
            controller: _tabCtrl,
            children: [
              _DocKycTab(vm: _vm),
              _VideoKycTab(vm: _vm),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Document KYC (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _DocKycTab extends StatelessWidget {
  final KycViewModel vm;
  const _DocKycTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.kycStatus?.isApproved ?? false) {
      return _StatusBanner(
        icon: Icons.verified_rounded,
        color: Colors.green,
        title: 'KYC Approved',
        message: 'Your identity has been verified successfully.',
      );
    }

    final isPending = vm.kycStatus?.isPending ?? false;

    if (vm.step == KycStep.submitting) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(vm.progressText ?? 'Uploading…',
              style: const TextStyle(fontSize: 15, color: AppColors.textGrey)),
        ]),
      );
    }

    if (vm.step == KycStep.success) {
      return _StatusBanner(
        icon: Icons.check_circle_outline,
        color: Colors.green,
        title: 'Documents Submitted',
        message:
        'Your KYC documents have been uploaded and are under review. We\'ll notify you once verified.',
      );
    }

    // When pending, show a read-only status card.
    // Do NOT show empty upload tiles — it makes users think docs weren't submitted.
    if (isPending) {
      return _PendingDocKycCard(vm: vm);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (vm.step == KycStep.error && !vm.isProfileIncomplete) ...[
          _InfoBanner(
            icon: Icons.error_outline,
            bgColor: const Color(0xFFFFF2F2),
            borderColor: Colors.red.shade200,
            iconBg: Colors.red.shade50,
            iconColor: Colors.red.shade700,
            title: 'Submission Failed',
            message: vm.errorMessage ?? 'Something went wrong. Please try again.',
          ),
          const SizedBox(height: 16),
        ],

        _SectionLabel(text: 'Address Proof'),
        const SizedBox(height: 8),
        _DocDropdown(
          value: vm.addressProofType,
          items: vm.addressProofTypes,
          onChanged: vm.setAddressProofType,
        ),
        const SizedBox(height: 12),
        _UploadTile(
          file: vm.addressFile,
          label: 'Upload Address Proof',
          onPick: () => vm.pickAddressFile(context),
          onRemove: vm.removeAddressFile,
        ),
        const SizedBox(height: 24),

        _SectionLabel(text: 'ID Proof'),
        const SizedBox(height: 8),
        _DocDropdown(
          value: vm.idProofType,
          items: vm.idProofTypes,
          onChanged: vm.setIdProofType,
        ),
        const SizedBox(height: 12),
        _UploadTile(
          file: vm.idFile,
          label: 'Upload ID Proof',
          onPick: () => vm.pickIdFile(context),
          onRemove: vm.removeIdFile,
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: vm.canSubmit ? vm.submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Submit Documents',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Video KYC (upload-only, no date/slot fields)
// ─────────────────────────────────────────────────────────────────────────────

class _VideoKycTab extends StatefulWidget {
  final KycViewModel vm;
  const _VideoKycTab({required this.vm});

  @override
  State<_VideoKycTab> createState() => _VideoKycTabState();
}

class _VideoKycTabState extends State<_VideoKycTab> {
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.vm.callPhone);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm      = widget.vm;
    final vStatus = vm.videoKycStatus;

    // Pending / scheduled — show status card
    if (vStatus != null && vStatus.isPending) {
      return _VideoScheduledCard(
        vm: vm,
        status: vStatus,
        onCancel: vm.cancelVideoKyc,
      );
    }

    // Completed
    if (vStatus?.isCompleted ?? false) {
      return _StatusBanner(
        icon: Icons.video_call_rounded,
        color: Colors.green,
        title: 'Video KYC Completed',
        message: 'Your video verification has been completed successfully.',
      );
    }

    // Success after upload
    if (vm.videoSuccess) {
      return _StatusBanner(
        icon: Icons.check_circle_outline,
        color: Colors.green,
        title: 'Video Submitted',
        message:
        'Your video KYC has been received and is under review. We\'ll notify you once verified.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info banner
        _InfoBanner(
          icon: Icons.videocam_outlined,
          bgColor: const Color(0xFFF0F4FF),
          borderColor: const Color(0xFFBDD0FF),
          iconBg: const Color(0xFFDEE8FF),
          iconColor: AppColors.primary,
          title: 'Video Verification',
          message:
          'Upload a short video for identity verification. Our team will review it and contact you if needed.',
        ),
        const SizedBox(height: 24),

        // ── Video upload (required) ─────────────────────────────────────
        _SectionLabel(text: 'Video Proof *'),
        const SizedBox(height: 4),
        Text(
          'MP4, MOV or WebM • Max 100 MB',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        _VideoUploadTile(
          file: vm.videoFile,
          onPick: () => vm.pickVideoFile(context),
          onRemove: vm.removeVideoFile,
        ),
        const SizedBox(height: 24),

        // ── Contact number (required) ───────────────────────────────────
        _SectionLabel(text: 'Contact Number *'),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          onChanged: vm.setCallPhone,
          decoration: InputDecoration(
            hintText: 'Enter phone number',
            hintStyle:
            const TextStyle(fontSize: 15, color: AppColors.textGrey),
            prefixIcon: const Icon(Icons.phone_outlined,
                size: 18, color: AppColors.textGrey),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // ── Submit ──────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: vm.canSubmitVideo && !vm.videoSubmitting
                ? vm.submitVideoKyc
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: vm.videoSubmitting
                ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : const Text('Submit Video KYC',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

// ── Pending doc KYC status card ─────────────────────────────────────────────

class _PendingDocKycCard extends StatelessWidget {
  final KycViewModel vm;
  const _PendingDocKycCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final s = vm.kycStatus;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Status banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF5C842)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  color: Color(0xFF8B6914), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Documents Under Review',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF8B6914))),
                SizedBox(height: 4),
                Text(
                  'Your documents have been submitted successfully and are being reviewed by our team. '
                      'We will notify you once verified.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8B6914), height: 1.5),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // Submitted doc details
        const Text('Submitted Documents',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        const SizedBox(height: 12),
        _SubmittedDocRow(
          label: 'Address Proof',
          type: s?.addressProofType ?? '—',
          icon: Icons.home_outlined,
          fileUrl: s?.addressProofUrl,
        ),
        const SizedBox(height: 12),
        _SubmittedDocRow(
          label: 'ID Proof',
          type: s?.idProofType ?? '—',
          icon: Icons.badge_outlined,
          fileUrl: s?.idProofUrl,
        ),
        if (s?.submittedAt != null) ...[
          const SizedBox(height: 16),
          Text(
            'Submitted on ${_formatDate(s!.submittedAt!)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ],
      ]),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Submitted doc row: shows type name + preview thumbnail / PDF link ─────────
class _SubmittedDocRow extends StatelessWidget {
  final String   label;
  final String   type;
  final IconData icon;
  final String?  fileUrl;

  const _SubmittedDocRow({
    required this.label,
    required this.type,
    required this.icon,
    this.fileUrl,
  });

  bool get _isPdf => fileUrl != null &&
      (fileUrl!.toLowerCase().endsWith('.pdf'));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header row (label + type name + check) ──────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: Colors.green.shade600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(type,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
              ]),
            ),
            Icon(Icons.check_circle, size: 18, color: Colors.green.shade500),
          ]),
        ),

        // ── Document preview ─────────────────────────────────────────────
        if (fileUrl != null) ...[
          Divider(height: 1, color: Colors.green.shade100),
          if (_isPdf)
          // PDF: tappable link row
            InkWell(
              onTap: () => _openUrl(context, fileUrl!),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(children: [
                  Icon(Icons.picture_as_pdf,
                      size: 16, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  const Text('View PDF',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                  const Spacer(),
                  const Icon(Icons.open_in_new,
                      size: 14, color: AppColors.textGrey),
                ]),
              ),
            )
          else
          // Image: thumbnail with tap-to-enlarge
            GestureDetector(
              onTap: () => _showFullImage(context, fileUrl!),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(11)),
                child: Stack(children: [
                  Image.network(
                    fileUrl!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 160,
                        color: Colors.green.shade50,
                        child: const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2)),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      color: Colors.green.shade50,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined,
                                size: 18,
                                color: Colors.green.shade300),
                            const SizedBox(width: 8),
                            Text('Could not load image',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade400)),
                          ]),
                    ),
                  ),
                  // Tap-to-enlarge hint overlay
                  Positioned(
                    bottom: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in,
                                size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Tap to enlarge',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.white)),
                          ]),
                    ),
                  ),
                ]),
              ),
            ),
        ],
      ]),
    );
  }

  void _openUrl(BuildContext context, String url) async {
    // Opens the PDF URL — uses url_launcher if available, else shows a snackbar
    try {
      final uri = Uri.parse(url);
      // ignore: deprecated_member_use
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Open: $url'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(children: [
          InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close,
                    size: 18, color: Colors.white),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontSize: 13,
        color: AppColors.textGrey,
        fontWeight: FontWeight.w600),
  );
}

class _DocDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final void Function(String) onChanged;

  const _DocDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textGrey),
          items: items
              .map((t) => DropdownMenuItem(
            value: t,
            child: Text(t,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textDark)),
          ))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final File?        file;
  final String       label;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _UploadTile({
    required this.file,
    required this.label,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return GestureDetector(
        onTap: onPick,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                style: BorderStyle.solid),
          ),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.cloud_upload_outlined,
                  size: 32, color: AppColors.primary.withOpacity(0.6)),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary.withOpacity(0.7),
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      );
    }

    final ext  = file!.path.split('.').last.toUpperCase();
    final name = file!.path.split('/').last;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(ext,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text('Tap × to remove',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ]),
        ),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child:
            Icon(Icons.close, size: 16, color: Colors.red.shade400),
          ),
        ),
      ]),
    );
  }
}

class _VideoUploadTile extends StatelessWidget {
  final File?        file;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _VideoUploadTile({
    required this.file,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return GestureDetector(
        onTap: onPick,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                style: BorderStyle.solid),
          ),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.videocam_outlined,
                  size: 36, color: AppColors.primary.withOpacity(0.6)),
              const SizedBox(height: 8),
              Text('Tap to select video',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary.withOpacity(0.7),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('MP4, MOV or WebM',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ]),
          ),
        ),
      );
    }

    final name = file!.path.split('/').last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.videocam, size: 22, color: Colors.blue.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text('Ready to upload',
                style: TextStyle(fontSize: 11, color: Colors.green.shade600)),
          ]),
        ),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: Colors.red.shade50, shape: BoxShape.circle),
            child:
            Icon(Icons.close, size: 16, color: Colors.red.shade400),
          ),
        ),
      ]),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color bgColor, borderColor, iconBg, iconColor;
  final String title, message;

  const _InfoBanner({
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration:
          BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            Text(message,
                style: TextStyle(
                    fontSize: 12,
                    color: iconColor,
                    height: 1.5)),
          ]),
        ),
      ]),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title, message;

  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  height: 1.5)),
        ]),
      ),
    );
  }
}

class _ProfileIncompleteCard extends StatelessWidget {
  final String       message;
  final VoidCallback onGoToProfile;

  const _ProfileIncompleteCard({
    required this.message,
    required this.onGoToProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.person_outline, size: 64, color: Colors.amber.shade400),
          const SizedBox(height: 16),
          const Text('Profile Incomplete',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textGrey, height: 1.5)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onGoToProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Complete Profile',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
        ]),
      ),
    );
  }
}

// ── Video scheduled/pending status card ──────────────────────────────────────

class _VideoScheduledCard extends StatelessWidget {
  final KycViewModel vm;
  final VideoKycStatus status;
  final Future<void> Function() onCancel;

  const _VideoScheduledCard({
    required this.vm,
    required this.status,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _InfoBanner(
          icon: Icons.schedule_rounded,
          bgColor: const Color(0xFFF0F4FF),
          borderColor: const Color(0xFFBDD0FF),
          iconBg: const Color(0xFFDEE8FF),
          iconColor: AppColors.primary,
          title: 'Video KYC Under Review',
          message: 'Your video has been submitted and is being reviewed by our team.',
        ),
        const SizedBox(height: 20),
        _DetailRow(label: 'Reference', value: status.referenceId ?? '—'),
        _DetailRow(label: 'Phone',     value: status.callPhone ?? '—'),
        _DetailRow(label: 'Status',    value: status.status),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Cancel Video KYC?'),
                  content: const Text(
                      'Are you sure you want to cancel this request?'),
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
              if (confirm == true) await onCancel();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel Request',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
        ),
      ]),
    );
  }
}