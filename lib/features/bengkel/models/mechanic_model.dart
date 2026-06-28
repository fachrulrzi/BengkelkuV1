class MechanicModel {
  final String id;
  final String bengkelId;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final String specialist;
  final String password;
  final String status; // Tersedia, Bertugas, Offline
  final double rating;
  final int servicesCount;

  MechanicModel({
    required this.id,
    required this.bengkelId,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.specialist,
    required this.password,
    this.status = 'Tersedia',
    this.rating = 5.0,
    this.servicesCount = 0,
  });

  factory MechanicModel.fromJson(Map<String, dynamic> json) {
    return MechanicModel(
      id: json['id'] as String,
      bengkelId: json['bengkel_id'] as String,
      name: json['name'] as String,
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      photoUrl: json['photo_url'],
      specialist: json['specialist'] ?? '',
      password: json['password'] ?? '',
      status: json['status'] ?? 'Tersedia',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      servicesCount: (json['services_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bengkel_id': bengkelId,
      'name': name,
      'email': email,
      'phone': phone,
      'photo_url': photoUrl,
      'specialist': specialist,
      'password': password,
      'status': status,
      'rating': rating,
      'services_count': servicesCount,
    };
  }
}
