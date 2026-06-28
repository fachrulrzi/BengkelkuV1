import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../models/booking_model.dart';
import '../viewmodels/customer_booking_viewmodel.dart';
import '../../shared/views/chat_screen.dart';
import 'transaction_payment_screen.dart';
import 'mekanik_tracking_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final BookingModel booking;
  
  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();
  final _mechanicNameController = TextEditingController();
  bool _isRatingSubmitting = false;

  String _getBookingScheduleText(BookingModel booking) {
    final dateStr = booking.bookingDate.toLocal().toString().split(' ')[0];
    final startStr = booking.bookingTime;
    
    final startParts = startStr.split(':');
    if (startParts.length != 2) return '$dateStr | $startStr';
    
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final duration = booking.estimatedDuration;
    final endMinutes = startMinutes + duration;
    
    final endHours = (endMinutes ~/ 60) % 24;
    final endMins = endMinutes % 60;
    
    final endHoursStr = endHours.toString().padLeft(2, '0');
    final endMinsStr = endMins.toString().padLeft(2, '0');
    
    return '$dateStr | $startStr - $endHoursStr:$endMinsStr (${duration} menit)';
  }

  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _mechanicNameController.text = widget.booking.mechanicName ?? '';
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _commentController.dispose();
    _mechanicNameController.dispose();
    super.dispose();
  }

  Widget _buildPaymentExpiresAtCountdown(BookingModel booking) {
    if (booking.paymentExpiresAt == null) return const SizedBox.shrink();
    final remaining = booking.paymentExpiresAt!.difference(DateTime.now());
    if (remaining.isNegative) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 8.0),
        child: Text(
          'Batas waktu pembayaran habis.',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
    }
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        'Batas waktu pembayaran: ${hours}j ${minutes}m lagi',
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Selesai':
      case 'Ulasan Dikirim':
      case 'Pembayaran Awal Lunas':
        return const Color(0xFF00C853);
      case 'Menunggu Konfirmasi':
        return Colors.amber.shade700;
      case 'Menunggu Pembayaran Jasa':
      case 'Menunggu Pembayaran Tambahan':
        return Colors.deepOrange;
      case 'Diproses':
      case 'Mekanik Ditugaskan':
        return Colors.blue;
      case 'Menuju Lokasi':
        return Colors.purple;
      case 'Sampai Lokasi':
        return Colors.teal;
      case 'Dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingVM = context.watch<CustomerBookingViewModel>();
    
    // Cari booking terbaru dari list agar terupdate secara real-time
    final activeBooking = bookingVM.bookings.firstWhere(
      (b) => b.id == widget.booking.id,
      orElse: () => widget.booking,
    );

    final hasMechanic = activeBooking.mechanicId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Booking', style: TextStyle(color: Color(0xFF1B3A5E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1B3A5E)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    bookingId: activeBooking.id,
                    isBengkel: false,
                    receiverId: activeBooking.bengkelId,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => bookingVM.fetchBookings(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Status Card
              Container(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status Pesanan', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          activeBooking.status,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _getStatusColor(activeBooking.status),
                          ),
                        ),
                      ],
                    ),
                    if (activeBooking.isHomeService)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🏠 Home Service',
                          style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🏭 Walk-in',
                          style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Alur Pembayaran Awal / Jasa DP
              if (activeBooking.status == 'Menunggu Pembayaran Jasa') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konfirmasi Bengkel: Tersedia!',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jadwal Anda dikonfirmasi. Harap selesaikan pembayaran biaya layanan awal sebesar Rp ${activeBooking.initialPaymentAmount} agar mekanik dikirim.',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentExpiresAtCountdown(activeBooking),
                      const SizedBox(height: 4),
                      if (activeBooking.paymentUrl != null && activeBooking.paymentUrl!.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B3A5E),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    final uri = Uri.parse(activeBooking.paymentUrl!);
                                    try {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    } catch (_) {
                                      await launchUrl(uri, mode: LaunchMode.platformDefault);
                                    }
                                  },
                                  icon: const Icon(Icons.payment),
                                  label: const Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1B3A5E),
                                  side: const BorderSide(color: Color(0xFF1B3A5E)),
                                ),
                                onPressed: () async {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Memverifikasi pembayaran...')),
                                  );
                                  await context.read<CustomerBookingViewModel>().fetchBookings();
                                },
                                child: const Icon(Icons.refresh),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B3A5E),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransactionPaymentScreen(
                                    booking: activeBooking,
                                    isInitial: true,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Bayar Jasa Layanan', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Alur Mekanik OTW & Live Tracking
              if (activeBooking.status == 'Menuju Lokasi') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    border: Border.all(color: Colors.purple.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mekanik Sedang Menuju Lokasi Anda!',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Mekanik Anda sedang mengendarai motor menuju alamat Anda. Silakan pantau rute perjalanannya secara live.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Lacak Mekanik (Live Tracking)', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MekanikTrackingScreen(booking: activeBooking),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Mekanik Info Box
              if (hasMechanic) ...[
                const Text('Mekanik Anda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3A5E))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF1B3A5E).withValues(alpha: 0.1),
                        radius: 24,
                        child: const Icon(Icons.engineering, color: Color(0xFF1B3A5E), size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeBooking.mechanicName ?? 'Mekanik Ditugaskan',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3A5E)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activeBooking.status == 'Menuju Lokasi'
                                  ? 'Mekanik sedang berkendara ke alamat Anda'
                                  : activeBooking.status == 'Sampai Lokasi'
                                      ? 'Mekanik telah sampai di lokasi Anda'
                                      : 'Mekanik ditugaskan mengerjakan kendaraan',
                              style: TextStyle(fontSize: 12, color: _getStatusColor(activeBooking.status)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Detail Booking Info
              const Text('Detail Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3A5E))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildRow('Nama Bengkel', activeBooking.bengkelName ?? '-'),
                    const Divider(height: 20),
                    _buildRow('Jenis Layanan', activeBooking.serviceCategory),
                    const Divider(height: 20),
                    _buildRow('Nama Kendaraan', activeBooking.vehicleName ?? '-'),
                    const Divider(height: 20),
                    _buildRow('Nomor Polisi', activeBooking.vehiclePoliceNumber ?? '-'),
                    const Divider(height: 20),
                    _buildRow('Jadwal Booking', _getBookingScheduleText(activeBooking)),
                    if (activeBooking.isHomeService) ...[
                      const Divider(height: 20),
                      _buildRow('Biaya Ongkir (Kunjungan)', 'Rp ${activeBooking.homeServiceFee}'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Alur Pembayaran Tambahan & Laporan Bengkel
              if (activeBooking.serviceReport != null && activeBooking.serviceReport!.isNotEmpty) ...[
                const Text('Laporan Servis & Biaya Tambahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3A5E))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: activeBooking.status == 'Menunggu Pembayaran Tambahan'
                        ? Colors.deepOrange.shade50
                        : Colors.white,
                    border: Border.all(
                      color: activeBooking.status == 'Menunggu Pembayaran Tambahan'
                          ? Colors.deepOrange.shade200
                          : Colors.grey.shade200,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeBooking.status == 'Menunggu Pembayaran Tambahan'
                            ? 'Pekerjaan Selesai - Butuh Biaya Tambahan'
                            : 'Pekerjaan Selesai',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: activeBooking.status == 'Menunggu Pembayaran Tambahan'
                              ? Colors.deepOrange
                              : Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Laporan Pengerjaan:\n${activeBooking.serviceReport ?? "-"}',
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tagihan Tambahan: Rp ${activeBooking.additionalPrice}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: activeBooking.status == 'Menunggu Pembayaran Tambahan'
                              ? Colors.deepOrange
                              : Colors.black87,
                        ),
                      ),
                      if (activeBooking.serviceProofUrl != null && activeBooking.serviceProofUrl!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Bukti Foto Pengerjaan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            activeBooking.serviceProofUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ],
                      if (activeBooking.status == 'Menunggu Pembayaran Tambahan') ...[
                        const Divider(height: 24),
                        _buildPaymentExpiresAtCountdown(activeBooking),
                        const SizedBox(height: 4),
                        if (activeBooking.paymentUrl != null && activeBooking.paymentUrl!.isNotEmpty) ...[
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepOrange,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      final uri = Uri.parse(activeBooking.paymentUrl!);
                                      try {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      } catch (_) {
                                        await launchUrl(uri, mode: LaunchMode.platformDefault);
                                      }
                                    },
                                    icon: const Icon(Icons.payment),
                                    label: const Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.deepOrange,
                                    side: const BorderSide(color: Colors.deepOrange),
                                  ),
                                  onPressed: () async {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Memverifikasi pembayaran...')),
                                    );
                                    await context.read<CustomerBookingViewModel>().fetchBookings();
                                  },
                                  child: const Icon(Icons.refresh),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TransactionPaymentScreen(
                                      booking: activeBooking,
                                      isInitial: false,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Bayar Tagihan Tambahan', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Alur Rating & Ulasan (Jika Selesai)
              if (activeBooking.status == 'Selesai') ...[
                const Text('Ulas Pengerjaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3A5E))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bagaimana servis Anda? Berikan penilaian untuk bengkel & mekanik:',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final score = index + 1;
                          return IconButton(
                            icon: Icon(
                              _selectedRating >= score ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 36,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedRating = score;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _mechanicNameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Mekanik',
                          labelStyle: const TextStyle(fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _commentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Komentar / Ulasan',
                          labelStyle: const TextStyle(fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          hintText: 'Tulis tanggapan Anda tentang pelayanan kami...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B3A5E),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isRatingSubmitting
                              ? null
                              : () async {
                                  setState(() => _isRatingSubmitting = true);
                                  try {
                                    await bookingVM.submitBookingReview(
                                      bookingId: activeBooking.id,
                                      mechanicId: activeBooking.mechanicId ?? '',
                                      mechanicName: _mechanicNameController.text.trim(),
                                      rating: _selectedRating,
                                      comment: _commentController.text.trim(),
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Ulasan berhasil dikirim! Terima kasih. 🌟'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Gagal mengirim ulasan: $e')),
                                      );
                                    }
                                  } finally {
                                    if (mounted) setState(() => _isRatingSubmitting = false);
                                  }
                                },
                          child: _isRatingSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Kirim Ulasan', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Ulasan Sudah Dikirim
              if (activeBooking.status == 'Ulasan Dikirim') ...[
                const Text('Ulasan Anda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3A5E))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Ulasan Terkirim (${activeBooking.ratingScore} Bintang)',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Komentar: ${activeBooking.ratingComment ?? "-"}',
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      if (activeBooking.ratingMechanicName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Mekanik: ${activeBooking.ratingMechanicName}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Laporan Servis Biasa (Jika Selesai atau Ulasan Dikirim)
              if ((activeBooking.status == 'Selesai' || activeBooking.status == 'Ulasan Dikirim') &&
                  activeBooking.serviceReport != null) ...[
                const Text('Laporan Hasil Servis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3A5E))),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeBooking.serviceReport!,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      if (activeBooking.serviceProofUrl != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            activeBooking.serviceProofUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Biaya:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3A5E))),
                          Text(
                            'Rp ${activeBooking.totalPrice ?? 0}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B3A5E)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Batalkan Booking (Jika status masih Menunggu Konfirmasi)
              if (activeBooking.status == 'Menunggu Konfirmasi') ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      bookingVM.cancelBooking(activeBooking.id);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Batalkan Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3A5E), fontSize: 13),
          ),
        ),
      ],
    );
  }
}
