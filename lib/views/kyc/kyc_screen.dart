// lib/views/kyc/kyc_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../viewmodels/kyc_viewmodel.dart';
import '../../theme/app_theme.dart';
import 'video_kyc_screen.dart';
import '../../services/kyc_service.dart';
import '../../services/video_kyc_service.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _vm       = KycViewModel();
  final _videoSvc = VideoKycService();

  VideoKycRequest? _videoStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    await _vm.init();
    final v = await _videoSvc.getStatus();
    if (mounted) setState(() => _videoStatus = v);
  }

  @override
  void dispose() {
    _vm.dispose();
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
          'KYC Verification',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final status = _vm.kycStatus;

          final docsApproved  = status != null && status.isApproved;
          final videoComplete = _videoStatus?.isCompleted == true;

          int currentStep = 0;
          if (docsApproved) {
            currentStep = videoComplete ? 2 : 1;
          }

          // Full-screen states that bypass the stepper
          if (_vm.step == KycStep.submitting) {
            return _SubmittingView(message: _vm.progressText ?? 'Submitting...');
          }
          if (_vm.step == KycStep.error && _vm.isProfileIncomplete) {
            return _ProfileIncompleteView(
                onGoToProfile: () => Navigator.pop(context));
          }
          if (currentStep == 2) {
            return _FullyVerifiedView(onDone: () => Navigator.pop(context));
          }

          return Column(
            children: [
              _KycStepper(currentStep: currentStep),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadAll,
                  child: currentStep == 1
                      ? VideoKycScreen(docKycStatus: status!.status,embedded: true,)
                      : _buildDocumentTabContent(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDocumentTabContent() {
    return switch (_vm.step) {
      KycStep.loading => const _LoadingView(),

      KycStep.success => _SuccessView(
        onDone: () async => _loadAll(),
      ),

      KycStep.submitting => _SubmittingView(
        message: _vm.progressText ?? 'Submitting...',
      ),

      KycStep.error when _vm.isProfileIncomplete => _ProfileIncompleteView(
        onGoToProfile: () => Navigator.pop(context),
      ),

      _ => _buildFormView(),
    };
  }

  Widget _buildFormView() {
    final status = _vm.kycStatus;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Status banners ──────────────────────────────────────
                if (status != null && status.isPending)
                  const _PendingBanner()
                else if (status != null && status.isRejected)
                  _RejectedBanner(
                    reason: status.rejectionReason ??
                        'Documents did not meet requirements',
                  ),

                // ── Error banner ────────────────────────────────────────
                if (_vm.errorMessage != null &&
                    _vm.step == KycStep.error &&
                    !_vm.isProfileIncomplete)
                  _ErrorBanner(
                    message: _vm.errorMessage!,
                    onRetry: _vm.retryAfterError,
                  ),

                // ── Pending state: show what was submitted + locked step 2
                if (status != null && status.isPending) ...[
                  const SizedBox(height: 8),
                  const _LockedNextStepCard(),
                  const SizedBox(height: 16),
                  _ApprovedDetailCard(status: status),
                ] else ...[

                  // ── Info card ─────────────────────────────────────────
                  const _InfoCard(),
                  const SizedBox(height: 24),

                  // ── Address Proof ─────────────────────────────────────
                  const _SectionHeader(
                    number: '1',
                    title: 'Address Proof',
                    subtitle: 'Proof of your current residential address',
                  ),
                  const SizedBox(height: 12),
                  _ProofTypeDropdown(
                    label: 'Document Type',
                    value: _vm.addressProofType,
                    options: _vm.addressProofTypes,
                    onChanged: _vm.setAddressProofType,
                  ),
                  const SizedBox(height: 12),
                  _FileUploadCard(
                    file: _vm.addressFile,
                    fileName: _vm.addressFileName,
                    onPick: () => _vm.pickAddressFile(context),
                    onRemove: _vm.removeAddressFile,
                    hint: 'Upload your ${_vm.addressProofType}',
                  ),
                  const SizedBox(height: 28),

                  // ── ID Proof ──────────────────────────────────────────
                  const _SectionHeader(
                    number: '2',
                    title: 'ID Proof',
                    subtitle: 'Government issued photo identity',
                  ),
                  const SizedBox(height: 12),
                  _ProofTypeDropdown(
                    label: 'Document Type',
                    value: _vm.idProofType,
                    options: _vm.idProofTypes,
                    onChanged: _vm.setIdProofType,
                  ),
                  const SizedBox(height: 12),
                  _FileUploadCard(
                    file: _vm.idFile,
                    fileName: _vm.idFileName,
                    onPick: () => _vm.pickIdFile(context),
                    onRemove: _vm.removeIdFile,
                    hint: 'Upload your ${_vm.idProofType}',
                  ),
                  const SizedBox(height: 24),

                  const _TipsCard(),
                  const SizedBox(height: 100),
                ],
              ],
            ),
          ),
        ),

        // Submit button only when not yet submitted or rejected
        if (status == null || status.isNotSubmitted || status.isRejected)
          _SubmitButton(
            enabled: _vm.canSubmit,
            onTap: _vm.submit,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEPPER
// ─────────────────────────────────────────────────────────────────────────────

class _KycStepper extends StatelessWidget {
  final int currentStep;
  const _KycStepper({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      child: Row(
        children: [
          _StepNode(
            title: 'Documents',
            icon: Icons.description_outlined,
            active: currentStep == 0,
            done: currentStep > 0,
          ),
          _StepConnector(done: currentStep > 0),
          _StepNode(
            title: 'Video KYC',
            icon: Icons.videocam_outlined,
            active: currentStep == 1,
            done: currentStep > 1,
          ),
          _StepConnector(done: currentStep > 1),
          _StepNode(
            title: 'Verified',
            icon: Icons.verified_rounded,
            active: currentStep == 2,
            done: false,
          ),
        ],
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  final String   title;
  final IconData icon;
  final bool     active;
  final bool     done;

  const _StepNode({
    required this.title,
    required this.icon,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? Colors.green
                  : active
                  ? Colors.white
                  : Colors.white.withOpacity(0.25),
              border: Border.all(
                color: active ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              done ? Icons.check_rounded : icon,
              color: done
                  ? Colors.white
                  : active
                  ? AppColors.primary
                  : Colors.white.withOpacity(0.5),
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: (done || active) ? Colors.white : Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool done;
  const _StepConnector({required this.done});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 28,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: done ? Colors.green : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCKED NEXT STEP CARD
// ─────────────────────────────────────────────────────────────────────────────

class _LockedNextStepCard extends StatelessWidget {
  const _LockedNextStepCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_outline_rounded,
              color: Colors.grey, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Step 2: Video KYC — Locked',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 3),
            Text(
              'Unlocks automatically once your documents are approved.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500,
                  height: 1.4),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FULLY VERIFIED
// ─────────────────────────────────────────────────────────────────────────────

class _FullyVerifiedView extends StatelessWidget {
  final VoidCallback onDone;
  const _FullyVerifiedView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.verified_rounded,
                  color: Colors.green, size: 68),
            ),
            const SizedBox(height: 28),
            const Text(
              'KYC Complete! 🎉',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            const Text(
              'Both your document verification and video KYC are complete.\nYou now have full access to all features.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.6),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Back to Home',
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
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
          child: Center(
            child: Text(number,
                style: const TextStyle(color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DROPDOWN
// ─────────────────────────────────────────────────────────────────────────────

class _ProofTypeDropdown extends StatelessWidget {
  final String             label;
  final String             value;
  final List<String>       options;
  final ValueChanged<String> onChanged;

  const _ProofTypeDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.textGrey)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textGrey),
              style: const TextStyle(fontSize: 15, color: AppColors.textDark,
                  fontWeight: FontWeight.w500),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILE UPLOAD CARD
// ─────────────────────────────────────────────────────────────────────────────

class _FileUploadCard extends StatelessWidget {
  final File?        file;
  final String       fileName;
  final String       hint;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _FileUploadCard({
    required this.file,
    required this.fileName,
    required this.hint,
    required this.onPick,
    required this.onRemove,
  });

  bool get _isImage =>
      file != null &&
          (file!.path.endsWith('.jpg') ||
              file!.path.endsWith('.jpeg') ||
              file!.path.endsWith('.png'));

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: file != null
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.borderColor,
          width: file != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: file == null
          ? _EmptyState(hint: hint, onTap: onPick)
          : _FilledState(
        file: file!,
        fileName: fileName,
        isImage: _isImage,
        onPick: onPick,
        onRemove: onRemove,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String       hint;
  final VoidCallback onTap;
  const _EmptyState({required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.upload_file_outlined, size: 30,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(hint,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.primary),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text('Camera • Gallery • PDF',
                style: TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }
}

class _FilledState extends StatelessWidget {
  final File         file;
  final String       fileName;
  final bool         isImage;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _FilledState({
    required this.file,
    required this.fileName,
    required this.isImage,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          child: isImage
              ? Image.file(file, height: 180, width: double.infinity,
              fit: BoxFit.cover)
              : Container(
            height: 120,
            color: Colors.grey.shade50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.picture_as_pdf_rounded, size: 52,
                    color: Colors.red.shade400),
                const SizedBox(height: 8),
                Text('PDF Document',
                    style: TextStyle(color: Colors.grey.shade500,
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.green, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(fileName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textDark),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            _ActionChip(label: 'Change', color: AppColors.primary, onTap: onPick),
            const SizedBox(width: 6),
            _ActionChip(label: 'Remove', color: Colors.red, onTap: onRemove),
          ]),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 12,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO + TIPS CARDS
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Step 1 of 2 — Document Verification',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                    color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text(
              'Upload your address proof and a government-issued ID. '
                  'Once approved, Step 2 (a short video call) will unlock automatically.',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.5),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    const tips = [
      'Ensure documents are clearly visible and not blurry',
      'All four corners of the document must be visible',
      'File size must be under 5 MB',
      'Accepted formats: JPG, PNG, PDF',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5C842).withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF8B6914), size: 18),
          SizedBox(width: 8),
          Text('Tips for faster approval',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                  color: Color(0xFF8B6914))),
        ]),
        const SizedBox(height: 10),
        ...tips.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('• ',
                style: TextStyle(color: Color(0xFF8B6914),
                    fontWeight: FontWeight.w700)),
            Expanded(
              child: Text(t,
                  style: const TextStyle(fontSize: 12,
                      color: Color(0xFF8B6914), height: 1.4)),
            ),
          ]),
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BANNERS
// ─────────────────────────────────────────────────────────────────────────────

class _PendingBanner extends StatelessWidget {
  const _PendingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5C842).withOpacity(0.5)),
      ),
      child: const Row(children: [
        Icon(Icons.hourglass_top_rounded, color: Color(0xFF8B6914), size: 24),
        SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Documents Under Review',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15,
                    color: Color(0xFF8B6914))),
            SizedBox(height: 3),
            Text(
              'Your documents are being verified (24–48 hrs). '
                  'Video KYC will unlock automatically once approved.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8B6914), height: 1.4),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _RejectedBanner extends StatelessWidget {
  final String reason;
  const _RejectedBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.cancel_rounded, color: Colors.red.shade600, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Documents Rejected',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15,
                    color: Colors.red.shade600)),
            const SizedBox(height: 3),
            Text('Reason: $reason',
                style: TextStyle(fontSize: 12, color: Colors.red.shade600,
                    height: 1.4)),
            const SizedBox(height: 6),
            Text('Please re-upload correct documents below.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: Colors.red.shade700)),
          ]),
        ),
      ]),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
          ),
          child: const Text('Retry',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APPROVED DETAIL CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ApprovedDetailCard extends StatelessWidget {
  final KycStatus status;
  const _ApprovedDetailCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(children: [
        _DetailRow(label: 'Address Proof',
            value: status.addressProofType ?? '-'),
        const Divider(height: 20),
        _DetailRow(label: 'ID Proof', value: status.idProofType ?? '-'),
        if (status.submittedAt != null) ...[
          const Divider(height: 20),
          _DetailRow(label: 'Submitted On', value: status.submittedAt!),
        ],
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
      const Spacer(),
      Text(value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.textDark)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUBMIT BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final bool         enabled;
  final VoidCallback onTap;

  const _SubmitButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.35),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(
            enabled
                ? 'Submit KYC Documents'
                : 'Upload Both Documents to Continue',
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE INCOMPLETE
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileIncompleteView extends StatelessWidget {
  final VoidCallback onGoToProfile;
  const _ProfileIncompleteView({required this.onGoToProfile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                  color: Colors.orange.shade50, shape: BoxShape.circle),
              child: Icon(Icons.person_outline_rounded,
                  color: Colors.orange.shade600, size: 56),
            ),
            const SizedBox(height: 28),
            const Text('Complete Your Profile First',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            const Text(
              'Your name and address details are required before you can submit KYC documents.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.6),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onGoToProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Go to Profile',
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
// LOADING / SUBMITTING
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _SubmittingView extends StatelessWidget {
  final String message;
  const _SubmittingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(message,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    color: AppColors.textDark),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text("Please don't close the app",
                style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUCCESS VIEW  (stays in flow, shows pending state after reload)
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 64),
            ),
            const SizedBox(height: 28),
            const Text('Documents Submitted!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            const Text(
              'Your documents are now under review.\n\n'
                  'We typically verify within 24–48 hours. '
                  'Video KYC (Step 2) will unlock automatically once approved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.6),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Got it',
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