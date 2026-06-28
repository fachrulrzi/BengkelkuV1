import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class BengkelDashboardViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _status =
      'pending'; // pending, profile_complete, document_uploaded, verified, rejected
  String get status => _status;

  String? _bengkelId;
  String get bengkelId => _bengkelId ?? '';

  String? _bengkelName;
  String get bengkelName => _bengkelName ?? '';

  String? _bengkelAddress;
  String get bengkelAddress => _bengkelAddress ?? '';

  String? _description;
  String get description => _description ?? '';

  String? _operatingHours;
  String get operatingHours => _operatingHours ?? '';

  String? _documentUrl;
  String? get documentUrl => _documentUrl;

  String? _rejectionReason;
  String? get rejectionReason => _rejectionReason;

  double? _latitude;
  double? get latitude => _latitude;

  double? _longitude;
  double? get longitude => _longitude;

  double? _rating;
  double get rating => _rating ?? 4.5;

  int? _reviewsCount;
  int get reviewsCount => _reviewsCount ?? 0;

  List<Map<String, dynamic>> _reviewsList = [];
  List<Map<String, dynamic>> get reviewsList => _reviewsList;

  bool _isReviewsLoading = false;
  bool get isReviewsLoading => _isReviewsLoading;

  // Profile dianggap lengkap jika name, address, description & operating_hours terisi
  bool get isProfileComplete =>
      (_bengkelName?.isNotEmpty ?? false) &&
      (_bengkelAddress?.isNotEmpty ?? false) &&
      (_description?.isNotEmpty ?? false) &&
      (_operatingHours?.isNotEmpty ?? false);

  BengkelDashboardViewModel();

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchBengkelStatus({String? userId}) async {
    setLoading(true);
    try {
      final id = userId ?? _supabase.auth.currentUser?.id;
      if (id != null) {
        final data = await _supabase
            .from('bengkels')
            .select()
            .eq('owner_id', id)
            .maybeSingle();

        if (data != null) {
          _bengkelId = data['id']?.toString() ?? '';
          _status = data['status'] ?? 'pending';
          _bengkelName = data['name'];
          _bengkelAddress = data['address'];
          _description = data['description'];
          _operatingHours = data['operating_hours'];
          _documentUrl = data['document_url'];
          _rejectionReason = data['rejection_reason'];
          _latitude = (data['latitude'] as num?)?.toDouble();
          _longitude = (data['longitude'] as num?)?.toDouble();
          _rating = (data['rating'] as num?)?.toDouble() ?? 4.5;
          _reviewsCount = (data['reviews_count'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (e) {
      debugPrint('Error fetching bengkel status: $e');
    }
    setLoading(false);
  }

  Future<void> fetchBengkelReviews() async {
    if (_bengkelId == null || _bengkelId!.isEmpty) return;
    _isReviewsLoading = true;
    // Notify on next microtask to avoid building errors
    Future.microtask(() => notifyListeners());

    try {
      debugPrint('[BengkelReviews] Fetching reviews for bengkel ID: $_bengkelId');

      // 1. Fetch Service Booking Reviews
      final bookingsRes = await _supabase
          .from('service_bookings')
          .select('id, rating_score, rating_comment, created_at, service_category, customer_name, users(full_name)')
          .eq('bengkel_id', _bengkelId!)
          .not('rating_score', 'is', null);

      final List<Map<String, dynamic>> bookingReviews = [];
      for (var b in bookingsRes) {
        final userName = b['users'] != null ? b['users']['full_name'] : null;
        bookingReviews.add({
          'id': b['id']?.toString() ?? '',
          'type': 'Servis',
          'category': b['service_category']?.toString() ?? 'Layanan Servis',
          'rating': (b['rating_score'] as num?)?.toDouble() ?? 5.0,
          'comment': b['rating_comment']?.toString() ?? 'Ulasan tanpa komentar',
          'customer': b['customer_name']?.toString() ?? userName?.toString() ?? 'Pelanggan',
          'date': b['created_at'] != null ? DateTime.parse(b['created_at'].toString()) : DateTime.now(),
        });
      }
      debugPrint('[BengkelReviews] Loaded service reviews: ${bookingReviews.length}');

      // 2. Fetch Order Reviews
      final ordersRes = await _supabase
          .from('orders')
          .select('id, rating, rating_note, created_at, recipient_name, order_items(sparepart_id, spareparts(name, bengkel_id))')
          .not('rating', 'is', null);

      final List<Map<String, dynamic>> orderReviews = [];
      for (var o in ordersRes) {
        final items = o['order_items'] as List? ?? [];
        final belongsToUs = items.any((item) {
          if (item['spareparts'] == null) return false;
          final sBId = item['spareparts']['bengkel_id']?.toString();
          return sBId == _bengkelId;
        });

        if (belongsToUs) {
          final itemNames = items
              .where((item) =>
                  item['spareparts'] != null &&
                  item['spareparts']['bengkel_id']?.toString() == _bengkelId)
              .map((item) => item['spareparts']['name']?.toString() ?? 'Sparepart')
              .join(', ');

          orderReviews.add({
            'id': o['id']?.toString() ?? '',
            'type': 'Sparepart',
            'category': itemNames.isNotEmpty ? itemNames : 'Pembelian Sparepart',
            'rating': (o['rating'] as num?)?.toDouble() ?? 5.0,
            'comment': o['rating_note']?.toString() ?? 'Ulasan tanpa komentar',
            'customer': o['recipient_name']?.toString() ?? 'Pelanggan',
            'date': o['created_at'] != null ? DateTime.parse(o['created_at'].toString()) : DateTime.now(),
          });
        }
      }
      debugPrint('[BengkelReviews] Loaded sparepart reviews: ${orderReviews.length}');

      // Combine
      _reviewsList = [...bookingReviews, ...orderReviews];
      _reviewsList.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      // Recalculate
      if (_reviewsList.isNotEmpty) {
        final totalScore = _reviewsList.fold(0.0, (sum, r) => sum + (r['rating'] as double));
        _rating = double.parse((totalScore / _reviewsList.length).toStringAsFixed(1));
        _reviewsCount = _reviewsList.length;
      } else {
        _rating = 4.5;
        _reviewsCount = 0;
      }
      debugPrint('[BengkelReviews] Dynamic stats: rating=$_rating, count=$_reviewsCount');
    } catch (e) {
      debugPrint('[BengkelReviews] Error in fetchBengkelReviews: $e');
    } finally {
      _isReviewsLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String name,
    required String address,
    required String description,
    required String operatingHours,
    double? latitude,
    double? longitude,
    String? userId,
  }) async {
    setLoading(true);
    try {
      final id = userId ?? _supabase.auth.currentUser?.id;
      if (id == null)
        throw Exception('User tidak ditemukan, silakan login ulang.');

      // Hitung status baru agar tidak merusak alur dokumen yang sudah diunggah atau status verifikasi
      String newStatus = 'tahap 1';
      if (_status == 'diterima' || _status == 'active') {
        newStatus = _status;
      } else if (_documentUrl != null && _documentUrl!.isNotEmpty) {
        newStatus = 'tahap 2';
      }

      final updateData = <String, dynamic>{
        'name': name,
        'address': address,
        'description': description,
        'operating_hours': operatingHours,
        'status': newStatus,
      };

      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;

      await _supabase
          .from('bengkels')
          .update(updateData)
          .eq('owner_id', id);

      _bengkelName = name;
      _bengkelAddress = address;
      _description = description;
      _operatingHours = operatingHours;
      _status = newStatus;
      if (latitude != null) _latitude = latitude;
      if (longitude != null) _longitude = longitude;
      notifyListeners();

      debugPrint('Profil bengkel berhasil diperbarui');
    } catch (e) {
      debugPrint('Error updateProfile: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateLocation(double lat, double lng, {String? userId}) async {
    setLoading(true);
    try {
      final id = userId ?? _supabase.auth.currentUser?.id;
      if (id == null) throw Exception('User tidak ditemukan.');

      String? newAddress;
      try {
        final url = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1');
        final response = await http.get(url, headers: {'User-Agent': 'BengkelinApp/1.0'});
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['display_name'] != null) {
            newAddress = data['display_name'];
          }
        }
      } catch (e) {
        debugPrint('Reverse geocoding failed: $e');
      }

      final updateData = <String, dynamic>{'latitude': lat, 'longitude': lng};
      if (newAddress != null) {
        updateData['address'] = newAddress;
        _bengkelAddress = newAddress;
      }

      await _supabase
          .from('bengkels')
          .update(updateData)
          .eq('owner_id', id);

      _latitude = lat;
      _longitude = lng;
      notifyListeners();
      debugPrint('[BengkelVM] Lokasi berhasil disimpan: $lat, $lng');
    } catch (e) {
      debugPrint('[BengkelVM] Error updateLocation: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> uploadDocument(
    String docType,
    Uint8List fileBytes,
    String fileName,
    {String? userId}
  ) async {
    setLoading(true);
    try {
      final id = userId ?? _supabase.auth.currentUser?.id;
      if (id == null)
        throw Exception('User tidak ditemukan, silakan login ulang.');

      final fileExt = fileName.split('.').last;
      final filePath =
          '$id/$docType-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      debugPrint('Uploading to bucket: bengkel_documents, path: $filePath');

      // 1. Upload binary ke Supabase Storage bucket 'bengkel_documents'
      await _supabase.storage
          .from('bengkel_documents')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      debugPrint('Upload storage berhasil');

      // 2. Ambil public URL
      final publicUrl = _supabase.storage
          .from('bengkel_documents')
          .getPublicUrl(filePath);

      debugPrint('Public URL: $publicUrl');

      // 3. Simpan URL ke kolom document_url dan ubah status ke 'tahap 2'
      await _supabase
          .from('bengkels')
          .update({
            'document_url': publicUrl,
            'status': 'tahap 2',
          })
          .eq('owner_id', id);

      _documentUrl = publicUrl;
      _status = 'tahap 2';
      notifyListeners();

      debugPrint('Update tabel bengkels berhasil');
    } catch (e) {
      debugPrint('Error uploadDocument: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }
}
