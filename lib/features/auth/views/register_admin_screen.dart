import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_screen.dart';

class RegisterAdminScreen extends StatefulWidget {
  const RegisterAdminScreen({super.key});

  @override
  State<RegisterAdminScreen> createState() => _RegisterAdminScreenState();
}

class _RegisterAdminScreenState extends State<RegisterAdminScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<AuthViewModel>(
            builder: (context, authViewModel, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Daftar Akun Admin',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kelola data master platform BengkelKu secara real-time',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    label: 'NAMA LENGKAP',
                    hint: 'Admin BengkelKu',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'EMAIL',
                    hint: 'admin@bengkelin.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'NOMOR HP',
                    hint: '08123456789',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_android_outlined, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'KATA SANDI',
                    hint: '••••••••',
                    controller: _passwordController,
                    obscureText: authViewModel.obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        authViewModel.obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: authViewModel.togglePasswordVisibility,
                    ),
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    text: 'Daftar Sebagai Admin',
                    isLoading: authViewModel.isLoading,
                    onPressed: () async {
                      if (_nameController.text.trim().isEmpty ||
                          _emailController.text.trim().isEmpty ||
                          _phoneController.text.trim().isEmpty ||
                          _passwordController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Semua field harus diisi!')),
                        );
                        return;
                      }
                      try {
                        await authViewModel.registerAdmin(
                          name: _nameController.text,
                          email: _emailController.text,
                          phone: _phoneController.text,
                          password: _passwordController.text,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Registrasi Admin berhasil! Silakan login.')),
                        );
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registrasi gagal: ${e.toString()}')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah memiliki akun? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
