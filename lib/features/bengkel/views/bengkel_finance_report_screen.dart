import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/bengkel_orders_viewmodel.dart';
import '../viewmodels/bengkel_booking_viewmodel.dart';
import '../viewmodels/bengkel_dashboard_viewmodel.dart';
import '../utils/finance_pdf_helper.dart';

class BengkelFinanceReportScreen extends StatefulWidget {
  const BengkelFinanceReportScreen({super.key});

  @override
  State<BengkelFinanceReportScreen> createState() => _BengkelFinanceReportScreenState();
}

class _BengkelFinanceReportScreenState extends State<BengkelFinanceReportScreen> {
  String _selectedType = 'Semua'; // Semua, Servis, Sparepart
  String _selectedTime = 'Semua'; // Semua, Hari Ini, Bulan Ini
  final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bengkelId = context.read<BengkelDashboardViewModel>().bengkelId;
        context.read<BengkelOrdersViewModel>().fetchBengkelOrders(bengkelId);
        context.read<BengkelBookingViewModel>().fetchBookings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersVM = context.watch<BengkelOrdersViewModel>();
    final bookingsVM = context.watch<BengkelBookingViewModel>();

    // 1. Get Completed/Paid Orders
    final completedOrders = ordersVM.orders.where((o) => o.isPaid || o.status == 'Selesai').toList();
    final double totalProductRevenue = completedOrders.fold(0.0, (sum, o) => sum + o.totalPrice);

    // 2. Get Completed Bookings
    final completedBookings = bookingsVM.bookings.where((b) => b.status == 'Selesai' || b.status == 'Ulasan Dikirim').toList();
    final double totalServiceRevenue = completedBookings.fold(0.0, (sum, b) => sum + (b.totalPrice ?? 0).toDouble());

    // 3. Overall Revenue
    final double overallRevenue = totalProductRevenue + totalServiceRevenue;

    // Filtered transaction list
    final List<Map<String, dynamic>> allTransactions = [];

    // Add orders to transaction list
    for (var o in completedOrders) {
      final itemsText = o.items.map((i) => i.sparepart?.name ?? 'Item').join(', ');
      allTransactions.add({
        'id': o.id,
        'date': o.createdAt,
        'type': 'Sparepart',
        'title': itemsText.isNotEmpty ? itemsText : 'Pembelian Sparepart',
        'customer': 'Pelanggan',
        'amount': o.totalPrice,
        'status': o.status,
      });
    }

    // Add bookings to transaction list
    for (var b in completedBookings) {
      allTransactions.add({
        'id': b.id,
        'date': b.bookingDate, // or createdAt
        'type': 'Servis',
        'title': b.serviceCategory,
        'customer': b.customerName ?? 'Pelanggan',
        'amount': (b.totalPrice ?? 0).toDouble(),
        'status': b.status,
      });
    }

    // Sort transactions by date descending
    allTransactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    // Filter by type
    var filteredTransactions = allTransactions;
    if (_selectedType != 'Semua') {
      filteredTransactions = filteredTransactions.where((t) => t['type'] == _selectedType).toList();
    }

    // Filter by time
    final now = DateTime.now();
    if (_selectedTime == 'Hari Ini') {
      filteredTransactions = filteredTransactions.where((t) {
        final d = t['date'] as DateTime;
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).toList();
    } else if (_selectedTime == 'Bulan Ini') {
      filteredTransactions = filteredTransactions.where((t) {
        final d = t['date'] as DateTime;
        return d.year == now.year && d.month == now.month;
      }).toList();
    }

    // Calculate chart data for last 7 days (Combined)
    final List<FlSpot> spots = [];
    final List<String> dayLabels = [];
    final List<String> weekDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    double maxRevenue = 0;
    double totalWeekRevenue = 0;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      dayLabels.add(weekDays[date.weekday - 1]);
      
      final double orderRev = completedOrders
          .where((o) => o.createdAt.year == date.year && o.createdAt.month == date.month && o.createdAt.day == date.day)
          .fold(0.0, (sum, o) => sum + o.totalPrice);

      final double bookingRev = completedBookings
          .where((b) => b.bookingDate.year == date.year && b.bookingDate.month == date.month && b.bookingDate.day == date.day)
          .fold(0.0, (sum, b) => sum + (b.totalPrice ?? 0).toDouble());

      final double dayRevenue = orderRev + bookingRev;
      totalWeekRevenue += dayRevenue;
      if (dayRevenue > maxRevenue) maxRevenue = dayRevenue;
      spots.add(FlSpot((6 - i).toDouble(), dayRevenue));
    }
    
    double chartMaxY = maxRevenue > 0 ? maxRevenue * 1.2 : 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2843),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Laporan Keuangan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFF2B300)),
            onPressed: () {
              FinancePdfHelper.exportFinanceReport(
                context: context,
                bengkelName: context.read<BengkelDashboardViewModel>().bengkelName,
                bengkelAddress: context.read<BengkelDashboardViewModel>().bengkelAddress,
                completedOrders: completedOrders,
                completedBookings: completedBookings,
                overallRevenue: overallRevenue,
                totalProductRevenue: totalProductRevenue,
                totalServiceRevenue: totalServiceRevenue,
              );
            },
            tooltip: 'Cetak PDF',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final ordersVM = context.read<BengkelOrdersViewModel>();
          final bookingsVM = context.read<BengkelBookingViewModel>();
          final dashboardVM = context.read<BengkelDashboardViewModel>();
          await ordersVM.fetchBengkelOrders(dashboardVM.bengkelId);
          await bookingsVM.fetchBookings();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Title
              const Text(
                'Ringkasan Keuangan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B3A5E)),
              ),
              const SizedBox(height: 12),

              // Overall Revenue Card (Large)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B3A5E), Color(0xFF2C5E8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B3A5E).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Pendapatan Keseluruhan',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'All-Time',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(overallRevenue),
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Order & Servis: ${completedOrders.length + completedBookings.length} transaksi',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const Icon(Icons.trending_up, color: Colors.lightGreenAccent, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Split Cards (Service vs Sparepart)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Layanan Servis',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currencyFormat.format(totalServiceRevenue),
                            style: const TextStyle(color: Color(0xFF1B3A5E), fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${completedBookings.length} Selesai',
                            style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Produk Sparepart',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currencyFormat.format(totalProductRevenue),
                            style: const TextStyle(color: Color(0xFF1B3A5E), fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${completedOrders.length} Terjual',
                            style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Chart Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pendapatan 7 Hari Terakhir',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B3A5E)),
                        ),
                        Text(
                          currencyFormat.format(totalWeekRevenue),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B3A5E)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 140,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 && value.toInt() < dayLabels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Text(
                                        dayLabels[value.toInt()],
                                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                                reservedSize: 22,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: const Color(0xFF1B3A5E),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF1B3A5E).withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                          minX: 0,
                          maxX: 6,
                          minY: 0,
                          maxY: chartMaxY,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Filter Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Transaksi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B3A5E)),
                  ),
                  Row(
                    children: [
                      // Type Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedType,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF1B3A5E), fontWeight: FontWeight.bold),
                            items: ['Semua', 'Servis', 'Sparepart'].map((String type) {
                              return DropdownMenuItem(value: type, child: Text(type));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedType = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedTime,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF1B3A5E), fontWeight: FontWeight.bold),
                            items: ['Semua', 'Hari Ini', 'Bulan Ini'].map((String time) {
                              return DropdownMenuItem(value: time, child: Text(time));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedTime = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Transactions List
              filteredTransactions.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.history_toggle_off, color: Colors.grey, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'Tidak ada transaksi yang cocok.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredTransactions.length,
                      separatorBuilder: (context, idx) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final tx = filteredTransactions[idx];
                        final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(tx['date'] as DateTime);
                        final isService = tx['type'] == 'Servis';
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            children: [
                              // Icon Indicator
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isService ? Colors.orange.shade50 : Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isService ? Icons.build_outlined : Icons.shopping_bag_outlined,
                                  color: isService ? Colors.orange : Colors.blue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx['title'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B3A5E)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${tx['customer']} • $dateStr',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Amount
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormat.format(tx['amount'] as double),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tx['status'] as String,
                                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
