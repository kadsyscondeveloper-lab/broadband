// lib/services/ticket_service.dart

import 'package:dio/dio.dart';
import '../core/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class TicketReply {
  final int     id;
  final int     senderId;
  final String  senderType;
  final String  message;
  final String? attachmentUrl;
  final DateTime createdAt;

  const TicketReply({
    required this.id,
    required this.senderId,
    required this.senderType,
    required this.message,
    this.attachmentUrl,
    required this.createdAt,
  });

  bool get isAdmin => senderType == 'admin';

  factory TicketReply.fromJson(Map<String, dynamic> j) => TicketReply(
    id:            int.tryParse(j['id'].toString()) ?? 0,
    senderId:      int.tryParse(j['sender_id'].toString()) ?? 0,
    senderType:    j['sender_type']    as String? ?? 'user',
    message:       j['message']        as String? ?? '',
    attachmentUrl: j['attachment_url'] as String?,
    createdAt:     DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now(),
  );
}

class SupportTicket {
  final int     id;
  final String  ticketNumber;
  final String  category;
  final String  subject;
  final String  description;
  final String  status;
  final String  priority;
  final DateTime?  resolvedAt;
  final DateTime   createdAt;
  final DateTime   updatedAt;
  final List<TicketReply> replies;

  const SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.replies = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> j) => SupportTicket(
    id:           int.tryParse(j['id'].toString()) ?? 0,
    ticketNumber: j['ticket_number'] as String? ?? '',
    category:     j['category']      as String? ?? '',
    subject:      j['subject']       as String? ?? '',
    description:  j['description']   as String? ?? '',
    status:       j['status']        as String? ?? 'open',
    priority:     j['priority']      as String? ?? 'medium',
    resolvedAt:   j['resolved_at'] != null
        ? DateTime.tryParse(j['resolved_at'].toString())
        : null,
    createdAt:    DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now(),
    updatedAt:    DateTime.tryParse(j['updated_at'].toString()) ?? DateTime.now(),
    replies:      (j['replies'] as List<dynamic>? ?? [])
        .map((r) => TicketReply.fromJson(r as Map<String, dynamic>))
        .toList(),
  );

  bool get isOpen       => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved   => status == 'resolved' || status == 'closed';
}

class TicketResult {
  final bool           success;
  final String?        error;
  final SupportTicket? ticket;
  const TicketResult({required this.success, this.error, this.ticket});
}

// ── Service ───────────────────────────────────────────────────────────────────

class TicketService {
  static final TicketService _i = TicketService._();
  factory TicketService() => _i;
  TicketService._();

  final _api = ApiClient();

  // ── Must stay in sync with backend VALID_CATEGORIES ──────────────────────
  static const List<String> categories = [
    'Billing',
    'Technical Issue',
    'Connection Issue',
    'Slow Speed',
    'New Connection',
    'Installation',
    'Plan Change',
    'KYC',
    'Other',
  ];

  // POST /tickets
  Future<TicketResult> createTicket({
    required String category,
    required String subject,
    required String description,
    String  priority           = 'medium',
    String? attachmentData,    // base64 string
    String? attachmentMime,    // e.g. 'image/jpeg'
  }) async {
    try {
      final res = await _api.post('/tickets', data: {
        'category':        category,
        'subject':         subject,
        'description':     description,
        'priority':        priority,
        if (attachmentData != null) 'attachment_data': attachmentData,
        if (attachmentMime != null) 'attachment_mime': attachmentMime,
      });
      final ticket = SupportTicket.fromJson(
        res.data['data']['ticket'] as Map<String, dynamic>,
      );
      return TicketResult(success: true, ticket: ticket);
    } on DioException catch (e) {
      return TicketResult(success: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      return TicketResult(success: false, error: e.toString());
    }
  }

  // GET /tickets
  Future<List<SupportTicket>> getTickets({int page = 1, int limit = 10}) async {
    final res  = await _api.get('/tickets', params: {'page': page, 'limit': limit});
    final list = res.data['data']['tickets'] as List<dynamic>;
    return list
        .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /tickets/:id
  Future<SupportTicket?> getTicket(int id) async {
    try {
      final res = await _api.get('/tickets/$id');
      return SupportTicket.fromJson(
          res.data['data']['ticket'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}