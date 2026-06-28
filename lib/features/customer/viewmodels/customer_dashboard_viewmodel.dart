import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class CustomerDashboardViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _bengkels = [];
  List<Map<String, dynamic>> get bengkels => _bengkels;

  double? _userLat;
  double? get userLat => _userLat;

  double? _userLng;
  double? get userLng => _userLng;

  bool _hasLocation = false;
  bool get hasLocation => _hasLocation;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[GPS] Location services are disabled.');
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[GPS] Location permissions are denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[GPS] Location permissions are permanently denied.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('[GPS] Error determining position: $e');
      return null;
    }
  }

  Future<void> fetchBengkels() async {
    setLoading(true);
    _hasLocation = false;
    try {
      debugPrint('====================================');
      debugPrint('[DEBUG] fetchBengkels DIJALANKAN (Dengan Deteksi Lokasi)');

      final position = await _determinePosition();
      List<dynamic> data = [];

      if (position != null) {
        _userLat = position.latitude;
        _userLng = position.longitude;
        _hasLocation = true;
        debugPrint('[GPS] User Location: $_userLat, $_userLng');

        // Panggil RPC find_nearby_bengkels
        try {
          final response = await _supabase.rpc('find_nearby_bengkels', params: {
            'customer_lat': _userLat,
            'customer_lng': _userLng,
            'radius_km': 100.0,
          });
          data = response as List<dynamic>;
          debugPrint('[RPC] Berhasil memanggil find_nearby_bengkels. Jumlah: ${data.length}');

          bool needsEnrichment = false;
          if (data.isNotEmpty && data.first is Map && (data.first as Map)['reviews_count'] == null) {
            needsEnrichment = true;
          }

          if (needsEnrichment) {
            data = await _enrichBengkelsWithCombinedRatings(data);
          } else {
            // Convert each map to Map<String, dynamic> explicitly to prevent runtime issues
            data = data.map((b) => Map<String, dynamic>.from(b as Map)).toList();
          }
        } catch (rpcError) {
          debugPrint('[RPC] Gagal memanggil RPC find_nearby_bengkels: $rpcError. Fallback ke standard select.');
          // Fallback ke select biasa
          final fallbackData = await _supabase
              .from('bengkels')
              .select()
              .inFilter('status', ['diterima', 'active']);
          data = await _enrichBengkelsWithCombinedRatings(fallbackData);
        }
      } else {
        debugPrint('[GPS] Posisi tidak didapatkan, fetch standard...');
        final fallbackData = await _supabase
            .from('bengkels')
            .select()
            .inFilter('status', ['diterima', 'active']);
        data = await _enrichBengkelsWithCombinedRatings(fallbackData);
      }

      _bengkels = List<Map<String, dynamic>>.from(data);
    } catch (e, stack) {
      debugPrint('[DEBUG] ERROR saat fetchBengkels: $e');
      debugPrint('[DEBUG] STACKTRACE: $stack');
      _loadMockBengkels();
    } finally {
      if (_bengkels.isEmpty) {
        debugPrint(
          '[DEBUG] Data bengkels dari Supabase kosong, memuat Mock Bengkels (Dummy)...',
        );
        _loadMockBengkels();
      } else {
        debugPrint(
          '[DEBUG] Menggunakan data bengkels asli dari database (Jumlah: ${_bengkels.length})',
        );
      }
      debugPrint('====================================');
      setLoading(false);
    }
  }

  void _loadMockBengkels() {
    _bengkels = [
      {
        'id': 'mock-b-1',
        'name': 'AutoCare Pro',
        'address': 'Jl. Sudirman No. 123, Jakarta',
        'specialization': ['Hanya Mobil'],
        'status': 'diterima',
        'rating': 4.8,
        'reviews_count': 256,
        'distance_km': 1.2,
        'latitude': -6.2088,
        'longitude': 106.8456,
        'image_url':
            'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&q=80&w=200',
        'services': ['Engine Service', 'Oil Change', 'Brake Service'],
      },
      {
        'id': 'mock-b-2',
        'name': 'Moto Expert',
        'address': 'Jl. Gatot Subroto No. 45, Jakarta',
        'specialization': ['Hanya Motor'],
        'status': 'diterima',
        'rating': 4.6,
        'reviews_count': 189,
        'distance_km': 2.5,
        'latitude': -6.2288,
        'longitude': 106.8156,
        'image_url':
            'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&q=80&w=200',
        'services': ['Engine Tuning', 'Tire Replacement', 'Chain Service'],
      },
      {
        'id': 'mock-b-3',
        'name': 'Speed Garage',
        'address': 'Jl. Thamrin No. 78, Jakarta',
        'specialization': ['Mobil & Motor'],
        'status': 'diterima',
        'rating': 4.9,
        'reviews_count': 421,
        'distance_km': 3.1,
        'latitude': -6.1888,
        'longitude': 106.8356,
        'image_url':
            'https://images.unsplash.com/photo-1562591176-b3336cc04f4e?auto=format&fit=crop&q=80&w=200',
        'services': ['Full Service', 'Detailing', 'Body Repair'],
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _enrichBengkelsWithCombinedRatings(List<dynamic> bengkelsList) async {
    if (bengkelsList.isEmpty) return [];

    final List<Map<String, dynamic>> enrichedData = [];
    final bengkelIds = bengkelsList
        .map((b) => b['id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toList();

    if (bengkelIds.isEmpty) {
      return bengkelsList.map((b) => Map<String, dynamic>.from(b as Map)).toList();
    }

    // 1. Fetch service bookings ratings
    List<dynamic> allBookings = [];
    try {
      final bookingsResponse = await _supabase
          .from('service_bookings')
          .select('bengkel_id, rating_score')
          .inFilter('bengkel_id', bengkelIds)
          .not('rating_score', 'is', null);
      allBookings = bookingsResponse as List;
    } catch (e) {
      debugPrint('[Combined Rating VM] Gagal fetch service bookings: $e');
    }

    // 2. Fetch order ratings
    List<dynamic> allOrderItems = [];
    try {
      final orderItemsResponse = await _supabase
          .from('order_items')
          .select('order_id, orders(rating), spareparts(bengkel_id)');
      allOrderItems = orderItemsResponse as List;
    } catch (e) {
      debugPrint('[Combined Rating VM] Gagal fetch order items: $e');
    }

    // Map of bengkelId -> Map of orderId -> rating
    final Map<String, Map<String, double>> workshopOrderRatings = {};

    for (var item in allOrderItems) {
      final order = item['orders'];
      final sparepart = item['spareparts'];
      final orderId = item['order_id']?.toString();
      if (order != null && sparepart != null && orderId != null) {
        final ratingVal = order['rating'];
        final bId = sparepart['bengkel_id']?.toString();
        if (ratingVal != null && bId != null && bengkelIds.contains(bId)) {
          final ratingDouble = (ratingVal as num).toDouble();
          workshopOrderRatings.putIfAbsent(bId, () => {})[orderId] = ratingDouble;
        }
      }
    }

    for (var b in bengkelsList) {
      final bengkelId = b['id']?.toString() ?? '';
      
      // Get service ratings for this workshop
      final serviceRatings = allBookings
          .where((bk) => bk['bengkel_id'] == bengkelId)
          .map((bk) => (bk['rating_score'] as num).toDouble())
          .toList();

      // Get marketplace/order ratings for this workshop
      final orderRatingsMap = workshopOrderRatings[bengkelId] ?? {};
      final orderRatings = orderRatingsMap.values.toList();

      // Combine them
      final allRatings = [...serviceRatings, ...orderRatings];

      double rating = 4.5;
      int reviewsCount = 0;
      if (allRatings.isNotEmpty) {
        final sum = allRatings.reduce((a, b) => a + b);
        rating = double.parse((sum / allRatings.length).toStringAsFixed(1));
        reviewsCount = allRatings.length;
      }

      final map = Map<String, dynamic>.from(b as Map);
      map['rating'] = rating;
      map['reviews_count'] = reviewsCount;
      enrichedData.add(map);
    }

    return enrichedData;
  }

  List<Map<String, dynamic>> _frequentBengkels = [];
  List<Map<String, dynamic>> get frequentBengkels => _frequentBengkels;

  Future<void> fetchFrequentlyVisitedBengkels() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('service_bookings')
          .select('bengkel_id, bengkels(*)');

      final List<dynamic> data = response;
      if (data.isEmpty) {
        _frequentBengkels = [];
        notifyListeners();
        return;
      }
      
      // Map of bengkel_id -> Map representing bengkel info
      final Map<String, Map<String, dynamic>> workshopMap = {};
      // Map of bengkel_id -> booking count
      final Map<String, int> bookingCounts = {};

      for (var item in data) {
        final bId = item['bengkel_id']?.toString();
        final bData = item['bengkels'];
        if (bId != null && bData != null) {
          final bMap = Map<String, dynamic>.from(bData as Map);
          workshopMap[bId] = bMap;
          bookingCounts[bId] = (bookingCounts[bId] ?? 0) + 1;
        }
      }

      // Sort by booking count descending
      final sortedBengkelIds = bookingCounts.keys.toList()
        ..sort((a, b) => bookingCounts[b]!.compareTo(bookingCounts[a]!));

      final List<Map<String, dynamic>> list = [];
      for (var bId in sortedBengkelIds) {
        final b = workshopMap[bId]!;
        // Enrich rating/reviews count
        final enrichedList = await _enrichBengkelsWithCombinedRatings([b]);
        if (enrichedList.isNotEmpty) {
          final enriched = enrichedList.first;
          enriched['total_bookings'] = bookingCounts[bId];
          list.add(enriched);
        }
      }

      _frequentBengkels = list;
      notifyListeners();
    } catch (e) {
      debugPrint('[DEBUG] Error fetching frequent bengkels: $e');
    }
  }
}
