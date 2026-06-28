import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../admin/models/workshop_report_model.dart';

class WorkshopReportViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Admin-side list of all reports
  List<WorkshopReportModel> _reports = [];
  List<WorkshopReportModel> get reports => _reports;

  // ─── Customer: Submit a report ───────────────────────────────────────────────

  Future<bool> submitReport({
    required String bengkelId,
    required String reason,
    String? evidenceUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      await _supabase.from('workshop_reports').insert({
        'reporter_id': userId,
        'bengkel_id': bengkelId,
        'reason': reason,
        'evidence_url': evidenceUrl,
        'status': 'pending',
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Admin: Fetch all reports ─────────────────────────────────────────────────

  Future<void> fetchReports() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _supabase
          .from('workshop_reports')
          .select('*, reporter:reporter_id(full_name, email), bengkels(name, address)')
          .order('created_at', ascending: false);

      _reports = List<Map<String, dynamic>>.from(data)
          .map((m) => WorkshopReportModel.fromMap(m))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching workshop reports: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── Admin: Update report status (reviewed / suspended / dismissed) ──────────

  Future<bool> updateReportStatus(String reportId, String status) async {
    try {
      await _supabase
          .from('workshop_reports')
          .update({'status': status})
          .eq('id', reportId);

      final idx = _reports.indexWhere((r) => r.id == reportId);
      if (idx != -1) {
        final old = _reports[idx];
        _reports[idx] = WorkshopReportModel(
          id: old.id,
          reporterId: old.reporterId,
          bengkelId: old.bengkelId,
          reason: old.reason,
          evidenceUrl: old.evidenceUrl,
          status: status,
          createdAt: old.createdAt,
          reporter: old.reporter,
          bengkel: old.bengkel,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Admin: Suspend a bengkel (set status to 'suspended') ───────────────────

  Future<bool> suspendBengkel(String bengkelId, String reportId) async {
    try {
      await _supabase
          .from('bengkels')
          .update({'status': 'suspended'})
          .eq('id', bengkelId);

      await updateReportStatus(reportId, 'suspended');
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Admin: Unsuspend a bengkel (set status back to 'active') ───────────────

  Future<bool> unsuspendBengkel(String bengkelId, String reportId) async {
    try {
      await _supabase
          .from('bengkels')
          .update({'status': 'active'})
          .eq('id', bengkelId);

      await updateReportStatus(reportId, 'reviewed');
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  int get pendingCount => _reports.where((r) => r.status == 'pending').length;
}
