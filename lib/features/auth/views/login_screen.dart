import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/google_logo.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/user_model.dart';
import 'role_selection_screen.dart';
import '../../customer/views/customer_main_screen.dart';
import '../../bengkel/views/bengkel_main_screen.dart';
import '../../mekanik/views/mekanik_main_screen.dart';
import '../../mekanik/viewmodels/mekanik_dashboard_viewmodel.dart';
import '../../admin/views/admin_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isInitializing = true;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    });

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        final authViewModel = context.read<AuthViewModel>();
        // Jika login via OAuth (Google), currentUser mungkin masih null
        if (authViewModel.currentUser == null) {
          await authViewModel.checkSession();
          if (authViewModel.currentUser != null && mounted) {
            final role = authViewModel.currentUser?.role;
            if (role == UserRole.admin) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminMainScreen()));
            } else if (role == UserRole.bengkel) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BengkelMainScreen()));
            } else if (role == UserRole.mekanik) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MekanikMainScreen()));
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CustomerMainScreen()));
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Consumer<AuthViewModel>(
            builder: (context, authViewModel, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(AppAssets.logo, height: 26),
                          const SizedBox(width: 8),
                          Text(
                            'BengkelKu',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.help_outline, size: 24),
                        color: AppColors.primary,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Selamat datang',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masuk ke akun Anda untuk melanjutkan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9), // Soft grey background card
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          label: 'EMAIL / NAMA / NO TELP',
                          hint: 'Email, Nama, atau No Telp',
                          controller: _emailController,
                          borderRadius: 16,
                          borderColor: Colors.transparent,
                          focusedBorderColor: AppColors.primary,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.person_outline),
                          prefixIconColor: const Color(0xFF64748B),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'KATA SANDI',
                          hint: '••••••••',
                          controller: _passwordController,
                          obscureText: authViewModel.obscurePassword,
                          borderRadius: 16,
                          borderColor: Colors.transparent,
                          focusedBorderColor: AppColors.primary,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.lock_outline),
                          prefixIconColor: const Color(0xFF64748B),
                          suffixIcon: IconButton(
                            icon: Icon(
                              authViewModel.obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: authViewModel.togglePasswordVisibility,
                          ),
                          suffixIconColor: const Color(0xFF64748B),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Lupa Kata Sandi?',
                              style: TextStyle(
                                color: Color(0xFF1E40AF),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Sign In',
                          height: 46,
                          isLoading: authViewModel.isLoading,
                          borderRadius: 16,
                          onPressed: () async {
                            try {
                              await authViewModel.login(
                                _emailController.text,
                                _passwordController.text,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Login berhasil!'), backgroundColor: Colors.blue),
);
                              final role = authViewModel.currentUser?.role;
                              if (role == UserRole.admin) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminMainScreen(),
                                  ),
                                );
                              } else if (role == UserRole.bengkel) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BengkelMainScreen(),
                                  ),
                                );
                              } else if (role == UserRole.mekanik) {
                                final mechData = authViewModel.mechanicData;
                                if (mechData != null) {
                                  context.read<MekanikDashboardViewModel>().setMechanicData(mechData);
                                }
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MekanikMainScreen(),
                                  ),
                                );
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CustomerMainScreen(),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Login gagal: ${e.toString()}'), backgroundColor: Colors.blue),
);
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'ATAU MASUK DENGAN',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Google',
                          height: 46,
                          isOutlined: true,
                          borderRadius: 16,
                          borderColor: const Color(0xFFE2E8F0),
                          backgroundColor: Colors.white,
                          textColor: AppColors.primary,
                          icon: const GoogleLogo(size: 20),
                          onPressed: () async {
                            try {
                              await authViewModel.loginWithGoogle();
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Login Google gagal: ${e.toString()}'), backgroundColor: Colors.blue),
);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RoleSelectionScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Buat Akun',
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
