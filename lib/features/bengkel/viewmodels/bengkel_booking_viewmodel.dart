import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../customer/models/booking_model.dart';
import '../models/mechanic_model.dart';

class BengkelBookingViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<BookingModel> _bookings = [];
  List<BookingModel> get bookings => _bookings;

  List<MechanicModel> _mechanics = [];
  List<MechanicModel> get mechanics => _mechanics;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String? _forcedBengkelId; // Set ini dari luar jika user adalah mekanik

  void setMechanicBengkelId(String bengkelId) {
    _forcedBengkelId = bengkelId;
  }

  Future<void> fetchBookings() async {
    _setLoading(true);
    try {
      // Jika bengkelId sudah di-set (login sebagai mekanik)
      if (_forcedBengkelId != null) {
        final response = await _supabase
            .from('service_bookings')
            .select('*, bengkels ( name ), users ( full_name )')
            .eq('bengkel_id', _forcedBengkelId!)
            .order('created_at', ascending: false);
        _bookings = (response as List).map((e) => BookingModel.fromJson(e)).toList();
        debugPrint('[BengkelBooking] Mechanic mode - bookings: ${_bookings.length}');
        _setLoading(false);
        return;
      }

      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('[BengkelBooking] ERROR: user is null, not logged in');
        return;
      }
      debugPrint('[BengkelBooking] Current user ID: ${user.id}');

      // 1. Get bengkel id - coba dengan owner_id dulu, lalu user_id sebagai fallback
      var bengkelData = await _supabase
          .from('bengkels')
          .select('id, name')
          .eq('owner_id', user.id)
          .maybeSingle();

      // Fallback: coba kolom user_id jika owner_id tidak ada
      if (bengkelData == null) {
        debugPrint('[BengkelBooking] owner_id not found, trying user_id column...');
        bengkelData = await _supabase
            .from('bengkels')
            .select('id, name')
            .eq('user_id', user.id)
            .maybeSingle();
      }

      if (bengkelData == null) {
        debugPrint('[BengkelBooking] ERROR: No bengkel found for this user. User ID: ${user.id}');
        final allBengkels = await _supabase.from('bengkels').select('id, name, owner_id').limit(5);
        debugPrint('[BengkelBooking] All bengkels in DB: $allBengkels');
        return;
      }


      final bengkelId = bengkelData['id'];
      debugPrint('[BengkelBooking] Found bengkel ID: $bengkelId, name: ${bengkelData['name']}');

      // 2. Get bookings for this bengkel (tanpa join dulu untuk debug)
      final rawBookings = await _supabase
          .from('service_bookings')
          .select('id, status, bengkel_id, booking_date')
          .eq('bengkel_id', bengkelId);
      debugPrint('[BengkelBooking] Raw bookings count: ${rawBookings.length}');

      // 3. Get bookings (tanpa join FK yang belum terdaftar)
      final response = await _supabase
          .from('service_bookings')
          .select('*, bengkels ( name ), users ( full_name )')
          .eq('bengkel_id', bengkelId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      debugPrint('[BengkelBooking] Bookings with join count: ${data.length}');
      _bookings = data.map((e) => BookingModel.fromJson(e)).toList();

      // 4. Fetch available mechanics for this bengkel
      final mechanicsData = await _supabase
          .from('mechanics')
          .select()
          .eq('bengkel_id', bengkelId);
      
      _mechanics = mechanicsData.map((e) => MechanicModel.fromJson(e)).toList();
      debugPrint('[BengkelBooking] Mechanics count: ${_mechanics.length}');

    } catch (e) {
      debugPrint('[BengkelBooking] EXCEPTION: $e');
    } finally {
      _setLoading(false);
    }
  }

  bool get areAllMechanicsBusy {
    if (_mechanics.isEmpty) return false;
    return _mechanics.every((m) => m.status == 'Bertugas');
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    _setLoading(true);
    try {
      await _supabase
          .from('service_bookings')
          .update({'status': status})
          .eq('id', bookingId);
      
      await fetchBookings();
    } catch (e) {
      debugPrint('Error updating booking status: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> requestInitialPayment(String bookingId) async {
    _setLoading(true);
    try {
      await _supabase
          .from('service_bookings')
          .update({'status': 'Menunggu Pembayaran Jasa'})
          .eq('id', bookingId);
      
      await fetchBookings();
    } catch (e) {
      debugPrint('Error requesting initial payment: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> assignMechanic(String bookingId, String mechanicId) async {
    _setLoading(true);
    try {
      // Ambil nama mekanik dulu
      String mechanicName = '';
      try {
        final mData = await _supabase
            .from('mechanics')
            .select('name')
            .eq('id', mechanicId)
            .maybeSingle();
        mechanicName = mData?['name'] ?? '';
      } catch (_) {}

      await _supabase
          .from('service_bookings')
          .update({
            'mechanic_id': mechanicId,
            'mechanic_name': mechanicName,
            'status': 'Mekanik Ditugaskan'
          })
          .eq('id', bookingId);
      
      // Update mechanic status to Bertugas
      await _supabase
          .from('mechanics')
          .update({'status': 'Bertugas'})
          .eq('id', mechanicId);

      await fetchBookings();
    } catch (e) {
      debugPrint('Error assigning mechanic: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeService(String bookingId, String report, int finalPrice) async {
    _setLoading(true);
    try {
      await _supabase
          .from('service_bookings')
          .update({
            'status': 'Selesai',
            'service_report': report,
            'total_price': finalPrice,
          })
          .eq('id', bookingId);
      
      // Bebaskan mekanik
      final booking = _bookings.firstWhere((b) => b.id == bookingId);
      if (booking.mechanicId != null) {
        await _supabase
            .from('mechanics')
            .update({'status': 'Tersedia'})
            .eq('id', booking.mechanicId!);
      }

      await fetchBookings();
    } catch (e) {
      debugPrint('Error completing service: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}


