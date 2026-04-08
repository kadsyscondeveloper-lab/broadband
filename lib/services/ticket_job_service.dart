// lib/services/ticket_job_service.dart
//
// Handles:
//   • REST  → GET /tickets/:id/job-status
//   • Socket.io → live technician location via ws://host/tracking/user
//
// pubspec.yaml dependencies needed:
//   socket_io_client: ^2.0.3+1
//   dio: (already present)

import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/api_client.dart';
import '../core/app_config.dart';
import '../core/storage_service.dart';
import '../models/ticket_job_model.dart';

// ── Callback typedefs ────────────────────────────────────────────────────────

typedef LocationCallback = void Function(TechnicianLocation location);
typedef ErrorCallback    = void Function(String message);

// ── Service ──────────────────────────────────────────────────────────────────

class TicketJobService {
  static final TicketJobService _i = TicketJobService._();
  factory TicketJobService() => _i;
  TicketJobService._();

  final _api     = ApiClient();
  final _storage = StorageService();

  IO.Socket? _socket;

  // ── REST: fetch job status snapshot ────────────────────────────────────────

  Future<TicketJobStatus?> getJobStatus(int ticketId) async {
    try {
      final res = await _api.get('/tickets/$ticketId/job-status');
      final data = res.data['data'] as Map<String, dynamic>;
      return TicketJobStatus.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ── Socket.io: start live tracking ─────────────────────────────────────────
  //
  //  1. Connects to ws://<host>/tracking/user with JWT.
  //  2. Emits   `track:ticket { ticket_id }` to subscribe.
  //  3. Receives `technician:location { lat, lng, updated_at }` events.
  //  4. Call stopTracking() when the screen is disposed.

  void startTracking({
    required int              ticketId,
    required LocationCallback onLocation,
    required ErrorCallback    onError,
    VoidCallback?             onConnected,
    VoidCallback?             onDisconnected,
  }) {
    // Derive Socket.io host from baseUrl (strip /api/v1)
    final wsHost = AppConfig.baseUrl.replaceFirst(RegExp(r'/api/v1.*'), '');
    final token  = _storage.accessToken ?? '';

    _socket = IO.io(
      '$wsHost/tracking/user',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': 'Bearer $token'})
          .build(),
    );

    _socket!
      ..onConnect((_) {
        onConnected?.call();
        // Subscribe to this ticket's room
        _socket!.emit('track:ticket', {'ticket_id': ticketId});
      })
      ..on('tracking:started', (_) {
        // Server confirmed we joined the room — no UI action needed
      })
      ..on('technician:location', (data) {
        try {
          final map = data as Map<String, dynamic>;
          onLocation(TechnicianLocation.fromJson(map));
        } catch (_) {}
      })
      ..on('error', (data) {
        final msg = (data is Map ? data['message'] : data?.toString()) ?? 'Socket error';
        onError(msg as String);
      })
      ..onDisconnect((_) => onDisconnected?.call())
      ..connect();
  }

  void stopTracking(int ticketId) {
    _socket?.emit('track:stop', {'ticket_id': ticketId});
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;
}
