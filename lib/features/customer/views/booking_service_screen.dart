import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/customer_dashboard_viewmodel.dart';
import '../viewmodels/customer_profile_viewmodel.dart';
import 'workshop_detail_screen.dart';

class BookingServiceScreen extends StatefulWidget {
  const BookingServiceScreen({super.key});

  @override
  State<BookingServiceScreen> createState() => _BookingServiceScreenState();
}

class _BookingServiceScreenState extends State<BookingServiceScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Filter states
  String _selectedVehicleType = 'Semua'; // Semua, Mobil, Motor
  String _selectedSort = 'Terdekat'; // Terdekat, Rating, Ulasan
  double _maxDistance = 50.0;
  double _minRating = 0.0;

  String _searchQuery = '';

  static const List<String> _vehicleTypeOptions = ['Semua', 'Mobil', 'Motor'];
  static const List<String> _sortOptions = ['Terdekat', 'Rating', 'Ulasan'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<CustomerDashboardViewModel>();
      if (vm.bengkels.isEmpty) {
        vm.fetchBengkels();
      }
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> bengkels) {
    List<Map<String, dynamic>> result = bengkels;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      result = result.where((b) {
        final name = (b['name'] as String? ?? '').toLowerCase();
        final address = (b['address'] as String? ?? '').toLowerCase();
        final specialization = List<String>.from(b['specialization'] as List? ?? [])
            .join(' ')
            .toLowerCase();
        return name.contains(_searchQuery) ||
            address.contains(_searchQuery) ||
            specialization.contains(_searchQuery);
      }).toList();
    }

    // Filter by vehicle type
    if (_selectedVehicleType != 'Semua') {
      result = result.where((b) {
        final specialization = List<String>.from(b['specialization'] as List? ?? []);
        if (specialization.isEmpty) return true;
        if (_selectedVehicleType == 'Mobil') {
          return specialization.any((s) =>
              s.toLowerCase().contains('mobil') ||
              s.toLowerCase().contains('semua') ||
              s.toLowerCase().contains('motor & mobil') ||
              s.toLowerCase().contains('mobil & motor'));
        } else {
          return specialization.any((s) =>
              s.toLowerCase().contains('motor') ||
              s.toLowerCase().contains('semua') ||
              s.toLowerCase().contains('motor & mobil') ||
              s.toLowerCase().contains('mobil & motor'));
        }
      }).toList();
    }

    // Filter by minimum rating
    if (_minRating > 0) {
      result = result.where((b) {
        final rating = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return rating >= _minRating;
      }).toList();
    }

    // Filter by max distance
    result = result.where((b) {
      final distance = (b['distance_km'] ?? b['distance'] as num?)?.toDouble() ?? 0.0;
      return distance <= _maxDistance;
    }).toList();

    // Sort
    result.sort((a, b) {
      switch (_selectedSort) {
        case 'Rating':
          final rA = (a['rating'] as num?)?.toDouble() ?? 0.0;
          final rB = (b['rating'] as num?)?.toDouble() ?? 0.0;
          return rB.compareTo(rA);
        case 'Ulasan':
          final uA = (a['reviews_count'] as num?)?.toInt() ?? 0;
          final uB = (b['reviews_count'] as num?)?.toInt() ?? 0;
          return uB.compareTo(uA);
        case 'Terdekat':
        default:
          final dA = (a['distance_km'] ?? a['distance'] as num?)?.toDouble() ?? 99.0;
          final dB = (b['distance_km'] ?? b['distance'] as num?)?.toDouble() ?? 99.0;
          return dA.compareTo(dB);
      }
    });

    return result;
  }

  void _showFilterBottomSheet() {
    double tempDistance = _maxDistance;
    double tempRating = _minRating;
    String tempSort = _selectedSort;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter & Urutkan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            tempDistance = 50.0;
                            tempRating = 0.0;
                            tempSort = 'Terdekat';
                          });
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Sort
                  const Text(
                    'Urutkan Berdasarkan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _sortOptions.map((opt) {
                      final selected = tempSort == opt;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setSheetState(() => tempSort = opt),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFF1E2843) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? const Color(0xFF1E2843) : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              opt,
                              style: TextStyle(
                                color: selected ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Distance slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jarak Maksimum',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2843),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${tempDistance.toInt()} km',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(ctx).copyWith(
                      activeTrackColor: const Color(0xFF1E2843),
                      inactiveTrackColor: Colors.grey.shade200,
                      thumbColor: const Color(0xFFF2B300),
                      overlayColor: const Color(0xFFF2B300).withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: tempDistance,
                      min: 1,
                      max: 100,
                      divisions: 99,
                      onChanged: (val) => setSheetState(() => tempDistance = val),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('1 km', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text('100 km', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Rating filter
                  const Text(
                    'Rating Minimum',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [0.0, 3.0, 3.5, 4.0, 4.5].map((r) {
                      final selected = tempRating == r;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setSheetState(() => tempRating = r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFFF2B300) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? const Color(0xFFF2B300) : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (r > 0) ...[
                                  const Icon(Icons.star, size: 12, color: Colors.orange),
                                  const SizedBox(width: 3),
                                ],
                                Text(
                                  r == 0.0 ? 'Semua' : '${r}+',
                                  style: TextStyle(
                                    color: selected ? Colors.black : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _maxDistance = tempDistance;
                          _minRating = tempRating;
                          _selectedSort = tempSort;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E2843),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Terapkan Filter',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer2<CustomerDashboardViewModel, CustomerProfileViewModel>(
        builder: (context, dashVM, profileVM, child) {
          final bengkels = dashVM.bengkels;
          final filtered = _applyFilters(bengkels);
          final activeVehicle = profileVM.activeVehicle;

          // Pre-fill vehicle type from active vehicle
          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: const Color(0xFF1E2843),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, color: Colors.white),
                    onPressed: _showFilterBottomSheet,
                    tooltip: 'Filter',
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E2843),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Booking Service',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${filtered.length} bengkel tersedia',
                              style: const TextStyle(
                                color: Color(0xFF8C96A8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Search bar
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: const InputDecoration(
                                        hintText: 'Cari nama bengkel atau layanan...',
                                        hintStyle: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    GestureDetector(
                                      onTap: () => _searchController.clear(),
                                      child: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Vehicle type filter chips (sticky)
              SliverPersistentHeader(
                pinned: true,
                delegate: _VehicleFilterHeaderDelegate(
                  activeVehicle: activeVehicle?.type,
                  selected: _selectedVehicleType,
                  options: _vehicleTypeOptions,
                  onSelected: (val) => setState(() => _selectedVehicleType = val),
                  activeFiltersCount: (_minRating > 0 ? 1 : 0) + (_maxDistance < 50.0 ? 1 : 0),
                  onFilterTap: _showFilterBottomSheet,
                ),
              ),

              // Content
              if (dashVM.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1E2843),
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.store_mall_directory_outlined,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak ada bengkel ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Coba ubah filter atau kata pencarian',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _selectedVehicleType = 'Semua';
                              _maxDistance = 50.0;
                              _minRating = 0.0;
                              _selectedSort = 'Terdekat';
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset Filter'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final b = filtered[index];
                        return _BengkelCard(
                          bengkel: b,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorkshopDetailScreen(bengkel: b),
                              ),
                            );
                          },
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Sticky Vehicle Type Filter Header ─────────────────────────────────────

class _VehicleFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String? activeVehicle;
  final String selected;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final int activeFiltersCount;
  final VoidCallback onFilterTap;

  const _VehicleFilterHeaderDelegate({
    required this.activeVehicle,
    required this.selected,
    required this.options,
    required this.onSelected,
    required this.activeFiltersCount,
    required this.onFilterTap,
  });

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  bool shouldRebuild(_VehicleFilterHeaderDelegate oldDelegate) =>
      oldDelegate.selected != selected ||
      oldDelegate.activeFiltersCount != activeFiltersCount;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: options.map((opt) {
                  final isSelected = selected == opt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onSelected(opt),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1E2843) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1E2843) : Colors.grey.shade300,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF1E2843).withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (opt == 'Mobil')
                              Icon(
                                Icons.directions_car_outlined,
                                size: 14,
                                color: isSelected ? const Color(0xFFF2B300) : AppColors.textSecondary,
                              )
                            else if (opt == 'Motor')
                              Icon(
                                Icons.motorcycle_outlined,
                                size: 14,
                                color: isSelected ? const Color(0xFFF2B300) : AppColors.textSecondary,
                              )
                            else
                              Icon(
                                Icons.category_outlined,
                                size: 14,
                                color: isSelected ? const Color(0xFFF2B300) : AppColors.textSecondary,
                              ),
                            const SizedBox(width: 5),
                            Text(
                              opt,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Filter button
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: GestureDetector(
              onTap: onFilterTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: activeFiltersCount > 0 ? const Color(0xFFF2B300) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: activeFiltersCount > 0
                        ? const Color(0xFFF2B300)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 14,
                      color: activeFiltersCount > 0 ? Colors.black : AppColors.textPrimary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      activeFiltersCount > 0 ? 'Filter ($activeFiltersCount)' : 'Filter',
                      style: TextStyle(
                        color: activeFiltersCount > 0 ? Colors.black : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bengkel Card ───────────────────────────────────────────────────────────

class _BengkelCard extends StatelessWidget {
  final Map<String, dynamic> bengkel;
  final VoidCallback onTap;

  const _BengkelCard({required this.bengkel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = bengkel['name'] as String? ?? 'Bengkel';
    final address = bengkel['address'] as String? ?? '-';
    final imageUrl = bengkel['image_url'] as String? ?? '';
    final rating = (bengkel['rating'] as num?)?.toDouble() ?? 4.5;
    final reviewsCount = (bengkel['reviews_count'] as num?)?.toInt() ?? 0;
    final distance = (bengkel['distance_km'] ?? bengkel['distance'] as num?)?.toDouble() ?? 0.0;
    final specialization = List<String>.from(bengkel['specialization'] as List? ?? []);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderImage(),
                        )
                      : _placeholderImage(),
                  // Distance badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me, color: Colors.white, size: 11),
                          const SizedBox(width: 4),
                          Text(
                            '${distance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Rating badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2B300).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF2B300), size: 14),
                            const SizedBox(width: 3),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Color(0xFFC8960A),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (reviewsCount > 0) ...[
                              const Text(
                                ' · ',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                              Text(
                                '$reviewsCount',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 13),
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
                  if (specialization.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: specialization.take(3).map((s) {
                        final isMobil = s.toLowerCase().contains('mobil');
                        final isMotor = s.toLowerCase().contains('motor');
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isMobil
                                ? const Color(0xFF1E2843).withValues(alpha: 0.08)
                                : isMotor
                                    ? Colors.orange.withValues(alpha: 0.08)
                                    : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isMobil
                                  ? const Color(0xFF1E2843).withValues(alpha: 0.15)
                                  : isMotor
                                      ? Colors.orange.withValues(alpha: 0.2)
                                      : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isMobil
                                    ? Icons.directions_car_outlined
                                    : isMotor
                                        ? Icons.motorcycle_outlined
                                        : Icons.build_outlined,
                                size: 10,
                                color: isMobil
                                    ? const Color(0xFF1E2843)
                                    : isMotor
                                        ? Colors.orange
                                        : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                s,
                                style: TextStyle(
                                  color: isMobil
                                      ? const Color(0xFF1E2843)
                                      : isMotor
                                          ? Colors.orange.shade700
                                          : AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Book button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E2843),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Lihat Detail & Booking',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 140,
      width: double.infinity,
      color: const Color(0xFF1E2843).withValues(alpha: 0.08),
      child: const Icon(Icons.storefront_outlined, size: 48, color: AppColors.textSecondary),
    );
  }
}
