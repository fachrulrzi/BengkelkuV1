import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/login_screen.dart';
import '../viewmodels/admin_config_viewmodel.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminConfigViewModel>().fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<AdminConfigViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: stats.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Grid of Stats Cards
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.35,
                          children: [
                            _buildStatCard(
                              icon: Icons.people_outline,
                              iconBg: Colors.blue.shade50,
                              iconColor: Colors.blue,
                              value: stats.totalUsers.toString(),
                              label: 'Total Users',
                              trend: '+${stats.newUsersThisMonth} baru',
                              trendColor: Colors.green,
                            ),
                            _buildStatCard(
                              icon: Icons.storefront,
                              iconBg: Colors.purple.shade50,
                              iconColor: Colors.purple,
                              value: stats.totalWorkshops.toString(),
                              label: 'Workshops',
                              trend: '+${stats.pendingWorkshops} pending',
                              trendColor: Colors.green,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Order Status Distribution Chart
                        _buildSectionCard(
                          title: 'Order Status Distribution',
                          child: Row(
                            children: [
                              // Simulated Donut Chart
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 16,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.pie_chart,
                                    color: Colors.blue,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Chart legends
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildLegendItem(
                                      'Completed',
                                      '${stats.completedOrders}',
                                      Colors.green,
                                    ),
                                    _buildLegendItem(
                                      'In Progress',
                                      '${stats.inProgressOrders}',
                                      Colors.blue,
                                    ),
                                    _buildLegendItem(
                                      'Pending',
                                      '${stats.pendingOrders}',
                                      Colors.orange,
                                    ),
                                    _buildLegendItem(
                                      'Cancelled',
                                      '${stats.cancelledOrders}',
                                      Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Top Performing Workshops
                        _buildSectionCard(
                          title: 'Top Performing Workshops',
                          child: Column(
                            children: stats.topWorkshops.isEmpty
                                ? [const Padding(padding: EdgeInsets.all(16), child: Text('Belum ada data transaksi'))]
                                : stats.topWorkshops.map((workshop) {
                                    // Generate a deterministic color based on the workshop name length for variety
                                    final colors = [Colors.blue, Colors.orange, Colors.red, Colors.purple, Colors.teal];
                                    final colorIndex = (workshop['name'] as String).length % colors.length;
                                    
                                    return _buildWorkshopItem(
                                      workshop['name'].toString(),
                                      '${workshop['orders']} orders',
                                      '★ ${double.tryParse(workshop['rating'].toString())?.toStringAsFixed(1) ?? '0.0'}',
                                      colors[colorIndex],
                                    );
                                  }).toList(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Recent Activities
                        _buildSectionCard(
                          title: 'Aktivitas Terbaru',
                          child: Column(
                            children: stats.recentActivities.isEmpty
                                ? [const Padding(padding: EdgeInsets.all(16), child: Text('Belum ada aktivitas terbaru.'))]
                                : stats.recentActivities.map((activity) {
                                    IconData icon;
                                    Color bgColor;
                                    
                                    if (activity['type'] == 'user') {
                                      icon = Icons.person;
                                      bgColor = Colors.blue;
                                    } else if (activity['type'] == 'booking') {
                                      icon = Icons.receipt_long;
                                      bgColor = Colors.green;
                                    } else {
                                      icon = Icons.storefront;
                                      bgColor = Colors.orange;
                                    }

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        backgroundColor: bgColor,
                                        child: Icon(icon, color: Colors.white),
                                      ),
                                      title: Text(activity['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      subtitle: Text(activity['subtitle'] ?? '', style: const TextStyle(fontSize: 12)),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                                    );
                                  }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    required String trend,
    required Color trendColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 10,
                  color: trendColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkshopItem(
    String name,
    String orders,
    String rating,
    Color tagColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.build_circle_outlined, color: tagColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  orders,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            rating,
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
