class PengajarPenggantiModel {
  final String id;
  final String nama;
  final String? noHp;
  final bool aktif;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PengajarPenggantiModel({
    required this.id,
    required this.nama,
    this.noHp,
    required this.aktif,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PengajarPenggantiModel.fromMap(Map<String, dynamic> map) {
    return PengajarPenggantiModel(
      id: map['id']?.toString() ?? '',
      nama: map['nama']?.toString() ?? '',
      noHp: map['no_hp']?.toString(),
      aktif: map['aktif'] as bool? ?? true,
      createdBy: map['created_by']?.toString(),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap({
    bool includeId = false,
    bool includeCreatedBy = false,
  }) {
    final data = <String, dynamic>{
      'nama': nama,
      'no_hp': _emptyToNull(noHp),
      'aktif': aktif,
    };

    if (includeId) {
      data['id'] = id;
    }

    if (includeCreatedBy) {
      data['created_by'] = createdBy;
    }

    return data;
  }

  PengajarPenggantiModel copyWith({
    String? id,
    String? nama,
    String? noHp,
    bool? aktif,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PengajarPenggantiModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      noHp: noHp ?? this.noHp,
      aktif: aktif ?? this.aktif,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String? _emptyToNull(String? value) {
    if (value == null) return null;

    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  @override
  String toString() {
    return 'PengajarPenggantiModel('
        'id: $id, '
        'nama: $nama, '
        'noHp: $noHp, '
        'aktif: $aktif'
        ')';
  }
}
