// lib/views/help/help_screen.dart

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/help_viewmodel.dart';
import '../../services/ticket_service.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';

class HelpScreen extends StatefulWidget {
  final HelpViewModel viewModel;
  const HelpScreen({super.key, required this.viewModel});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String _filter       = 'All';
  String _searchQuery  = '';
  bool   _showSearch   = false;
  final  _searchCtrl   = TextEditingController();

  static const _filters = ['All', 'Open', 'In Progress', 'Resolved', 'Closed'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadTickets();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCreateTicket() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTicketScreen(viewModel: widget.viewModel),
      ),
    );
    if (mounted) widget.viewModel.loadTickets();
  }

  List<SupportTicket> _filtered(List<SupportTicket> all) {
    var list = all;

    // Filter by status tab
    if (_filter != 'All') {
      list = list.where((t) {
        final s = t.status.toLowerCase();
        switch (_filter) {
          case 'Open':        return s == 'open';
          case 'In Progress': return s == 'in_progress' || s == 'in progress';
          case 'Resolved':    return s == 'resolved';
          case 'Closed':      return s == 'closed';
          default:            return true;
        }
      }).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) =>
      t.subject.toLowerCase().contains(q)      ||
          t.category.toLowerCase().contains(q)     ||
          t.ticketNumber.toLowerCase().contains(q)
      ).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm       = widget.viewModel;
          final filtered = _filtered(vm.tickets);

          return CustomScrollView(
            slivers: [

              // ── Header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.only(
                    top:    MediaQuery.of(context).padding.top + 12,
                    left:   20,
                    right:  20,
                    bottom: 20,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft:  Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title row ──────────────────────────────────────
                      Row(children: [
                        if (canPop)
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        const Expanded(
                          child: Text(
                            'Support Tickets',
                            style: TextStyle(
                              color:      Colors.white,
                              fontSize:   22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        // Search toggle
                        GestureDetector(
                          onTap: () => setState(() {
                            _showSearch = !_showSearch;
                            if (!_showSearch) {
                              _searchQuery = '';
                              _searchCtrl.clear();
                            }
                          }),
                          child: Container(
                            width: 38, height: 38,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color:  Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _showSearch
                                  ? Icons.close_rounded
                                  : Icons.search_rounded,
                              color: Colors.white, size: 20,
                            ),
                          ),
                        ),
                        // New ticket button
                        GestureDetector(
                          onTap: _openCreateTicket,
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color:  Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ]),

                      // ── Search bar (animated) ──────────────────────────
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        child: _showSearch
                            ? Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller:         _searchCtrl,
                              autofocus:          true,
                              style:              const TextStyle(
                                  color: AppColors.textDark, fontSize: 14),
                              decoration: InputDecoration(
                                hintText:      'Search tickets...',
                                hintStyle:     const TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 14),
                                prefixIcon:    const Icon(Icons.search_rounded,
                                    color: AppColors.textGrey,
                                    size: 18),
                                border:        InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 11),
                              ),
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                            ),
                          ),
                        )
                            : const SizedBox.shrink(),
                      ),

                      // ── Filter chips ───────────────────────────────────
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final f        = _filters[i];
                            final isActive = f == _filter;
                            return GestureDetector(
                              onTap: () => setState(() => _filter = f),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    color: isActive
                                        ? AppColors.primary
                                        : Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Loading ──────────────────────────────────────────────────
              if (vm.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )

              // ── Error ────────────────────────────────────────────────────
              else if (vm.listError != null)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/no_ticket.png',
                              width: 150, height: 150, fit: BoxFit.contain),
                          const SizedBox(height: 20),
                          Text(vm.listError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.textLight)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: vm.loadTickets,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: const Text('Retry',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                )

              // ── Empty ────────────────────────────────────────────────────
              else if (vm.tickets.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyTickets(onCreateTap: _openCreateTicket),
                  )

                // ── No results for filter/search ──────────────────────────
                else if (filtered.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/no_tickets_filter.png',
                              width:  200,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No tickets match "$_filter"',
                              style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    )

                  // ── Ticket list ──────────────────────────────────────────────
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _TicketCard(
                              ticket: filtered[i],
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TicketDetailScreen(
                                      viewModel: vm,
                                      ticketId:  filtered[i].id,
                                    ),
                                  ),
                                );
                                if (context.mounted) vm.loadTickets();
                              },
                            ),
                          ),
                          childCount: filtered.length,
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

// ─────────────────────────────────────────────────────────────────────────────
// TICKET CARD  — redesigned
// ─────────────────────────────────────────────────────────────────────────────

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback  onTap;
  const _TicketCard({required this.ticket, required this.onTap});

  // ── Category icon + bg color ─────────────────────────────────────────────
  _CategoryStyle get _catStyle {
    switch (ticket.category.toLowerCase()) {
      case 'billing':
        return _CategoryStyle(
          icon:  PhosphorIcons.creditCard(PhosphorIconsStyle.fill),
          color: const Color(0xFF2ECC71),
          bg:    const Color(0xFFE8F8F0),
        );
      case 'technical issue':
      case 'technical':
        return _CategoryStyle(
          icon:  PhosphorIcons.wrench(PhosphorIconsStyle.fill),
          color: const Color(0xFF3498DB),
          bg:    const Color(0xFFEAF4FC),
        );
      case 'connectivity':
        return _CategoryStyle(
          icon:  PhosphorIcons.wifiHigh(PhosphorIconsStyle.fill),
          color: const Color(0xFF5B8FF9),
          bg:    const Color(0xFFEDF2FF),
        );
      case 'security':
        return _CategoryStyle(
          icon:  PhosphorIcons.shieldWarning(PhosphorIconsStyle.fill),
          color: const Color(0xFFE67E22),
          bg:    const Color(0xFFFEF3E7),
        );
      case 'hardware':
        return _CategoryStyle(
          icon:  PhosphorIcons.cpu(PhosphorIconsStyle.fill),
          color: const Color(0xFF9B59B6),
          bg:    const Color(0xFFF5EEF8),
        );
      case 'new connection':
        return _CategoryStyle(
          icon:  PhosphorIcons.plugsConnected(PhosphorIconsStyle.fill),
          color: const Color(0xFF1ABC9C),
          bg:    const Color(0xFFE8F8F5),
        );
      case 'slow speed':
        return _CategoryStyle(
          icon:  PhosphorIcons.gauge(PhosphorIconsStyle.fill),
          color: const Color(0xFFE74C3C),
          bg:    const Color(0xFFFDEDEB),
        );
      default:
        return _CategoryStyle(
          icon:  PhosphorIcons.headset(PhosphorIconsStyle.fill),
          color: AppColors.primary,
          bg:    AppColors.primary.withOpacity(0.10),
        );
    }
  }

  // ── Status style ─────────────────────────────────────────────────────────
  _StatusStyle get _statStyle {
    switch (ticket.status.toLowerCase()) {
      case 'resolved':
        return _StatusStyle(
            dot: const Color(0xFF27AE60),
            bg:  const Color(0xFFE9F7EF),
            fg:  const Color(0xFF1E8449),
            label: 'Resolved');
      case 'closed':
        return _StatusStyle(
            dot: Colors.grey,
            bg:  Colors.grey.shade100,
            fg:  Colors.grey.shade600,
            label: 'Closed');
      case 'in_progress':
      case 'in progress':
        return _StatusStyle(
            dot: const Color(0xFFE67E22),
            bg:  const Color(0xFFFEF3E7),
            fg:  const Color(0xFFD35400),
            label: 'In Progress');
      case 'awaiting_user':
      case 'awaiting user':
        return _StatusStyle(
            dot: const Color(0xFF8E44AD),
            bg:  const Color(0xFFF5EEF8),
            fg:  const Color(0xFF7D3C98),
            label: 'Awaiting You');
      default:
        return _StatusStyle(
            dot: const Color(0xFF2980B9),
            bg:  const Color(0xFFEAF4FC),
            fg:  const Color(0xFF1A5276),
            label: 'Open');
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final cat  = _catStyle;
    final stat = _statStyle;

    return GestureDetector(
      onTap:    onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Category icon ──────────────────────────────────────────────
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color:        cat.bg,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: PhosphorIcon(cat.icon, color: cat.color, size: 26),
              ),
            ),
            const SizedBox(width: 12),

            // ── Content ────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Subject + chevron
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          ticket.subject,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize:   15,
                            color:      AppColors.textDark,
                            height:     1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: AppColors.textLight),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Category • Ticket number
                  Row(children: [
                    Text(
                      ticket.category.toUpperCase(),
                      style: TextStyle(
                        fontSize:      10,
                        fontWeight:    FontWeight.w700,
                        color:         cat.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 3, height: 3,
                        decoration: BoxDecoration(
                          color:  Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        ticket.ticketNumber,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textGrey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // Status chip + time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dot + label chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:        stat.bg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color:  stat.dot,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            stat.label,
                            style: TextStyle(
                              color:      stat.fg,
                              fontSize:   11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ]),
                      ),

                      // Time ago
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.access_time_rounded,
                            size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(
                          _timeAgo(ticket.createdAt),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA CLASSES
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryStyle {
  final dynamic icon;
  final Color   color;
  final Color   bg;
  const _CategoryStyle({
    required this.icon,
    required this.color,
    required this.bg,
  });
}

class _StatusStyle {
  final Color  dot;
  final Color  bg;
  final Color  fg;
  final String label;
  const _StatusStyle({
    required this.dot,
    required this.bg,
    required this.fg,
    required this.label,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyTickets extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyTickets({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/no_ticket.png',
                width: 160, height: 160, fit: BoxFit.contain),
            const SizedBox(height: 24),
            const Text(
              'No Support Tickets',
              style: TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.w700,
                  color:      AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              "You don't have any open support\nrequests right now.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textGrey, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCreateTap,
                icon:  const Icon(Icons.add_rounded,
                    color: Colors.white, size: 20),
                label: const Text('New Ticket',
                    style: TextStyle(
                        color:      Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize:   15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}