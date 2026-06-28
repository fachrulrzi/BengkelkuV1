import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/customer_dashboard_viewmodel.dart';
import '../viewmodels/customer_profile_viewmodel.dart';
import 'workshop_detail_screen.dart';

class CustomerBengkelListTab extends StatefulWidget {
  const CustomerBengkelListTab({super.key});

  @override
  State<CustomerBengkelListTab> createState() => _CustomerBengkelListTabState();
}

class _CustomerBengkelListTabState extends State<CustomerBengkelListTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Terdekat';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerDashboardViewModel>().fetchBengkels();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardViewModel = context.watch<CustomerDashboardViewModel>();
    final profileViewModel = context.watch<CustomerProfileViewModel>();
    final activeVehicle = profileViewModel.activeVehicle;

    // Filter bengkel sesuai tipe kendaraan
    List<Map<String, dynamic>> filteredBengkels = dashboardViewModel.bengkels;
    if (activeVehicle != null) {
      filteredBengkels = dashboardViewModel.bengkels.where((b) {
        final specs = b['specialization'] as List<dynamic>? ?? [];
        if (activeVehicle.type == 'mobil') {
          return specs.any((s) => s.toString().toLowerCase().contains('mobil'));
        } else if (activeVehicle.type == 'motor') {
          return specs.any((s) => s.toString().toLowerCase().contains('motor'));
        }
        return true;
      }).toList();
    }

    // Search & Sort
    if (_searchQuery.isNotEmpty) {
      filteredBengkels = filteredBengkels.where((b) {
        final name = (b['name'] as String? ?? '').toLowerCase();
        return name.contains(_searchQuery);
      }).toList();
    }

    if (_sortBy == 'Rating Tertinggi') {
      filteredBengkels.sort((a, b) {
        final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return ratingB.compareTo(ratingA);
      });
    } else { // Terdekat
      filteredBengkels.sort((a, b) {
        final distA = (a['distance_km'] ?? a['distance'] as num?)?.toDouble() ?? 999.0;
        final distB = (b['distance_km'] ?? b['distance'] as num?)?.toDouble() ?? 999.0;
        return distA.compareTo(distB);
      });
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<CustomerDashboardViewModel>().fetchBengkels();
      },
      child: dashboardViewModel.isLoading && dashboardViewModel.bengkels.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            )
          : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                              hintText: 'Cari bengkel...',
                              hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Compatibility Banner
                        if (activeVehicle != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E5E5)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  activeVehicle.type == 'motor' ? Icons.motorcycle : Icons.directions_car,
                                  color: const Color(0xFF1E2843),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Hanya menampilkan bengkel untuk ${activeVehicle.type.toUpperCase()}',
                                    style: const TextStyle(
                                      color: Color(0xFF1E2843),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['Terdekat', 'Rating Tertinggi'].map((filter) {
                              final isSelected = _sortBy == filter;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _sortBy = filter;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: isSelected ? null : Border.all(color: const Color(0xFFE5E5E5)),
                                  ),
                                  child: Text(
                                    filter,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.white : const Color(0xFF8C8C8C),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (filteredBengkels.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.store_mall_directory_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          activeVehicle != null && _searchQuery.isEmpty
                              ? 'Tidak ada bengkel yang melayani ${activeVehicle.type}'
                              : 'Tidak ada bengkel ditemukan',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final b = filteredBengkels[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WorkshopDetailScreen(bengkel: b),
                                ),
                              );
                            },
                            child: _buildWorkshopCard(
                              imageUrl: b['image_url'] as String? ?? '',
                              name: b['name'] as String? ?? 'Bengkel',
                              rating: (b['rating'] as num?)?.toDouble() ?? 4.5,
                              reviewsCount: (b['reviews_count'] as num?)?.toInt() ?? 0,
                              distance: (b['distance_km'] ?? b['distance'] as num?)?.toDouble() ?? 0.0,
                              address: b['address'] as String? ?? '-',
                              services: List<String>.from(
                                b['specialization'] as List? ?? [],
                              ),
                            ),
                          );
                        },
                        childCount: filteredBengkels.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  Widget _buildWorkshopCard({
    required String imageUrl,
    required String name,
    required double rating,
    required int reviewsCount,
    required double distance,
    required String address,
    required List<String> services,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workshop image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade100,
                child: const Icon(
                  Icons.storefront,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '($reviewsCount) • ${distance.toStringAsFixed(1)} km',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.textSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: services
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
