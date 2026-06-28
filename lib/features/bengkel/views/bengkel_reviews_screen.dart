import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/bengkel_dashboard_viewmodel.dart';

class BengkelReviewsScreen extends StatefulWidget {
  const BengkelReviewsScreen({super.key});

  @override
  State<BengkelReviewsScreen> createState() => _BengkelReviewsScreenState();
}

class _BengkelReviewsScreenState extends State<BengkelReviewsScreen> {
  String _selectedType = 'Semua'; // Semua, Servis, Sparepart
  String _selectedRating = 'Semua'; // Semua, 5, 4, 3, 2, 1

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BengkelDashboardViewModel>();
    final reviews = viewModel.reviewsList;

    // Filter reviews
    var filteredReviews = reviews;

    if (_selectedType != 'Semua') {
      filteredReviews = filteredReviews.where((r) {
        if (_selectedType == 'Sparepart') {
          return r['type'] == 'Sparepart';
        } else {
          return r['type'] == 'Servis';
        }
      }).toList();
    }

    if (_selectedRating != 'Semua') {
      final targetRating = double.tryParse(_selectedRating) ?? 5.0;
      filteredReviews = filteredReviews.where((r) {
        return (r['rating'] as double).floor() == targetRating.floor();
      }).toList();
    }

    // Dynamic stats computation for filtered items (or overall)
    final double avgRating = reviews.isNotEmpty
        ? double.parse((reviews.fold(0.0, (sum, r) => sum + (r['rating'] as double)) / reviews.length).toStringAsFixed(1))
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2843),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Ulasan Bengkel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await viewModel.fetchBengkelReviews();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B3A5E), Color(0xFF2C5E8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B3A5E).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rata-rata Rating',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                avgRating > 0 ? avgRating.toStringAsFixed(1) : '-',
                                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '/ 5.0',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < avgRating.floor() ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 70,
                      color: Colors.white24,
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Ulasan',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reviews.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Ulasan Pelanggan',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Filter Label
              const Text(
                'Filter Ulasan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B3A5E)),
              ),
              const SizedBox(height: 10),

              // Dropdown Filter Row
              Row(
                children: [
                  // Filter Kategori
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedType,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1B3A5E), fontWeight: FontWeight.bold),
                          items: ['Semua', 'Servis', 'Sparepart'].map((String type) {
                            return DropdownMenuItem(value: type, child: Text('Kategori: $type'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedType = val);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filter Rating
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRating,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1B3A5E), fontWeight: FontWeight.bold),
                          items: ['Semua', '5', '4', '3', '2', '1'].map((String r) {
                            return DropdownMenuItem(
                              value: r, 
                              child: Text(r == 'Semua' ? 'Rating: Semua' : 'Rating: $r Bintang'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedRating = val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // List of Reviews
              filteredReviews.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rate_review_outlined, color: Colors.grey, size: 48),
                          SizedBox(height: 12),
                          Text(
                            'Tidak ada ulasan yang cocok.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredReviews.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final r = filteredReviews[index];
                        final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(r['date'] as DateTime);
                        final isService = r['type'] == 'Servis';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B3A5E).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      (r['customer'] as String).isNotEmpty ? (r['customer'] as String)[0].toUpperCase() : 'P',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3A5E), fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              r['customer'] as String,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B3A5E)),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isService ? Colors.orange.shade50 : Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isService ? 'Servis' : 'Sparepart',
                                                style: TextStyle(
                                                  fontSize: 9, 
                                                  fontWeight: FontWeight.bold,
                                                  color: isService ? Colors.orange : Colors.blue,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              // Stars Row
                              Row(
                                children: [
                                  ...List.generate(5, (starIdx) {
                                    return Icon(
                                      starIdx < (r['rating'] as double).floor() ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                  const SizedBox(width: 6),
                                  Text(
                                    (r['rating'] as double).toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B3A5E)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Category / Sparepart name details
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isService ? 'Layanan: ${r['category']}' : 'Produk: ${r['category']}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Comments
                              Text(
                                r['comment'] as String,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1B3A5E), height: 1.4),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
