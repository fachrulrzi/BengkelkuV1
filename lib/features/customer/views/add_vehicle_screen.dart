import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../viewmodels/customer_profile_viewmodel.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBrand;
  String? _selectedModel;
  final _yearController = TextEditingController();
  final _licensePlateController = TextEditingController();
  String _selectedType = 'mobil';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProfileViewModel>().fetchBrands();
      context.read<CustomerProfileViewModel>().fetchVehicleModels();
    });
  }

  @override
  void dispose() {
    _yearController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileViewModel = context.watch<CustomerProfileViewModel>();

    final filteredModels = profileViewModel.vehicleModels.where((m) {
      final String mBrand = m['brand']?.toString().toLowerCase() ?? '';
      final String mType = m['type']?.toString().toLowerCase() ?? '';
      return mBrand == _selectedBrand?.toLowerCase() && mType == _selectedType.toLowerCase();
    }).map((m) => m['name']?.toString() ?? '').where((n) => n.isNotEmpty).toSet().toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Vehicle',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Masukkan detail kendaraan Anda untuk ditambahkan ke garasi.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // 1. MEREK KENDARAAN (Pilih Merek dulu)
                const Text(
                  'MEREK KENDARAAN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedBrand,
                  hint: const Text('Pilih Merek (contoh: Honda, Toyota)', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  items: profileViewModel.brands.map((brand) {
                    return DropdownMenuItem<String>(
                      value: brand,
                      child: Text(brand, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedBrand = val;
                      _selectedModel = null; // reset model when brand changes
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Merek tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 2. JENIS KENDARAAN (Pilih Jenis kedua)
                const Text(
                  'JENIS KENDARAAN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Mobil'),
                      selected: _selectedType == 'mobil',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedType = 'mobil';
                            _selectedModel = null; // reset model when type changes
                          });
                        }
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: _selectedType == 'mobil' ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Motor'),
                      selected: _selectedType == 'motor',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedType = 'motor';
                            _selectedModel = null; // reset model when type changes
                          });
                        }
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: _selectedType == 'motor' ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. MODEL KENDARAAN (Pilih Model ketiga via Dropdown)
                const Text(
                  'MODEL KENDARAAN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedModel,
                  hint: Text(
                    _selectedBrand == null
                        ? 'Pilih merek terlebih dahulu'
                        : 'Pilih Model (contoh: Civic RS)',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  items: filteredModels.map((modelName) {
                    return DropdownMenuItem<String>(
                      value: modelName,
                      child: Text(modelName, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                    );
                  }).toList(),
                  onChanged: _selectedBrand == null ? null : (val) {
                    setState(() {
                      _selectedModel = val;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Model tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  label: 'TAHUN PEMBUATAN',
                  hint: '2021',
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Tahun tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Tahun harus berupa angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'PLAT NOMOR KENDARAAN',
                  hint: 'B 1234 XYZ',
                  controller: _licensePlateController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Plat nomor tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                CustomButton(
                  text: 'Simpan Kendaraan',
                  isLoading: profileViewModel.isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await profileViewModel.addVehicle(
                          brand: _selectedBrand!,
                          model: _selectedModel!,
                          year: int.parse(_yearController.text.trim()),
                          licensePlate: _licensePlateController.text.trim().toUpperCase(),
                          type: _selectedType,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kendaraan berhasil ditambahkan!')),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal menambahkan kendaraan: $e')),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
