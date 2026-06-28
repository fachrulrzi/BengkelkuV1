import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sparepart_model.dart';
import '../../admin/models/vehicle_brand_model.dart';

class BengkelInventoryViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<SparepartModel> _spareparts = [];
  List<SparepartModel> get spareparts => _spareparts;

  List<VehicleBrandModel> _allBrands = [];
  List<VehicleBrandModel> get allBrands => _allBrands;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetch all brands for compatibility checklist
  Future<void> fetchBrands() async {
    try {
      final response = await _supabase
          .from('vehicle_brands')
          .select()
          .order('name', ascending: true);
      final List<dynamic> data = response;
      _allBrands = data.map((e) => VehicleBrandModel.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching brands in inventory viewmodel: $e');
    }
  }

  // Fetch spareparts for a specific bengkel
  Future<void> fetchSpareparts(String bengkelId) async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('spareparts')
          .select('*, sparepart_compatibilities(vehicle_brand_id)')
          .eq('bengkel_id', bengkelId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      _spareparts = data.map((e) => SparepartModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching spareparts: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Upload binary image to Supabase Storage
  Future<String?> uploadSparepartImage(Uint8List fileBytes, String fileName) async {
    try {
      final fileExt = fileName.split('.').last;
      final filePath = 'sparepart-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      await _supabase.storage.from('spareparts').uploadBinary(
        filePath,
        fileBytes,
        fileOptions: const FileOptions(upsert: true),
      );
      
      final publicUrl = _supabase.storage.from('spareparts').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading sparepart image: $e');
      rethrow;
    }
  }

  // Delete file from Supabase Storage
  Future<void> deleteSparepartImage(String imageUrl) async {
    try {
      final Uri uri = Uri.parse(imageUrl);
      final String path = uri.pathSegments.last;
      await _supabase.storage.from('spareparts').remove([path]);
    } catch (e) {
      debugPrint('Error deleting sparepart image from storage: $e');
    }
  }

  // Add a new sparepart with compatibility mappings and image
  Future<void> addSparepart({
    required String bengkelId,
    required String name,
    required String sku,
    required String category,
    required double price,
    required int stock,
    String? imageUrl,
    required List<String> compatibleBrandIds,
  }) async {
    _setLoading(true);
    try {
      // 1. Insert sparepart
      final insertRes = await _supabase.from('spareparts').insert({
        'bengkel_id': bengkelId,
        'name': name,
        'sku': sku,
        'category': category,
        'price': price,
        'stock': stock,
        'image_url': imageUrl,
      }).select('id').single();

      final String newSparepartId = insertRes['id']?.toString() ?? '';

      // 2. Insert compatibilities
      if (newSparepartId.isNotEmpty && compatibleBrandIds.isNotEmpty) {
        final List<Map<String, dynamic>> linkRows = compatibleBrandIds
            .map((brandId) => {
                  'sparepart_id': newSparepartId,
                  'vehicle_brand_id': brandId,
                })
            .toList();

        await _supabase.from('sparepart_compatibilities').insert(linkRows);
      }

      await fetchSpareparts(bengkelId);
    } catch (e) {
      debugPrint('Error adding sparepart: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Edit an existing sparepart with compatibility updates and image
  Future<void> editSparepart({
    required String sparepartId,
    required String bengkelId,
    required String name,
    required String sku,
    required String category,
    required double price,
    required int stock,
    String? imageUrl,
    required List<String> compatibleBrandIds,
  }) async {
    _setLoading(true);
    try {
      // 1. Update basic fields
      await _supabase.from('spareparts').update({
        'name': name,
        'sku': sku,
        'category': category,
        'price': price,
        'stock': stock,
        'image_url': imageUrl,
      }).eq('id', sparepartId);

      // 2. Clear existing compatibilities
      await _supabase
          .from('sparepart_compatibilities')
          .delete()
          .eq('sparepart_id', sparepartId);

      // 3. Insert new compatibilities
      if (compatibleBrandIds.isNotEmpty) {
        final List<Map<String, dynamic>> linkRows = compatibleBrandIds
            .map((brandId) => {
                  'sparepart_id': sparepartId,
                  'vehicle_brand_id': brandId,
                })
            .toList();

        await _supabase.from('sparepart_compatibilities').insert(linkRows);
      }

      await fetchSpareparts(bengkelId);
    } catch (e) {
      debugPrint('Error editing sparepart: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a sparepart and its image
  Future<void> deleteSparepart(String sparepartId, String bengkelId) async {
    _setLoading(true);
    try {
      // Find the image URL first
      final itemRes = await _supabase
          .from('spareparts')
          .select('image_url')
          .eq('id', sparepartId)
          .maybeSingle();
      
      final String? oldImageUrl = itemRes?['image_url'];

      await _supabase.from('spareparts').delete().eq('id', sparepartId);

      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await deleteSparepartImage(oldImageUrl);
      }

      await fetchSpareparts(bengkelId);
    } catch (e) {
      debugPrint('Error deleting sparepart: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
