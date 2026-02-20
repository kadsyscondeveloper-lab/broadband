// lib/models/plan_model.dart

class Plan {
  final int id;
  final String name;
  final int speedMbps;
  final int? dataLimitGb; // null = unlimited
  final int validityDays;
  final double price;
  final String? description;

  const Plan({
    required this.id,
    required this.name,
    required this.speedMbps,
    this.dataLimitGb,
    required this.validityDays,
    required this.price,
    this.description,
  });

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
    id:           j['id']             as int,
    name:         j['name']           as String,
    speedMbps:    j['speed_mbps']     as int,
    dataLimitGb:  j['data_limit_gb']  as int?,
    validityDays: j['validity_days']  as int,
    price:        (j['price'] as num).toDouble(),
    description:  j['description']   as String?,
  );

  String get dataLabel => dataLimitGb == null ? 'Unlimited' : '${dataLimitGb} GB';

  String get validityLabel {
    if (validityDays == 30)  return '1 Month';
    if (validityDays == 90)  return '3 Months';
    if (validityDays == 365) return '1 Year';
    return '$validityDays Days';
  }

  String get speedLabel => speedMbps >= 1000
      ? '${speedMbps ~/ 1000} Gbps'
      : '$speedMbps Mbps';
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
  final int? dataLimitGb;
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
    this.dataLimitGb,
    required this.validityDays,
  });

  factory ActiveSubscription.fromJson(Map<String, dynamic> j) => ActiveSubscription(
    id:           j['id']           as int,
    orderRef:     j['order_ref']    as String,
    status:       j['status']       as String,
    amountPaid:   (j['amount_paid'] as num).toDouble(),
    startsAt:     j['starts_at']  != null ? DateTime.parse(j['starts_at'])  : null,
    expiresAt:    j['expires_at'] != null ? DateTime.parse(j['expires_at']) : null,
    planId:       j['plan_id']      as int,
    planName:     j['plan_name']    as String,
    speedMbps:    j['speed_mbps']   as int,
    dataLimitGb:  j['data_limit_gb'] as int?,
    validityDays: j['validity_days'] as int,
  );

  int get daysRemaining {
    if (expiresAt == null) return 0;
    return expiresAt!.difference(DateTime.now()).inDays;
  }

  bool get isExpiringSoon => daysRemaining <= 5;
}

class PlanTransaction {
  final int id;
  final String orderRef;
  final String type;   // debit | credit | refund
  final double amount;
  final String? paymentMode;
  final String status; // pending | success | failed
  final String? note;
  final String? planName;
  final DateTime createdAt;

  const PlanTransaction({
    required this.id,
    required this.orderRef,
    required this.type,
    required this.amount,
    this.paymentMode,
    required this.status,
    this.note,
    this.planName,
    required this.createdAt,
  });

  factory PlanTransaction.fromJson(Map<String, dynamic> j) => PlanTransaction(
    id:          j['id']           as int,
    orderRef:    j['order_ref']    as String,
    type:        j['type']         as String,
    amount:      (j['amount'] as num).toDouble(),
    paymentMode: j['payment_mode'] as String?,
    status:      j['status']       as String,
    note:        j['note']         as String?,
    planName:    j['plan_name']    as String?,
    createdAt:   DateTime.parse(j['created_at'] as String),
  );
}