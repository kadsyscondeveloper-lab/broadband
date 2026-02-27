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

  List<TicketMessage> _messages   = [];
  bool    _isLoading  = true;
  bool    _isSending  = false;
  bool    _isActive   = true;
  String  _status     = '';
  String? _error;
  int?    _lastMessageId;

  Timer? _pollTimer;
  static const _pollInterval = Duration(seconds: 5);

  // ─────────────────────────────────────────────────────────────────────────

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

  // ── Full load ─────────────────────────────────────────────────────────────

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
            ? state.messages.last.id
            : null;
        _isLoading = false;
      });
      _scrollToBottom(jump: true);
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ── Polling every 5s for new messages ────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    if (!_isActive) return; // no need to poll closed tickets

    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      try {
        final state = await _service.getMessages(
          widget.ticketId,
          afterId: _lastMessageId,
        );
        if (!mounted || state == null) return;

        final newMessages = state.messages;
        if (newMessages.isNotEmpty || state.status != _status) {
          setState(() {
            _messages.addAll(newMessages);
            _isActive = state.isActive;
            _status   = state.status;
            if (newMessages.isNotEmpty) {
              _lastMessageId = newMessages.last.id;
            }
          });
          if (newMessages.isNotEmpty) _scrollToBottom();
          if (!state.isActive) _pollTimer?.cancel();
        }
      } catch (_) {
        // Silently ignore poll errors — don't disrupt the UI
      }
    });
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending || !_isActive) return;

    setState(() => _isSending = true);
    _controller.clear();

    // Optimistic insert — show immediately before server confirms
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final optimistic = TicketMessage(
      id:         tempId,
      senderId:   0,
      senderType: 'user',
      message:    text,
      createdAt:  DateTime.now(),
    );

    setState(() => _messages.add(optimistic));
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
          content:         Text('Failed to send. Please try again.'),
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
      if (jump) {
        _scrollCtrl.jumpTo(max);
      } else {
        _scrollCtrl.animateTo(
          max,
          duration: const Duration(milliseconds: 280),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  // ── Status chip color ─────────────────────────────────────────────────────

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'open':            return Colors.blue;
      case 'in progress':
      case 'in_progress':     return Colors.orange;
      case 'awaiting user':
      case 'awaiting_user':   return Colors.purple;
      case 'resolved':        return Colors.green;
      case 'closed':          return Colors.grey;
      default:                return Colors.blue;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.ticketNumber,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700),
          ),
          Text(
            widget.subject,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        if (_status.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        _statusColor(_status).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border:       Border.all(color: Colors.white54),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      fontSize: 16,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              const Text(
                'Send a message and our support team\nwill respond shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color:    AppColors.textGrey,
                    height:   1.5),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller:  _scrollCtrl,
      padding:     const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount:   _messages.length,
      itemBuilder: (context, index) {
        final msg  = _messages[index];
        final prev = index > 0 ? _messages[index - 1] : null;
        final showDate = prev == null ||
            !_isSameDay(prev.createdAt, msg.createdAt);
        return Column(
          children: [
            if (showDate) _DateDivider(date: msg.createdAt),
            _MessageBubble(message: msg),
          ],
        );
      },
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    // Ticket is closed/resolved
    if (!_isActive) {
      return Container(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color:      Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset:     const Offset(0, -2)),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color:        Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(
                'Ticket is $_status — chat closed',
                style: TextStyle(
                    fontSize:   13,
                    color:      Colors.grey.shade500,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 8, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset:     const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color:        const Color(0xFFF0F1F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller:         _controller,
                maxLines:           5,
                minLines:           1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText:        'Type a message...',
                  hintStyle:       TextStyle(
                      color: AppColors.textLight, fontSize: 14),
                  border:          InputBorder.none,
                  contentPadding:  EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width:  44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSending
                    ? AppColors.textLight
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                  backgroundColor: AppColors.primary),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final TicketMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;
    final time   = _fmtTime(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Agent avatar
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: const Icon(Icons.support_agent_rounded,
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Label for agent
                if (!isUser)
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      'Support Agent',
                      style: TextStyle(
                          fontSize:   11,
                          color:      AppColors.textGrey,
                          fontWeight: FontWeight.w600),
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(18),
                      topRight:    const Radius.circular(18),
                      bottomLeft:  Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color:      Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset:     const Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                        fontSize: 14,
                        color:    isUser
                            ? Colors.white
                            : AppColors.textDark,
                        height: 1.4),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(
                      top: 3, left: 4, right: 4),
                  child: Text(
                    time,
                    style: const TextStyle(
                        fontSize: 10,
                        color:    AppColors.textLight),
                  ),
                ),
              ],
            ),
          ),

          // User avatar
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: const Icon(Icons.person_rounded,
                  size: 18, color: AppColors.primary),
            ),
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
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _label(),
            style: const TextStyle(
                fontSize:   11,
                color:      AppColors.textLight,
                fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
      ]),
    );
  }
}