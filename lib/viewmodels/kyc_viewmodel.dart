import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/kyc_service.dart';
import '../services/user_service.dart';

enum KycStep { loading, form, submitting, success, error }

class KycViewModel extends ChangeNotifier {
  final _service   = KycService();
  final _imgPicker = ImagePicker();

  // ── Doc KYC state ─────────────────────────────────────────────────────────
  KycStep    _step         = KycStep.loading;
  String?    _errorMessage;
  String?    _progressText;
  KycStatus? _kycStatus;

  String _addressProofType = 'Rent Agreement';
  String _idProofType      = 'Aadhar Card';
  File?  _addressFile;
  File?  _idFile;

  // ── Video KYC state ───────────────────────────────────────────────────────
  VideoKycStatus? _videoKycStatus;
  File?   _videoFile;
  String  _preferredDate  = '';
  String  _preferredSlot  = 'Morning (9 AM – 12 PM)';
  String  _callPhone      = '';
  bool    _videoSubmitting = false;
  String? _videoError;
  bool    _videoSuccess    = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  KycStep         get step           => _step;
  String?         get errorMessage   => _errorMessage;
  String?         get progressText   => _progressText;
  KycStatus?      get kycStatus      => _kycStatus;
  String          get addressProofType => _addressProofType;
  String          get idProofType      => _idProofType;
  File?           get addressFile    => _addressFile;
  File?           get idFile         => _idFile;

  VideoKycStatus? get videoKycStatus  => _videoKycStatus;
  File?           get videoFile       => _videoFile;
  String          get preferredDate   => _preferredDate;
  String          get preferredSlot   => _preferredSlot;
  String          get callPhone       => _callPhone;
  bool            get videoSubmitting => _videoSubmitting;
  String?         get videoError      => _videoError;
  bool            get videoSuccess    => _videoSuccess;

  bool get isSubmitting        => _step == KycStep.submitting;
  bool get hasAddressFile      => _addressFile != null;
  bool get hasIdFile           => _idFile != null;
  bool get canSubmit           => hasAddressFile && hasIdFile && !isSubmitting;
  bool get hasVideoFile        => _videoFile != null;
  bool get canSubmitVideo      =>
      _preferredDate.isNotEmpty && _callPhone.isNotEmpty && !_videoSubmitting;
  bool get isProfileIncomplete =>
      _step == KycStep.error && (_errorMessage?.contains('profile') ?? false);

  String get addressFileName =>
      _addressFile != null ? _addressFile!.path.split('/').last : '';
  String get idFileName =>
      _idFile != null ? _idFile!.path.split('/').last : '';
  String get videoFileName =>
      _videoFile != null ? _videoFile!.path.split('/').last : '';

  final List<String> addressProofTypes = [
    'Rent Agreement', 'Utility Bill', 'Bank Statement', 'Passport', 'Voter ID',
  ];
  final List<String> idProofTypes = [
    'Aadhar Card', 'Passport', 'Voter ID', 'Driving License', 'PAN Card',
  ];
  final List<String> timeSlots = [
    'Morning (9 AM – 12 PM)',
    'Afternoon (12 PM – 3 PM)',
    'Evening (3 PM – 6 PM)',
  ];

  // ── Init ──────────────────────────────────────────────────────────────────
  final _userService = UserService();

  Future<void> init() async {
    _step = KycStep.loading;
    notifyListeners();

    final profile = await _userService.getProfile();
    final addr    = profile?.address;
    final isComplete = profile != null &&
        profile.name.isNotEmpty &&
        addr != null &&
        addr.address.isNotEmpty &&
        addr.city.isNotEmpty &&
        addr.state.isNotEmpty &&
        addr.pinCode.isNotEmpty;

    if (!isComplete) {
      _step         = KycStep.error;
      _errorMessage = 'Please complete your profile (name and address) before submitting KYC.';
      notifyListeners();
      return;
    }

    final results = await Future.wait([
      _service.getStatus(),
      _service.getVideoStatus(),
    ]);
    _kycStatus      = results[0] as KycStatus;
    _videoKycStatus = results[1] as VideoKycStatus;
    _callPhone      = profile?.phone ?? '';
    _step           = KycStep.form;
    notifyListeners();
  }

  // ── Setters ───────────────────────────────────────────────────────────────
  void setAddressProofType(String v) { _addressProofType = v; notifyListeners(); }
  void setIdProofType(String v)      { _idProofType = v;      notifyListeners(); }
  void setPreferredDate(String v)    { _preferredDate = v;    notifyListeners(); }
  void setPreferredSlot(String v)    { _preferredSlot = v;    notifyListeners(); }
  void setCallPhone(String v)        { _callPhone = v;        notifyListeners(); }

  // ── File picking ──────────────────────────────────────────────────────────
  Future<void> pickAddressFile(BuildContext ctx) async {
    final f = await _showPickerSheet(ctx, allowVideo: false);
    if (f != null) { _addressFile = f; notifyListeners(); }
  }

  Future<void> pickIdFile(BuildContext ctx) async {
    final f = await _showPickerSheet(ctx, allowVideo: false);
    if (f != null) { _idFile = f; notifyListeners(); }
  }

  Future<void> pickVideoFile(BuildContext ctx) async {
    final f = await _showPickerSheet(ctx, allowVideo: true);
    if (f != null) { _videoFile = f; notifyListeners(); }
  }

  void removeAddressFile() { _addressFile = null; notifyListeners(); }
  void removeIdFile()      { _idFile = null;      notifyListeners(); }
  void removeVideoFile()   { _videoFile = null;   notifyListeners(); }

  Future<File?> _showPickerSheet(BuildContext ctx, {required bool allowVideo}) async {
    final source = await showModalBottomSheet<String>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _FilePickerSheet(
        allowVideo: allowVideo,
        onCamera:   () => Navigator.pop(sheetCtx, 'camera'),
        onGallery:  () => Navigator.pop(sheetCtx, 'gallery'),
        onDocument: () => Navigator.pop(sheetCtx, 'document'),
        onVideo:    () => Navigator.pop(sheetCtx, 'video'),
      ),
    );
    if (source == null) return null;

    switch (source) {
      case 'camera':
        final img = await _imgPicker.pickImage(source: ImageSource.camera, imageQuality: 80);
        return img != null ? File(img.path) : null;
      case 'gallery':
        final img = await _imgPicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        return img != null ? File(img.path) : null;
      case 'video':
        final vid = await _imgPicker.pickVideo(source: ImageSource.gallery);
        return vid != null ? File(vid.path) : null;
      case 'document':
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        );
        if (result?.files.single.path != null) return File(result!.files.single.path!);
        return null;
      default:
        return null;
    }
  }

  // ── Submit doc KYC ────────────────────────────────────────────────────────
  Future<void> submit() async {
    if (!canSubmit) return;

    _step         = KycStep.submitting;
    _errorMessage = null;
    _progressText = 'Uploading documents…';
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

  // ── Submit video KYC ──────────────────────────────────────────────────────
  Future<void> submitVideoKyc() async {
    if (!canSubmitVideo) return;

    _videoSubmitting = true;
    _videoError      = null;
    _videoSuccess    = false;
    notifyListeners();

    final result = await _service.submitVideoKyc(
      preferredDate: _preferredDate,
      preferredSlot: _preferredSlot,
      callPhone:     _callPhone,
      videoFile:     _videoFile,
    );

    _videoSubmitting = false;
    if (result.success) {
      _videoKycStatus = result.videoKycStatus;
      _videoSuccess   = true;
    } else {
      _videoError = result.error;
    }
    notifyListeners();
  }

  Future<void> cancelVideoKyc() async {
    await _service.cancelVideoKyc();
    _videoKycStatus = VideoKycStatus.notSubmitted();
    _videoSuccess   = false;
    notifyListeners();
  }

  void retryAfterError() {
    _step = KycStep.form;
    _errorMessage = null;
    notifyListeners();
  }

  void clearVideoError() {
    _videoError = null;
    notifyListeners();
  }
}

// ── File / Video picker bottom sheet ─────────────────────────────────────────

class _FilePickerSheet extends StatelessWidget {
  final bool         allowVideo;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onDocument;
  final VoidCallback onVideo;

  const _FilePickerSheet({
    required this.allowVideo,
    required this.onCamera,
    required this.onGallery,
    required this.onDocument,
    required this.onVideo,
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
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              allowVideo ? 'Upload Video / Document' : 'Upload Document',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 6),
            Text(
              allowVideo ? 'MP4, MOV, WebM • Max 100 MB' : 'JPG, PNG or PDF • Max 10 MB',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: allowVideo
                  ? [
                _SheetOption(icon: Icons.videocam_outlined,     label: 'Gallery', onTap: onVideo),
                _SheetOption(icon: Icons.description_outlined,  label: 'Files',   onTap: onDocument),
              ]
                  : [
                _SheetOption(icon: Icons.camera_alt_outlined,   label: 'Camera',   onTap: onCamera),
                _SheetOption(icon: Icons.photo_library_outlined, label: 'Gallery',  onTap: onGallery),
                _SheetOption(icon: Icons.description_outlined,  label: 'Document', onTap: onDocument),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;

  const _SheetOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1A1A2E);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primary.withOpacity(0.15)),
            ),
            child: Icon(icon, size: 32, color: primary),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}