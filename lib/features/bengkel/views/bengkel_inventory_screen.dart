import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/login_screen.dart';
import '../viewmodels/bengkel_inventory_viewmodel.dart';
import '../viewmodels/bengkel_dashboard_viewmodel.dart';
import '../models/sparepart_model.dart';
import '../../admin/models/vehicle_brand_model.dart';

class BengkelInventoryScreen extends StatefulWidget {
  const BengkelInventoryScreen({super.key});

  @override
  State<BengkelInventoryScreen> createState() => _BengkelInventoryScreenState();
}

class _BengkelInventoryScreenState extends State<BengkelInventoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  String? _lastBengkelId;

  final List<String> _categories = ['Semua', 'Oli', 'Filter', 'Rem', 'Aki', 'Mesin'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BengkelInventoryViewModel>().fetchBrands();
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

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun mitra?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (context.mounted) {
      await context.read<AuthViewModel>().signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showAddEditSparepartDialog(BuildContext context, {SparepartModel? sparepart}) {
    final isEdit = sparepart != null;
    final nameCtrl = TextEditingController(text: sparepart?.name);
    final skuCtrl = TextEditingController(text: sparepart?.sku);
    final priceCtrl = TextEditingController(text: sparepart?.price.toInt().toString());
    final stockCtrl = TextEditingController(text: sparepart?.stock.toString());
    
    String selectedCat = sparepart != null ? sparepart.category : 'Oli';
    List<String> selectedBrandIds = sparepart != null ? List<String>.from(sparepart.compatibleBrandIds) : [];

    PlatformFile? selectedImageFile;
    String? currentImageUrl = sparepart?.imageUrl;
    bool imageDeleted = false;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal during saving
      builder: (dialogCtx) => StatefulBuilder(
        builder: (statefulCtx, setDialogState) {
          final inventoryVM = statefulCtx.read<BengkelInventoryViewModel>();
          
          return AlertDialog(
            scrollable: true,
            title: Text(isEdit ? 'Edit Sparepart' : 'Tambah Sparepart', style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Picker
                const Text('Foto Produk:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: selectedImageFile != null
                              ? Image.memory(
                                  selectedImageFile!.bytes!,
                                  fit: BoxFit.cover,
                                )
                              : (currentImageUrl != null && !imageDeleted
                                  ? Image.network(
                                      currentImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),
                                    )
                                  : Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.shade400)),
                        ),
                      ),
                      if (selectedImageFile != null || (currentImageUrl != null && !imageDeleted))
                        Positioned(
                          right: 4,
                          top: 4,
                          child: GestureDetector(
                            onTap: isSaving ? null : () {
                              setDialogState(() {
                                if (selectedImageFile != null) {
                                  selectedImageFile = null;
                                } else {
                                  imageDeleted = true;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: isSaving ? null : () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        withData: true,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        setDialogState(() {
                          selectedImageFile = result.files.first;
                          imageDeleted = false;
                        });
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: Text(
                      selectedImageFile != null || (currentImageUrl != null && !imageDeleted)
                          ? 'Ubah Foto'
                          : 'Pilih Foto',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Name
                const Text('Nama Sparepart:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  enabled: !isSaving,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Shell Helix Ultra 5W-30',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),

                // SKU
                const Text('SKU:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: skuCtrl,
                  enabled: !isSaving,
                  decoration: InputDecoration(
                    hintText: 'Contoh: OLI-001, FLT-002',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),

                // Category dropdown
                const Text('Kategori:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  items: isSaving ? null : _categories
                      .where((c) => c != 'Semua')
                      .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                      .toList(),
                  onChanged: isSaving ? null : (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedCat = val;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),

                // Price
                const Text('Harga (Rp):', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: priceCtrl,
                  enabled: !isSaving,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 185000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),

                // Stock
                const Text('Stok:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: stockCtrl,
                  enabled: !isSaving,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 24',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 16),

                // Compatibility Setup section
                const Text(
                  'Kesesuaian Kendaraan (Compatibility):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                inventoryVM.allBrands.isEmpty
                    ? const Text('Belum ada merek kendaraan terdaftar.', style: TextStyle(fontSize: 12, color: Colors.grey))
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: inventoryVM.allBrands.map((brand) {
                          final isChecked = selectedBrandIds.contains(brand.id);
                          return CheckboxListTile(
                            title: Text(brand.name, style: const TextStyle(fontSize: 13)),
                            value: isChecked,
                            dense: true,
                            enabled: !isSaving,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (bool? val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedBrandIds.add(brand.id);
                                } else {
                                  selectedBrandIds.remove(brand.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isEdit)
                    TextButton(
                      onPressed: isSaving ? null : () async {
                        final confirm = await showDialog<bool>(
                          context: dialogCtx,
                          builder: (cCtx) => AlertDialog(
                            title: const Text('Hapus Sparepart'),
                            content: Text('Hapus "${sparepart.name}" dari inventori?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(cCtx, false), child: const Text('Batal')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(cCtx, true),
                                child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && dialogCtx.mounted) {
                          try {
                            setDialogState(() {
                              isSaving = true;
                            });
                            final dashboardVM = dialogCtx.read<BengkelDashboardViewModel>();
                            await dialogCtx.read<BengkelInventoryViewModel>().deleteSparepart(sparepart.id, dashboardVM.bengkelId);
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                const SnackBar(content: Text('Sparepart berhasil dihapus'), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            if (dialogCtx.mounted) {
                              ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
                              );
                            }
                            setDialogState(() {
                              isSaving = false;
                            });
                          }
                        }
                      },
                      child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                    child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3A5E)),
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            final sku = skuCtrl.text.trim();
                            final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                            final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;
                            
                            if (name.isEmpty || sku.isEmpty) {
                              ScaffoldMessenger.of(statefulCtx).showSnackBar(
                                const SnackBar(content: Text('Nama dan SKU wajib diisi'), backgroundColor: Colors.orange),
                              );
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                            });

                            final dashboardVM = statefulCtx.read<BengkelDashboardViewModel>();
                            final invVM = statefulCtx.read<BengkelInventoryViewModel>();
                            
                            try {
                              String? finalImageUrl = currentImageUrl;

                              // 1. Delete old image if requested
                              if (imageDeleted && currentImageUrl != null) {
                                await invVM.deleteSparepartImage(currentImageUrl);
                                finalImageUrl = null;
                              }

                              // 2. Upload new image if chosen
                              if (selectedImageFile != null) {
                                // Delete old image from storage if overwriting
                                if (currentImageUrl != null) {
                                  await invVM.deleteSparepartImage(currentImageUrl);
                                }
                                finalImageUrl = await invVM.uploadSparepartImage(selectedImageFile!.bytes!, selectedImageFile!.name);
                              }

                              if (isEdit) {
                                await invVM.editSparepart(
                                  sparepartId: sparepart.id,
                                  bengkelId: dashboardVM.bengkelId,
                                  name: name,
                                  sku: sku,
                                  category: selectedCat,
                                  price: price,
                                  stock: stock,
                                  imageUrl: finalImageUrl,
                                  compatibleBrandIds: selectedBrandIds,
                                );
                              } else {
                                await invVM.addSparepart(
                                  bengkelId: dashboardVM.bengkelId,
                                  name: name,
                                  sku: sku,
                                  category: selectedCat,
                                  price: price,
                                  stock: stock,
                                  imageUrl: finalImageUrl,
                                  compatibleBrandIds: selectedBrandIds,
                                );
                              }

                              if (dialogCtx.mounted) {
                                Navigator.pop(dialogCtx);
                                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                  SnackBar(
                                    content: Text(isEdit ? 'Sparepart berhasil diperbarui' : 'Sparepart berhasil ditambahkan'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (dialogCtx.mounted) {
                                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                );
                              }
                              setDialogState(() {
                                isSaving = false;
                              });
                            }
                          },
                          child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                        ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardVM = context.watch<BengkelDashboardViewModel>();
    final inventoryVM = context.watch<BengkelInventoryViewModel>();

    if (dashboardVM.bengkelId.isNotEmpty && _lastBengkelId != dashboardVM.bengkelId) {
      _lastBengkelId = dashboardVM.bengkelId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<BengkelInventoryViewModel>().fetchSpareparts(dashboardVM.bengkelId);
      });
    }

    // 1. Filter by category
    List<SparepartModel> filteredList = inventoryVM.spareparts;
    if (_selectedCategory != 'Semua') {
      filteredList = filteredList.where((item) => item.category == _selectedCategory).toList();
    }

    // 2. Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((item) {
        final nameMatch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final skuMatch = item.sku.toLowerCase().contains(_searchQuery.toLowerCase());
        return nameMatch || skuMatch;
      }).toList();
    }

    // 3. Count low stock/habis products
    final lowStockCount = inventoryVM.spareparts.where((item) => item.stock <= 2).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Dark Header block
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F1E2C),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF1B5A90),
                    child: const Text(
                      'B',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dashboardVM.bengkelName.isNotEmpty ? dashboardVM.bengkelName : 'Bengkel Jaya Motor',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Mitra Terverifikasi ✓',
                          style: TextStyle(
                            color: Color(0xFF5ED3A6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    onPressed: () => _handleLogout(context),
                  ),
                ],
              ),
            ),
            // Title, Search, Filters & Alert
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Row with "+ Tambah" button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Inventori',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF152A4A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () => _showAddEditSparepartDialog(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Tambah',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Low Stock alert banner
                  if (lowStockCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFCCCC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '$lowStockCount produk stok rendah / habis',
                            style: const TextStyle(
                              color: Color(0xFFCC0000),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEFEF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                        hintText: 'Cari produk...',
                        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category horizontal list
                  SingleChildScrollView(
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
                              color: isSelected ? const Color(0xFF152A4A) : const Color(0xFFEAEAEA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // Items List
            Expanded(
              child: inventoryVM.isLoading && inventoryVM.spareparts.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('Tidak ada produk', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            if (dashboardVM.bengkelId.isNotEmpty) {
                              await inventoryVM.fetchSpareparts(dashboardVM.bengkelId);
                            }
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final item = filteredList[index];
                              final isOut = item.stock == 0;
                              final isLow = item.stock > 0 && item.stock <= 2;

                              Color cardBorderColor = Colors.transparent;
                              Color packageIconColor = Colors.grey.shade600;
                              Color packageIconBg = Colors.grey.shade100;
                              Widget stockWidget;

                              if (isOut) {
                                cardBorderColor = const Color(0xFFFFCCCC);
                                packageIconColor = Colors.red.shade400;
                                packageIconBg = const Color(0xFFFFF2F2);
                                stockWidget = const Text(
                                  'Habis',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                                );
                              } else if (isLow) {
                                cardBorderColor = Colors.amber.shade200;
                                stockWidget = Text(
                                  'Stok: ${item.stock}',
                                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                                );
                              } else {
                                stockWidget = Text(
                                  'Stok: ${item.stock}',
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                );
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: cardBorderColor, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Image or package icon
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: packageIconBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: cardBorderColor.withValues(alpha: 0.5), width: 1),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                            ? Image.network(
                                                item.imageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Icon(
                                                  Icons.broken_image_outlined,
                                                  color: packageIconColor,
                                                  size: 20,
                                                ),
                                              )
                                            : Icon(
                                                Icons.inventory_2_outlined,
                                                color: packageIconColor,
                                                size: 20,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Content details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.sku}  •  ${item.category}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
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
                                              const SizedBox(width: 8),
                                              stockWidget,
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Edit button
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                                      onPressed: () => _showAddEditSparepartDialog(context, sparepart: item),
                                    ),
                                  ],
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
}
