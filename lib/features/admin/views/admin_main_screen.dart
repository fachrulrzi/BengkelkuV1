import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'admin_dashboard_screen.dart';
import 'admin_config_screen.dart';
import 'admin_verification_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_users_screen.dart';
import 'package:provider/provider.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/login_screen.dart';
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboardScreen(),
    const AdminUsersScreen(),
    const AdminVerificationScreen(),
    const AdminReportsScreen(),
    const AdminConfigScreen(),
  ];

  final List<Map<String, String>> _pageHeaders = [
    {
      'title': 'Admin Dashboard',
      'subtitle': 'Platform Management & Analytics',
    },
    {
      'title': 'Manajemen Pengguna',
      'subtitle': 'Daftar, ubah, dan hapus pengguna',
    },
    {
      'title': 'Verifikasi Mitra',
      'subtitle': 'Kelola pengajuan bengkel',
    },
    {
      'title': 'Laporan Bengkel',
      'subtitle': 'Tinjau laporan kecurangan',
    },
    {
      'title': 'Pengaturan Platform',
      'subtitle': 'Konfigurasi sistem admin',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Unified Admin Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1B2E3C), // Dark theme color for admin
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pageHeaders[_currentIndex]['title']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _pageHeaders[_currentIndex]['subtitle']!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
                    await context.read<AuthViewModel>().signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Page Content
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Pengguna',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Mitra',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem_outlined),
            activeIcon: Icon(Icons.report_problem),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
