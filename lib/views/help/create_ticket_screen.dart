// lib/views/help/create_ticket_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/help_viewmodel.dart';

class CreateTicketScreen extends StatefulWidget {
  final HelpViewModel viewModel;

  const CreateTicketScreen({super.key, required this.viewModel});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;
  bool _pickingFile = false;

  @override
  void initState() {
    super.initState();
    _subjectController     = TextEditingController(text: widget.viewModel.subject);
    _descriptionController = TextEditingController(text: widget.viewModel.description);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ── File picker → base64 ─────────────────────────────────────────────────

  Future<void> _pickFile() async {
    setState(() => _pickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,           // loads bytes into memory — no path needed
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) return;

      // Size check — 5 MB max
      if (file.bytes!.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File too large. Maximum size is 5 MB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final base64  = base64Encode(file.bytes!);
      final mime    = _mimeFromExtension(file.extension ?? '');
      final name    = file.name;

      widget.viewModel.setAttachment(
        base64:   base64,
        mime:     mime,
        fileName: name,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick file: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  String _mimeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':  return 'application/pdf';
      case 'png':  return 'image/png';
      default:     return 'image/jpeg';
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    widget.viewModel.setSubject(_subjectController.text);
    widget.viewModel.setDescription(_descriptionController.text);
    await widget.viewModel.submitTicket();

    if (!mounted) return;

    if (widget.viewModel.submitSuccess) {
      final ref = widget.viewModel.createdTicketNumber ?? '';
      widget.viewModel.resetSubmitState();
      _showSuccessDialog(ref);
    }
    // Error is shown inline via vm.submitError
  }

  void _showSuccessDialog(String ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  color: Colors.green.shade50, shape: BoxShape.circle),
              child: Icon(Icons.check_circle_outline_rounded,
                  color: Colors.green.shade600, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Ticket Created!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              ref.isNotEmpty
                  ? 'Your ticket $ref has been submitted.\nWe\'ll get back to you shortly.'
                  : 'Your ticket has been submitted.\nWe\'ll get back to you shortly.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back to help
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Done',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Create Ticket'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm = widget.viewModel;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Category ────────────────────────────────────────
                      const _FieldLabel(text: 'Issue Category'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: vm.selectedCategory,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            hintText: 'Select',
                            hintStyle:
                            TextStyle(color: AppColors.textLight),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: AppColors.textGrey),
                          items: vm.categories
                              .map((c) => DropdownMenuItem(
                              value: c, child: Text(c)))
                              .toList(),
                          onChanged: vm.setCategory,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Subject ─────────────────────────────────────────
                      const _FieldLabel(text: 'Subject'),
                      const SizedBox(height: 8),
                      _InputField(
                          controller: _subjectController, maxLines: 1),
                      const SizedBox(height: 20),

                      // ── Description ─────────────────────────────────────
                      const _FieldLabel(text: 'Description'),
                      const SizedBox(height: 8),
                      _InputField(
                          controller: _descriptionController, maxLines: 5),
                      const SizedBox(height: 20),

                      // ── Attachment ──────────────────────────────────────
                      const _FieldLabel(text: 'Attachment (Optional)'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickingFile ? null : _pickFile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: vm.hasAttachment
                                  ? AppColors.primary
                                  : AppColors.borderColor,
                            ),
                          ),
                          child: Row(children: [
                            Expanded(
                              child: _pickingFile
                                  ? const Row(children: [
                                SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Picking file…',
                                    style: TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 14)),
                              ])
                                  : Text(
                                vm.attachmentFileName ??
                                    'Upload screenshot/photo (JPG, PNG, PDF)',
                                style: TextStyle(
                                  color: vm.hasAttachment
                                      ? AppColors.textDark
                                      : AppColors.textLight,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (vm.hasAttachment)
                              GestureDetector(
                                onTap: vm.clearAttachment,
                                child: const Icon(Icons.close,
                                    color: AppColors.textGrey, size: 18),
                              )
                            else
                              const Icon(Icons.attach_file,
                                  color: AppColors.textGrey),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text('Max 5 MB · JPG, PNG or PDF',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textGrey)),

                      // ── Error ────────────────────────────────────────────
                      if (vm.submitError != null) ...[
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
                                color: Colors.red.shade700, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(vm.submitError!,
                                  style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 13)),
                            ),
                          ]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Submit button ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: vm.isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: vm.isSubmitting
                        ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : const Text(
                      'Add new Ticket',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final int maxLines;
  const _InputField({required this.controller, required this.maxLines});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor),
    ),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(16),
      ),
    ),
  );
}