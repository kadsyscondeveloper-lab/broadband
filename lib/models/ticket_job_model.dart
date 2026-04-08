// lib/models/ticket_job_model.dart

class TechnicianInfo {
  final int    id;
  final String name;
  final String phone;

  const TechnicianInfo({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory TechnicianInfo.fromJson(Map<String, dynamic> j) => TechnicianInfo(
    id:    int.tryParse(j['id'].toString()) ?? 0,
    name:  j['name']  as String? ?? 'Technician',
    phone: j['phone'] as String? ?? '',
  );
}

class TechnicianLocation {
  final double   lat;
  final double   lng;
  final DateTime updatedAt;

  const TechnicianLocation({
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory TechnicianLocation.fromJson(Map<String, dynamic> j) =>
      TechnicianLocation(
        lat:       double.tryParse(j['lat'].toString()) ?? 0.0,
        lng:       double.tryParse(j['lng'].toString()) ?? 0.0,
        updatedAt: DateTime.tryParse(j['updated_at'].toString())?.toLocal() ??
            DateTime.now(),
      );
}

/// Mirrors the response of GET /api/v1/tickets/:id/job-status
class TicketJobStatus {
  final bool               requiresTechnician;
  final String?            techJobStatus;   // 'open' | 'assigned' | 'completed'
  final DateTime?          jobOpenedAt;
  final DateTime?          jobAssignedAt;
  final DateTime?          jobCompletedAt;
  final TechnicianInfo?    technician;
  final TechnicianLocation? location;

  const TicketJobStatus({
    required this.requiresTechnician,
    this.techJobStatus,
    this.jobOpenedAt,
    this.jobAssignedAt,
    this.jobCompletedAt,
    this.technician,
    this.location,
  });

  bool get isOpen       => techJobStatus == 'open';
  bool get isAssigned   => techJobStatus == 'assigned';
  bool get isCompleted  => techJobStatus == 'completed';

  factory TicketJobStatus.fromJson(Map<String, dynamic> j) => TicketJobStatus(
    requiresTechnician: j['requires_technician'] as bool? ?? false,
    techJobStatus:      j['tech_job_status'] as String?,
    jobOpenedAt: j['job_opened_at'] != null
        ? DateTime.tryParse(j['job_opened_at'].toString())?.toLocal()
        : null,
    jobAssignedAt: j['job_assigned_at'] != null
        ? DateTime.tryParse(j['job_assigned_at'].toString())?.toLocal()
        : null,
    jobCompletedAt: j['job_completed_at'] != null
        ? DateTime.tryParse(j['job_completed_at'].toString())?.toLocal()
        : null,
    technician: j['technician'] != null
        ? TechnicianInfo.fromJson(j['technician'] as Map<String, dynamic>)
        : null,
    location: j['location'] != null
        ? TechnicianLocation.fromJson(j['location'] as Map<String, dynamic>)
        : null,
  );
}
