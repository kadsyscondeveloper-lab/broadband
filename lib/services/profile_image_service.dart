// lib/services/profile_image_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api_client.dart';

// ── Result wrapper ────────────────────────────────────────────────────────────

class ProfileImageResult {
  final bool    success;
  final String? imageBase64; // raw base64 (no data URI prefix) — for immediate display
  final String? error;

  const ProfileImageResult({
    required this.success,
    this.imageBase64,
    this.error,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class ProfileImageService {
  // Singleton
  static final ProfileImageService _instance = ProfileImageService._();
  factory ProfileImageService() => _instance;
  ProfileImageService._();

  final _api    = ApiClient();
  final _picker = ImagePicker();

  /// Pick an image from [source] (gallery or camera), compress it,
  /// upload as a base64 data URI via PUT /user/profile/image,
  /// and return the raw base64 so the UI can render it immediately.
  Future<ProfileImageResult> pickAndUpload({
    required ImageSource source,
  }) async {
    try {
      // 1. Let user pick / capture
      final picked = await _picker.pickImage(
        source:       source,
        imageQuality: 72,   // keep file size reasonable
        maxWidth:     800,
        maxHeight:    800,
      );

      if (picked == null) {
        // User cancelled — not an error, just no-op
        return const ProfileImageResult(success: false, error: null);
      }

      // 2. Read bytes & encode
      final bytes   = await File(picked.path).readAsBytes();
      final base64  = base64Encode(bytes);
      final mime    = _mimeType(picked.path);
      final dataUri = 'data:$mime;base64,$base64';

      // 3. Upload to backend
      await _api.put('/user/profile/image', data: {'image_url': dataUri});

      return ProfileImageResult(success: true, imageBase64: base64);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?
          ?? e.message
          ?? 'Upload failed';
      return ProfileImageResult(success: false, error: msg);
    } catch (e) {
      return ProfileImageResult(success: false, error: e.toString());
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png'))  return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg'; // default for .jpg / .jpeg / unknown
  }
}