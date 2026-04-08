// lib/views/help/ticket_tracking_screen.dart
//
// Shows the live technician tracking screen for a support ticket.
// Opens from TicketDetailScreen when tech_job_status is 'assigned'.
//
// Required pubspec packages:
//   google_maps_flutter: ^2.6.0
//   socket_io_client:    ^2.0.3+1
//   url_launcher:        ^6.2.5   (for "Call" button)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../models/ticket_job_model.dart';
import '../../viewmodels/ticket_tracking_viewmodel.dart';

class TicketTrackingScreen extends StatefulWidget {
  final int    ticketId;
  final String subject;

  const TicketTrackingScreen({
    super.key,
    required this.ticketId,
    required this.subject,
  });

  @override
  State<TicketTrackingScreen> createState() => _TicketTrackingScreenState();
}

class _TicketTrackingScreenState extends State<TicketTrackingScreen> {
  final _vm = TicketTrackingViewModel();
  GoogleMapController? _mapCtrl;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onVmChange);
    _vm.load(widget.ticketId);
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChange);
    _vm.stopTracking(widget.ticketId);
    _vm.dispose();
    _mapCtrl?.dispose();
    super.dispose();
  }

  void _onVmChange() {
    // Animate camera to new location whenever socket pushes an update
    final loc = _vm.liveLocation;
    if (loc != null && _mapCtrl != null) {
      _mapCtrl!.animateCamera(
        CameraUpdate.newLatLng(LatLng(loc.lat, loc.lng)),
      );
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2,'0');
    final min = dt.minute.toString().padLeft(2,'0');
    return '${dt.day} ${m[dt.month-1]}, $h:$min';
  }

  String _ago(DateTime? dt) {
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60)  return 'Just now';
    if (d.inMinutes < 60)  return '${d.inMinutes}m ago';
    if (d.inHours   < 24)  return '${d.inHours}h ago';
    return _fmt(dt);
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            if (_vm.loading) return _buildLoading();
            if (_vm.error != null && _vm.jobStatus == null) return _buildError();
            final job = _vm.jobStatus;
            if (job == null || !job.requiresTechnician) return _buildNoJob();
            return _buildContent(job);
          },
        ),
      ),
    );
  }

  // ── Loading ──────────────────────────────────────────────────────────────

  Widget _buildLoading() => Scaffold(
    backgroundColor: AppColors.background,
    appBar: _appBar(),
    body: const Center(child: CircularProgressIndicator()),
  );

  Widget _buildError() => Scaffold(
    backgroundColor: AppColors.background,
    appBar: _appBar(),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(_vm.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _vm.load(widget.ticketId),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    ),
  );

  Widget _buildNoJob() => Scaffold(
    backgroundColor: AppColors.background,
    appBar: _appBar(),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.engineering_rounded, size: 56, color: AppColors.textLight),
          SizedBox(height: 12),
          Text('No technician has been assigned to this ticket yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey)),
        ]),
      ),
    ),
  );

  // ── Main content ─────────────────────────────────────────────────────────

  Widget _buildContent(TicketJobStatus job) {
    final loc  = _vm.bestLocation;
    final tech = job.technician;

    return CustomScrollView(
      slivers: [
        // ── AppBar ────────────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          expandedHeight: 56,
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Technician Tracking',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 16)),
              if (_vm.socketReady)
                Row(children: [
                  Container(width: 6, height: 6,
                      decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Live', style: TextStyle(
                      color: Colors.white70, fontSize: 11)),
                ]),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
              onPressed: () => _vm.refresh(widget.ticketId),
            ),
          ],
        ),

        // ── Live Map ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildMap(loc),
        ),

        // ── Status timeline ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildTimeline(job),
          ),
        ),

        // ── Technician card ───────────────────────────────────────────
        if (tech != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildTechCard(tech, loc),
            ),
          ),

        // ── Last update ───────────────────────────────────────────────
        if (loc != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.update_rounded, size: 14, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text('Location updated ${_ago(loc.updatedAt)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  // ── Map widget ───────────────────────────────────────────────────────────

  Widget _buildMap(TechnicianLocation? loc) {
    const defaultLat = 19.0760; // Mumbai fallback
    const defaultLng = 72.8777;

    final initLat = loc?.lat ?? defaultLat;
    final initLng = loc?.lng ?? defaultLng;

    return Container(
      height: 280,
      color: AppColors.borderColor,
      child: loc == null
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.location_searching_rounded,
                    size: 40, color: AppColors.textLight),
                const SizedBox(height: 8),
                const Text('Waiting for technician location…',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
              ]),
            )
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(initLat, initLng),
                zoom: 15,
              ),
              onMapCreated: (ctrl) => _mapCtrl = ctrl,
              markers: {
                Marker(
                  markerId: const MarkerId('technician'),
                  position: LatLng(initLat, initLng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                  infoWindow: const InfoWindow(title: 'Technician'),
                ),
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapType: MapType.normal,
            ),
    );
  }

  // ── Status timeline ──────────────────────────────────────────────────────

  Widget _buildTimeline(TicketJobStatus job) {
    final steps = [
      _TimelineStep(
        label:    'Job Created',
        sub:      _fmt(job.jobOpenedAt),
        done:     true,
        icon:     Icons.assignment_rounded,
      ),
      _TimelineStep(
        label:    'Technician Assigned',
        sub:      job.isAssigned || job.isCompleted
            ? _fmt(job.jobAssignedAt)
            : 'Waiting for technician…',
        done:     job.isAssigned || job.isCompleted,
        active:   job.isAssigned,
        icon:     Icons.engineering_rounded,
      ),
      _TimelineStep(
        label:    'Issue Resolved',
        sub:      job.isCompleted ? _fmt(job.jobCompletedAt) : 'Pending',
        done:     job.isCompleted,
        icon:     Icons.check_circle_rounded,
      ),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Job Status',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                  color: AppColors.textDark)),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((e) =>
              _buildTimelineRow(e.value, isLast: e.key == steps.length - 1)),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(_TimelineStep step, {required bool isLast}) {
    final color = step.done
        ? AppColors.primary
        : step.active
            ? AppColors.primary
            : AppColors.borderColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dot + line
        Column(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: step.done ? AppColors.primary : AppColors.background,
              border: Border.all(color: color, width: 2),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon,
                size: 16,
                color: step.done ? Colors.white : AppColors.textLight),
          ),
          if (!isLast)
            Container(
              width: 2, height: 36,
              color: step.done ? AppColors.primary : AppColors.borderColor,
            ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: step.done ? AppColors.textDark : AppColors.textGrey)),
                Text(step.sub,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textGrey)),
                if (!isLast) const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Technician card ──────────────────────────────────────────────────────

  Widget _buildTechCard(TechnicianInfo tech, TechnicianLocation? loc) {
    return _Card(
      child: Row(children: [
        // Avatar
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.engineering_rounded,
              color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tech.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14,
                      color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text('Field Technician',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textGrey)),
            ],
          ),
        ),
        // Action buttons
        if (tech.phone.isNotEmpty)
          _IconBtn(
            icon: Icons.phone_rounded,
            color: const Color(0xFF4CAF50),
            onTap: () => _call(tech.phone),
          ),
        if (loc != null) ...[
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.map_rounded,
            color: AppColors.primary,
            onTap: () => _openMaps(loc.lat, loc.lng),
          ),
        ],
      ]),
    );
  }

  // ── AppBar helper ─────────────────────────────────────────────────────────

  AppBar _appBar() => AppBar(
    backgroundColor: AppColors.primary,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded,
          color: Colors.white, size: 20),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text('Technician Tracking',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
  );
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.borderColor),
    ),
    padding: const EdgeInsets.all(16),
    child: child,
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    ),
  );
}

class _TimelineStep {
  final String   label;
  final String   sub;
  final bool     done;
  final bool     active;
  final IconData icon;

  const _TimelineStep({
    required this.label,
    required this.sub,
    this.done   = false,
    this.active = false,
    required this.icon,
  });
}
