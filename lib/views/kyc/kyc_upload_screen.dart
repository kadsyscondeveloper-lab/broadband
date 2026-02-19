//ui only

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({super.key});

  @override
  State<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends State<KycUploadScreen> {
  String _addressProof = 'Rent Agreement';
  String _idProof = 'Passport';
  bool _isSubmitting = false;

  final List<String> addressProofTypes = ['Rent Agreement', 'Utility Bill', 'Bank Statement', 'Passport', 'Voter ID'];
  final List<String> idProofTypes = ['Passport', 'Aadhar Card', 'Voter ID', 'Driving License', 'PAN Card'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('KYC Upload'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // In Review banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.reviewBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF5C842).withOpacity(0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.badge_outlined, color: Color(0xFF8B6914), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('In Review', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              SizedBox(height: 4),
                              Text(
                                'Your KYC documents have been submitted and are currently under review. We\'ll notify you once the verification is complete.',
                                style: TextStyle(color: Color(0xFF8B6914), fontSize: 12, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Address Proof
                  const Text('Address Proof', style: TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderColor)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _addressProof,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textGrey),
                        items: addressProofTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 15)))).toList(),
                        onChanged: (v) => v != null ? setState(() => _addressProof = v) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Upload area - address proof
                  _UploadBox(label: 'Upload Address Proof'),
                  const SizedBox(height: 24),

                  // ID Proof
                  const Text('ID Proof', style: TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderColor)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _idProof,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textGrey),
                        items: idProofTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 15)))).toList(),
                        onChanged: (v) => v != null ? setState(() => _idProof = v) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Upload area - ID proof
                  _UploadBox(label: 'Upload ID Proof'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () async {
                  setState(() => _isSubmitting = true);
                  await Future.delayed(const Duration(seconds: 1));
                  if (mounted) {
                    setState(() => _isSubmitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('KYC submitted successfully!'), backgroundColor: Colors.green),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadBox extends StatefulWidget {
  final String label;
  const _UploadBox({required this.label});

  @override
  State<_UploadBox> createState() => _UploadBoxState();
}

class _UploadBoxState extends State<_UploadBox> {
  bool _hasImage = true; // simulate already uploaded

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _hasImage = !_hasImage),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _hasImage
                  ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.grey.shade300,
                      child: Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.image, size: 50, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(widget.label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ]),
                      ),
                    ),
                  ),
                  // Simulate status bar effect like in screenshot
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                      ),
                      child: const Center(
                        child: Text('Tap to change', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ),
                    ),
                  ),
                ],
              )
                  : Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('Tap to upload', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            const SizedBox(height: 30),
            // View icon
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
              child: const Icon(Icons.remove_red_eye_outlined, size: 20, color: AppColors.textGrey),
            ),
            const SizedBox(height: 8),
            // Delete icon
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline, size: 20, color: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }
}
