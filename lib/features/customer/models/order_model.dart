import '../../bengkel/models/sparepart_model.dart';

class OrderModel {
  final String id;
  final String userId;
  final double totalPrice;
  final double discount;
  final double shippingFee;
  final String status;
  final String paymentMethod;
  final String? recipientName;
  final String? recipientPhone;
  final String? shippingAddress;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  // Delivery tracking (diisi bengkel)
  final String? trackingNumber;
  final String? shippingPhotoUrl;

  // Rating (diisi customer setelah selesai)
  final int? rating;
  final String? ratingNote;

  // Pickup = true → ambil sendiri (tidak ada ongkir)
  final bool isPickup;

  // Coordinates
  final double? latitude;
  final double? longitude;

  // --- Midtrans "Pay Later" fields ---
  // payment_status: 'unpaid' | 'paid' | 'expired' | 'failed'
  final String paymentStatus;
  // URL Snap Midtrans untuk membayar (bisa dibuka ulang kapan saja sebelum expiry)
  final String? paymentUrl;
  // order_id yang dikirim ke Midtrans (untuk verifikasi status)
  final String? midtransOrderId;
  // Batas waktu pembayaran (mengikuti expiry Midtrans)
  final DateTime? paymentExpiresAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.totalPrice,
    required this.discount,
    required this.shippingFee,
    required this.status,
    required this.paymentMethod,
    this.recipientName,
    this.recipientPhone,
    this.shippingAddress,
    required this.createdAt,
    required this.items,
    this.trackingNumber,
    this.shippingPhotoUrl,
    this.rating,
    this.ratingNote,
    this.isPickup = false,
    this.latitude,
    this.longitude,
    this.paymentStatus = 'unpaid',
    this.paymentUrl,
    this.midtransOrderId,
    this.paymentExpiresAt,
  });

  // Convenience: apakah pesanan sudah dibayar?
  bool get isPaid => paymentStatus == 'paid';
  // Apakah masih bisa dibayar (unpaid & belum lewat expiry)?
  bool get canPayLater =>
      paymentStatus == 'unpaid' &&
      paymentUrl != null &&
      paymentUrl!.isNotEmpty &&
      (paymentExpiresAt == null || paymentExpiresAt!.isAfter(DateTime.now()));

  OrderModel copyWith({
    String? id,
    String? userId,
    double? totalPrice,
    double? discount,
    double? shippingFee,
    String? status,
    String? paymentMethod,
    String? recipientName,
    String? recipientPhone,
    String? shippingAddress,
    DateTime? createdAt,
    List<OrderItemModel>? items,
    String? trackingNumber,
    String? shippingPhotoUrl,
    int? rating,
    String? ratingNote,
    bool? isPickup,
    double? latitude,
    double? longitude,
    String? paymentStatus,
    String? paymentUrl,
    String? midtransOrderId,
    DateTime? paymentExpiresAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalPrice: totalPrice ?? this.totalPrice,
      discount: discount ?? this.discount,
      shippingFee: shippingFee ?? this.shippingFee,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      shippingPhotoUrl: shippingPhotoUrl ?? this.shippingPhotoUrl,
      rating: rating ?? this.rating,
      ratingNote: ratingNote ?? this.ratingNote,
      isPickup: isPickup ?? this.isPickup,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      midtransOrderId: midtransOrderId ?? this.midtransOrderId,
      paymentExpiresAt: paymentExpiresAt ?? this.paymentExpiresAt,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['order_items'] as List? ?? [];
    return OrderModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shipping_fee'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Pending',
      paymentMethod: json['payment_method'] ?? 'GoPay',
      recipientName: json['recipient_name'],
      recipientPhone: json['recipient_phone'],
      shippingAddress: json['shipping_address'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      items: itemsList.map((e) => OrderItemModel.fromJson(e)).toList(),
      trackingNumber: json['tracking_number'],
      shippingPhotoUrl: json['shipping_photo_url'],
      rating: (json['rating'] as num?)?.toInt(),
      ratingNote: json['rating_note'],
      isPickup: json['is_pickup'] as bool? ?? false,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      paymentStatus: (json['payment_status']?.toString() ?? 'unpaid'),
      paymentUrl: json['payment_url']?.toString(),
      midtransOrderId: json['midtrans_order_id']?.toString(),
      paymentExpiresAt: json['payment_expires_at'] != null
          ? DateTime.parse(json['payment_expires_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total_price': totalPrice,
      'discount': discount,
      'shipping_fee': shippingFee,
      'status': status,
      'payment_method': paymentMethod,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'shipping_address': shippingAddress,
      'created_at': createdAt.toIso8601String(),
      'tracking_number': trackingNumber,
      'shipping_photo_url': shippingPhotoUrl,
      'rating': rating,
      'rating_note': ratingNote,
      'is_pickup': isPickup,
      'latitude': latitude,
      'longitude': longitude,
      'payment_status': paymentStatus,
      'payment_url': paymentUrl,
      'midtrans_order_id': midtransOrderId,
      'payment_expires_at': paymentExpiresAt?.toIso8601String(),
    };
  }
}

class OrderItemModel {
  final String id;
  final String orderId;
  final String sparepartId;
  final int quantity;
  final double price;
  final SparepartModel? sparepart;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.sparepartId,
    required this.quantity,
    required this.price,
    this.sparepart,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      sparepartId: json['sparepart_id']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      sparepart: json['spareparts'] != null
          ? SparepartModel.fromJson(json['spareparts'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'sparepart_id': sparepartId,
      'quantity': quantity,
      'price': price,
    };
  }
}
