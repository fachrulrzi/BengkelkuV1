import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'order_history_screen.dart';
import 'booking_history_screen.dart';

class CustomerActivityScreen extends StatelessWidget {
  const CustomerActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Aktivitas',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Servis Bengkel'),
              Tab(text: 'Marketplace'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BookingHistoryScreen(),
            OrderHistoryScreen(showAppBar: false),
          ],
        ),
      ),
    );
  }
}
