import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/customer_profile_viewmodel.dart';
import 'add_vehicle_screen.dart';
import 'edit_vehicle_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Garage / Vehicle List',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
              ).then((_) {
                if (!context.mounted) return;
                context.read<CustomerProfileViewModel>().fetchVehicles();
              });
            },
          )
        ],
      ),
      body: Consumer<CustomerProfileViewModel>(
        builder: (context, profileViewModel, child) {
          if (profileViewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          final vehicles = profileViewModel.vehicles;

          if (vehicles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_car_outlined,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Belum ada kendaraan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tambahkan kendaraan pertama Anda untuk mulai mengelola garasi dan jadwal servis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
                        ).then((_) {
                          if (!context.mounted) return;
                          context.read<CustomerProfileViewModel>().fetchVehicles();
                        });
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        vehicle.type == 'motor' ? Icons.motorcycle_outlined : Icons.directions_car_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${vehicle.brand} ${vehicle.model}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (vehicle.status == 'Active')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
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
                      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditVehicleScreen(vehicle: vehicle),
                            ),
                          ).then((_) {
                            if (!context.mounted) return;
                            context.read<CustomerProfileViewModel>().fetchVehicles();
                          });
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hapus Kendaraan'),
                              content: const Text('Apakah Anda yakin ingin menghapus kendaraan ini dari garasi?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            try {
                              await context.read<CustomerProfileViewModel>().deleteVehicle(vehicle.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Kendaraan berhasil dihapus'),
                                    backgroundColor: Colors.green.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal menghapus: $e'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Hapus', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
          ).then((_) {
            if (!context.mounted) return;
            context.read<CustomerProfileViewModel>().fetchVehicles();
          });
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
