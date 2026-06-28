import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/mekanik_dashboard_viewmodel.dart';
import '../models/mechanic_task_model.dart';

class MekanikHistoryScreen extends StatelessWidget {
  const MekanikHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MekanikDashboardViewModel>();
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final tasks = vm.completedTasks;

    // Stats calculation
    final now = DateTime.now();
    final thisMonth = tasks
        .where((t) => t.bookingDate.year == now.year && t.bookingDate.month == now.month)
        .length;

    final statusColor = vm.mechanicStatus == 'Tersedia'
        ? const Color(0xFF00C853)
        : vm.mechanicStatus == 'Bertugas'
            ? Colors.orange
            : Colors.grey;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF1B3A5E),
              radius: 18,
              child: Text(
                vm.mechanicName.isNotEmpty ? vm.mechanicName[0].toUpperCase() : 'M',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    vm.mechanicName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B3A5E),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vm.mechanicStatus,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: () => vm.fetchData(),
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B3A5E)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    'Riwayat Servis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B3A5E),
                    ),
                  ),
                ),

                // Stats row
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('${tasks.length}', 'Total Servis'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('$thisMonth', 'Bulan Ini'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // History List
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text(
                                'Belum ada riwayat servis',
                                style: TextStyle(color: Colors.grey, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => vm.fetchData(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: tasks.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) => _buildHistoryCard(context, tasks[i], currency),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B3A5E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, MechanicTaskModel task, NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular Check Icon on left
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9), // very light green bg
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_circle_outlined,
              color: Color(0xFF00C853), // green checkmark
              size: 26,
            ),
          ),
          const SizedBox(width: 12),

          // Central Customer details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.customerName ?? 'Customer',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1B3A5E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.serviceCategory,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${task.bookingDate.day} ${_monthName(task.bookingDate.month)} ${task.bookingDate.year}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                // Rating stars
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.star,
                      color: i < (task.ratingScore ?? 5) ? Colors.amber : Colors.grey.shade300,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Price & Laporan text button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(task.totalPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1B3A5E),
                ),
              ),
              const SizedBox(height: 8),
              if (task.serviceReport != null && task.serviceReport!.isNotEmpty)
                InkWell(
                  onTap: () => _showReportBottomSheet(context, task, currency),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.description_outlined, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Laporan',
                          style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month];
  }

  void _showReportBottomSheet(BuildContext context, MechanicTaskModel task, NumberFormat currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Detail Laporan Servis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B3A5E),
                    ),
                  ),
                  const Divider(height: 24),
                  _buildReportRow('Customer', task.customerName ?? 'Customer'),
                  _buildReportRow('Layanan', task.serviceCategory),
                  _buildReportRow(
                    'Tanggal',
                    '${task.bookingDate.day} ${_monthName(task.bookingDate.month)} ${task.bookingDate.year}',
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Hasil Pemeriksaan / Tindakan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      task.serviceReport ?? '-',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (task.serviceProofUrl != null && task.serviceProofUrl!.isNotEmpty) ...[
                    const Text(
                      'Foto Bukti Pekerjaan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        task.serviceProofUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 100,
                          color: Colors.grey.shade100,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Rincian Biaya',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPriceRow('Biaya Awal', currency.format(task.initialPaymentAmount)),
                  _buildPriceRow('Biaya Tambahan', currency.format(task.additionalPrice)),
                  const Divider(height: 16),
                  _buildPriceRow(
                    'Total Pembayaran',
                    currency.format(task.totalPrice),
                    isTotal: true,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B3A5E),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? const Color(0xFF1B3A5E) : Colors.grey,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 14 : 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isTotal ? const Color(0xFF00C853) : const Color(0xFF1B3A5E),
              fontSize: isTotal ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
