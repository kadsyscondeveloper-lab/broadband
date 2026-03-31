// lib/views/installation/installation_tracker_screen.dart
//
// Can be pushed with an already-loaded request (right after address confirmation)
// OR loaded fresh from the API (from home screen shortcut).
//
// Usage:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => const InstallationTrackerScreen(),
//   ));

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/installation_viewmodel.dart';
import '../../services/installation_service.dart';

class InstallationTrackerScreen extends StatefulWidget {
  final InstallationRequest? initialRequest;
  final int?                 requestId;

  const InstallationTrackerScreen({
    super.key,
    this.initialRequest,
    this.requestId,
  });

  @override
  State<InstallationTrackerScreen> createState() =>
      _InstallationTrackerScreenState();
}

class _InstallationTrackerScreenState
    extends State<InstallationTrackerScreen> {
  final _vm = InstallationTrackerViewModel();

  @override
  void initState() {
    super.initState();
    if (widget.initialRequest != null) {
      _vm.setRequest(widget.initialRequest!);
    } else {
      _vm.load(requestId: widget.requestId);
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [

              // ── Header ─────────────────────────────────────────────────
              SliverAppBar(
                pinned:          true,
                expandedHeight:  140,
                backgroundColor: AppColors.primary,
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text('Installation Tracker',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 17)),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 22),
                    onPressed: () =>
                        _vm.load(requestId: widget.requestId),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    color: AppColors.primary,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            20, 60, 20, 16),
                        child: ListenableBuilder(
                          listenable: _vm,
                          builder: (_, __) {
                            final req = _vm.request;
                            if (req == null) {
                              return const SizedBox.shrink();
                            }
                            return Row(children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.build_rounded,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text: req.requestNumber));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text('Request ID copied'),
                                      duration: Duration(seconds: 1),
                                    ));
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(req.requestNumber,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight:
                                              FontWeight.w700)),
                                      const SizedBox(width: 4),
                                      Icon(Icons.copy_rounded,
                                          color: Colors.white
                                              .withOpacity(0.6),
                                          size: 12),
                                    ],
                                  ),
                                ),
                              ])),
                              // Status chip in header
                              _StatusChip(
                                status: req.status,
                                inHeader: true,
                              ),
                            ]);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Body ───────────────────────────────────────────────────
              if (_vm.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(
                      color: AppColors.primary)),
                )
              else if (_vm.error != null)
                SliverFillRemaining(child: _ErrorView(
                  message: _vm.error!,
                  onRetry: () => _vm.load(requestId: widget.requestId),
                ))
              else if (!_vm.hasRequest)
                const SliverFillRemaining(child: _NoRequestView())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _StatusTimeline(request: _vm.request!),
                      const SizedBox(height: 20),
                      if (_vm.request!.technician != null) ...[
                        _TechnicianCard(
                            technician: _vm.request!.technician!),
                        const SizedBox(height: 16),
                      ],
                      _AddressCard(request: _vm.request!),
                      const SizedBox(height: 16),
                      if (_vm.request!.scheduledAt != null) ...[
                        _ScheduledDateCard(
                            scheduledAt: _vm.request!.scheduledAt!),
                        const SizedBox(height: 16),
                      ],
                      if (_vm.request!.notes != null &&
                          _vm.request!.notes!.isNotEmpty) ...[
                        _NotesCard(notes: _vm.request!.notes!),
                        const SizedBox(height: 16),
                      ],
                      _InfoCard(),
                    ]),
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
// STATUS TIMELINE
// ─────────────────────────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final InstallationRequest request;
  const _StatusTimeline({required this.request});

  static const _steps = [
    (InstallationStatus.pending,    'Request\nSubmitted',  Icons.assignment_turned_in_rounded),
    (InstallationStatus.assigned,   'Agent\nAssigned',     Icons.person_pin_circle_rounded),
    (InstallationStatus.scheduled,  'Visit\nScheduled',    Icons.calendar_month_rounded),
    (InstallationStatus.inProgress, 'Installation\nStarted', Icons.construction_rounded),
    (InstallationStatus.completed,  'Connection\nActive',  Icons.wifi_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final currentStep = request.status == InstallationStatus.cancelled
        ? -1
        : request.status.stepIndex;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset:     const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color:        AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.timeline_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Installation Progress',
              style: TextStyle(fontWeight: FontWeight.w700,
                  fontSize: 15, color: AppColors.textDark)),
          const Spacer(),
          _StatusChip(status: request.status, inHeader: false),
        ]),
        const SizedBox(height: 24),

        if (request.status == InstallationStatus.cancelled) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: Colors.red.shade200),
            ),
            child: Row(children: [
              Icon(Icons.cancel_rounded,
                  color: Colors.red.shade600, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('This installation request has been cancelled.\nPlease contact support if you need help.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textGrey, height: 1.4)),
              ),
            ]),
          ),
        ] else ...[
          // Timeline steps
          ...List.generate(_steps.length, (i) {
            final (_, label, iconData) = _steps[i];
            final isDone   = i <= currentStep;
            final isActive = i == currentStep;
            final isLast   = i == _steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: dot + connector
                Column(children: [
                  Container(
                    width:  36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDone
                          ? (isActive ? AppColors.primary : Colors.green)
                          : Colors.grey.shade100,
                      shape:  BoxShape.circle,
                      border: isDone
                          ? null
                          : Border.all(color: Colors.grey.shade300, width: 1.5),
                    ),
                    child: Icon(
                      isActive
                          ? Icons.radio_button_checked_rounded
                          : isDone
                          ? Icons.check_rounded
                          : iconData,
                      color: isDone ? Colors.white : Colors.grey.shade400,
                      size:  18,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2, height: 36,
                      color: i < currentStep
                          ? Colors.green.shade300
                          : Colors.grey.shade200,
                    ),
                ]),
                const SizedBox(width: 14),

                // Right: label
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: isLast ? 0 : 20, top: 6),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                        label.replaceAll('\n', ' '),
                        style: TextStyle(
                          fontWeight: isActive
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: 14,
                          color: isDone
                              ? AppColors.textDark
                              : AppColors.textLight,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 4),
                        Text(
                          _activeSubtitle(request),
                          style: const TextStyle(
                              fontSize: 12,
                              color:    AppColors.primary,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ]),
                  ),
                ),
              ],
            );
          }),
        ],
      ]),
    );
  }

  String _activeSubtitle(InstallationRequest r) {
    switch (r.status) {
      case InstallationStatus.pending:
        return 'Waiting for agent assignment';
      case InstallationStatus.assigned:
        return r.technician != null
            ? '${r.technician!.name} will contact you'
            : 'Agent will contact you shortly';
      case InstallationStatus.scheduled:
        return r.scheduledAt != null
            ? 'Visit on ${_fmt(r.scheduledAt!)}'
            : 'Date to be confirmed';
      case InstallationStatus.inProgress:
        return 'Technician is currently on-site';
      case InstallationStatus.completed:
        return 'Your connection is active!';
      default:
        return '';
    }
  }

  String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month-1]}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TECHNICIAN CARD
// ─────────────────────────────────────────────────────────────────────────────

class _TechnicianCard extends StatelessWidget {
  final InstallationTechnician technician;
  const _TechnicianCard({required this.technician});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(children: [
        Container(
          width:  54,
          height: 54,
          decoration: BoxDecoration(
            color:  AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.support_agent_rounded,
              color: AppColors.primary, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('Assigned Technician',
              style: TextStyle(fontSize: 11,
                  color: AppColors.textGrey, fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(technician.name,
              style: const TextStyle(fontWeight: FontWeight.w800,
                  fontSize: 16, color: AppColors.textDark)),
          if (technician.employeeId != null) ...[
            const SizedBox(height: 2),
            Text('ID: ${technician.employeeId}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textGrey)),
          ],
        ])),
        if (technician.phone != null)
          GestureDetector(
            onTap: () {
              // Launch phone dialer
              // launchUrl(Uri(scheme: 'tel', path: technician.phone));
            },
            child: Container(
              width:  44,
              height: 44,
              decoration: BoxDecoration(
                color:        AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.call_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADDRESS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final InstallationRequest request;
  const _AddressCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return _InfoTile(
      icon:      Icons.location_on_rounded,
      iconColor: Colors.orange.shade600,
      iconBg:    Colors.orange.shade50,
      title:     'Installation Address',
      body:      request.fullAddress,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCHEDULED DATE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduledDateCard extends StatelessWidget {
  final DateTime scheduledAt;
  const _ScheduledDateCard({required this.scheduledAt});

  String _fmt(DateTime d) {
    const weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months   = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    final wd = weekdays[d.weekday - 1];
    final h  = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m  = d.minute.toString().padLeft(2, '0');
    final ap = d.hour < 12 ? 'AM' : 'PM';
    return '$wd, ${d.day} ${months[d.month-1]} ${d.year}  ·  $h:$m $ap';
  }

  @override
  Widget build(BuildContext context) {
    return _InfoTile(
      icon:      Icons.event_rounded,
      iconColor: Colors.blue.shade600,
      iconBg:    Colors.blue.shade50,
      title:     'Scheduled Visit',
      body:      _fmt(scheduledAt),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTES CARD
// ─────────────────────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return _InfoTile(
      icon:      Icons.note_rounded,
      iconColor: Colors.purple.shade600,
      iconBg:    Colors.purple.shade50,
      title:     'Notes for Technician',
      body:      notes,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO CARD  (help strip at bottom)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(
            color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded,
            color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Our technician will call you before arriving. If you need to reschedule or have questions, please contact our support team.',
            style: TextStyle(fontSize: 13,
                color: AppColors.textGrey, height: 1.5),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final Color    iconBg;
  final String   title;
  final String   body;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width:  40,
          height: 40,
          decoration: BoxDecoration(color: iconBg,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(title,
              style: const TextStyle(fontSize: 12,
                  color:      AppColors.textGrey,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
          const SizedBox(height: 5),
          Text(body,
              style: const TextStyle(fontSize: 14,
                  color: AppColors.textDark, height: 1.4)),
        ])),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final InstallationStatus status;
  final bool               inHeader;
  const _StatusChip({required this.status, required this.inHeader});

  _ChipStyle get _style {
    switch (status) {
      case InstallationStatus.completed:
        return _ChipStyle(
            bg:    inHeader ? Colors.white.withOpacity(0.2) : Colors.green.shade50,
            fg:    inHeader ? Colors.white : Colors.green.shade700,
            dot:   inHeader ? Colors.white : Colors.green.shade500);
      case InstallationStatus.inProgress:
        return _ChipStyle(
            bg:    inHeader ? Colors.white.withOpacity(0.2) : Colors.blue.shade50,
            fg:    inHeader ? Colors.white : Colors.blue.shade700,
            dot:   inHeader ? Colors.white : Colors.blue.shade400);
      case InstallationStatus.scheduled:
        return _ChipStyle(
            bg:    inHeader ? Colors.white.withOpacity(0.2) : const Color(0xFFEDF2FF),
            fg:    inHeader ? Colors.white : const Color(0xFF1A4BA0),
            dot:   inHeader ? Colors.white : const Color(0xFF378ADD));
      case InstallationStatus.assigned:
        return _ChipStyle(
            bg:    inHeader ? Colors.white.withOpacity(0.2) : Colors.purple.shade50,
            fg:    inHeader ? Colors.white : Colors.purple.shade700,
            dot:   inHeader ? Colors.white : Colors.purple.shade400);
      case InstallationStatus.cancelled:
        return _ChipStyle(
            bg:    inHeader ? Colors.white.withOpacity(0.2) : Colors.red.shade50,
            fg:    inHeader ? Colors.white : Colors.red.shade700,
            dot:   inHeader ? Colors.white : Colors.red.shade400);
      default: // pending
        return _ChipStyle(
            bg:    inHeader ? Colors.white.withOpacity(0.2) : Colors.orange.shade50,
            fg:    inHeader ? Colors.white : Colors.orange.shade700,
            dot:   inHeader ? Colors.white : Colors.orange.shade400);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        s.bg,
        borderRadius: BorderRadius.circular(20),
        border: inHeader
            ? Border.all(color: Colors.white.withOpacity(0.3))
            : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: s.dot, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(status.label,
            style: TextStyle(color: s.fg, fontSize: 11,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _ChipStyle {
  final Color bg, fg, dot;
  const _ChipStyle({required this.bg, required this.fg, required this.dot});
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY / ERROR STATES
// ─────────────────────────────────────────────────────────────────────────────

class _NoRequestView extends StatelessWidget {
  const _NoRequestView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width:  100,
            height: 100,
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.build_outlined,
                size: 50, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          const Text('No Active Installation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: 10),
          const Text(
            "You don't have any pending installation requests. Purchase a plan to get started.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.6),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Go Back',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
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
  }
}
