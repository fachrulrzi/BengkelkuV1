import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_screen.dart';

class RegisterPartnerScreen extends StatefulWidget {
  const RegisterPartnerScreen({super.key});

  @override
  State<RegisterPartnerScreen> createState() => _RegisterPartnerScreenState();
}

class _RegisterPartnerScreenState extends State<RegisterPartnerScreen> {
  final _workshopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedSpecialization = 'Hanya Mobil';

  final List<String> _specializations = ['Hanya Mobil', 'Hanya Motor', 'Mobil & Motor'];

  @override
  void dispose() {
    _workshopNameController.dispose();
    _ownerNameController.dispose();
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
                    'Kemitraan Bengkel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Daftarkan bengkel fisik Anda ke dalam jaringan digital',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 36),
                  CustomTextField(
                    label: 'NAMA BENGKEL',
                    hint: 'Nama Bengkel Anda',
                    controller: _workshopNameController,
                    borderRadius: 16,
                    borderColor: Colors.transparent,
                    focusedBorderColor: AppColors.primary,
                    fillColor: const Color(0xFFF1F5F9),
                    prefixIcon: const Icon(Icons.storefront_outlined),
                    prefixIconColor: const Color(0xFF64748B),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'NAMA PEMILIK',
                    hint: 'Nama Pemilik',
                    controller: _ownerNameController,
                    borderRadius: 16,
                    borderColor: Colors.transparent,
                    focusedBorderColor: AppColors.primary,
                    fillColor: const Color(0xFFF1F5F9),
                    prefixIcon: const Icon(Icons.person_outline),
                    prefixIconColor: const Color(0xFF64748B),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'EMAIL OPERASIONAL',
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
                    label: 'NOMOR HP BENGKEL',
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
                  const Text(
                    'SPESIALISASI LAYANAN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSpecialization,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        items: _specializations.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedSpecialization = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'KATA SANDI AKUN',
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
                    text: 'Ajukan Kemitraan',
                    isLoading: authViewModel.isLoading,
                    borderRadius: 16,
                    onPressed: () async {
                      try {
                        // Pass empty string for address since it's removed from UI
                        await authViewModel.registerPartner(
                          workshopName: _workshopNameController.text,
                          ownerName: _ownerNameController.text,
                          email: _emailController.text,
                          phone: _phoneController.text,
                          address: '', 
                          specialization: _selectedSpecialization,
                          password: _passwordController.text,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Registrasi Mitra berhasil! Silakan login.')),
                        );
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registrasi gagal: ${e.toString()}')),
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
