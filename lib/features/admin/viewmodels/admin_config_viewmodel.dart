import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle_brand_model.dart';
import '../models/vehicle_type_model.dart';
import '../models/service_category_model.dart';
import '../../auth/models/user_model.dart';

class AdminConfigViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Platform Commissions
  double _marketplaceCommission = 12.0;
  double get marketplaceCommission => _marketplaceCommission;

  double _homeServiceCommission = 15.0;
  double get homeServiceCommission => _homeServiceCommission;

  void setCommissions(double marketplace, double homeService) {
    _marketplaceCommission = marketplace;
    _homeServiceCommission = homeService;
    notifyListeners();
  }

  // Configuration Lists
  List<VehicleBrandModel> _brands = [];
  List<VehicleBrandModel> get brands => _brands;

  List<Map<String, dynamic>> _vehicleModels = [];
  List<Map<String, dynamic>> get vehicleModels => _vehicleModels;

  List<VehicleTypeModel> _types = [];
  List<VehicleTypeModel> get types => _types;

  List<ServiceCategoryModel> _categories = [];
  List<ServiceCategoryModel> get categories => _categories;

  // Stats
  int _totalUsers = 0;
  int get totalUsers => _totalUsers;

  int _newUsersThisMonth = 0;
  int get newUsersThisMonth => _newUsersThisMonth;

  int _totalWorkshops = 0;
  int get totalWorkshops => _totalWorkshops;

  int _pendingWorkshops = 0;
  int get pendingWorkshops => _pendingWorkshops;

  // Order Stats
  int _completedOrders = 0;
  int get completedOrders => _completedOrders;
  
  int _inProgressOrders = 0;
  int get inProgressOrders => _inProgressOrders;
  
  int _pendingOrders = 0;
  int get pendingOrders => _pendingOrders;
  
  int _cancelledOrders = 0;
  int get cancelledOrders => _cancelledOrders;

  // Top Workshops
  List<Map<String, dynamic>> _topWorkshops = [];
  List<Map<String, dynamic>> get topWorkshops => _topWorkshops;

  // Cancellation Rate
  double _cancellationRate = 0.0;
  double get cancellationRate => _cancellationRate;

  // Recent Activities
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> get recentActivities => _recentActivities;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetch Dashboard Stats
  Future<void> fetchDashboardStats() async {
    _setLoading(true);
    try {
      // Fetch users
      final usersRes = await _supabase.from('users').select('created_at');
      final List<dynamic> usersData = usersRes;
      _totalUsers = usersData.length;
      
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      _newUsersThisMonth = usersData.where((u) {
        final date = DateTime.tryParse(u['created_at']?.toString() ?? '');
        return date != null && date.isAfter(thirtyDaysAgo);
      }).length;

      // Fetch bengkels count
      final bengkelsRes = await _supabase.from('bengkels').select('status');
      final List<dynamic> list = bengkelsRes;
      _totalWorkshops = list.length;
      _pendingWorkshops = list.where((b) => b['status'] == 'pending' || b['status'] == 'tahap 2').length;

      // Fetch bookings for order distribution & top workshops
      final bookingsRes = await _supabase.from('bookings').select('status, bengkel_id, bengkels(name, rating)');
      final List<dynamic> bookings = bookingsRes;
      
      _completedOrders = bookings.where((b) => b['status'] == 'completed' || b['status'] == 'selesai').length;
      _inProgressOrders = bookings.where((b) => b['status'] == 'in_progress' || b['status'] == 'accepted' || b['status'] == 'diproses' || b['status'] == 'diterima').length;
      _pendingOrders = bookings.where((b) => b['status'] == 'pending' || b['status'] == 'menunggu').length;
      _cancelledOrders = bookings.where((b) => b['status'] == 'cancelled' || b['status'] == 'rejected' || b['status'] == 'dibatalkan' || b['status'] == 'ditolak').length;

      // Group bookings by bengkel
      Map<String, int> bengkelBookingCount = {};
      Map<String, Map<String, dynamic>> bengkelDetails = {};
      
      for(var b in bookings) {
        if (b['bengkel_id'] != null) {
          final bid = b['bengkel_id'].toString();
          // Only count completed/in_progress for "top performing" if you want, but total orders is fine
          bengkelBookingCount[bid] = (bengkelBookingCount[bid] ?? 0) + 1;
          
          if (b['bengkels'] != null) {
            bengkelDetails[bid] = {
              'name': b['bengkels']['name'] ?? 'Bengkel',
              'rating': b['bengkels']['rating'] ?? 4.5,
            };
          }
        }
      }

      var sortedBengkels = bengkelBookingCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      _topWorkshops = sortedBengkels.take(4).map((e) {
        return {
          'name': bengkelDetails[e.key]?['name'] ?? 'Bengkel',
          'rating': bengkelDetails[e.key]?['rating'] ?? 4.5,
          'orders': e.value,
        };
      }).toList();

      // Calculate cancellation rate
      int totalOrders = bookings.length;
      if (totalOrders > 0) {
        _cancellationRate = (_cancelledOrders / totalOrders) * 100;
      } else {
        _cancellationRate = 0.0;
      }

      // Fetch Recent Activities from Multiple Tables
      final futures = await Future.wait([
        _supabase.from('users').select('id, name, created_at').order('created_at', ascending: false).limit(3),
        _supabase.from('bengkels').select('id, name, created_at, status').order('created_at', ascending: false).limit(3),
        _supabase.from('bookings').select('id, created_at, status, bengkels(name)').order('created_at', ascending: false).limit(3),
      ]);

      List<Map<String, dynamic>> combinedActivities = [];

      // Process Users
      for (var u in futures[0] as List<dynamic>) {
        combinedActivities.add({
          'type': 'user',
          'title': u['name'] ?? 'Pengguna Baru',
          'subtitle': 'Baru saja mendaftar akun',
          'created_at': DateTime.tryParse(u['created_at'].toString()) ?? DateTime.now(),
        });
      }

      // Process Bengkels
      for (var b in futures[1] as List<dynamic>) {
        String status = b['status'] ?? 'pending';
        String subtitle = status == 'pending' || status == 'tahap 2' 
            ? 'Menunggu verifikasi admin' 
            : 'Bengkel terverifikasi';
        combinedActivities.add({
          'type': 'bengkel',
          'title': b['name'] ?? 'Bengkel Baru',
          'subtitle': subtitle,
          'created_at': DateTime.tryParse(b['created_at'].toString()) ?? DateTime.now(),
        });
      }

      // Process Bookings
      for (var bk in futures[2] as List<dynamic>) {
        String bName = bk['bengkels'] != null ? bk['bengkels']['name'] : 'bengkel';
        combinedActivities.add({
          'type': 'booking',
          'title': 'Pesanan Baru',
          'subtitle': 'Pesanan masuk ke $bName',
          'created_at': DateTime.tryParse(bk['created_at'].toString()) ?? DateTime.now(),
        });
      }

      // Sort combined activities by created_at descending
      combinedActivities.sort((a, b) => (b['created_at'] as DateTime).compareTo(a['created_at'] as DateTime));
      
      // Take top 5
      _recentActivities = combinedActivities.take(5).toList();

    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      // Remove fallback data so it doesn't suddenly jump to 2453 if one query fails
    } finally {
      _setLoading(false);
    }
  }

  // --- VEHICLE BRANDS CRUD ---
  Future<void> fetchBrands() async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('vehicle_brands')
          .select()
          .order('name', ascending: true);
      final List<dynamic> data = response;
      _brands = data.map((e) => VehicleBrandModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching brands: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addBrand(String name) async {
    final nameLower = name.trim().toLowerCase();
    if (_brands.any((b) => b.name.trim().toLowerCase() == nameLower)) {
      throw Exception('Merek "$name" sudah ada di database.');
    }
    _setLoading(true);
    try {
      await _supabase.from('vehicle_brands').insert({'name': name.trim()});
      await fetchBrands();
    } catch (e) {
      debugPrint('Error adding brand: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateBrand(String id, String name) async {
    final nameLower = name.trim().toLowerCase();
    if (_brands.any((b) => b.id != id && b.name.trim().toLowerCase() == nameLower)) {
      throw Exception('Merek "$name" sudah ada di database.');
    }
    _setLoading(true);
    try {
      await _supabase.from('vehicle_brands').update({'name': name.trim()}).eq('id', id);
      await fetchBrands();
    } catch (e) {
      debugPrint('Error updating brand: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteBrand(String id) async {
    _setLoading(true);
    try {
      await _supabase.from('vehicle_brands').delete().eq('id', id);
      await fetchBrands();
    } catch (e) {
      debugPrint('Error deleting brand: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  // --- VEHICLE MODELS CRUD ---
  Future<void> fetchVehicleModels() async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('vehicle_models')
          .select()
          .order('brand', ascending: true)
          .order('name', ascending: true);
      _vehicleModels = List<Map<String, dynamic>>.from(response as List);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching vehicle models: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addVehicleModel(String name, String brand, String type) async {
    final nameLower = name.trim().toLowerCase();
    final brandLower = brand.trim().toLowerCase();
    if (_vehicleModels.any((m) => 
        (m['name']?.toString() ?? '').trim().toLowerCase() == nameLower && 
        (m['brand']?.toString() ?? '').trim().toLowerCase() == brandLower)) {
      throw Exception('Model "$name" sudah ada di dalam merek "$brand".');
    }
    _setLoading(true);
    try {
      await _supabase.from('vehicle_models').insert({
        'name': name.trim(),
        'brand': brand,
        'type': type,
      });
      await fetchVehicleModels();
    } catch (e) {
      debugPrint('Error adding vehicle model: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateVehicleModel(String id, String name, String brand, String type) async {
    final nameLower = name.trim().toLowerCase();
    final brandLower = brand.trim().toLowerCase();
    if (_vehicleModels.any((m) => 
        m['id']?.toString() != id &&
        (m['name']?.toString() ?? '').trim().toLowerCase() == nameLower && 
        (m['brand']?.toString() ?? '').trim().toLowerCase() == brandLower)) {
      throw Exception('Model "$name" sudah ada di dalam merek "$brand".');
    }
    _setLoading(true);
    try {
      await _supabase.from('vehicle_models').update({
        'name': name.trim(),
        'brand': brand,
        'type': type,
      }).eq('id', id);
      await fetchVehicleModels();
    } catch (e) {
      debugPrint('Error updating vehicle model: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteVehicleModel(String id) async {
    _setLoading(true);
    try {
      await _supabase.from('vehicle_models').delete().eq('id', id);
      await fetchVehicleModels();
    } catch (e) {
      debugPrint('Error deleting vehicle model: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // --- VEHICLE TYPES CRUD ---
  Future<void> fetchTypes() async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('vehicle_types')
          .select()
          .order('name', ascending: true);
      final List<dynamic> data = response;
      _types = data.map((e) => VehicleTypeModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching types: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addType(String name, String description) async {
    _setLoading(true);
    try {
      await _supabase.from('vehicle_types').insert({
        'name': name,
        'description': description,
      });
      await fetchTypes();
    } catch (e) {
      debugPrint('Error adding type: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateType(String id, String name, String description) async {
    _setLoading(true);
    try {
      await _supabase.from('vehicle_types').update({
        'name': name,
        'description': description,
      }).eq('id', id);
      await fetchTypes();
    } catch (e) {
      debugPrint('Error updating type: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteType(String id) async {
    _setLoading(true);
    try {
      await _supabase.from('vehicle_types').delete().eq('id', id);
      await fetchTypes();
    } catch (e) {
      debugPrint('Error deleting type: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // --- SERVICE CATEGORIES CRUD ---
  Future<void> fetchCategories() async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('service_categories')
          .select()
          .order('name', ascending: true);
      final List<dynamic> data = response;
      _categories = data.map((e) => ServiceCategoryModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addCategory(String name, String description) async {
    _setLoading(true);
    try {
      await _supabase.from('service_categories').insert({
        'name': name,
        'description': description,
      });
      await fetchCategories();
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCategory(String id, String name, String description) async {
    _setLoading(true);
    try {
      await _supabase.from('service_categories').update({
        'name': name,
        'description': description,
      }).eq('id', id);
      await fetchCategories();
    } catch (e) {
      debugPrint('Error updating category: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteCategory(String id) async {
    _setLoading(true);
    try {
      await _supabase.from('service_categories').delete().eq('id', id);
      await fetchCategories();
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // --- USERS CRUD ---
  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  Future<void> fetchUsers() async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);
      final List<dynamic> data = response;
      _users = data.map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addUser({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String role,
  }) async {
    _setLoading(true);
    try {
      await _supabase.rpc('create_new_user', params: {
        'p_email': email,
        'p_password': password,
        'p_full_name': fullName,
        'p_phone': phone,
        'p_address': address,
        'p_role': role,
      });
      await fetchUsers();
      await fetchDashboardStats();
    } catch (e) {
      debugPrint('Error adding user via RPC: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUser(
    String id, {
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String role,
  }) async {
    _setLoading(true);
    try {
      await _supabase.rpc('update_existing_user', params: {
        'p_user_id': id,
        'p_email': email,
        'p_full_name': fullName,
        'p_phone': phone,
        'p_address': address,
        'p_role': role,
      });
      await fetchUsers();
    } catch (e) {
      debugPrint('Error updating user via RPC: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteUser(String id) async {
    _setLoading(true);
    try {
      await _supabase.rpc('delete_existing_user', params: {
        'p_user_id': id,
      });
      await fetchUsers();
      await fetchDashboardStats();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
