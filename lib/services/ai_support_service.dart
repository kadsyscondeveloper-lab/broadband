// lib/services/ai_support_service.dart

import 'package:dio/dio.dart';
import '../core/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

enum AiSessionStatus { active, resolved, escalated }

enum AiAction { none, resolved, ticketCreated, technicianDispatched }

class AiMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;

  const AiMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isUser      => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory AiMessage.fromJson(Map<String, dynamic> j) => AiMessage(
    role:      j['role']    as String,
    content:   j['content'] as String,
    createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '')?.toLocal()
        ?? DateTime.now(),
  );

  // Optimistic local constructor
  factory AiMessage.local({required String role, required String content}) =>
      AiMessage(role: role, content: content, createdAt: DateTime.now());
}

class AiStartResult {
  final int    sessionId;
  final String greeting;
  const AiStartResult({required this.sessionId, required this.greeting});
}

class AiMessageResult {
  final String         reply;
  final AiAction       action;
  final int?           ticketId;
  final String?        ticketNumber;
  final AiSessionStatus sessionStatus;

  const AiMessageResult({
    required this.reply,
    required this.action,
    required this.sessionStatus,
    this.ticketId,
    this.ticketNumber,
  });

  factory AiMessageResult.fromJson(Map<String, dynamic> j) {
    final actionStr = j['action'] as String?;
    final action = switch (actionStr) {
      'resolved'              => AiAction.resolved,
      'ticket_created'        => AiAction.ticketCreated,
      'technician_dispatched' => AiAction.technicianDispatched,
      _                       => AiAction.none,
    };
    final statusStr = j['sessionStatus'] as String? ?? 'active';
    final status = switch (statusStr) {
      'resolved'  => AiSessionStatus.resolved,
      'escalated' => AiSessionStatus.escalated,
      _           => AiSessionStatus.active,
    };
    return AiMessageResult(
      reply:         j['reply']        as String? ?? '',
      action:        action,
      sessionStatus: status,
      ticketId:      j['ticketId']     as int?,
      ticketNumber:  j['ticketNumber'] as String?,
    );
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class AiSupportService {
  static final AiSupportService _i = AiSupportService._();
  factory AiSupportService() => _i;
  AiSupportService._();

  final _api = ApiClient();

  Future<AiStartResult> startSession() async {
    try {
      final res = await _api.post('/ai-support/sessions');
      final data = res.data['data'] as Map<String, dynamic>;
      return AiStartResult(
        sessionId: data['sessionId'] as int,
        greeting:  data['greeting']  as String,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AiMessageResult> sendMessage(int sessionId, String message) async {
    try {
      final res = await _api.post(
        '/ai-support/sessions/$sessionId/message',
        data: {'message': message},
      );
      return AiMessageResult.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<AiMessage>> getHistory(int sessionId) async {
    try {
      final res = await _api.get('/ai-support/sessions/$sessionId');
      final msgs = res.data['data']['messages'] as List<dynamic>? ?? [];
      return msgs
          .map((m) => AiMessage.fromJson(m as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
