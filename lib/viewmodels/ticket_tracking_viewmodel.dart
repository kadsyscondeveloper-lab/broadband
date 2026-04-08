// lib/viewmodels/ticket_tracking_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../models/ticket_job_model.dart';
import '../services/ticket_job_service.dart';

class TicketTrackingViewModel extends ChangeNotifier {
  final _service = TicketJobService();

  // ── State ──────────────────────────────────────────────────────────────────

  TicketJobStatus?    _jobStatus;
  TechnicianLocation? _liveLocation;

  bool    _loading     = false;
  bool    _socketReady = false;
  String? _error;

  TicketJobStatus?    get jobStatus     => _jobStatus;
  TechnicianLocation? get liveLocation  => _liveLocation;
  bool                get loading       => _loading;
  bool                get socketReady   => _socketReady;
  String?             get error         => _error;

  // Combined latest location: live socket → fallback REST snapshot
  TechnicianLocation? get bestLocation  => _liveLocation ?? _jobStatus?.location;

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> load(int ticketId) async {
    _loading = true;
    _error   = null;
    notifyListeners();

    try {
      _jobStatus = await _service.getJobStatus(ticketId);

      // Only start Socket.io if a technician is actively assigned
      if (_jobStatus?.isAssigned == true) {
        _connectSocket(ticketId);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh(int ticketId) => load(ticketId);

  // ── Socket ─────────────────────────────────────────────────────────────────

  void _connectSocket(int ticketId) {
    _service.startTracking(
      ticketId: ticketId,
      onLocation: (loc) {
        _liveLocation = loc;
        notifyListeners();
      },
      onError: (msg) {
        _error = msg;
        notifyListeners();
      },
      onConnected: () {
        _socketReady = true;
        notifyListeners();
      },
      onDisconnected: () {
        _socketReady = false;
        notifyListeners();
      },
    );
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  void stopTracking(int ticketId) {
    _service.stopTracking(ticketId);
    _socketReady = false;
  }

  @override
  void dispose() {
    // Caller must call stopTracking(ticketId) before dispose
    super.dispose();
  }
}
