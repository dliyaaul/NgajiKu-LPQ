class HaditsBookModel {
  final String slug;
  final String name;
  final String nameArabic;
  final int total;
  final int sortOrder;

  const HaditsBookModel({
    required this.slug,
    required this.name,
    required this.nameArabic,
    required this.total,
    required this.sortOrder,
  });

  factory HaditsBookModel.fromJson(Map<String, dynamic> json) {
    return HaditsBookModel(
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameArabic: json['name_arabic']?.toString() ?? '',
      total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
    );
  }
}
