import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/customer_marketplace_viewmodel.dart';
import '../../bengkel/models/sparepart_model.dart';
import 'cart_screen.dart';
import 'payment_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final SparepartModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<CustomerMarketplaceViewModel>();
      try {
        final reviews = await viewModel.fetchSparepartReviews(widget.product.id);
        if (mounted) {
          setState(() {
            _reviews = reviews;
            _isLoadingReviews = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingReviews = false;
          });
        }
      }
    });
  }

  String _formatReviewDate(DateTime dt) {
    final localDt = dt.toLocal();
    final day = localDt.day.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[localDt.month - 1];
    final year = localDt.year;
    return '$day $month $year';
  }

  String _formatFullPrice(double price) {
    // Format numeric price to full string e.g. Rp 185.000
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${price.toInt().toString().replaceAllMapped(reg, (Match match) => '${match[1]}.')}';
  }

  String _getCategoryLabel(String category) {
    if (category == 'Oli' || category == 'Filter') return 'Oli & Filter';
    if (category == 'Ban' || category == 'Velg') return 'Ban & Velg';
    return category;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CustomerMarketplaceViewModel>();
    final product = widget.product;
    final compatibleVehicle = viewModel.getCompatibleUserVehicle(product);
    final isCompatible = viewModel.isCompatible(product);

    // Calculate display rating and review count from loaded reviews if they exist
    double displayRating = product.rating;
    int displayReviewCount = product.reviewCount;
    if (!_isLoadingReviews && _reviews.isNotEmpty) {
      displayReviewCount = _reviews.length;
      double sum = 0;
      for (var r in _reviews) {
        sum += (r['rating'] as num).toDouble();
      }
      displayRating = double.parse((sum / _reviews.length).toStringAsFixed(1));
    }

    // Calculate original price if discount exists
    double originalPrice = product.price;
    if (product.discountPercentage > 0) {
      originalPrice = product.price / (1 - product.discountPercentage / 100);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Produk',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                  ),
                ),
                if (viewModel.cartCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${viewModel.cartCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Product Image with Discount Overlay
            Stack(
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  color: Colors.white,
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.broken_image,
                            size: 80,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : const Icon(
                          Icons.image,
                          size: 80,
                          color: AppColors.textSecondary,
                        ),
                ),
                if (product.discountPercentage > 0)
                  Positioned(
                    left: 20,
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Promo ${product.discountPercentage}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // 2. Product Info
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getCategoryLabel(product.category),
                      style: const TextStyle(
                        color: Color(0xFF1B3A5E),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Product Title
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Brand name
                  Text(
                    product.sku.split('-').first.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rating & Compatibility Row
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '$displayRating',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($displayReviewCount ulasan)',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 8),
                      Icon(
                        isCompatible ? Icons.check_circle_outlined : Icons.info_outline,
                        color: isCompatible ? const Color(0xFF00C853) : Colors.amber.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          compatibleVehicle != null
                              ? 'Cocok untuk $compatibleVehicle'
                              : (isCompatible ? 'Kompatibel' : 'Cek Kecocokan'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCompatible ? const Color(0xFF00C853) : Colors.amber.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Prices
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _formatFullPrice(product.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.discountPercentage > 0)
                        Text(
                          _formatFullPrice(originalPrice),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Stok Tersedia: ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      Text(
                        '${product.stock} pcs',
                        style: TextStyle(
                          color: product.stock > 0 ? const Color(0xFF00C853) : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Keuntungan Berbelanja Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Keuntungan Berbelanja',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPerkItem(
                    icon: Icons.local_shipping_outlined,
                    title: 'Gratis Ongkir',
                    subtitle: 'Untuk pembelian minimal Rp 100.000',
                  ),
                  const Divider(height: 20),
                  _buildPerkItem(
                    icon: Icons.shield_outlined,
                    title: 'Garansi Resmi',
                    subtitle: '100% produk original bergaransi',
                  ),
                  const Divider(height: 20),
                  _buildPerkItem(
                    icon: Icons.handyman_outlined,
                    title: 'Pemasangan Gratis',
                    subtitle: 'Gratis pasang di bengkel partner',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. Deskripsi Produk
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deskripsi Produk',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.description ?? 'Tidak ada deskripsi produk.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. Spesifikasi
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spesifikasi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSpecRow('Brand', product.sku.split('-').first.toUpperCase()),
                  _buildSpecRow('Kategori', _getCategoryLabel(product.category)),
                  _buildSpecRow('Kompatibilitas', compatibleVehicle ?? 'Merek Kompatibel'),
                  _buildSpecRow('Kondisi', 'Baru 100%'),
                  _buildSpecRow('Garansi', '1 Tahun'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 6. Ulasan Pengguna Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ulasan Pengguna',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_reviews.length} ulasan',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingReviews)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    )
                  else if (_reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Text(
                          'Belum ada ulasan untuk produk ini.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reviews.length,
                      separatorBuilder: (context, index) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        final int rating = review['rating'];
                        final String note = review['note'];
                        final String name = review['name'];
                        final DateTime date = review['created_at'];

                        // Extract initials
                        final names = name.split(' ');
                        final String initials = names.isNotEmpty
                            ? (names.length > 1
                                ? '${names[0][0]}${names[1][0]}'.toUpperCase()
                                : names[0][0].toUpperCase())
                            : 'C';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF1B3A5E).withValues(alpha: 0.1),
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Color(0xFF1B3A5E),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
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
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: List.generate(5, (starIdx) {
                                          return Icon(
                                            Icons.star,
                                            size: 14,
                                            color: starIdx < rating ? Colors.amber : Colors.grey.shade300,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatReviewDate(date),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            if (note.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.only(left: 48.0),
                                child: Text(
                                  note,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Bottom spacer for the floating bar
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Quantity Picker
            Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: () {
                      if (_quantity > 1) {
                        setState(() {
                          _quantity--;
                        });
                      }
                    },
                  ),
                  Text(
                    '${product.stock > 0 ? _quantity : 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () {
                      if (product.stock > 0 && _quantity < product.stock) {
                        setState(() {
                          _quantity++;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Tambah Ke Keranjang (Outlined style for premium visual hierarchy)
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B3A5E),
                    side: const BorderSide(color: Color(0xFF1B3A5E), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: product.stock <= 0
                      ? null
                      : () {
                          viewModel.addToCartWithQty(product.id, _quantity);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$_quantity produk berhasil ditambahkan ke keranjang!'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                  child: const Icon(Icons.add_shopping_cart, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Beli Sekarang Button
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3A5E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: product.stock <= 0
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentScreen(
                                selectedItemIds: [product.id],
                                customQuantities: {product.id: _quantity},
                              ),
                            ),
                          );
                        },
                  child: Text(
                    product.stock > 0 ? 'Beli Sekarang' : 'Stok Habis',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerkItem({required IconData icon, required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F5F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF1B3A5E), size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
        ],
      ),
    );
  }
}
