import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/bengkel_mechanic_viewmodel.dart';
import '../viewmodels/bengkel_dashboard_viewmodel.dart';
import '../../admin/viewmodels/admin_config_viewmodel.dart';

class AddMechanicBottomSheet extends StatefulWidget {
  const AddMechanicBottomSheet({super.key});

  @override
  State<AddMechanicBottomSheet> createState() => _AddMechanicBottomSheetState();
}

class _AddMechanicBottomSheetState extends State<AddMechanicBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final List<String> _selectedSpecialties = [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminConfigViewModel>().fetchCategories();
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSpecialties.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih minimal satu spesialisasi')),
        );
        return;
      }

      final mechanicVM = context.read<BengkelMechanicViewModel>();
      final dashboardVM = context.read<BengkelDashboardViewModel>();

      try {
        await mechanicVM.addMechanic(
          bengkelId: dashboardVM.bengkelId,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          specialist: _selectedSpecialties.join(', '),
          password: _passwordController.text.trim(),
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mekanik berhasil ditambahkan')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menambahkan mekanik: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<BengkelMechanicViewModel>().isLoading;
    final adminVM = context.watch<AdminConfigViewModel>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tambah Mekanik',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Nama Lengkap',
                hint: 'Nama mekanik',
                controller: _nameController,
                validator: (val) => val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Spesialisasi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: adminVM.categories.map((cat) {
                  final isSelected = _selectedSpecialties.contains(cat.name);
                  return FilterChip(
                    label: Text(
                      cat.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedSpecialties.add(cat.name);
                        } else {
                          _selectedSpecialties.remove(cat.name);
                        }
                      });
                    },
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_selectedSpecialties.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    '* Pilih minimal satu spesialisasi',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Email',
                hint: 'email@contoh.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'No. Telepon',
                hint: '0812xxxxxx',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Password',
                hint: 'Minimal 6 karakter',
                controller: _passwordController,
                obscureText: true,
                validator: (val) => val != null && val.isNotEmpty && val.length < 6
                    ? 'Password minimal 6 karakter'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Tambah Mekanik',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
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
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
