// lib/viewmodels/kyc_viewmodel.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/kyc_service.dart';

enum KycStep { loading, form, submitting, success, error }

class KycViewModel extends ChangeNotifier {
  final _service     = KycService();
  final _imgPicker   = ImagePicker();

  // ── State ─────────────────────────────────────────────────────────────────
  KycStep  _step          = KycStep.loading;
  String?  _errorMessage;
  String?  _progressText;
  KycStatus? _kycStatus;

  String  _addressProofType = 'Rent Agreement';
  String  _idProofType      = 'Aadhar Card';
  File?   _addressFile;
  File?   _idFile;

  // ── Getters ───────────────────────────────────────────────────────────────
  KycStep   get step          => _step;
  String?   get errorMessage  => _errorMessage;
  String?   get progressText  => _progressText;
  KycStatus? get kycStatus    => _kycStatus;
  String    get addressProofType => _addressProofType;
  String    get idProofType      => _idProofType;
  File?     get addressFile   => _addressFile;
  File?     get idFile        => _idFile;

  bool get isSubmitting    => _step == KycStep.submitting;
  bool get hasAddressFile  => _addressFile != null;
  bool get hasIdFile       => _idFile != null;
  bool get canSubmit       => hasAddressFile && hasIdFile && !isSubmitting;

  String get addressFileName =>
      _addressFile != null ? _addressFile!.path.split('/').last : '';

  String get idFileName =>
      _idFile != null ? _idFile!.path.split('/').last : '';

  final List<String> addressProofTypes = [
    'Rent Agreement',
    'Utility Bill',
    'Bank Statement',
    'Passport',
    'Voter ID',
  ];

  final List<String> idProofTypes = [
    'Aadhar Card',
    'Passport',
    'Voter ID',
    'Driving License',
    'PAN Card',
  ];

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _step = KycStep.loading;
    notifyListeners();
    _kycStatus = await _service.getStatus();
    _step = KycStep.form;
    notifyListeners();
  }

  // ── Setters ───────────────────────────────────────────────────────────────
  void setAddressProofType(String v) { _addressProofType = v; notifyListeners(); }
  void setIdProofType(String v)      { _idProofType = v;      notifyListeners(); }

  // ── File picking ──────────────────────────────────────────────────────────
  Future<void> pickAddressFile(BuildContext ctx) async {
    final file = await _showPickerSheet(ctx);
    if (file != null) { _addressFile = file; notifyListeners(); }
  }

  Future<void> pickIdFile(BuildContext ctx) async {
    final file = await _showPickerSheet(ctx);
    if (file != null) { _idFile = file; notifyListeners(); }
  }

  void removeAddressFile() { _addressFile = null; notifyListeners(); }
  void removeIdFile()      { _idFile = null;      notifyListeners(); }

  Future<File?> _showPickerSheet(BuildContext ctx) async {
    // Step 1: show the sheet and wait for the user to pick a SOURCE (not a file yet)
    final source = await showModalBottomSheet<String>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _FilePickerSheet(
        onCamera:   () => Navigator.pop(sheetCtx, 'camera'),
        onGallery:  () => Navigator.pop(sheetCtx, 'gallery'),
        onDocument: () => Navigator.pop(sheetCtx, 'document'),
      ),
    );

    if (source == null) return null;

    // Step 2: NOW do the async file picking after the sheet has fully closed
    switch (source) {
      case 'camera':
        final img = await _imgPicker.pickImage(
            source: ImageSource.camera, imageQuality: 80);
        return img != null ? File(img.path) : null;

      case 'gallery':
        final img = await _imgPicker.pickImage(
            source: ImageSource.gallery, imageQuality: 80);
        return img != null ? File(img.path) : null;

      case 'document':
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        );
        if (result != null && result.files.single.path != null) {
          return File(result.files.single.path!);
        }
        return null;

      default:
        return null;
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> submit() async {
    if (!canSubmit) return;

    _step         = KycStep.submitting;
    _errorMessage = null;
    _progressText = 'Encoding documents...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300)); // let UI paint

    _progressText = 'Submitting KYC...';
    notifyListeners();

    final result = await _service.submitKyc(
      addressProofType: _addressProofType,
      addressProofFile: _addressFile!,
      idProofType:      _idProofType,
      idProofFile:      _idFile!,
    );

    if (result.success) {
      _kycStatus = result.kycStatus;
      _step      = KycStep.success;
    } else {
      _step         = KycStep.error;
      _errorMessage = result.error;
    }
    _progressText = null;
    notifyListeners();
  }

  void retryAfterError() {
    _step = KycStep.form;
    _errorMessage = null;
    notifyListeners();
  }
}

// ── File picker bottom sheet ──────────────────────────────────────────────────

class _FilePickerSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onDocument;

  const _FilePickerSheet({
    required this.onCamera,
    required this.onGallery,
    required this.onDocument,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Upload Document',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 6),
            Text(
              'JPG, PNG or PDF • Max 5 MB',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SheetOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: onCamera,
                ),
                _SheetOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: onGallery,
                ),
                _SheetOption(
                  icon: Icons.description_outlined,
                  label: 'Document',
                  onTap: onDocument,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1A1A2E);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primary.withOpacity(0.15)),
            ),
            child: Icon(icon, size: 32, color: primary),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}