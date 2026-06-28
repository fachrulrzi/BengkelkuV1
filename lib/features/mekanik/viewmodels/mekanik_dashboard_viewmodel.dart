import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mechanic_task_model.dart';

class MekanikDashboardViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _mechanicId;
  String? get mechanicId => _mechanicId;

  Map<String, dynamic>? _profile;
  List<MechanicTaskModel> _activeTasks = [];
  List<MechanicTaskModel> _completedTasks = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<MechanicTaskModel> get activeTasks => _activeTasks;
  List<MechanicTaskModel> get completedTasks => _completedTasks;

  String get mechanicName => _profile?['name']?.toString() ?? 'Mekanik';
  String get mechanicStatus => _profile?['status']?.toString() ?? 'Tersedia';
  String get mechanicSpecialist => _profile?['specialist']?.toString() ?? '';

  int get tasksCompletedToday {
    final today = DateTime.now();
    return _completedTasks.where((t) {
      return t.bookingDate.year == today.year &&
          t.bookingDate.month == today.month &&
          t.bookingDate.day == today.day;
    }).length;
  }

  int get tasksCompletedThisMonth {
    final now = DateTime.now();
    return _completedTasks.where((t) {
      return t.bookingDate.year == now.year && t.bookingDate.month == now.month;
    }).length;
  }

  int get totalTasks => _completedTasks.length;

  int get totalIncome =>
      _completedTasks.fold(0, (sum, t) => sum + t.totalPrice);

  MechanicTaskModel? get activeTask {
    try {
      return _activeTasks.firstWhere((t) => t.status == 'Diproses');
    } catch (_) {
      try {
        return _activeTasks
            .firstWhere((t) => t.status == 'Mekanik Ditugaskan');
      } catch (_) {
        return null;
      }
    }
  }

  List<MechanicTaskModel> get newTasks =>
      _activeTasks.where((t) => t.status == 'Mekanik Ditugaskan').toList();

  void setMechanicData(Map<String, dynamic> data) {
    _mechanicId = data['id']?.toString();
    _profile = data;
    notifyListeners();
    fetchData();
  }

  Future<void> fetchData() async {
    if (_mechanicId == null) return;
    _setLoading(true);
    try {
      // Refresh profile
      final profileData = await _supabase
          .from('mechanics')
          .select()
          .eq('id', _mechanicId!)
          .maybeSingle();
      if (profileData != null) _profile = profileData;

      // Active tasks (not selesai/dibatalkan/ulasan dikirim)
      final activeData = await _supabase
          .from('service_bookings')
          .select('*, users:customer_id(full_name, phone)')
          .eq('mechanic_id', _mechanicId!)
          .not('status', 'in', '("Selesai","Dibatalkan","Ulasan Dikirim","Menunggu Pembayaran Tambahan")')
          .order('booking_date', ascending: true)
          .order('booking_time', ascending: true);
      _activeTasks =
          (activeData as List).map((e) => MechanicTaskModel.fromJson(e)).toList();

      // Auto lock status to 'Bertugas' if there are active tasks, or revert to 'Tersedia' if none
      if (_activeTasks.isNotEmpty) {
        if (mechanicStatus != 'Bertugas') {
          await _supabase
              .from('mechanics')
              .update({'status': 'Bertugas'})
              .eq('id', _mechanicId!);
          if (_profile != null) {
            _profile!['status'] = 'Bertugas';
          }
        }
      } else {
        if (mechanicStatus == 'Bertugas') {
          await _supabase
              .from('mechanics')
              .update({'status': 'Tersedia'})
              .eq('id', _mechanicId!);
          if (_profile != null) {
            _profile!['status'] = 'Tersedia';
          }
        }
      }

      // Completed tasks
      final completedData = await _supabase
          .from('service_bookings')
          .select('*, users:customer_id(full_name, phone)')
          .eq('mechanic_id', _mechanicId!)
          .inFilter('status', ['Selesai', 'Ulasan Dikirim', 'Menunggu Pembayaran Tambahan'])
          .order('booking_date', ascending: false)
          .order('booking_time', ascending: false);
      _completedTasks = (completedData as List)
          .map((e) => MechanicTaskModel.fromJson(e))
          .toList();

      debugPrint('[Mekanik] Active: ${_activeTasks.length}, Completed: ${_completedTasks.length}');
    } catch (e) {
      debugPrint('[Mekanik] Error fetching data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateStatus(String status) async {
    if (_mechanicId == null) return;
    if (status == 'Bertugas') {
      debugPrint('[Mekanik] Cannot update status to "Bertugas" manually');
      return;
    }
    if (_activeTasks.isNotEmpty) {
      debugPrint('[Mekanik] Cannot update status manually while having active tasks');
      return;
    }
    try {
      await _supabase
          .from('mechanics')
          .update({'status': status})
          .eq('id', _mechanicId!);
      if (_profile != null) {
        _profile!['status'] = status;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Mekanik] Error updating status: $e');
      rethrow;
    }
  }

  Future<void> acceptTask(String bookingId) async {
    try {
      await _supabase
          .from('service_bookings')
          .update({'status': 'Diterima'})
          .eq('id', bookingId);
      // Update mekanik jadi Bertugas
      await _supabase
          .from('mechanics')
          .update({'status': 'Bertugas'})
          .eq('id', _mechanicId!);
      await fetchData();
    } catch (e) {
      debugPrint('[Mekanik] Error accepting task: $e');
      rethrow;
    }
  }

  Future<void> rejectTask(String bookingId) async {
    try {
      await _supabase.from('service_bookings').update({
        'status': 'Menunggu Konfirmasi',
        'mechanic_id': null,
        'mechanic_name': null,
      }).eq('id', bookingId);

      // Reset status mekanik ke Tersedia karena menolak tugas
      await _supabase
          .from('mechanics')
          .update({'status': 'Tersedia'})
          .eq('id', _mechanicId!);

      await fetchData();
    } catch (e) {
      debugPrint('[Mekanik] Error rejecting task: $e');
      rethrow;
    }
  }

  Future<void> startJourney(String bookingId) async {
    final hasOngoing = _activeTasks.any((t) => 
      t.id != bookingId && 
      (t.status == 'Menuju Lokasi' || t.status == 'Sampai Lokasi' || t.status == 'Diproses')
    );
    if (hasOngoing) {
      throw Exception('Anda sedang mengerjakan tugas lain yang belum selesai.');
    }

    try {
      await _supabase
          .from('service_bookings')
          .update({
            'status': 'Menuju Lokasi',
            'mechanic_latitude': -6.2000,
            'mechanic_longitude': 106.8166,
          })
          .eq('id', bookingId);
      await fetchData();
    } catch (e) {
      debugPrint('[Mekanik] Error starting journey: $e');
      rethrow;
    }
  }

  Future<void> updateLiveLocation(String bookingId, double lat, double lng) async {
    try {
      await _supabase
          .from('service_bookings')
          .update({
            'mechanic_latitude': lat,
            'mechanic_longitude': lng,
          })
          .eq('id', bookingId);
      
      // Update local activeTasks
      final idx = _activeTasks.indexWhere((t) => t.id == bookingId);
      if (idx != -1) {
        final t = _activeTasks[idx];
        _activeTasks[idx] = MechanicTaskModel(
          id: t.id,
          customerId: t.customerId,
          customerName: t.customerName,
          customerPhone: t.customerPhone,
          vehicleName: t.vehicleName,
          vehiclePoliceNumber: t.vehiclePoliceNumber,
          serviceCategory: t.serviceCategory,
          bookingDate: t.bookingDate,
          bookingTime: t.bookingTime,
          status: t.status,
          complaint: t.complaint,
          isHomeService: t.isHomeService,
          customerAddress: t.customerAddress,
          homeServiceFee: t.homeServiceFee,
          totalPrice: t.totalPrice,
          bengkelId: t.bengkelId,
          serviceReport: t.serviceReport,
          createdAt: t.createdAt,
          initialPaymentStatus: t.initialPaymentStatus,
          initialPaymentAmount: t.initialPaymentAmount,
          additionalPrice: t.additionalPrice,
          additionalPaymentStatus: t.additionalPaymentStatus,
          serviceProofUrl: t.serviceProofUrl,
          mechanicLatitude: lat,
          mechanicLongitude: lng,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Mekanik] Error updating live location: $e');
    }
  }

  Future<void> arriveAtLocation(String bookingId) async {
    try {
      await _supabase
          .from('service_bookings')
          .update({'status': 'Sampai Lokasi'})
          .eq('id', bookingId);
      await fetchData();
    } catch (e) {
      debugPrint('[Mekanik] Error arriving at location: $e');
      rethrow;
    }
  }

  Future<void> confirmCustomerArrival(String bookingId) async {
    final hasOngoing = _activeTasks.any((t) => 
      t.id != bookingId && 
      (t.status == 'Menuju Lokasi' || t.status == 'Sampai Lokasi' || t.status == 'Diproses')
    );
    if (hasOngoing) {
      throw Exception('Anda sedang mengerjakan tugas lain yang belum selesai.');
    }

    try {
      await _supabase
          .from('service_bookings')
          .update({'status': 'Diproses'})
          .eq('id', bookingId);
      await fetchData();
    } catch (e) {
      debugPrint('[Mekanik] Error confirming customer arrival: $e');
      rethrow;
    }
  }

  Future<void> completeTask({
    required String bookingId,
    required String report,
    required int additionalPrice,
    required int initialPaymentAmount,
    String? serviceProofUrl,
  }) async {
    try {
      final finalStatus = additionalPrice > 0 ? 'Menunggu Pembayaran Tambahan' : 'Selesai';
      final totalPrice = initialPaymentAmount + additionalPrice;

      await _supabase.from('service_bookings').update({
        'status': finalStatus,
        'service_report': report,
        'additional_price': additionalPrice,
        'additional_payment_status': additionalPrice > 0 ? 'unpaid' : 'none',
        'total_price': totalPrice,
        'service_proof_url': serviceProofUrl,
      }).eq('id', bookingId);

      // Mekanik kembali Tersedia
      await _supabase
          .from('mechanics')
          .update({'status': 'Tersedia'})
          .eq('id', _mechanicId!);
      await fetchData();
    } catch (e) {
      debugPrint('[Mekanik] Error completing task: $e');
      rethrow;
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
