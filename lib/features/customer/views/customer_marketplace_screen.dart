import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/customer_marketplace_viewmodel.dart';
import '../viewmodels/customer_profile_viewmodel.dart';
import '../../bengkel/models/sparepart_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'payment_screen.dart';

class CustomerMarketplaceScreen extends StatefulWidget {
  const CustomerMarketplaceScreen({super.key});

  @override
  State<CustomerMarketplaceScreen> createState() => _CustomerMarketplaceScreenState();
}

class _CustomerMarketplaceScreenState extends State<CustomerMarketplaceScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  String _sortBy = 'default';

  final List<String> _categories = ['Semua', 'Oli & Filter', 'Ban & Velg', 'Rem', 'Aki'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerMarketplaceViewModel>().fetchMarketplaceData();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    final buffer = StringBuffer();
    final str = price.toInt().toString();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CustomerMarketplaceViewModel>();
    final profileViewModel = context.watch<CustomerProfileViewModel>();
    final activeVehicle = profileViewModel.activeVehicle;

    // Filter by active vehicle compatibility
    List<SparepartModel> filteredList = viewModel.spareparts.where((item) {
      return viewModel.isCompatibleWith(item, activeVehicle);
    }).toList();

    // 1. Filter by category
    if (_selectedCategory != 'Semua') {
      if (_selectedCategory == 'Oli & Filter') {
        filteredList = filteredList
            .where((item) => item.category == 'Oli' || item.category == 'Filter')
            .toList();
      } else if (_selectedCategory == 'Ban & Velg') {
        filteredList = filteredList
            .where((item) => item.category == 'Ban' || item.category == 'Velg')
            .toList();
      } else {
        filteredList = filteredList
            .where((item) => item.category.toLowerCase() == _selectedCategory.toLowerCase())
            .toList();
      }
    }

    // 2. Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((item) {
        final nameMatch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final skuMatch = item.sku.toLowerCase().contains(_searchQuery.toLowerCase());
        return nameMatch || skuMatch;
      }).toList();
    }

    // 3. Sort by selection
    if (_sortBy == 'rating') {
      filteredList.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'price_asc') {
      filteredList.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'price_desc') {
      filteredList.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'default') {
      filteredList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search Input & Filter Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                          hintText: 'Cari sparepart...',
                          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _sortBy != 'default'
                          ? const Color(0xFF1B3A5E).withValues(alpha: 0.1)
                          : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _sortBy != 'default'
                            ? const Color(0xFF1B3A5E).withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.tune,
                            color: _sortBy != 'default'
                                ? const Color(0xFF1B3A5E)
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            _showFilterBottomSheet(context);
                          },
                        ),
                        if (_sortBy != 'default')
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1B3A5E),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (activeVehicle != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                        'Menampilkan produk untuk kategori ${activeVehicle.type.toUpperCase()}',
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

            // Horizontal Category Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? null
                              : Border.all(color: const Color(0xFFE5E5E5)),
                        ),
                        child: Text(
                          cat,
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
            ),
            const SizedBox(height: 12),

            // Product Cards Grid
            Expanded(
              child: viewModel.isLoading && viewModel.spareparts.isEmpty
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)))
                  : RefreshIndicator(
                      onRefresh: () async {
                        await viewModel.fetchMarketplaceData();
                      },
                      child: filteredList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada sparepart ditemukan',
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.58,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final item = filteredList[index];
                                final isCompatible = viewModel.isCompatible(item);
                                
                                // Calculate original price if discount exists
                                double originalPrice = item.price;
                                if (item.discountPercentage > 0) {
                                  originalPrice = item.price / (1 - item.discountPercentage / 100);
                                }

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailScreen(product: item),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.shade200),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Product Image with discount overlay
                                      Expanded(
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                                  ? Image.network(
                                                      item.imageUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        color: Colors.grey.shade100,
                                                        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                                      ),
                                                    )
                                                  : Container(
                                                      color: Colors.grey.shade100,
                                                      child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                                    ),
                                            ),
                                            if (item.discountPercentage > 0)
                                              Positioned(
                                                left: 8,
                                                top: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFF2D55),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    '-${item.discountPercentage}%',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Details Section
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Brand Name
                                            Text(
                                              item.sku.split('-').first.toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),

                                            // Product Name
                                            Text(
                                              item.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),

                                            // Compatibility Info
                                            Row(
                                              children: [
                                                Icon(
                                                  isCompatible ? Icons.check_circle_outlined : Icons.info_outline,
                                                  color: isCompatible ? const Color(0xFF00C853) : Colors.amber.shade700,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isCompatible ? 'Kompatibel' : 'Cek Kecocokan',
                                                  style: TextStyle(
                                                    color: isCompatible ? const Color(0xFF00C853) : Colors.amber.shade700,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),

                                            // Rating
                                            Row(
                                              children: [
                                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${item.rating} (${item.reviewCount})',
                                                  style: const TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),

                                            // Prices
                                            Row(
                                              children: [
                                                Text(
                                                  _formatPrice(item.price),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                if (item.discountPercentage > 0)
                                                  Text(
                                                    _formatPrice(originalPrice),
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 11,
                                                      decoration: TextDecoration.lineThrough,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),

                                            // Direct Buy Button
                                            SizedBox(
                                              width: double.infinity,
                                              height: 36,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF1E2843),
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => PaymentScreen(
                                                        selectedItemIds: [item.id],
                                                        customQuantities: {item.id: 1},
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 14),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'Beli',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
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
                            },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }



  // Quick filter bottom sheet
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Urutkan & Filter',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_sortBy != 'default')
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _sortBy = 'default';
                              });
                              setState(() {
                                _sortBy = 'default';
                              });
                            },
                            child: const Text(
                              'Atur Ulang',
                              style: TextStyle(
                                color: Color(0xFF1B3A5E),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),
                    const Text(
                      'URUTKAN BERDASARKAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSortOption(
                      title: 'Terbaru (Bawaan)',
                      value: 'default',
                      icon: Icons.calendar_today_outlined,
                      setModalState: setModalState,
                    ),
                    _buildSortOption(
                      title: 'Rating Tertinggi',
                      value: 'rating',
                      icon: Icons.star_border_rounded,
                      setModalState: setModalState,
                    ),
                    _buildSortOption(
                      title: 'Harga Terendah',
                      value: 'price_asc',
                      icon: Icons.trending_down_rounded,
                      setModalState: setModalState,
                    ),
                    _buildSortOption(
                      title: 'Harga Tertinggi',
                      value: 'price_desc',
                      icon: Icons.trending_up_rounded,
                      setModalState: setModalState,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption({
    required String title,
    required String value,
    required IconData icon,
    required StateSetter setModalState,
  }) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _sortBy = value;
        });
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B3A5E).withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B3A5E).withValues(alpha: 0.15) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF1B3A5E) : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF1B3A5E) : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF1B3A5E),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
