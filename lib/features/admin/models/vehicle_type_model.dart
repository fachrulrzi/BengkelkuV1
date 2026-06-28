class VehicleTypeModel {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;

  VehicleTypeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
