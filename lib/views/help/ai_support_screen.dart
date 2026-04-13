// lib/views/help/ai_support_screen.dart

import 'package:flutter/material.dart';
import '../../services/ai_support_service.dart';
import '../../theme/app_theme.dart';
import 'ticket_chat_screen.dart';
import 'ticket_tracking_screen.dart';

class AiSupportScreen extends StatefulWidget {
  const AiSupportScreen({super.key});

  @override
  State<AiSupportScreen> createState() => _AiSupportScreenState();
}

class _AiSupportScreenState extends State<AiSupportScreen> {
  final _service    = AiSupportService();
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<AiMessage> _messages = [];
  int?              _sessionId;
  AiSessionStatus   _status    = AiSessionStatus.active;
  bool              _isLoading = true;  // initial session start
  bool              _isSending = false;
  String?           _error;

  // Escalation result
  int?    _ticketId;
  String? _ticketNumber;
  AiAction _lastAction = AiAction.none;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Session start ─────────────────────────────────────────────────────────

  Future<void> _startSession() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _service.startSession();
      if (!mounted) return;
      setState(() {
        _sessionId = result.sessionId;
        _messages.add(AiMessage.local(role: 'assistant', content: result.greeting));
        _isLoading = false;
      });
      _scrollToBottom(jump: true);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ── Send message ──────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending || _status != AiSessionStatus.active) return;

    setState(() {
      _isSending = true;
      _messages.add(AiMessage.local(role: 'user', content: text));
    });
    _controller.clear();
    _scrollToBottom();

    // Typing indicator
    final typingId = UniqueKey();
    setState(() => _messages.add(_TypingMessage()));
    _scrollToBottom();

    try {
      final result = await _service.sendMessage(_sessionId!, text);
      if (!mounted) return;

      setState(() {
        // Remove typing indicator
        _messages.removeWhere((m) => m is _TypingMessage);
        _messages.add(AiMessage.local(role: 'assistant', content: result.reply));
        _status      = result.sessionStatus;
        _isSending   = false;
        _lastAction  = result.action;
        if (result.ticketId != null) {
          _ticketId     = result.ticketId;
          _ticketNumber = result.ticketNumber;
        }
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m is _TypingMessage);
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text('Failed to send: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _openTicketChat() {
    if (_ticketId == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TicketChatScreen(
        ticketId:     _ticketId!,
        ticketNumber: _ticketNumber ?? '',
        subject:      'Support Ticket',
      ),
    ));
  }

  void _openTracking() {
    if (_ticketId == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TicketTrackingScreen(
        ticketId: _ticketId!,
        subject:  'Technician Visit',
      ),
    ));
  }

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

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
          ? _buildError()
          : Column(children: [
        Expanded(child: _buildMessageList()),
        if (_status != AiSessionStatus.active) _buildEscalationBanner(),
        _buildInputBar(),
      ]),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: AppColors.primary,
    elevation:       0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded,
          color: Colors.white, size: 20),
      onPressed: () => Navigator.pop(context),
    ),
    title: Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color:  Colors.white.withOpacity(0.20),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text('⚡', style: TextStyle(fontSize: 16)),
        ),
      ),
      const SizedBox(width: 10),
    Expanded(

      child : const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Speedo AI',
              style: TextStyle(
                  color:      Colors.white,
                  fontSize:   15,
                  fontWeight: FontWeight.w700)),
          Text('Speedonet Support Assistant',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    ),
    ]),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 14),
        child: _StatusPill(status: _status),
      ),
    ],
  );

  // ── Message list ──────────────────────────────────────────────────────────

  Widget _buildMessageList() => ListView.builder(
    controller:  _scrollCtrl,
    padding:     const EdgeInsets.fromLTRB(16, 16, 16, 8),
    itemCount:   _messages.length,
    itemBuilder: (_, i) {
      final msg = _messages[i];
      if (msg is _TypingMessage) return const _TypingBubble();
      final prev = i > 0 ? _messages[i - 1] : null;
      final next = i < _messages.length - 1 ? _messages[i + 1] : null;

      final showDate = prev == null ||
          !_sameDay(prev.createdAt, msg.createdAt);
      final isLastInGroup = next == null || next.role != msg.role ||
          (next is! _TypingMessage && !_sameDay(next.createdAt, msg.createdAt));

      return Column(children: [
        if (showDate) _DateDivider(date: msg.createdAt),
        _AiBubble(
          message:       msg,
          isLastInGroup: isLastInGroup,
        ),
      ]);
    },
  );

  // ── Escalation banner ─────────────────────────────────────────────────────

  Widget _buildEscalationBanner() {
    if (_lastAction == AiAction.resolved) {
      return _EscalationBanner(
        icon:        Icons.check_circle_rounded,
        color:       Colors.green.shade600,
        bg:          Colors.green.shade50,
        title:       'Issue resolved!',
        subtitle:    'Session closed. Feel free to start a new one anytime.',
        buttonLabel: null,
        onTap:       null,
      );
    }
    if (_lastAction == AiAction.technicianDispatched) {
      return _EscalationBanner(
        icon:        Icons.engineering_rounded,
        color:       const Color(0xFF1565C0),
        bg:          const Color(0xFFE3F0FF),
        title:       'Technician dispatched · $_ticketNumber',
        subtitle:    'A field technician will be assigned shortly.',
        buttonLabel: 'Track technician',
        onTap:       _openTracking,
      );
    }
    // ticket_created
    return _EscalationBanner(
      icon:        Icons.support_agent_rounded,
      color:       AppColors.primary,
      bg:          AppColors.primary.withOpacity(0.08),
      title:       'Ticket created · $_ticketNumber',
      subtitle:    'Our support team will follow up soon.',
      buttonLabel: 'Open ticket chat',
      onTap:       _openTicketChat,
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isActive  = _status == AiSessionStatus.active;

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
                enabled:            isActive,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText:  isActive ? 'Type a message...' : 'Session ended',
                  hintStyle: const TextStyle(
                      color: AppColors.textLight, fontSize: 15),
                  border:         InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          GestureDetector(
            onTap: (isActive && !_isSending) ? _sendMessage : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width:  50, height: 50,
              margin: const EdgeInsets.only(left: 10, bottom: 1),
              decoration: BoxDecoration(
                color: (!isActive || _isSending)
                    ? AppColors.primary.withOpacity(0.4)
                    : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [BoxShadow(
                  color:      AppColors.primary.withOpacity(0.35),
                  blurRadius: 10,
                  offset:     const Offset(0, 4),
                )]
                    : [],
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

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded,
            size: 48, color: AppColors.textLight),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _startSession,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          child: const Text('Retry', style: TextStyle(color: Colors.white)),
        ),
      ]),
    ),
  );

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERNAL MODELS
// ─────────────────────────────────────────────────────────────────────────────

// Sentinel used as a typing indicator placeholder
class _TypingMessage extends AiMessage {
  _TypingMessage()
      : super(role: 'assistant', content: '...', createdAt: DateTime.now());
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class _AiBubble extends StatelessWidget {
  final AiMessage message;
  final bool      isLastInGroup;

  const _AiBubble({required this.message, required this.isLastInGroup});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final h = message.createdAt.hour, m = message.createdAt.minute;
    final time =
        '${h % 12 == 0 ? 12 : h % 12}:${m.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';

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
          if (!isUser) ...[
            if (isLastInGroup)
              Container(
                width: 30, height: 30,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('⚡', style: TextStyle(fontSize: 14)),
                ),
              )
            else
              const SizedBox(width: 38),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (isLastInGroup)
                  Padding(
                    padding: EdgeInsets.only(
                        left: isUser ? 0 : 4,
                        right: isUser ? 4 : 0,
                        bottom: 3),
                    child: Text(
                      isUser ? 'YOU' : 'SPEEDO AI',
                      style: TextStyle(
                          fontSize:      9,
                          fontWeight:    FontWeight.w700,
                          color:         isUser
                              ? AppColors.primary
                              : AppColors.textGrey,
                          letterSpacing: 0.5),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(18),
                      topRight:    const Radius.circular(18),
                      bottomLeft:  Radius.circular(
                          !isUser && isLastInGroup ? 4 : 18),
                      bottomRight: Radius.circular(
                          isUser  && isLastInGroup ? 4 : 18),
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
                    message.content,
                    style: TextStyle(
                        fontSize: 14,
                        height:   1.5,
                        color:    isUser
                            ? Colors.white
                            : AppColors.textDark),
                  ),
                ),
                if (isLastInGroup)
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 4, left: 4, right: 4),
                    child: Text(time,
                        style: TextStyle(
                            fontSize: 10,
                            color:    Colors.grey.shade500)),
                  ),
              ],
            ),
          ),

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
          ] else if (isUser) ...[
            const SizedBox(width: 38),
          ],
        ],
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 3, right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft:     Radius.circular(18),
            topRight:    Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft:  Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i / 3;
                final t     = ((_ctrl.value - delay) % 1.0 + 1.0) % 1.0;
                final op    = 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                return Container(
                  width:  7, height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(op),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ESCALATION BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _EscalationBanner extends StatelessWidget {
  final IconData  icon;
  final Color     color;
  final Color     bg;
  final String    title;
  final String    subtitle;
  final String?   buttonLabel;
  final VoidCallback? onTap;

  const _EscalationBanner({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color:  color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize:   13,
                      color:      color)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textGrey)),
            ],
          ),
        ),
        if (buttonLabel != null)
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:        color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                buttonLabel!,
                style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS PILL
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final AiSessionStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, dotColor) = switch (status) {
      AiSessionStatus.resolved  => ('Resolved', Colors.green.shade300),
      AiSessionStatus.escalated => ('Escalated', Colors.orange.shade300),
      _                         => ('Live', Colors.greenAccent.shade400),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color:      Colors.white,
                fontSize:   11,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATE DIVIDER (reused pattern from ticket_chat_screen)
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
    const months = ['','Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
        Container(
          margin:  const EdgeInsets.symmetric(horizontal: 10),
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
          child: Text(_label(),
              style: const TextStyle(
                  fontSize:   11,
                  color:      AppColors.textGrey,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
      ]),
    );
  }
}
