import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../customer/models/bengkel_service_model.dart';

class BengkelManageServiceViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<BengkelServiceModel> _services = [];
  List<BengkelServiceModel> get services => _services;

  String? _fetchError;
  String? get fetchError => _fetchError;

  List<Map<String, dynamic>> _masterCategories = [];
  List<Map<String, dynamic>> get masterCategories => _masterCategories;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Ambil daftar layanan yang sudah dimiliki bengkel
  Future<void> fetchMyServices(String bengkelId) async {
    if (bengkelId.isEmpty) return;
    _fetchError = null;
    setLoading(true);
    try {
      final response = await _supabase.from('bengkel_services').select('''
        id,
        bengkel_id,
        base_price,
        home_service_fee,
        estimated_duration,
        service_categories (
          id,
          name,
          description
        )
      ''').eq('bengkel_id', bengkelId);

      _services = response.map((data) => BengkelServiceModel.fromJson(data)).toList();
    } catch (e) {
      _fetchError = e.toString();
      debugPrint('Error fetching my services: $e');
    } finally {
      setLoading(false);
    }
  }

  // Ambil daftar kategori layanan master (untuk dropdown tambah layanan)
  Future<void> fetchMasterCategories() async {
    try {
      final response = await _supabase.from('service_categories').select();
      _masterCategories = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching master categories: $e');
    }
  }

  // Tambah layanan baru
  Future<void> addService({
    required String bengkelId,
    required String categoryId,
    required int basePrice,
    required int homeServiceFee,
    required String duration,
  }) async {
    setLoading(true);
    try {
      await _supabase.from('bengkel_services').insert({
        'bengkel_id': bengkelId,
        'service_category_id': categoryId,
        'base_price': basePrice,
        'home_service_fee': homeServiceFee,
        'estimated_duration': duration,
      });
      // Refresh list
      await fetchMyServices(bengkelId);
    } catch (e) {
      debugPrint('Error adding service: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // Edit layanan
  Future<void> updateService({
    required String serviceId,
    required String bengkelId,
    required int basePrice,
    required int homeServiceFee,
    required String duration,
  }) async {
    setLoading(true);
    try {
      await _supabase.from('bengkel_services').update({
        'base_price': basePrice,
        'home_service_fee': homeServiceFee,
        'estimated_duration': duration,
      }).eq('id', serviceId);
      // Refresh list
      await fetchMyServices(bengkelId);
    } catch (e) {
      debugPrint('Error updating service: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // Hapus layanan
  Future<void> deleteService(String serviceId, String bengkelId) async {
    setLoading(true);
    try {
      await _supabase.from('bengkel_services').delete().eq('id', serviceId);
      // Refresh list
      await fetchMyServices(bengkelId);
    } catch (e) {
      debugPrint('Error deleting service: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }
}
