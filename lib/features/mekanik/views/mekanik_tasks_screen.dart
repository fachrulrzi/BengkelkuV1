import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/mekanik_dashboard_viewmodel.dart';
import '../models/mechanic_task_model.dart';
import 'mekanik_report_screen.dart';
import 'mekanik_journey_screen.dart';

class MekanikTasksScreen extends StatefulWidget {
  const MekanikTasksScreen({super.key});

  @override
  State<MekanikTasksScreen> createState() => _MekanikTasksScreenState();
}

class _MekanikTasksScreenState extends State<MekanikTasksScreen> {
  String _selectedStatus = 'Semua';
  String _selectedDateFilter = 'Semua';

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B3A5E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B3A5E) : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B3A5E).withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MekanikDashboardViewModel>();
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final newCount = vm.newTasks.length;

    final filteredTasks = vm.activeTasks.where((task) {
      // 1. Status Filter
      if (_selectedStatus != 'Semua') {
        if (_selectedStatus == 'Ditugaskan' && task.status != 'Mekanik Ditugaskan') {
          return false;
        }
        if (_selectedStatus == 'Diproses' && task.status != 'Diproses') {
          return false;
        }
      }
      
      // 2. Date Filter
      if (_selectedDateFilter != 'Semua') {
        final now = DateTime.now();
        final taskDate = task.bookingDate;
        final isToday = taskDate.year == now.year && taskDate.month == now.month && taskDate.day == now.day;
        
        if (_selectedDateFilter == 'Hari Ini' && !isToday) {
          return false;
        }
        if (_selectedDateFilter == 'Mendatang') {
          final todayMidnight = DateTime(now.year, now.month, now.day);
          final taskDateMidnight = DateTime(taskDate.year, taskDate.month, taskDate.day);
          if (!taskDateMidnight.isAfter(todayMidnight)) {
            return false;
          }
        }
      }
      return true;
    }).toList();

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tugas Servis',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B3A5E),
                        ),
                      ),
                      if (newCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$newCount Tugas Baru!',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Filter Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildFilterChip('Status: Semua', _selectedStatus == 'Semua', () {
                        setState(() => _selectedStatus = 'Semua');
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Ditugaskan', _selectedStatus == 'Ditugaskan', () {
                        setState(() => _selectedStatus = 'Ditugaskan');
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Diproses', _selectedStatus == 'Diproses', () {
                        setState(() => _selectedStatus = 'Diproses');
                      }),
                      const SizedBox(width: 16),
                      // Divider
                      Container(width: 1.5, height: 20, color: Colors.grey.shade300),
                      const SizedBox(width: 16),
                      _buildFilterChip('Waktu: Semua', _selectedDateFilter == 'Semua', () {
                        setState(() => _selectedDateFilter = 'Semua');
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Hari Ini', _selectedDateFilter == 'Hari Ini', () {
                        setState(() => _selectedDateFilter = 'Hari Ini');
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Mendatang', _selectedDateFilter == 'Mendatang', () {
                        setState(() => _selectedDateFilter = 'Mendatang');
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: vm.activeTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text(
                                'Tidak ada tugas aktif',
                                style: TextStyle(color: Colors.grey, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : filteredTasks.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.filter_list_off, size: 64, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text(
                                    'Tidak ada tugas yang cocok dengan filter',
                                    style: TextStyle(color: Colors.grey, fontSize: 15),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => vm.fetchData(),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: filteredTasks.length,
                                itemBuilder: (context, i) {
                                  return _buildTaskCard(context, filteredTasks[i], vm, currency);
                                },
                              ),
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    MechanicTaskModel task,
    MekanikDashboardViewModel vm,
    NumberFormat currency,
  ) {
    final isAssigned = task.status == 'Mekanik Ditugaskan';
    final isAccepted = task.status == 'Diterima';
    final isOtw = task.status == 'Menuju Lokasi';
    final isArrived = task.status == 'Sampai Lokasi';
    final isOngoing = task.status == 'Diproses';

    Color statusColor;
    String statusLabel;
    if (isAssigned) {
      statusColor = Colors.orange;
      statusLabel = 'Ditugaskan';
    } else if (isAccepted) {
      statusColor = Colors.blue;
      statusLabel = 'Diterima';
    } else if (isOtw) {
      statusColor = Colors.purple;
      statusLabel = 'Menuju Lokasi';
    } else if (isArrived) {
      statusColor = Colors.teal;
      statusLabel = 'Sampai Lokasi';
    } else if (isOngoing) {
      statusColor = Colors.green;
      statusLabel = 'Sedang Servis';
    } else {
      statusColor = Colors.grey;
      statusLabel = task.status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAssigned ? Colors.orange.withValues(alpha: 0.4) : Colors.grey.shade200,
          width: isAssigned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B3A5E).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.shortId,
                        style: const TextStyle(
                          color: Color(0xFF1B3A5E),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: task.isHomeService ? Colors.purple.withValues(alpha: 0.1) : Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.isHomeService ? '🏠 Home' : '🏭 Walk-in',
                        style: TextStyle(
                          color: task.isHomeService ? Colors.purple : Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(task.totalPrice > 0 ? task.totalPrice : (task.initialPaymentAmount > 0 ? task.initialPaymentAmount : task.homeServiceFee)),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1B3A5E),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 11, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(task.bookingDate)} | ${task.bookingTime}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer & Vehicle
            Text(
              task.customerName ?? 'Customer',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B3A5E),
              ),
            ),
            Text(
              '${task.vehicleName ?? '-'} · ${task.vehiclePoliceNumber ?? ''}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 8),

            // Services
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.build_outlined, size: 14, color: Colors.black45),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.serviceCategory,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Location Address
            if (task.isHomeService && task.customerAddress != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.customerAddress!,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.store_outlined, size: 14, color: Colors.black45),
                    SizedBox(width: 8),
                    Text(
                      'Customer ke workshop',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action Buttons
            if (isAssigned) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await vm.acceptTask(task.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tugas Diterima! ✅'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Terima'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await vm.rejectTask(task.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tugas ditolak')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Tolak'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEBEE),
                        foregroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (isAccepted || isOtw) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Check if date booking is valid (from previous user request rule #5:
                    // "bookingnya itu sesuai tanggal jadi mekanik ga bisa langsung nih menuju lokasi kalo tanggalnya blum sesuai")
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final bookingDay = DateTime(task.bookingDate.year, task.bookingDate.month, task.bookingDate.day);
                    if (bookingDay.isAfter(today)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              task.isHomeService
                                  ? 'Belum masuk tanggal booking (${task.bookingDate.day}/${task.bookingDate.month}/${task.bookingDate.year}). Anda baru dapat memulai perjalanan pada hari H.'
                                  : 'Belum masuk tanggal booking (${task.bookingDate.day}/${task.bookingDate.month}/${task.bookingDate.year}). Konfirmasi kedatangan baru dapat dilakukan pada hari H.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }

                    if (task.isHomeService) {
                      final hasOngoing = vm.activeTasks.any((t) => 
                        t.id != task.id && 
                        (t.status == 'Menuju Lokasi' || t.status == 'Sampai Lokasi' || t.status == 'Diproses')
                      );
                      if (hasOngoing) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Anda memiliki tugas lain yang sedang berjalan. Selesaikan tugas tersebut terlebih dahulu.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MekanikJourneyScreen(task: task),
                        ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text(
                              'Konfirmasi Kedatangan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B3A5E),
                              ),
                            ),
                            content: const Text(
                              'Apakah Anda yakin customer sudah datang ke workshop dan ingin memulai pengerjaan servis?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(dialogContext);
                                  final hasOngoing = vm.activeTasks.any((t) => 
                                    t.id != task.id && 
                                    (t.status == 'Menuju Lokasi' || t.status == 'Sampai Lokasi' || t.status == 'Diproses')
                                  );
                                  if (hasOngoing) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Anda memiliki tugas lain yang sedang berjalan. Selesaikan tugas tersebut terlebih dahulu.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  try {
                                    await vm.confirmCustomerArrival(task.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Kedatangan customer dikonfirmasi! ✅'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00C853),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Ya, Konfirmasi'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  icon: Icon(task.isHomeService ? Icons.send : Icons.check_circle_outline, size: 18),
                  label: Text(task.isHomeService ? 'Mulai Perjalanan' : 'Konfirmasi Kedatangan Customer', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3A5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ] else if (isArrived || isOngoing) ...[
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
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Buat Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
