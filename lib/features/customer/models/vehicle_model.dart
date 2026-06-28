class VehicleModel {
  final String id;
  final String userId;
  final String brand;
  final String model;
  final int year;
  final String licensePlate;
  final String status;
  final String type; // mobil or motor

  VehicleModel({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.status,
    required this.type,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] is int ? json['year'] : int.tryParse(json['year']?.toString() ?? '0') ?? 0,
      licensePlate: json['license_plate'] ?? '',
      status: json['status'] ?? 'Active',
      type: json['type'] ?? 'mobil',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'brand': brand,
      'model': model,
      'year': year,
      'license_plate': licensePlate,
      'status': status,
      'type': type,
    };
  }
}
