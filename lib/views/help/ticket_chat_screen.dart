// lib/views/help/ticket_chat_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
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

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending || !_isActive) return;

    setState(() => _isSending = true);
    _controller.clear();

    final tempId = DateTime.now().millisecondsSinceEpoch;
    setState(() => _messages.add(TicketMessage(
      id: tempId, senderId: 0, senderType: 'user',
      message: text, createdAt: DateTime.now(),
    )));
    _scrollToBottom();

    try {
      final sent = await _service.sendMessage(widget.ticketId, text);
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == tempId);
        if (idx != -1) _messages[idx] = sent;
        _lastMessageId = sent.id;
        _isSending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.id == tempId);
        _controller.text = text;
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send. Please try again.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
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
          curve: Curves.easeOut);
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
        // Agent avatar
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color:  Colors.white.withOpacity(0.20),
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
                    color: Colors.white,
                    fontSize: 14,
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
                  border:       Border.all(
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
              color:  AppColors.primary.withOpacity(0.08),
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

        // Group messages from same sender
        final isLastInGroup = next == null ||
            next.isFromUser != msg.isFromUser ||
            !_isSameDay(next.createdAt, msg.createdAt);

        return Column(children: [
          if (showDate) _DateDivider(date: msg.createdAt),
          _MessageBubble(
              message:       msg,
              isLastInGroup: isLastInGroup),
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
          // Greyed-out input row (visual only)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:        Colors.grey.shade100,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(children: [
              Icon(Icons.add_rounded,
                  color: Colors.grey.shade400, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Type your message...',
                  style: TextStyle(
                      color:    Colors.grey.shade400,
                      fontSize: 14),
                ),
              ),
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color:  Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          // ── + button (outside the field, left) ───────────────────────
          GestureDetector(
            onTap: () {},
            child: Container(
              width:  40,
              height: 40,
              margin: const EdgeInsets.only(right: 10, bottom: 2),
              decoration: BoxDecoration(
                color:        Colors.grey.shade100,
                shape:        BoxShape.circle,
                border:       Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(Icons.add_rounded,
                  color: Colors.grey.shade500, size: 22),
            ),
          ),

          // ── Text field (its own full-width rounded box) ───────────────
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

          // ── Send button (outside the field, right) ────────────────────
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width:  50,
              height: 50,
              margin: const EdgeInsets.only(left: 10, bottom: 1),
              decoration: BoxDecoration(
                color:  _isSending
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
// MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final TicketMessage message;
  final bool          isLastInGroup;

  const _MessageBubble({
    required this.message,
    required this.isLastInGroup,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;
    final time   = _fmtTime(message.createdAt);

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLastInGroup ? 12 : 3,
        left:  isUser ? 48 : 0,
        right: isUser ? 0  : 48,
      ),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          // ── Agent avatar (only on last in group) ────────────────────────
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
              const SizedBox(width: 38), // spacer to align messages
          ],

          // ── Bubble ─────────────────────────────────────────────────────
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Sender label (first of group only)
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

                // Message box
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color:  isUser ? AppColors.primary : Colors.white,
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
                  child: Text(
                    message.message,
                    style: TextStyle(
                        fontSize: 14,
                        height:   1.45,
                        color:    isUser
                            ? Colors.white
                            : AppColors.textDark),
                  ),
                ),

                // Timestamp (only on last in group)
                if (isLastInGroup)
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 4, left: 4, right: 4),
                    child: Text(
                      time,
                      style: TextStyle(
                          fontSize: 10,
                          color:    Colors.grey.shade500),
                    ),
                  ),
              ],
            ),
          ),

          // ── User avatar (only on last in group) ──────────────────────────
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
    const months = ['', 'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        Expanded(
            child: Divider(color: Colors.grey.shade300, height: 1)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color:        Colors.white,
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
        Expanded(
            child: Divider(color: Colors.grey.shade300, height: 1)),
      ]),
    );
  }
}