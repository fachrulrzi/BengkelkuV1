import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'booking_form_screen.dart';
import 'workshop_report_screen.dart';
import '../models/bengkel_service_model.dart';
import '../viewmodels/bengkel_service_viewmodel.dart';
import 'package:intl/intl.dart';

class WorkshopDetailScreen extends StatefulWidget {
  final Map<String, dynamic> bengkel;

  const WorkshopDetailScreen({super.key, required this.bengkel});

  @override
  State<WorkshopDetailScreen> createState() => _WorkshopDetailScreenState();
}

class _WorkshopDetailScreenState extends State<WorkshopDetailScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bengkelId = widget.bengkel['id']?.toString() ?? '';
      if (bengkelId.isNotEmpty) {
        final vm = context.read<BengkelServiceViewModel>();
        vm.fetchServicesByBengkel(bengkelId);
        vm.fetchReviewsByBengkel(bengkelId);
      }
    });
  }

  Future<void> _launchWhatsApp(BuildContext context, String? phone) async {
    if (phone == null || phone.isEmpty || phone == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor telepon tidak tersedia')),
      );
      return;
    }
    String formattedPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    }
    final url = Uri.parse('https://wa.me/$formattedPhone');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka WhatsApp')),
        );
      }
    }
  }

  void _navigateToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingFormScreen(bengkel: widget.bengkel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.bengkel['name'] as String? ?? 'Bengkel';
    final address = widget.bengkel['address'] as String? ?? '-';
    final imageUrl = widget.bengkel['image_url'] as String?;
    final opHours = widget.bengkel['operating_hours'] as String? ?? '07:00-21:00';
    final phone = widget.bengkel['phone'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<BengkelServiceViewModel>(
        builder: (context, vm, child) {
          final reviews = vm.reviews;
          double rating = 0.0;
          int reviewsCount = 0;

          if (reviews.isNotEmpty) {
            double sum = 0;
            for (var r in reviews) {
              sum += (r['rating_score'] as num?)?.toDouble() ?? 0.0;
            }
            rating = double.parse((sum / reviews.length).toStringAsFixed(1));
            reviewsCount = reviews.length;
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Image
                Stack(
                  children: [
                    Container(
                      height: 280,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        image: imageUrl != null && imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imageUrl == null || imageUrl.isEmpty
                          ? const Icon(Icons.store, size: 80, color: Colors.grey)
                          : null,
                    ),
                    // Gradient overlay
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                    // Top Bar Elements
                    Positioned(
                      top: 40,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                            ),
                          ),
                          if (rating >= 4.0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B3A5E),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Top Rated',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Title and Address
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  address,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Details info
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _launchWhatsApp(context, phone),
                            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 28),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3-Column Info
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              rating > 0 ? rating.toStringAsFixed(1) : '-',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < rating.floor() ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 12,
                                );
                              }),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$reviewsCount ulasan',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 40, width: 1, color: const Color(0xFFEEEEEE)),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              '6',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Icon(Icons.build_outlined, color: AppColors.textSecondary, size: 14),
                            const SizedBox(height: 2),
                            const Text(
                              'Mekanik',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 40, width: 1, color: const Color(0xFFEEEEEE)),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Buka',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            const SizedBox(height: 4),
                            const Icon(Icons.access_time, color: AppColors.textSecondary, size: 14),
                            const SizedBox(height: 2),
                            Text(
                              opHours,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Description
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tentang Bengkel',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.bengkel['description'] as String? ?? 'Bengkel terpercaya dengan pelayanan terbaik.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Report Workshop section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.report_problem_outlined, color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Menemukan Masalah?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Laporkan jika bengkel melakukan kecurangan atau penipuan.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WorkshopReportScreen(bengkel: widget.bengkel),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade900,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Laporkan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // Layanan Tersedia
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Layanan Tersedia',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: _navigateToBooking,
                            child: const Text('Booking Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      vm.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : vm.services.isEmpty
                              ? const Text('Belum ada layanan terdaftar.', style: TextStyle(color: Colors.grey))
                              : Column(
                                  children: vm.services.map((s) => _buildServiceCard(s)).toList(),
                                ),
                    ],
                  ),
                ),

                // Ulasan Pelanggan
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  color: const Color(0xFFF8F9FA),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ulasan Pelanggan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (vm.isReviewsLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF1B3A5E),
                            ),
                          ),
                        )
                      else if (reviews.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.rate_review_outlined, color: Colors.grey, size: 40),
                              SizedBox(height: 10),
                              Text(
                                'Belum ada ulasan untuk bengkel ini.',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: reviews.map((review) {
                            final customerName = review['users']?['full_name'] as String? ?? 'Pelanggan';
                            final content = review['rating_comment'] as String? ?? 'Ulasan tanpa komentar';
                            final ratingVal = (review['rating_score'] as num?)?.toInt() ?? 5;
                            
                            String timeAgo = 'Baru saja';
                            if (review['created_at'] != null) {
                              final date = DateTime.tryParse(review['created_at'].toString())?.toLocal();
                              if (date != null) {
                                final diff = DateTime.now().difference(date);
                                if (diff.inDays > 30) {
                                  timeAgo = '${(diff.inDays / 30).floor()} bulan lalu';
                                } else if (diff.inDays > 0) {
                                  timeAgo = '${diff.inDays} hari lalu';
                                } else if (diff.inHours > 0) {
                                  timeAgo = '${diff.inHours} jam lalu';
                                } else if (diff.inMinutes > 0) {
                                  timeAgo = '${diff.inMinutes} menit lalu';
                                }
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildReviewCard(
                                customerName,
                                content,
                                timeAgo,
                                ratingVal,
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 40), // Bottom padding
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(BengkelServiceModel service) {
    int iconCode = 0xe8b8; // default settings icon
    if (service.iconCode != null) {
      final intParsed = int.tryParse(service.iconCode!);
      if (intParsed != null) {
        iconCode = intParsed;
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ignore: non_const_argument_for_const_parameter
          Icon(IconData(iconCode, fontFamily: 'MaterialIcons'), color: Colors.blue.shade400, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  service.description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined, color: AppColors.textSecondary, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      service.duration,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(service.basePrice),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                '+${currencyFormat.format(service.homeServiceFee)} home',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String name, String content, String time, int rating) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade500,
                radius: 16,
                child: Text(
                  name[0],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            time,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
