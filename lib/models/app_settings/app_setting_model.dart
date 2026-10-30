class AppSettingModel {
  final String id;
  final String settingKey;
  final String settingValue;
  final String? description;
  final DateTime updatedAt;
  final String? updatedBy;

  const AppSettingModel({
    required this.id,
    required this.settingKey,
    required this.settingValue,
    this.description,
    required this.updatedAt,
    this.updatedBy,
  });

  factory AppSettingModel.fromMap(Map<String, dynamic> map) {
    return AppSettingModel(
      id: map['id']?.toString() ?? '',
      settingKey: map['setting_key']?.toString() ?? '',
      settingValue: map['setting_value']?.toString() ?? '',
      description: map['description']?.toString(),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
      updatedBy: map['updated_by']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'setting_key': settingKey,
      'setting_value': settingValue,
      'description': description,
      'updated_at': updatedAt.toIso8601String(),
      'updated_by': updatedBy,
    };
  }
}
