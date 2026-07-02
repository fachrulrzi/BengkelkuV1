import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../customer/viewmodels/workshop_report_viewmodel.dart';
import '../models/workshop_report_model.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _activeFilter = 'all'; // 'all', 'pending', 'suspended', 'dismissed'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkshopReportViewModel>().fetchReports();
    });
  }

  Future<void> _handleSuspend(WorkshopReportModel report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Konfirmasi Suspensi', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menangguhkan (suspend) bengkel "${report.bengkel?['name'] ?? 'Bengkel'}"? Tindakan ini akan memblokir operasional bengkel tersebut.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Suspend', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context
          .read<WorkshopReportViewModel>()
          .suspendBengkel(report.bengkelId, report.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Bengkel "${report.bengkel?['name']}" berhasil ditangguhkan!'), backgroundColor: Colors.green),
);
        context.read<WorkshopReportViewModel>().fetchReports();
      } else if (mounted) {
        final errorMsg = context.read<WorkshopReportViewModel>().error ?? 'Terjadi kesalahan';
        ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Gagal melakukan suspensi: $errorMsg'), backgroundColor: Colors.red),
);
      }
    }
  }

  Future<void> _handleDismiss(WorkshopReportModel report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Abaikan Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin mengabaikan laporan terhadap "${report.bengkel?['name'] ?? 'Bengkel'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Abaikan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context
          .read<WorkshopReportViewModel>()
          .updateReportStatus(report.id, 'dismissed');

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Laporan diabaikan.'), backgroundColor: Colors.blue),
);
        context.read<WorkshopReportViewModel>().fetchReports();
      } else if (mounted) {
        final errorMsg = context.read<WorkshopReportViewModel>().error ?? 'Terjadi kesalahan';
        ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Gagal memperbarui status: $errorMsg'), backgroundColor: Colors.red),
);
      }
    }
  }

  Future<void> _handleUnsuspend(WorkshopReportModel report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Konfirmasi Buka Suspensi', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan status pembekuan (unsuspend) bengkel "${report.bengkel?['name'] ?? 'Bengkel'}"? Bengkel akan dapat beroperasi kembali secara normal.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Buka Suspensi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context
          .read<WorkshopReportViewModel>()
          .unsuspendBengkel(report.bengkelId, report.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Status pembekuan "${report.bengkel?['name']}" berhasil dibuka! Bengkel aktif kembali.'), backgroundColor: Colors.green),
);
        context.read<WorkshopReportViewModel>().fetchReports();
      } else if (mounted) {
        final errorMsg = context.read<WorkshopReportViewModel>().error ?? 'Terjadi kesalahan';
        ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Gagal membuka suspensi: $errorMsg'), backgroundColor: Colors.red),
);
      }
    }
  }

  void _showImagePreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          SizedBox(height: 8),
                          Text('Gagal memuat gambar', style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<WorkshopReportViewModel>(
        builder: (context, vm, child) {
          List<WorkshopReportModel> filteredReports = [];
          if (_activeFilter == 'all') {
            filteredReports = vm.reports;
          } else {
            filteredReports = vm.reports.where((r) => r.status == _activeFilter).toList();
          }

          return RefreshIndicator(
            onRefresh: () => vm.fetchReports(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Buttons Row
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton('all', 'Semua (${vm.reports.length})'),
                        const SizedBox(width: 8),
                        _buildFilterButton('pending', 'Pending (${vm.reports.where((r) => r.status == 'pending').length})'),
                        const SizedBox(width: 8),
                        _buildFilterButton('reviewed', 'Ditinjau (${vm.reports.where((r) => r.status == 'reviewed').length})'),
                        const SizedBox(width: 8),
                        _buildFilterButton('suspended', 'Suspended (${vm.reports.where((r) => r.status == 'suspended').length})'),
                        const SizedBox(width: 8),
                        _buildFilterButton('dismissed', 'Abaikan (${vm.reports.where((r) => r.status == 'dismissed').length})'),
                      ],
                    ),
                  ),
                ),

                // Content List
                Expanded(
                  child: vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredReports.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'Tidak ada laporan ditemukan',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Semua aman dan berjalan kondusif!',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: filteredReports.length,
                              itemBuilder: (context, index) {
                                final report = filteredReports[index];
                                return _buildReportCard(report);
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterButton(String filterCode, String label) {
    final isActive = _activeFilter == filterCode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = filterCode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1B2E3C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B2E3C).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(WorkshopReportModel report) {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt);
    final isPending = report.status.toLowerCase().trim() == 'pending';
    
    Color statusColor = Colors.orange;
    String statusText = 'Pending';
    if (report.status == 'suspended') {
      statusColor = Colors.red;
      statusText = 'Suspended';
    } else if (report.status == 'dismissed') {
      statusColor = Colors.grey;
      statusText = 'Diabaikan';
    } else if (report.status == 'reviewed') {
      statusColor = Colors.blue;
      statusText = 'Ditinjau';
    }

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
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Bengkel & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  report.bengkel?['name'] as String? ?? 'Bengkel Tidak Dikenal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Bengkel Address
          Text(
            report.bengkel?['address'] as String? ?? 'Alamat tidak dicantumkan',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const Divider(height: 24, color: Color(0xFFEEEEEE)),

          // Reporter Details
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: 'Pelapor: '),
                      TextSpan(
                        text: report.reporter?['full_name'] as String? ?? 'Pelanggan',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      TextSpan(text: ' (${report.reporter?['email'] as String? ?? '-'})'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Date
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Waktu: $dateStr',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Reason/Details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alasan / Kronologi Kecurangan:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  report.reason,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Evidence Image if exists
          if (report.evidenceUrl != null && report.evidenceUrl!.isNotEmpty) ...[
            const Text(
              'Bukti Pendukung:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showImagePreview(context, report.evidenceUrl!),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      report.evidenceUrl!,
                      height: 120,
                      width: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 120,
                          width: 200,
                          color: Colors.grey.shade100,
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        width: 200,
                        color: Colors.grey.shade100,
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined, color: Colors.grey),
                            SizedBox(height: 4),
                            Text('Gagal memuat gambar', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 10),
                          SizedBox(width: 4),
                          Text('Lihat Bukti', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Actions
          if (isPending || report.status == 'reviewed') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _handleDismiss(report),
                    icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                    label: const Text('Abaikan', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () => _handleSuspend(report),
                    icon: const Icon(Icons.block, size: 16, color: Colors.white),
                    label: const Text('Suspend Bengkel', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
          if (report.status == 'suspended') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () => _handleUnsuspend(report),
                    icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                    label: const Text('Buka Suspensi', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
