// lib/views/help/ticket_tracking_screen.dart
//
// Live technician tracking screen for a support ticket — USER APP.
// Uses the same open-source stack as the technician's job_route_map.dart:
//
//   Tiles:     OpenStreetMap  (no key)
//   Routing:   OSRM public    (no key)
//   GPS:       geolocator     (already a dependency)
//
// pubspec.yaml — make sure these are present:
//   flutter_map: ^7.0.2
//   latlong2:    ^0.9.1
//   http:        ^1.2.1
//   geolocator:  ^12.0.0
//   url_launcher: ^6.2.5

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
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
  final _vm      = TicketTrackingViewModel();
  final _mapCtrl = MapController();

  // Map state
  LatLng?      _myLocation;
  List<LatLng> _routePoints = [];
  String?      _distance;
  String?      _duration;
  bool         _loadingRoute = false;
  bool         _mapReady     = false;

  // Avoid re-fetching route if tech location hasn't changed meaningfully
  LatLng? _lastRoutedTechLoc;

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
    super.dispose();
  }


  Future<void> _geocodeJobAddress(String address) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(address)}&format=json&limit=1',
      );

      final res = await http.get(uri, headers: {
        'User-Agent': 'com.yourapp.app',
      });

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;

        if (list.isNotEmpty) {
          final lat = double.tryParse(list[0]['lat']);
          final lng = double.tryParse(list[0]['lon']);

          if (lat != null && lng != null && mounted) {
            setState(() {
              _myLocation = LatLng(lat, lng);
            });

            _maybeRefreshRoute();
          }
        }
      }
    } catch (e) {
      print("Geocode error: $e");
    }
  }


  // ── ViewModel listener ────────────────────────────────────────────────────

  void _onVmChange() {
    final job = _vm.jobStatus;

    // ✅ SET JOB LOCATION (BLUE DOT)
    if (_myLocation == null) {
      final addr = job?.customerAddress;
      if (addr != null) {
        _geocodeJobAddress(addr);
      }
    }

    // existing technician logic
    final loc = _vm.liveLocation;
    if (loc == null) return;

    final techLatLng = LatLng(loc.lat, loc.lng);

    if (_mapReady) {
      _mapCtrl.move(techLatLng, _mapCtrl.camera.zoom);
    }

    final prev = _lastRoutedTechLoc;
    if (prev == null ||
        const Distance().as(LengthUnit.Meter, prev, techLatLng) > 50) {
      _maybeRefreshRoute();
    }
  }

  // ── OSRM route ────────────────────────────────────────────────────────────

  Future<void> _maybeRefreshRoute() async {
    final techLoc = _vm.liveLocation;
    if (techLoc == null || _myLocation == null) return;

    final from = LatLng(techLoc.lat, techLoc.lng);
    final to   = _myLocation!;

    if (_loadingRoute) return;
    setState(() => _loadingRoute = true);

    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );

      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data   = jsonDecode(res.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>;

        if (routes.isNotEmpty) {
          final route  = routes[0] as Map<String, dynamic>;
          final coords = route['geometry']['coordinates'] as List<dynamic>;
          final dist   = (route['distance'] as num).toDouble();
          final dur    = (route['duration'] as num).toDouble();

          final points = coords
              .map((c) => LatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  ))
              .toList();

          // Fit bounds to show the full route
          if (points.isNotEmpty && _mapReady) {
            final bounds = LatLngBounds.fromPoints(points);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _mapCtrl.fitCamera(CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(52),
                ));
              }
            });
          }

          final mins = (dur / 60).ceil();

          if (mounted) {
            setState(() {
              _routePoints    = points;
              _distance       = dist < 1000
                  ? '${dist.toStringAsFixed(0)} m'
                  : '${(dist / 1000).toStringAsFixed(1)} km';
              _duration       = mins < 60
                  ? '$mins min'
                  : '${(mins / 60).floor()}h ${mins % 60}m';
              _lastRoutedTechLoc = from;
            });
          }
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _loadingRoute = false);
  }

  // ── External navigation ───────────────────────────────────────────────────

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final h   = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${m[dt.month - 1]}, $h:$min';
  }

  String _ago(DateTime? dt) {
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours   < 24) return '${d.inHours}h ago';
    return _fmt(dt);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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

  // ── States ────────────────────────────────────────────────────────────────

  Widget _buildLoading() => Scaffold(
    backgroundColor: AppColors.background,
    appBar: _simpleAppBar(),
    body: const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    ),
  );

  Widget _buildError() => Scaffold(
    backgroundColor: AppColors.background,
    appBar: _simpleAppBar(),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(_vm.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _vm.load(widget.ticketId),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Retry',
                style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    ),
  );

  Widget _buildNoJob() => Scaffold(
    backgroundColor: AppColors.background,
    appBar: _simpleAppBar(),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.engineering_rounded,
              size: 56, color: AppColors.textLight),
          SizedBox(height: 12),
          Text('No technician has been assigned yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey)),
        ]),
      ),
    ),
  );

  // ── Main content ──────────────────────────────────────────────────────────

  Widget _buildContent(TicketJobStatus job) {
    final loc  = _vm.bestLocation;
    final tech = job.technician;

    return CustomScrollView(
      slivers: [

        // ── AppBar ────────────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
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
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              if (_vm.socketReady)
                Row(children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  const Text('Live',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 11)),
                ]),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 22),
              onPressed: () => _vm.refresh(widget.ticketId),
            ),
          ],
        ),

        // ── Map ───────────────────────────────────────────────────────
        SliverToBoxAdapter(child: _buildMap(loc)),

        // ── Timeline ──────────────────────────────────────────────────
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

        // ── Last update timestamp ─────────────────────────────────────
        if (loc != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.update_rounded,
                      size: 14, color: AppColors.textLight),
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

  // ── Map widget ────────────────────────────────────────────────────────────

  Widget _buildMap(TechnicianLocation? loc) {
    // Default centre: Mumbai; will fit to route once data arrives
    const defaultCenter = LatLng(19.0760, 72.8777);

    final techLatLng = loc != null ? LatLng(loc.lat, loc.lng) : null;

    // Show placeholder when we don't have the tech's location yet
    if (techLatLng == null) {
      return Container(
        height: 280,
        decoration: const BoxDecoration(color: AppColors.background),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            const Text('Waiting for technician location…',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textGrey)),
          ]),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: Stack(
        children: [

          // ── flutter_map ──────────────────────────────────────────────
          SizedBox(
            height: 280,
            child: FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: techLatLng,
                initialZoom:   14,
                onMapReady: () => setState(() => _mapReady = true),
              ),
              children: [

                // OpenStreetMap tiles
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.yourapp.user',
                  maxZoom: 19,
                ),

                // Route polyline
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points:           _routePoints,
                        color:            AppColors.primary,
                        strokeWidth:      5,
                        borderColor:      Colors.white,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),

                // Markers
                MarkerLayer(
                  markers: [

                    // ── Technician pin ─────────────────────────────────
                    Marker(
                      point:  techLatLng,
                      width:  48,
                      height: 56,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withOpacity(0.45),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                                Icons.engineering_rounded,
                                color: Colors.white,
                                size: 16),
                          ),
                          CustomPaint(
                            size: const Size(12, 8),
                            painter:
                                _TrianglePainter(AppColors.primary),
                          ),
                        ],
                      ),
                    ),

                    // ── My location dot ────────────────────────────────
                    if (_myLocation != null)
                      Marker(
                        point:  _myLocation!,
                        width:  22,
                        height: 22,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF007AFF)
                                    .withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Distance / ETA strip ─────────────────────────────────────
          if (_distance != null)
            Positioned(
              top: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.route_rounded,
                      size: 15, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    '$_distance  ·  $_duration',
                    style: const TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                      color:      AppColors.textDark,
                    ),
                  ),
                ]),
              ),
            ),

          // ── Route loading spinner ────────────────────────────────────
          if (_loadingRoute)
            Positioned(
              top: 12, right: 12,
              child: Container(
                width: 32, height: 32,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            ),

          // ── Open in Google Maps button ───────────────────────────────
          Positioned(
            bottom: 12, right: 12,
            child: GestureDetector(
              onTap: () => _openMaps(techLatLng.latitude,
                  techLatLng.longitude),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new_rounded,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 5),
                      Text('Navigate',
                          style: TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w700,
                            color:      AppColors.primary,
                          )),
                    ]),
              ),
            ),
          ),

          // ── Legend ──────────────────────────────────────────────────
          Positioned(
            bottom: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendDot(
                      color: AppColors.primary,
                      label: 'Technician'),
                  const SizedBox(height: 4),
                  if (_myLocation != null)
                    _LegendDot(
                        color: const Color(0xFF007AFF),
                        label: 'You'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Timeline ──────────────────────────────────────────────────────────────

  Widget _buildTimeline(TicketJobStatus job) {
    final steps = [
      _TimelineStep(
        label:  'Job Created',
        sub:    _fmt(job.jobOpenedAt),
        done:   true,
        icon:   Icons.assignment_rounded,
      ),
      _TimelineStep(
        label:  'Technician Assigned',
        sub:    job.isAssigned || job.isCompleted
            ? _fmt(job.jobAssignedAt)
            : 'Waiting for technician…',
        done:   job.isAssigned || job.isCompleted,
        active: job.isAssigned,
        icon:   Icons.engineering_rounded,
      ),
      _TimelineStep(
        label:  'Issue Resolved',
        sub:    job.isCompleted ? _fmt(job.jobCompletedAt) : 'Pending',
        done:   job.isCompleted,
        icon:   Icons.check_circle_rounded,
      ),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Job Status',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize:   15,
                  color:      AppColors.textDark)),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map(
                (e) => _buildTimelineRow(e.value,
                    isLast: e.key == steps.length - 1),
              ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(_TimelineStep step, {required bool isLast}) {
    final color = (step.done || step.active)
        ? AppColors.primary
        : AppColors.borderColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color:  step.done
                  ? AppColors.primary
                  : AppColors.background,
              border: Border.all(color: color, width: 2),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon,
                size:  16,
                color: step.done ? Colors.white : AppColors.textLight),
          ),
          if (!isLast)
            Container(
              width:  2,
              height: 36,
              color:  step.done
                  ? AppColors.primary
                  : AppColors.borderColor,
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
                        fontSize:   13,
                        color:      step.done
                            ? AppColors.textDark
                            : AppColors.textGrey)),
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

  // ── Technician card ───────────────────────────────────────────────────────

  Widget _buildTechCard(
      TechnicianInfo tech, TechnicianLocation? loc) {
    return _Card(
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.engineering_rounded,
              color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tech.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textDark)),
              const SizedBox(height: 2),
              const Text('Field Technician',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textGrey)),
            ],
          ),
        ),
        if (tech.phone.isNotEmpty)
          _IconBtn(
            icon:  Icons.phone_rounded,
            color: const Color(0xFF4CAF50),
            onTap: () => _call(tech.phone),
          ),
        if (loc != null) ...[
          const SizedBox(width: 8),
          _IconBtn(
            icon:  Icons.map_rounded,
            color: AppColors.primary,
            onTap: () => _openMaps(loc.lat, loc.lng),
          ),
        ],
      ]),
    );
  }

  // ── Shared AppBar ─────────────────────────────────────────────────────────

  AppBar _simpleAppBar() => AppBar(
    backgroundColor: AppColors.primary,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded,
          color: Colors.white, size: 20),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text('Technician Tracking',
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCAL HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color:        AppColors.cardBg,
      borderRadius: BorderRadius.circular(16),
      border:       Border.all(color: AppColors.borderColor),
    ),
    padding: const EdgeInsets.all(16),
    child: child,
  );
}

class _IconBtn extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 18),
    ),
  );
}

class _LegendDot extends StatelessWidget {
  final Color  color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey)),
    ],
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

// ── Marker pin triangle ───────────────────────────────────────────────────────

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path  = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}