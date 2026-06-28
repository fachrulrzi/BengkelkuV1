import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mechanic_model.dart';

class BengkelMechanicViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<MechanicModel> _mechanics = [];
  List<MechanicModel> get mechanics => _mechanics;

  int get availableCount => _mechanics.where((m) => m.status == 'Tersedia').length;
  int get busyCount => _mechanics.where((m) => m.status == 'Bertugas').length;
  int get offlineCount => _mechanics.where((m) => m.status == 'Offline').length;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchMechanics(String bengkelId) async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('mechanics')
          .select()
          .eq('bengkel_id', bengkelId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      _mechanics = data.map((e) => MechanicModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching mechanics: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addMechanic({
    required String bengkelId,
    required String name,
    required String email,
    required String phone,
    required String specialist,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _supabase.from('mechanics').insert({
        'bengkel_id': bengkelId,
        'name': name,
        'email': email,
        'phone': phone,
        'specialist': specialist,
        'password': password,
        'status': 'Tersedia',
        'rating': 5.0,
        'services_count': 0,
      });
      await fetchMechanics(bengkelId);
    } catch (e) {
      debugPrint('Error adding mechanic: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateStatus(String mechanicId, String newStatus, String bengkelId) async {
    _setLoading(true);
    try {
      await _supabase
          .from('mechanics')
          .update({'status': newStatus})
          .eq('id', mechanicId);
      await fetchMechanics(bengkelId);
    } catch (e) {
      debugPrint('Error updating mechanic status: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
