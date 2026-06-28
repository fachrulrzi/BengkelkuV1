import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

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
          'Edit Profile',
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
                CustomTextField(
                  label: 'NAMA LENGKAP',
                  hint: 'John Doe',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'NOMOR HP',
                  hint: '08123456789',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nomor HP tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                CustomButton(
                  text: 'Simpan Perubahan',
                  isLoading: authViewModel.isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await authViewModel.updateProfile(
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profil berhasil diperbarui!')),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal memperbarui profil: $e')),
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
