import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/customer_marketplace_viewmodel.dart';
import '../../bengkel/models/sparepart_model.dart';
import 'payment_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    // Default all items to be selected initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<CustomerMarketplaceViewModel>();
      setState(() {
        _selectedItems.addAll(viewModel.cart.keys);
      });
    });
  }

  String _formatPrice(double price) {
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${price.toInt().toString().replaceAllMapped(reg, (Match match) => '${match[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CustomerMarketplaceViewModel>();
    final cartEntries = viewModel.cart.entries.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shopping Cart',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Chat bubble icon with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.textPrimary),
                onPressed: () {},
              ),
              Positioned(
                right: 6,
                top: 6,
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
                  child: const Text(
                    '2',
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          // Notification bell with red dot
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: cartEntries.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Select All Checkbox Card
                        _buildSelectAllCard(cartEntries.length),
                        const SizedBox(height: 16),

                        // 2. Cart Items Grouped by Workshop
                        _buildGroupedCartItems(viewModel, cartEntries),
                        const SizedBox(height: 16),

                        // 3. Order Summary Section
                        _buildOrderSummaryCard(viewModel, cartEntries),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Checkout Panel
                _buildBottomCheckoutPanel(viewModel, cartEntries),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3A5E).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined, size: 72, color: Color(0xFF1B3A5E)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Keranjang Belanja Kosong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mulai cari sparepart atau ban untuk kendaraan Anda sekarang.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF152A4A),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Mulai Belanja', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectAllCard(int totalItems) {
    final isAllSelected = _selectedItems.length == totalItems && totalItems > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Checkbox(
            activeColor: const Color(0xFF1B3A5E),
            value: isAllSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  final viewModel = context.read<CustomerMarketplaceViewModel>();
                  _selectedItems.addAll(viewModel.cart.keys);
                } else {
                  _selectedItems.clear();
                }
              });
            },
          ),
          Text(
            'Select All ($totalItems items)',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedCartItems(
    CustomerMarketplaceViewModel viewModel,
    List<MapEntry<String, int>> cartEntries,
  ) {
    // Group items by workshop (bengkelId)
    final Map<String, List<MapEntry<String, int>>> grouped = {};
    for (var entry in cartEntries) {
      final product = viewModel.spareparts.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => SparepartModel(
          id: entry.key,
          bengkelId: 'unknown',
          name: 'Loading...',
          sku: 'SKU',
          category: 'Oli',
          price: 0,
          stock: 0,
          createdAt: DateTime.now(),
          compatibleBrandIds: const [],
        ),
      );
      grouped.putIfAbsent(product.bengkelId, () => []).add(entry);
    }

    return Column(
      children: grouped.entries.map((group) {
        final bengkelId = group.key;
        final entries = group.value;

        // Try to get workshop name from sparepart metadata
        String bengkelName = 'AutoCare Pro';
        if (entries.isNotEmpty) {
          final firstSparepart = viewModel.spareparts.firstWhere(
            (p) => p.id == entries.first.key,
            orElse: () => SparepartModel(
              id: '',
              bengkelId: '',
              name: '',
              sku: '',
              category: '',
              price: 0,
              stock: 0,
              createdAt: DateTime.now(),
              compatibleBrandIds: const [],
            ),
          );
          if (firstSparepart.bengkelName != null) {
            bengkelName = firstSparepart.bengkelName!;
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bengkel Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  bengkelName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
              const Divider(height: 1),

              // Bengkel items list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final product = viewModel.spareparts.firstWhere(
                    (p) => p.id == entry.key,
                    orElse: () => SparepartModel(
                      id: entry.key,
                      bengkelId: bengkelId,
                      name: 'Sparepart',
                      sku: 'SKU',
                      category: 'Oli',
                      price: 0,
                      stock: 0,
                      createdAt: DateTime.now(),
                      compatibleBrandIds: const [],
                    ),
                  );

                  final isChecked = _selectedItems.contains(product.id);

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          activeColor: const Color(0xFF1B3A5E),
                          value: isChecked,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedItems.add(product.id);
                              } else {
                                _selectedItems.remove(product.id);
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        // Image
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade100,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                                : const Icon(Icons.image, size: 32, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatPrice(product.price),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF152A4A)),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Quantity Counter
                                  Container(
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F2F2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(Icons.remove, size: 14, color: AppColors.textPrimary),
                                          onPressed: () {
                                            viewModel.removeFromCart(product.id);
                                          },
                                        ),
                                        Text(
                                          '${entry.value}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(Icons.add, size: 14, color: AppColors.textPrimary),
                                          onPressed: () {
                                            viewModel.addToCart(product.id);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Delete Trash Icon
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _selectedItems.remove(product.id);
                                      });
                                      viewModel.deleteFromCart(product.id);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderSummaryCard(CustomerMarketplaceViewModel viewModel, List<MapEntry<String, int>> cartEntries) {
    double subtotal = 0;
    for (var entry in cartEntries) {
      if (_selectedItems.contains(entry.key)) {
        final product = viewModel.spareparts.firstWhere(
          (p) => p.id == entry.key,
          orElse: () => SparepartModel(
            id: entry.key,
            bengkelId: '1',
            name: '',
            sku: '',
            category: '',
            price: 0,
            stock: 0,
            createdAt: DateTime.now(),
            compatibleBrandIds: const [],
          ),
        );
        subtotal += product.price * entry.value;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal (${_selectedItems.length} items)', _formatPrice(subtotal)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
              ),
              Text(
                _formatPrice(subtotal),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF152A4A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildBottomCheckoutPanel(CustomerMarketplaceViewModel viewModel, List<MapEntry<String, int>> cartEntries) {
    double subtotal = 0;
    for (var entry in cartEntries) {
      if (_selectedItems.contains(entry.key)) {
        final product = viewModel.spareparts.firstWhere(
          (p) => p.id == entry.key,
          orElse: () => SparepartModel(
            id: entry.key,
            bengkelId: '1',
            name: '',
            sku: '',
            category: '',
            price: 0,
            stock: 0,
            createdAt: DateTime.now(),
            compatibleBrandIds: const [],
          ),
        );
        subtotal += product.price * entry.value;
      }
    }

    final isAllSelected = _selectedItems.length == cartEntries.length && cartEntries.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: SafeArea(
        child: Row(
          children: [
            Checkbox(
              activeColor: const Color(0xFF1B3A5E),
              value: isAllSelected,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedItems.addAll(viewModel.cart.keys);
                  } else {
                    _selectedItems.clear();
                  }
                });
              },
            ),
            const Text('All', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(
                  _formatPrice(subtotal),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF152A4A)),
                ),
              ],
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  elevation: 0,
                ),
                onPressed: _selectedItems.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              selectedItemIds: _selectedItems.toList(),
                            ),
                          ),
                        );
                      },
                child: Text(
                  'Checkout (${_selectedItems.length})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
