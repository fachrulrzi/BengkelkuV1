import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/notification_viewmodel.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationViewModel>().fetchNotifications();
    });
  }

  String _formatDateTime(DateTime dt) {
    final localDt = dt.toLocal();
    final day = localDt.day.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[localDt.month - 1];
    final year = localDt.year;
    final hour = localDt.hour.toString().padLeft(2, '0');
    final minute = localDt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (viewModel.unreadCount > 0)
            TextButton(
              onPressed: () => viewModel.markAllAsRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Color(0xFF1B3A5E), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)))
          : viewModel.notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => viewModel.fetchNotifications(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: viewModel.notifications.length,
                    itemBuilder: (context, index) {
                      final item = viewModel.notifications[index];

                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red.shade700,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                        ),
                        onDismissed: (direction) {
                          viewModel.deleteNotification(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notification deleted'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            if (!item.isRead) {
                              viewModel.markAsRead(item.id);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: item.isRead ? Colors.white : const Color(0xFF1B3A5E).withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: item.isRead ? Colors.grey.shade200 : const Color(0xFF1B3A5E).withValues(alpha: 0.15),
                                width: item.isRead ? 1 : 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon badge
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: item.isRead ? Colors.grey.shade100 : const Color(0xFF1B3A5E).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item.title.contains('Berhasil') || item.title.contains('Verifikasi') || item.title.contains('Selesai')
                                        ? Icons.check_circle_outline
                                        : item.title.contains('Masuk')
                                            ? Icons.shopping_bag_outlined
                                            : Icons.notifications_none_outlined,
                                    color: item.isRead ? AppColors.textSecondary : const Color(0xFF1B3A5E),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Text details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: TextStyle(
                                                fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                                                fontSize: 14,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (!item.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.blue,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.message,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: item.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatDateTime(item.createdAt),
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3A5E).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_off_outlined, size: 72, color: Color(0xFF1B3A5E)),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have no notifications yet. Status updates will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
