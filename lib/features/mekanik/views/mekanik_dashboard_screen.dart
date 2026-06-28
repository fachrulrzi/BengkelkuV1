import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../../features/auth/views/login_screen.dart';
import '../viewmodels/mekanik_dashboard_viewmodel.dart';
import '../models/mechanic_task_model.dart';
import 'mekanik_report_screen.dart';

class MekanikDashboardScreen extends StatelessWidget {
  const MekanikDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MekanikDashboardViewModel>();
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    final isLocked = vm.mechanicStatus == 'Bertugas' || vm.activeTasks.isNotEmpty;

    final statusColor = vm.mechanicStatus == 'Tersedia'
        ? const Color(0xFF00C853)
        : vm.mechanicStatus == 'Bertugas'
            ? Colors.orange
            : Colors.grey;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B3A5E)))
          : RefreshIndicator(
              onRefresh: () => vm.fetchData(),
              child: CustomScrollView(
                slivers: [
                  // AppBar
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 0.5,
                    automaticallyImplyLeading: false,
                    title: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF1B3A5E),
                          radius: 20,
                          child: Text(
                            vm.mechanicName.isNotEmpty
                                ? vm.mechanicName[0].toUpperCase()
                                : 'M',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                vm.mechanicName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B3A5E),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    vm.mechanicStatus,
                                    style: TextStyle(
                                      fontSize: 12,
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
                        icon: const Icon(Icons.logout, color: Color(0xFF1B3A5E)),
                        onPressed: () async {
                          await context.read<AuthViewModel>().signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (_) => false,
                            );
                          }
                        },
                      ),
                    ],
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: vm.mechanicStatus == 'Tersedia'
                                    ? [const Color(0xFF00C853), const Color(0xFF00897B)]
                                    : vm.mechanicStatus == 'Bertugas'
                                        ? [Colors.orange.shade600, Colors.orange.shade800]
                                        : [Colors.grey.shade500, Colors.grey.shade700],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Status Saya',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  vm.mechanicStatus,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vm.mechanicStatus == 'Tersedia'
                                      ? 'Siap menerima tugas'
                                      : vm.mechanicStatus == 'Bertugas'
                                          ? 'Sedang menangani tugas'
                                          : 'Tidak tersedia saat ini',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Status Buttons
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Ubah Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF1B3A5E),
                                      ),
                                    ),
                                    if (isLocked) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.lock, size: 14, color: Colors.orange),
                                    ],
                                  ],
                                ),
                                if (isLocked) ...[
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Status terkunci selama bertugas menyelesaikan order.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _StatusBtn(
                                      label: 'Tersedia',
                                      isActive: vm.mechanicStatus == 'Tersedia',
                                      color: const Color(0xFF00C853),
                                      onTap: isLocked
                                          ? null
                                          : () => vm.updateStatus('Tersedia'),
                                    ),
                                    const SizedBox(width: 8),
                                    _StatusBtn(
                                      label: 'Bertugas',
                                      isActive: vm.mechanicStatus == 'Bertugas',
                                      color: Colors.orange,
                                      onTap: null, // Bertugas status is only set automatically by system on tasks
                                    ),
                                    const SizedBox(width: 8),
                                    _StatusBtn(
                                      label: 'Offline',
                                      isActive: vm.mechanicStatus == 'Offline',
                                      color: Colors.grey,
                                      onTap: isLocked
                                          ? null
                                          : () => vm.updateStatus('Offline'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Stats Grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.7,
                            children: [
                              _StatCard(
                                icon: Icons.check_circle_outline,
                                iconColor: const Color(0xFF00C853),
                                value: '${vm.tasksCompletedToday}',
                                label: 'Selesai Hari Ini',
                              ),
                              _StatCard(
                                icon: Icons.star_outline,
                                iconColor: Colors.amber,
                                value: '4.9',
                                label: 'Rating',
                              ),
                              _StatCard(
                                icon: Icons.build_outlined,
                                iconColor: Colors.blue,
                                value: '${vm.totalTasks}',
                                label: 'Total Servis',
                              ),
                              _StatCard(
                                icon: Icons.calendar_month_outlined,
                                iconColor: Colors.purple,
                                value: '${vm.tasksCompletedThisMonth}',
                                label: 'Bulan Ini',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Active Task
                          if (vm.activeTask != null) ...[
                            _buildActiveTaskCard(context, vm.activeTask!, currency),
                            const SizedBox(height: 16),
                          ],

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveTaskCard(
      BuildContext context, MechanicTaskModel task, NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B3A5E).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TUGAS AKTIF',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3A5E),
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: task.status == 'Diproses'
                      ? Colors.blue
                      : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  task.status == 'Diproses' ? 'Berlangsung' : 'Ditugaskan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.serviceCategory,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B3A5E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${task.customerName ?? 'Customer'} · ${task.vehicleName ?? '-'}',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Color(0xFF1B3A5E)),
              const SizedBox(width: 4),
              Text(
                'Jadwal: ${DateFormat('dd/MM/yyyy').format(task.bookingDate)} | ${task.bookingTime}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1B3A5E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (task.status == 'Diproses') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MekanikReportScreen(task: task),
                    ),
                  );
                },
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('Buat Laporan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B3A5E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }


}

class _StatusBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback? onTap;

  const _StatusBtn({
    required this.label,
    required this.isActive,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onTap == null && !isActive;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Opacity(
            opacity: isDisabled ? 0.4 : 1.0,
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1B3A5E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
