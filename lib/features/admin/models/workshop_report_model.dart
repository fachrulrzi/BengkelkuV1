class WorkshopReportModel {
  final String id;
  final String reporterId;
  final String bengkelId;
  final String reason;
  final String? evidenceUrl;
  final String status; // 'pending', 'reviewed', 'suspended', 'dismissed'
  final DateTime createdAt;
  final Map<String, dynamic>? reporter;
  final Map<String, dynamic>? bengkel;

  WorkshopReportModel({
    required this.id,
    required this.reporterId,
    required this.bengkelId,
    required this.reason,
    this.evidenceUrl,
    required this.status,
    required this.createdAt,
    this.reporter,
    this.bengkel,
  });

  factory WorkshopReportModel.fromMap(Map<String, dynamic> map) {
    return WorkshopReportModel(
      id: map['id']?.toString() ?? '',
      reporterId: map['reporter_id']?.toString() ?? '',
      bengkelId: map['bengkel_id']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      evidenceUrl: map['evidence_url']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      reporter: map['reporter'] as Map<String, dynamic>?,
      bengkel: map['bengkels'] as Map<String, dynamic>?,
    );
  }
}
