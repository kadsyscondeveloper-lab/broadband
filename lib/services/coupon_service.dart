// lib/services/coupon_service.dart
import 'package:dio/dio.dart';
import '../core/api_client.dart';

class CouponValidationResult {
  final bool    valid;
  final String? code;
  final String? description;
  final String  discountType;   // 'percent' | 'flat'
  final double  discountValue;
  final double  discountAmount; // actual ₹ off
  final double  originalTotal;
  final double  finalTotal;
  final String? error;

  const CouponValidationResult({
    required this.valid,
    this.code,
    this.description,
    this.discountType  = '',
    this.discountValue = 0,
    this.discountAmount = 0,
    this.originalTotal  = 0,
    this.finalTotal     = 0,
    this.error,
  });

  factory CouponValidationResult.fromJson(Map<String, dynamic> j) {
    final d = j['data'] as Map<String, dynamic>? ?? j;
    return CouponValidationResult(
      valid:           j['success'] == true,
      code:            d['code']           as String?,
      description:     d['description']    as String?,
      discountType:    d['discount_type']  as String? ?? '',
      discountValue:   (d['discount_value']  as num?)?.toDouble() ?? 0,
      discountAmount:  (d['discount_amount'] as num?)?.toDouble() ?? 0,
      originalTotal:   (d['original_total']  as num?)?.toDouble() ?? 0,
      finalTotal:      (d['final_total']     as num?)?.toDouble() ?? 0,
    );
  }

  factory CouponValidationResult.invalid(String err) =>
      CouponValidationResult(valid: false, error: err);

  String get discountLabel {
    if (discountType == 'percent') return '${discountValue.toStringAsFixed(0)}% off';
    return '₹${discountValue.toStringAsFixed(0)} off';
  }
}

class CouponService {
  static final CouponService _i = CouponService._();
  factory CouponService() => _i;
  CouponService._();

  final _api = ApiClient();

  /// POST /plans/coupon/validate
  Future<CouponValidationResult> validate({
    required int    planId,
    required String couponCode,
  }) async {
    try {
      final res = await _api.post(
        '/plans/coupon/validate',
        data: {'plan_id': planId, 'coupon_code': couponCode.trim().toUpperCase()},
      );
      return CouponValidationResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Invalid coupon code.';
      return CouponValidationResult.invalid(msg);
    } catch (_) {
      return CouponValidationResult.invalid('Could not validate coupon. Please try again.');
    }
  }
}