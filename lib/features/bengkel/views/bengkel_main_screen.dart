import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/bengkel_dashboard_viewmodel.dart';
import 'bengkel_dashboard_screen.dart';
import 'bengkel_orders_screen.dart';
import 'bengkel_mechanics_screen.dart';
import 'bengkel_profile_screen.dart';
import 'bengkel_booking_list_screen.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';

class BengkelMainScreen extends StatefulWidget {
  const BengkelMainScreen({super.key});

  @override
  State<BengkelMainScreen> createState() => _BengkelMainScreenState();
}

class _BengkelMainScreenState extends State<BengkelMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const BengkelDashboardScreen(),
    const BengkelBookingListScreen(),
    const BengkelOrdersScreen(),
    const BengkelMechanicsScreen(),
    const BengkelProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthViewModel>().currentUser?.id;
      context.read<BengkelDashboardViewModel>().fetchBengkelStatus(userId: userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BengkelDashboardViewModel>(
      builder: (context, viewModel, child) {
        final isVerified =
            viewModel.status == 'diterima' || viewModel.status == 'active';

        return Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: _BengkelBottomNav(
            selectedIndex: _selectedIndex,
            isVerified: isVerified,
            onTap: (index) {
              if (!isVerified && index != 0 && index != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: const [
                        Icon(Icons.lock_outline, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Akun belum terverifikasi. Selesaikan verifikasi terlebih dahulu.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF1E2843),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}

// ─── Custom Bottom Nav for Bengkel ────────────────────────────────────────

class _BengkelBottomNav extends StatelessWidget {
  final int selectedIndex;
  final bool isVerified;
  final ValueChanged<int> onTap;

  const _BengkelBottomNav({
    required this.selectedIndex,
    required this.isVerified,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard', locked: false),
      _NavItem(icon: Icons.car_repair_outlined, activeIcon: Icons.car_repair_rounded, label: 'Booking', locked: !isVerified),
      _NavItem(icon: Icons.store_outlined, activeIcon: Icons.store_rounded, label: 'Toko', locked: !isVerified),
      _NavItem(icon: Icons.people_outline, activeIcon: Icons.people_rounded, label: 'Mekanik', locked: !isVerified),
      _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profil', locked: false),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                size: 22,
                                color: isSelected
                                    ? AppColors.primary
                                    : item.locked
                                        ? AppColors.textSecondary.withValues(alpha: 0.4)
                                        : AppColors.textSecondary,
                              ),
                            ),
                            if (item.locked)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.lock, color: Colors.white, size: 7),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : item.locked
                                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                                    : AppColors.textSecondary,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool locked;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.locked,
  });
}
