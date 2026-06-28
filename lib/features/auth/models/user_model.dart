enum UserRole {
  customer,
  bengkel,
  mekanik,
  admin
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final UserRole role;
  final double? latitude;
  final double? longitude;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    required this.role,
    this.latitude,
    this.longitude,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.customer,
      ),
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role.name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
