// lib/views/help/ticket_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/help_viewmodel.dart';
import '../../services/ticket_service.dart';
import '../../services/ticket_job_service.dart';
import '../../models/ticket_job_model.dart';
import 'ticket_tracking_screen.dart';
import 'ticket_chat_screen.dart';

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
  TicketJobStatus? _jobStatus;
  bool _loadingJob = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadTicketDetail(widget.ticketId);
      _loadJobStatus();
    });
  }

  Future<void> _loadJobStatus() async {
    setState(() => _loadingJob = true);
    try {
      _jobStatus = await TicketJobService().getJobStatus(widget.ticketId);
    } catch (_) {}
    if (mounted) setState(() => _loadingJob = false);
  }

  String _fmt(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    return _fmt(dt);
  }

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


  void _openTracking(SupportTicket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketTrackingScreen(
          ticketId: ticket.id,
          subject:  ticket.subject,
        ),
      ),
    );
  }

  // ── Status ────────────────────────────────────────────────────────────────

  _StatusStyle _statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return _StatusStyle(
            bg: const Color(0xFFE9F7EF),
            fg: const Color(0xFF1E8449),
            dot: const Color(0xFF27AE60),
            label: 'Resolved');
      case 'closed':
        return _StatusStyle(
            bg: Colors.grey.shade100,
            fg: Colors.grey.shade600,
            dot: Colors.grey,
            label: 'Closed');
      case 'in_progress':
      case 'in progress':
        return _StatusStyle(
            bg: const Color(0xFFFEF3E7),
            fg: const Color(0xFFD35400),
            dot: const Color(0xFFE67E22),
            label: 'In Progress');
      case 'awaiting_user':
      case 'awaiting user':
        return _StatusStyle(
            bg: const Color(0xFFF5EEF8),
            fg: const Color(0xFF7D3C98),
            dot: const Color(0xFF8E44AD),
            label: 'Awaiting You');
      default:
        return _StatusStyle(
            bg: const Color(0xFFEAF4FC),
            fg: const Color(0xFF1A5276),
            dot: const Color(0xFF2980B9),
            label: 'Open');
    }
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high':   return Colors.red.shade600;
      case 'low':    return Colors.green.shade600;
      default:       return Colors.orange.shade700;
    }
  }

  // ── Category icon ─────────────────────────────────────────────────────────

  _CatStyle _catStyle(String category) {
    switch (category.toLowerCase()) {
      case 'billing':
        return _CatStyle(
            icon: PhosphorIcons.creditCard(PhosphorIconsStyle.fill),
            color: const Color(0xFF2ECC71),
            bg: const Color(0xFFE8F8F0));
      case 'technical issue':
      case 'technical':
        return _CatStyle(
            icon: PhosphorIcons.wrench(PhosphorIconsStyle.fill),
            color: const Color(0xFF3498DB),
            bg: const Color(0xFFEAF4FC));
      case 'connectivity':
        return _CatStyle(
            icon: PhosphorIcons.wifiHigh(PhosphorIconsStyle.fill),
            color: const Color(0xFF5B8FF9),
            bg: const Color(0xFFEDF2FF));
      case 'security':
        return _CatStyle(
            icon: PhosphorIcons.shieldWarning(PhosphorIconsStyle.fill),
            color: const Color(0xFFE67E22),
            bg: const Color(0xFFFEF3E7));
      case 'hardware':
        return _CatStyle(
            icon: PhosphorIcons.cpu(PhosphorIconsStyle.fill),
            color: const Color(0xFF9B59B6),
            bg: const Color(0xFFF5EEF8));
      case 'slow speed':
        return _CatStyle(
            icon: PhosphorIcons.gauge(PhosphorIconsStyle.fill),
            color: const Color(0xFFE74C3C),
            bg: const Color(0xFFFDEDEB));
      default:
        return _CatStyle(
            icon: PhosphorIcons.headset(PhosphorIconsStyle.fill),
            color: AppColors.primary,
            bg: AppColors.primary.withOpacity(0.10));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.loadingDetail) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final ticket = widget.viewModel.selectedTicket;
          if (ticket == null) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: AppColors.primary,
                title: const Text('Ticket Detail'),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: const Center(
                child: Text('Ticket not found',
                    style: TextStyle(color: AppColors.textLight)),
              ),
            );
          }

          final chatActive = !ticket.isResolved;
          final stat = _statusStyle(ticket.status);
          final cat  = _catStyle(ticket.category);

          return Scaffold(
            backgroundColor: AppColors.background,
            body: CustomScrollView(
              slivers: [

                // ── Fancy SliverAppBar ───────────────────────────────
                SliverAppBar(
                  pinned:            true,
                  expandedHeight:    160,
                  backgroundColor:   AppColors.primary,
                  automaticallyImplyLeading: false,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: const Text(
                    'Ticket Detail',
                    style: TextStyle(
                        color:      Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize:   17),
                  ),
                  centerTitle: true,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              20, 60, 20, 16),
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.end,
                            children: [
                              // Category icon
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.18),
                                  borderRadius:
                                  BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: PhosphorIcon(
                                    cat.icon,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ticket.subject,
                                      style: const TextStyle(
                                        color:      Colors.white,
                                        fontSize:   18,
                                        fontWeight: FontWeight.w800,
                                        height:     1.2,
                                      ),
                                      maxLines: 2,
                                      overflow:
                                      TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(
                                          ClipboardData(
                                              text: ticket
                                                  .ticketNumber),
                                        );
                                        ScaffoldMessenger.of(
                                            context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Ticket ID copied'),
                                            duration: Duration(
                                                seconds: 1),
                                          ),
                                        );
                                      },
                                      child: Row(
                                          mainAxisSize:
                                          MainAxisSize.min,
                                          children: [
                                            Text(
                                              ticket.ticketNumber,
                                              style: TextStyle(
                                                  color: Colors
                                                      .white
                                                      .withOpacity(
                                                      0.80),
                                                  fontSize: 12),
                                            ),
                                            const SizedBox(
                                                width: 4),
                                            Icon(
                                                Icons
                                                    .copy_rounded,
                                                color: Colors
                                                    .white
                                                    .withOpacity(
                                                    0.6),
                                                size: 12),
                                          ]),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Status chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.18),
                                  borderRadius:
                                  BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white
                                          .withOpacity(0.35)),
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width:  7, height: 7,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        stat.label,
                                        style: const TextStyle(
                                            color:      Colors.white,
                                            fontSize:   12,
                                            fontWeight:
                                            FontWeight.w700),
                                      ),
                                    ]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Body ────────────────────────────────────────────
                SliverPadding(
                  padding:
                  const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      // ── Meta info card ─────────────────────────────
                      _Card(
                        child: Column(children: [
                          _MetaRow(
                            icon: PhosphorIcons.tag(
                                PhosphorIconsStyle.fill),
                            iconColor: cat.color,
                            iconBg:    cat.bg,
                            label:     'Category',
                            value:     ticket.category,
                            valueColor: cat.color,
                            valueWeight: FontWeight.w700,
                          ),
                          _Divider(),
                          _MetaRow(
                            icon: PhosphorIcons.flag(
                                PhosphorIconsStyle.fill),
                            iconColor: _priorityColor(
                                ticket.priority),
                            iconBg: _priorityColor(ticket.priority)
                                .withOpacity(0.10),
                            label: 'Priority',
                            value: ticket.priority[0].toUpperCase() +
                                ticket.priority.substring(1),
                            valueColor:
                            _priorityColor(ticket.priority),
                            valueWeight: FontWeight.w700,
                          ),
                          _Divider(),
                          _MetaRow(
                            icon: PhosphorIcons.calendarBlank(
                                PhosphorIconsStyle.fill),
                            iconColor: AppColors.textGrey,
                            iconBg: Colors.grey.shade100,
                            label: 'Submitted',
                            value: _fmt(ticket.createdAt),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 14),

                      // ── Description ─────────────────────────────────
                      _Card(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              PhosphorIcon(
                                PhosphorIcons.textAlignLeft(
                                    PhosphorIconsStyle.fill),
                                color: AppColors.textGrey,
                                size:  16,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'DESCRIPTION',
                                style: TextStyle(
                                  fontSize:      11,
                                  fontWeight:    FontWeight.w700,
                                  color:         AppColors.textGrey,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            Text(
                              ticket.description,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color:    AppColors.textDark,
                                  height:   1.6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Conversation header ──────────────────────────
                      if (ticket.replies.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(
                              left: 4, bottom: 12),
                          child: Text(
                            'Conversation',
                            style: TextStyle(
                                fontSize:   17,
                                fontWeight: FontWeight.w800,
                                color:      AppColors.textDark),
                          ),
                        ),
                        ...ticket.replies.map(
                              (r) => _ReplyBubble(
                            reply:   r,
                            fmtDate: _fmt,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_loadingJob) ...[
                        const SizedBox(height: 8),
                        const Center(
                          child: SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ] else if (_jobStatus != null && _jobStatus!.requiresTechnician) ...[
                        // ── Technician info card ──────────────────────────
                        _Card(
                          child: Column(children: [
                            Row(children: [
                              Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.engineering_rounded,
                                    color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: 12),
                              const Text('TECHNICIAN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textGrey,
                                    letterSpacing: 0.8,
                                  )),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              const SizedBox(width: 46),
                              const Text('Status',
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.textGrey)),
                              const Spacer(),
                              _TechStatusChip(_jobStatus!.techJobStatus),
                            ]),
                            if (_jobStatus!.technician != null) ...[
                              const Padding(
                                padding: EdgeInsets.only(left: 46),
                                child: Divider(height: 18, color: Color(0xFFEEEEF4)),
                              ),
                              Row(children: [
                                const SizedBox(width: 46),
                                const Text('Assigned To',
                                    style: TextStyle(
                                        fontSize: 13, color: AppColors.textGrey)),
                                const Spacer(),
                                Text(_jobStatus!.technician!.name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark)),
                              ]),
                              if (_jobStatus!.technician!.phone.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.only(left: 46),
                                  child: Divider(height: 18, color: Color(0xFFEEEEF4)),
                                ),
                                Row(children: [
                                  const SizedBox(width: 46),
                                  const Text('Phone',
                                      style: TextStyle(
                                          fontSize: 13, color: AppColors.textGrey)),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () async {
                                      final uri = Uri.parse(
                                          'tel:\${_jobStatus!.technician!.phone}');
                                      if (await canLaunchUrl(uri)) launchUrl(uri);
                                    },
                                    child: Row(mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(_jobStatus!.technician!.phone,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.info)),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.phone_rounded,
                                              size: 14, color: AppColors.info),
                                        ]),
                                  ),
                                ]),
                              ],
                            ],
                          ]),
                        ),
                        const SizedBox(height: 12),
                        // ── Track button (only when actively assigned) ────
                        if (_jobStatus!.isAssigned)
                          GestureDetector(
                            onTap: () => _openTracking(ticket),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1565C0).withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.location_on_rounded,
                                      color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Track Technician',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15)),
                                      SizedBox(height: 2),
                                      Text('See live location on map',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('Track',
                                      style: TextStyle(
                                          color: Color(0xFF1565C0),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ),
                              ]),
                            ),
                          ),
                      ],

                      // ── Live chat CTA ────────────────────────────────
                      if (chatActive)
                        GestureDetector(
                          onTap: () => _openChat(ticket),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary
                                      .withOpacity(0.85),
                                ],
                                begin: Alignment.topLeft,
                                end:   Alignment.bottomRight,
                              ),
                              borderRadius:
                              BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(children: [
                              Container(
                                width:  44, height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.chat_rounded,
                                    color: Colors.white,
                                    size:  22),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Live Chat with Support',
                                      style: TextStyle(
                                          color:      Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize:   15),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Message our team directly',
                                      style: TextStyle(
                                          color:    Colors.white70,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                  BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Open',
                                  style: TextStyle(
                                      color:      AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize:   13),
                                ),
                              ),
                            ]),
                          ),
                        )
                      else
                      // Closed / resolved CTA
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.grey.shade200),
                          ),
                          child: Row(children: [
                            Container(
                              width:  44, height: 44,
                              decoration: BoxDecoration(
                                color:  Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.lock_outline_rounded,
                                  color: Colors.grey.shade400,
                                  size:  22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chat Unavailable',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ticket is ${ticket.status}',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: stat.bg,
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6, height: 6,
                                      decoration: BoxDecoration(
                                          color: stat.dot,
                                          shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(stat.label,
                                        style: TextStyle(
                                            color:      stat.fg,
                                            fontSize:   11,
                                            fontWeight:
                                            FontWeight.w700)),
                                  ]),
                            ),
                          ]),
                        ),
                    ]),
                  ),
                ),
              ],
            ),


          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// META ROW
// ─────────────────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final dynamic    icon;
  final Color      iconColor;
  final Color      iconBg;
  final String     label;
  final String     value;
  final Color?     valueColor;
  final FontWeight valueWeight;

  const _MetaRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color:        iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: PhosphorIcon(icon, color: iconColor, size: 17),
          ),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textGrey)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize:   13,
                fontWeight: valueWeight,
                color:      valueColor ?? AppColors.textDark)),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
      height: 1, color: Colors.grey.shade100, indent: 46);
}

// ─────────────────────────────────────────────────────────────────────────────
// REPLY BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class _ReplyBubble extends StatelessWidget {
  final TicketReply reply;
  final String Function(DateTime) fmtDate;
  const _ReplyBubble({required this.reply, required this.fmtDate});

  @override
  Widget build(BuildContext context) {
    final isAdmin = reply.isAdmin;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
        left:  isAdmin ? 0  : 48,
        right: isAdmin ? 48 : 0,
      ),
      child: Row(
        mainAxisAlignment:
        isAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAdmin) ...[
            Container(
              width: 30, height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color:  AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded,
                  size: 15, color: AppColors.primary),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isAdmin
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                if (isAdmin)
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 3),
                    child: Text('SUPPORT TEAM',
                        style: TextStyle(
                            fontSize:      9,
                            fontWeight:    FontWeight.w700,
                            color:         AppColors.textGrey,
                            letterSpacing: 0.5)),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(right: 4, bottom: 3),
                    child: Text('YOU',
                        style: TextStyle(
                            fontSize:      9,
                            fontWeight:    FontWeight.w700,
                            color:         AppColors.primary,
                            letterSpacing: 0.5)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? Colors.white
                        : AppColors.primary.withOpacity(0.09),
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(isAdmin ? 4 : 16),
                      bottomRight: Radius.circular(isAdmin ? 16 : 4),
                    ),
                    border: isAdmin
                        ? Border.all(color: Colors.grey.shade100)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color:      Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset:     const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(reply.message,
                      style: const TextStyle(
                          fontSize: 14,
                          color:    AppColors.textDark,
                          height:   1.45)),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 4, left: 4, right: 4),
                  child: Text(fmtDate(reply.createdAt),
                      style: TextStyle(
                          fontSize: 10,
                          color:    Colors.grey.shade500)),
                ),
              ],
            ),
          ),
          if (!isAdmin) ...[
            Container(
              width: 30, height: 30,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color:  AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  size: 15, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color:      Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset:     const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA CLASSES
// ─────────────────────────────────────────────────────────────────────────────

class _StatusStyle {
  final Color  bg, fg, dot;
  final String label;
  const _StatusStyle({
    required this.bg,
    required this.fg,
    required this.dot,
    required this.label,
  });
}

class _CatStyle {
  final dynamic icon;
  final Color   color;
  final Color   bg;
  const _CatStyle({
    required this.icon,
    required this.color,
    required this.bg,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// TECH STATUS CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _TechStatusChip extends StatelessWidget {
  final String? status;
  const _TechStatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    switch (status) {
      case 'assigned':
        bg = const Color(0xFFEAF4FC); fg = const Color(0xFF1A5276);
        label = 'Technician On The Way'; break;
      case 'open':
        bg = const Color(0xFFFEF3E7); fg = const Color(0xFFD35400);
        label = 'Finding Technician'; break;
      case 'completed':
        bg = const Color(0xFFE9F7EF); fg = const Color(0xFF1E8449);
        label = 'Completed'; break;
      default:
        bg = Colors.grey.shade100; fg = Colors.grey.shade600;
        label = status ?? 'Unknown';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}