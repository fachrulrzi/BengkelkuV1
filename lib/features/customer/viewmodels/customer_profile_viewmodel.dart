import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle_model.dart';

class CustomerProfileViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<VehicleModel> _vehicles = [];
  List<VehicleModel> get vehicles => _vehicles;

  int _selectedVehicleIndex = 0;
  int get selectedVehicleIndex => _selectedVehicleIndex;

  void setSelectedVehicleIndex(int index) {
    _selectedVehicleIndex = index;
    notifyListeners();
  }

  VehicleModel? get activeVehicle {
    if (_vehicles.isNotEmpty && _selectedVehicleIndex >= 0 && _selectedVehicleIndex < _vehicles.length) {
      return _vehicles[_selectedVehicleIndex];
    }
    return null;
  }

  List<String> _brands = [];
  List<String> get brands => _brands;

  Future<void> fetchBrands() async {
    try {
      final response = await _supabase
          .from('vehicle_brands')
          .select('name')
          .order('name', ascending: true);
      final List<dynamic> data = response;
      _brands = data.map((e) => e['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
    } catch (e) {
      debugPrint('Error fetching brands: $e');
    } finally {
      if (_brands.isEmpty) {
        _brands = ['Honda', 'Toyota', 'Suzuki', 'Yamaha', 'Kawasaki', 'Mitsubishi', 'Daihatsu'];
      }
      notifyListeners();
    }
  }

  Future<void> fetchVehicles() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _setLoading(true);

    try {
      final response = await _supabase
          .from('vehicles')
          .select()
          .eq('user_id', user.id)
          .neq('status', 'deleted')   // exclude soft-deleted vehicles
          .order('created_at', ascending: true);

      final List<dynamic> data = response;
      _vehicles = data.map((e) => VehicleModel.fromJson(e)).toList();
      debugPrint('[Vehicles] Berhasil memuat ${_vehicles.length} kendaraan dari Supabase');
    } catch (e) {
      debugPrint('[Vehicles] ERROR saat fetchVehicles: $e');
      _vehicles = [];
    } finally {
      if (_selectedVehicleIndex >= _vehicles.length) {
        _selectedVehicleIndex = 0;
      }
      _setLoading(false);
    }
  }

  Future<void> addVehicle({
    required String brand,
    required String model,
    required int year,
    required String licensePlate,
    required String type,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    try {
      await _supabase.from('vehicles').insert({
        'user_id': user.id,
        'brand': brand,
        'model': model,
        'year': year,
        'license_plate': licensePlate,
        'status': 'Active',
        'type': type,
      });
      await fetchVehicles();
    } catch (e) {
      debugPrint('Error adding vehicle: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateVehicle({
    required String id,
    required String brand,
    required String model,
    required int year,
    required String licensePlate,
    required String type,
  }) async {
    _setLoading(true);
    try {
      await _supabase.from('vehicles').update({
        'brand': brand,
        'model': model,
        'year': year,
        'license_plate': licensePlate,
        'type': type,
      }).eq('id', id);
      await fetchVehicles();
    } catch (e) {
      debugPrint('Error updating vehicle: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteVehicle(String id) async {
    if (id.isEmpty) {
      debugPrint('[Vehicles] deleteVehicle: id kosong, dibatalkan.');
      return;
    }
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('[Vehicles] deleteVehicle: user tidak login.');
      return;
    }
    _setLoading(true);
    try {
      // Soft delete: ubah status ke 'deleted' agar tidak melanggar
      // FK constraint dari service_bookings.vehicle_id (NOT NULL).
      // Hard delete akan gagal karena ada booking yang mereferensikan vehicle ini.
      await _supabase
          .from('vehicles')
          .update({'status': 'deleted'})
          .eq('id', id)
          .eq('user_id', user.id);

      // Sesuaikan index agar tidak out-of-bounds setelah hapus
      if (_selectedVehicleIndex >= _vehicles.length - 1) {
        _selectedVehicleIndex = 0;
      }
      await fetchVehicles();
      debugPrint('[Vehicles] Kendaraan $id berhasil dihapus (soft delete).');
    } catch (e) {
      debugPrint('[Vehicles] Error soft-deleting vehicle $id: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  List<Map<String, dynamic>> _vehicleModels = [];
  List<Map<String, dynamic>> get vehicleModels => _vehicleModels;

  Future<void> fetchVehicleModels() async {
    try {
      final response = await _supabase
          .from('vehicle_models')
          .select();
      _vehicleModels = List<Map<String, dynamic>>.from(response as List);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching vehicle models: $e');
    }
  }
}
