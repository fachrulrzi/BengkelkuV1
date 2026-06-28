import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/bengkel_dashboard_viewmodel.dart';
import '../viewmodels/bengkel_mechanic_viewmodel.dart';
import '../models/mechanic_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_mechanic_bottom_sheet.dart';

class BengkelMechanicsScreen extends StatefulWidget {
  const BengkelMechanicsScreen({super.key});

  @override
  State<BengkelMechanicsScreen> createState() => _BengkelMechanicsScreenState();
}

class _BengkelMechanicsScreenState extends State<BengkelMechanicsScreen> {
  String _lastFetchedBengkelId = '';

  @override
  Widget build(BuildContext context) {
    final dashboardVM = Provider.of<BengkelDashboardViewModel>(context);
    
    if (dashboardVM.bengkelId.isNotEmpty && dashboardVM.bengkelId != _lastFetchedBengkelId) {
      _lastFetchedBengkelId = dashboardVM.bengkelId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<BengkelMechanicViewModel>().fetchMechanics(dashboardVM.bengkelId);
        }
      });
    }

    final bengkelName = dashboardVM.bengkelName.isNotEmpty ? dashboardVM.bengkelName : 'Bengkel Saya';
    final isVerified = dashboardVM.status == 'diterima' || dashboardVM.status == 'active';

    return Consumer<BengkelMechanicViewModel>(
      builder: (context, mechanicVM, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context, bengkelName, isVerified),
          body: mechanicVM.isLoading && mechanicVM.mechanics.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => mechanicVM.fetchMechanics(dashboardVM.bengkelId),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header "Tim Mekanik" & Tambah
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tim Mekanik',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const AddMechanicBottomSheet(),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              icon: const Icon(Icons.add, color: Colors.white, size: 18),
                              label: const Text('Tambah', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Stats Row
                        Row(
                          children: [
                            _buildStatCard('${mechanicVM.availableCount}', 'Tersedia'),
                            const SizedBox(width: 8),
                            _buildStatCard('${mechanicVM.busyCount}', 'Bertugas'),
                            const SizedBox(width: 8),
                            _buildStatCard('${mechanicVM.offlineCount}', 'Offline'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // List Mekanik
                        if (mechanicVM.mechanics.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 32.0),
                              child: Text('Belum ada mekanik', style: TextStyle(color: AppColors.textSecondary)),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: mechanicVM.mechanics.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final mechanic = mechanicVM.mechanics[index];
                              return _buildMechanicCard(mechanic);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String bengkelName, bool isVerified) {
    final nameInitial = bengkelName.isNotEmpty ? bengkelName[0].toUpperCase() : 'B';
    return AppBar(
      backgroundColor: const Color(0xFF1E2843),
      elevation: 0,
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF2B300), Color(0xFFFF8C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              nameInitial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bengkelName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: isVerified ? const Color(0xFF4ADE80) : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isVerified ? 'Mitra Terverifikasi' : 'Belum Terverifikasi',
                  style: TextStyle(
                    color: isVerified ? const Color(0xFF4ADE80) : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
            ),
            onPressed: () {
              // Placeholder logout logic, similar to dashboard
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String count, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMechanicCard(MechanicModel mechanic) {
    Color statusColor;
    Color statusBgColor;
    if (mechanic.status == 'Bertugas') {
      statusColor = Colors.blue;
      statusBgColor = Colors.blue.shade50;
    } else if (mechanic.status == 'Offline') {
      statusColor = Colors.grey;
      statusBgColor = Colors.grey.shade200;
    } else {
      statusColor = Colors.green;
      statusBgColor = Colors.green.shade50;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: mechanic.photoUrl == null
                  ? const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              image: mechanic.photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(mechanic.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: mechanic.photoUrl == null
                ? Text(
                    mechanic.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        mechanic.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        mechanic.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  mechanic.specialist,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      mechanic.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${mechanic.servicesCount} servis',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Row(
            children: [
              _buildIconButton(Icons.phone, () => _launchWhatsApp(mechanic.phone)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: AppColors.textPrimary),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _launchWhatsApp(String phone) async {
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor telepon mekanik tidak tersedia')),
        );
      }
      return;
    }
    
    String formattedPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('62')) {
      // Assuming it's already properly formatted or doesn't start with 0/62
    }

    final url = Uri.parse('https://wa.me/$formattedPhone');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    }
  }
}
