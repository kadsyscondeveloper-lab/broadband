// lib/services/bill_service.dart
import '../core/api_client.dart';

class Bill {
  final int     id;
  final String  billNumber;
  final String? planName;
  final DateTime? billingPeriodStart;   // ← nullable
  final DateTime? billingPeriodEnd;     // ← nullable
  final double  baseAmount;
  final double  gstAmount;
  final double  discountAmount;
  final double  totalAmount;
  final DateTime? dueDate;             // ← nullable
  final String  status;
  final DateTime? paidAt;
  final DateTime createdAt;
  final String? orderRef;
  final String? paymentMethod;
  final String? couponCode;      // ← NEW

  const Bill({
    required this.id,
    required this.billNumber,
    this.planName,
    this.billingPeriodStart,           // ← no longer required
    this.billingPeriodEnd,
    required this.baseAmount,
    required this.gstAmount,
    this.discountAmount = 0,
    required this.totalAmount,
    this.dueDate,
    required this.status,
    this.paidAt,
    required this.createdAt,
    this.orderRef,
    this.paymentMethod,
    this.couponCode,
  });

  bool get isPaid    => status == 'paid';
  bool get isOverdue => status == 'overdue';
  bool get isUnpaid  => status == 'unpaid';
  bool get hasCoupon => couponCode != null &&
      couponCode!.isNotEmpty &&
      discountAmount > 0;

  factory Bill.fromJson(Map<String, dynamic> j) => Bill(
    id:                   int.tryParse(j['id'].toString()) ?? 0,
    billNumber:           j['bill_number']           as String? ?? '',
    planName:             j['plan_name']             as String?,
    billingPeriodStart: j['billing_period_start'] != null
        ? DateTime.tryParse(j['billing_period_start'].toString())
        : null,

    billingPeriodEnd: j['billing_period_end'] != null
        ? DateTime.tryParse(j['billing_period_end'].toString())
        : null,

    dueDate: j['due_date'] != null
        ? DateTime.tryParse(j['due_date'].toString())
        : null,
    baseAmount:           (j['base_amount']    as num).toDouble(),
    gstAmount:            (j['gst_amount']     as num).toDouble(),
    discountAmount:       (j['discount_amount'] as num?)?.toDouble() ?? 0,
    totalAmount:          (j['total_amount']   as num).toDouble(),
    status:               j['status']               as String? ?? 'unpaid',
    paidAt:               j['paid_at'] != null
        ? DateTime.tryParse(j['paid_at'].toString())
        : null,
    createdAt: DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now(),
    orderRef:             j['order_ref']       as String?,
    paymentMethod:        j['payment_method']  as String?,
    couponCode:           j['coupon_code']     as String?,
  );
}

class BillService {
  static final BillService _i = BillService._();
  factory BillService() => _i;
  BillService._();

  final _api = ApiClient();

  /// GET /user/bills
  Future<List<Bill>> getBills({int page = 1, int limit = 20}) async {
    final res  = await _api.get('/user/bills',
        params: {'page': page, 'limit': limit});
    final list = res.data['data']['bills'] as List<dynamic>;
    return list.map((e) => Bill.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /user/bills/:id
  Future<Bill?> getBill(int id) async {
    try {
      final res = await _api.get('/user/bills/$id');
      return Bill.fromJson(
          res.data['data']['bill'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}