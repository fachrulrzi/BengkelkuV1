import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/customer_marketplace_viewmodel.dart';
import '../models/order_model.dart';
import 'midtrans_snap_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderHistoryScreen extends StatefulWidget {
  final bool showAppBar;
  const OrderHistoryScreen({super.key, this.showAppBar = true});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _activeTab = 'Semua';
  final List<String> _tabs = [
    'Semua',
    'Pending',
    'Diproses',
    'Selesai',
    'Batal',
  ];

  // Timer untuk update countdown "bayar dalam xx:mm:ss" tiap detik
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerMarketplaceViewModel>().fetchOrderHistory();
    });
    // Refresh countdown setiap detik agar sisa waktu pembayaran up-to-date.
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFF00C853);
      case 'pending':
        return Colors.amber.shade700;
      case 'diproses':
        return const Color(0xFF1B3A5E);
      case 'batal':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  // --- Helpers untuk status pembayaran Midtrans (pay later) ---

  String _paymentStatusLabel(String paymentStatus) {
    switch (paymentStatus) {
      case 'unpaid':
        return 'Belum Dibayar';
      case 'paid':
        return 'Lunas';
      case 'expired':
        return 'Pesanan Belum Dibayar';
      case 'failed':
        return 'Gagal';
      default:
        return 'Belum Dibayar';
    }
  }

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus) {
      case 'paid':
        return const Color(0xFF00C853);
      case 'unpaid':
        return Colors.orange;
      case 'expired':
        return Colors.grey;
      case 'failed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // Format sisa waktu menuju expiry: "23j 59m 59d" atau "59m 59d" atau "habis".
  String _formatRemaining(Duration d) {
    if (d.isNegative || d.inSeconds == 0) return 'Habis';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}j ${m}m ${s}d';
    } else if (m > 0) {
      return '${m}m ${s}d';
    } else {
      return '${s}d';
    }
  }

  // Label badge status di header kartu. Kalau belum dibayar, tampilkan
  // status pembayaran dulu (lebih penting daripada status order).
  String _headerBadgeLabel(OrderModel order) {
    if (!order.isPaid &&
        (order.status.toLowerCase() == 'pending' ||
            order.status.toLowerCase() == 'batal')) {
      return _paymentStatusLabel(order.paymentStatus);
    }
    return order.status;
  }

  Color _headerBadgeColor(OrderModel order) {
    if (!order.isPaid &&
        (order.status.toLowerCase() == 'pending' ||
            order.status.toLowerCase() == 'batal')) {
      return _getPaymentStatusColor(order.paymentStatus);
    }
    return _getStatusColor(order.status);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CustomerMarketplaceViewModel>();
    final orders = viewModel.orders.where((order) {
      if (_activeTab == 'Semua') return true;
      return order.status.toLowerCase() == _activeTab.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              title: const Text(
                'Riwayat Transaksi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              automaticallyImplyLeading: false,
            )
          : null,
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _tabs.map((tab) {
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
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF1B3A5E)
                            : const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Orders List
          Expanded(
            child: viewModel.isOrdersLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFF1B3A5E)),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await viewModel.fetchOrderHistory();
                    },
                    child: orders.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.2,
                              ),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 72,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Belum ada transaksi di tab $_activeTab',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return _buildOrderCard(order);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    // Safe item resolution
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final firstSparepart = firstItem?.sparepart;
    final otherItemsCount = order.items.length - 1;

    return GestureDetector(
      onTap: () => _showOrderDetailBottomSheet(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Date and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(order.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _headerBadgeColor(order).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _headerBadgeLabel(order),
                    style: TextStyle(
                      color: _headerBadgeColor(order),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.5),

            // Product Brief Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
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
                        firstSparepart?.imageUrl != null &&
                            firstSparepart!.imageUrl!.isNotEmpty
                        ? Image.network(
                            firstSparepart.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.broken_image,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                          )
                        : const Icon(Icons.image, size: 20, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),

                // Details Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstSparepart?.name ?? 'Nama Produk Tidak Tersedia',
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
                        '${firstItem?.quantity ?? 1}x  ${_formatPrice(firstItem?.price ?? 0)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (otherItemsCount > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          '+ $otherItemsCount produk lainnya',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),

            // Footer: Total Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Belanja',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _formatPrice(order.totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF152A4A),
                  ),
                ),
              ],
            ),

            // Status pembayaran (pay later) — tampilkan kalau belum dibayar /
            // kadaluarsa / gagal.
              if (order.paymentStatus == 'unpaid') ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(order.paymentStatus)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _getPaymentStatusColor(order.paymentStatus)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: _getPaymentStatusColor(order.paymentStatus),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _paymentStatusLabel(order.paymentStatus),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _getPaymentStatusColor(order.paymentStatus),
                            ),
                          ),
                          if (order.paymentExpiresAt != null) ...[
                            const Spacer(),
                            Text(
                              'Bayar dalam ${_formatRemaining(order.paymentExpiresAt!.difference(DateTime.now()))}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getPaymentStatusColor(order.paymentStatus),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pesanan belum aktif sampai pembayaran selesai. '
                        'Pembayaran bisa ditunda selama batas waktu belum habis.',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Tombol Bayar Sekarang / batalkan
              if (order.canPayLater) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B3A5E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _openPaymentUrl(order),
                        icon: const Icon(
                          Icons.payment_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: const Text(
                          'Bayar Sekarang',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B3A5E),
                          side: const BorderSide(color: Color(0xFF1B3A5E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _checkPaymentStatus(order),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text(
                          'Saya Sudah Bayar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (order.paymentStatus == 'expired') ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pesanan dibatalkan otomatis karena melewati batas waktu pembayaran.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  // Buka ulang URL Midtrans Snap untuk bayar dalam in-app WebView.
  // Setelah WebView ditutup, sinkronkan status pembayaran ke Midtrans
  // supaya order langsung berubah jadi paid/Pending kalau sukses.
  Future<void> _openPaymentUrl(OrderModel order) async {
    final url = order.paymentUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL pembayaran tidak tersedia.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Buka halaman Snap dalam in-app WebView
    final paymentResult = await Navigator.push<MidtransPaymentResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MidtransSnapScreen(
          snapUrl: url,
          orderId: order.id,
        ),
      ),
    );

    if (!mounted) return;

    // Tampilkan loader saat sinkronisasi status
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
      final viewModel = context.read<CustomerMarketplaceViewModel>();
      if (paymentResult == MidtransPaymentResult.success) {
        await viewModel.verifyAndUpdateOrderPayment(order.id);
      }
      await viewModel.fetchOrderHistory();
    } finally {
      if (mounted) Navigator.pop(context); // tutup loader
    }

    if (!mounted) return;
    if (paymentResult == MidtransPaymentResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pembayaran berhasil! Menunggu konfirmasi bengkel.'),
          backgroundColor: Color(0xFF00C853),
          duration: Duration(seconds: 4),
        ),
      );
    } else if (paymentResult == MidtransPaymentResult.pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Pembayaran sedang diproses. Cek status kembali nanti.'),
          backgroundColor: Color(0xFF1B3A5E),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // Tombol "Saya Sudah Bayar": verifikasi ke Midtrans & refresh.
  Future<void> _checkPaymentStatus(OrderModel order) async {
    final viewModel = context.read<CustomerMarketplaceViewModel>();
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
      final paid = await viewModel.verifyPaymentForOrder(order.id);
      if (mounted) Navigator.pop(context); // close loader
      await viewModel.fetchOrderHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            paid
                ? 'Pembayaran terkonfirmasi! Pesanan Anda sekarang aktif.'
                : 'Pembayaran belum terdeteksi. Silakan selesaikan pembayaran terlebih dahulu.',
          ),
          backgroundColor: paid ? const Color(0xFF00C853) : Colors.orange,
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memverifikasi pembayaran: $e')),
      );
    }
  }

  // Hapus order yang kadaluarsa/gagal dari daftar lokal (mock).
  Future<void> _cancelExpiredOrder(OrderModel order) async {
    final viewModel = context.read<CustomerMarketplaceViewModel>();
    // Untuk order DB, kita tandai sebagai Batal.
    try {
      await viewModel.markOrderCancelled(order.id);
      await viewModel.fetchOrderHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus pesanan: $e')),
      );
    }
  }

  void _showOrderDetailBottomSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        double subtotal = 0;
        for (var item in order.items) {
          subtotal += item.price * item.quantity;
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  // Header handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Detail Transaksi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _headerBadgeColor(order)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _headerBadgeLabel(order),
                            style: TextStyle(
                              color: _headerBadgeColor(order),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 16, thickness: 1),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Details Section
                        _buildDetailRow(
                          'No. Transaksi',
                          order.id.toUpperCase().substring(0, 13),
                        ),
                        _buildDetailRow(
                          'Waktu Transaksi',
                          _formatDate(order.createdAt),
                        ),
                        _buildDetailRow(
                          'Status Pembayaran',
                          _paymentStatusLabel(order.paymentStatus),
                        ),
                        if (order.paymentStatus == 'unpaid' &&
                            order.paymentExpiresAt != null)
                          _buildDetailRow(
                            'Batas Waktu Bayar',
                            order.paymentExpiresAt!.isAfter(DateTime.now())
                                ? '${_formatRemaining(order.paymentExpiresAt!.difference(DateTime.now()))} lagi'
                                : 'Sudah lewat',
                          ),
                        const Divider(height: 24, thickness: 0.5),

                        // Banner + tombol pembayaran untuk order belum dibayar
                        if (!order.isPaid) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: _getPaymentStatusColor(order.paymentStatus)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _getPaymentStatusColor(
                                  order.paymentStatus,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              order.paymentStatus == 'unpaid'
                                  ? 'Pesanan ini BELUM dibayar dan belum aktif. '
                                      'Selesaikan pembayaran sebelum batas waktu habis.'
                                  : order.paymentStatus == 'expired'
                                  ? 'Pembayaran sudah kadaluarsa.'
                                  : 'Pembayaran gagal/ditolak.',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getPaymentStatusColor(
                                  order.paymentStatus,
                                ),
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (order.canPayLater) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B3A5E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context); // tutup sheet dulu
                                  _openPaymentUrl(order);
                                },
                                icon: const Icon(
                                  Icons.payment_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Bayar Sekarang',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1B3A5E),
                                  side: const BorderSide(
                                    color: Color(0xFF1B3A5E),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _checkPaymentStatus(order);
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text(
                                  'Saya Sudah Bayar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ] else if (order.paymentStatus == 'expired' ||
                              order.paymentStatus == 'failed') ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(
                                    color: Colors.red.shade300,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _cancelExpiredOrder(order);
                                },
                                child: const Text(
                                  'Hapus Pesanan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const Divider(height: 24, thickness: 0.5),
                        ],

                        // Products Section
                        const Text(
                          'PRODUK YANG DIBELI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...order.items.map((item) {
                          final sparepart = item.sparepart;
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child:
                                        sparepart?.imageUrl != null &&
                                            sparepart!.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            sparepart.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.broken_image,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                          )
                                        : const Icon(
                                            Icons.image,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sparepart?.name ??
                                            'Nama Produk Tidak Tersedia',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.quantity}x • ${_formatPrice(item.price)}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatPrice(item.price * item.quantity),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 32, thickness: 0.5),

                        // Payment Details
                        const Text(
                          'RINCIAN PEMBAYARAN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Subtotal', _formatPrice(subtotal)),
                        if (order.discount > 0)
                          _buildSummaryRow(
                            'Diskon Voucher',
                            '- ${_formatPrice(order.discount)}',
                            valueColor: Colors.red,
                          ),
                        _buildSummaryRow(
                          'Biaya Pengiriman',
                          _formatPrice(order.shippingFee),
                        ),
                        const Divider(height: 20, thickness: 0.5),
                        _buildSummaryRow(
                          'Total Pembayaran',
                          _formatPrice(order.totalPrice),
                          isTotal: true,
                        ),
                        const Divider(height: 32, thickness: 0.5),

                        // Info Pengiriman (Resi / Bukti Kirim)
                        if (!order.isPickup && (order.trackingNumber != null || order.shippingPhotoUrl != null)) ...[
                          const Text(
                            'INFO PENGIRIMAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (order.trackingNumber != null)
                            _buildDetailRow('No. Resi Pengiriman', order.trackingNumber!),
                          if (order.shippingPhotoUrl != null) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Foto Bukti Kirim:',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                order.shippingPhotoUrl!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text('Gagal memuat foto bukti kirim', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const Divider(height: 32, thickness: 0.5),
                        ],

                        // Info Pengambilan / Ambil Sendiri (Self Pickup)
                        if (order.isPickup && order.status.toLowerCase() != 'pending' && order.status.toLowerCase() != 'batal') ...[
                          const Text(
                            'INFO PENGAMBILAN (SELF PICKUP)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Builder(builder: (context) {
                            final firstItem = order.items.isNotEmpty ? order.items.first : null;
                            final sparepart = firstItem?.sparepart;
                            final bName = sparepart?.bengkelName ?? 'Bengkel';
                            final bAddress = sparepart?.bengkelAddress ?? 'Alamat Bengkel';
                            final bLat = sparepart?.bengkelLatitude;
                            final bLng = sparepart?.bengkelLongitude;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('Nama Bengkel', bName),
                                _buildDetailRow('Alamat Pengambilan', bAddress),
                                if (bLat != null && bLng != null) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00C853), // Green
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        elevation: 0,
                                      ),
                                      onPressed: () async {
                                        final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$bLat,$bLng');
                                        try {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        } catch (_) {
                                          try {
                                            await launchUrl(url, mode: LaunchMode.platformDefault);
                                          } catch (_) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Tidak dapat membuka tautan peta')),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.location_on, color: Colors.white, size: 18),
                                      label: const Text('Buka Shareloc (Google Maps)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          }),
                          const Divider(height: 32, thickness: 0.5),
                        ],

                        // Rating & Ulasan
                        if (order.status.toLowerCase() == 'selesai') ...[
                          const Text(
                            'RATING & ULASAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (order.rating != null) ...[
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < order.rating! ? Icons.star : Icons.star_border,
                                  color: Colors.orange,
                                  size: 20,
                                );
                              }),
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
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B3A5E),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  Navigator.pop(context); // close bottom sheet
                                  _showRatingDialog(order);
                                },
                                icon: const Icon(Icons.star_border, color: Colors.white, size: 18),
                                label: const Text('Beri Rating & Ulasan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRatingDialog(OrderModel order) {
    int selectedStars = 5;
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            'Beri Rating & Ulasan',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF152A4A)),
            textAlign: TextAlign.center,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Bagaimana kualitas sparepart dan layanan bengkel ini?',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedStars = starVal;
                          });
                        },
                        child: Icon(
                          starVal <= selectedStars ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                          size: 36,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tulis ulasan Anda (opsional)...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B3A5E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                _submitReview(order, selectedStars, noteCtrl.text.trim());
              },
              child: const Text('Kirim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _submitReview(OrderModel order, int rating, String note) async {
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
      final sparepartIds = order.items.map((e) => e.sparepartId).toList();
      await context.read<CustomerMarketplaceViewModel>().submitRating(
            orderId: order.id,
            rating: rating,
            note: note.isEmpty ? null : note,
            sparepartIds: sparepartIds,
          );
      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terima kasih! Ulasan Anda telah terkirim.'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim ulasan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  valueColor ??
                  (isTotal ? const Color(0xFF152A4A) : AppColors.textPrimary),
              fontSize: isTotal ? 16 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
