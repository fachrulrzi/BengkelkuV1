import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/customer_booking_viewmodel.dart';
import '../models/booking_model.dart';
import 'booking_detail_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  String _selectedStatus = 'Semua';
  final List<String> _statuses = ['Semua', 'Pending', 'Diproses', 'Selesai', 'Batal'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerBookingViewModel>().fetchBookings();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'ulasan dikirim':
        return const Color(0xFF00C853);
      case 'menunggu konfirmasi':
      case 'pending':
        return Colors.amber.shade700;
      case 'diterima':
      case 'diproses':
        return const Color(0xFF1B3A5E);
      case 'dibatalkan':
      case 'batal':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  bool _matchesStatusFilter(String bookingStatus, String filter) {
    if (filter == 'Semua') return true;
    final statusLower = bookingStatus.toLowerCase();
    final filterLower = filter.toLowerCase();

    if (filterLower == 'pending') {
      return statusLower == 'pending' || statusLower.contains('menunggu konfirmasi') || statusLower.contains('konfirmasi');
    }
    if (filterLower == 'diproses') {
      return statusLower == 'diterima' || statusLower.contains('proses') || statusLower.contains('mekanik') || statusLower.contains('menuju');
    }
    if (filterLower == 'selesai') {
      return statusLower == 'selesai' || statusLower.contains('ulasan');
    }
    if (filterLower == 'batal') {
      return statusLower == 'batal' || statusLower.contains('batal') || statusLower.contains('dibatalkan');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bookingVM = context.watch<CustomerBookingViewModel>();
    final bookings = bookingVM.bookings;
    final filteredBookings = bookings.where((b) => _matchesStatusFilter(b.status, _selectedStatus)).toList();

    return Column(
      children: [
        // Horizontal Filter Chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _statuses.map((status) {
                final isSelected = _selectedStatus == status;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? null
                          : Border.all(color: const Color(0xFFE5E5E5)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF8C8C8C),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Booking List
        Expanded(
          child: bookingVM.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => context.read<CustomerBookingViewModel>().fetchBookings(),
                  child: filteredBookings.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.2,
                            ),
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 72,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Belum ada riwayat booking servis',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredBookings.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final booking = filteredBookings[index];
                            return _buildBookingCard(booking);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingDetailScreen(booking: booking),
          ),
        ).then((_) {
          context.read<CustomerBookingViewModel>().fetchBookings();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                    const Icon(Icons.store, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      booking.bengkelName ?? 'Bengkel',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.border),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.build_circle_outlined, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceCategory,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kendaraan: ${booking.vehicleName ?? '-'} (${booking.vehiclePoliceNumber ?? '-'})',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jadwal: ${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year} | ${booking.bookingTime}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (booking.complaint != null && booking.complaint!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Keluhan: ${booking.complaint}',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Ketuk untuk lihat detail', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
