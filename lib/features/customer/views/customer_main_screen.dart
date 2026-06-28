import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/login_screen.dart';
import 'customer_dashboard_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_explore_screen.dart';
import 'customer_activity_screen.dart';
import 'emergency_sos_screen.dart';
import '../viewmodels/customer_profile_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';
class CustomerMainScreen extends StatefulWidget {
  final int initialIndex;
  const CustomerMainScreen({super.key, this.initialIndex = 0});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  late int _currentIndex;

  final List<Widget> _pages = [
    const CustomerDashboardScreen(),
    const CustomerExploreScreen(),
    const CustomerActivityScreen(),
    const CustomerProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _CustomerDrawer(
        currentIndex: _currentIndex,
        onTapTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Premium Sidebar Drawer ────────────────────────────────────────────────

class _CustomerDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTapTab;

  const _CustomerDrawer({
    required this.currentIndex,
    required this.onTapTab,
  });

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final profileViewModel = context.watch<CustomerProfileViewModel>();
    final user = authViewModel.currentUser;
    final initials = user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'R';
    final activeVehicle = profileViewModel.activeVehicle;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // ── Premium Header ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 28,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2843),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + Edit button row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF2B300), Color(0xFFFF8C00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF2B300).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onTapTab(3);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_outlined, color: Colors.white70, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? 'User',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? 'user@email.com',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8C96A8),
                    fontSize: 12,
                  ),
                ),
                // Active vehicle badge
                if (activeVehicle != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          activeVehicle.type == 'motor'
                              ? Icons.motorcycle_outlined
                              : Icons.directions_car_outlined,
                          color: const Color(0xFFF2B300),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${activeVehicle.brand} ${activeVehicle.model}',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Menu Items ──────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
                  child: Text(
                    'MENU UTAMA',
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                _DrawerItem(
                  icon: Icons.home_rounded,
                  label: 'Beranda',
                  isSelected: currentIndex == 0,
                  onTap: () {
                    Navigator.pop(context);
                    onTapTab(0);
                  },
                ),
                _DrawerItem(
                  icon: Icons.explore_rounded,
                  label: 'Marketplace',
                  isSelected: currentIndex == 1,
                  onTap: () {
                    Navigator.pop(context);
                    onTapTab(1);
                  },
                ),
                _DrawerItem(
                  icon: Icons.assignment_rounded,
                  label: 'Riwayat Servis',
                  isSelected: currentIndex == 2,
                  onTap: () {
                    Navigator.pop(context);
                    onTapTab(2);
                  },
                ),
                _DrawerItem(
                  icon: Icons.person_rounded,
                  label: 'Profil Saya',
                  isSelected: currentIndex == 3,
                  onTap: () {
                    Navigator.pop(context);
                    onTapTab(3);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 6),
                  child: Text(
                    'LAYANAN DARURAT',
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                _DrawerItem(
                  icon: Icons.warning_amber_rounded,
                  label: 'Emergency SOS',
                  isSelected: false,
                  iconColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmergencySosScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Logout Footer ───────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                ),
                title: Text(
                  'Keluar',
                  style: GoogleFonts.outfit(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Logout dari akun',
                  style: GoogleFonts.outfit(color: Colors.red, fontSize: 11),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await context.read<AuthViewModel>().signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Drawer Menu Item ──────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? iconColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    const selectedBg = Color(0xFF1E2843);
    final resolvedIconColor =
        iconColor ?? (isSelected ? Colors.white : AppColors.textSecondary);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: selectedBg.withValues(alpha: 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? selectedBg.withValues(alpha: 0.07) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: selectedBg.withValues(alpha: 0.12))
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? selectedBg
                        : (iconColor != null
                            ? iconColor!.withValues(alpha: 0.08)
                            : const Color(0xFFF5F7FA)),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: resolvedIconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: isSelected ? selectedBg : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2B300),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
