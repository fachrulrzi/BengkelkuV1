import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bengkel_service_model.dart';

class BengkelServiceViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<BengkelServiceModel> _services = [];
  List<BengkelServiceModel> get services => _services;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchServicesByBengkel(String bengkelId) async {
    _isLoading = true;
    // We use Future.microtask to avoid modifying providers during build phases
    Future.microtask(() => notifyListeners());

    try {
      final response = await _supabase
          .from('bengkel_services')
          .select('*, service_categories(name, description)')
          .eq('bengkel_id', bengkelId);
          
      final List<dynamic> data = response;
      _services = data.map((json) => BengkelServiceModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching bengkel services: $e');
      _services = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> get reviews => _reviews;

  bool _isReviewsLoading = false;
  bool get isReviewsLoading => _isReviewsLoading;

  Future<void> fetchReviewsByBengkel(String bengkelId) async {
    _isReviewsLoading = true;
    // Notify on next microtask to prevent build-phase notify errors
    Future.microtask(() => notifyListeners());

    try {
      final response = await _supabase
          .from('service_bookings')
          .select('id, rating_score, rating_comment, rating_mechanic_name, created_at, users(full_name)')
          .eq('bengkel_id', bengkelId)
          .not('rating_score', 'is', null)
          .order('created_at', ascending: false);
      
      _reviews = List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      _reviews = [];
    } finally {
      _isReviewsLoading = false;
      notifyListeners();
    }
  }
}
