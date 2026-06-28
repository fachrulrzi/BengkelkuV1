import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../customer/models/order_model.dart';
import '../../customer/models/vehicle_model.dart';
import '../viewmodels/bengkel_dashboard_viewmodel.dart';
import '../viewmodels/bengkel_orders_viewmodel.dart';

class BengkelOrdersScreen extends StatefulWidget {
  const BengkelOrdersScreen({super.key});

  @override
  State<BengkelOrdersScreen> createState() => _BengkelOrdersScreenState();
}
class _BengkelOrdersScreenState extends State<BengkelOrdersScreen> {
  String _activeTab = 'Semua';
  final List<String> _tabs = ['Semua', 'Menunggu', 'Aktif', 'Selesai'];
  String? _lastFetchedBengkelId;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dashboardVM = Provider.of<BengkelDashboardViewModel>(context);
    if (dashboardVM.bengkelId.isNotEmpty &&
        dashboardVM.bengkelId != _lastFetchedBengkelId) {
      _lastFetchedBengkelId = dashboardVM.bengkelId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<BengkelOrdersViewModel>().fetchBengkelOrders(
                dashboardVM.bengkelId,
              );
        }
      });
    }
  }

  void _refreshOrders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardVM = context.read<BengkelDashboardViewModel>();
      if (dashboardVM.bengkelId.isNotEmpty) {
        _lastFetchedBengkelId = dashboardVM.bengkelId;
        context.read<BengkelOrdersViewModel>().fetchBengkelOrders(
              dashboardVM.bengkelId,
            );
      }
    });
  }

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

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Map status in DB to filter tab
  bool _matchesTab(String statusInDb, String tab) {
    if (tab == 'Semua')
      return statusInDb.toLowerCase() != 'batal'; // show all except cancelled
    if (tab == 'Menunggu') return statusInDb.toLowerCase() == 'pending';
    if (tab == 'Aktif') return statusInDb.toLowerCase() == 'diproses';
    if (tab == 'Selesai') return statusInDb.toLowerCase() == 'selesai';
    return false;
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'diproses':
        return 'Aktif';
      case 'selesai':
        return 'Selesai';
      case 'batal':
        return 'Batal';
      default:
        return 'Menunggu';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber.shade700;
      case 'diproses':
        return Colors.blue;
      case 'selesai':
        return const Color(0xFF00C853);
      case 'batal':
        return Colors.red;
      default:
        return Colors.amber.shade700;
    }
  }

  String _getItemsSummary(OrderModel order) {
    if (order.items.isEmpty) return 'Tidak ada barang/jasa';
    // Join all items using '+' just like the design
    return order.items
        .map((item) => item.sparepart?.name ?? 'Sparepart/Jasa')
        .join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    final dashboardVM = context.watch<BengkelDashboardViewModel>();
    final ordersVM = context.watch<BengkelOrdersViewModel>();

    final filteredOrders = ordersVM.orders.where((order) {
      return _matchesTab(order.status, _activeTab);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2843),
        elevation: 0,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Container(
            width: 38, height: 38,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF2B300), Color(0xFFFF8C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                dashboardVM.bengkelName.isNotEmpty
                    ? dashboardVM.bengkelName[0].toUpperCase()
                    : 'B',
                style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            dashboardVM.bengkelName.isNotEmpty ? dashboardVM.bengkelName : 'Bengkel Saya',
            style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Title
          const Padding(
            padding: EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 12),
            child: Text(
              'Manajemen Pesanan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Horizontal Filter Tabs
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final tab = _tabs[index];
                final isActive = _activeTab == tab;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeTab = tab;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF1B3A5E)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tab,
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // List of Orders
          Expanded(
            child: ordersVM.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1B3A5E),
                      ),
                    ),
                  )
                : filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada pesanan $_activeTab',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final vehicle = ordersVM.getCustomerVehicle(order.userId);
                      return _buildOrderCard(
                        order,
                        vehicle,
                        dashboardVM.bengkelId,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    OrderModel order,
    VehicleModel? vehicle,
    String bengkelId,
  ) {
    final statusLabel = _getStatusLabel(order.status);
    final statusColor = _getStatusColor(order.status);
    final itemsSummary = _getItemsSummary(order);
    final shortOrderId =
        'ORD-${order.id.replaceAll('-', '').substring(0, 3).toUpperCase()}';
    final hasHomeService = order.shippingFee > 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header (ID, Status Badge, Home Service Badge, Total Price)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    shortOrderId,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (hasHomeService) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Home',
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                _formatPrice(order.totalPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF1B3A5E),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Customer Name & Order Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.recipientName ?? 'Customer',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(order.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),

          // Vehicle Model Description
          Text(
            vehicle != null
                ? '${vehicle.brand} ${vehicle.model} ${vehicle.year}'
                : 'Mobil/Motor Customer',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),

          const SizedBox(height: 12),

          // Items/Services Box summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.build_outlined,
                  size: 14,
                  color: Colors.black54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    itemsSummary,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons based on Status
          if (order.status.toLowerCase() == 'pending')
            if (!order.isPaid)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Menunggu Pembayaran',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF00C853,
                          ), // Green "Terima"
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () =>
                            _updateStatus(order.id, 'Diproses', bengkelId),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Terima',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50, // Soft Red "Tolak"
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.red.shade100),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () =>
                            _updateStatus(order.id, 'Batal', bengkelId),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cancel_outlined,
                              color: Colors.red,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Tolak',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
          else if (order.status.toLowerCase() == 'diproses')
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF1B3A5E,
                  ), // Dark blue "Tandai Selesai"
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  if (order.isPickup) {
                    _updateStatus(order.id, 'Selesai', bengkelId);
                  } else {
                    _showShippingDetailsDialog(order.id, bengkelId);
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Tandai Selesai',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (order.status.toLowerCase() == 'selesai') ...[
            if (order.rating != null) ...[
              const Divider(height: 24, thickness: 0.5),
              Row(
                children: [
                  const Text(
                    'Rating dari Customer: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Row(
                    children: List.generate(5, (starIdx) {
                      return Icon(
                        Icons.star,
                        size: 16,
                        color: starIdx < order.rating! ? Colors.amber : Colors.grey.shade300,
                      );
                    }),
                  ),
                ],
              ),
              if (order.ratingNote != null && order.ratingNote!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Text(
                    '"${order.ratingNote}"',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ] else ...[
              const Divider(height: 24, thickness: 0.5),
              const Row(
                children: [
                  Icon(Icons.star_outline, color: Colors.grey, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Belum ada ulasan dari customer',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showShippingDetailsDialog(String orderId, String bengkelId) {
    final trackingCtrl = TextEditingController();
    Uint8List? fileBytes;
    String? fileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Pengiriman Pesanan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: trackingCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nomor Resi / Bukti Pengiriman',
                        hintText: 'Masukkan no resi kurir...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Foto Bukti Pengiriman',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          withData: true,
                        );
                        if (result != null && result.files.single.bytes != null) {
                          setState(() {
                            fileBytes = result.files.single.bytes;
                            fileName = result.files.single.name;
                          });
                        }
                      },
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: fileBytes == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Pilih Foto Bukti Kirim', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(fileBytes!, fit: BoxFit.cover),
                              ),
                      ),
                    ),
                    if (fileName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'File terpilih: $fileName',
                        style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B3A5E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: (trackingCtrl.text.trim().isEmpty || fileBytes == null)
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _submitShipping(orderId, trackingCtrl.text.trim(), fileBytes!, fileName!, bengkelId);
                            },
                      child: const Text(
                        'Kirim & Selesai',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _submitShipping(
    String orderId,
    String trackingNumber,
    Uint8List photoBytes,
    String photoName,
    String bengkelId,
  ) async {
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
      await context.read<BengkelOrdersViewModel>().completeOrderWithShipping(
            orderId: orderId,
            trackingNumber: trackingNumber,
            photoBytes: photoBytes,
            photoName: photoName,
            bengkelId: bengkelId,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil diselesaikan dengan bukti kirim!'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyelesaikan pesanan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateStatus(String orderId, String status, String bengkelId) async {
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
      await context.read<BengkelOrdersViewModel>().updateOrderStatus(
        orderId,
        status,
        bengkelId,
      );
      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pesanan berhasil diperbarui ke status: ${_getStatusLabel(status)}',
            ),
            backgroundColor: status == 'Batal'
                ? Colors.red
                : const Color(0xFF00C853),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
