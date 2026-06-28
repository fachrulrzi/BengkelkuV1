class BookingModel {
  final String id;
  final String customerId;
  final String bengkelId;
  final String vehicleId;
  final String serviceCategory;
  final DateTime bookingDate;
  final String bookingTime;
  final String status;
  final String? complaint;
  final DateTime createdAt;
  
  // Transaksi & Mekanik
  final bool isHomeService;
  final String? customerAddress;
  final int homeServiceFee;
  final int? totalPrice;
  final String? mechanicId;
  final String? serviceReport;

  // Double payment & tracking
  final String initialPaymentStatus;
  final int initialPaymentAmount;
  final int additionalPrice;
  final String additionalPaymentStatus;
  final String? serviceProofUrl;
  final double? mechanicLatitude;
  final double? mechanicLongitude;
  final double? latitude;
  final double? longitude;
  final int estimatedDuration;
  final String? midtransOrderId;
  final String? paymentUrl;
  final DateTime? paymentExpiresAt;

  // Rating & Review
  final int? ratingScore;
  final String? ratingComment;
  final String? ratingMechanicName;

  // Joined data
  final String? bengkelName;
  final String? vehicleName;
  final String? vehiclePoliceNumber;
  final String? mechanicName;
  final String? customerName;

  BookingModel({
    required this.id,
    required this.customerId,
    required this.bengkelId,
    required this.vehicleId,
    required this.serviceCategory,
    required this.bookingDate,
    required this.bookingTime,
    required this.status,
    this.complaint,
    required this.createdAt,
    this.isHomeService = false,
    this.customerAddress,
    this.homeServiceFee = 0,
    this.totalPrice,
    this.mechanicId,
    this.serviceReport,
    this.initialPaymentStatus = 'unpaid',
    this.initialPaymentAmount = 0,
    this.additionalPrice = 0,
    this.additionalPaymentStatus = 'none',
    this.serviceProofUrl,
    this.mechanicLatitude,
    this.mechanicLongitude,
    this.latitude,
    this.longitude,
    this.ratingScore,
    this.ratingComment,
    this.ratingMechanicName,
    this.bengkelName,
    this.vehicleName,
    this.vehiclePoliceNumber,
    this.mechanicName,
    this.customerName,
    this.estimatedDuration = 120,
    this.midtransOrderId,
    this.paymentUrl,
    this.paymentExpiresAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      customerId: json['customer_id'] ?? '',
      bengkelId: json['bengkel_id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      serviceCategory: json['service_category'] ?? '',
      bookingDate: DateTime.tryParse(json['booking_date'] ?? '') ?? DateTime.now(),
      bookingTime: json['booking_time'] ?? '',
      status: json['status'] ?? 'Menunggu Konfirmasi',
      complaint: json['complaint'] != null ? json['complaint'] as String : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isHomeService: json['is_home_service'] ?? false,
      customerAddress: json['customer_address'] != null ? json['customer_address'] as String : null,
      homeServiceFee: json['home_service_fee'] ?? 0,
      totalPrice: json['total_price'] != null ? (json['total_price'] as num).toInt() : null,
      mechanicId: json['mechanic_id'] != null ? json['mechanic_id'] as String : null,
      serviceReport: json['service_report'] != null ? json['service_report'] as String : null,
      initialPaymentStatus: json['initial_payment_status'] ?? 'unpaid',
      initialPaymentAmount: (json['initial_payment_amount'] as num?)?.toInt() ?? 0,
      additionalPrice: (json['additional_price'] as num?)?.toInt() ?? 0,
      additionalPaymentStatus: json['additional_payment_status'] ?? 'none',
      serviceProofUrl: json['service_proof_url'] != null ? json['service_proof_url'] as String : null,
      mechanicLatitude: json['mechanic_latitude'] != null ? (json['mechanic_latitude'] as num).toDouble() : null,
      mechanicLongitude: json['mechanic_longitude'] != null ? (json['mechanic_longitude'] as num).toDouble() : null,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      ratingScore: json['rating_score'] != null ? (json['rating_score'] as num).toInt() : null,
      ratingComment: json['rating_comment'] != null ? json['rating_comment'] as String : null,
      ratingMechanicName: json['rating_mechanic_name'] != null ? json['rating_mechanic_name'] as String : null,
      bengkelName: json['bengkels'] != null && json['bengkels'] is Map ? json['bengkels']['name'] as String? : null,
      vehicleName: json['vehicle_name'] != null ? json['vehicle_name'] as String : null,
      vehiclePoliceNumber: json['vehicle_police_number'] != null ? json['vehicle_police_number'] as String : null,
      mechanicName: json['mechanic_name'] != null ? json['mechanic_name'] as String : null,
      customerName: json['users'] != null && json['users'] is Map ? json['users']['full_name'] as String? : null,
      estimatedDuration: json['estimated_duration'] as int? ?? 120,
      midtransOrderId: json['midtrans_order_id'] != null ? json['midtrans_order_id'] as String : null,
      paymentUrl: json['payment_url'] != null ? json['payment_url'] as String : null,
      paymentExpiresAt: json['payment_expires_at'] != null ? DateTime.tryParse(json['payment_expires_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'bengkel_id': bengkelId,
      'vehicle_id': vehicleId,
      'service_category': serviceCategory,
      'booking_date': bookingDate.toIso8601String().split('T').first,
      'booking_time': bookingTime,
      'status': status,
      'complaint': complaint,
      'created_at': createdAt.toIso8601String(),
      'is_home_service': isHomeService,
      'customer_address': customerAddress,
      'home_service_fee': homeServiceFee,
      'total_price': totalPrice,
      'mechanic_id': mechanicId,
      'service_report': serviceReport,
      'initial_payment_status': initialPaymentStatus,
      'initial_payment_amount': initialPaymentAmount,
      'additional_price': additionalPrice,
      'additional_payment_status': additionalPaymentStatus,
      'service_proof_url': serviceProofUrl,
      'mechanic_latitude': mechanicLatitude,
      'mechanic_longitude': mechanicLongitude,
      'latitude': latitude,
      'longitude': longitude,
      'rating_score': ratingScore,
      'rating_comment': ratingComment,
      'rating_mechanic_name': ratingMechanicName,
      'estimated_duration': estimatedDuration,
      'midtrans_order_id': midtransOrderId,
      'payment_url': paymentUrl,
      'payment_expires_at': paymentExpiresAt?.toIso8601String(),
    };
  }
}
