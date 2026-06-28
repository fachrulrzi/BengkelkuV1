import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/bengkel_dashboard_viewmodel.dart';
import '../viewmodels/bengkel_manage_service_viewmodel.dart';
import 'add_edit_bengkel_service_screen.dart';

class BengkelServiceListScreen extends StatefulWidget {
  const BengkelServiceListScreen({super.key});

  @override
  State<BengkelServiceListScreen> createState() => _BengkelServiceListScreenState();
}

class _BengkelServiceListScreenState extends State<BengkelServiceListScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bengkelId = context.read<BengkelDashboardViewModel>().bengkelId;
      if (bengkelId.isNotEmpty) {
        context.read<BengkelManageServiceViewModel>().fetchMyServices(bengkelId);
        context.read<BengkelManageServiceViewModel>().fetchMasterCategories();
      }
    });
  }

  void _confirmDelete(String serviceId, String bengkelId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Layanan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin menghapus layanan ini?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BengkelManageServiceViewModel>().deleteService(serviceId, bengkelId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bengkelId = context.watch<BengkelDashboardViewModel>().bengkelId;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2843),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Kelola Layanan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditBengkelServiceScreen(bengkelId: bengkelId),
            ),
          );
        },
        backgroundColor: const Color(0xFFF2B300),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Layanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<BengkelManageServiceViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (vm.fetchError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Terjadi Kesalahan saat Membaca Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(vm.fetchError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => vm.fetchMyServices(bengkelId),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (vm.services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.design_services_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Belum ada layanan yang ditambahkan', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Tekan tombol + di bawah untuk menambah', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vm.services.length,
            itemBuilder: (context, index) {
              final service = vm.services[index];
              int iconCode = 0xe8b8; // default settings icon
              if (service.iconCode != null) {
                final intParsed = int.tryParse(service.iconCode!);
                if (intParsed != null) {
                  iconCode = intParsed;
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(IconData(iconCode, fontFamily: 'MaterialIcons'), color: Colors.blue.shade600, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                service.description,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddEditBengkelServiceScreen(bengkelId: bengkelId, service: service),
                                ),
                              );
                            } else if (value == 'delete') {
                              _confirmDelete(service.id, bengkelId);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Hapus', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, thickness: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Harga Layanan', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              currencyFormat.format(service.basePrice),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3A5E), fontSize: 14),
                            ),
                          ],
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
    );
  }
}
