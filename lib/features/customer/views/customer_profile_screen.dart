import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/login_screen.dart';
import '../viewmodels/customer_profile_viewmodel.dart';
import 'add_vehicle_screen.dart';
import 'edit_profile_screen.dart';
import 'saved_addresses_screen.dart';
import 'edit_vehicle_screen.dart';
import 'order_history_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProfileViewModel>().fetchVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<AuthViewModel, CustomerProfileViewModel>(
        builder: (context, authViewModel, profileViewModel, child) {
          final user = authViewModel.currentUser;
          final initials = user?.name.isNotEmpty == true
              ? user!.name[0].toUpperCase()
              : 'R';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Section Redesigned
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    top: 60,
                    bottom: 40,
                    left: 24,
                    right: 24,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E2843), // Solid dark navy background
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: const Color(
                          0xFF2C3B5E,
                        ), // Lighter navy circle background
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'user@email.com',
                        style: const TextStyle(
                          color: Color(0xFF8C96A8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // My Garage Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Garage',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddVehicleScreen(),
                                ),
                              ).then((_) {
                                context
                                    .read<CustomerProfileViewModel>()
                                    .fetchVehicles();
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2C3B5E),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Color(0xFF2C3B5E),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Add Vehicle',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Vehicle List
                      if (profileViewModel.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (profileViewModel.vehicles.isEmpty)
                        const Text('Belum ada kendaraan di garasi.')
                      else
                        ...profileViewModel.vehicles.map(
                          (vehicle) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    vehicle.type == 'motor'
                                        ? Icons.motorcycle_outlined
                                        : Icons.directions_car_outlined,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${vehicle.brand} ${vehicle.model}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (vehicle.status == 'Active')
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8F5E9),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'Active',
                                                style: TextStyle(
                                                  color: Color(0xFF2E7D32),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${vehicle.year} • ${vehicle.licensePlate}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: AppColors.textSecondary,
                                  ),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditVehicleScreen(
                                                vehicle: vehicle,
                                              ),
                                        ),
                                      ).then((_) {
                                        if (context.mounted) {
                                          context
                                              .read<CustomerProfileViewModel>()
                                              .fetchVehicles();
                                        }
                                      });
                                    } else if (value == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Hapus Kendaraan'),
                                          content: const Text(
                                            'Apakah Anda yakin ingin menghapus kendaraan ini dari garasi?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Batal'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: const Text('Hapus'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true && context.mounted) {
                                        try {
                                          await context
                                              .read<CustomerProfileViewModel>()
                                              .deleteVehicle(vehicle.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'Kendaraan berhasil dihapus',
                                                ),
                                                backgroundColor:
                                                    Colors.green.shade600,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Gagal menghapus: $e',
                                                ),
                                                backgroundColor: Colors.red,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Hapus',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Menu Items Card Redesigned (Outline design style matching mockup)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              icon: Icons.person_outline,
                              title: 'Edit Profile',
                              iconColor: const Color(0xFF1E2843),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EditProfileScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 60, endIndent: 16),
                            _buildMenuItem(
                              icon: Icons.location_on_outlined,
                              title: 'Saved Addresses',
                              iconColor: const Color(0xFF1E2843),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SavedAddressesScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 60, endIndent: 16),
                            _buildMenuItem(
                              icon: Icons.history_outlined,
                              title: 'Order History',
                              iconColor: const Color(0xFF1E2843),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const OrderHistoryScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 60, endIndent: 16),
                            _buildMenuItem(
                              icon: Icons.notifications_none_outlined,
                              title: 'Notifications',
                              iconColor: const Color(0xFF1E2843),
                              onTap: () {},
                            ),
                            const Divider(height: 1, indent: 60, endIndent: 16),
                            _buildMenuItem(
                              icon: Icons.shield_outlined,
                              title: 'Privacy & Security',
                              iconColor: const Color(0xFF1E2843),
                              onTap: () {},
                            ),
                            const Divider(height: 1, indent: 60, endIndent: 16),
                            _buildMenuItem(
                              icon: Icons.help_outline,
                              title: 'Help & Support',
                              iconColor: const Color(0xFF1E2843),
                              onTap: () async {
                                final phone = '6281234567890';
                                final text =
                                    'Halo Admin BengkelKu, saya butuh bantuan terkait penggunaan aplikasi.';
                                final url = Uri.parse(
                                  'https://wa.me/$phone?text=${Uri.encodeComponent(text)}',
                                );
                                try {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Gagal membuka WhatsApp. Hubungi support@bengkelku.com',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            const Divider(height: 1, indent: 60, endIndent: 16),
                            _buildMenuItem(
                              icon: Icons.logout,
                              title: 'Logout',
                              titleColor: Colors.red,
                              iconColor: Colors.red,
                              onTap: () async {
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

                      const SizedBox(height: 32),

                      // Version Info
                      const Center(
                        child: Column(
                          children: [
                            Text(
                              'BengkelKu v1.0.0',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '© 2026 BengkelKu. All rights reserved.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Color? titleColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: titleColor ?? const Color(0xFF1E2843),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey.shade400,
        size: 18,
      ),
      onTap: onTap,
    );
  }
}
