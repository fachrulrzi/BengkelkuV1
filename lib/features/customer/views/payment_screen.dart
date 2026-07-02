import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../bengkel/models/sparepart_model.dart';
import '../viewmodels/customer_marketplace_viewmodel.dart';
import '../viewmodels/customer_dashboard_viewmodel.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'customer_main_screen.dart';
import 'midtrans_snap_screen.dart';

class PaymentScreen extends StatefulWidget {
  final List<String> selectedItemIds;
  final Map<String, int>? customQuantities;

  const PaymentScreen({
    super.key,
    required this.selectedItemIds,
    this.customQuantities,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // --- Midtrans Environment & API Key Configuration ---
  // PENTING: Untuk menggunakan Sandbox, masukkan Sandbox Server Key Anda (selalu berawalan 'SB-Mid-server-').
  // Jika menggunakan Production, masukkan Production Server Key (selalu berawalan 'Mid-server-').
  static const String _midtransServerKey = String.fromEnvironment(
    'MIDTRANS_SERVER_KEY',
  );
  static const bool _isSandboxMode = true;

  String _selectedMethod = 'gopay'; // Default selection
  String _selectedBank =
      'bca'; // Default bank selection if bank transfer is selected
  bool _isPickup = false; // Shipping option state

  // Delivery coordinate state
  double? _selectedLat;
  double? _selectedLng;

  // Shipping details state
  String? _recipientName;
  String? _recipientPhone;
  String? _shippingAddress;

  String _formatPrice(double price) {
    final buffer = StringBuffer();
    final str = price.toInt().toString();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    var p = 0.017453292519943295;
    var c = cos;
    var a =
        0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  double _getDistanceKm(
    CustomerMarketplaceViewModel viewModel,
    CustomerDashboardViewModel dashboardViewModel,
  ) {
    if (widget.selectedItemIds.isEmpty) return 0.0;

    final firstItemId = widget.selectedItemIds.first;
    final product = viewModel.spareparts.firstWhere(
      (p) => p.id == firstItemId,
      orElse: () => SparepartModel(
        id: '',
        bengkelId: '',
        name: '',
        sku: '',
        category: '',
        price: 0,
        stock: 0,
        createdAt: DateTime.now(),
        compatibleBrandIds: const [],
      ),
    );

    if (product.bengkelId.isEmpty) return 0.0;

    final bengkel = dashboardViewModel.bengkels.firstWhere(
      (b) => b['id'] == product.bengkelId,
      orElse: () => {},
    );

    if (bengkel.isEmpty) return 0.0;

    // Check if coordinates exist
    final double? currentLat = _selectedLat ?? dashboardViewModel.userLat;
    final double? currentLng = _selectedLng ?? dashboardViewModel.userLng;

    if (bengkel['latitude'] != null &&
        bengkel['longitude'] != null &&
        currentLat != null &&
        currentLng != null) {
      return _calculateDistance(
        currentLat,
        currentLng,
        (bengkel['latitude'] as num).toDouble(),
        (bengkel['longitude'] as num).toDouble(),
      );
    }

    if (bengkel['distance_km'] != null) {
      return (bengkel['distance_km'] as num).toDouble();
    }

    return 0.0;
  }

  double _getShippingFee(double distanceKm) {
    if (_isPickup) return 0.0;
    if (widget.selectedItemIds.isEmpty) return 0.0;
    if (distanceKm == 0.0) return 15000.0; // fallback if distance is unknown

    final calculatedFee = distanceKm * 5000.0;
    return (calculatedFee / 1000).ceil() * 1000.0; // round to next 1000 rupiah
  }

  String _getPaymentMethodDisplayName() {
    switch (_selectedMethod) {
      case 'gopay':
        return 'GoPay';
      case 'ovo':
        return 'OVO';
      case 'dana':
        return 'DANA';
      case 'shopeepay':
        return 'ShopeePay';
      case 'card':
        return 'Credit/Debit Card';
      case 'bank_transfer':
        switch (_selectedBank) {
          case 'bca':
            return 'Bank Transfer (BCA)';
          case 'mandiri':
            return 'Bank Transfer (Mandiri)';
          case 'bni':
            return 'Bank Transfer (BNI)';
          case 'bri':
            return 'Bank Transfer (BRI)';
          case 'permata':
            return 'Bank Transfer (Permata)';
          default:
            return 'Bank Transfer';
        }
      default:
        return 'GoPay';
    }
  }

  String _generateUUID() {
    final random = Random.secure();
    final List<int> bytes = List<int>.generate(16, (_) => random.nextInt(256));

    // Set version to 4 (random)
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant to RFC 4122
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < bytes.length; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(bytes[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  List<String> _getEnabledPayments() {
    switch (_selectedMethod) {
      case 'gopay':
        return ['gopay', 'qris'];
      case 'ovo':
        return ['qris'];
      case 'dana':
        return ['qris'];
      case 'shopeepay':
        return ['shopeepay', 'qris'];
      case 'card':
        return ['credit_card'];
      case 'bank_transfer':
        switch (_selectedBank) {
          case 'bca':
            return ['bca_va'];
          case 'mandiri':
            return ['echannel'];
          case 'bni':
            return ['bni_va'];
          case 'bri':
            return ['bri_va'];
          case 'permata':
            return ['permata_va'];
          default:
            return ['bank_transfer'];
        }
      default:
        return ['gopay', 'qris', 'bank_transfer', 'credit_card'];
    }
  }

  Future<String?> _createMidtransTransaction(
    String orderId,
    double amount,
    AuthViewModel authViewModel,
  ) async {
    final String serverKey = _midtransServerKey;
    if (serverKey.trim().isEmpty) {
      throw Exception(
        'MIDTRANS_SERVER_KEY belum diset. Jalankan app dengan --dart-define=MIDTRANS_SERVER_KEY=... ',
      );
    }
    final url = _isSandboxMode
        ? 'https://app.sandbox.midtrans.com/snap/v1/transactions'
        : 'https://app.midtrans.com/snap/v1/transactions';

    final basicAuth = 'Basic ${base64Encode(utf8.encode('$serverKey:'))}';
    final user = authViewModel.currentUser;

    // Pastikan gross_amount minimal 1
    final grossAmount = amount.toInt().clamp(1, 999999999);

    // Bangun customer_details — hindari field kosong yang bisa ditolak Midtrans
    final String firstName = _isPickup
        ? 'Customer'
        : (_recipientName != null && _recipientName!.isNotEmpty
              ? _recipientName!
              : (user != null && (user.name?.isNotEmpty ?? false)
                    ? user.name!
                    : 'Customer'));
    final String email = user != null && (user.email?.isNotEmpty ?? false)
        ? user.email!
        : 'customer@bengkelin.com';
    final String? phone = _isPickup ? null : (_recipientPhone ?? user?.phone);

    final Map<String, dynamic> customerDetails = {
      'first_name': firstName,
      'email': email,
    };
    if (phone != null && phone.isNotEmpty) {
      customerDetails['phone'] = phone;
    }

    final Map<String, dynamic> body = {
      'transaction_details': {'order_id': orderId, 'gross_amount': grossAmount},
      'credit_card': {'secure': true},
      'enabled_payments': _getEnabledPayments(),
      'customer_details': customerDetails,
      'expiry': {'unit': 'minute', 'duration': 1440},
      // Callbacks: setelah bayar, Midtrans Snap redirect ke URL ini.
      // MidtransSnapScreen memonitor URL ini untuk auto-close WebView.
      'callbacks': {'finish': 'bengkelin://payment/finish'},
    };

    debugPrint('[Midtrans] POST $url');
    debugPrint('[Midtrans] Body: ${jsonEncode(body)}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
        body: jsonEncode(body),
      );

      debugPrint('[Midtrans] Status: ${response.statusCode}');
      debugPrint('[Midtrans] Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['redirect_url'];
      } else {
        // Parse error message dari Midtrans jika ada
        String errorMsg = response.body;
        try {
          final errData = jsonDecode(response.body);
          if (errData['error_messages'] is List) {
            errorMsg = (errData['error_messages'] as List).join('\n');
          }
        } catch (_) {}
        throw Exception(
          'Status ${response.statusCode}: $errorMsg\n\n'
          'Pastikan Sandbox Server Key di dashboard Midtrans sudah benar.',
        );
      }
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('[Midtrans] Exception: $e');
      throw Exception('Gagal menghubungi server Midtrans: $e');
    }
  }

  Future<void> _processPayment(
    CustomerMarketplaceViewModel viewModel,
    double calculatedTotal,
    double calculatedShipping,
  ) async {
    bool loaderShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B3A5E)),
        ),
      ),
    );

    try {
      final authViewModel = context.read<AuthViewModel>();
      final dashboardViewModel = context.read<CustomerDashboardViewModel>();
      final user = authViewModel.currentUser;
      final finalPaymentMethod = _getPaymentMethodDisplayName();
      final orderId = _generateUUID();

      // 1. Create transaction in Midtrans first
      final redirectUrl = await _createMidtransTransaction(
        orderId,
        calculatedTotal,
        authViewModel,
      );

      if (redirectUrl == null) {
        throw Exception('Gagal membuat transaksi pembayaran Midtrans.');
      }

      // Batas waktu pembayaran mengikuti Midtrans (default 24 jam).
      final paymentExpiry = DateTime.now().add(const Duration(minutes: 1440));

      // 2. Insert order ke database sebagai UNPAID (pembayaran belum selesai).
      //    Order belum dianggap aktif sampai payment_status == 'paid',
      //    tapi pembayaran BISA DITUNDA selama belum lewat expiry.
      await viewModel.checkout(
        selectedItemIds: widget.selectedItemIds,
        totalPrice: calculatedTotal,
        discount: 0.0,
        shippingFee: calculatedShipping,
        paymentMethod: finalPaymentMethod,
        recipientName: _isPickup ? '-' : (_recipientName ?? user?.name),
        recipientPhone: _isPickup ? '-' : (_recipientPhone ?? user?.phone),
        shippingAddress: _isPickup
            ? 'Ambil di Bengkel'
            : (_shippingAddress ?? user?.address),
        isPickup: _isPickup,
        customQuantities: widget.customQuantities,
        orderId: orderId,
        paymentUrl: redirectUrl,
        midtransOrderId: orderId,
        paymentExpiry: paymentExpiry,
        latitude: _isPickup
            ? null
            : (_selectedLat ?? dashboardViewModel.userLat),
        longitude: _isPickup
            ? null
            : (_selectedLng ?? dashboardViewModel.userLng),
      );

      if (mounted) {
        Navigator.pop(context); // Close loading indicator
        loaderShown = false;
      }

      // 3. Buka Midtrans Snap in-app WebView
      MidtransPaymentResult? paymentResult;
      if (mounted) {
        paymentResult = await Navigator.push<MidtransPaymentResult>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MidtransSnapScreen(snapUrl: redirectUrl, orderId: orderId),
          ),
        );
      }

      // 4. Setelah WebView ditutup, sync status dengan Midtrans
      if (mounted) {
        if (paymentResult == MidtransPaymentResult.success) {
          // Langsung update order status ke paid
          await viewModel.verifyAndUpdateOrderPayment(orderId);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Pembayaran berhasil! Menunggu konfirmasi bengkel.',
              ),
              backgroundColor: Colors.blue,
            ),
          );
        } else if (paymentResult == MidtransPaymentResult.pending) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⏳ Pembayaran sedang diproses. Cek status di menu Pesanan.',
              ),
              backgroundColor: Colors.blue,
            ),
          );
        } else {
          // Cancelled / failed — tetap simpan order sbg unpaid
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Order tersimpan. Selesaikan pembayaran lewat menu Pesanan.',
              ),
              backgroundColor: Colors.blue,
            ),
          );
        }

        // Redirect ke halaman Order History (tab 2)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const CustomerMainScreen(initialIndex: 2),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        if (loaderShown) {
          Navigator.pop(context);
        }
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Pembayaran Gagal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF152A4A),
              ),
            ),
            content: Text(
              'Terjadi kesalahan saat memproses pembayaran:\n\n$e\n\nSilakan coba lagi.',
              style: const TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(
                    color: Color(0xFF1B3A5E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CustomerMarketplaceViewModel>();
    final dashboardViewModel = context.watch<CustomerDashboardViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    final List<SparepartModel> checkoutItems = viewModel.spareparts
        .where((item) => widget.selectedItemIds.contains(item.id))
        .toList();

    // Calculate Subtotal dynamically
    double subtotal = 0;
    for (var item in checkoutItems) {
      final qty = widget.customQuantities != null
          ? (widget.customQuantities![item.id] ?? 1)
          : (viewModel.cart[item.id] ?? 1);
      subtotal += item.price * qty;
    }

    double distanceKm = _getDistanceKm(viewModel, dashboardViewModel);
    double shippingFee = _getShippingFee(distanceKm);
    double total = subtotal + shippingFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Payment',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Shipping options switch (Ambil vs Kirim)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Opsi Pengambilan/Pengiriman',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPickup = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isPickup
                                  ? const Color(0xFF1B3A5E)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Kirim ke Alamat',
                              style: TextStyle(
                                color: !_isPickup
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPickup = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isPickup
                                  ? const Color(0xFF1B3A5E)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Ambil Sendiri',
                              style: TextStyle(
                                color: _isPickup
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (!_isPickup) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF1B3A5E),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Shipping Address',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => _showEditAddressBottomSheet(context),
                          child: const Text(
                            'Change',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _recipientName ?? user?.name ?? 'Budi Santoso',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _recipientPhone ?? user?.phone ?? '+62 812 3456 7890',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _shippingAddress ??
                          user?.address ??
                          'Jl. Sudirman No. 123, RT 001/RW 002\nJakarta Selatan, DKI Jakarta\n12190',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ] else ...[
                    const Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          color: Color(0xFF1B3A5E),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ambil Sendiri di Bengkel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pesanan Anda akan diambil secara langsung di lokasi bengkel terkait setelah statusnya diproses/selesai.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Order Items Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xFF1B3A5E),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Order Items (${widget.selectedItemIds.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: checkoutItems.length,
                    itemBuilder: (context, index) {
                      final item = checkoutItems[index];
                      final qty = widget.customQuantities != null
                          ? (widget.customQuantities![item.id] ?? 1)
                          : (viewModel.cart[item.id] ?? 1);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    item.imageUrl != null &&
                                        item.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.broken_image,
                                                  size: 20,
                                                  color: Colors.grey,
                                                ),
                                      )
                                    : const Icon(
                                        Icons.image,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'x$qty',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatPrice(item.price * qty),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Select Payment Method Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentOption(
                    'gopay',
                    'GoPay',
                    'Instant',
                    Icons.qr_code_scanner_outlined,
                    Colors.green,
                  ),
                  _buildPaymentOption(
                    'ovo',
                    'OVO',
                    'Instant',
                    Icons.account_balance_wallet_outlined,
                    Colors.purple,
                  ),
                  _buildPaymentOption(
                    'dana',
                    'DANA',
                    'Instant',
                    Icons.payment_outlined,
                    Colors.blue,
                  ),
                  _buildPaymentOption(
                    'shopeepay',
                    'ShopeePay',
                    'Instant',
                    Icons.shopping_bag_outlined,
                    Colors.orange,
                  ),
                  _buildPaymentOption(
                    'card',
                    'Credit/Debit Card',
                    'Secure',
                    Icons.credit_card_outlined,
                    Colors.teal,
                  ),
                  _buildPaymentOption(
                    'bank_transfer',
                    'Bank Transfer',
                    '1-2 Hours',
                    Icons.account_balance_outlined,
                    Colors.blueGrey,
                  ),

                  if (_selectedMethod == 'bank_transfer') ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 36.0,
                        top: 8,
                        bottom: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'Pilih Bank Transfer (Midtrans)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildBankSubOption(
                            'bca',
                            'BCA Virtual Account',
                            'BCA',
                          ),
                          _buildBankSubOption(
                            'mandiri',
                            'Mandiri Bill Payment',
                            'MND',
                          ),
                          _buildBankSubOption(
                            'bni',
                            'BNI Virtual Account',
                            'BNI',
                          ),
                          _buildBankSubOption(
                            'bri',
                            'BRI Virtual Account',
                            'BRI',
                          ),
                          _buildBankSubOption(
                            'permata',
                            'Permata Virtual Account',
                            'PRM',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Order Summary breakdown card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    'Subtotal (${widget.selectedItemIds.length} items)',
                    _formatPrice(subtotal),
                  ),
                  _buildSummaryRow(
                    _isPickup
                        ? 'Shipping Fee (Ambil Sendiri)'
                        : 'Shipping Fee${distanceKm > 0 ? ' (~${distanceKm.toStringAsFixed(1)} km)' : ''}',
                    _formatPrice(shippingFee),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payment',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _formatPrice(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF152A4A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Payment',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _formatPrice(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF152A4A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3A5E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () =>
                      _processPayment(viewModel, total, shippingFee),
                  child: const Text(
                    'Pay Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String id,
    String title,
    String tag,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1B3A5E).withValues(alpha: 0.03)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B3A5E) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF1B3A5E),
                size: 20,
              )
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankSubOption(String id, String name, String code) {
    final isSelected = _selectedBank == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBank = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1B3A5E).withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B3A5E) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF1B3A5E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                code,
                style: const TextStyle(
                  color: Color(0xFF1B3A5E),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Radio<String>(
              value: id,
              groupValue: _selectedBank,
              activeColor: const Color(0xFF1B3A5E),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedBank = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAddressBottomSheet(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();
    final user = authViewModel.currentUser;

    final nameCtrl = TextEditingController(text: user?.name ?? 'Budi Santoso');
    final phoneCtrl = TextEditingController(
      text: user?.phone ?? '+62 812 3456 7890',
    );
    final addressCtrl = TextEditingController(
      text:
          user?.address ??
          'Jl. Sudirman No. 123, RT 001/RW 002, Jakarta Selatan, DKI Jakarta 12190',
    );

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final dashboardViewModel = ctx.read<CustomerDashboardViewModel>();
        double? tempLat = _selectedLat ?? dashboardViewModel.userLat;
        double? tempLng = _selectedLng ?? dashboardViewModel.userLng;
        bool isMapLoading = false;
        final MapController addressMapController = MapController();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ubah Alamat Pengiriman',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Divider(height: 24),

                      const Text(
                        'Nama Penerima',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          hintText: 'Masukkan nama penerima',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Nomor Telepon',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Masukkan nomor telepon',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'No. telepon tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Alamat Lengkap',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: addressCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Masukkan alamat lengkap pengiriman',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Alamat tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Titik Koordinat Pengiriman',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              try {
                                setModalState(() {
                                  isMapLoading = true;
                                });
                                LocationPermission permission =
                                    await Geolocator.checkPermission();
                                if (permission == LocationPermission.denied) {
                                  permission =
                                      await Geolocator.requestPermission();
                                }
                                if (permission ==
                                        LocationPermission.whileInUse ||
                                    permission == LocationPermission.always) {
                                  final pos =
                                      await Geolocator.getCurrentPosition();
                                  final latLng = LatLng(
                                    pos.latitude,
                                    pos.longitude,
                                  );
                                  setModalState(() {
                                    tempLat = pos.latitude;
                                    tempLng = pos.longitude;
                                  });
                                  addressMapController.move(latLng, 15.0);
                                }
                              } catch (e) {
                                debugPrint('Gagal mengambil lokasi: $e');
                              } finally {
                                setModalState(() {
                                  isMapLoading = false;
                                });
                              }
                            },
                            icon: const Icon(
                              Icons.my_location,
                              size: 14,
                              color: Colors.blue,
                            ),
                            label: const Text(
                              'Lokasi Saya',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              FlutterMap(
                                mapController: addressMapController,
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    tempLat ?? -6.2000,
                                    tempLng ?? 106.8166,
                                  ),
                                  initialZoom: 15.0,
                                  onTap: (tapPosition, latLng) {
                                    setModalState(() {
                                      tempLat = latLng.latitude;
                                      tempLng = latLng.longitude;
                                    });
                                    addressMapController.move(
                                      latLng,
                                      addressMapController.camera.zoom,
                                    );
                                  },
                                  onPositionChanged: (position, hasGesture) {
                                    if (hasGesture && position.center != null) {
                                      setModalState(() {
                                        tempLat = position.center!.latitude;
                                        tempLng = position.center!.longitude;
                                      });
                                    }
                                  },
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName:
                                        'com.example.bengkelin_app',
                                  ),
                                ],
                              ),
                              const IgnorePointer(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 24),
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                              if (isMapLoading)
                                Container(
                                  color: Colors.black12,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (tempLat != null && tempLng != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Koordinat Terpilih: ${tempLat!.toStringAsFixed(6)}, ${tempLng!.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B3A5E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              showDialog(
                                context: ctx,
                                barrierDismissible: false,
                                builder: (dialogCtx) => const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF1B3A5E),
                                    ),
                                  ),
                                ),
                              );

                              try {
                                await authViewModel.updateProfile(
                                  name: nameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                );
                                await authViewModel.updateAddress(
                                  addressCtrl.text.trim(),
                                );

                                if (ctx.mounted) {
                                  Navigator.pop(ctx); // Pop progress dialog
                                  Navigator.pop(ctx); // Close bottom sheet

                                  setState(() {
                                    _recipientName = nameCtrl.text.trim();
                                    _recipientPhone = phoneCtrl.text.trim();
                                    _shippingAddress = addressCtrl.text.trim();
                                    _selectedLat = tempLat;
                                    _selectedLng = tempLng;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Alamat berhasil diperbarui!',
                                      ),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  Navigator.pop(ctx); // Pop progress dialog
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Gagal menyimpan alamat: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          child: const Text(
                            'Simpan Alamat',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
