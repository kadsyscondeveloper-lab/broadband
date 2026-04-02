class InstallStatusData {
  final InstallationSummary? installation;
  final PendingPlanSummary?  pendingPlan;

  bool get installationCompleted => installation?.status == 'completed';

  const InstallStatusData({this.installation, this.pendingPlan});

  factory InstallStatusData.fromJson(Map<String, dynamic> json) {
    final inst = json['installation'];
    final plan = json['pending_plan'];

    return InstallStatusData(
      installation: inst is Map<String, dynamic>
          ? InstallationSummary.fromJson(inst)
          : null,
      pendingPlan: plan is Map<String, dynamic>
          ? PendingPlanSummary.fromJson(plan)
          : null,
    );
  }
}

class InstallationSummary {
  final int    id;
  final String requestNumber;
  final String status;

  const InstallationSummary({
    required this.id,
    required this.requestNumber,
    required this.status,
  });

  factory InstallationSummary.fromJson(Map<String, dynamic> j) =>
      InstallationSummary(
        id:            j['id'] as int,
        requestNumber: j['request_number'] as String,
        status:        j['status'] as String,
      );
}

class PendingPlanSummary {
  final String planName;
  final int    speedMbps;

  const PendingPlanSummary({
    required this.planName,
    required this.speedMbps,
  });

  factory PendingPlanSummary.fromJson(Map<String, dynamic> j) =>
      PendingPlanSummary(
        planName:  j['plan_name'] as String? ?? '',
        speedMbps: int.tryParse(j['speed_mbps'].toString()) ?? 0,
      );
}