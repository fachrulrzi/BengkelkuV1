import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../customer/models/order_model.dart';
import '../../customer/models/vehicle_model.dart';

class BengkelOrdersViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  // Map to store customer vehicles by userId
  Map<String, List<VehicleModel>> _customerVehicles = {};

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetch all orders where at least one order_item belongs to our bengkel
  Future<void> fetchBengkelOrders(String bengkelId) async {
    _setLoading(true);
    try {
      debugPrint('====================================');
      debugPrint('[DEBUG] fetchBengkelOrders DIJALANKAN');
      debugPrint('[DEBUG] Target bengkelId: $bengkelId');

      final response = await _supabase
          .from('orders')
          .select('*, order_items(*, spareparts(*))')
          .order('created_at', ascending: false);

      debugPrint('[DEBUG] Jumlah raw orders dari database: ${response.length}');
      debugPrint('[DEBUG] Raw response: $response');

      final List<dynamic> data = response;
      final allOrders = data.map((e) => OrderModel.fromJson(e)).toList();

      debugPrint(
        '[DEBUG] Berhasil memetakan ke OrderModel. Jumlah: ${allOrders.length}',
      );

      // Filter orders where any of its order_items has a sparepart belonging to our bengkelId
      _orders = allOrders.where((order) {
        bool match = order.items.any((item) {
          final sBId = item.sparepart?.bengkelId;
          debugPrint(
            '[DEBUG] Memeriksa Item Order ID ${order.id}: item.sparepartId=${item.sparepartId}, item.sparepart.bengkelId=$sBId',
          );
          return sBId == bengkelId;
        });
        debugPrint('[DEBUG] Order ID ${order.id} status match: $match');
        return match;
      }).toList();

      debugPrint(
        '[DEBUG] Jumlah orders setelah difilter untuk bengkel: ${_orders.length}',
      );

      // Fetch customer vehicles for those orders
      final userIds = _orders.map((o) => o.userId).toSet().toList();
      debugPrint('[DEBUG] User IDs unik pelanggan: $userIds');
      if (userIds.isNotEmpty) {
        final vehiclesRes = await _supabase
            .from('vehicles')
            .select()
            .inFilter('user_id', userIds);

        final List<dynamic> vehiclesData = vehiclesRes;
        final List<VehicleModel> allVehicles = vehiclesData
            .map((e) => VehicleModel.fromJson(e))
            .toList();

        debugPrint(
          '[DEBUG] Berhasil memuat ${allVehicles.length} kendaraan customer',
        );

        // Group vehicles by user_id
        _customerVehicles.clear();
        for (var vehicle in allVehicles) {
          if (!_customerVehicles.containsKey(vehicle.userId)) {
            _customerVehicles[vehicle.userId] = [];
          }
          _customerVehicles[vehicle.userId]!.add(vehicle);
        }
      }
      debugPrint('====================================');
      notifyListeners();
    } catch (e, stack) {
      debugPrint('[DEBUG] ERROR saat fetchBengkelOrders: $e');
      debugPrint('[DEBUG] STACKTRACE: $stack');
    } finally {
      _setLoading(false);
    }
  }

  // Helper to get first/active vehicle of a customer
  VehicleModel? getCustomerVehicle(String userId) {
    final list = _customerVehicles[userId];
    if (list != null && list.isNotEmpty) {
      return list.first; // return first registered vehicle
    }
    return null;
  }

  // Update order status (Terima, Tolak, Selesai)
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus,
    String bengkelId,
  ) async {
    _setLoading(true);
    try {
      await _supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      // Refresh orders list
      await fetchBengkelOrders(bengkelId);
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Complete order with tracking number and photo
  Future<void> completeOrderWithShipping({
    required String orderId,
    required String trackingNumber,
    required Uint8List photoBytes,
    required String photoName,
    required String bengkelId,
  }) async {
    _setLoading(true);
    try {
      final fileExt = photoName.split('.').last;
      final filePath = 'orders/$orderId/shipping-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // 1. Upload photo to 'shipping_photos' bucket
      await _supabase.storage
          .from('shipping_photos')
          .uploadBinary(
            filePath,
            photoBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // 2. Get public url
      final publicUrl = _supabase.storage
          .from('shipping_photos')
          .getPublicUrl(filePath);

      // 3. Update orders table
      await _supabase
          .from('orders')
          .update({
            'tracking_number': trackingNumber,
            'shipping_photo_url': publicUrl,
            'status': 'Selesai',
          })
          .eq('id', orderId);

      // 4. Refresh orders list
      await fetchBengkelOrders(bengkelId);
    } catch (e) {
      debugPrint('Error completing order with shipping: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
