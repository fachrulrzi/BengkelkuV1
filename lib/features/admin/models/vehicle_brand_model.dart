class VehicleBrandModel {
  final String id;
  final String name;
  final DateTime createdAt;

  VehicleBrandModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory VehicleBrandModel.fromJson(Map<String, dynamic> json) {
    return VehicleBrandModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
