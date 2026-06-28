class BengkelServiceModel {
  final String id;
  final String bengkelId;
  final String categoryId;
  final String name;
  final String description;
  final int basePrice;
  final int homeServiceFee;
  final String duration;
  final String? iconCode;

  BengkelServiceModel({
    required this.id,
    required this.bengkelId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.homeServiceFee,
    required this.duration,
    this.iconCode,
  });

  factory BengkelServiceModel.fromJson(Map<String, dynamic> json) {
    // Menangani relasi join ke tabel service_categories
    final category = json['service_categories'] as Map<String, dynamic>? ?? {};
    
    return BengkelServiceModel(
      id: json['id'] as String? ?? '',
      bengkelId: json['bengkel_id'] as String? ?? '',
      categoryId: json['service_category_id'] as String? ?? '',
      name: category['name'] as String? ?? 'Layanan',
      description: category['description'] as String? ?? '',
      basePrice: json['base_price'] as int? ?? 0,
      homeServiceFee: json['home_service_fee'] as int? ?? 0,
      duration: json['estimated_duration'] as String? ?? '-',
      iconCode: category['icon_code'] as String?,
    );
  }
}
