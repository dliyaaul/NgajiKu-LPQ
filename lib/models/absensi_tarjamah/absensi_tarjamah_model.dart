class AbsensiTarjamahModel {
  final String id;
  final String tarjamahPertemuanId;
  final String santriProgramId;
  final String status;

  final String? createdBy;
  final DateTime createdAt;

  // Data santri hasil relational select
  final String? santriId;
  final String? namaSantri;

  const AbsensiTarjamahModel({
    required this.id,
    required this.tarjamahPertemuanId,
    required this.santriProgramId,
    required this.status,
    this.createdBy,
    required this.createdAt,
    this.santriId,
    this.namaSantri,
  });

  factory AbsensiTarjamahModel.fromJson(Map<String, dynamic> json) {
    final santriProgram = json['santri_program'];
    final santri = santriProgram is Map ? santriProgram['santri'] : null;

    return AbsensiTarjamahModel(
      id: json['id']?.toString() ?? '',
      tarjamahPertemuanId: json['tarjamah_pertemuan_id']?.toString() ?? '',
      santriProgramId: json['santri_program_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Alpa',

      createdBy: json['created_by']?.toString(),

      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),

      santriId: santri is Map ? santri['id']?.toString() : null,

      namaSantri: santri is Map ? santri['username']?.toString() : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'tarjamah_pertemuan_id': tarjamahPertemuanId,
      'santri_program_id': santriProgramId,
      'status': status,
      'created_by': createdBy,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {'status': status};
  }

  AbsensiTarjamahModel copyWith({
    String? id,
    String? tarjamahPertemuanId,
    String? santriProgramId,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    String? santriId,
    String? namaSantri,
  }) {
    return AbsensiTarjamahModel(
      id: id ?? this.id,
      tarjamahPertemuanId: tarjamahPertemuanId ?? this.tarjamahPertemuanId,
      santriProgramId: santriProgramId ?? this.santriProgramId,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      santriId: santriId ?? this.santriId,
      namaSantri: namaSantri ?? this.namaSantri,
    );
  }
}
