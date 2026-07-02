import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_screen.dart';
import '../../customer/views/customer_main_screen.dart';

class RegisterCustomerScreen extends StatefulWidget {
  const RegisterCustomerScreen({super.key});

  @override
  State<RegisterCustomerScreen> createState() => _RegisterCustomerScreenState();
}

class _RegisterCustomerScreenState extends State<RegisterCustomerScreen> {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Consumer<AuthViewModel>(
            builder: (context, authViewModel, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Daftar Akun',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mulai rawat kendaraanmu dengan kemudahan digital',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 36),
                  CustomTextField(
                    label: 'NAMA LENGKAP',
                    hint: 'John Doe',
                    controller: _nameController,
                    borderRadius: 16,
                    borderColor: Colors.transparent,
                    focusedBorderColor: AppColors.primary,
                    fillColor: const Color(0xFFF1F5F9),
                    prefixIcon: const Icon(Icons.person_outline),
                    prefixIconColor: const Color(0xFF64748B),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'EMAIL',
                    hint: 'nama@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    borderRadius: 16,
                    borderColor: Colors.transparent,
                    focusedBorderColor: AppColors.primary,
                    fillColor: const Color(0xFFF1F5F9),
                    prefixIcon: const Icon(Icons.mail_outline),
                    prefixIconColor: const Color(0xFF64748B),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'NOMOR HP',
                    hint: '08123456789',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    borderRadius: 16,
                    borderColor: Colors.transparent,
                    focusedBorderColor: AppColors.primary,
                    fillColor: const Color(0xFFF1F5F9),
                    prefixIcon: const Icon(Icons.smartphone_outlined),
                    prefixIconColor: const Color(0xFF64748B),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'KATA SANDI',
                    hint: '••••••••',
                    controller: _passwordController,
                    obscureText: authViewModel.obscurePassword,
                    borderRadius: 16,
                    borderColor: Colors.transparent,
                    focusedBorderColor: AppColors.primary,
                    fillColor: const Color(0xFFF1F5F9),
                    prefixIcon: const Icon(Icons.lock_outline),
                    prefixIconColor: const Color(0xFF64748B),
                    suffixIcon: IconButton(
                      icon: Icon(
                        authViewModel.obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      ),
                      onPressed: authViewModel.togglePasswordVisibility,
                    ),
                    suffixIconColor: const Color(0xFF64748B),
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    text: 'Daftar Sekarang',
                    isLoading: authViewModel.isLoading,
                    borderRadius: 16,
                    onPressed: () async {
                      try {
                        await authViewModel.registerCustomer(
                          name: _nameController.text,
                          email: _emailController.text,
                          phone: _phoneController.text,
                          password: _passwordController.text,
                        );
                        
                        await authViewModel.login(
                          _emailController.text,
                          _passwordController.text,
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Registrasi berhasil! Anda langsung masuk.'), backgroundColor: Colors.blue),
                        );
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const CustomerMainScreen()),
                          (route) => false,
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registrasi gagal: ${e.toString()}'), backgroundColor: Colors.blue),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah memiliki akun? ',
                        style: TextStyle(color: Color(0xFF64748B)),
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
                            color: Color(0xFF1E40AF),
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
