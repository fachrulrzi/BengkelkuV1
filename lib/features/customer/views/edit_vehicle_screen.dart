import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../models/vehicle_model.dart';
import '../viewmodels/customer_profile_viewmodel.dart';

class EditVehicleScreen extends StatefulWidget {
  final VehicleModel vehicle;

  const EditVehicleScreen({super.key, required this.vehicle});

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBrand;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _licensePlateController;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedBrand = widget.vehicle.brand;
    _modelController = TextEditingController(text: widget.vehicle.model);
    _yearController = TextEditingController(text: widget.vehicle.year.toString());
    _licensePlateController = TextEditingController(text: widget.vehicle.licensePlate);
    _selectedType = widget.vehicle.type;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProfileViewModel>().fetchBrands();
    });
  }

  @override
  void dispose() {
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileViewModel = context.watch<CustomerProfileViewModel>();

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
          'Edit Vehicle',
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
                  'Perbarui detail kendaraan Anda.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
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
                  items: (() {
                    final list = List<String>.from(profileViewModel.brands);
                    if (_selectedBrand != null && !list.contains(_selectedBrand)) {
                      list.add(_selectedBrand!);
                    }
                    return list.map((brand) {
                      return DropdownMenuItem<String>(
                        value: brand,
                        child: Text(brand, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                      );
                    }).toList();
                  })(),
                  onChanged: (val) {
                    setState(() {
                      _selectedBrand = val;
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
                CustomTextField(
                  label: 'MODEL KENDARAAN',
                  hint: 'Avanza',
                  controller: _modelController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
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
                  text: 'Simpan Perubahan',
                  isLoading: profileViewModel.isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await profileViewModel.updateVehicle(
                          id: widget.vehicle.id,
                          brand: _selectedBrand!,
                          model: _modelController.text.trim(),
                          year: int.parse(_yearController.text.trim()),
                          licensePlate: _licensePlateController.text.trim().toUpperCase(),
                          type: _selectedType,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kendaraan berhasil diperbarui!')),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal memperbarui kendaraan: $e')),
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
