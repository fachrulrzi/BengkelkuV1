import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  final String id;
  final String bookingId;
  final String senderId;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      bookingId: json['booking_id'],
      senderId: json['sender_id'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ChatViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  RealtimeChannel? _chatSubscription;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchMessages(String bookingId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('booking_chats')
          .select()
          .eq('booking_id', bookingId)
          .order('created_at', ascending: true);

      _messages = (response as List).map((e) => ChatMessage.fromJson(e)).toList();
      _subscribeToChat(bookingId);
    } catch (e) {
      debugPrint('Error fetching chat messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToChat(String bookingId) {
    if (_chatSubscription != null) {
      _supabase.removeChannel(_chatSubscription!);
    }
    _chatSubscription = _supabase
        .channel('public:booking_chats:booking_id=eq.$bookingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'booking_chats',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'booking_id',
            value: bookingId,
          ),
          callback: (payload) {
            final newMessage = ChatMessage.fromJson(payload.newRecord);
            // Hindari duplikat jika kita sendiri yang mengirim
            if (!_messages.any((m) => m.id == newMessage.id)) {
              _messages.add(newMessage);
              notifyListeners();
            }
          },
        );
    _chatSubscription?.subscribe();
  }

  Future<void> sendMessage(String bookingId, String message) async {
    final user = _supabase.auth.currentUser;
    if (user == null || message.trim().isEmpty) return;

    try {
      final data = {
        'booking_id': bookingId,
        'sender_id': user.id,
        'message': message.trim(),
      };

      // Optimistic update
      final optimisticMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // temp ID
        bookingId: bookingId,
        senderId: user.id,
        message: message.trim(),
        createdAt: DateTime.now(),
      );
      _messages.add(optimisticMsg);
      notifyListeners();

      await _supabase.from('booking_chats').insert(data);
      // Data real akan terupdate otomatis via subscription
    } catch (e) {
      debugPrint('Error sending message: $e');
      // Re-fetch jika terjadi error
      await fetchMessages(bookingId);
    }
  }

  @override
  void dispose() {
    if (_chatSubscription != null) {
      _supabase.removeChannel(_chatSubscription!);
    }
    super.dispose();
  }
}
