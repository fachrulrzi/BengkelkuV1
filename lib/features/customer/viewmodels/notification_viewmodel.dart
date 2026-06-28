import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final res = await _supabase
            .from('notifications')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        final List<dynamic> data = res;
        _notifications = data.map((e) => NotificationModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
      
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          title: _notifications[index].title,
          message: _notifications[index].message,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase
            .from('notifications')
            .update({'is_read': true})
            .eq('user_id', user.id);
        
        _notifications = _notifications
            .map((n) => NotificationModel(
                  id: n.id,
                  userId: n.userId,
                  title: n.title,
                  message: n.message,
                  isRead: true,
                  createdAt: n.createdAt,
                ))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _supabase.from('notifications').delete().eq('id', id);
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }
}
