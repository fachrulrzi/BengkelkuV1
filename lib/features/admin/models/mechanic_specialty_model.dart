class MechanicSpecialtyModel {
  final String id;
  final String name;

  MechanicSpecialtyModel({
    required this.id,
    required this.name,
  });

  factory MechanicSpecialtyModel.fromJson(Map<String, dynamic> json) {
    return MechanicSpecialtyModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
