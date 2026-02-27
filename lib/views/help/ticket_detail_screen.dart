// lib/views/help/ticket_detail_screen.dart

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/help_viewmodel.dart';
import '../../services/ticket_service.dart';
import 'ticket_chat_screen.dart';  // ← NEW

class TicketDetailScreen extends StatefulWidget {
  final HelpViewModel viewModel;
  final int ticketId;

  const TicketDetailScreen({
    super.key,
    required this.viewModel,
    required this.ticketId,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadTicketDetail(widget.ticketId);
  }

  String _fmt(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }

  // ── NEW: open chat screen ─────────────────────────────────────────────────
  void _openChat(SupportTicket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketChatScreen(
          ticketId:     ticket.id,
          ticketNumber: ticket.ticketNumber,
          subject:      ticket.subject,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Ticket Detail'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.loadingDetail) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          final ticket = widget.viewModel.selectedTicket;
          if (ticket == null) {
            return const Center(
              child: Text('Ticket not found',
                  style: TextStyle(color: AppColors.textLight)),
            );
          }

          // ── Ticket is active if NOT resolved/closed ───────────────────
          final chatActive = !ticket.isResolved;

          return Stack(                         // ← CHANGED: was just SingleChildScrollView
            children: [

              // ── Scrollable content (unchanged) ────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // extra bottom for FAB
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header card ──────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(ticket.subject,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark)),
                              ),
                              _StatusChip(status: ticket.status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _InfoRow(label: 'Ticket ID', value: ticket.ticketNumber),
                          const SizedBox(height: 6),
                          _InfoRow(label: 'Category',  value: ticket.category),
                          const SizedBox(height: 6),
                          _InfoRow(
                              label: 'Priority',
                              value: ticket.priority[0].toUpperCase() +
                                  ticket.priority.substring(1),
                              valueColor: _priorityColor(ticket.priority)),
                          const SizedBox(height: 6),
                          _InfoRow(
                              label: 'Submitted',
                              value: _fmt(ticket.createdAt)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Description ──────────────────────────────────────
                    _SectionCard(
                      title: 'Description',
                      child: Text(ticket.description,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textDark,
                              height: 1.5)),
                    ),

                    // ── Replies (historical) ──────────────────────────────
                    if (ticket.replies.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Conversation',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      const SizedBox(height: 12),
                      ...ticket.replies.map((r) => _ReplyBubble(
                        reply:   r,
                        fmtDate: _fmt,
                      )),
                    ],

                    const SizedBox(height: 8),

                    // ── Chat CTA card ─────────────────────────────────────
                    Container(
                      width:   double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:        AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: chatActive
                            ? Border.all(
                            color: AppColors.primary.withOpacity(0.25))
                            : null,
                      ),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: chatActive
                                ? AppColors.primary.withOpacity(0.10)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_rounded,
                            color: chatActive
                                ? AppColors.primary
                                : Colors.grey.shade400,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chatActive
                                    ? 'Live Chat with Support'
                                    : 'Chat Unavailable',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize:   14,
                                    color: chatActive
                                        ? AppColors.textDark
                                        : AppColors.textLight),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                chatActive
                                    ? 'Message our support team directly'
                                    : 'Ticket is ${ticket.status}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textGrey),
                              ),
                            ],
                          ),
                        ),
                        if (chatActive)
                          TextButton(
                            onPressed: () => _openChat(ticket),
                            child: const Text(
                              'Open',
                              style: TextStyle(
                                  color:      AppColors.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                      ]),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // ── Floating chat button (only when ticket is active) ──────
              if (chatActive)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  right:  20,
                  child: FloatingActionButton.extended(
                    onPressed:       () => _openChat(ticket),
                    backgroundColor: AppColors.primary,
                    icon: const Icon(Icons.chat_rounded,
                        color: Colors.white),
                    label: const Text(
                      'Chat',
                      style: TextStyle(
                          color:      Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'high': return Colors.red.shade600;
      case 'low':  return Colors.green.shade600;
      default:     return Colors.orange.shade700;
    }
  }
}

// ── Reply bubble (unchanged) ──────────────────────────────────────────────────

class _ReplyBubble extends StatelessWidget {
  final TicketReply reply;
  final String Function(DateTime) fmtDate;
  const _ReplyBubble({required this.reply, required this.fmtDate});

  @override
  Widget build(BuildContext context) {
    final isAdmin = reply.isAdmin;
    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isAdmin
              ? AppColors.cardBg
              : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(14),
            topRight:    const Radius.circular(14),
            bottomLeft:  Radius.circular(isAdmin ? 0 : 14),
            bottomRight: Radius.circular(isAdmin ? 14 : 0),
          ),
          border: isAdmin
              ? Border.all(color: AppColors.borderColor)
              : null,
        ),
        child: Column(
          crossAxisAlignment:
          isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              isAdmin ? 'Support Team' : 'You',
              style: TextStyle(
                  fontSize:   11,
                  fontWeight: FontWeight.w600,
                  color: isAdmin ? AppColors.textGrey : AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(reply.message,
                style: const TextStyle(
                    fontSize: 14,
                    color:    AppColors.textDark,
                    height:   1.4)),
            const SizedBox(height: 4),
            Text(fmtDate(reply.createdAt),
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets (unchanged) ────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    switch (status.toLowerCase()) {
      case 'in_progress':
      case 'in progress':
        bg = Colors.orange.shade50; fg = Colors.orange.shade700; label = 'In Progress';
        break;
      case 'resolved':
        bg = Colors.green.shade50;  fg = Colors.green.shade700;  label = 'Resolved';
        break;
      case 'closed':
        bg = Colors.grey.shade100;  fg = Colors.grey.shade600;   label = 'Closed';
        break;
      default:
        bg = Colors.blue.shade50;   fg = Colors.blue.shade700;   label = 'Open';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: const TextStyle(
              color: AppColors.textGrey, fontSize: 13)),
      Text(value,
          style: TextStyle(
              color:      valueColor ?? AppColors.textDark,
              fontSize:   13,
              fontWeight: FontWeight.w600)),
    ],
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.w700,
                color:      AppColors.textDark)),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}