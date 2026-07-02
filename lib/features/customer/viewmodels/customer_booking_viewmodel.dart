import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';

class CustomerBookingViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _midtransServerKey = String.fromEnvironment(
    'MIDTRANS_SERVER_KEY',
  );
  static const bool _isSandboxMode = true;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<BookingModel> _bookings = [];
  List<BookingModel> get bookings => _bookings;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Hasilkan order_id Midtrans yang unik namun tetap di bawah 50 karakter
  /// (batas Midtrans). Booking UUID (36 char) dipotong jadi 8 char lalu
  /// digabung dengan prefix + timestamp pendek.
  /// Contoh: "SB-a1b2c3d4-1900123456" (~24 char).
  String _generateMidtransOrderId(String prefix, String bookingId) {
    final shortId = bookingId.replaceAll('-', '').substring(0, 8).toUpperCase();
    final now = DateTime.now();
    // YYMMDDHHmmss (12 digit) — cukup unik per detik
    final ts =
        '${now.year.toString().substring(2)}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return '$prefix-$shortId-$ts';
  }

  Future<void> fetchBookings() async {
    _setLoading(true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('service_bookings')
          .select('*, bengkels ( name )')
          .eq('customer_id', user.id)
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      final List<BookingModel> dbBookings = data
          .map((e) => BookingModel.fromJson(e))
          .toList();

      // Sync payment statuses from Midtrans/local expiry
      await _syncUnpaidBookingsStatus(dbBookings);

      // Re-fetch updated list from DB
      final updatedResponse = await _supabase
          .from('service_bookings')
          .select('*, bengkels ( name )')
          .eq('customer_id', user.id)
          .order('created_at', ascending: false);

      final List<dynamic> updatedData = updatedResponse;
      _bookings = updatedData.map((e) => BookingModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<List<BookingModel>> fetchBookingsForBengkelAndDate(
    String bengkelId,
    String dateStr,
  ) async {
    try {
      final response = await _supabase
          .from('service_bookings')
          .select('*, bengkels ( name )')
          .eq('bengkel_id', bengkelId)
          .eq('booking_date', dateStr)
          .not('status', 'eq', 'Dibatalkan');

      final List<dynamic> data = response;
      return data.map((e) => BookingModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching bookings for bengkel and date: $e');
      return [];
    }
  }

  Future<void> createBooking({
    required String bengkelId,
    required String vehicleId,
    required String vehicleName,
    required String vehiclePlate,
    required String serviceCategory,
    required DateTime bookingDate,
    required String bookingTime,
    String? complaint,
    bool isHomeService = false,
    String? customerAddress,
    double? latitude,
    double? longitude,
    int homeServiceFee = 0,
    int initialPaymentAmount = 0,
    int estimatedDuration = 120,
  }) async {
    _setLoading(true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _supabase.from('service_bookings').insert({
        'customer_id': user.id,
        'bengkel_id': bengkelId,
        'vehicle_id': vehicleId,
        'vehicle_name': vehicleName,
        'vehicle_police_number': vehiclePlate,
        'service_category': serviceCategory,
        'booking_date': bookingDate.toIso8601String().split('T').first,
        'booking_time': bookingTime,
        'status': 'Menunggu Konfirmasi',
        'complaint': complaint,
        'is_home_service': isHomeService,
        'customer_address': customerAddress,
        'latitude': latitude,
        'longitude': longitude,
        'home_service_fee': homeServiceFee,
        'initial_payment_amount': initialPaymentAmount,
        'initial_payment_status': 'unpaid',
        'estimated_duration': estimatedDuration,
      });

      await fetchBookings();
    } catch (e) {
      debugPrint('Error creating booking: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    _setLoading(true);
    try {
      await _supabase
          .from('service_bookings')
          .update({'status': 'Dibatalkan'})
          .eq('id', bookingId);

      await fetchBookings();
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> payInitialFee(
    String bookingId, {
    List<String>? enabledPayments,
  }) async {
    _setLoading(true);
    try {
      final res = await _supabase
          .from('service_bookings')
          .select('*')
          .eq('id', bookingId)
          .single();
      final booking = BookingModel.fromJson(res);

      // Midtrans membatasi order_id maksimal 50 karakter. UUID booking (36) +
      // prefix + timestamp bisa lebih dari 50, jadi potong UUID jadi 8 char.
      final midtransOrderId = _generateMidtransOrderId('SB', booking.id);
      final amount = booking.initialPaymentAmount.toDouble();

      final redirectUrl = await _createMidtransTransaction(
        midtransOrderId,
        amount,
        booking.serviceCategory,
        enabledPayments: enabledPayments,
      );

      if (redirectUrl != null) {
        final paymentExpiry = DateTime.now().add(const Duration(minutes: 1440));
        await _supabase
            .from('service_bookings')
            .update({
              'midtrans_order_id': midtransOrderId,
              'payment_url': redirectUrl,
              'payment_expires_at': paymentExpiry.toIso8601String(),
            })
            .eq('id', bookingId);
      }

      await fetchBookings();
      return redirectUrl;
    } catch (e) {
      debugPrint('Error paying initial fee: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<BookingModel> createSosBooking({
    required String bengkelId,
    required String mechanicId,
    required String mechanicName,
    required String vehicleId,
    required String vehicleName,
    required String vehiclePlate,
    required String complaint,
    required String customerAddress,
    required int travelFee,
    double? latitude,
    double? longitude,
  }) async {
    _setLoading(true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final bookingMap = {
        'customer_id': user.id,
        'bengkel_id': bengkelId,
        'mechanic_id': mechanicId,
        'mechanic_name': mechanicName,
        'vehicle_id': vehicleId,
        'vehicle_name': vehicleName,
        'vehicle_police_number': vehiclePlate,
        'service_category': 'SOS',
        'booking_date': DateTime.now().toIso8601String().split('T').first,
        'booking_time': DateFormat('HH:mm').format(DateTime.now()),
        'status': 'Menunggu Pembayaran Jasa',
        'complaint': complaint,
        'is_home_service': true,
        'customer_address': customerAddress,
        'home_service_fee': travelFee,
        'initial_payment_amount': travelFee,
        'initial_payment_status': 'unpaid',
        'estimated_duration': 60, // Default duration of 1 hour for SOS
        'latitude': latitude,
        'longitude': longitude,
      };

      final response = await _supabase
          .from('service_bookings')
          .insert(bookingMap)
          .select('*, bengkels ( name )')
          .single();

      final createdBooking = BookingModel.fromJson(response);
      await fetchBookings();
      return createdBooking;
    } catch (e) {
      debugPrint('Error creating SOS booking: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> payAdditionalFee(
    String bookingId, {
    List<String>? enabledPayments,
  }) async {
    _setLoading(true);
    try {
      final res = await _supabase
          .from('service_bookings')
          .select('*')
          .eq('id', bookingId)
          .single();
      final booking = BookingModel.fromJson(res);

      final midtransOrderId = _generateMidtransOrderId('SB-ADD', booking.id);
      final amount = booking.additionalPrice.toDouble();

      final redirectUrl = await _createMidtransTransaction(
        midtransOrderId,
        amount,
        booking.serviceCategory,
        enabledPayments: enabledPayments,
      );

      if (redirectUrl != null) {
        final paymentExpiry = DateTime.now().add(const Duration(minutes: 1440));
        await _supabase
            .from('service_bookings')
            .update({
              'midtrans_order_id': midtransOrderId,
              'payment_url': redirectUrl,
              'payment_expires_at': paymentExpiry.toIso8601String(),
            })
            .eq('id', bookingId);
      }

      await fetchBookings();
      return redirectUrl;
    } catch (e) {
      debugPrint('Error paying additional fee: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> _createMidtransTransaction(
    String orderId,
    double amount,
    String serviceCategory, {
    List<String>? enabledPayments,
  }) async {
    final String serverKey = _midtransServerKey;
    if (serverKey.trim().isEmpty) {
      throw Exception(
        'MIDTRANS_SERVER_KEY belum diset. Jalankan app dengan --dart-define=MIDTRANS_SERVER_KEY=... ',
      );
    }
    final url = _isSandboxMode
        ? 'https://app.sandbox.midtrans.com/snap/v1/transactions'
        : 'https://app.midtrans.com/snap/v1/transactions';

    // Midtrans menolak gross_amount = 0. Pastikan minimal 1.
    // gross_amount juga tidak boleh melebihi 10 digit.
    final grossAmount = amount.toInt().clamp(1, 999999999);

    final basicAuth = 'Basic ${base64Encode(utf8.encode('$serverKey:'))}';
    final user = _supabase.auth.currentUser;

    // Nama item tampil di halaman Snap Midtrans — potong supaya aman.
    final String itemName = serviceCategory.isEmpty
        ? 'Jasa Layanan Bengkel'
        : (serviceCategory.length > 45
              ? '${serviceCategory.substring(0, 45)}...'
              : serviceCategory);

    final Map<String, dynamic> body = {
      'transaction_details': {'order_id': orderId, 'gross_amount': grossAmount},
      'item_details': [
        {'id': orderId, 'name': itemName, 'price': grossAmount, 'quantity': 1},
      ],
      'credit_card': {'secure': true},
      if (enabledPayments != null && enabledPayments.isNotEmpty)
        'enabled_payments': enabledPayments,
      'customer_details': {
        'first_name': user?.email?.split('@').first ?? 'Customer',
        'email': user?.email ?? 'customer@bengkelin.com',
      },
      'expiry': {'unit': 'minute', 'duration': 1440},
      // Callbacks: setelah bayar, Midtrans Snap redirect ke URL ini.
      // MidtransSnapScreen memonitor URL ini untuk auto-close WebView &
      // melaporkan hasil pembayaran (success/pending/error).
      'callbacks': {'finish': 'bengkelin://payment/finish'},
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
        body: jsonEncode(body),
      );

      debugPrint('[Midtrans-Booking] POST $url');
      debugPrint('[Midtrans-Booking] Status: ${response.statusCode}');
      debugPrint('[Midtrans-Booking] Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['redirect_url'];
      } else {
        // Parse error message dari Midtrans jika ada
        String errorMsg = response.body;
        try {
          final errData = jsonDecode(response.body);
          if (errData['error_messages'] is List) {
            errorMsg = (errData['error_messages'] as List).join('\n');
          }
        } catch (_) {}
        throw Exception(
          'Status ${response.statusCode}: $errorMsg\n\n'
          'Pastikan Sandbox Server Key di dashboard Midtrans sudah benar.',
        );
      }
    } catch (e) {
      debugPrint('[Midtrans-Booking] Exception: $e');
      throw Exception('Gagal menghubungi server Midtrans: $e');
    }
  }

  Future<String?> _getMidtransTransactionStatus(String midtransOrderId) async {
    try {
      if (_midtransServerKey.trim().isEmpty) {
        debugPrint('[Midtrans] MIDTRANS_SERVER_KEY belum diset.');
        return null;
      }
      final base = _isSandboxMode
          ? 'https://api.sandbox.midtrans.com'
          : 'https://api.midtrans.com';
      final url = '$base/v2/$midtransOrderId/status';
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('$_midtransServerKey:'))}';

      final res = await http
          .get(
            Uri.parse(url),
            headers: {'Accept': 'application/json', 'Authorization': basicAuth},
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['transaction_status']?.toString();
      } else if (res.statusCode == 404) {
        debugPrint(
          '[Midtrans] Status 404 untuk $midtransOrderId (belum ada transaksi)',
        );
        return 'pending';
      } else {
        debugPrint('[Midtrans] Status code ${res.statusCode}: ${res.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[Midtrans] Gagal cek status transaksi $midtransOrderId: $e');
      return null;
    }
  }

  Future<void> _syncUnpaidBookingsStatus(
    List<BookingModel> bookingsList,
  ) async {
    final now = DateTime.now();
    for (final booking in bookingsList) {
      // 1) Cek status pembayaran awal (initial)
      if (booking.initialPaymentStatus == 'unpaid' &&
          booking.status == 'Menunggu Pembayaran Jasa') {
        // Cek expiry lokal
        if (booking.paymentExpiresAt != null &&
            now.isAfter(booking.paymentExpiresAt!)) {
          await _markBookingPaymentStatus(booking, 'expired', isInitial: true);
          continue;
        }

        // Verifikasi Midtrans jika ada order ID
        if (booking.midtransOrderId != null &&
            !booking.midtransOrderId!.startsWith('SB-ADD')) {
          final midtransStatus = await _getMidtransTransactionStatus(
            booking.midtransOrderId!,
          );
          if (midtransStatus != null) {
            switch (midtransStatus.toLowerCase()) {
              case 'settlement':
              case 'capture':
                await _markBookingPaymentStatus(
                  booking,
                  'paid',
                  isInitial: true,
                );
                break;
              case 'expire':
                await _markBookingPaymentStatus(
                  booking,
                  'expired',
                  isInitial: true,
                );
                break;
              case 'deny':
              case 'failure':
              case 'cancel':
                await _markBookingPaymentStatus(
                  booking,
                  'failed',
                  isInitial: true,
                );
                break;
            }
          }
        }
      }

      // 2) Cek status pembayaran tambahan (additional/pelunasan)
      if (booking.additionalPaymentStatus == 'unpaid' &&
          (booking.status == 'Menunggu Pembayaran Tambahan' ||
              booking.status == 'Menunggu Pelunasan')) {
        // Cek expiry lokal
        if (booking.paymentExpiresAt != null &&
            now.isAfter(booking.paymentExpiresAt!)) {
          await _markBookingPaymentStatus(booking, 'expired', isInitial: false);
          continue;
        }

        // Verifikasi Midtrans jika ada order ID
        if (booking.midtransOrderId != null &&
            booking.midtransOrderId!.startsWith('SB-ADD')) {
          final midtransStatus = await _getMidtransTransactionStatus(
            booking.midtransOrderId!,
          );
          if (midtransStatus != null) {
            switch (midtransStatus.toLowerCase()) {
              case 'settlement':
              case 'capture':
                await _markBookingPaymentStatus(
                  booking,
                  'paid',
                  isInitial: false,
                );
                break;
              case 'expire':
                await _markBookingPaymentStatus(
                  booking,
                  'expired',
                  isInitial: false,
                );
                break;
              case 'deny':
              case 'failure':
              case 'cancel':
                await _markBookingPaymentStatus(
                  booking,
                  'failed',
                  isInitial: false,
                );
                break;
            }
          }
        }
      }
    }
  }

  Future<void> _markBookingPaymentStatus(
    BookingModel booking,
    String status, {
    required bool isInitial,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (isInitial) {
        updateData['initial_payment_status'] = status;
        if (status == 'paid') {
          final isSos = booking.serviceCategory == 'SOS';
          updateData['status'] = isSos ? 'Diterima' : 'Pembayaran Awal Lunas';

          if (isSos && booking.mechanicId != null) {
            await _supabase
                .from('mechanics')
                .update({'status': 'Bertugas'})
                .eq('id', booking.mechanicId!);
          }
        } else if (status == 'expired' || status == 'failed') {
          updateData['status'] = 'Dibatalkan';
          if (booking.mechanicId != null) {
            await _supabase
                .from('mechanics')
                .update({'status': 'Aktif'})
                .eq('id', booking.mechanicId!);
          }
        }
      } else {
        updateData['additional_payment_status'] = status;
        if (status == 'paid') {
          updateData['status'] = 'Selesai';
        }
      }

      await _supabase
          .from('service_bookings')
          .update(updateData)
          .eq('id', booking.id);
      debugPrint(
        '[Payment] Booking ${booking.id} updated isInitial=$isInitial status=$status',
      );
    } catch (e) {
      debugPrint('[Payment] Failed to update booking payment status: $e');
    }
  }

  Future<void> submitBookingReview({
    required String bookingId,
    required String mechanicId,
    required String mechanicName,
    required int rating,
    required String comment,
  }) async {
    _setLoading(true);
    try {
      // 1. Update rating di tabel service_bookings
      await _supabase
          .from('service_bookings')
          .update({
            'rating_score': rating,
            'rating_comment': comment,
            'rating_mechanic_name': mechanicName,
            'status': 'Ulasan Dikirim',
          })
          .eq('id', bookingId);

      // 2. Update rating rata-rata mekanik di tabel mechanics jika mechanicId ada
      if (mechanicId.isNotEmpty) {
        final allRatings = await _supabase
            .from('service_bookings')
            .select('rating_score')
            .eq('mechanic_id', mechanicId)
            .not('rating_score', 'is', null);

        final ratingsList = allRatings as List;
        if (ratingsList.isNotEmpty) {
          double sum = 0;
          for (var item in ratingsList) {
            sum += (item['rating_score'] as num).toDouble();
          }
          double avgRating = sum / ratingsList.length;

          await _supabase
              .from('mechanics')
              .update({
                'rating': avgRating,
                'services_count': ratingsList.length,
              })
              .eq('id', mechanicId);
        }
      }

      await fetchBookings();
    } catch (e) {
      debugPrint('Error submitting booking review: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
