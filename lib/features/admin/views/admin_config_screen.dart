import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/login_screen.dart';
import '../viewmodels/admin_config_viewmodel.dart';
import '../models/vehicle_brand_model.dart';
import '../models/service_category_model.dart';
 
class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key});
 
  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}
 
class _AdminConfigScreenState extends State<AdminConfigScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminConfigViewModel>().fetchBrands();
      context.read<AdminConfigViewModel>().fetchVehicleModels();
      context.read<AdminConfigViewModel>().fetchCategories();
    });
  }
 
  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun admin?'),
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
 
  void _showAddBrandDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Tambah Merek Kendaraan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nama Merek:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'Contoh: Honda, Toyota, Yamaha',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3A5E)),
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              try {
                await context.read<AdminConfigViewModel>().addBrand(name);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Merek "$name" berhasil ditambahkan'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Gagal menambahkan: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
 
  void _showManageBrandDialog(BuildContext context, VehicleBrandModel brand) {
    final ctrl = TextEditingController(text: brand.name);
    final newModelCtrl = TextEditingController();
    String selectedType = 'Mobil';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final viewModel = context.watch<AdminConfigViewModel>();
          final brandModels = viewModel.vehicleModels.where((m) => 
            (m['brand']?.toString() ?? '').trim().toLowerCase() == brand.name.trim().toLowerCase()
          ).toList();

          return AlertDialog(
            scrollable: true,
            title: Text('Kelola: ${brand.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BRAND MANAGEMENT
                const Text('Ubah Nama Merek:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3A5E)),
                      onPressed: () async {
                        final newName = ctrl.text.trim();
                        if (newName.isEmpty) return;
                        try {
                          await context.read<AdminConfigViewModel>().updateBrand(brand.id, newName);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Merek berhasil diperbarui'), backgroundColor: Colors.green),
                            );
                            Navigator.pop(ctx);
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Gagal memperbarui: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                    label: const Text('Hapus Merek', style: TextStyle(color: Colors.red, fontSize: 12)),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: ctx,
                        builder: (confirmCtx) => AlertDialog(
                          title: const Text('Hapus Merek'),
                          content: Text('Hapus merek "${brand.name}"? Semua model di dalamnya juga akan terdampak.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(confirmCtx, false), child: const Text('Batal')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(confirmCtx, true),
                              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && ctx.mounted) {
                        try {
                          await context.read<AdminConfigViewModel>().deleteBrand(brand.id);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Merek berhasil dihapus'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }
                    },
                  ),
                ),
                
                const Divider(height: 24),
                // MODELS MANAGEMENT
                const Text('Model Kendaraan:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                brandModels.isEmpty
                    ? const Text('Belum ada model.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: brandModels.map((m) => _buildModelChip(context, m)).toList(),
                      ),
                
                const SizedBox(height: 24),
                const Text('Tambah Model Baru:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Mobil'),
                      selected: selectedType == 'Mobil',
                      onSelected: (val) { if (val) setState(() => selectedType = 'Mobil'); },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Motor'),
                      selected: selectedType == 'Motor',
                      onSelected: (val) { if (val) setState(() => selectedType = 'Motor'); },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: newModelCtrl,
                        decoration: InputDecoration(
                          hintText: 'Nama Model',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3A5E)),
                      onPressed: () async {
                        final name = newModelCtrl.text.trim();
                        if (name.isEmpty) return;
                        try {
                          await context.read<AdminConfigViewModel>().addVehicleModel(name, brand.name, selectedType);
                          if (ctx.mounted) {
                            newModelCtrl.clear();
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Model ditambahkan'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Gagal menambahkan: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      child: const Text('Tambah', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showManageModelDialog(BuildContext context, Map<String, dynamic> model) {
    final ctrl = TextEditingController(text: model['name']?.toString());
    String? selectedBrand = model['brand']?.toString();
    String selectedType = model['type']?.toString() ?? 'mobil';
    final id = model['id'].toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final vm = context.watch<AdminConfigViewModel>();
          return AlertDialog(
            scrollable: true,
            title: const Text('Kelola Model Kendaraan', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Merek:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: vm.brands.any((b) => b.name == selectedBrand) ? selectedBrand : null,
                  hint: Text(vm.brands.isEmpty ? 'Silakan tambah merek dulu' : 'Pilih Merek', 
                             style: TextStyle(color: vm.brands.isEmpty ? Colors.red : null)),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: vm.brands.isEmpty
                      ? [const DropdownMenuItem<String>(value: 'kosong', enabled: false, child: Text('Data merek kosong'))]
                      : vm.brands.map((b) => DropdownMenuItem(value: b.name, child: Text(b.name))).toList(),
                  onChanged: vm.brands.isEmpty ? null : (val) => setState(() => selectedBrand = val),
                ),
                const SizedBox(height: 12),
                const Text('Tipe:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Mobil'),
                      selected: selectedType == 'mobil',
                      onSelected: (val) { if (val) setState(() => selectedType = 'mobil'); },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Motor'),
                      selected: selectedType == 'motor',
                      onSelected: (val) { if (val) setState(() => selectedType = 'motor'); },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Nama Model:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: ctx,
                        builder: (confirmCtx) => AlertDialog(
                          title: const Text('Hapus Model'),
                          content: Text('Hapus model "${model['name']}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(confirmCtx, false), child: const Text('Batal')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(confirmCtx, true),
                              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && ctx.mounted) {
                        try {
                          await context.read<AdminConfigViewModel>().deleteVehicleModel(id);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Model dihapus'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3A5E)),
                        onPressed: () async {
                          final newName = ctrl.text.trim();
                          if (newName.isEmpty || selectedBrand == null) return;
                          try {
                            await context.read<AdminConfigViewModel>().updateVehicleModel(id, newName, selectedBrand!, selectedType);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Model diperbarui'), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Gagal memperbarui: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        }
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Tambah Kategori Layanan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nama Kategori:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                hintText: 'Contoh: Ganti Oli, Tune Up',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            const Text('Deskripsi:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Deskripsi singkat layanan...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3A5E)),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final desc = descCtrl.text.trim();
              if (name.isEmpty) return;
              try {
                await context.read<AdminConfigViewModel>().addCategory(name, desc);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kategori "$name" berhasil ditambahkan'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Gagal menambahkan: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
 
  void _showEditCategoryDialog(BuildContext context, ServiceCategoryModel category) {
    final nameCtrl = TextEditingController(text: category.name);
    final descCtrl = TextEditingController(text: category.description);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Kelola Kategori Layanan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nama Kategori:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Deskripsi:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (confirmCtx) => AlertDialog(
                      title: const Text('Hapus Kategori'),
                      content: Text('Hapus kategori "${category.name}" dari platform?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(confirmCtx, false), child: const Text('Batal')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(confirmCtx, true),
                          child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && ctx.mounted) {
                    try {
                      await context.read<AdminConfigViewModel>().deleteCategory(category.id);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kategori berhasil dihapus'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3A5E)),
                    onPressed: () async {
                      final newName = nameCtrl.text.trim();
                      final newDesc = descCtrl.text.trim();
                      if (newName.isEmpty) return;
                      try {
                        await context.read<AdminConfigViewModel>().updateCategory(category.id, newName, newDesc);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kategori berhasil diperbarui'), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Gagal memperbarui: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminConfigViewModel>();
 
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable body
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await context.read<AdminConfigViewModel>().fetchBrands();
                  await context.read<AdminConfigViewModel>().fetchVehicleModels();
                  await context.read<AdminConfigViewModel>().fetchCategories();
                },
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                children: [
 
                  // 1. Vehicle Brands Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.directions_car_filled_outlined, color: Color(0xFF1A3A5F), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Merek Kendaraan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => _showAddBrandDialog(context),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE3EFFC),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Color(0xFF1A3A5F),
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        viewModel.isLoading && viewModel.brands.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: viewModel.brands.isEmpty
                                    ? [
                                        const Text(
                                          'Belum ada merek kendaraan.',
                                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                        )
                                      ]
                                    : viewModel.brands
                                        .map((brand) => _buildBrandChip(context, brand))
                                        .toList(),
                              ),
                      ],
                    ),
                  ),
 


                  // 2. Service Categories Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.build_outlined, color: Color(0xFF1A3A5F), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Kategori Layanan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => _showAddCategoryDialog(context),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE3EFFC),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Color(0xFF1A3A5F),
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        viewModel.isLoading && viewModel.categories.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : viewModel.categories.isEmpty
                                ? const Text(
                                    'Belum ada kategori layanan.',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: viewModel.categories.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(height: 1, color: AppColors.border),
                                    itemBuilder: (context, index) {
                                      final cat = viewModel.categories[index];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          cat.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        trailing: const Icon(
                                          Icons.chevron_right,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                        onTap: () => _showEditCategoryDialog(context, cat),
                                      );
                                    },
                                  ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildBrandChip(BuildContext context, VehicleBrandModel brand) {
    return GestureDetector(
      onTap: () => _showManageBrandDialog(context, brand),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(brand.name, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(width: 4),
            const Icon(Icons.edit, size: 12, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildModelChip(BuildContext context, Map<String, dynamic> model) {
    final typeIcon = model['type'] == 'motor' ? Icons.two_wheeler : Icons.directions_car;
    return GestureDetector(
      onTap: () => _showManageModelDialog(context, model),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(typeIcon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('${model['brand']} ${model['name']}', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            const Icon(Icons.edit, size: 12, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
 