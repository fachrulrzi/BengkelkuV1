class MechanicTaskModel {
  final String id;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? vehicleName;
  final String? vehiclePoliceNumber;
  final String serviceCategory;
  final DateTime bookingDate;
  final String bookingTime;
  final String status;
  final String? complaint;
  final bool isHomeService;
  final String? customerAddress;
  final int homeServiceFee;
  final int totalPrice;
  final String? bengkelId;
  final String? serviceReport;
  final DateTime? createdAt;

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

  // Rating & Review
  final int? ratingScore;
  final String? ratingComment;
  final String? ratingMechanicName;

  MechanicTaskModel({
    required this.id,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.vehicleName,
    this.vehiclePoliceNumber,
    required this.serviceCategory,
    required this.bookingDate,
    required this.bookingTime,
    required this.status,
    this.complaint,
    this.isHomeService = false,
    this.customerAddress,
    this.homeServiceFee = 0,
    this.totalPrice = 0,
    this.bengkelId,
    this.serviceReport,
    this.createdAt,
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
  });

  String get shortId =>
      'JOB-${id.replaceAll('-', '').substring(0, 3).toUpperCase()}';

  factory MechanicTaskModel.fromJson(Map<String, dynamic> json) {
    final usersMap = json['users'] as Map<String, dynamic>?;
    final parsedName = usersMap?['full_name']?.toString() ?? json['customer_name']?.toString();
    final parsedPhone = usersMap?['phone']?.toString();

    return MechanicTaskModel(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString(),
      customerName: parsedName,
      customerPhone: parsedPhone,
      vehicleName: json['vehicle_name']?.toString(),
      vehiclePoliceNumber: json['vehicle_police_number']?.toString(),
      serviceCategory: json['service_category']?.toString() ?? '',
      bookingDate: json['booking_date'] != null
          ? DateTime.tryParse(json['booking_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      bookingTime: json['booking_time']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Menunggu Konfirmasi',
      complaint: json['complaint']?.toString(),
      isHomeService: json['is_home_service'] == true,
      customerAddress: json['customer_address']?.toString(),
      homeServiceFee: (json['home_service_fee'] as num?)?.toInt() ?? 0,
      totalPrice: (json['total_price'] as num?)?.toInt() ?? 0,
      bengkelId: json['bengkel_id']?.toString(),
      serviceReport: json['service_report']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      initialPaymentStatus: json['initial_payment_status']?.toString() ?? 'unpaid',
      initialPaymentAmount: (json['initial_payment_amount'] as num?)?.toInt() ?? 0,
      additionalPrice: (json['additional_price'] as num?)?.toInt() ?? 0,
      additionalPaymentStatus: json['additional_payment_status']?.toString() ?? 'none',
      serviceProofUrl: json['service_proof_url']?.toString(),
      mechanicLatitude: (json['mechanic_latitude'] as num?)?.toDouble(),
      mechanicLongitude: (json['mechanic_longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      ratingScore: (json['rating_score'] as num?)?.toInt(),
      ratingComment: json['rating_comment']?.toString(),
      ratingMechanicName: json['rating_mechanic_name']?.toString(),
    );
  }
}
