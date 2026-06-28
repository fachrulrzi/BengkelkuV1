import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../models/booking_model.dart';
import '../viewmodels/customer_booking_viewmodel.dart';
import 'midtrans_snap_screen.dart';

class TransactionPaymentScreen extends StatefulWidget {
  final BookingModel booking;
  final bool isInitial; // true = bayar jasa awal + ongkir, false = bayar biaya tambahan

  const TransactionPaymentScreen({
    super.key,
    required this.booking,
    this.isInitial = true,
  });

  @override
  State<TransactionPaymentScreen> createState() => _TransactionPaymentScreenState();
}

class _TransactionPaymentScreenState extends State<TransactionPaymentScreen> {
  bool _isLoading = false;
  String _selectedMethod = 'gopay';
  String _selectedBank = 'bca';

  String _getPaymentMethodDisplayName() {
    switch (_selectedMethod) {
      case 'gopay':
        return 'GoPay';
      case 'dana':
        return 'DANA';
      case 'shopeepay':
        return 'ShopeePay';
      case 'card':
        return 'Kartu Kredit/Debit';
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

  List<String> _getEnabledPayments() {
    switch (_selectedMethod) {
      case 'gopay':
        return ['gopay', 'qris'];
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
        return ['gopay', 'qris'];
    }
  }

  void _handlePayment() async {
    setState(() => _isLoading = true);
    try {
      final vm = context.read<CustomerBookingViewModel>();
      final enabledPayments = _getEnabledPayments();
      String? redirectUrl;
      if (widget.isInitial) {
        redirectUrl = await vm.payInitialFee(
          widget.booking.id,
          enabledPayments: enabledPayments,
        );
      } else {
        redirectUrl = await vm.payAdditionalFee(
          widget.booking.id,
          enabledPayments: enabledPayments,
        );
      }

      final snapUrl = redirectUrl;
      if (snapUrl != null) {
        if (mounted) {
          setState(() => _isLoading = false);

          // Buka Midtrans Snap in-app WebView
          final paymentResult = await Navigator.push<MidtransPaymentResult>(
            context,
            MaterialPageRoute(
              builder: (_) => MidtransSnapScreen(
                snapUrl: snapUrl,
                orderId: widget.booking.id,
              ),
            ),
          );

          if (mounted) {
            if (paymentResult == MidtransPaymentResult.success) {
              // Setelah pembayaran sukses, booking status tetap 'Pending' (Menunggu Konfirmasi/Menunggu Pembayaran Jasa)
              // Payment sync akan dilakukan otomatis saat fetchBookings() next time
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
                  content: Text(
                    '⏳ Pembayaran sedang diproses. Cek status di menu Booking.',
                  ),
                  backgroundColor: Color(0xFF1B3A5E),
                  duration: Duration(seconds: 4),
                ),
              );
            } else {
              // Cancelled / failed — booking tetap unpaid
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Booking tersimpan. Selesaikan pembayaran nanti dari halaman booking.',
                  ),
                  backgroundColor: Color(0xFF1B3A5E),
                  duration: Duration(seconds: 4),
                ),
              );
            }

            // Kembali ke Booking Detail / History
            Navigator.pop(context);
          }
        }
      } else {
        throw Exception('Gagal mendapatkan link pembayaran dari Midtrans.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Pembayaran Gagal',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF152A4A)),
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
                  style: TextStyle(color: Color(0xFF1B3A5E), fontWeight: FontWeight.bold),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }

  Widget _buildPaymentOption(
    String method,
    String name,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B3A5E).withValues(alpha: 0.05) : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF1B3A5E) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: method,
              groupValue: _selectedMethod,
              onChanged: (v) => setState(() => _selectedMethod = v!),
              activeColor: const Color(0xFF1B3A5E),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankSubOption(String bank, String name, String shortCode) {
    final isSelected = _selectedBank == bank;
    return GestureDetector(
      onTap: () => setState(() => _selectedBank = bank),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B3A5E).withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B3A5E) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                shortCode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Radio<String>(
              value: bank,
              groupValue: _selectedBank,
              onChanged: (v) => setState(() => _selectedBank = v!),
              activeColor: const Color(0xFF1B3A5E),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isInitial ? 'Pembayaran Jasa Layanan' : 'Pembayaran Tagihan Tambahan';
    final amount = widget.isInitial
        ? widget.booking.initialPaymentAmount
        : widget.booking.additionalPrice;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Color(0xFF1B3A5E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1B3A5E)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total tagihan card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                children: [
                  const Text(
                    'Total Tagihan',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp $amount',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detail layanan
            const Text(
              'Detail Layanan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildRow('Bengkel', widget.booking.bengkelName ?? '-'),
                  const SizedBox(height: 8),
                  _buildRow('Layanan', widget.booking.serviceCategory),
                  const SizedBox(height: 8),
                  _buildRow('Kendaraan', widget.booking.vehicleName ?? '-'),
                  if (widget.isInitial && widget.booking.isHomeService) ...[
                    const SizedBox(height: 8),
                    _buildRow('Biaya Kunjungan (Ongkir)', 'Rp ${widget.booking.homeServiceFee}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pilih metode pembayaran
            const Text(
              'Metode Pembayaran',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
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
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildPaymentOption('gopay', 'GoPay', 'Instant via QR', Icons.qr_code_scanner_outlined, Colors.green),
                  _buildPaymentOption('dana', 'DANA', 'Instant via QR', Icons.payment_outlined, Colors.blue),
                  _buildPaymentOption('shopeepay', 'ShopeePay', 'Instant via QR', Icons.shopping_bag_outlined, Colors.orange),
                  _buildPaymentOption('card', 'Kartu Kredit/Debit', 'Secure', Icons.credit_card_outlined, Colors.teal),
                  _buildPaymentOption('bank_transfer', 'Bank Transfer', '1-2 Jam', Icons.account_balance_outlined, Colors.blueGrey),

                  // Sub-pilihan bank
                  if (_selectedMethod == 'bank_transfer') ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 8, bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 6),
                          const Text(
                            'Pilih Bank',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildBankSubOption('bca', 'BCA Virtual Account', 'BCA'),
                          _buildBankSubOption('mandiri', 'Mandiri Bill Payment', 'MND'),
                          _buildBankSubOption('bni', 'BNI Virtual Account', 'BNI'),
                          _buildBankSubOption('bri', 'BRI Virtual Account', 'BRI'),
                          _buildBankSubOption('permata', 'Permata Virtual Account', 'PRM'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Pembayaran', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text(
                    'Rp $amount',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _handlePayment,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Bayar via ${_getPaymentMethodDisplayName()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
