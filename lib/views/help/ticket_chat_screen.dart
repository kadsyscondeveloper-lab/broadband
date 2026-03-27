// lib/views/help/ticket_chat_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ticket_service.dart';
import '../../theme/app_theme.dart';

class TicketChatScreen extends StatefulWidget {
  final int    ticketId;
  final String ticketNumber;
  final String subject;

  const TicketChatScreen({
    super.key,
    required this.ticketId,
    required this.ticketNumber,
    required this.subject,
  });

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final _service    = TicketService();
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<TicketMessage> _messages      = [];
  bool    _isLoading    = true;
  bool    _isSending    = false;
  bool    _isActive     = true;
  String  _status       = '';
  String? _error;
  int?    _lastMessageId;

  // ── Attachment state ───────────────────────────────────────────────────────
  String? _pendingAttachmentData;
  String? _pendingAttachmentMime;
  String? _pendingAttachmentName;
  bool    _pickingAttachment = false;

  Timer? _pollTimer;
  static const _pollInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _loadMessages() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final state = await _service.getMessages(widget.ticketId);
      if (!mounted || state == null) return;
      setState(() {
        _messages      = state.messages;
        _isActive      = state.isActive;
        _status        = state.status;
        _lastMessageId = state.messages.isNotEmpty
            ? state.messages.last.id : null;
        _isLoading     = false;
      });
      _scrollToBottom(jump: true);
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ── Polling ───────────────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    if (!_isActive) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      try {
        final state = await _service.getMessages(
            widget.ticketId, afterId: _lastMessageId);
        if (!mounted || state == null) return;
        final newMessages = state.messages;
        if (newMessages.isNotEmpty || state.status != _status) {
          setState(() {
            _messages.addAll(newMessages);
            _isActive = state.isActive;
            _status   = state.status;
            if (newMessages.isNotEmpty) _lastMessageId = newMessages.last.id;
          });
          if (newMessages.isNotEmpty) _scrollToBottom();
          if (!state.isActive) _pollTimer?.cancel();
        }
      } catch (_) {}
    });
  }

  // ── Attachment picking ────────────────────────────────────────────────────

  Future<void> _pickAttachment() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AttachPickerSheet(
        onCamera:   () => Navigator.pop(ctx, 'camera'),
        onGallery:  () => Navigator.pop(ctx, 'gallery'),
        onDocument: () => Navigator.pop(ctx, 'document'),
      ),
    );

    if (source == null || !mounted) return;
    setState(() => _pickingAttachment = true);

    try {
      Uint8List? bytes;
      String?    mime;
      String?    name;

      if (source == 'camera') {
        final img = await ImagePicker().pickImage(
          source:       ImageSource.camera,
          imageQuality: 70,
          maxWidth:     1200,
        );
        if (img != null) {
          bytes = await img.readAsBytes();
          mime  = 'image/jpeg';
          name  = img.name;
        }
      } else if (source == 'gallery') {
        final img = await ImagePicker().pickImage(
          source:       ImageSource.gallery,
          imageQuality: 70,
          maxWidth:     1200,
        );
        if (img != null) {
          bytes = await img.readAsBytes();
          mime  = img.name.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg';
          name = img.name;
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          type:              FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
          withData:          true,
        );
        if (result != null && result.files.first.bytes != null) {
          bytes = result.files.first.bytes!;
          name  = result.files.first.name;
          final ext = result.files.first.extension?.toLowerCase() ?? '';
          mime  = ext == 'pdf' ? 'application/pdf'
              : ext == 'png' ? 'image/png'
              : 'image/jpeg';
        }
      }

      if (bytes == null || !mounted) return;

      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:         Text('File too large. Maximum size is 5 MB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _pendingAttachmentData = base64Encode(bytes!);
        _pendingAttachmentMime = mime;
        _pendingAttachmentName = name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick file: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingAttachment = false);
    }
  }

  void _clearAttachment() {
    setState(() {
      _pendingAttachmentData = null;
      _pendingAttachmentMime = null;
      _pendingAttachmentName = null;
    });
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text        = _controller.text.trim();
    final hasText     = text.isNotEmpty;
    final hasAttach   = _pendingAttachmentData != null;

    if ((!hasText && !hasAttach) || _isSending || !_isActive) return;

    setState(() => _isSending = true);
    _controller.clear();

    // Snapshot and clear pending attachment before the async call
    final attachData = _pendingAttachmentData;
    final attachMime = _pendingAttachmentMime;
    _clearAttachment();

    final tempId = DateTime.now().millisecondsSinceEpoch;
    setState(() => _messages.add(TicketMessage(
      id:             tempId,
      senderId:       0,
      senderType:     'user',
      message:        text,
      attachmentData: attachData,
      attachmentMime: attachMime,
      createdAt:      DateTime.now(),
    )));
    _scrollToBottom();

    try {
      final sent = await _service.sendMessage(
        widget.ticketId,
        text,
        attachmentData: attachData,
        attachmentMime: attachMime,
      );
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == tempId);
        if (idx != -1) _messages[idx] = sent;
        _lastMessageId = sent.id;
        _isSending     = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.id == tempId);
        _controller.text           = text;
        _pendingAttachmentData     = attachData;  // restore on failure
        _pendingAttachmentMime     = attachMime;
        _isSending                 = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Failed to send. Please try again.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  // ── Fullscreen image viewer ────────────────────────────────────────────────

  void _openFullscreen(String base64Data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme:       const IconThemeData(color: Colors.white),
            elevation:       0,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(
                base64Decode(base64Data),
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white,
                  size:  64,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Scroll ────────────────────────────────────────────────────────────────

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final max = _scrollCtrl.position.maxScrollExtent;
      jump
          ? _scrollCtrl.jumpTo(max)
          : _scrollCtrl.animateTo(max,
          duration: const Duration(milliseconds: 280),
          curve:    Curves.easeOut);
    });
  }

  // ── Status helpers ────────────────────────────────────────────────────────

  String get _statusLabel {
    switch (_status.toLowerCase()) {
      case 'in_progress':
      case 'in progress':   return 'In Progress';
      case 'resolved':      return 'Resolved';
      case 'closed':        return 'Closed';
      case 'awaiting_user':
      case 'awaiting user': return 'Awaiting You';
      default:              return 'Open';
    }
  }

  Color get _statusColor {
    switch (_status.toLowerCase()) {
      case 'resolved':      return Colors.green;
      case 'closed':        return Colors.grey;
      case 'in_progress':
      case 'in progress':   return Colors.orange;
      case 'awaiting_user':
      case 'awaiting user': return Colors.purple;
      default:              return Colors.blue;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
          ? _buildError()
          : Column(children: [
        Expanded(child: _buildMessageList()),
        _buildInputBar(),
      ]),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.20),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.support_agent_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.subject,
                style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   14,
                    fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.ticketNumber,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 11),
              ),
            ],
          ),
        ),
      ]),
      actions: [
        if (_status.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.40)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color:  Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _statusLabel,
                    style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   11,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            ),
          ),
      ],
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('No messages yet',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize:   16,
                  color:      AppColors.textDark)),
          const SizedBox(height: 8),
          const Text(
            'Send a message and our support\nteam will respond shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: AppColors.textGrey, height: 1.5),
          ),
        ]),
      );
    }

    return ListView.builder(
      controller:  _scrollCtrl,
      padding:     const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount:   _messages.length,
      itemBuilder: (context, index) {
        final msg  = _messages[index];
        final prev = index > 0 ? _messages[index - 1] : null;
        final next = index < _messages.length - 1
            ? _messages[index + 1] : null;

        final showDate = prev == null ||
            !_isSameDay(prev.createdAt, msg.createdAt);

        final isLastInGroup = next == null ||
            next.isFromUser != msg.isFromUser ||
            !_isSameDay(next.createdAt, msg.createdAt);

        return Column(children: [
          if (showDate) _DateDivider(date: msg.createdAt),
          _MessageBubble(
            message:       msg,
            isLastInGroup: isLastInGroup,
            onImageTap:    _openFullscreen,
          ),
        ]);
      },
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // ── Closed state ─────────────────────────────────────────────────────
    if (!_isActive) {
      return Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad + 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset:     const Offset(0, -3),
            ),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:        Colors.grey.shade100,
              borderRadius: BorderRadius.circular(28),
              border:       Border.all(color: Colors.grey.shade200),
            ),
            child: Row(children: [
              Icon(Icons.add_rounded, color: Colors.grey.shade400, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Type your message...',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ),
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300, shape: BoxShape.circle),
                child: Icon(Icons.send_rounded,
                    color: Colors.grey.shade500, size: 16),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.lock_outline_rounded,
                size: 12, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(
              'TICKET IS ${_status.toUpperCase()}',
              style: TextStyle(
                  fontSize:      10,
                  fontWeight:    FontWeight.w700,
                  color:         Colors.grey.shade400,
                  letterSpacing: 0.8),
            ),
          ]),
        ]),
      );
    }

    // ── Active input ──────────────────────────────────────────────────────
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset:     const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Attachment preview strip ──────────────────────────────────
          if (_pendingAttachmentData != null) ...[
            Container(
              margin:  const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:        AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Row(children: [
                // Thumbnail
                if (_pendingAttachmentMime?.startsWith('image/') == true)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      base64Decode(_pendingAttachmentData!),
                      width:  44,
                      height: 44,
                      fit:    BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color:        Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.red.shade400, size: 24),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pendingAttachmentName ?? 'Attachment',
                        style: const TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color:      AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _pendingAttachmentMime == 'application/pdf'
                            ? 'PDF Document'
                            : 'Image',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _clearAttachment,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color:  Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: AppColors.textGrey),
                  ),
                ),
              ]),
            ),
          ],

          // ── Message row ───────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              // + button (attachment)
              GestureDetector(
                onTap: _pickingAttachment ? null : _pickAttachment,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width:  40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 10, bottom: 2),
                  decoration: BoxDecoration(
                    color: _pickingAttachment
                        ? AppColors.primary.withOpacity(0.15)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _pickingAttachment
                      ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary),
                  )
                      : Icon(Icons.add_rounded,
                      color: Colors.grey.shade500, size: 22),
                ),
              ),

              // Text field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 130),
                  decoration: BoxDecoration(
                    color:        const Color(0xFFF2F3F7),
                    borderRadius: BorderRadius.circular(26),
                    border:       Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller:         _controller,
                    maxLines:           5,
                    minLines:           1,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.textDark),
                    decoration: const InputDecoration(
                      hintText:       'Type a message...',
                      hintStyle:      TextStyle(
                          color: AppColors.textLight, fontSize: 15),
                      border:         InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),

              // Send button
              GestureDetector(
                onTap: _isSending ? null : _sendMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width:  50,
                  height: 50,
                  margin: const EdgeInsets.only(left: 10, bottom: 1),
                  decoration: BoxDecoration(
                    color: _isSending
                        ? AppColors.primary.withOpacity(0.55)
                        : AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:      AppColors.primary.withOpacity(0.40),
                        blurRadius: 10,
                        offset:     const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isSending
                      ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                      : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded,
            size: 48, color: AppColors.textLight),
        const SizedBox(height: 12),
        Text(_error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loadMessages,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          child: const Text('Retry',
              style: TextStyle(color: Colors.white)),
        ),
      ]),
    ),
  );

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─────────────────────────────────────────────────────────────────────────────
// ATTACHMENT PICKER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _AttachPickerSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onDocument;

  const _AttachPickerSheet({
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
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color:        Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Send Attachment',
              style: TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.w800,
                  color:      AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              'JPG, PNG or PDF · Max 5 MB',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SheetOption(
                    icon:  Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: onCamera),
                _SheetOption(
                    icon:  Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: onGallery),
                _SheetOption(
                    icon:  Icons.description_outlined,
                    label: 'Document',
                    onTap: onDocument),
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

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:    onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              color:        AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.18)),
            ),
            child: Icon(icon, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize:   13,
              color:      Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final TicketMessage      message;
  final bool               isLastInGroup;
  final void Function(String base64Data) onImageTap;

  const _MessageBubble({
    required this.message,
    required this.isLastInGroup,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;
    final time   = _fmtTime(message.createdAt);

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLastInGroup ? 12 : 3,
        left:   isUser ? 48 : 0,
        right:  isUser ? 0  : 48,
      ),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          // Agent avatar
          if (!isUser) ...[
            if (isLastInGroup)
              Container(
                width: 30, height: 30,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color:  AppColors.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent_rounded,
                    size: 16, color: AppColors.primary),
              )
            else
              const SizedBox(width: 38),
          ],

          // Bubble content
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Sender label
                if (isLastInGroup && !isUser)
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      'SUPPORT TEAM',
                      style: TextStyle(
                          fontSize:      9,
                          fontWeight:    FontWeight.w700,
                          color:         AppColors.textGrey,
                          letterSpacing: 0.5),
                    ),
                  ),
                if (isLastInGroup && isUser)
                  const Padding(
                    padding: EdgeInsets.only(right: 4, bottom: 3),
                    child: Text(
                      'YOU',
                      style: TextStyle(
                          fontSize:      9,
                          fontWeight:    FontWeight.w700,
                          color:         AppColors.primary,
                          letterSpacing: 0.5),
                    ),
                  ),

                // Bubble box
                Container(
                  padding: EdgeInsets.fromLTRB(
                    14,
                    10,
                    14,
                    message.hasAttachment ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(18),
                      topRight:    const Radius.circular(18),
                      bottomLeft:  Radius.circular(
                          !isUser && isLastInGroup ? 4 : 18),
                      bottomRight: Radius.circular(
                          isUser && isLastInGroup  ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:      Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset:     const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text (may be empty if attachment-only)
                      if (message.message.isNotEmpty)
                        Text(
                          message.message,
                          style: TextStyle(
                              fontSize: 14,
                              height:   1.45,
                              color:    isUser
                                  ? Colors.white
                                  : AppColors.textDark),
                        ),

                      // Attachment
                      if (message.hasAttachment) ...[
                        if (message.message.isNotEmpty)
                          const SizedBox(height: 8),
                        _buildAttachment(isUser),
                      ],
                    ],
                  ),
                ),

                // Timestamp
                if (isLastInGroup)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Text(
                      time,
                      style:
                      TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ),
              ],
            ),
          ),

          // User avatar
          if (isUser && isLastInGroup) ...[
            const SizedBox(width: 8),
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color:  AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  size: 16, color: AppColors.primary),
            ),
          ] else if (isUser && !isLastInGroup) ...[
            const SizedBox(width: 38),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachment(bool isUser) {
    final data = message.attachmentData;

    // ── Image attachment ──────────────────────────────────────────────────
    if (message.isImageAttachment && data != null && data.isNotEmpty) {
      return GestureDetector(
        onTap: () => onImageTap(data),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Image.memory(
                base64Decode(data),
                width:            200,
                height:           150,
                fit:              BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 200, height: 150,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image_rounded,
                      size: 40, color: Colors.grey),
                ),
              ),
              // Tap-to-expand hint
              Positioned(
                bottom: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:        Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.open_in_full_rounded,
                      color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── PDF / Document attachment ──────────────────────────────────────────
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withOpacity(0.18)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          Icons.picture_as_pdf_rounded,
          color: isUser ? Colors.white : Colors.red.shade400,
          size:  20,
        ),
        const SizedBox(width: 8),
        Text(
          'Document',
          style: TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w600,
            color: isUser ? Colors.white : AppColors.textDark,
          ),
        ),
      ]),
    );
  }

  String _fmtTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final p = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $p';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATE DIVIDER
// ─────────────────────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  String _label() {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(date.year, date.month, date.day);
    if (d == today)
      return 'Today';
    if (d == today.subtract(const Duration(days: 1)))
      return 'Yesterday';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset:     const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            _label(),
            style: const TextStyle(
                fontSize:   11,
                color:      AppColors.textGrey,
                fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
      ]),
    );
  }
}