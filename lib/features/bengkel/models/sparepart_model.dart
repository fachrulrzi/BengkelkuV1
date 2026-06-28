class SparepartModel {
  final String id;
  final String bengkelId;
  final String name;
  final String sku;
  final String category;
  final double price;
  final int stock;
  final String? imageUrl;
  final int discountPercentage;
  final double rating;
  final int reviewCount;
  final String? description;
  final DateTime createdAt;
  final List<String> compatibleBrandIds;

  // Nested Bengkel Info (diisi lewat join query database)
  final String? bengkelName;
  final String? bengkelAddress;
  final double? bengkelLatitude;
  final double? bengkelLongitude;
  final List<String>? bengkelSpecialization;

  SparepartModel({
    required this.id,
    required this.bengkelId,
    required this.name,
    required this.sku,
    required this.category,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.discountPercentage = 0,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.description,
    required this.createdAt,
    required this.compatibleBrandIds,
    this.bengkelName,
    this.bengkelAddress,
    this.bengkelLatitude,
    this.bengkelLongitude,
    this.bengkelSpecialization,
  });

  factory SparepartModel.fromJson(Map<String, dynamic> json) {
    // Parse nested compatibility list from join table
    final compatList = json['sparepart_compatibilities'] as List?;
    final brandIds = compatList
            ?.map((item) => item['vehicle_brand_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList() ??
        [];

    final bengkelsJson = json['bengkels'];
    final specList = bengkelsJson?['specialization'] as List?;
    final bengkelSpec = specList != null
        ? List<String>.from(specList.map((e) => e.toString()))
        : null;

    return SparepartModel(
      id: json['id']?.toString() ?? '',
      bengkelId: json['bengkel_id']?.toString() ?? '',
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'],
      discountPercentage: (json['discount_percentage'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      description: json['description'] ?? 'Tidak ada deskripsi produk.',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      compatibleBrandIds: List<String>.from(brandIds),
      bengkelName: bengkelsJson?['name']?.toString(),
      bengkelAddress: bengkelsJson?['address']?.toString(),
      bengkelLatitude: (bengkelsJson?['latitude'] as num?)?.toDouble(),
      bengkelLongitude: (bengkelsJson?['longitude'] as num?)?.toDouble(),
      bengkelSpecialization: bengkelSpec,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bengkel_id': bengkelId,
      'name': name,
      'sku': sku,
      'category': category,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
      'discount_percentage': discountPercentage,
      'rating': rating,
      'review_count': reviewCount,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SparepartModel copyWith({
    String? id,
    String? bengkelId,
    String? name,
    String? sku,
    String? category,
    double? price,
    int? stock,
    String? imageUrl,
    int? discountPercentage,
    double? rating,
    int? reviewCount,
    String? description,
    DateTime? createdAt,
    List<String>? compatibleBrandIds,
    String? bengkelName,
    String? bengkelAddress,
    double? bengkelLatitude,
    double? bengkelLongitude,
    List<String>? bengkelSpecialization,
  }) {
    return SparepartModel(
      id: id ?? this.id,
      bengkelId: bengkelId ?? this.bengkelId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      compatibleBrandIds: compatibleBrandIds ?? this.compatibleBrandIds,
      bengkelName: bengkelName ?? this.bengkelName,
      bengkelAddress: bengkelAddress ?? this.bengkelAddress,
      bengkelLatitude: bengkelLatitude ?? this.bengkelLatitude,
      bengkelLongitude: bengkelLongitude ?? this.bengkelLongitude,
      bengkelSpecialization: bengkelSpecialization ?? this.bengkelSpecialization,
    );
  }
}
