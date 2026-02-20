// lib/models/plan_model.dart

class Plan {
  final int id;
  final String name;
  final int speedMbps;
  final String dataLimit; // e.g. "100 GB" or "Unlimited" — DB stores as nvarchar
  final int validityDays;
  final double price;
  final String? category;

  const Plan({
    required this.id,
    required this.name,
    required this.speedMbps,
    required this.dataLimit,
    required this.validityDays,
    required this.price,
    this.category,
  });

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
    id:           j['id']            as int,
    name:         j['name']          as String,
    speedMbps:    j['speed_mbps']    as int,
    dataLimit:    j['data_limit']    as String, // ← was j['data_limit_gb'] as int?
    validityDays: j['validity_days'] as int,
    price:        (j['price'] as num).toDouble(),
    category:     j['category']      as String?,
    // description removed — column does not exist in broadband_plans
  );

  /// True when the plan has no data cap (e.g. "Unlimited", "unlimited")
  bool get isUnlimited =>
      dataLimit.trim().toLowerCase() == 'unlimited';

  /// Display-ready label — kept for UI compatibility
  String get dataLabel => isUnlimited ? 'Unlimited' : dataLimit;

  String get validityLabel {
    if (validityDays == 30) return '1 Month';
    if (validityDays == 90) return '3 Months';
    if (validityDays == 365) return '1 Year';
    return '$validityDays Days';
  }

  String get speedLabel =>
      speedMbps >= 1000 ? '${speedMbps ~/ 1000} Gbps' : '$speedMbps Mbps';
}

class ActiveSubscription {
  final int id;
  final String orderRef;
  final String status;
  final double amountPaid;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final int planId;
  final String planName;
  final int speedMbps;
  final String dataLimit; // ← was int? dataLimitGb
  final int validityDays;

  const ActiveSubscription({
    required this.id,
    required this.orderRef,
    required this.status,
    required this.amountPaid,
    this.startsAt,
    this.expiresAt,
    required this.planId,
    required this.planName,
    required this.speedMbps,
    required this.dataLimit,
    required this.validityDays,
  });

  factory ActiveSubscription.fromJson(Map<String, dynamic> j) =>
      ActiveSubscription(
        id:           j['subscription_id'] as int,            // ← was j['id']
        orderRef:     j['order_ref']        as String,
        status:       j['status']           as String,
        amountPaid:   (j['amount_paid'] as num).toDouble(),
        startsAt:     j['start_date']  != null               // ← was j['starts_at']
            ? DateTime.tryParse(j['start_date'] as String)
            : null,
        expiresAt:    j['expires_at'] != null
            ? DateTime.tryParse(j['expires_at'] as String)
            : null,
        planId:       j['plan_id']          as int,
        planName:     j['plan_name']        as String,
        speedMbps:    j['speed_mbps']       as int,
        dataLimit:    j['data_limit']       as String,        // ← was j['data_limit_gb'] as int?
        validityDays: j['validity_days']    as int,
      );

  bool get isUnlimited =>
      dataLimit.trim().toLowerCase() == 'unlimited';

  String get dataLabel => isUnlimited ? 'Unlimited' : dataLimit;

  int get daysRemaining {
    if (expiresAt == null) return 0;
    return expiresAt!.difference(DateTime.now()).inDays;
  }

  bool get isExpiringSoon => daysRemaining <= 5;
}

/// Maps to dbo.wallet_transactions joined with payment_orders
class PlanTransaction {
  final int id;
  final String type;         // 'debit' | 'credit'
  final double amount;
  final double balanceAfter;
  final String description;
  final String? referenceId;
  final String? referenceType;
  final String? orderRef;
  final String? paymentStatus;
  final String? planName;
  final DateTime createdAt;

  const PlanTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    this.referenceId,
    this.referenceType,
    this.orderRef,
    this.paymentStatus,
    this.planName,
    required this.createdAt,
  });

  factory PlanTransaction.fromJson(Map<String, dynamic> j) => PlanTransaction(
    id:            j['id']              as int,
    type:          j['type']            as String,
    amount:        (j['amount'] as num).toDouble(),
    balanceAfter:  (j['balance_after'] as num).toDouble(),
    description:   j['description']     as String,
    referenceId:   j['reference_id']    as String?,
    referenceType: j['reference_type']  as String?,
    orderRef:      j['order_ref']       as String?,
    paymentStatus: j['payment_status']  as String?,
    planName:      j['plan_name']       as String?,
    createdAt:     DateTime.parse(j['created_at'] as String),
  );

  /// Convenience: was this a wallet top-up?
  bool get isCredit => type == 'credit';

  /// Display sign for amount
  String get amountLabel =>
      isCredit ? '+₹${amount.toStringAsFixed(2)}' : '-₹${amount.toStringAsFixed(2)}';
}