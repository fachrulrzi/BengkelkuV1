import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Syarat & Ketentuan',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Syarat & Ketentuan Layanan BengkelKu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Terakhir diperbarui: 27 Juni 2026',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 24),
              _Section(
                title: '1. Pengenalan',
                content:
                    'Selamat datang di BengkelKu. Syarat dan Ketentuan ini mengatur akses dan penggunaan Anda atas aplikasi BengkelKu, baik sebagai Pelanggan maupun sebagai Mitra Bengkel. Dengan mendaftar dan menggunakan layanan kami, Anda menyetujui seluruh ketentuan yang tertulis di sini.',
              ),
              _Section(
                title: '2. Akun Pelanggan',
                content:
                    'Sebagai pelanggan, Anda bertanggung jawab untuk menjaga kerahasiaan informasi akun Anda. BengkelKu menyediakan platform untuk mencari bengkel terdekat, melakukan reservasi servis, dan membeli suku cadang, namun kami tidak bertanggung jawab secara langsung atas kualitas layanan yang diberikan oleh Mitra Bengkel independen.',
              ),
              _Section(
                title: '3. Akun Mitra Bengkel & Mekanik',
                content:
                    'Sebagai Mitra Bengkel, Anda wajib memberikan informasi yang akurat mengenai bengkel, layanan, dan suku cadang yang Anda tawarkan. Anda bertanggung jawab penuh atas tindakan mekanik yang terdaftar di bawah bengkel Anda serta wajib menjaga standar kualitas pelayanan.',
              ),
              _Section(
                title: '4. Pembayaran dan Transaksi',
                content:
                    'Semua transaksi dilakukan melalui sistem pembayaran yang terintegrasi di dalam aplikasi. BengkelKu berhak memotong biaya layanan atau komisi sesuai dengan kesepakatan mitra yang berlaku. Pengembalian dana (refund) mengikuti kebijakan masing-masing bengkel sesuai standar yang ditetapkan platform.',
              ),
              _Section(
                title: '5. Batasan Tanggung Jawab',
                content:
                    'BengkelKu bertindak sebagai perantara antara Pelanggan dan Mitra Bengkel. Kami tidak bertanggung jawab atas kerugian, cedera, atau kerusakan yang timbul dari layanan perbaikan atau produk yang dibeli melalui Mitra Bengkel kami.',
              ),
              _Section(
                title: '6. Perubahan Ketentuan',
                content:
                    'Kami dapat mengubah Syarat dan Ketentuan ini dari waktu ke waktu. Kami akan memberitahukan perubahan tersebut melalui aplikasi. Penggunaan Anda yang berkelanjutan atas aplikasi menunjukkan persetujuan Anda terhadap perubahan tersebut.',
              ),
              SizedBox(height: 32),
              Center(
                child: Text(
                  'Terima kasih telah menggunakan BengkelKu.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
