import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../customer/models/booking_model.dart';
import '../viewmodels/bengkel_booking_viewmodel.dart';

class ServiceReportScreen extends StatefulWidget {
  final BookingModel booking;
  const ServiceReportScreen({super.key, required this.booking});

  @override
  State<ServiceReportScreen> createState() => _ServiceReportScreenState();
}

class _ServiceReportScreenState extends State<ServiceReportScreen> {
  final _reportController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reportController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submitReport() async {
    final report = _reportController.text.trim();
    final priceStr = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final price = int.tryParse(priceStr) ?? 0;

    if (report.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan pekerjaan tidak boleh kosong')));
      return;
    }
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Total tagihan tidak valid')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Total tagihan dari mekanik, kita tambahkan dengan ongkos home service
      final finalPrice = price + widget.booking.homeServiceFee;
      
      await context.read<BengkelBookingViewModel>().completeService(
        widget.booking.id,
        report,
        finalPrice,
      );
      
      if (mounted) {
        Navigator.pop(context, true); // true = success
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pekerjaan selesai, tagihan dikirim!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Tagihan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E2843),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Laporan Pekerjaan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reportController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Contoh: Oli sudah diganti, kampas rem depan masih bagus, filter udara dibersihkan...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Total Tagihan (Rp)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Masukkan total harga layanan & sparepart',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
            ),
            if (widget.booking.isHomeService) ...[
              const SizedBox(height: 8),
              Text(
                '+ Biaya Kunjungan (Home Service): Rp ${widget.booking.homeServiceFee}',
                style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Total di atas akan otomatis ditambah dengan biaya kunjungan.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _submitReport,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Selesai & Kirim Tagihan', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
