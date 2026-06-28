import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../customer/models/booking_model.dart';
import '../viewmodels/bengkel_dashboard_viewmodel.dart';
import '../viewmodels/bengkel_booking_viewmodel.dart';
import 'bengkel_booking_detail_screen.dart';

class BengkelBookingListScreen extends StatefulWidget {
  const BengkelBookingListScreen({super.key});

  @override
  State<BengkelBookingListScreen> createState() => _BengkelBookingListScreenState();
}

class _BengkelBookingListScreenState extends State<BengkelBookingListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _activeTab = 'Semua';
  final List<String> _tabs = ['Semua', 'Menunggu', 'Diproses', 'Selesai', 'Dibatalkan'];

  bool _matchesTab(String statusInDb, String tab) {
    if (tab == 'Semua') return true;
    if (tab == 'Menunggu') return statusInDb == 'Menunggu Konfirmasi';
    if (tab == 'Diproses') {
      return statusInDb == 'Diproses' ||
          statusInDb == 'Mekanik Ditugaskan' ||
          statusInDb == 'Menuju Lokasi' ||
          statusInDb == 'Sampai Lokasi' ||
          statusInDb == 'Menunggu Pembayaran Jasa' ||
          statusInDb == 'Menunggu Pembayaran Tambahan' ||
          statusInDb == 'Pembayaran Awal Lunas';
    }
    if (tab == 'Selesai') return statusInDb == 'Selesai' || statusInDb == 'Ulasan Dikirim';
    if (tab == 'Dibatalkan') return statusInDb == 'Dibatalkan' || statusInDb == 'Batal';
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BengkelBookingViewModel>().fetchBookings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }



  Color _getStatusColor(String status) {
    if (status == 'Menunggu Konfirmasi') return Colors.amber.shade700;
    if (status == 'Diproses' ||
        status == 'Mekanik Ditugaskan' ||
        status == 'Menuju Lokasi' ||
        status == 'Sampai Lokasi' ||
        status == 'Pembayaran Awal Lunas') {
      return Colors.blue;
    }
    if (status == 'Menunggu Pembayaran Jasa' || status == 'Menunggu Pembayaran Tambahan') {
      return Colors.amber.shade800;
    }
    if (status == 'Selesai' || status == 'Ulasan Dikirim') return const Color(0xFF00C853);
    if (status == 'Dibatalkan' || status == 'Batal') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final dashboardVM = context.watch<BengkelDashboardViewModel>();
    final bookingVM = context.watch<BengkelBookingViewModel>();

    final filteredBookings = bookingVM.bookings.where((booking) {
      if (!_matchesTab(booking.status, _activeTab)) return false;
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final vehicle = (booking.vehicleName ?? '').toLowerCase();
      final category = booking.serviceCategory.toLowerCase();
      final customer = (booking.customerName ?? '').toLowerCase();
      return vehicle.contains(query) || category.contains(query) || customer.contains(query);
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
            onPressed: () => context.read<BengkelBookingViewModel>().fetchBookings(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 12),
            child: Text(
              'Booking Service',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari customer, kendaraan, atau layanan...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
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
                      horizontal: 18,
                      vertical: 6,
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
          const SizedBox(height: 12),
          Expanded(
            child: bookingVM.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B3A5E)),
                    ),
                  )
                : filteredBookings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.car_repair,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada booking $_activeTab',
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
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      return _buildBookingCard(booking);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final statusColor = _getStatusColor(booking.status);
    final shortId = 'BKG-${booking.id.replaceAll('-', '').substring(0, 4).toUpperCase()}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BengkelBookingDetailScreen(booking: booking),
          ),
        ).then((_) {
          context.read<BengkelBookingViewModel>().fetchBookings();
        });
      },
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      shortId,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        booking.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (booking.isHomeService) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Home Service',
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
                  booking.bookingTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF1B3A5E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  booking.customerName ?? 'Pelanggan',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              booking.vehicleName ?? 'Kendaraan',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              booking.serviceCategory,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.bookingDate.toLocal().toString().split(' ')[0],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (booking.ratingScore != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < booking.ratingScore! ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.ratingComment != null && booking.ratingComment!.isNotEmpty
                          ? '"${booking.ratingComment}"'
                          : 'Ulasan tanpa komentar',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
