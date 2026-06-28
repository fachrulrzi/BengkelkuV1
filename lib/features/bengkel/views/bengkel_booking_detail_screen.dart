import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../customer/models/booking_model.dart';
import '../models/mechanic_model.dart';
import '../viewmodels/bengkel_booking_viewmodel.dart';
import 'service_report_screen.dart';
import '../../shared/views/chat_screen.dart';

class BengkelBookingDetailScreen extends StatefulWidget {
  final BookingModel booking;

  const BengkelBookingDetailScreen({super.key, required this.booking});

  @override
  State<BengkelBookingDetailScreen> createState() => _BengkelBookingDetailScreenState();
}

class _BengkelBookingDetailScreenState extends State<BengkelBookingDetailScreen> {
  String? _selectedMechanicId;

  String _getBookingTimeText(BookingModel booking) {
    final startStr = booking.bookingTime;
    
    final startParts = startStr.split(':');
    if (startParts.length != 2) return startStr;
    
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final duration = booking.estimatedDuration;
    final endMinutes = startMinutes + duration;
    
    final endHours = (endMinutes ~/ 60) % 24;
    final endMins = endMinutes % 60;
    
    final endHoursStr = endHours.toString().padLeft(2, '0');
    final endMinsStr = endMins.toString().padLeft(2, '0');
    
    return '$startStr - $endHoursStr:$endMinsStr (${duration} menit)';
  }

  @override
  void initState() {
    super.initState();
    _selectedMechanicId = widget.booking.mechanicId;
  }

  void _handleRequestPayment(BuildContext context) async {
    try {
      await context.read<BengkelBookingViewModel>().requestInitialPayment(widget.booking.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan diterima. Menunggu pembayaran awal customer.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _handleAssign(BuildContext context) async {
    try {
      if (_selectedMechanicId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih mekanik terlebih dahulu')),
        );
        return;
      }
      
      await context.read<BengkelBookingViewModel>().assignMechanic(
        widget.booking.id,
        _selectedMechanicId!,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mekanik berhasil ditugaskan & dikirim!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _handleReject(BuildContext context) async {
    try {
      await context.read<BengkelBookingViewModel>().updateBookingStatus(
        widget.booking.id,
        'Dibatalkan',
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking berhasil dibatalkan.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final bookingVM = context.watch<BengkelBookingViewModel>();

    // Cari booking terbaru dari list
    final activeBooking = bookingVM.bookings.firstWhere(
      (b) => b.id == widget.booking.id,
      orElse: () => widget.booking,
    );

    final isPending = activeBooking.status == 'Menunggu Konfirmasi';
    final isLunasAwal = activeBooking.status == 'Pembayaran Awal Lunas';
    final isProcessing = activeBooking.status == 'Diproses' || activeBooking.status == 'Mekanik Ditugaskan';
    final isOtw = activeBooking.status == 'Menuju Lokasi' || activeBooking.status == 'Sampai Lokasi';

    final allBusy = bookingVM.areAllMechanicsBusy;
    final hasMechanic = activeBooking.mechanicId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E2843),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFF2B300)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    bookingId: activeBooking.id,
                    isBengkel: true,
                    receiverId: activeBooking.customerId,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & ID
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Booking',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeBooking.status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: activeBooking.status == 'Selesai' ? Colors.green : const Color(0xFF1B3A5E),
                        ),
                      ),
                    ],
                  ),
                  if (activeBooking.isHomeService)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Home Service',
                        style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Walk-in',
                        style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detail Service
            const Text(
              'Detail Layanan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3A5E)),
            ),
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
                  _buildRow('Tanggal', activeBooking.bookingDate.toLocal().toString().split(' ')[0]),
                  const SizedBox(height: 8),
                  _buildRow('Jam', _getBookingTimeText(activeBooking)),
                  const SizedBox(height: 8),
                  _buildRow('Layanan', activeBooking.serviceCategory),
                  const SizedBox(height: 8),
                  _buildRow('Kendaraan', activeBooking.vehicleName ?? '-'),
                  const SizedBox(height: 8),
                  _buildRow('No Polisi', activeBooking.vehiclePoliceNumber ?? '-'),
                  if (activeBooking.isHomeService) ...[
                    const Divider(height: 24),
                    const Text('Alamat Customer', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(activeBooking.customerAddress ?? '-'),
                    const SizedBox(height: 8),
                    _buildRow('Biaya Perjalanan', 'Rp ${activeBooking.homeServiceFee}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Keluhan
            if (activeBooking.complaint != null && activeBooking.complaint!.isNotEmpty) ...[
              const Text(
                'Keluhan Customer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3A5E)),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Text(activeBooking.complaint!),
              ),
              const SizedBox(height: 16),
            ],

            // Penugasan Mekanik Section
            if (isLunasAwal || isPending || hasMechanic) ...[
              const Text(
                'Mekanik yang Bertugas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3A5E)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: (isLunasAwal)
                    ? DropdownButtonFormField<String>(
                        value: _selectedMechanicId,
                        hint: const Text('Pilih Mekanik untuk Dikirim'),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: bookingVM.mechanics.map((m) {
                          final statusColor = m.status == 'Tersedia'
                              ? Colors.green
                              : m.status == 'Bertugas'
                                  ? Colors.orange
                                  : Colors.grey;
                          return DropdownMenuItem(
                            value: m.id,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(m.name),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    m.status,
                                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedMechanicId = val;
                          });
                        },
                      )
                    : Row(
                        children: [
                          const Icon(Icons.person, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            activeBooking.mechanicName ?? 'Mekanik belum ditugaskan',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 16),

            // Laporan Pengerjaan Mekanik (Bengkel View)
            if (activeBooking.serviceReport != null && activeBooking.serviceReport!.isNotEmpty) ...[
              const Text(
                'Laporan Pengerjaan Mekanik',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3A5E)),
              ),
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
                    Row(
                      children: [
                        const Icon(Icons.description_outlined, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Laporan dari ${activeBooking.mechanicName ?? "Mekanik"}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3A5E)),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Deskripsi Pekerjaan:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeBooking.serviceReport!,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    _buildRow('Biaya Jasa Awal / DP', 'Rp ${activeBooking.initialPaymentAmount}'),
                    const SizedBox(height: 4),
                    _buildRow('Biaya Tambahan / Sparepart', 'Rp ${activeBooking.additionalPrice}'),
                    const SizedBox(height: 4),
                    _buildRow(
                      'Status Sisa Pembayaran',
                      activeBooking.additionalPaymentStatus == 'paid'
                          ? 'Lunas'
                          : activeBooking.additionalPaymentStatus == 'unpaid'
                              ? 'Belum Dibayar'
                              : 'Tidak Ada',
                    ),
                    const SizedBox(height: 4),
                    _buildRow('Total Pendapatan Servis', 'Rp ${activeBooking.totalPrice ?? 0}'),
                    if (activeBooking.serviceProofUrl != null && activeBooking.serviceProofUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Foto Bukti Pengerjaan:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          activeBooking.serviceProofUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              color: Colors.grey.shade100,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Ulasan Pelanggan (Bengkel View)
            if (activeBooking.ratingScore != null) ...[
              const Text(
                'Ulasan & Penilaian Pelanggan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3A5E)),
              ),
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
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < activeBooking.ratingScore! ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${activeBooking.ratingScore}/5)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (activeBooking.ratingMechanicName != null && activeBooking.ratingMechanicName!.isNotEmpty) ...[
                      _buildRow('Mekanik yang Dinilai', activeBooking.ratingMechanicName!),
                      const SizedBox(height: 8),
                    ],
                    const Text(
                      'Ulasan Pelanggan:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeBooking.ratingComment != null && activeBooking.ratingComment!.isNotEmpty
                          ? '"${activeBooking.ratingComment!}"'
                          : 'Tidak ada ulasan tertulis.',
                      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            if (isPending) ...[
              if (allBusy)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Peringatan: Semua mekanik Anda sedang BERTUGAS saat ini.',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                      ),
                      onPressed: () => _handleReject(context),
                      child: Text(allBusy ? 'Batalkan (Mekanik Sibuk)' : 'Tolak'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      onPressed: () => _handleRequestPayment(context),
                      child: const Text('Terima & Minta DP'),
                    ),
                  ),
                ],
              ),
            ],

            if (isLunasAwal)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _handleAssign(context),
                  child: const Text('Tugaskan & Kirim Mekanik', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
