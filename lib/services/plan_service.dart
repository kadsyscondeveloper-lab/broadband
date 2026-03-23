// lib/services/plan_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/storage_service.dart';
import '../models/plan_model.dart';

class PlanService {
  static const String _base = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://103.88.81.7:3000/api/v1',
  );

  final _storage = StorageService();

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_storage.accessToken}',
  };

  // ── Plans ───────────────────────────────────────────────────────────────────

  Future<List<Plan>> getPlans() async {
    final res  = await http.get(Uri.parse('$_base/plans'));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw body['message'] ?? 'Failed to load plans';
    final list = body['data']['plans'] as List<dynamic>;
    return list.map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Plan> getPlan(int planId) async {
    final res  = await http.get(Uri.parse('$_base/plans/$planId'));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw body['message'] ?? 'Failed to load plan';
    return Plan.fromJson(body['data']['plan'] as Map<String, dynamic>);
  }

  // ── Purchase ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> purchasePlan(
      int planId, {
        String paymentMode = 'wallet',
        String? couponCode,
      }) async {
    final res = await http.post(
      Uri.parse('$_base/plans/$planId/purchase'),
      headers: _authHeaders,
      body: jsonEncode({
        'payment_mode': paymentMode,
        if (couponCode != null) 'coupon_code': couponCode,
      }),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 201) throw body['message'] ?? 'Purchase failed';
    return body['data'] as Map<String, dynamic>;
  }

  // ── Active subscription (currently running) ──────────────────────────────────

  Future<ActiveSubscription?> getActiveSubscription() async {
    final res  = await http.get(
      Uri.parse('$_base/plans/subscription/active'),
      headers: _authHeaders,
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw body['message'] ?? 'Failed to load subscription';
    final sub = body['data']['subscription'];
    if (sub == null) return null;
    return ActiveSubscription.fromJson(sub as Map<String, dynamic>);
  }

  // ── Queued subscription (upcoming / not yet started) ─────────────────────────
  // FIX: New method that fetches the nearest future-start subscription.
  // This ensures the queued plan is visible even after leaving and re-entering
  // the plans screen — it's fetched from the server, not held in memory.

  Future<ActiveSubscription?> getQueuedSubscription() async {
    final res = await http.get(
      Uri.parse('$_base/plans/subscription/queued'),
      headers: _authHeaders,
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw body['message'] ?? 'Failed to load queued subscription';
    final sub = body['data']['subscription'];
    if (sub == null) return null;
    return ActiveSubscription.fromJson(sub as Map<String, dynamic>);
  }

  // ── Transactions ─────────────────────────────────────────────────────────────

  Future<List<PlanTransaction>> getTransactions({int page = 1, int limit = 20}) async {
    final res  = await http.get(
      Uri.parse('$_base/plans/transactions?page=$page&limit=$limit'),
      headers: _authHeaders,
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw body['message'] ?? 'Failed to load transactions';
    final list = body['data']['transactions'] as List<dynamic>;
    return list.map((e) => PlanTransaction.fromJson(e as Map<String, dynamic>)).toList();
  }
}